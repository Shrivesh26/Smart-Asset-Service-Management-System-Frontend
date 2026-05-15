import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderContactSupportScreen extends StatefulWidget {
  const ProviderContactSupportScreen({super.key});

  @override
  State<ProviderContactSupportScreen> createState() =>
      _ProviderContactSupportScreenState();
}

class _ProviderContactSupportScreenState
    extends State<ProviderContactSupportScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  int _expandedFaq = -1;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _div => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _inputBg => _isDark ? AppTheme.darkInput : const Color(0xFFF9F9F9);

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactCards(),
                const SizedBox(height: 24),
                _sectionLabel('Send Us a Message'),
                const SizedBox(height: 12),
                _buildMessageForm(),
                const SizedBox(height: 24),
                _sectionLabel('Frequently Asked Questions'),
                const SizedBox(height: 12),
                _buildFaqList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _isDark
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
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Support',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text('We\'re here to help you',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70)),
                ],
              )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  const Text('Online',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          )),
    );
  }

  Widget _buildContactCards() {
    final contacts = [
      _ContactItem(
        icon: Icons.email_outlined,
        label: 'Email Support',
        value: 'support@gmail.com',
        color: AppTheme.providerPrimary,
        onTap: () => _copyToClipboard('support@gmail.com', 'Email copied'),
        actionLabel: 'Copy Email',
      ),
      // _ContactItem(
      //   icon: Icons.phone_outlined,
      //   label: 'Call Us',
      //   value: '+91 98000 00000',
      //   color: const Color(0xFF059669),
      //   onTap: () => _copyToClipboard('+9198000 00000', 'Phone copied'),
      //   actionLabel: 'Copy Number',
      // ),
      _ContactItem(
        icon: Icons.access_time_rounded,
        label: 'Support Hours',
        value: 'Mon–Sat, 9am–6pm IST',
        color: const Color(0xFFF59E0B),
        onTap: null,
        actionLabel: '',
      ),
    ];

    return Column(
      children: contacts
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildContactCard(c),
              ))
          .toList(),
    );
  }

  Widget _buildContactCard(_ContactItem c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: c.color.withOpacity(_isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(c.icon, color: c.color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _txtS)),
          const SizedBox(height: 2),
          Text(c.value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _txtP)),
        ])),
        if (c.onTap != null)
          GestureDetector(
            onTap: c.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: c.color.withOpacity(_isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(c.actionLabel,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.color)),
            ),
          ),
      ]),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.providerPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Describe your issue',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _txtP)),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _msgCtrl,
          maxLines: 5,
          style: TextStyle(fontFamily: 'Poppins', color: _txtP),
          decoration: InputDecoration(
            hintText:
                'Describe your issue in detail. Include any relevant booking IDs, dates, or screenshots...',
            hintStyle: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: _txtS, height: 1.5),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _div)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _div)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.providerPrimary, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.providerPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            label: Text(_sending ? 'Sending...' : 'Send Message',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
            child: Text('Average response time: within 2–4 hours',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: _txtS))),
      ]),
    );
  }

  Widget _buildFaqList() {
    return Container(
      decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: _div, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => _buildFaqItem(i),
      ),
    );
  }

  Widget _buildFaqItem(int i) {
    final isExpanded = _expandedFaq == i;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
                () => _expandedFaq = isExpanded ? -1 : i),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Text(_faqs[i]['q']!,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isExpanded ? AppTheme.providerPrimary : _txtP))),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? AppTheme.providerPrimary : _txtS, size: 20),
                ),
              ]),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.providerPrimary.withOpacity(0.15))),
                child: Text(_faqs[i]['a']!,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: _txtS,
                        height: 1.6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _txtS)),
      );

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please describe your issue before sending.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate API call
    if (!mounted) return;
    setState(() => _sending = false);
    _msgCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: const [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Message sent! We\'ll respond within 2–4 hours.',
            style: TextStyle(fontFamily: 'Poppins')),
      ]),
      backgroundColor: AppTheme.statusCompleted,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _copyToClipboard(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppTheme.providerPrimary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I get assigned to a job?',
      'a':
          'Jobs are assigned by the tenant administrator. Once assigned, you\'ll receive a push notification and the job will appear in your "My Jobs" section. Make sure your notifications are enabled for timely updates.',
    },
    {
      'q': 'How are my ratings calculated?',
      'a':
          'Your rating is the average of all ratings given by tenants after each completed job. Ratings range from 1 to 5 stars. We recommend completing jobs promptly and professionally to maintain a high rating.',
    },
    {
      'q': 'What happens if I can\'t complete a job?',
      'a':
          'If you\'re unable to complete an assigned job, contact the tenant directly and inform your platform administrator as soon as possible. Frequent cancellations may affect your account standing.',
    },
    {
      'q': 'How do I update my skills or profile?',
      'a':
          'Go to Settings → My Skills & Experience to update your skill category, years of experience, and specializations. For profile photo and personal details, use Settings → Edit Profile.',
    },
    {
      'q': 'When will I receive payment for completed jobs?',
      'a':
          'Payment schedules are determined by the tenant organization you work with. Please contact your assigned tenant administrator for payment-related queries. The platform does not directly handle provider payments.',
    },
    {
      'q': 'How do I report a problem with a booking?',
      'a':
          'Use the "Send Us a Message" form above to describe the booking issue, including the booking ID and date. Our support team will investigate and respond within 2–4 business hours.',
    },
  ];
}

class _ContactItem {
  final IconData icon;
  final String label, value, actionLabel;
  final Color color;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.actionLabel,
  });
}