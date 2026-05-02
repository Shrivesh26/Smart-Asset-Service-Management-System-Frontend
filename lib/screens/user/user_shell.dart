import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class UserShell extends StatefulWidget {
  final Widget child;
  const UserShell({super.key, required this.child});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;

  late final AnimationController _menuCtrl;

  // ── Dark-mode helpers ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _drawerBg =>
      _isDark ? const Color(0xFF0F1A14) : Colors.white;
  Color get _navBg => _isDark ? const Color(0xFF111A15) : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _divider =>
      _isDark ? const Color(0xFF1E2E25) : AppTheme.dividerColor;
  Color get _activeBg =>
      _isDark ? AppTheme.userPrimary.withOpacity(0.15) : AppTheme.userLight;

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

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.userDashboard)) return 0;
    if (location.startsWith(AppRoutes.userMarketplace) ||
        location.startsWith(AppRoutes.userStores)) return 1;
    if (location.startsWith(AppRoutes.userOrderHistory)) return 2;
    if (location.startsWith(AppRoutes.userNotifications)) return 3;
    if (location.startsWith(AppRoutes.userSettings)) return 4;
    return 0;
  }

  void _onTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.userDashboard);
        break;
      case 1:
        context.go(AppRoutes.userMarketplace);
        break;
      case 2:
        context.go(AppRoutes.userOrderHistory);
        break;
      case 3:
        context.go(AppRoutes.userNotifications);
        break;
      case 4:
        context.go(AppRoutes.userSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIdx = _locationToIndex(location);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor:
            _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5),
        body: Row(children: [
          _buildSidebar(context),
          Expanded(child: widget.child),
        ]),
      );
    }

    // Mobile
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context, currentIdx),
    );
  }

  // ── Desktop Sidebar ────────────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final location = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 72 : 240,
      decoration: BoxDecoration(
        color: _drawerBg,
        border: Border(right: BorderSide(color: _divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(children: [
          // ── Collapse toggle ──────────────────────────────────────
          Align(
            alignment: _isCollapsed ? Alignment.center : Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: IconButton(
                tooltip: _isCollapsed ? 'Expand' : 'Collapse',
                icon: Icon(
                  _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: _txtS,
                  size: 22,
                ),
                onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
              ),
            ),
          ),

          // ── User profile header ──────────────────────────────────
          if (!_isCollapsed)
            _buildExpandedHeader(user)
          else
            _buildCollapsedAvatar(user),

          const SizedBox(height: 8),

          // ── Nav items ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _sidebarItem(
                  context: context,
                  location: location,
                  icon: Icons.home_outlined,
                  filledIcon: Icons.home_rounded,
                  label: 'Home',
                  route: AppRoutes.userDashboard,
                ),
                _sidebarItem(
                  context: context,
                  location: location,
                  icon: Icons.grid_view_outlined,
                  filledIcon: Icons.dashboard_customize_rounded,
                  label: 'Services',
                  route: AppRoutes.userMarketplace,
                ),
                _sidebarItem(
                  context: context,
                  location: location,
                  icon: Icons.receipt_long_outlined,
                  filledIcon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  route: AppRoutes.userOrderHistory,
                ),
                _sidebarItem(
                  context: context,
                  location: location,
                  icon: Icons.notifications_outlined,
                  filledIcon: Icons.notifications_rounded,
                  label: 'Alerts',
                  route: AppRoutes.userNotifications,
                ),
                _sidebarItem(
                  context: context,
                  location: location,
                  icon: Icons.settings_outlined,
                  filledIcon: Icons.settings_rounded,
                  label: 'Settings',
                  route: AppRoutes.userSettings,
                ),
                const SizedBox(height: 8),
                Divider(color: _divider),
                // Logout
                _buildLogoutTile(context),
              ],
            ),
          ),

          // ── Footer ──────────────────────────────────────────────
          if (!_isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
              child: Column(children: [
                Divider(color: _divider),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('v${AppConstants.appVersion}',
                        style: TextStyle(fontSize: 11, color: _txtS)),
                    Text('SmartAsset',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _txtS,
                        )),
                  ],
                ),
              ]),
            )
        ]),
      ),
    );
  }

  // ── Expanded header card ───────────────────────────────────────────────
  Widget _buildExpandedHeader(dynamic user) {
    final url = user?.profilePhoto as String?;
    final hasPhoto = url != null && url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.userPrimary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: hasPhoto ? NetworkImage(url!) : null,
              onBackgroundImageError: hasPhoto ? (_, __) {} : null,
              child: !hasPhoto
                  ? Text(
                      user?.initials ?? 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
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
            user?.email ?? '',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.78),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Customer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsed avatar only ──────────────────────────────────────────────
  Widget _buildCollapsedAvatar(dynamic user) {
    final url = user?.profilePhoto as String?;
    final hasPhoto = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.userPrimary.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.userPrimary.withOpacity(0.15),
          backgroundImage: hasPhoto ? NetworkImage(url!) : null,
          onBackgroundImageError: hasPhoto ? (_, __) {} : null,
          child: !hasPhoto
              ? Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.userPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ── Sidebar item ───────────────────────────────────────────────────────
  Widget _sidebarItem({
    required BuildContext context,
    required String location,
    required IconData icon,
    required IconData filledIcon,
    required String label,
    required String route,
  }) {
    final isActive = location.startsWith(route);

    return Tooltip(
      message: _isCollapsed ? label : '',
      preferBelow: false,
      child: GestureDetector(
        onTap: () => context.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? _activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: AppTheme.userPrimary.withOpacity(0.25))
                : null,
          ),
          child: Row(
            mainAxisAlignment: _isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              if (_isCollapsed && isActive)
                Container(
                  width: 3,
                  height: 22,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.userPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                isActive ? filledIcon : icon,
                color: isActive ? AppTheme.userPrimary : _txtS,
                size: 22,
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive ? AppTheme.userPrimary : _txtP,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout tile ────────────────────────────────────────────────────────
  Widget _buildLogoutTile(BuildContext context) {
    return Tooltip(
      message: _isCollapsed ? 'Logout' : '',
      child: GestureDetector(
        onTap: () => _confirmLogout(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: _isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const Icon(Icons.logout_rounded,
                  color: AppTheme.statusInactive, size: 22),
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                const Text('Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.statusInactive,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: _drawerBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700, color: _txtP)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: _txtS, height: 1.45)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Cancel', style: TextStyle(color: _txtS))),
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
    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }

  // ── Mobile Bottom Nav ──────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, int currentIdx) {
    return Container(
      decoration: BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(children: [
            _navItem(context, 0, currentIdx, Icons.home_outlined,
                Icons.home_rounded, 'Home'),
            _navItem(context, 1, currentIdx, Icons.grid_view_outlined,
                Icons.dashboard_customize_rounded, 'Services'),
            _navItem(context, 2, currentIdx, Icons.receipt_long_outlined,
                Icons.receipt_long_rounded, 'Orders'),
            _navItem(context, 3, currentIdx, Icons.notifications_outlined,
                Icons.notifications_rounded, 'Alerts'),
            _navItem(context, 4, currentIdx, Icons.settings_outlined,
                Icons.settings_rounded, 'Settings'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    int currentIdx,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = index == currentIdx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTab(context, index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? _activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? filledIcon : outlineIcon,
              size: 22,
              color: isSelected ? AppTheme.userPrimary : _txtS,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppTheme.userPrimary : _txtS,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}