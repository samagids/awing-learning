"""Mock Apps Script deployments, to test test_webhook offline.

  8731 HEALTHY   POST -> 303 /echo ; GET /echo -> a genuine doPost reply
                 (303 because _post_follow only treats a 302 as an "echo"
                 hop when the host is googleusercontent.com, which a local
                 mock cannot be; the 303 branch exercises the same
                 fetch-the-result-then-evaluate path)
  8732 BOUNCING  POST -> 302 /exec ; GET /exec -> doGet health payload
  8733 DIRECT    POST -> 200 doGet health payload, no redirect at all
                 (hits test_webhook's decisive `service` check head on)
"""
import json, threading, time
from http.server import BaseHTTPRequestHandler, HTTPServer

HEALTH = json.dumps({"status": "ok", "service": "Awing Contributions",
                     "timestamp": "2026-09-28T00:00:00Z"}).encode()
DOPOST = json.dumps({"status": "error", "message": "Unknown action"}).encode()

def make(mode):
    class H(BaseHTTPRequestHandler):
        def log_message(self, *a): pass
        def _send(self, body):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers(); self.wfile.write(body)
        def do_POST(self):
            self.rfile.read(int(self.headers.get("Content-Length", 0) or 0))
            port = self.server.server_port
            if mode == "direct":
                return self._send(HEALTH)
            code = 303 if mode == "healthy" else 302
            path = "echo" if mode == "healthy" else "exec"
            self.send_response(code)
            self.send_header("Location", f"http://127.0.0.1:{port}/{path}")
            self.end_headers()
        def do_GET(self):
            self._send(DOPOST if (mode == "healthy" and self.path.endswith("echo")) else HEALTH)
    return H

servers = []
for port, mode in ((8731, "healthy"), (8732, "bouncing"), (8733, "direct")):
    s = HTTPServer(("127.0.0.1", port), make(mode))
    servers.append(s)
    threading.Thread(target=s.serve_forever, daemon=True).start()

time.sleep(600)
