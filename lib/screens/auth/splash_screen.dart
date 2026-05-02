import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _mainCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authService = context.read<AuthService>();
    if (authService.isLoggedIn) {
      final role = authService.currentRole;
      switch (role) {
        case 'admin':
          context.go(AppRoutes.adminDashboard);
          break;
        case 'tenant':
          context.go(AppRoutes.tenantDashboard);
          break;
        case 'provider':
          context.go(AppRoutes.providerDashboard);
          break;
        case 'user':
          context.go(AppRoutes.userDashboard);
          break;
        default:
          context.go(AppRoutes.login);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash always uses a rich gradient — not affected by light/dark theme
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1A73E8)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Decorative layered circles ──────────────────────────────
              ..._buildDecoCircles(),

              // ── Main content ─────────────────────────────────────────────
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _mainCtrl,
                        builder: (_, __) => Opacity(
                          opacity: _fadeAnim.value,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: _buildCenterContent(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Bottom loading ──────────────────────────────────────
                  AnimatedBuilder(
                    animation: _mainCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _fadeAnim.value,
                      child: _buildBottom(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Decorative background circles ─────────────────────────────────────────
  List<Widget> _buildDecoCircles() => [
        _circle(top: -80, right: -50, size: 260,
            opacity: 0.07, delay: 0),
        _circle(top: 80, right: -10, size: 140,
            opacity: 0.05, delay: 200),
        _circle(top: 200, left: -60, size: 180,
            opacity: 0.04, delay: 100),
        _circle(bottom: 100, right: -30, size: 160,
            opacity: 0.05, delay: 300),
        _circle(bottom: -60, left: -40, size: 200,
            opacity: 0.06, delay: 150),
      ];

  Widget _circle({
    double? top, double? bottom, double? left, double? right,
    required double size,
    required double opacity,
    required int delay,
  }) =>
      Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity),
          ),
        ),
      );

  // ── Center logo + text ────────────────────────────────────────────────────
  Widget _buildCenterContent() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Logo box with glow ────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15 * _pulseAnim.value),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: child,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/sasms-logo.png',
                width: 64,
                height: 64,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── App name ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Smart Asset & Service\nManagement System',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tag pill ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              'Manage  •  Track  •  Booking',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      );

  // ── Bottom loading indicator ──────────────────────────────────────────────
  Widget _buildBottom() => Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          children: [
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) =>
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    final offset = (i * 0.33).clamp(0.0, 0.66);
                    final t      = ((_pulseCtrl.value - offset) * 3.0)
                        .clamp(0.0, 1.0);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3 + 0.7 * t),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
}