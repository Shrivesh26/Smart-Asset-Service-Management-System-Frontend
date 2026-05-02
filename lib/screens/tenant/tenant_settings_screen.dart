import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class TenantSettingsScreen extends StatelessWidget {
  const TenantSettingsScreen({super.key});

  // ── Theme helpers ──────────────────────────────────────────────────────
  bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;
  Color _cardBg(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkCard : Colors.white;
  Color _surface(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkBackground : AppTheme.background;
  Color _txtP(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color _txtS(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color _divColor(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final tp = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final dark = _isDark(context);

    return Scaffold(
      backgroundColor: _surface(context),
      body: Column(
        children: [
          _buildHeader(context, dark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ─────────────────────────────────────
                  _buildProfileCard(context, user, dark),
                  const SizedBox(height: 28),

                  // ── Appearance ───────────────────────────────────────
                  _sectionLabel(context, 'Appearance'),
                  const SizedBox(height: 10),
                  _buildThemeToggle(context, tp, dark),
                  const SizedBox(height: 20),

                  // ── Account ──────────────────────────────────────────
                  _sectionLabel(context, 'Account'),
                  const SizedBox(height: 10),
                  _buildSectionCard(context, dark, [
                    _buildTile(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      subtitle: 'Update your personal & business info',
                      dark: dark,
                      onTap: () => context.go(AppRoutes.tenantEditProfile),
                    ),
                    _divider(context),
                    _buildTile(
                      context,
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      subtitle: 'Update your account password',
                      dark: dark,
                      onTap: () => _showChangePasswordSheet(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Business Info ─────────────────────────────────────
                  if (user != null) ...[
                    _sectionLabel(context, 'Business Information'),
                    const SizedBox(height: 10),
                    _buildBusinessCard(context, user, dark),
                    const SizedBox(height: 20),
                  ],

                  // ── Preferences ───────────────────────────────────────
                  _sectionLabel(context, 'Preferences'),
                  const SizedBox(height: 10),
                  _buildSectionCard(context, dark, [
                    _buildTile(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Notification Settings',
                      subtitle: 'Manage alerts and reminders',
                      dark: dark,
                      onTap: () {
                        _showComingSoon(context, 'Notification Settings');
                      }, // plug-in route when available
                    ),
                    _divider(context),
                    _buildTile(
                      context,
                      icon: Icons.language_outlined,
                      label: 'Language',
                      subtitle: 'English (Default)',
                      dark: dark,
                      trailing: _badge(context, 'EN', dark),
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────────────
                  _sectionLabel(context, 'About'),
                  const SizedBox(height: 10),
                  _buildSectionCard(context, dark, [
                    _buildTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      subtitle: AppConstants.appVersion,
                      dark: dark,
                      trailing: _badge(context, AppConstants.appVersion, dark),
                      onTap: () {},
                    ),
                    _divider(context),
                    _buildTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      dark: dark,
                      onTap: () => context.go(AppRoutes.tenantPrivacyPolicy),
                    ),
                    _divider(context),
                    _buildTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      subtitle: 'FAQs, contact and issue reporting',
                      dark: dark,
                      onTap: () => context.go(AppRoutes.tenantHelpSupport),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Logout ────────────────────────────────────────────
                  _buildLogoutButton(context, dark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account, business, and preferences.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.78),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, dynamic user, bool dark) {
    final url = user?.profilePhoto as String?;
    return GestureDetector(
      onTap: () => context.go(AppRoutes.tenantEditProfile),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [const Color(0xFF250844), const Color(0xFF4A2085)]
                : [AppTheme.tenantDark, AppTheme.tenantPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tenantPrimary.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.18),
                backgroundImage:
                    (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                onBackgroundImageError:
                    (url != null && url.isNotEmpty) ? (_, __) {} : null,
                child: (url == null || url.isEmpty)
                    ? Text(
                        user?.initials ?? 'T',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Tenant',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tenant Workspace',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit hint
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Business card ──────────────────────────────────────────────────────
  Widget _buildBusinessCard(BuildContext context, dynamic user, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary.withOpacity(dark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined,
                    color: AppTheme.tenantPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Business Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _txtP(context),
                ),
              ),
              // const Spacer(),
              // GestureDetector(
              //   onTap: () => context.go(AppRoutes.tenantEditProfile),
              //   child: Text(
              //     'Edit',
              //     style: TextStyle(
              //       fontSize: 12,
              //       fontWeight: FontWeight.w600,
              //       color: AppTheme.tenantPrimary,
              //     ),
              //   ),
              // ),
            ],
          ),
          Divider(height: 20, color: _divColor(context)),
          _infoRow(context, 'Business',
              (user?.businessName?.isNotEmpty ?? false) ? user.businessName : '—'),
          _infoRow(context, 'Subdomain',
              (user?.subdomain?.isNotEmpty ?? false) ? user.subdomain : '—'),
          _infoRow(context, 'Phone',
              (user?.phone?.isNotEmpty ?? false) ? user.phone : '—'),
          _infoRow(context, 'City',
              (user?.city?.isNotEmpty ?? false) ? user.city : '—'),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Theme toggle ───────────────────────────────────────────────────────
  Widget _buildThemeToggle(
      BuildContext context, ThemeProvider tp, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.tenantPrimary.withOpacity(dark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            tp.isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
            color: AppTheme.tenantPrimary,
            size: 20,
          ),
        ),
        title: Text(
          'App Theme',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _txtP(context),
          ),
        ),
        subtitle: Text(
          tp.isDark ? 'Dark mode active' : 'Light mode active',
          style: TextStyle(fontSize: 12, color: _txtS(context)),
        ),
        trailing: GestureDetector(
          onTap: tp.toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 54,
            height: 30,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  tp.isDark ? AppTheme.tenantPrimary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              alignment:
                  tp.isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(
                  tp.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.wb_sunny_rounded,
                  size: 13,
                  color: tp.isDark ? AppTheme.tenantPrimary : Colors.amber,
                ),
              ),
            ),
          ),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, bool dark) {
    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark
              ? AppTheme.statusInactive.withOpacity(0.12)
              : const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppTheme.statusInactive.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.statusInactive.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppTheme.statusInactive, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusInactive,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sign out of your tenant account',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.statusInactive,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.statusInactive, size: 14),
          ],
        ),
      ),
    );
  }

  // ── Change password bottom sheet ───────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        isDark: _isDark(context),
        tenantPrimary: AppTheme.tenantPrimary,
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: _cardBg(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: _txtP(context))),
        content: Text(
          'Are you sure you want to sign out of your tenant account?',
          style: TextStyle(color: _txtS(context), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text('Cancel',
                style: TextStyle(color: _txtS(context))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }

  // ── Layout helpers ─────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: _txtS(context),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, bool dark, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool dark,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.tenantPrimary.withOpacity(dark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.tenantPrimary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _txtP(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: _txtS(context)),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: _txtS(context)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

    // ── Coming Soon popup ─────────────────────────────────────────────────
  void _showComingSoon(BuildContext ctx, String feature) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: _cardBg(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined,
                  color: AppTheme.tenantPrimary, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Coming Soon!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _txtP(ctx))),
            const SizedBox(height: 8),
            Text(
                '$feature is currently under development and will be available in the next update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _txtS(ctx),
                    height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(d),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tenantPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Got it',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
      height: 1, indent: 64, endIndent: 14, color: _divColor(context));

  Widget _badge(BuildContext context, String text, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.tenantPrimary.withOpacity(dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.tenantPrimary,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style:
                  TextStyle(fontSize: 12, color: _txtS(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _txtP(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Change Password Sheet (Stateful) ────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({
    required this.isDark,
    required this.tenantPrimary,
  });

  final bool isDark;
  final Color tenantPrimary;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Color get _cardBg =>
      widget.isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _fill =>
      widget.isDark ? AppTheme.darkInput : const Color(0xFFF5F5F5);
  Color get _border =>
      widget.isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white24
                        : Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _txtP,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: _txtS),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a strong password of at least 6 characters.',
                style: TextStyle(fontSize: 13, color: _txtS, height: 1.4),
              ),
              const SizedBox(height: 20),
              _passwordField(
                controller: _currentCtrl,
                label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 12),
              _passwordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.tenantPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Update Password',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: _txtP),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _txtS, fontSize: 13),
        filled: true,
        fillColor: _fill,
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: widget.tenantPrimary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _txtS,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: widget.tenantPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_currentCtrl.text.trim().isEmpty) {
      _showError(messenger, 'Please enter your current password.');
      return;
    }
    if (_newCtrl.text.trim().length < 6) {
      _showError(messenger, 'New password must be at least 6 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _showError(messenger, 'Passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final ok = await context.read<AuthService>().changePassword(
            currentPassword: _currentCtrl.text.trim(),
            newPassword: _newCtrl.text.trim(),
          );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        _showSuccess(messenger, 'Password changed successfully.');
      } else {
        _showError(
          messenger,
          context.read<AuthService>().error ?? 'Failed to change password.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(messenger, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(ScaffoldMessengerState m, String msg) {
    m.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.statusInactive,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(ScaffoldMessengerState m, String msg) {
    m.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.statusCompleted,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}