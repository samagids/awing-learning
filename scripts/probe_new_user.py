#!/usr/bin/env python3
"""Probe the deployed analytics webhook for the `new_user` handler.

Why this exists instead of a curl one-liner: Apps Script answers every
POST with a 302, and a client that auto-follows turns POST into GET and
lands on doGet(), which happily returns a healthy-looking payload. That
trap has now bitten the Dart client (Session 26), PowerShell's
Invoke-RestMethod (Session 64) and urllib (Session 64). On top of that,
quoting a JSON body through PowerShell is its own minefield -- two
attempts produced a malformed URL and a bodyless POST (HTTP 411).

So: reuse `_post_follow` from setup_and_deploy.py, which POSTs without
following, reads the Location header, then GETs that URL.

The probe deliberately sends an EMPTY email. handleNewUser rejects it
before MailApp.sendEmail, so nothing is sent and the server-side dedupe
store is not touched. We are testing that the dispatch EXISTS.

  python scripts/probe_new_user.py

  {"status": "error", "message": "invalid email"}
      -> handleNewUser is live.
  {"status": "ok", "service": ...}
      -> doGet leaked through; the probe could not observe. Retry.
  Unknown action / anything else
      -> the deployed Code.js predates the new_user handler. Re-deploy.
"""
import json
import sys
from pathlib import Path
from urllib.request import Request

sys.path.insert(0, str(Path(__file__).resolve().parent))
from setup_and_deploy import _post_follow, load_webhooks  # noqa: E402


def main():
    config = load_webhooks()
    url = config.get('analytics_url', '')
    if not url:
        print("  No analytics_url in config/webhooks.json.")
        print("  Run: python scripts/setup_and_deploy.py --webhooks")
        return 1

    print(f"\n  Probing: {url}")
    print('  POST {"action":"new_user","email":""}  (no mail is sent)\n')

    payload = json.dumps({"action": "new_user", "email": ""}).encode('utf-8')
    req = Request(url, data=payload,
                  headers={'Content-Type': 'application/json; charset=utf-8'})
    try:
        raw = _post_follow(req)
    except Exception as e:
        print(f"  Could not reach the endpoint: {type(e).__name__}: {e}")
        print("  Inconclusive -- this says nothing about what is deployed.")
        return 2

    body = raw.decode('utf-8', errors='replace')
    try:
        data = json.loads(body)
    except ValueError:
        print(f"  Non-JSON response:\n{body[:400]}")
        return 2

    print(f"  Response: {json.dumps(data)}\n")
    status, msg = data.get('status'), str(data.get('message', ''))

    if status == 'error' and msg == 'invalid email':
        print("  OK: handleNewUser is LIVE (it validated and rejected the")
        print("      empty address, which only the new code does).")
        return 0
    if status == 'ok' and data.get('service'):
        print("  ? INCONCLUSIVE: got doGet's health payload, so the doPost")
        print("    result was never read. Nothing learned -- retry.")
        return 2
    if msg.lower().startswith('unknown action'):
        print("  STALE: the deployed Code.js has no new_user handler.")
        print("    Fix: cd scripts/clasp_analytics && clasp push --force")
        print("         then clasp deploy --deploymentId <analytics id>")
        return 1
    print("  UNEXPECTED response -- treat as not deployed and re-check.")
    return 1


if __name__ == '__main__':
    sys.exit(main())
