import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _navAnimCtrl;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _navAnimCtrl.dispose();
    super.dispose();
  }

  int _currentIndex(String location) {
    if (location.startsWith(AppRoutes.adminTenants)) return 1;
    if (location.startsWith(AppRoutes.adminSettings)) return 2;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _previousIndex) return;
    _navAnimCtrl.forward(from: 0);
    setState(() => _previousIndex = index);
    switch (index) {
      case 0:
        context.go(AppRoutes.adminDashboard);
        break;
      case 1:
        context.go(AppRoutes.adminTenants);
        break;
      case 2:
        context.go(AppRoutes.adminSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isLoggedIn || auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.adminPrimary),
        ),
      );
    }

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _buildNavItem(
                context,
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                color: AppTheme.adminPrimary,
              ),
              _buildNavItem(
                context,
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.apartment_outlined,
                activeIcon: Icons.apartment_rounded,
                label: 'Tenants',
                color: AppTheme.tenantPrimary,
                badgeCount: 2,
              ),
              _buildNavItem(
                context,
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                color: AppTheme.adminPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
    int badgeCount = 0,
  }) {
    final isActive = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(context, index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey(isActive),
                      color: isActive ? color : AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.statusInactive,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? color : AppTheme.textSecondary,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isActive ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}