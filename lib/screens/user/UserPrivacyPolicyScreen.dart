import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../utils/app_theme.dart';

// ── Data model ──────────────────────────────────────────────────────────────
class _PolicySection {
  const _PolicySection(this.title, this.icon, this.body);
  final String title;
  final IconData icon;
  final String body;
}

// ── Policy content ───────────────────────────────────────────────────────────
const _lastUpdated = 'Last updated: 1 May 2025';

const _sections = [
  _PolicySection(
    'Introduction',
    Icons.info_outline_rounded,
    'Welcome. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our mobile application and related services ("Platform"). By using the Platform you agree to the practices described in this policy.\n\nWe are committed to safeguarding your privacy and handling your data responsibly. If you have questions, please contact us at privacy@example.com.',
  ),
  _PolicySection(
    'Information We Collect',
    Icons.folder_open_outlined,
    'We collect the following categories of information:\n\n• Account Information — name, email address, phone number, and profile photo provided during registration or profile updates.\n\n• Location Data — city, state, street address, and pincode used to match you with nearby service providers.\n\n• Booking Details — service selections, preferred dates and times, problem descriptions, and communication with providers.\n\n• Payment Information — transaction records. Full payment card details are processed directly by our payment partners and are never stored on our servers.\n\n• Device Information — device model, operating system, app version, and unique device identifiers for security and diagnostics.\n\n• Usage Data — pages visited, features used, tap events, and session durations, collected to improve the app experience.',
  ),
  _PolicySection(
    'How We Use Your Information',
    Icons.tune_outlined,
    'We use the information we collect to:\n\n• Create and maintain your account and authenticate your identity.\n\n• Match you with appropriate service providers and facilitate bookings.\n\n• Send booking confirmations, status updates, and support notifications.\n\n• Process payments and maintain financial records as required by law.\n\n• Personalise your in-app experience, including service recommendations.\n\n• Detect fraud, investigate complaints, and enforce our Terms of Service.\n\n• Improve the Platform through usage analytics and user feedback.\n\n• Comply with legal obligations and respond to lawful government requests.',
  ),
  _PolicySection(
    'Sharing Your Information',
    Icons.share_outlined,
    'We do not sell, rent, or trade your personal information to third parties for marketing purposes.\n\nWe share your information only in the following circumstances:\n\n• Service Providers — We share your name, contact details, and booking information with the assigned service provider so they can fulfil your request.\n\n• Business Operators (Tenants) — The business whose service you booked receives booking and contact details necessary to manage the service.\n\n• Payment Processors — Transaction data is shared with our payment gateway partners who are independently certified to handle financial data securely.\n\n• Legal Requirements — We may disclose information when required by law, court order, or to protect the rights and safety of users and third parties.\n\n• Business Transfers — In the event of a merger or acquisition, your data may be transferred to the successor entity under equivalent privacy protections.',
  ),
  _PolicySection(
    'Data Retention',
    Icons.history_outlined,
    'We retain your personal information for as long as your account is active or as needed to provide services.\n\nBooking records are retained for a minimum of 3 years to comply with applicable financial and consumer protection regulations.\n\nIf you request account deletion, we will anonymise or delete your personal data within 30 days, except where retention is required by law or is necessary to resolve disputes or enforce agreements.\n\nAnonymised and aggregated data (which cannot identify you) may be retained indefinitely for analytical purposes.',
  ),
  _PolicySection(
    'Data Security',
    Icons.lock_outline_rounded,
    'We implement industry-standard technical and organisational measures to protect your data against unauthorised access, alteration, disclosure, or destruction. These include:\n\n• TLS/SSL encryption for all data transmitted between your device and our servers.\n\n• Encrypted storage of sensitive fields in our databases.\n\n• Role-based access controls limiting employee access to personal data.\n\n• Regular security audits and vulnerability assessments.\n\nNo method of transmission over the internet or electronic storage is completely secure. While we strive to protect your data, we cannot guarantee absolute security.',
  ),
  _PolicySection(
    'Your Rights',
    Icons.verified_user_outlined,
    'Depending on your jurisdiction, you may have the following rights regarding your personal data:\n\n• Access — Request a copy of the personal data we hold about you.\n\n• Correction — Ask us to correct inaccurate or incomplete information.\n\n• Deletion — Request that we delete your personal data, subject to legal retention requirements.\n\n• Portability — Receive your data in a structured, machine-readable format.\n\n• Objection — Object to certain types of processing, including direct marketing.\n\n• Withdrawal of Consent — Where processing is based on consent, you may withdraw it at any time without affecting the lawfulness of prior processing.\n\nTo exercise any of these rights, contact us at privacy@example.com. We will respond within 30 days.',
  ),
  _PolicySection(
    'Cookies & Tracking',
    Icons.cookie_outlined,
    'Our mobile app does not use browser cookies. However, we use similar technologies such as:\n\n• Analytics SDKs — to understand aggregate usage patterns and improve app performance.\n\n• Crash Reporting Tools — to detect and resolve technical issues.\n\n• Push Notification Tokens — to deliver timely booking and service updates to your device.\n\nYou can disable push notifications at any time through your device settings. Note that this will prevent you from receiving booking status updates in real time.',
  ),
  _PolicySection(
    'Third-Party Services',
    Icons.open_in_new_rounded,
    'The Platform integrates with third-party services including payment gateways, cloud storage providers, and analytics platforms. These services have their own privacy policies and we encourage you to review them.\n\nWe are not responsible for the privacy practices of third-party services. We select partners who meet high standards of data protection and require them to handle your data securely and in accordance with applicable law.',
  ),
  _PolicySection(
    'Children\'s Privacy',
    Icons.child_care_outlined,
    'Our Platform is not directed at individuals under the age of 18. We do not knowingly collect personal information from minors.\n\nIf you believe that a minor has provided us with personal information without parental consent, please contact us immediately at privacy@example.com and we will take steps to delete that information.',
  ),
  _PolicySection(
    'Changes to This Policy',
    Icons.update_outlined,
    'We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. When we make material changes, we will notify you through the app or via email at least 14 days before the changes take effect.\n\nYour continued use of the Platform after the effective date of any changes constitutes your acceptance of the updated policy. We encourage you to review this page periodically.',
  ),
  _PolicySection(
    'Contact Us',
    Icons.mail_outline_rounded,
    'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please reach out to us:\n\nEmail: kashyapsam733@gmail.com\nPhone: +91 98000 00000\nAddress: Atlas Copco, 6th floor, Ashoka Plaza, Viman Nagar, Pune, Maharashtra – 411001, India\n\nWe take all privacy concerns seriously and aim to respond within 5 business days.',
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────
class UserPrivacyPolicyScreen extends StatefulWidget {
  const UserPrivacyPolicyScreen({super.key});

  @override
  State<UserPrivacyPolicyScreen> createState() =>
      _UserPrivacyPolicyScreenState();
}

class _UserPrivacyPolicyScreenState extends State<UserPrivacyPolicyScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _divider =>
      _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
              children: [
                // Hero banner
                _buildHeroBanner(),
                const SizedBox(height: 24),

                // Table of contents
                _buildTableOfContents(),
                const SizedBox(height: 24),

                // Policy sections
                ..._sections.asMap().entries.map((e) =>
                    _buildSection(e.key + 1, e.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.go(AppRoutes.userSettings),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _lastUpdated,
                    style:
                        TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Hero banner ─────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.privacy_tip_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy matters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We are transparent about how your data is collected and used.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Table of contents ───────────────────────────────────────────────────
  Widget _buildTableOfContents() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.userPrimary
                    .withOpacity(_isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.list_alt_outlined,
                  color: AppTheme.userPrimary, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'Contents',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _txtP,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: _divider),
          const SizedBox(height: 10),
          ..._sections.asMap().entries.map((e) {
            final num = e.key + 1;
            final sec = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.userPrimary
                        .withOpacity(_isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$num',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.userPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  sec.title,
                  style: TextStyle(fontSize: 13, color: _txtS),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ── Policy section card ──────────────────────────────────────────────────
  Widget _buildSection(int number, _PolicySection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.userPrimary
                      .withOpacity(_isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon,
                    color: AppTheme.userPrimary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$number. ${section.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: _divider),
            const SizedBox(height: 12),

            // Body text — renders bullet points correctly
            ..._parseBody(section.body),
          ],
        ),
      ),
    );
  }

  // ── Body text parser ────────────────────────────────────────────────────
  // Splits on newlines and renders bullet lines (•) with indented layout,
  // and blank lines as small spacing.
  List<Widget> _parseBody(String body) {
    final lines = body.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.userPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: TextStyle(
                    fontSize: 13,
                    color: _txtS,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13,
              color: _txtS,
              height: 1.6,
            ),
          ),
        ));
      }
    }

    return widgets;
  }
}