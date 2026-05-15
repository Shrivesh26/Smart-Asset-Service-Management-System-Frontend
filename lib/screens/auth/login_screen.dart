import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = AppConstants.roleTenant;
  bool _obscurePassword = true;

  // ── 3 public SaaS roles ──────────────────────────────────────────────
  final List<Map<String, dynamic>> _roles = [
    {
      'role': AppConstants.roleTenant,
      'label': 'Tenant',
      'icon': Icons.apartment_outlined,
    },
    {
      'role': AppConstants.roleProvider,
      'label': 'Provider',
      'icon': Icons.engineering_outlined,
    },
    {
      'role': AppConstants.roleUser,
      'label': 'User',
      'icon': Icons.person_outline_rounded,
    },
  ];

  // Always derived fresh from current role
  Color get _roleColor => AppTheme.primaryForRole(_selectedRole);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    if (authService.error != null) authService.clearError();

    final success = await authService.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      switch (_selectedRole) {
        case AppConstants.roleTenant:
          context.go(AppRoutes.tenantDashboard);
          break;
        case AppConstants.roleProvider:
          context.go(AppRoutes.providerDashboard);
          break;
        case AppConstants.roleUser:
          context.go(AppRoutes.userDashboard);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildRoleSelector(),
                    const SizedBox(height: 28),
                    _buildLabel('Email Address'),
                    const SizedBox(height: 8),
                    _buildEmailField(),
                    const SizedBox(height: 18),
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(),
                    const SizedBox(height: 6),
                    _buildForgotPassword(),
                    const SizedBox(height: 16),
                    _buildError(),
                    _buildSignInButton(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    if (_selectedRole != AppConstants.roleProvider)
                      _buildRegisterRow()
                    else
                      _buildProviderNote(),
                    const SizedBox(height: 32),
                    _buildAdminPortalLink(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // ── Header — color animates with role ─────────────────────────────────
  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: AppTheme.gradientForRole(_selectedRole),
      ),
      child: Stack(
        children: [
          // 🔵 Background Circles (Splash Style)
          Positioned(
            top: -40,
            right: -30,
            child: _buildCircle(120, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            top: 60,
            right: 80,
            child: _buildCircle(60, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: _buildCircle(140, Colors.white.withOpacity(0.05)),
          ),

          // 🔷 Main Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/sasms-logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 🔥 FIX: Prevent overflow
                      const Expanded(
                        child: Text(
                          'Smart Asset & Service Management System',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16, // reduced for better fit
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back 👋',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to manage your assets, services & bookings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role selector ─────────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign in as',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _roles.map((r) {
            final role = r['role'] as String;
            final isSelected = _selectedRole == role;
            // ✅ Derive colors from role string directly — never from _selectedRole
            final roleColor = AppTheme.primaryForRole(role);
            final roleBg = AppTheme.lightForRole(role);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRole = role;
                    _emailCtrl.clear();
                    _passwordCtrl.clear();
                  });
                  if (context.read<AuthService>().error != null) {
                    context.read<AuthService>().clearError();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.only(
                    right: role != AppConstants.roleUser ? 8 : 0,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? roleBg : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? roleColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? roleColor.withOpacity(0.15)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          r['icon'] as IconData,
                          size: 18,
                          color:
                              isSelected ? roleColor : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        r['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? roleColor : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Field label ───────────────────────────────────────────────────────
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      );

  // ── Email field ───────────────────────────────────────────────────────
  Widget _buildEmailField() => TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(Icons.email_outlined, color: _roleColor),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _roleColor, width: 1.5),
          ),
        ),
      );

  // ── Password field ────────────────────────────────────────────────────
  Widget _buildPasswordField() => TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: _roleColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _roleColor, width: 1.5),
          ),
        ),
      );

  // ── Forgot password ───────────────────────────────────────────────────
  Widget _buildForgotPassword() => Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () =>
              context.push('${AppRoutes.forgotPassword}?role=$_selectedRole'),
          style: TextButton.styleFrom(
            foregroundColor: _roleColor,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _roleColor,
            ),
          ),
        ),
      );

  // ── Error banner ──────────────────────────────────────────────────────
  Widget _buildError() => Consumer<AuthService>(
        builder: (_, auth, __) {
          if (auth.error == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppTheme.statusInactive.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.statusInactive, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.error!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppTheme.statusInactive,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  // ── Sign in button ────────────────────────────────────────────────────
  Widget _buildSignInButton() => Consumer<AuthService>(
        builder: (_, auth, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientForRole(_selectedRole),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _roleColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        },
      );

  // ── Divider ───────────────────────────────────────────────────────────
  Widget _buildDivider() => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'or',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );

  // ── Register row (Tenant & User only) ─────────────────────────────────
  Widget _buildRegisterRow() => Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () =>
                      context.push('${AppRoutes.register}?role=$_selectedRole'),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _roleColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Provider note ─────────────────────────────────────────────────────
  Widget _buildProviderNote() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.providerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.providerPrimary.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 18, color: AppTheme.providerPrimary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Provider accounts are created by Tenant only. '
                'Contact your assigned tenant for login credentials.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.providerDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Admin portal link ─────────────────────────────────────────────────
  Widget _buildAdminPortalLink() => Center(
        child: GestureDetector(
          onTap: _showAdminLoginSheet,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  size: 15, color: AppTheme.textHint),
              SizedBox(width: 6),
              Text(
                'Platform Admin Portal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.textHint,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Admin login bottom sheet ──────────────────────────────────────────
  void _showAdminLoginSheet() {
    final adminEmailCtrl = TextEditingController();
    final adminPasswordCtrl = TextEditingController();
    final adminFormKey = GlobalKey<FormState>();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Form(
              key: adminFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Handle bar ──────────────────────────────────
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      // ✅ Uses AppTheme.adminDark / adminPrimary — no hardcoded indigo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.adminDark,
                              AppTheme.adminPrimary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Admin',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            // ✅ Removed "Super Admin" — no such role
                            'Admin access only',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Info note ────────────────────────────────────
                  // ✅ Uses AppTheme.adminLight / adminPrimary — no hardcoded indigo
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.adminLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security_rounded,
                            color: AppTheme.adminPrimary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This area is for platform administrators '
                            'who manage tenants and the SaaS system.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppTheme.adminDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Email ────────────────────────────────────────
                  TextFormField(
                    controller: adminEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 20, color: AppTheme.adminPrimary),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(
                            color: AppTheme.adminPrimary, width: 1.5),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Email required' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ─────────────────────────────────────
                  TextFormField(
                    controller: adminPasswordCtrl,
                    obscureText: obscure,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Admin Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 20, color: AppTheme.adminPrimary),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(
                            color: AppTheme.adminPrimary, width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password required' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Login button ─────────────────────────────────
                  Consumer<AuthService>(
                    builder: (_, auth, __) => Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        // ✅ Uses AppTheme admin gradient — no hardcoded indigo
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.adminDark,
                            AppTheme.adminPrimary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.adminPrimary.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!adminFormKey.currentState!.validate())
                                  return;
                                if (auth.error != null) {
                                  auth.clearError();
                                }

                                final ok = await auth.login(
                                  email: adminEmailCtrl.text.trim(),
                                  password: adminPasswordCtrl.text.trim(),
                                  role: AppConstants.roleAdmin,
                                );

                                if (!ctx.mounted) return;
                                if (ok) {
                                  Navigator.pop(ctx);
                                  context.go(AppRoutes.adminDashboard);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: auth.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.admin_panel_settings_rounded,
                                color: Colors.white, size: 20),
                        label: const Text(
                          'Access Admin Portal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      adminEmailCtrl.dispose();
      adminPasswordCtrl.dispose();
    });
  }
}
