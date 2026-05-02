import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');

  final _bizNameCtrl = TextEditingController();
  final _bizDescCtrl = TextEditingController();
  final _bizWebCtrl = TextEditingController();

  final _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  String _businessType = AppConstants.businessTypes.first;
  String _generatedSubdomain = '';
  String _subdomainHex = '';
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  bool get _isTenant => widget.role == AppConstants.roleTenant;
  bool get _isUser => widget.role == AppConstants.roleUser;
  bool get _isProvider => widget.role == AppConstants.roleProvider;
  Color get _roleColor => AppTheme.primaryForRole(widget.role);

  @override
  void initState() {
    super.initState();
    _subdomainHex = _generateHex();
    _bizNameCtrl.addListener(_updateSubdomain);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _bioCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizDescCtrl.dispose();
    _bizWebCtrl.dispose();
    super.dispose();
  }

  String _generateHex() {
    return DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(16)
        .padLeft(12, '0')
        .substring(6);
  }

  void _updateSubdomain() {
    final slug = _slugify(_bizNameCtrl.text.trim());
    setState(() {
      _generatedSubdomain = slug.isEmpty ? '' : '$slug-$_subdomainHex';
    });
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _onRegister() async {
    if (_isProvider) {
      context.go(AppRoutes.login);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    if (auth.error != null) auth.clearError();

    final address = {
      'street': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pinCode': _zipCtrl.text.trim(),
      'country': _countryCtrl.text.trim().isEmpty ? 'India' : _countryCtrl.text.trim(),
    };

    final data = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
    };

    if (_isTenant) {
      data['role'] = AppConstants.roleTenant;
      data['tenantData'] = {
        'businessName': _bizNameCtrl.text.trim(),
        'subdomain': _generatedSubdomain,
        'phone': _phoneCtrl.text.trim(),
        'address': address,
        'business': {
          'type': _businessType,
          'description': _bizDescCtrl.text.trim(),
          'website': _bizWebCtrl.text.trim(),
        },
      };
    } else {
      data['role'] = AppConstants.roleUser;
      data['address'] = address;
      data['profile'] = {
        'bio': _bioCtrl.text.trim(),
      };
    }

    if (_pickedImage != null && _imageBytes != null) {
      data['imageName'] = _pickedImage!.name;
      data['imageBytes'] = _imageBytes!;
    }

    final success = await auth.register(data);
    if (!mounted || !success) return;

    if (_isTenant) {
      context.go(AppRoutes.tenantDashboard);
    } else {
      context.go(AppRoutes.userDashboard);
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (_isProvider) {
      return _buildProviderBlock();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalSection(),
          const SizedBox(height: 20),
          _buildPhotoSection(),
          const SizedBox(height: 20),
          if (_isTenant) ...[
            _buildBusinessSection(),
            const SizedBox(height: 20),
          ],
          _buildAddressSection(),
          const SizedBox(height: 32),
          _buildError(),
          _buildSubmitButton(),
          const SizedBox(height: 20),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = {
      AppConstants.roleTenant: 'Tenant Registration',
      AppConstants.roleUser: 'User Registration',
      AppConstants.roleProvider: 'Provider Info',
    };
    final subtitles = {
      AppConstants.roleTenant: 'Create your business workspace',
      AppConstants.roleUser: 'Create your customer account',
      AppConstants.roleProvider: 'Providers are created by tenant admin',
    };

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[widget.role] ?? 'Register',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitles[widget.role] ?? '',
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

  Widget _buildPersonalSection() {
    return _sectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Personal Information',
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                ctrl: _firstNameCtrl,
                label: 'First Name *',
                hint: 'First name',
                icon: Icons.badge_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                ctrl: _lastNameCtrl,
                label: 'Last Name *',
                hint: 'Last name',
                icon: Icons.badge_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field(
          ctrl: _emailCtrl,
          label: 'Email Address *',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
              return 'Invalid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          ctrl: _phoneCtrl,
          label: 'Phone Number *',
          hint: '+91 XXXXX XXXXX',
          icon: Icons.phone_outlined,
          type: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
        ),
        if (_isUser) ...[
          const SizedBox(height: 14),
          _field(
            ctrl: _bioCtrl,
            label: 'Bio',
            hint: 'Tell us a little about yourself',
            icon: Icons.edit_note_rounded,
            maxLines: 3,
          ),
        ],
        const SizedBox(height: 14),
        _passwordField(
          ctrl: _passwordCtrl,
          label: 'Password *',
          hint: 'Min 6 characters',
          obscure: _obscurePass,
          toggle: () => setState(() => _obscurePass = !_obscurePass),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Password is required';
            if (v.trim().length < 6) return 'At least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _passwordField(
          ctrl: _confirmCtrl,
          label: 'Confirm Password *',
          hint: 'Re-enter password',
          obscure: _obscureConfirm,
          toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please confirm password';
            if (v != _passwordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final isTenantLogo = _isTenant;
    return _sectionCard(
      icon: isTenantLogo ? Icons.store_outlined : Icons.person_pin_outlined,
      title: isTenantLogo ? 'Business Logo' : 'Profile Photo',
      children: [
        Text(
          isTenantLogo
              ? 'Upload your tenant logo.'
              : 'Upload a profile photo.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildImagePicker(isTenantLogo),
      ],
    );
  }

  Widget _buildImagePicker(bool isLogo) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: isLogo ? 120 : 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageBytes != null ? _roleColor : AppTheme.dividerColor,
            width: _imageBytes != null ? 1.5 : 1,
          ),
        ),
        child: _imageBytes != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: isLogo ? BoxFit.contain : BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _pickedImage = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.lightForRole(widget.role),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLogo ? Icons.add_business_outlined : Icons.add_a_photo_outlined,
                      color: _roleColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to choose from gallery',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _roleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PNG, JPG up to 5 MB',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBusinessSection() {
    return _sectionCard(
      icon: Icons.storefront_outlined,
      title: 'Business Information',
      children: [
        _field(
          ctrl: _bizNameCtrl,
          label: 'Business Name *',
          hint: 'Your shop / salon / clinic name',
          icon: Icons.store_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
        ),
        if (_generatedSubdomain.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.tenantLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.tenantPrimary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: AppTheme.tenantPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Subdomain  ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    _generatedSubdomain,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tenantPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _labelText('Business Type *'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _businessType,
          decoration: _dropDecoration(),
          items: AppConstants.businessTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _businessType = v!),
        ),

        const SizedBox(height: 14),
        _field(
          ctrl: _bizDescCtrl,
          label: 'Business Description',
          hint: 'What services do you offer?',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        _field(
          ctrl: _bizWebCtrl,
          label: 'Website',
          hint: 'https://yourbusiness.com',
          icon: Icons.language_outlined,
          type: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Address',
      children: [
        _field(
          ctrl: _streetCtrl,
          label: 'Street / House No. *',
          hint: 'Building, Street name',
          icon: Icons.home_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Street is required' : null,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                ctrl: _cityCtrl,
                label: 'City *',
                hint: 'City',
                icon: Icons.location_city_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                ctrl: _stateCtrl,
                label: 'State *',
                hint: 'State',
                icon: Icons.map_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                ctrl: _zipCtrl,
                label: 'PIN Code *',
                hint: 'Postal code',
                icon: Icons.pin_drop_outlined,
                type: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                ctrl: _countryCtrl,
                label: 'Country',
                hint: 'India',
                icon: Icons.public_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderBlock() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.providerLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.providerPrimary.withOpacity(0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.providerPrimary, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Provider accounts are created by the tenant admin.\n\nYour tenant will create your account and share your login credentials with you.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.providerPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.lightForRole(widget.role),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _roleColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _roleColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, size: 20, color: AppTheme.textSecondary) : null,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _roleColor, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              onPressed: toggle,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _roleColor, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _dropDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _roleColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildError() {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        if (auth.error == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.statusInactive, size: 18),
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
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthService>(
      builder: (_, auth, __) => Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppTheme.gradientForRole(widget.role),
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          boxShadow: [
            BoxShadow(
              color: _roleColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _onRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            ),
          ),
          child: auth.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                )
              : Text(
                  _isTenant ? 'Create Tenant Account' : 'Create User Account',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: Text(
                  'Sign In',
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
  }
}
