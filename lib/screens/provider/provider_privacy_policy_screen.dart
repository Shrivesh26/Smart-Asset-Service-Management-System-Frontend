import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderPrivacyPolicyScreen extends StatelessWidget {
  const ProviderPrivacyPolicyScreen({super.key});

  bool get _isDark => false; // resolved at build time via Theme

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final txtP = dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final txtS = dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = dark ? AppTheme.darkCard : Colors.white;
    final surface = dark ? AppTheme.darkBackground : AppTheme.surface;

    return Scaffold(
      backgroundColor: surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                      : [AppTheme.providerDark, AppTheme.providerPrimary])),
          child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.go(AppRoutes.providerSettings),
                  ),
                  const Expanded(
                      child: Text('Privacy Policy',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('v1.0',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              )),
        ),

        // ── Content ─────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Updated date notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppTheme.providerPrimary.withOpacity(dark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.providerPrimary.withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.providerPrimary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            'Last updated: January 1, 2025. Please read this policy carefully.',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppTheme.providerPrimary,
                                height: 1.4))),
                  ]),
                ),
                const SizedBox(height: 24),

                ..._sections.map((s) => _buildSection(
                    context, s['title']!, s['body']!, dark, txtP, txtS, cardBg)),

                const SizedBox(height: 12),
                Text(
                    'If you have questions about this Privacy Policy, please contact us at support@gmail.com',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: txtS,
                        height: 1.6)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSection(BuildContext context, String title, String body,
      bool dark, Color txtP, Color txtS, Color cardBg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 6,
              height: 20,
              decoration: BoxDecoration(
                  color: AppTheme.providerPrimary,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtP))),
          ]),
          const SizedBox(height: 12),
          Text(body,
              style:
                  TextStyle(fontFamily: 'Poppins', fontSize: 13, color: txtS, height: 1.7)),
        ]),
      ),
    );
  }

  static const List<Map<String, String>> _sections = [
    {
      'title': '1. Information We Collect',
      'body':
          'We collect information you provide directly to us, such as your name, email address, phone number, professional qualifications, and profile photo when you register as a service provider on our platform.\n\nWe also automatically collect certain information when you use our app, including device information, log data, location data (when permitted), and usage analytics to improve our services.'
    },
    {
      'title': '2. How We Use Your Information',
      'body':
          'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Match you with job opportunities from tenants\n• Process payments and send related information\n• Send you technical notices and support messages\n• Respond to your comments and questions\n• Monitor and analyze trends and usage patterns\n• Detect and prevent fraudulent transactions and other illegal activities'
    },
    {
      'title': '3. Information Sharing',
      'body':
          'We share your information with tenants and clients only as necessary to provide services. Your professional profile, ratings, and work history are visible to tenants who can offer you jobs.\n\nWe do not sell your personal information to third parties. We may share data with service providers who assist us in operating the platform, subject to confidentiality agreements.'
    },
    {
      'title': '4. Data Security',
      'body':
          'We implement industry-standard security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes SSL/TLS encryption for data in transit and AES-256 encryption for data at rest.\n\nDespite these measures, no method of transmission over the Internet is 100% secure. We cannot guarantee absolute security.'
    },
    {
      'title': '5. Data Retention',
      'body':
          'We retain your personal information for as long as your account is active or as needed to provide you services. You may request deletion of your account and associated data at any time by contacting our support team.\n\nSome data may be retained for legal compliance, dispute resolution, or enforcement of our agreements even after account deletion.'
    },
    {
      'title': '6. Your Rights',
      'body':
          'You have the right to:\n\n• Access your personal information\n• Correct inaccurate data\n• Request deletion of your data\n• Object to or restrict processing\n• Data portability\n• Withdraw consent at any time\n\nTo exercise these rights, please contact us through the support section of the app.'
    },
    {
      'title': '7. Cookies & Tracking',
      'body':
          'We use cookies and similar tracking technologies to track activity on our app and hold certain information. You can instruct your device to refuse all cookies or to indicate when a cookie is being sent.\n\nWe use analytics tools to understand how our app is used, which helps us improve the user experience for all providers.'
    },
    {
      'title': '8. Changes to This Policy',
      'body':
          'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and sending a push notification or email.\n\nYour continued use of the app after any modifications to the Privacy Policy constitutes your acceptance of the updated policy.'
    },
  ];
}