import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderShell extends StatefulWidget {
  final Widget child;
  const ProviderShell({super.key, required this.child});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  late final AnimationController _menuCtrl;

  // ── Dark helpers ───────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _sidebarBg =>
      _isDark ? const Color(0xFF140C00) : Colors.white;
  Color get _navBg =>
      _isDark ? const Color(0xFF1A1000) : Colors.white;
  Color get _txtP =>
      _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? Colors.white.withOpacity(0.60) : AppTheme.textSecondary;
  Color get _div =>
      _isDark ? Colors.white.withOpacity(0.10) : AppTheme.dividerColor;
  Color get _activeBg =>
      AppTheme.providerPrimary.withOpacity(_isDark ? 0.18 : 0.10);

  static const _navItems = [
    _NavItem(AppRoutes.providerDashboard, Icons.dashboard_outlined,
        Icons.dashboard_rounded, 'Dashboard', 0),
    _NavItem(AppRoutes.providerServices, Icons.home_repair_service_outlined,
        Icons.home_repair_service_rounded, 'My Services', 1),
    _NavItem(AppRoutes.providerCompleted, Icons.check_circle_outline_rounded,
        Icons.check_circle_rounded, 'Completed', 2),
    _NavItem(AppRoutes.providerNotifications, Icons.notifications_outlined,
        Icons.notifications_rounded, 'Alerts', 3),
    _NavItem(AppRoutes.providerSettings, Icons.settings_outlined,
        Icons.settings_rounded, 'Settings', 4),
  ];

  int _indexFor(String loc) {
    for (int i = 0; i < _navItems.length; i++) {
      if (loc.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  void _navigate(int idx) => context.go(_navItems[idx].route);

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final curIdx = _indexFor(loc);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor:
            _isDark ? AppTheme.darkBackground : const Color(0xFFF7F4F0),
        body: Row(children: [
          _buildSidebar(context, loc),
          Expanded(child: widget.child),
        ]),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(curIdx),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DESKTOP SIDEBAR
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildSidebar(BuildContext context, String loc) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 72 : 248,
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _div, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(children: [
          // Collapse toggle
          Align(
            alignment:
                _isCollapsed ? Alignment.center : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: IconButton(
                tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                icon: Icon(
                  _isCollapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: _txtS,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
              ),
            ),
          ),

          // Profile header
          if (!_isCollapsed)
            _buildExpandedHeader(user)
          else
            _buildCollapsedAvatar(user),

          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: _isCollapsed ? 6 : 10, vertical: 4),
              children: _navItems
                  .asMap()
                  .entries
                  .map((e) =>
                      _sidebarItem(context: context, location: loc, item: e.value, idx: e.key))
                  .toList(),
            ),
          ),

          Divider(height: 1, color: _div),

          // Logout
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _isCollapsed ? 6 : 10, vertical: 8),
            child: _buildLogoutTile(context),
          ),

          // Footer
          if (!_isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('v${AppConstants.appVersion}',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: _txtS)),
                  Text('SmartAsset',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _txtS,
                      )),
                ],
              ),
            )
        ]),
      ),
    );
  }

  // ── Expanded profile card ──────────────────────────────────────────────
  Widget _buildExpandedHeader(dynamic user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF451A03), const Color(0xFF78350F)]
              : [AppTheme.providerDark, AppTheme.providerPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.providerPrimary.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _buildRoleAvatar(
          user: user,
          radius: 28,
          borderColor: Colors.white.withOpacity(0.45),
          initialsColor: Colors.white,
          bgColor: AppTheme.providerPrimary.withOpacity(0.35),
        ),
        const SizedBox(height: 10),
        Text(
          user?.fullName ?? 'Provider',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          (user?.skillCategory?.isNotEmpty ?? false)
              ? user!.skillCategory!
              : (user?.email ?? ''),
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white.withOpacity(0.8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _badge(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              label: user?.rating?.toStringAsFixed(1) ?? '0.0'),
          const SizedBox(width: 8),
          _badge(
              icon: Icons.work_outline_rounded,
              iconColor: Colors.white,
              label: '${user?.completedJobs ?? 0} jobs'),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Service Provider',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        ),
      ]),
    );
  }

  Widget _badge(
      {required IconData icon,
      required Color iconColor,
      required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
      ]),
    );
  }

  // ── Collapsed avatar ───────────────────────────────────────────────────
  Widget _buildCollapsedAvatar(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Tooltip(
        message: user?.fullName ?? 'Provider',
        child: _buildRoleAvatar(
          user: user,
          radius: 20,
          borderColor: AppTheme.providerPrimary.withOpacity(0.6),
          initialsColor: AppTheme.providerPrimary,
          bgColor: AppTheme.providerPrimary.withOpacity(0.15),
        ),
      ),
    );
  }

  // ── Shared role avatar ─────────────────────────────────────────────────
  Widget _buildRoleAvatar({
    required dynamic user,
    required double radius,
    required Color borderColor,
    required Color initialsColor,
    required Color bgColor,
  }) {
    final url = user?.profilePhoto as String?;
    final hasPhoto = url != null && url.isNotEmpty;
    final initials = (user?.initials as String?) ?? 'P';

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: hasPhoto ? NetworkImage(url!) : null,
        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
        child: !hasPhoto
            ? Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: radius * 0.68,
                  fontWeight: FontWeight.w800,
                  color: initialsColor,
                ),
              )
            : null,
      ),
    );
  }

  // ── Sidebar nav item ───────────────────────────────────────────────────
  Widget _sidebarItem({
    required BuildContext context,
    required String location,
    required _NavItem item,
    required int idx,
  }) {
    final isActive = location.startsWith(item.route);

    if (_isCollapsed) {
      return Tooltip(
        message: item.label,
        preferBelow: false,
        child: GestureDetector(
          onTap: () => _navigate(idx),
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? _activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(
                isActive ? item.filledIcon : item.outlineIcon,
                size: 22,
                color: isActive ? AppTheme.providerPrimary : _txtS,
              ),
              if (isActive)
                Positioned(
                  right: 4,
                  child: Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.providerPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _navigate(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? _activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: AppTheme.providerPrimary.withOpacity(0.2))
              : null,
        ),
        child: Row(children: [
          Icon(
            isActive ? item.filledIcon : item.outlineIcon,
            size: 22,
            color: isActive ? AppTheme.providerPrimary : _txtS,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppTheme.providerPrimary : _txtP,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.providerPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Logout tile ────────────────────────────────────────────────────────
  Widget _buildLogoutTile(BuildContext context) {
    if (_isCollapsed) {
      return Tooltip(
        message: 'Logout',
        child: GestureDetector(
          onTap: () => _confirmLogout(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.statusInactive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded,
                color: AppTheme.statusInactive, size: 20),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.statusInactive.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(children: [
          Icon(Icons.logout_rounded,
              color: AppTheme.statusInactive, size: 20),
          SizedBox(width: 12),
          Text('Logout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.statusInactive,
              )),
        ]),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: _isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _txtP)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(
                fontFamily: 'Poppins',
                color: _txtS,
                height: 1.45)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Cancel',
                  style:
                      TextStyle(fontFamily: 'Poppins', color: _txtS))),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthService>().logout();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MOBILE BOTTOM NAV
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(int curIdx) {
    return Container(
      decoration: BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _div, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(_isDark ? 0.4 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: _navItems.map((item) {
              final sel = curIdx == item.allIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigate(item.allIdx),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.providerPrimary.withOpacity(
                                  _isDark ? 0.2 : 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          sel ? item.filledIcon : item.outlineIcon,
                          size: 22,
                          color: sel
                              ? AppTheme.providerPrimary
                              : _txtS,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: sel
                              ? AppTheme.providerPrimary
                              : _txtS,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route, label;
  final IconData outlineIcon, filledIcon;
  final int allIdx;
  const _NavItem(this.route, this.outlineIcon, this.filledIcon,
      this.label, this.allIdx);
}