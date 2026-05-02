import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});

  @override
  State<UserEditProfileScreen> createState() =>
      _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  File? _selectedImage;
  bool _loading = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _fill => _isDark ? AppTheme.darkInput : Colors.grey.shade50;
  Color get _border =>
      _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _addressCtrl.text = user?.address ?? '';
    _cityCtrl.text = user?.city ?? '';
    _stateCtrl.text = user?.state ?? '';
    _pinCtrl.text = user?.pincode ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  ImageProvider<Object>? get _imageProvider {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    final url =
        context.read<AuthService>().currentUser?.profilePhoto;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file != null) setState(() => _selectedImage = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': {
          'street': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pinCode': _pinCtrl.text.trim(),
        },
      };

      if (_selectedImage != null) {
        final url = await context
            .read<AuthService>()
            .uploadProfileImage(_selectedImage!);
        if (url != null) data['avatarUrl'] = url;
      }

      await context.read<AuthService>().updateProfile(data);
      await context.read<AuthService>().refreshProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: AppTheme.statusCompleted,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                // Avatar card
                _buildAvatarCard(user),
                const SizedBox(height: 16),

                // Personal info
                _buildSection('Personal Info', Icons.person_outline_rounded, [
                  _field('Full Name', _nameCtrl, Icons.badge_outlined,
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null),
                  const SizedBox(height: 12),
                  _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                ]),
                const SizedBox(height: 14),

                // Address
                _buildSection('Address', Icons.location_on_outlined, [
                  _field('Street Address', _addressCtrl, Icons.map_outlined),
                  const SizedBox(height: 12),
                  _field('City', _cityCtrl, Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _field('State', _stateCtrl, Icons.flag_outlined),
                  const SizedBox(height: 12),
                  _field('Pincode', _pinCtrl, Icons.pin_outlined,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                          return 'Enter a valid 6-digit pincode';
                        }
                        return null;
                      }),
                ]),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(_loading ? 'Saving...' : 'Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.userPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.go(AppRoutes.userSettings),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  Text('Update your personal information',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAvatarCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.userPrimary.withOpacity(0.5),
                    width: 2.5),
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundColor:
                    AppTheme.userPrimary.withOpacity(0.12),
                backgroundImage: _imageProvider,
                child: _imageProvider == null
                    ? Text(user?.initials ?? 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.userPrimary,
                        ))
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.userPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: _card, width: 2),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Colors.white, size: 15),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(user?.fullName ?? 'User',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _txtP)),
        const SizedBox(height: 3),
        Text(user?.email ?? '',
            style: TextStyle(fontSize: 12, color: _txtS)),
        const SizedBox(height: 8),
        Text('Tap avatar to change photo',
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.userPrimary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.userPrimary
                  .withOpacity(_isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.userPrimary, size: 17),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _txtP)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      style: TextStyle(color: _txtP, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _txtS, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.userPrimary, size: 20),
        filled: true,
        fillColor: _fill,
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppTheme.statusInactive, width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
      ),
    );
  }
}