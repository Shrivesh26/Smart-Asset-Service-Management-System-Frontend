import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../utils/app_theme.dart';

// ── Data model ──────────────────────────────────────────────────────────────
class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

class _FaqCategory {
  const _FaqCategory(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
}

// ── FAQ data ────────────────────────────────────────────────────────────────
const _faqCategories = [
  _FaqCategory(
    'Getting Started',
    Icons.play_circle_outline_rounded,
    [
      _FaqItem(
        'How do I create an account?',
        'Download the app and tap "Sign Up". Enter your name, email address, and create a password. You will receive a verification email — click the link inside to activate your account.',
      ),
      _FaqItem(
        'How do I browse available services?',
        'Tap the "Marketplace" tab at the bottom of the screen. You can filter services by category, location, or price range to find exactly what you need.',
      ),
      _FaqItem(
        'Is the app free to use?',
        'Yes, browsing and booking services through the app is completely free for users. You only pay the service fee shown on each listing at the time of booking.',
      ),
    ],
  ),
  _FaqCategory(
    'Bookings',
    Icons.event_note_outlined,
    [
      _FaqItem(
        'How do I place a booking?',
        'Open any service, tap "Book Service", select your preferred date and time slot, describe your requirement, and confirm the booking. You will receive a confirmation notification once the provider accepts.',
      ),
      _FaqItem(
        'Can I book a service for the same day?',
        'This depends on the individual service. Services that show "Same-day" availability support last-minute bookings. Others require advance scheduling — the maximum advance days are shown on the service card.',
      ),
      _FaqItem(
        'How do I view my active bookings?',
        'Go to the "My Bookings" or "Order History" section from the bottom navigation bar or the dashboard. All your past and upcoming bookings are listed there.',
      ),
      _FaqItem(
        'What happens after I submit a booking?',
        'Your booking enters "Requested" status. The business reviews it and assigns a suitable provider. You will be notified at each stage — when a provider is assigned, when they accept, and when the service is in progress or completed.',
      ),
    ],
  ),
  _FaqCategory(
    'Cancellations & Refunds',
    Icons.cancel_outlined,
    [
      _FaqItem(
        'Can I cancel my booking?',
        'You can cancel a booking only while it is in "Requested" or "Finding Provider" status, and only if the service allows pre-assignment cancellation (shown as "Cancellable" on the service card). Once a provider has been assigned, cancellation is no longer available.',
      ),
      _FaqItem(
        'How do I cancel a booking?',
        'Open the booking from your order list, scroll to the bottom, and tap "Cancel Booking". Confirm in the dialog that appears. The status will update to "Cancelled" immediately.',
      ),
      _FaqItem(
        'Will I get a refund if I cancel?',
        'Refund eligibility depends on the service policy. Services marked "Cancellable" allow free cancellation before a provider is assigned. Services marked "Non-refundable" do not offer refunds. Check the service listing before booking.',
      ),
    ],
  ),
  _FaqCategory(
    'Payments',
    Icons.payments_outlined,
    [
      _FaqItem(
        'What payment methods are accepted?',
        'Accepted payment methods vary by business. Common options include UPI, credit/debit cards, net banking, and cash on service completion. The available methods are shown during checkout.',
      ),
      _FaqItem(
        'When am I charged for a service?',
        'Payment timing depends on the business — some charge at booking, others after service completion. The payment terms are displayed on the service detail page.',
      ),
      _FaqItem(
        'How do I view my cost breakdown?',
        'Open any booking from your order list. Scroll down to see a full cost breakdown including the service fee, provider fee, asset charges, and total amount.',
      ),
    ],
  ),
  _FaqCategory(
    'Ratings & Feedback',
    Icons.star_outline_rounded,
    [
      _FaqItem(
        'How do I rate a completed service?',
        'After a service is marked "Completed", open the booking and scroll to the "Your Rating" card. Tap "Rate This Service", select your star rating, optionally add a comment, and tap Submit.',
      ),
      _FaqItem(
        'Can I edit my rating after submitting?',
        'Ratings cannot be edited after submission. Please take a moment to reflect before you submit your review.',
      ),
      _FaqItem(
        'Do ratings affect the provider?',
        'Yes. Provider ratings are averaged and displayed publicly on service listings. Honest feedback helps other users and encourages providers to maintain high service quality.',
      ),
    ],
  ),
  _FaqCategory(
    'Account & Privacy',
    Icons.manage_accounts_outlined,
    [
      _FaqItem(
        'How do I update my profile information?',
        'Go to Settings → Edit Profile. You can update your name, phone number, and address. Tap the avatar to change your profile photo, then tap "Save Changes".',
      ),
      _FaqItem(
        'How do I change my password?',
        'Go to Settings → Change Password. Enter your current password followed by your new password and confirm it.',
      ),
      _FaqItem(
        'How is my personal data used?',
        'Your data is used only to provide and improve the services offered through the app. We do not sell your data to third parties. Read our Privacy Policy for full details.',
      ),
      _FaqItem(
        'How do I delete my account?',
        'To request account deletion, please contact our support team via the "Contact Support" option below. We will process your request within 7 business days.',
      ),
    ],
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────
class UserHelpFaqScreen extends StatefulWidget {
  const UserHelpFaqScreen({super.key});

  @override
  State<UserHelpFaqScreen> createState() => _UserHelpFaqScreenState();
}

class _UserHelpFaqScreenState extends State<UserHelpFaqScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtered categories ─────────────────────────────────────────────────
  List<_FaqCategory> get _filtered {
    if (_query.isEmpty) return _faqCategories;
    final q = _query.toLowerCase();
    return _faqCategories
        .map((cat) {
          final items = cat.items
              .where((item) =>
                  item.question.toLowerCase().contains(q) ||
                  item.answer.toLowerCase().contains(q))
              .toList();
          return items.isEmpty ? null : _FaqCategory(cat.title, cat.icon, items);
        })
        .whereType<_FaqCategory>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filtered;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 20),

                // Quick contact bar
                _buildQuickContact(),
                const SizedBox(height: 24),

                if (categories.isEmpty)
                  _buildEmptySearch()
                else
                  ...categories.map((cat) => _buildCategory(cat)),

                const SizedBox(height: 32),

                // Still need help
                _buildStillNeedHelp(),
                const SizedBox(height: 28),
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
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => context.go(AppRoutes.userSettings),
                ),
                const Expanded(
                  child: Text(
                    'Help & FAQ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Find answers to the most common questions about using the app.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        style: TextStyle(color: _txtP, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search questions…',
          hintStyle: TextStyle(color: _txtS, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: _txtS, size: 22),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  child: Icon(Icons.close_rounded, color: _txtS, size: 20),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Quick contact ───────────────────────────────────────────────────────
  Widget _buildQuickContact() {
    return Row(children: [
      Expanded(
        child: _contactChip(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Live Chat',
          onTap: () {},
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _contactChip(
          icon: Icons.email_outlined,
          label: 'Email Us',
          onTap: () {},
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _contactChip(
          icon: Icons.phone_outlined,
          label: 'Call Us',
          onTap: () {},
        ),
      ),
    ]);
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.userPrimary.withOpacity(_isDark ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.userPrimary.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.userPrimary, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.userPrimary,
              )),
        ]),
      ),
    );
  }

  // ── FAQ category ────────────────────────────────────────────────────────
  Widget _buildCategory(_FaqCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
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
            // Category header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.userPrimary
                        .withOpacity(_isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon,
                      color: AppTheme.userPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  cat.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
              ]),
            ),
            Divider(height: 1, color: _divider),

            // Items
            ...cat.items.asMap().entries.map((entry) {
              final isLast = entry.key == cat.items.length - 1;
              return _buildFaqTile(entry.value, isLast);
            }),
          ],
        ),
      ),
    );
  }

  // ── FAQ tile (expandable) ───────────────────────────────────────────────
  Widget _buildFaqTile(_FaqItem item, bool isLast) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: AppTheme.userPrimary.withOpacity(0.05),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppTheme.userPrimary,
        collapsedIconColor: _txtS,
        title: Text(
          item.question,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _txtP,
            height: 1.4,
          ),
        ),
        children: [
          if (!isLast)
            Divider(height: 1, color: _divider.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            item.answer,
            style: TextStyle(
              fontSize: 13,
              color: _txtS,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty search ────────────────────────────────────────────────────────
  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.search_off_rounded, size: 52, color: _txtS),
        const SizedBox(height: 14),
        Text('No results for "$_query"',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _txtP)),
        const SizedBox(height: 6),
        Text('Try different keywords or contact our support team.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _txtS, height: 1.4)),
      ]),
    );
  }

  // ── Still need help ─────────────────────────────────────────────────────
  Widget _buildStillNeedHelp() {
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
      child: Column(children: [
        const Icon(Icons.support_agent_rounded,
            color: Colors.white, size: 38),
        const SizedBox(height: 12),
        const Text(
          'Still need help?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Our support team is available Mon–Sat, 9 AM – 6 PM.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text('Contact Support'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.userPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}