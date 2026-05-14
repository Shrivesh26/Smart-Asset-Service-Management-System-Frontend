import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/tenant_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

// ── Business Type Enum ──────────────────────────────────────────────────────
enum BusinessType {
  homeServices,
  cleaningServices,
  repairMaintenance,
  salon,
  fitness,
  consulting,
  other,
}

extension BusinessTypeX on BusinessType {
  String get apiValue {
    switch (this) {
      case BusinessType.homeServices:
        return 'home services';
      case BusinessType.cleaningServices:
        return 'cleaning services';
      case BusinessType.repairMaintenance:
        return 'repair & maintenance';
      case BusinessType.salon:
        return 'salon';
      case BusinessType.fitness:
        return 'fitness';
      case BusinessType.consulting:
        return 'consulting';
      case BusinessType.other:
        return 'other';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessType.homeServices:
        return Icons.home_repair_service_outlined;
      case BusinessType.cleaningServices:
        return Icons.cleaning_services_outlined;
      case BusinessType.repairMaintenance:
        return Icons.build_outlined;
      case BusinessType.salon:
        return Icons.content_cut_outlined;
      case BusinessType.fitness:
        return Icons.fitness_center_outlined;
      case BusinessType.consulting:
        return Icons.business_center_outlined;
      case BusinessType.other:
        return Icons.category_outlined;
    }
  }

  String get label {
    return apiValue
        .split(' ')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  static BusinessType? fromApi(String? value) {
    if (value == null) return null;
    try {
      return BusinessType.values.firstWhere(
        (e) => e.apiValue.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────
class TenantEditProfileScreen extends StatefulWidget {
  const TenantEditProfileScreen({super.key});

  @override
  State<TenantEditProfileScreen> createState() =>
      _TenantEditProfileScreenState();
}

class _TenantEditProfileScreenState extends State<TenantEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _subdomainCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  // ── Image state ─────────────────────────────────────────────────────────
  // We store raw bytes so MemoryImage works on all Android API levels
  // without the _namespace / content-URI access errors from FileImage.
  File? _selectedImageFile;      // passed to upload
  Uint8List? _previewBytes;      // used for local preview only

  bool _loading = false;
  bool _isEditing = false;
  BusinessType? _selectedBusinessType;

  // ── Init ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _businessCtrl.text = user?.businessName ?? '';
    _subdomainCtrl.text = user?.subdomain ?? '';
    _addressCtrl.text = user?.address ?? '';
    _cityCtrl.text = user?.city ?? '';
    _stateCtrl.text = user?.state ?? '';
    _pinCtrl.text = user?.pincode ?? '';
    if (user is TenantModel) {
      _selectedBusinessType = BusinessTypeX.fromApi(user.businessType);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessCtrl.dispose();
    _subdomainCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  // ── Theme helpers ───────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.background;
  Color get _txtP => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _fill => _isDark ? AppTheme.darkInput : Colors.grey.shade100;
  Color get _border => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  // ── Resolved image provider ─────────────────────────────────────────────
  // Priority: local picked bytes → server URL → null (shows initials)
  ImageProvider<Object>? get _imageProvider {
    if (_previewBytes != null) return MemoryImage(_previewBytes!);
    final url = context.read<AuthService>().currentUser?.profilePhoto;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  // ── Pick image ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    // Read as bytes immediately — avoids _namespace / content-URI errors
    // that occur when passing Android content:// URIs to dart:io File.
    final bytes = await picked.readAsBytes();

    setState(() {
      _selectedImageFile = File(picked.path); // for upload
      _previewBytes = bytes;                  // for preview
    });
  }

  // ── Save ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();

      final data = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'businessName': _businessCtrl.text.trim(),
        'business': {'type': _selectedBusinessType?.apiValue},
        'address': {
          'street': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pinCode': _pinCtrl.text.trim(),
        },
      };

      if (_selectedImageFile != null) {
        final imageUrl = await auth.uploadProfileImage(_selectedImageFile!);
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          data['avatarUrl'] = imageUrl;
        }
      }

      await auth.updateProfile(data);
      await auth.refreshProfile();

      // Clear local preview — server image is now the source of truth
      _selectedImageFile = null;
      _previewBytes = null;

      if (!mounted) return;
      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppTheme.statusCompleted,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.statusInactive,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAvatarCard(user),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Account Info',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _field(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                          disabled: false,
                        ),
                        _field(
                          label: 'Phone Number',
                          controller: _phoneCtrl,
                          icon: Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                          disabled: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      title: 'Business Info',
                      icon: Icons.store_outlined,
                      children: [
                        _field(
                          label: 'Business Name',
                          controller: _businessCtrl,
                          icon: Icons.business_outlined,
                          disabled: false,
                        ),
                        _businessTypeField(),
                        const SizedBox(height: 10),
                        _field(
                          label: 'Subdomain',
                          controller: _subdomainCtrl,
                          icon: Icons.link_outlined,
                          disabled: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      title: 'Store Address',
                      icon: Icons.location_on_outlined,
                      children: [
                        _field(
                          label: 'Street Address',
                          controller: _addressCtrl,
                          icon: Icons.map_outlined,
                          disabled: false,
                        ),
                        _field(
                          label: 'City',
                          controller: _cityCtrl,
                          icon: Icons.location_city_outlined,
                          disabled: false,
                        ),
                        _field(
                          label: 'State',
                          controller: _stateCtrl,
                          icon: Icons.flag_outlined,
                          disabled: false,
                        ),
                        _field(
                          label: 'Pincode',
                          controller: _pinCtrl,
                          icon: Icons.pin_outlined,
                          keyboard: TextInputType.number,
                          disabled: false,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                              return 'Enter a valid 6-digit pincode';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 22),
                      _buildSaveButton(),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go(AppRoutes.tenantSettings),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 16),
                  label: const Text('Edit',
                      style: TextStyle(color: Colors.white)),
                )
              else ...[
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _isEditing = false;
                            // Discard unsaved local preview
                            _previewBytes = null;
                            _selectedImageFile = null;
                          }),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar card ─────────────────────────────────────────────────────────
  Widget _buildAvatarCard(dynamic user) {
    final provider = _imageProvider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.tenantPrimary.withOpacity(0.5),
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: provider != null
                          ? Image(
                              image: provider,
                              fit: BoxFit.cover,
                              // Graceful error — fall back to initials
                              errorBuilder: (_, __, ___) => _initialsAvatar(user),
                            )
                          : _initialsAvatar(user),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.tenantPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardBg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Tenant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _txtP,
            ),
          ),
          const SizedBox(height: 3),
          Text(user?.email ?? '',
              style: TextStyle(fontSize: 12, color: _txtS)),
          if (_isEditing) ...[
            const SizedBox(height: 10),
            Text(
              _previewBytes != null
                  ? '✓ New photo selected — tap Save to apply'
                  : 'Tap avatar to change photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _previewBytes != null
                    ? AppTheme.statusCompleted
                    : AppTheme.tenantPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initialsAvatar(dynamic user) {
    return Container(
      color: AppTheme.tenantPrimary.withOpacity(0.12),
      alignment: Alignment.center,
      child: Text(
        user?.initials ?? 'T',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppTheme.tenantPrimary,
        ),
      ),
    );
  }

  // ── Section wrapper ─────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary
                      .withOpacity(_isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.tenantPrimary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _txtP,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ── Reusable field ──────────────────────────────────────────────────────
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    required bool disabled,
  }) {
    if (!_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: _txtS)),
            const SizedBox(height: 4),
            Text(
              controller.text.isEmpty ? '—' : controller.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _txtP,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        enabled: !disabled,
        style: TextStyle(
          color: disabled ? _txtS : _txtP,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _txtS, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.tenantPrimary, size: 20),
          filled: true,
          fillColor: disabled ? _fill.withOpacity(0.5) : _fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.tenantPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.statusInactive, width: 1.2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  // ── Business type field ─────────────────────────────────────────────────
  Widget _businessTypeField() {
    if (!_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Type',
                style: TextStyle(fontSize: 11, color: _txtS)),
            const SizedBox(height: 4),
            Text(
              _selectedBusinessType?.label ?? '—',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _txtP,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<BusinessType>(
        value: _selectedBusinessType,
        dropdownColor: _cardBg,
        style: TextStyle(color: _txtP, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Business Type',
          labelStyle: TextStyle(color: _txtS, fontSize: 13),
          prefixIcon: Icon(
            _selectedBusinessType?.icon ?? Icons.category_outlined,
            color: AppTheme.tenantPrimary,
            size: 20,
          ),
          filled: true,
          fillColor: _fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.tenantPrimary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: BusinessType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.label),
          );
        }).toList(),
        onChanged: (v) => setState(() => _selectedBusinessType = v),
      ),
    );
  }

  // ── Save button ─────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _loading ? null : _save,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_loading ? 'Saving...' : 'Save Changes'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.tenantPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}