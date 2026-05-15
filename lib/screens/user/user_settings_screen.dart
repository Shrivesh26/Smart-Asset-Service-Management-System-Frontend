import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  bool _isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
  Color _surface(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color _card(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkCard : Colors.white;
  Color _txtP(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color _txtS(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color _div(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final tp = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final dark = _isDark(context);

    return Scaffold(
      backgroundColor: _surface(context),
      body: Column(children: [
        _buildHeader(context, dark),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card
                _buildProfileCard(context, user, dark),
                const SizedBox(height: 26),

                // Appearance
                _sectionLabel(context, 'Appearance'),
                const SizedBox(height: 10),
                _buildThemeToggle(context, tp, dark),
                const SizedBox(height: 20),

                // Account
                _sectionLabel(context, 'Account'),
                const SizedBox(height: 10),
                _buildSectionCard(context, dark, [
                  _buildTile(context,
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      subtitle: 'Update name, phone and photo',
                      dark: dark,
                      onTap: () =>
                          context.go(AppRoutes.userEditProfile)),
                  _divider(context),
                  _buildTile(context,
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      subtitle: 'Manage your delivery locations',
                      dark: dark,
                      onTap: () => _showSavedAddressesSheet(context)),
                  _divider(context),
                  _buildTile(context,
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      subtitle: 'Update your account password',
                      dark: dark,
                      onTap: () =>
                          _showChangePasswordSheet(context)),
                ]),
                const SizedBox(height: 20),

                // Support
                _sectionLabel(context, 'Support'),
                const SizedBox(height: 10),
                _buildSectionCard(context, dark, [
                  _buildTile(context,
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      subtitle: 'Common questions and guides',
                      dark: dark,
                      onTap: () =>
                          context.go(AppRoutes.userHelpFaq)),
                  _divider(context),
                  _buildTile(context,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Contact Us',
                      subtitle: 'Reach our support team',
                      dark: dark,
                      onTap: () => _showContactSheet(context)),
                ]),
                const SizedBox(height: 20),

                // About
                _sectionLabel(context, 'About'),
                const SizedBox(height: 10),
                _buildSectionCard(context, dark, [
                  _buildTile(context,
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      subtitle: AppConstants.appVersion,
                      dark: dark,
                      trailing: _badge(AppConstants.appVersion, dark),
                      onTap: () {}),
                  _divider(context),
                  _buildTile(context,
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      subtitle: 'How we handle your data',
                      dark: dark,
                      onTap: () =>
                          context.go(AppRoutes.userPrivacyPolicy)),
                ]),
                const SizedBox(height: 24),

                // Logout
                _buildLogoutButton(context, dark, auth),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 4),
              Text('Manage your account and preferences.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.78),
                    height: 1.4,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────
  Widget _buildProfileCard(
      BuildContext context, dynamic user, bool dark) {
    final url = user?.profilePhoto as String?;
    final hasPhoto = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: () => context.go(AppRoutes.userEditProfile),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [const Color(0xFF0D3B28), const Color(0xFF1A6640)]
                : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.userPrimary.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.18),
              backgroundImage:
                  hasPhoto ? NetworkImage(url!) : null,
              onBackgroundImageError: hasPhoto ? (_, __) {} : null,
              child: !hasPhoto
                  ? Text(user?.initials ?? 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(user?.email ?? '',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.78)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if ((user?.phone?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(user!.phone!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.72))),
                ],
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_outlined,
                color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }

  // ── Theme toggle ───────────────────────────────────────────────────────
  Widget _buildThemeToggle(
      BuildContext context, ThemeProvider tp, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: _card(context),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.userPrimary
                .withOpacity(dark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            tp.isDark
                ? Icons.dark_mode_rounded
                : Icons.wb_sunny_rounded,
            color: AppTheme.userPrimary,
            size: 20,
          ),
        ),
        title: Text('App Theme',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _txtP(context),
            )),
        subtitle: Text(
            tp.isDark ? 'Dark mode active' : 'Light mode active',
            style: TextStyle(fontSize: 12, color: _txtS(context))),
        trailing: GestureDetector(
          onTap: tp.toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 54,
            height: 30,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tp.isDark
                  ? AppTheme.userPrimary
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              alignment: tp.isDark
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
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
                  color: tp.isDark
                      ? AppTheme.userPrimary
                      : Colors.amber,
                ),
              ),
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // ── Section card ───────────────────────────────────────────────────────
  Widget _buildSectionCard(
      BuildContext context, bool dark, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(dark ? 0.2 : 0.04),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.userPrimary
              .withOpacity(dark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.userPrimary, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _txtP(context),
          )),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: _txtS(context))),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: _txtS(context)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _divider(BuildContext context) => Divider(
      height: 1, indent: 66, endIndent: 14, color: _div(context));

  Widget _badge(String text, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.userPrimary
            .withOpacity(dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.userPrimary,
          )),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: _txtS(context),
          )),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────
  Widget _buildLogoutButton(
      BuildContext context, bool dark, AuthService auth) {
    return GestureDetector(
      onTap: () => _confirmLogout(context, auth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark
              ? AppTheme.statusInactive.withOpacity(0.12)
              : const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppTheme.statusInactive.withOpacity(0.22)),
        ),
        child: Row(children: [
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
                Text('Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusInactive,
                    )),
                SizedBox(height: 2),
                Text('Sign out of your account',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.statusInactive)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppTheme.statusInactive, size: 14),
        ]),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthService auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: _txtP(context))),
        content: Text('Are you sure you want to sign out?',
            style:
                TextStyle(color: _txtS(context), height: 1.45)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Cancel',
                  style:
                      TextStyle(color: _txtS(context)))),
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
    if (ok == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FEATURE SHEETS
  // ══════════════════════════════════════════════════════════════════════

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _UserChangePasswordSheet(isDark: _isDark(context)),
    );
  }

  void _showSavedAddressesSheet(BuildContext context) {
    final dark = _isDark(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedAddressesSheet(isDark: dark),
    );
  }

  void _showContactSheet(BuildContext context) {
    final dark = _isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(isDark: dark),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  CHANGE PASSWORD SHEET
// ══════════════════════════════════════════════════════════════════════
class _UserChangePasswordSheet extends StatefulWidget {
  const _UserChangePasswordSheet({required this.isDark});
  final bool isDark;

  @override
  State<_UserChangePasswordSheet> createState() =>
      _UserChangePasswordSheetState();
}

class _UserChangePasswordSheetState
    extends State<_UserChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obsOld = true, _obsNew = true, _obsConf = true;
  bool _isSaving = false;

  Color get _bg =>
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
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _handle(),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Text('Change Password',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _txtP)),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: _txtS),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Choose a strong password of at least 6 characters.',
                style: TextStyle(fontSize: 13, color: _txtS)),
            const SizedBox(height: 20),
            _passField(_currentCtrl, 'Current Password', _obsOld,
                () => setState(() => _obsOld = !_obsOld)),
            const SizedBox(height: 12),
            _passField(_newCtrl, 'New Password', _obsNew,
                () => setState(() => _obsNew = !_obsNew)),
            const SizedBox(height: 12),
            _passField(_confirmCtrl, 'Confirm New Password', _obsConf,
                () => setState(() => _obsConf = !_obsConf)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.userPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : const Text('Update Password',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _passField(TextEditingController ctrl, String label, bool obs,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obs,
      style: TextStyle(color: _txtP),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _txtS, fontSize: 13),
        filled: true,
        fillColor: _fill,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppTheme.userPrimary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obs ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _txtS,
            size: 20,
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.userPrimary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Future<void> _submit() async {
    final m = ScaffoldMessenger.of(context);
    if (_currentCtrl.text.trim().isEmpty) {
      _err(m, 'Enter your current password.');
      return;
    }
    if (_newCtrl.text.trim().length < 6) {
      _err(m, 'New password must be at least 6 characters.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _err(m, 'Passwords do not match.');
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
        m.showSnackBar(SnackBar(
          content: const Text('Password changed successfully.'),
          backgroundColor: AppTheme.statusCompleted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        _err(m,
            context.read<AuthService>().error ?? 'Failed to change password.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _err(ScaffoldMessengerState m, String msg) =>
      m.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
}

// ══════════════════════════════════════════════════════════════════════
//  SAVED ADDRESSES SHEET
// ══════════════════════════════════════════════════════════════════════
class _SavedAddressesSheet extends StatefulWidget {
  const _SavedAddressesSheet({required this.isDark});
  final bool isDark;

  @override
  State<_SavedAddressesSheet> createState() =>
      _SavedAddressesSheetState();
}

class _SavedAddressesSheetState extends State<_SavedAddressesSheet> {
  final _ctrl = TextEditingController();
  bool _adding = false;

  late List<SavedAddressModel> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = List<SavedAddressModel>.from(
      context.read<AuthService>().currentUser?.savedAddresses ?? const [],
    );
  }

  Color get _bg =>
      widget.isDark ? AppTheme.darkCard : Colors.white;
  Color get _fill =>
      widget.isDark ? AppTheme.darkInput : const Color(0xFFF5F5F5);
  Color get _txtP =>
      widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _border =>
      widget.isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    await context.read<AuthService>().updateProfile({
      'savedAddresses': _addresses.map((address) => address.toJson()).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: Text('Saved Addresses',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _txtP)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: _txtS),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
        const SizedBox(height: 14),

        // Address list
        ..._addresses.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.userPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppTheme.userPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _txtP)),
                    const SizedBox(height: 2),
                    Text(a.display,
                        style: TextStyle(
                            fontSize: 12, color: _txtS),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: AppTheme.statusInactive, size: 20),
                onPressed: () async {
                  setState(() => _addresses.removeAt(i));
                  await _persist();
                },
              ),
            ]),
          );
        }),

        // Add new address inline
        if (_adding) ...[
          TextField(
            controller: _ctrl,
            style: TextStyle(color: _txtP, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter full address',
              hintStyle: TextStyle(color: _txtS, fontSize: 13),
              filled: true,
              fillColor: _fill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _adding = false;
                    _ctrl.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _txtS,
                  side: BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  if (_ctrl.text.trim().isEmpty) return;
                  setState(() {
                    _addresses.add(SavedAddressModel(
                      label: 'Address ${_addresses.length + 1}',
                      street: _ctrl.text.trim(),
                      isDefault: _addresses.isEmpty,
                    ));
                    _adding = false;
                    _ctrl.clear();
                  });
                  await _persist();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.userPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save'),
              ),
            ),
          ]),
        ] else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _adding = true),
              icon: const Icon(Icons.add_location_alt_outlined,
                  size: 18),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.userPrimary,
                side: const BorderSide(color: AppTheme.userPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  CONTACT SHEET
// ══════════════════════════════════════════════════════════════════════
class _ContactSheet extends StatelessWidget {
  const _ContactSheet({required this.isDark});
  final bool isDark;

  Color get _bg => isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _fill =>
      isDark ? AppTheme.darkInput : const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: Text('Contact Us',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _txtP)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: _txtS),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
        const SizedBox(height: 16),
        _contactRow(Icons.email_outlined, 'Email',
            'support@gmail.com'),
        const SizedBox(height: 10),
        _contactRow(Icons.phone_outlined, 'Phone', '+91 98000 00000'),
        const SizedBox(height: 10),
        _contactRow(
            Icons.access_time_outlined, 'Hours', 'Mon–Sat, 9am–6pm'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.userPrimary.withOpacity(isDark ? 0.15 : 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.userPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Our team typically responds within 2 business hours.',
                style: TextStyle(
                    fontSize: 12,
                    color: _txtS,
                    height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.userPrimary
                .withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: AppTheme.userPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _txtS)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _txtP)),
        ]),
      ]),
    );
  }
}
