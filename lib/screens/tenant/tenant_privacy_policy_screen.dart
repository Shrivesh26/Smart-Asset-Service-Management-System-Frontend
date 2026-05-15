import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../utils/app_theme.dart';

// ── Data models ─────────────────────────────────────────────────────────────
class _PolicySection {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

// ── Screen ───────────────────────────────────────────────────────────────────
class TenantPrivacyPolicyScreen extends StatelessWidget {
  const TenantPrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'April 2025';

  static const _sections = [
    _PolicySection(
      icon: Icons.info_outline_rounded,
      title: 'Overview',
      body:
          'SmartAsset Service ("we", "us", or "our") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and associated services.\n\nBy using the app, you agree to the terms of this policy. If you do not agree, please discontinue use immediately.',
    ),
    _PolicySection(
      icon: Icons.data_usage_outlined,
      title: 'Information We Collect',
      body:
          '• Personal identifiers: name, email address, phone number.\n'
          '• Business information: business name, subdomain, type, and address.\n'
          '• Profile photo (optional, provided by you).\n'
          '• Device information: device type, OS version, and app version.\n'
          '• Usage data: features used, pages visited, and time spent in the app.\n'
          '• Communication data: messages or feedback you send to our support team.',
    ),
    _PolicySection(
      icon: Icons.build_circle_outlined,
      title: 'How We Use Your Information',
      body:
          'We use the collected information to:\n\n'
          '• Create and manage your tenant account.\n'
          '• Provide and maintain our services.\n'
          '• Personalise your experience and business workspace.\n'
          '• Communicate updates, security alerts, and support messages.\n'
          '• Analyse usage patterns to improve the app.\n'
          '• Comply with applicable laws and regulations.',
    ),
    _PolicySection(
      icon: Icons.share_outlined,
      title: 'Information Sharing',
      body:
          'We do not sell your personal data. We may share information with:\n\n'
          '• Service providers who assist with app hosting, analytics, and communication (bound by confidentiality agreements).\n'
          '• Law enforcement or regulatory bodies when required by law.\n'
          '• Successors in the event of a merger, acquisition, or business transfer (with advance notice to you).',
    ),
    _PolicySection(
      icon: Icons.lock_outline_rounded,
      title: 'Data Security',
      body:
          'We implement industry-standard measures to protect your data:\n\n'
          '• All data in transit is encrypted using TLS 1.2+.\n'
          '• Data at rest is encrypted using AES-256.\n'
          '• Access to production databases is restricted to authorised personnel only.\n'
          '• Regular security audits and vulnerability assessments are conducted.\n\n'
          'No system is completely secure. If you believe your account has been compromised, contact us immediately.',
    ),
    _PolicySection(
      icon: Icons.storage_outlined,
      title: 'Data Retention',
      body:
          'We retain your personal data for as long as your account remains active or as required by law. If you delete your account:\n\n'
          '• Most data is removed within 30 days.\n'
          '• Certain records (e.g., transaction history) may be retained for up to 7 years for legal and accounting purposes.',
    ),
    _PolicySection(
      icon: Icons.person_outline_rounded,
      title: 'Your Rights',
      body:
          'Depending on your jurisdiction, you may have the right to:\n\n'
          '• Access the personal data we hold about you.\n'
          '• Correct inaccurate data.\n'
          '• Request deletion of your data ("right to be forgotten").\n'
          '• Restrict or object to certain processing.\n'
          '• Data portability (receive your data in a machine-readable format).\n\n'
          'To exercise any of these rights, email us at privacy@smartasset.app.',
    ),
    _PolicySection(
      icon: Icons.cookie_outlined,
      title: 'Cookies & Tracking',
      body:
          'Our mobile app does not use browser cookies. We may use lightweight analytics SDKs to understand usage patterns. No personally identifiable information is shared with analytics providers beyond a pseudonymous device identifier.',
    ),
    _PolicySection(
      icon: Icons.child_care_outlined,
      title: "Children's Privacy",
      body:
          'Our services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If we become aware that a child has provided us with personal data, we will delete it promptly.',
    ),
    _PolicySection(
      icon: Icons.update_outlined,
      title: 'Changes to This Policy',
      body:
          'We may update this Privacy Policy from time to time. When we do, we will revise the "Last Updated" date at the top of this screen. For material changes, we will notify you via in-app notification or email at least 14 days before the change takes effect.',
    ),
    _PolicySection(
      icon: Icons.contact_mail_outlined,
      title: 'Contact Us',
      body:
          'If you have any questions about this Privacy Policy or our data practices, please reach out:\n\n'
          'Email: support@gmail.com'
    ),
  ];

  // ── Theme helpers ─────────────────────────────────────────────────────
  bool _isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
  Color _cardBg(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkCard : Colors.white;
  Color _surface(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkBackground : AppTheme.background;
  Color _txtP(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color _txtS(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);

    return Scaffold(
      backgroundColor: _surface(context),
      body: Column(
        children: [
          _buildHeader(context, dark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Intro banner
                  _buildIntroBanner(context, dark),
                  const SizedBox(height: 20),
                  // Policy sections
                  ...List.generate(_sections.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildSection(context, _sections[i], dark),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go(AppRoutes.tenantSettings),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Last updated: $_lastUpdated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'v1.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Intro banner ──────────────────────────────────────────────────────
  Widget _buildIntroBanner(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.tenantPrimary.withOpacity(dark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.tenantPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.tenantPrimary.withOpacity(dark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppTheme.tenantPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy matters to us',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txtP(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'This document explains what data we collect, why we collect it, and how you can control it. We believe in full transparency.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _txtS(context),
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

  // ── Policy section card ───────────────────────────────────────────────
  Widget _buildSection(
      BuildContext context, _PolicySection section, bool dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary
                      .withOpacity(dark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon,
                    color: AppTheme.tenantPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txtP(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Section body
          Text(
            section.body,
            style: TextStyle(
              fontSize: 13,
              color: _txtS(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}