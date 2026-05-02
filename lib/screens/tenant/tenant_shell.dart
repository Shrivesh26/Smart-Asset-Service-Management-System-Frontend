import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class TenantShell extends StatefulWidget {
  final Widget child;
  const TenantShell({super.key, required this.child});

  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _drawerOpen = false;
  bool _isCollapsed = false;

  late final AnimationController _menuCtrl;
  late final Animation<double> _menuAnim;

  // ── Dark mode helpers ──────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _drawerBg =>
      _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _navBg =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _txtP =>
      _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _divider =>
      _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;
  Color get _activeBg => _isDark
      ? AppTheme.tenantPrimary.withOpacity(0.15)
      : AppTheme.tenantLight;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _menuAnim =
        CurvedAnimation(parent: _menuCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() => _drawerOpen = isOpen);
    isOpen ? _menuCtrl.forward() : _menuCtrl.reverse();
  }

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.tenantDashboard)) return 0;
    if (location.startsWith(AppRoutes.tenantServices)) return 1;
    if (location.startsWith(AppRoutes.tenantInventory)) return 2;
    if (location.startsWith(AppRoutes.tenantProviders)) return 3;
    if (location.startsWith(AppRoutes.tenantOrders)) return 4;
    if (location.startsWith(AppRoutes.tenantSettings)) return 5;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.tenantDashboard);
        break;
      case 1:
        context.go(AppRoutes.tenantServices);
        break;
      case 2:
        context.go(AppRoutes.tenantInventory);
        break;
      case 3:
        context.go(AppRoutes.tenantProviders);
        break;
      case 4:
        context.go(AppRoutes.tenantOrders);
        break;
      case 5:
        context.go(AppRoutes.tenantSettings);
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
        body: Row(
          children: [
            _buildDesktopSidebar(context),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile — original bottom nav
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: _onDrawerChanged,
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context, currentIdx),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DESKTOP SIDEBAR
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildDesktopSidebar(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 70 : 240,
      color: _drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Collapse toggle
            Align(
              alignment: _isCollapsed
                  ? Alignment.center
                  : Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  _isCollapsed
                      ? Icons.chevron_right
                      : Icons.chevron_left,
                  color: _txtS,
                ),
                onPressed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
              ),
            ),

            // Profile header
            Consumer<AuthService>(
              builder: (_, auth, __) {
                final user = auth.currentUser;
                return _isCollapsed
                    ? _buildCollapsedAvatar(user)
                    : _buildExpandedHeader(user);
              },
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: AppRoutes.tenantDashboard,
                  ),
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.home_repair_service_outlined,
                    label: 'Services',
                    route: AppRoutes.tenantServices,
                  ),
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.inventory_2_outlined,
                    label: 'Inventory',
                    route: AppRoutes.tenantInventory,
                  ),
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.engineering_outlined,
                    label: 'Providers',
                    route: AppRoutes.tenantProviders,
                  ),
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    route: AppRoutes.tenantOrders,
                  ),
                  _sidebarItem(
                    context: context,
                    location: location,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: AppRoutes.tenantSettings,
                  ),
                  const SizedBox(height: 10),
                  Divider(color: _divider),
                  _buildLogoutTile(context),
                ],
              ),
            ),

            // Footer
            if (!_isCollapsed)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(children: [
                  Divider(color: _divider),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('v${AppConstants.appVersion}',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: _txtS)),
                      Text('SmartAsset',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _txtS,
                          )),
                    ],
                  ),
                ]),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Icon(Icons.circle, size: 6, color: _txtS),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  EXPANDED HEADER  — gradient card, photo or role-coloured initials
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildExpandedHeader(dynamic user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tenantPrimary.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ─────────────────────────────────────────────
          _buildRoleAvatar(
            user: user,
            radius: 28,
            borderColor: Colors.white.withOpacity(0.45),
            // When no photo: white initials on role-colour tint
            initialsColor: Colors.white,
            bgColor: AppTheme.tenantPrimary.withOpacity(0.35),
          ),
          const SizedBox(height: 10),

          // Name
          Text(
            user?.fullName ?? 'Tenant',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Business name / email
          Text(
            (user?.businessName?.isNotEmpty ?? false)
                ? user!.businessName!
                : (user?.email ?? ''),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Role badge
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
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  COLLAPSED AVATAR  — role-coloured ring + photo or initials
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCollapsedAvatar(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Tooltip(
        message: user?.fullName ?? 'Tenant',
        child: _buildRoleAvatar(
          user: user,
          radius: 20,
          borderColor: AppTheme.tenantPrimary.withOpacity(0.6),
          // When no photo: tenant-purple initials on light tint
          initialsColor: AppTheme.tenantPrimary,
          bgColor: AppTheme.tenantPrimary.withOpacity(0.15),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  SHARED AVATAR BUILDER
  //  - Shows NetworkImage when profilePhoto is set
  //  - Falls back to initials on a role-coloured background
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildRoleAvatar({
    required dynamic user,
    required double radius,
    required Color borderColor,
    required Color initialsColor,
    required Color bgColor,
  }) {
    final url = user?.profilePhoto as String?;
    final hasPhoto = url != null && url.isNotEmpty;
    final initials = user?.initials as String? ?? 'T';

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: hasPhoto ? NetworkImage(url) : null,
        // Silently swallow load errors so initials show through
        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
        child: !hasPhoto
            ? Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  // scale nicely with avatar size
                  fontSize: radius * 0.68,
                  fontWeight: FontWeight.w800,
                  color: initialsColor,
                ),
              )
            : null,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  SIDEBAR NAV ITEM
  // ══════════════════════════════════════════════════════════════════════
  Widget _sidebarItem({
    required BuildContext context,
    required String location,
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = location.startsWith(route);

    return Tooltip(
      message: _isCollapsed ? label : '',
      child: GestureDetector(
        onTap: () => context.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? _activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: AppTheme.tenantPrimary.withOpacity(0.3))
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
                  height: 24,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Tooltip(
                message: label,
                child: Icon(
                  icon,
                  color: isActive
                      ? AppTheme.tenantPrimary
                      : _txtS,
                ),
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isActive
                          ? AppTheme.tenantPrimary
                          : _txtP,
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

  // ══════════════════════════════════════════════════════════════════════
  //  LOGOUT TILE
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildLogoutTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmLogout(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.symmetric(
          horizontal: _isCollapsed ? 0 : 10,
          vertical: 10,
        ),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: _isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppTheme.statusInactive),
            if (!_isCollapsed) ...[
              const SizedBox(width: 10),
              const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppTheme.statusInactive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  LOGOUT DIALOG
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _drawerBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: _txtP,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: _txtS,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    TextStyle(fontFamily: 'Poppins', color: _txtS)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().logout();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MOBILE BOTTOM NAV  (original, unchanged)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(BuildContext context, int currentIdx) {
    return Container(
      decoration: BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(_isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(children: [
            _navItem(context, 0, currentIdx,
                Icons.dashboard_outlined,
                Icons.dashboard_rounded, 'Home'),
            _navItem(context, 1, currentIdx,
                Icons.home_repair_service_outlined,
                Icons.home_repair_service_rounded, 'Services'),
            _navItem(context, 2, currentIdx,
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded, 'Assets'),
            _navItem(context, 3, currentIdx,
                Icons.engineering_outlined,
                Icons.engineering_rounded, 'Providers'),
            _navItem(context, 4, currentIdx,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded, 'Orders'),
            _navItem(context, 5, currentIdx,
                Icons.settings_outlined,
                Icons.settings_suggest_rounded, 'Settings'),
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
        onTap: () => _onTabTapped(context, index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                size: 22,
                color: isSelected
                    ? AppTheme.tenantPrimary
                    : _txtS,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isSelected
                    ? AppTheme.tenantPrimary
                    : _txtS,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  ANIMATED MENU ↔ CLOSE BUTTON  (unchanged)
// ══════════════════════════════════════════════════════════════════════
class AnimatedMenuButton extends StatelessWidget {
  final Animation<double> animation;
  final bool isOpen;
  final VoidCallback onTap;

  const AnimatedMenuButton({
    super.key,
    required this.animation,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween(begin: 0.25, end: 0.0).animate(anim),
              child:
                  FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isOpen ? Icons.close_rounded : Icons.menu_rounded,
              key: ValueKey(isOpen),
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}