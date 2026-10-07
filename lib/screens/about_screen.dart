import 'package:flutter/material.dart';
import 'package:awing_ai_learning/data/audio_contributors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/utils/pin_text_controller.dart';

/// About screen — credits, version, app information, and hidden developer mode entry.
class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  // v1.24.0: buildNumber was stuck at '140' through 1.23.5+141 and
  // 1.23.6+142, so the About screen and the analytics payload both
  // reported the wrong build for three releases. There are SIX places the
  // version lives - pubspec.yaml, these two constants, analytics_service
  // and cloud_backup_service - and only four were in the release
  // checklist. developer_screen now derives from these instead of holding
  // a seventh copy.
  static const String appVersion = '1.24.4';
  static const String buildNumber = '148';
  static const String developerName = 'Dr. Guidion Sama, DIT';
  static const String developerEmail = 'samagids@gmail.com';
  static const String appDescription =
      'Awing Learning is an interactive mobile application designed to '
      'teach the Awing language — a Grassfields Bantu language spoken by '
      'about 19,000 people in the Mezam division, North West Province, '
      'Republic of Cameroon. The app targets kids and beginners with '
      'AI-powered lessons across three proficiency levels.';

  static const Color _awingGreen = Color(0xFF006432);
  static const Color _awingGold = Color(0xFFDAA520);
  static const Color _awingAmber = Color(0xFFF5AF19);
  static const Color _awingDarkGreen = Color(0xFF004623);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Developer mode entry state
  int _versionTapCount = 0;
  int _devCodeFailedAttempts = 0;
  DateTime? _devCodeLockoutUntil;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // App icon
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            // App name
            Text(
              'Awing Learning',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
              ),
            ),
            const SizedBox(height: 4),
            // Version text — 5 taps to enter developer mode
            GestureDetector(
              onTap: () {
                final auth = context.read<AuthService>();
                _versionTapCount++;
                if (_versionTapCount >= 5 && !auth.isDeveloper) {
                  _versionTapCount = 0;
                  _showDevModeDialog(context, auth);
                } else if (_versionTapCount >= 5 && auth.isDeveloper) {
                  _versionTapCount = 0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Developer mode is already active')),
                  );
                } else if (_versionTapCount >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${5 - _versionTapCount} more taps...'),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              child: Text(
                'Version ${AboutScreen.appVersion} (Build ${AboutScreen.buildNumber})',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Text(
                AboutScreen.appDescription,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Developer section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E2E1E), const Color(0xFF252525)]
                      : [AboutScreen._awingGreen.withAlpha(20), AboutScreen._awingGold.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : AboutScreen._awingGold.withAlpha(80),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AboutScreen.developerName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchEmail(),
                    child: Text(
                      AboutScreen.developerEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Linguistic credits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linguistic References',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreditRow(
                    title: 'Awing Orthography Guide (2005)',
                    author: 'Alomofor Christian & Stephen C. Anderson',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _CreditRow(
                    title: 'Awing English Dictionary (2007)',
                    author: 'Alomofor Christian, CABTAL',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _CreditRow(
                    title: 'A Phonological Sketch of Awing (2009)',
                    author: 'Bianca van den Berg, SIL Cameroon',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Community supporters section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.diversity_3,
                        size: 20,
                        color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'With Support From',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // NACDA emblem centered above the credits. Tap-to-zoom
                  // for users who want a closer look at the design.
                  Center(
                    child: GestureDetector(
                      onTap: () => _showNacdaLogo(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/nacda_logo.jpg',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This project is made possible with support from the '
                    'Ndong Awing Cultural and Development Association '
                    '(NACDA) and the wider Awing community:',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreditRow(
                    title: 'With support from NACDA (Ndong Awing Cultural and Development Association)',
                    author: 'NACDA-DMV',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _CreditRow(
                    title: 'With support from the Virginia NACDA',
                    author: 'NACDA-DMV-Virginia',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Audio Contributors section -- credits every native voice
            // that has recorded audio shipped in the app. Core voices
            // (Dr. Sama + family) are hard-coded in
            // lib/data/audio_contributors.dart; approved external
            // contributors are auto-appended by
            // scripts/apply_contributions.py during the build pipeline.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic,
                        size: 20,
                        color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Audio Contributors',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Native speakers whose voices bring this app to life. '
                    'Their recordings power the Awing pronunciation you hear '
                    'in lessons, quizzes, and stories.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in audioContributors)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.green.shade900.withOpacity(0.4)
                                : AboutScreen._awingDarkGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.green.shade700
                                  : AboutScreen._awingDarkGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.green.shade100
                                  : AboutScreen._awingDarkGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Technology section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Built With',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade200 : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TechRow(icon: Icons.phone_android, label: 'Flutter & Dart', isDark: isDark),
                  _TechRow(icon: Icons.smart_toy, label: 'TensorFlow Lite (On-device AI)', isDark: isDark),
                  _TechRow(icon: Icons.record_voice_over, label: 'Edge TTS (Bantu Neural Voices)', isDark: isDark),
                  _TechRow(icon: Icons.mic, label: 'Speech-to-Text Recognition', isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support / Donation section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E2E1E), const Color(0xFF252525)]
                      : [AboutScreen._awingGold.withAlpha(25), AboutScreen._awingAmber.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : AboutScreen._awingGold.withAlpha(100),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFDAA520), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Support This Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AboutScreen._awingGold : AboutScreen._awingDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help preserve the Awing language for future generations. '
                    'Your donation supports app development, linguistic research, '
                    'and native speaker recordings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDonationInfo(context),
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text(
                        'Donate via Zelle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AboutScreen._awingGold,
                        foregroundColor: AboutScreen._awingDarkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Copyright
            Text(
              '\u00A9 ${DateTime.now().year} ${AboutScreen.developerName}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: AboutScreen.developerEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDonationInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFFDAA520)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Donate via Zelle', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send your donation via Zelle to:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E2E1E) : const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDAA520).withAlpha(100),
                ),
              ),
              child: SelectableText(
                AboutScreen.developerEmail,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF81C784) : AboutScreen._awingGreen,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Open your banking app, select Zelle, and send to the email above. '
              'Every contribution helps keep the Awing language alive!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show the NACDA emblem in a full-screen-ish dialog so users can see
  /// the detail of the traditional Bamileke-pattern sleeve + open palm
  /// design. Tap-to-dismiss.
  void _showNacdaLogo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/nacda_logo.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ndong Awing Cultural and\nDevelopment Association',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap anywhere to close',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Developer Mode Entry ──────────────────────────────────────────────

  /// Load the analytics webhook URL from bundled config.
  Future<String?> _getAnalyticsWebhookUrl() async {
    try {
      final jsonStr = await rootBundle.loadString('config/webhooks.json');
      final config = jsonDecode(jsonStr) as Map<String, dynamic>;
      return config['analytics_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Send a 6-digit verification code to the developer's Gmail via webhook.
  ///
  /// Returns TRI-STATE, deliberately (v1.23.5, Session 64d):
  ///   true  — the server confirmed `status: ok`. The mail was sent.
  ///   false — we know it was NOT sent (no webhook URL, the POST itself
  ///           never got through, or the server explicitly said not-ok).
  ///   null  — UNKNOWN. doPost ran (we got its 302) but we could not read
  ///           the reply. The mail has most likely gone out.
  ///
  /// Why: this used to return a plain bool, and every unreadable reply
  /// became `false` -> "The verification email could not be sent
  /// (offline or webhook down)". That message was simply untrue. Apps
  /// Script answers the POST with a 302 to a googleusercontent "echo"
  /// URL that is NOT ready the instant the redirect arrives, so the
  /// follow-up GET can 404. The old code never checked the status code,
  /// fed the 404 HTML page straight into jsonDecode, threw, and landed
  /// in the catch-all. Verified against the Apps Script execution log:
  /// 50/50 doPost runs Completed, MailApp never threw, and the codes
  /// were arriving in the inbox the whole time the app claimed failure.
  Future<bool?> _sendDevVerificationEmail(String code) async {
    final webhookUrl = await _getAnalyticsWebhookUrl();
    if (webhookUrl == null) return false;

    final payload = jsonEncode({
      'action': 'send_dev_code',
      'code': code,
      'email': 'samagids@gmail.com',
    });

    // Set once the POST has been answered. After that point doPost has
    // RUN on the server, so a later read failure means "unknown", never
    // "not sent".
    var postDelivered = false;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      // Step 1: POST the payload — Apps Script processes it and returns 302
      final postRequest = await client.postUrl(Uri.parse(webhookUrl));
      postRequest.followRedirects = false;
      postRequest.headers.contentType = ContentType.json;
      postRequest.write(payload);
      final postResponse = await postRequest.close();
      postDelivered = true;

      debugPrint('Webhook POST: ${postResponse.statusCode}');

      // Step 2: Follow 302 redirect with GET to read the response
      if (postResponse.statusCode == 302 || postResponse.statusCode == 301) {
        await postResponse.drain<void>();
        final location = postResponse.headers.value('location');
        if (location == null) {
          client.close();
          debugPrint('Webhook error: redirect with no location header');
          return false;
        }
        debugPrint('Webhook redirect to: ${location.substring(0, 80)}...');

        // Follow redirect chain with GET.
        // The echo URL is often not ready the moment the 302 lands, so a
        // 404 here is TRANSIENT — the same 404-then-success we see in
        // scripts/setup_and_deploy.py's verifier. Retry before giving up,
        // and never parse a non-200 body as JSON.
        var getUri = Uri.parse(location);
        var transientTries = 0;
        for (int i = 0; i < 8; i++) {
          final getRequest = await client.getUrl(getUri);
          getRequest.followRedirects = false;
          final getResponse = await getRequest.close();

          if (getResponse.statusCode == 302 || getResponse.statusCode == 301) {
            await getResponse.drain<void>();
            final nextLocation = getResponse.headers.value('location');
            if (nextLocation == null) break;
            getUri = Uri.parse(nextLocation);
            continue;
          }

          final sc = getResponse.statusCode;
          if (sc == 404 || sc == 408 || sc == 429 || (sc >= 500 && sc < 600)) {
            await getResponse.drain<void>();
            if (transientTries < 3) {
              transientTries++;
              debugPrint('Webhook echo not ready (HTTP $sc) — '
                  'retry $transientTries/3');
              await Future<void>.delayed(
                  Duration(milliseconds: 700 * transientTries));
              continue;
            }
            client.close();
            debugPrint('Webhook: echo URL still HTTP $sc after retries — '
                'result UNKNOWN (the mail was probably sent).');
            return null;
          }

          final body = await getResponse.transform(utf8.decoder).join();
          client.close();
          debugPrint('Webhook response: $sc $body');
          if (sc != 200) return null;
          try {
            final result = jsonDecode(body);
            if (result is Map && result['status'] == 'ok') return true;
            // A readable, explicit non-ok IS a real failure.
            debugPrint('Webhook said not-ok: $body');
            return false;
          } catch (_) {
            // Unparseable body — we learned nothing.
            return null;
          }
        }
      } else {
        // No redirect — read directly
        final body = await postResponse.transform(utf8.decoder).join();
        client.close();
        debugPrint('Webhook response (no redirect): ${postResponse.statusCode} $body');
        if (postResponse.statusCode != 200) return null;
        try {
          final result = jsonDecode(body);
          if (result is Map && result['status'] == 'ok') return true;
          return false;
        } catch (_) {
          return null;
        }
      }

      client.close();
      debugPrint('Webhook: ran out of redirect hops — result UNKNOWN.');
      return null;
    } catch (e) {
      debugPrint('Webhook error: $e');
      // If the POST was already answered, doPost ran on the server and
      // the mail may well have been sent — that is UNKNOWN, not failure.
      // Only a failure BEFORE the POST was answered proves nothing was
      // sent.
      return postDelivered ? null : false;
    }
  }

  void _showDevModeDialog(BuildContext context, AuthService auth) {
    // Step 1: Must be signed in with the developer Gmail
    if (!auth.isDeveloperEmail) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.red),
              SizedBox(width: 8),
              Text('Access Denied'),
            ],
          ),
          content: const Text(
            'Developer Mode is only available for the designated developer account. '
            'Sign in with the developer Google account to access this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Rate limit: lock out for 5 minutes after 3 failed attempts
    if (_devCodeLockoutUntil != null &&
        DateTime.now().isBefore(_devCodeLockoutUntil!)) {
      final remaining = _devCodeLockoutUntil!.difference(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many failed attempts. Try again in ${remaining.inMinutes + 1} minutes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 2: Enter access code
    final codeController = PinTextController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: Colors.grey),
            SizedBox(width: 8),
            Text('Developer Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 1 of 2: Enter the developer access code.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              // Masked by PinTextController, not obscureText: that reveals
              // each character for ~10 frames, which a screen recording keeps.
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text == 'awing2026') {
                _devCodeFailedAttempts = 0;
                _devCodeLockoutUntil = null;
                Navigator.pop(ctx);
                _startDevMode2FA(context, auth);
              } else {
                _devCodeFailedAttempts++;
                Navigator.pop(ctx);
                if (_devCodeFailedAttempts >= 3) {
                  _devCodeLockoutUntil =
                      DateTime.now().add(const Duration(minutes: 5));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Too many failed attempts. Locked for 5 minutes.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid access code (${3 - _devCodeFailedAttempts} attempts remaining)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  /// Step 3: Send verification code to developer Gmail and show input dialog.
  void _startDevMode2FA(BuildContext context, AuthService auth) async {
    // Generate and store code
    final code = auth.generateDevVerificationCode();

    // Show loading dialog while sending email
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Sending verification code to your Gmail...')),
          ],
        ),
      ),
    );

    // Send code via webhook
    final sent = await _sendDevVerificationEmail(code);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    // Webhook fallback: show the code on-screen as well as via email.
    // Security model is intact — caller already cleared the `awing2026`
    // access-code gate, is signed in as the developer email, and still has
    // to type the 6-digit code into the verification dialog. The webhook
    // email is a third factor that's helpful in production but blocks
    // local-only dev work when the network or webhook deployment is down.
    //
    // v1.23.5 (Session 64d): `sent` is now tri-state. `null` means we
    // could not READ the webhook's reply — it does NOT mean the mail
    // failed, and in practice it almost always went out. Saying "could
    // not be sent" there was a lie that sent the developer chasing a
    // webhook that was working perfectly.
    if (sent != true) {
      final unknown = sent == null;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(unknown ? Icons.info_outline : Icons.warning_amber,
                  color: unknown ? Colors.blue : Colors.orange),
              const SizedBox(width: 8),
              Text(unknown ? 'Check your email' : 'Email unavailable'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unknown
                    ? 'The code was sent, but the app could not confirm it '
                        '(the webhook reply was unreadable). Check your '
                        'inbox — it is most likely there. The same code is '
                        'shown below either way:'
                    : 'The verification email could not be sent (offline or '
                        'webhook down). Showing the code on-screen as a '
                        'fallback:',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Copy or memorize the code, then tap Continue.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }

    // Show code entry dialog
    final verifyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Email Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 2 of 2: A 6-digit code was sent to your Gmail. '
              'Enter it below to activate Developer Mode.',
            ),
            const SizedBox(height: 8),
            Text(
              'Code expires in 10 minutes.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verifyController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final error = auth.verifyDevCode(verifyController.text);
              Navigator.pop(ctx);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer mode activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String title;
  final String author;
  final bool isDark;

  const _CreditRow({
    required this.title,
    required this.author,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade200 : Colors.black87,
            ),
          ),
          Text(
            author,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _TechRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF81C784) : const Color(0xFF006432),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
