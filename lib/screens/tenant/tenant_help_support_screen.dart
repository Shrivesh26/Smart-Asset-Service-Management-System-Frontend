import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

// ── Data models ─────────────────────────────────────────────────────────────
class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _ContactItem {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback onTap;
}

// ── Screen ───────────────────────────────────────────────────────────────────
class TenantHelpSupportScreen extends StatefulWidget {
  const TenantHelpSupportScreen({super.key});

  @override
  State<TenantHelpSupportScreen> createState() =>
      _TenantHelpSupportScreenState();
}

class _TenantHelpSupportScreenState extends State<TenantHelpSupportScreen> {
  int? _expandedIndex;
  final _feedbackCtrl = TextEditingController();
  bool _feedbackSent = false;

  // ── Static data ───────────────────────────────────────────────────────
  static const _faqs = [
    _FaqItem(
      question: 'How do I update my business profile?',
      answer:
          'Go to Settings → Edit Profile. You can update your business name, address, subdomain, and business type. Tap Save after making changes.',
    ),
    _FaqItem(
      question: 'How do I change my password?',
      answer:
          'Navigate to Settings → Change Password. Enter your current password, then set a new password of at least 6 characters.',
    ),
    _FaqItem(
      question: 'How do I manage my service providers?',
      answer:
          'In the dashboard, navigate to the Providers section. You can invite, view, and manage all service providers assigned to your business.',
    ),
    _FaqItem(
      question: 'Can I customize my subdomain?',
      answer:
          'Yes! Go to Settings → Edit Profile → Business Info. Update the subdomain field and save. Note that subdomains must be unique and may take a few minutes to propagate.',
    ),
    _FaqItem(
      question: 'How do I view customer bookings?',
      answer:
          'Visit the Bookings tab in your dashboard. You can filter by date, provider, or status to find specific bookings.',
    ),
    _FaqItem(
      question: 'What happens if I forget my password?',
      answer:
          'On the login screen, tap "Forgot Password" and enter your registered email. You will receive a reset link within a few minutes.',
    ),
    _FaqItem(
      question: 'How is my data protected?',
      answer:
          'All your data is encrypted in transit (TLS) and at rest (AES-256). We never sell your personal data to third parties. Read our Privacy Policy for full details.',
    ),
  ];

  // ── Theme helpers ─────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : AppTheme.background;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _divColor =>
      _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _fill => _isDark ? AppTheme.darkInput : Colors.grey.shade100;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact cards
                  _sectionLabel('Contact Us'),
                  const SizedBox(height: 10),
                  _buildContactGrid(),
                  const SizedBox(height: 24),

                  // FAQs
                  _sectionLabel('Frequently Asked Questions'),
                  const SizedBox(height: 10),
                  _buildFaqList(),
                  const SizedBox(height: 24),

                  // Send feedback
                  _sectionLabel('Send Feedback'),
                  const SizedBox(height: 10),
                  _buildFeedbackCard(),
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
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go(AppRoutes.tenantSettings),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "We're here to help you succeed.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contact cards grid ────────────────────────────────────────────────
  Widget _buildContactGrid() {
    final contacts = [
      _ContactItem(
        icon: Icons.email_outlined,
        title: 'Email Support',
        value: 'support@gmail.com',
        actionLabel: 'Copy',
        onTap: () {
          Clipboard.setData(
              const ClipboardData(text: 'support@gmail.com'));
          _showSnack('Email copied!', AppTheme.statusCompleted);
        },
      ),
      _ContactItem(
        icon: Icons.access_time_outlined,
        title: 'Working Hours',
        value: 'Mon–Sat\n9:00 AM – 6:00 PM',
        actionLabel: '',
        onTap: () {},
      ),
      _ContactItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Live Chat',
        value: 'In-app chat available\nduring business hours',
        actionLabel: '',
        onTap: () {},
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: contacts.map((c) => _buildContactCard(c)).toList(),
    );
  }

  Widget _buildContactCard(_ContactItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.tenantPrimary
                    .withOpacity(_isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon,
                  color: AppTheme.tenantPrimary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _txtP,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                item.value,
                style: TextStyle(fontSize: 11, color: _txtS, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ list ──────────────────────────────────────────────────────────
  Widget _buildFaqList() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: List.generate(_faqs.length, (index) {
            final faq = _faqs[index];
            final isExpanded = _expandedIndex == index;
            final isLast = index == _faqs.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() =>
                      _expandedIndex = isExpanded ? null : index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq.question,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isExpanded
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isExpanded
                                  ? AppTheme.tenantPrimary
                                  : _txtP,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isExpanded
                                ? AppTheme.tenantPrimary
                                : _txtS,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      faq.answer,
                      style: TextStyle(
                        fontSize: 13,
                        color: _txtS,
                        height: 1.55,
                      ),
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
                if (!isLast)
                  Divider(height: 1, indent: 16, color: _divColor),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Feedback card ─────────────────────────────────────────────────────
  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _feedbackSent
          ? Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.statusCompleted.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppTheme.statusCompleted, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  'Feedback Sent!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thank you for your feedback. Our team will review it shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _txtS,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () =>
                      setState(() => _feedbackSent = false),
                  child: const Text('Send Another'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.tenantPrimary
                            .withOpacity(_isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.feedback_outlined,
                          color: AppTheme.tenantPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Share your experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txtP,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _feedbackCtrl,
                  maxLines: 4,
                  style: TextStyle(color: _txtP, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Tell us how we can improve your experience...',
                    hintStyle:
                        TextStyle(color: _txtS, fontSize: 13),
                    filled: true,
                    fillColor: _fill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Send Feedback'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.tenantPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _submitFeedback() {
    if (_feedbackCtrl.text.trim().isEmpty) {
      _showSnack(
          'Please enter your feedback.', AppTheme.statusInactive);
      return;
    }
    // TODO: wire to API
    setState(() => _feedbackSent = true);
    _feedbackCtrl.clear();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _sectionLabel(String title) {
    final _txtS =
        _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: _txtS,
        ),
      ),
    );
  }
}