import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;

  const ForgotPasswordScreen({super.key, required this.role});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();

  bool    _submitted  = false;
  String? _successMsg;

  Color get _roleColor => AppTheme.primaryForRole(widget.role);

  // Provider cannot reset password themselves
  bool get _isProvider => widget.role == AppConstants.roleProvider;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isProvider) return;
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    authService.clearError();

    final result = await authService.forgotPassword(
      email: _emailCtrl.text.trim(),
      role:  widget.role,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _submitted  = true;
        _successMsg = result['message'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingPage),
              child: _isProvider
                  ? _buildProviderContactAdmin()
                  : _submitted
                      ? _buildSuccess()
                      : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.gradientForRole(widget.role),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 20, 28),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isProvider
                        ? 'Contact your administrator'
                        : 'Reset your password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
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

  // ── Provider: Show "Contact Admin" — no email reset ───────────────────
  Widget _buildProviderContactAdmin() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.providerLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 44,
            color: AppTheme.providerPrimary,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Contact Your Admin',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.providerLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.providerPrimary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 28,
                color: AppTheme.providerPrimary,
              ),
              const SizedBox(height: 12),
              const Text(
                AppConstants.providerForgotMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Your admin will reset your password and\n'
          'provide you with new login credentials.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.providerPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.providerPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Email form (Admin & User) ──────────────────────────────────────────
  Widget _buildForm() {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.lightForRole(widget.role),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 38,
                color: _roleColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reset Password',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email address.\n'
              'We\'ll send you a link to reset your password.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter your registered email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final r =
                          RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!r.hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
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
              ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientForRole(widget.role),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _roleColor.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'Back to Login',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: _roleColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Success state ─────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 44,
            color: AppTheme.statusCompleted,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _successMsg ??
              'A password reset link has been sent to ${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: _roleColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}