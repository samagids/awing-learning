#!/usr/bin/env python3
"""Probe the deployed analytics webhook's `send_dev_code` action.

Developer Mode 2FA mails a code via MailApp from the analytics Apps
Script. When "entering admin mode" fails to send, the app only shows a
generic failure -- the useful error is in the webhook's JSON reply, and
this pulls it out.

Two stages:

  1. SAFE probe (default). Sends a deliberately wrong address.
     handleSendDevCode rejects it BEFORE MailApp.sendEmail, so nothing
     is sent and no quota is spent.
       "Unauthorized email" -> dispatch + execution are fine; the fault
                               is in MailApp itself (quota or auth).
       doGet health payload -> the request never reached doPost.
       anything else        -> the deployed code is not what we think.

  2. REAL probe (--real). Requests an actual code to the developer
     address read from scripts/analytics_webapp.gs. This DOES send, and
     surfaces the true MailApp error, e.g.
       "Service invoked too many times for one day: email"  -> QUOTA
       "Authorization is required to perform that action"   -> re-auth

  python scripts/probe_dev_code.py
  python scripts/probe_dev_code.py --real
"""
import json
import re
import sys
from pathlib import Path
from urllib.request import Request

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from setup_and_deploy import _post_follow, load_webhooks  # noqa: E402


def developer_email():
    """Read DEVELOPER_EMAIL from the .gs rather than hardcoding it here."""
    gs = (HERE / "analytics_webapp.gs").read_text(encoding="utf-8")
    m = re.search(r"var\s+DEVELOPER_EMAIL\s*=\s*['\"]([^'\"]+)['\"]", gs)
    return m.group(1) if m else None


def post(url, payload):
    req = Request(url, data=json.dumps(payload).encode("utf-8"),
                  headers={"Content-Type": "application/json; charset=utf-8"})
    return json.loads(_post_follow(req, timeout=30).decode("utf-8"))


def main():
    url = load_webhooks().get("analytics_url", "")
    if not url:
        print("  No analytics_url in config/webhooks.json.")
        return 1

    real = "--real" in sys.argv
    print(f"\n  Endpoint: {url}\n")

    print("  [1/2] SAFE probe (wrong address -> no mail sent)")
    try:
        r = post(url, {"action": "send_dev_code", "code": "000000",
                       "email": "nobody@example.invalid"})
    except Exception as e:
        print(f"        Could not reach the endpoint: {e}")
        return 2
    print(f"        {json.dumps(r)}")

    if r.get("status") == "ok" and r.get("service"):
        print("        ? doGet health payload -- never reached doPost. Retry.")
        return 2
    if r.get("message") == "Unauthorized email":
        print("        OK: handleSendDevCode is live and executing.")
        print("        This proves dispatch + execution only. It says")
        print("        NOTHING about whether MailApp can actually send —")
        print("        the reject happens before MailApp is touched.")
    else:
        print("        UNEXPECTED: deployed code differs from the repo.")
        return 1

    if not real:
        print("\n  [2/2] skipped. Re-run with --real to request an actual")
        print("        code and surface the true MailApp error.")
        return 0

    dev = developer_email()
    if not dev:
        print("\n  Could not read DEVELOPER_EMAIL from analytics_webapp.gs.")
        return 1
    print(f"\n  [2/2] REAL probe -> {dev}  (this sends an email)")
    try:
        r2 = post(url, {"action": "send_dev_code", "code": "123456",
                        "email": dev})
    except Exception as e:
        print(f"        Could not reach the endpoint: {e}")
        return 2
    print(f"        {json.dumps(r2)}")

    msg = str(r2.get("message", ""))
    if r2.get("status") == "ok":
        print("        SENT. Check the inbox (and spam).")
        return 0
    low = msg.lower()
    if "too many times" in low or "quota" in low or "limit" in low:
        print("        >>> MAILAPP DAILY QUOTA EXHAUSTED.")
        print("            Consumer Gmail allows ~100 MailApp recipients/day,")
        print("            shared across send_dev_code AND the new")
        print("            handleNewUser alerts. It resets on a rolling 24h.")
    elif "authoriz" in low or "permission" in low:
        print("        >>> AUTHORIZATION LOST. Open the Apps Script editor,")
        print("            Run any function once, and accept the prompt.")
    else:
        print("        >>> Unrecognized MailApp error (above).")
    return 1


if __name__ == "__main__":
    sys.exit(main())
