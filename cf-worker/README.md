# Awing AI Learning — CloudFlare Worker Backend

This directory contains the CloudFlare Worker that powers Cloud AI mode.

## One-time setup

### 1. Sign up for CloudFlare (5 min)

- Go to https://dash.cloudflare.com/sign-up
- Sign up with samagids@gmail.com (no credit card needed for the free tier)
- Skip "Add a website" — we don't need it
- After login, look for your **Account ID** in the right sidebar of any
  Workers page. It's a long hex string like `abc123...`

### 2. Install wrangler (2 min)

```powershell
npm install -g wrangler
wrangler --version   # should print v3.x
```

If you don't have Node.js:
- Install from https://nodejs.org (LTS version)
- Then run the wrangler install command above.

### 3. Log in to CloudFlare from wrangler (30 sec)

```powershell
cd C:\Users\samag\OneDrive\Documents\Claude\Awing\cf-worker
wrangler login
```

This opens a browser tab. Click "Allow".

### 4. Fill in your Account ID

Edit `wrangler.toml` and replace `REPLACE_WITH_YOUR_ACCOUNT_ID` with the
account ID you saw in the CloudFlare dashboard.

### 5. Set the Firebase project id secret

The Worker verifies that requests come from your Firebase-authenticated
app users. It needs to know which Firebase project to trust.

```powershell
wrangler secret put FIREBASE_PROJECT_ID
# When prompted, paste: awing-ai-learning
# (or whatever your Firebase project id is — check firebase console)
```

### 6. Deploy

```powershell
npm install
wrangler deploy
```

You'll get output like:
```
Published awing-ai (2.34 sec)
  https://awing-ai.<your-subdomain>.workers.dev
```

Copy that URL. Paste it back to Claude — I'll wire it into the Dart app
as the Cloud AI endpoint.

## Testing the deployed Worker

Health check (no auth):
```powershell
curl https://awing-ai.<your-subdomain>.workers.dev/health
# Should return: {"status":"ok","model":"@cf/meta/llama-3.1-8b-instruct-fast"}
```

## Monitoring

Live tail the logs:
```powershell
wrangler tail
```

Or open the CloudFlare dashboard → Workers & Pages → awing-ai → Logs.

## Cost

Free tier limits:
- 100,000 Worker invocations per day
- 10,000 neurons per day (Workers AI)
  - Llama 3.1 8B fast: ~11 neurons per translation
  - So roughly 900 translations/day free

Once you exceed either, requests fail — no automatic billing. Upgrade
to Workers Paid ($5/month) to raise the limits.
