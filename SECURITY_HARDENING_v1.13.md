# Security hardening — Session 61 — v1.13.0 release

This document lists the 5 hardening items implemented in code on
2026-05-25 and the manual Console steps required to activate each one.
**Code changes alone are not sufficient** — without the Console steps,
G2/G4/G1 work as-is, but V3+G10 (App Check) and G6 (audit log) need
server-side configuration.

## Summary table

| Gap | What it defends against | Code | Console | Status |
|-----|------------------------|------|---------|--------|
| G1  | APK reverse-engineering | ✓    | n/a     | DONE — verify build |
| G2  | Auto-Backup data leak   | ✓    | n/a     | DONE |
| G4  | Cleartext + user-CA MITM | ✓   | n/a     | DONE |
| V3+G10 | API key abuse, repackaging | ✓ | REQUIRED | Awaiting Console |
| G6  | Dev-account compromise blast radius | ✓ | DEPLOY rules | Awaiting publish |

## Step-by-step deployment

### Before tagging v1.13.0

**1. Run pub get and a full release build.** R8 minify is now on (G1).
The first release build with new keep rules WILL surface any missing
keeps as a runtime crash. Always test before tagging.

```bash
flutter clean
flutter pub get
flutter build apk --release
# Smoke test on a real device:
adb install -r build/app/outputs/flutter-apk/app-release.apk
# Walk through: Google Sign-In, dev mode 2FA, contribution submit,
# quiz, exam mode, profile screen cloud-sync icon.
```

If anything crashes, the mapping file at
`build/app/outputs/mapping/release/mapping.txt` decodes the obfuscated
stack trace. Add a `-keep` rule for the offending package, repeat.

**2. Publish Firestore rules.** The audit log (G6) collection needs
the new rule block.

- Open https://console.firebase.google.com/
- Project → Firestore Database → Rules tab
- Paste contents of `firestore.rules` (now includes `/audit/{auditId}`)
- Publish

**3. Enable Firebase App Check.** V3+G10 client code is in place but
the server side must be configured.

- Firebase Console → App Check → Get started
- Register Android app: select **Play Integrity** as the provider.
  - You will need your app's **SHA-256 fingerprint** from the
    release keystore. Get it via:
    ```powershell
    keytool -list -v -alias <alias> -keystore <path-to-release.jks>
    ```
  - Paste SHA-256 into Firebase App Check Android registration.
- Register iOS app: select **App Attest** (with DeviceCheck fallback).
  - The iOS Team ID + Bundle ID will auto-populate from your APNs cert.
- **Do NOT enable enforcement yet.** Leave it in "Unenforced" mode for
  at least one week of v1.13.0 in production. App Check collects
  metrics during this period without blocking; check
  Firebase Console → App Check → APIs → Firestore tab to verify
  ≥99% of legit traffic shows valid attestation tokens before flipping
  the Enforce switch.

**4. Add debug tokens for dev builds.** During development, the app
prints a debug token to logcat on first launch:

```
Enter this debug secret into the allow list in the Firebase Console
for your project: XXXX-XXXX-XXXX-XXXX
```

- Copy that token
- Firebase Console → App Check → Apps → Manage debug tokens
- Add the token + a label like "samag-windows-debug"
- Repeat for each dev machine / emulator

**5. (Optional but recommended) Enable 2FA on the developer Google
account.** Single point of compromise for the entire user dataset.

- https://myaccount.google.com/security
- Turn on 2-Step Verification with at least an authenticator app
  (Google Authenticator, Authy, or a hardware security key).
- Once 2FA is active, save backup codes offline (not in the repo,
  not in OneDrive, not in any cloud-synced location).

### After tagging v1.13.0

**6. Monitor App Check metrics for one week.**
- Firebase Console → App Check → Metrics
- Watch the "Verified requests" percentage for Firestore.
- Until it exceeds 99%, do NOT enforce.

**7. Flip enforcement when stable.**
- Firebase Console → App Check → APIs → Firestore → Enforce
- Confirm. From this point onward, any Firestore request from a
  non-attested client (stolen API key in curl, unmodified APK from
  rooted device, replayed token) fails with permission-denied.
- Repeat for Cloud Storage if you ever start using it.

**8. Set up an alert on the audit log.** (Manual; optional.)
- Firebase Console → Firestore → Indexes
- Create a Cloud Function (or scheduled Apps Script) that emails
  samagids@gmail.com whenever a new doc is written to /audit and
  the count over 24 hours exceeds N (e.g. 10). This catches a
  compromised dev account before they exfiltrate everyone's data.

## What each change does

### G1: R8 minify + shrink (`android/app/build.gradle.kts`)

`isMinifyEnabled = true` and `isShrinkResources = true` in the release
buildType. Uses `proguard-android.txt` (not -optimize.txt) for
plugin-safety. Comprehensive keep rules in
`android/app/proguard-rules.pro`.

**Effect:** APK class/method names are obfuscated. Reverse-engineering
the platform channel (`com.awing.learning/asset_pack`) requires
deobfuscation; static string-grep no longer works. Crash reports
still mappable via Play Console mapping.txt upload.

### G2: Auto-Backup off (`AndroidManifest.xml` + `xml/data_extraction_rules.xml`)

`android:allowBackup="false"`, `android:fullBackupContent="false"`,
`android:dataExtractionRules="@xml/data_extraction_rules"`. The XML
denies cloud-backup and device-transfer at all domain levels.

**Effect:** SharedPreferences containing the dev's 2FA state, auth
accounts, progress, and settings are NO LONGER auto-backed-up to the
user's Google Drive. Existing backups will remain on Google's servers
until the device next attempts a backup (which now skips). To delete
historical backups, the user must remove the app via "Settings → My
account → Apps & devices → Awing → Remove backup" on each device.

### G4: Network Security Config (`AndroidManifest.xml` + `xml/network_security_config.xml`)

`android:networkSecurityConfig="@xml/network_security_config"` and
`android:usesCleartextTraffic="false"`. The XML sets
`cleartextTrafficPermitted="false"` and trusts only `<certificates
src="system" />` (rejects user CAs). Debug builds get a
`<debug-overrides>` block that re-enables user CAs for local
mitmproxy/Charles use.

**Effect:** A parent/school admin who installs a custom root CA on the
device cannot MITM our HTTPS traffic. Firebase, Apps Script webhooks,
Google Sign-In all fail closed against interception. Cleartext HTTP
is rejected at the OS layer regardless of how URLs are constructed.

### V3+G10: Firebase App Check (`pubspec.yaml` + `main.dart`)

`firebase_app_check: ^0.3.1+7` package added.
`FirebaseAppCheck.instance.activate(...)` called after
`Firebase.initializeApp()` with `AndroidProvider.playIntegrity` /
`AppleProvider.appAttestWithDeviceCheckFallback` for release builds,
`AndroidProvider.debug` / `AppleProvider.debug` for debug builds.

**Effect (once enforcement enabled):** Every Firestore call from the
app carries a per-request Play Integrity / App Attest attestation
token. Firebase's backend rejects requests without a valid token —
defeats both V3 (extracted API key replayed from outside the app)
and G10 (modified/repackaged APK without auth logic). The 1-week
unenforced rollout window prevents the change from breaking live
users while metrics confirm legit traffic attests cleanly.

### G6: Firestore audit log (`firestore.rules` + `developer_screen.dart`)

New `/audit/{auditId}` collection with rules:
- `create`: dev only, email must match auth token email
- `read`: dev only
- `update + delete`: NEVER (append-only forensics)

Developer Mode → Users tab now writes one audit entry per bulk-read
of user data: `{email, action: 'bulk_read_users', timestamp,
userCount}`.

**Effect:** If samagids@gmail.com is ever phished, the
post-compromise question "what data did the attacker read?" is
answerable from the audit collection. Logs can't be tampered with
or deleted — even by the developer account itself.

## Verification commands

After deploying:

```powershell
# Verify minify worked
unzip -p build\app\outputs\bundle\release\app-release.aab base\classes.dex `
  | strings | findstr "com.awing.learning"
# Should show only the MainActivity FQN — everything else obfuscated.

# Verify App Check token mints in debug build
adb logcat -s flutter:* | findstr "App Check\|debug secret"
# Should print a debug token line on first launch.

# Verify audit log writes (after deploying rules + tapping Users tab)
# In Firebase Console → Firestore → Data → audit collection
# Each tap of Users tab adds one doc.
```

## Rollback if needed

If the v1.13.0 release surfaces a R8 issue you can't quickly fix:

1. In `android/app/build.gradle.kts`, flip
   `isMinifyEnabled = false`, `isShrinkResources = false`. Tag a
   v1.13.1 hotfix. Other hardening (G2, G4, V3+G10, G6) all stay on.

If App Check breaks legit users:

1. Firebase Console → App Check → APIs → Firestore → Unenforce.
   Clients keep sending tokens but server stops rejecting unattested
   ones. No client-side change needed.

## Files touched

```
pubspec.yaml                                        — added firebase_app_check
lib/main.dart                                       — App Check init
android/app/build.gradle.kts                        — minify + shrink
android/app/proguard-rules.pro                      — comprehensive keeps
android/app/src/main/AndroidManifest.xml            — backup off + NSC + cleartext off
android/app/src/main/res/xml/data_extraction_rules.xml — NEW
android/app/src/main/res/xml/network_security_config.xml — NEW
firestore.rules                                     — /audit collection
lib/screens/admin/developer_screen.dart             — audit write on bulk read
SECURITY_HARDENING_v1.13.md                         — this file
```
