import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/provider_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  bool _isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;
  Color _cardBg(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkCard : Colors.white;
  Color _surface(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkBackground : AppTheme.surface;
  Color _txtP(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color _txtS(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color _div(BuildContext ctx) =>
      _isDark(ctx) ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final tp = context.watch<ThemeProvider>();
    final dark = _isDark(context);

    return Scaffold(
      backgroundColor: _surface(context),
      body: Column(children: [
        _buildHeader(context, dark),
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _profileCard(context, user, dark),
            const SizedBox(height: 20),

            if (user?.skillCategory != null) ...[
              _skillCard(context, user!, dark),
              const SizedBox(height: 16),
            ],

            // ── Appearance ────────────────────────────────────────────
            _sectionLabel(context, 'Appearance'),
            const SizedBox(height: 8),
            _themeToggleTile(context, tp, dark),
            const SizedBox(height: 16),

            // ── Account ───────────────────────────────────────────────
            _sectionLabel(context, 'Account'),
            const SizedBox(height: 8),
            _section(context, dark, [
              _tile(context, Icons.person_outline_rounded, 'Edit Profile',
                  () => context.go(AppRoutes.providerEditProfile), dark),
              _dividerLine(context),
              _tile(context, Icons.lock_outline_rounded, 'Change Password',
                  () => _changePasswordSheet(context), dark),
              _dividerLine(context),
              _tile(context, Icons.notifications_outlined, 'Notification Settings',
                  () => _showComingSoon(context, 'Notification Settings'), dark),
            ]),
            const SizedBox(height: 16),

            // ── Work ─────────────────────────────────────────────────
            _sectionLabel(context, 'Work'),
            const SizedBox(height: 8),
            _section(context, dark, [
              _tile(context, Icons.star_outline_rounded, 'My Ratings',
                  () => _ratingsDialog(context, user), dark),
              _dividerLine(context),
              _tile(context, Icons.history_rounded, 'Work History',
                  () => context.go(AppRoutes.providerCompleted), dark),
            ]),
            const SizedBox(height: 16),

            // ── About ────────────────────────────────────────────────
            _sectionLabel(context, 'About'),
            const SizedBox(height: 8),
            _section(context, dark, [
              _tile(context, Icons.info_outline_rounded, 'App Version', () {},
                  dark, trailing: _versionBadge(dark)),
              _dividerLine(context),
              _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                  () => context.go(AppRoutes.providerPrivacyPolicy), dark),
              _dividerLine(context),
              _tile(context, Icons.support_agent_outlined, 'Contact Support',
                  () => context.go(AppRoutes.providerContactSupport), dark),
            ]),
            const SizedBox(height: 20),

            _logoutBtn(context, dark),
            const SizedBox(height: 28),
          ]),
        )),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx, bool dark) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: dark
                  ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                  : [AppTheme.providerDark, AppTheme.providerPrimary])),
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => ctx.go(AppRoutes.providerDashboard),
              ),
              const Expanded(
                  child: Text('Settings',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
            ]),
          )),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────
  Widget _profileCard(BuildContext ctx, user, bool dark) {
    final rating = (user?.rating as num?)?.toDouble() ?? 0.0;
    // ✅ Show total completed jobs
    final totalJobs = user?.completedJobs ?? user?.ratingCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF451A03), const Color(0xFF78350F)]
              : [AppTheme.providerDark, AppTheme.providerPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.providerPrimary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(children: [
        _avatar(user),
        const SizedBox(width: 16),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.fullName ?? 'Provider',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(user?.email ?? '',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            _badge(Icons.star_rounded, rating.toStringAsFixed(1),
                const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            // ✅ Replaced "jobs" with "Total Completed Jobs"
            _badge(Icons.work_outline_rounded, '$totalJobs Job', Colors.white),
          ]),
        ])),
      ]),
    );
  }

  Widget _avatar(user) {
    final url = user?.profilePhoto as String?;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(url),
          backgroundColor: Colors.white.withOpacity(0.2),
          onBackgroundImageError: (_, __) {});
    }
    return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(user?.initials ?? 'P',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white)));
  }

  Widget _badge(IconData icon, String text, Color iconColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      );

  // ── Skill summary card ────────────────────────────────────────────────
  Widget _skillCard(BuildContext ctx, user, bool dark) {
    // ✅ Show total completed jobs in card too
    final totalJobs = user?.completedJobs ?? user?.ratingCount ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _cardBg(ctx),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.providerPrimary.withOpacity(dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.engineering_outlined,
                color: AppTheme.providerPrimary, size: 20)),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.skillCategory ?? '',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _txtP(ctx))),
          if (user.experience != null)
            Text('${user.experience} yrs experience  ·  $totalJobs total completed jobs',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, color: _txtS(ctx))),
        ])),
      ]),
    );
  }

  // ── Theme toggle tile ─────────────────────────────────────────────────
  Widget _themeToggleTile(BuildContext ctx, ThemeProvider tp, bool dark) =>
      Container(
        decoration: BoxDecoration(
            color: _cardBg(ctx),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ]),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppTheme.providerPrimary.withOpacity(dark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  tp.isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                  color: AppTheme.providerPrimary,
                  size: 19)),
          title: Text('Theme',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _txtP(ctx))),
          subtitle: Text(tp.isDark ? 'Dark mode' : 'Light mode',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12, color: _txtS(ctx))),
          trailing: GestureDetector(
            onTap: tp.toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: tp.isDark ? AppTheme.providerPrimary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(15)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                alignment: tp.isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                        tp.isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                        size: 13,
                        color: tp.isDark ? AppTheme.providerPrimary : Colors.amber)),
              ),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );

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
                  color: AppTheme.providerPrimary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined,
                  color: AppTheme.providerPrimary, size: 32),
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
                    backgroundColor: AppTheme.providerPrimary,
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

  // ── Change Password ───────────────────────────────────────────────────
  void _changePasswordSheet(BuildContext ctx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obsOld = true, obsNew = true, obsConf = true;
    final dark = _isDark(ctx);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (bsCtx, setState) {
          bool saving = false;
          return Container(
            decoration: BoxDecoration(
              color: _cardBg(ctx),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(bsCtx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              _sheetHandle(dark),
              const SizedBox(height: 16),
              Row(children: [
                Text('Change Password',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _txtP(ctx))),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.close_rounded, color: _txtS(ctx)),
                    onPressed: () => Navigator.pop(bsCtx)),
              ]),
              const SizedBox(height: 16),
              _passField(currentCtrl, 'Current Password', obsOld,
                  () => setState(() => obsOld = !obsOld), dark, ctx),
              const SizedBox(height: 12),
              _passField(newCtrl, 'New Password', obsNew,
                  () => setState(() => obsNew = !obsNew), dark, ctx),
              const SizedBox(height: 12),
              _passField(confirmCtrl, 'Confirm New Password', obsConf,
                  () => setState(() => obsConf = !obsConf), dark, ctx),
              const SizedBox(height: 20),
              _submitButton(
                  ctx,
                  dark,
                  saving
                      ? null
                      : () async {
                          final current = currentCtrl.text.trim();
                          final newPass = newCtrl.text.trim();
                          final confirm = confirmCtrl.text.trim();
                          if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                            _snack(ctx, 'All fields are required', AppTheme.statusInactive);
                            return;
                          }
                          if (newPass.length < 6) {
                            _snack(ctx, 'Password must be at least 6 characters',
                                AppTheme.statusInactive);
                            return;
                          }
                          if (newPass != confirm) {
                            _snack(ctx, 'Passwords do not match', AppTheme.statusInactive);
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            await ctx.read<AuthService>().changePassword(
                                currentPassword: current, newPassword: newPass);
                            if (ctx.mounted) {
                              Navigator.pop(bsCtx);
                              _snack(ctx, 'Password updated successfully',
                                  AppTheme.statusCompleted);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              _snack(ctx, 'Error: $e', AppTheme.statusInactive);
                            }
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  saving ? 'Updating...' : 'Update Password'),
            ])),
          );
        },
      ),
    );
  }

  // ── Ratings dialog ────────────────────────────────────────────────────
  void _ratingsDialog(BuildContext ctx, user) {
    final rating = (user?.rating as num?)?.toDouble() ?? 0.0;
    // ✅ Total completed jobs
    final totalJobs = user?.completedJobs ?? user?.ratingCount ?? 0;
    final dark = _isDark(ctx);

    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        backgroundColor: _cardBg(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('My Ratings',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _txtP(ctx))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF451A03), const Color(0xFF78350F)]
                      : [AppTheme.providerDark, AppTheme.providerPrimary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => Icon(
                          i < rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 24))),
              const SizedBox(height: 6),
              // ✅ "Total Completed Jobs" label
              Text('Based on $totalJobs total completed jobs',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8))),
            ]),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: Text('Close',
                  style: TextStyle(fontFamily: 'Poppins', color: _txtS(ctx))))
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Widget _logoutBtn(BuildContext ctx, bool dark) => GestureDetector(
        onTap: () async {
          final ok = await showDialog<bool>(
            context: ctx,
            builder: (d) => AlertDialog(
              backgroundColor: _cardBg(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text('Logout',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: _txtP(ctx))),
              content: Text('Are you sure you want to logout?',
                  style: TextStyle(fontFamily: 'Poppins', color: _txtS(ctx))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(d, false),
                    child: Text('Cancel',
                        style: TextStyle(fontFamily: 'Poppins', color: _txtS(ctx)))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(d, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusInactive,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text('Logout',
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                ),
              ],
            ),
          );
          if (ok == true && ctx.mounted) await ctx.read<AuthService>().logout();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark
                ? AppTheme.statusInactive.withOpacity(0.1)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.statusInactive.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: AppTheme.statusInactive.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.statusInactive, size: 20)),
            const SizedBox(width: 14),
            const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Logout',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.statusInactive)),
              Text('Sign out of your account',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.statusInactive)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.statusInactive, size: 14),
          ]),
        ),
      );

  // ── Layout helpers ────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext ctx, String t) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(t.toUpperCase(),
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _txtS(ctx)))));

  Widget _section(BuildContext ctx, bool dark, List<Widget> tiles) => Container(
        decoration: BoxDecoration(
            color: _cardBg(ctx),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ]),
        child: Column(children: tiles),
      );

  Widget _tile(BuildContext ctx, IconData icon, String label,
          VoidCallback onTap, bool dark,
          {Widget? trailing}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppTheme.providerPrimary.withOpacity(dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.providerPrimary, size: 19)),
        title: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _txtP(ctx))),
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _txtS(ctx)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _dividerLine(BuildContext ctx) =>
      Divider(height: 1, indent: 62, endIndent: 14, color: _div(ctx));

  Widget _versionBadge(bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppTheme.providerPrimary.withOpacity(dark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(AppConstants.appVersion,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.providerPrimary)),
      );

  Widget _fieldLabel(BuildContext ctx, String label) => Text(label,
      style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _txtS(ctx)));

  Widget _sheetHandle(bool dark) => Center(
      child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: dark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2))));

  InputDecoration _inputDeco(
          BuildContext ctx, String hint, IconData icon, bool dark) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Poppins', color: _txtS(ctx)),
        filled: true,
        fillColor: dark ? AppTheme.darkInput : AppTheme.surface,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.providerPrimary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div(ctx))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div(ctx))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.providerPrimary, width: 1.5)),
      );

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      bool dark, BuildContext ctx,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP(ctx)),
      decoration: _inputDeco(ctx, hint, icon, dark),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint, bool obscure,
      VoidCallback toggle, bool dark, BuildContext ctx) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP(ctx)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Poppins', color: _txtS(ctx)),
        filled: true,
        fillColor: dark ? AppTheme.darkInput : AppTheme.surface,
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 18, color: AppTheme.providerPrimary),
        suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: _txtS(ctx)),
            onPressed: toggle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div(ctx))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div(ctx))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.providerPrimary, width: 1.5)),
      ),
    );
  }

  Widget _submitButton(
          BuildContext ctx, bool dark, VoidCallback? onPressed, String label) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.providerPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: onPressed == null
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(label,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
        ),
      );

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}