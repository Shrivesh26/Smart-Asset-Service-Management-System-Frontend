import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    final names = (user?.fullName ?? '')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    _firstNameController.text = names.isNotEmpty ? names.first : '';
    _lastNameController.text =
        names.length > 1 ? names.sublist(1).join(' ') : '';
    _phoneController.text = user?.phone ?? '';
    _bioController.text = user?.bio ?? '';
    _experienceController.text = user?.experience ?? '';
    _specializationsController.text =
        (user?.specializations ?? const <String>[]).join(', ');
    _streetController.text = user?.address ?? '';
    _cityController.text = user?.city ?? '';
    _stateController.text = user?.state ?? '';
    _pincodeController.text = user?.pincode ?? '';
    _countryController.text = user?.country ?? 'India';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _specializationsController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final surface = isDark ? AppTheme.darkBackground : AppTheme.background;
    final Object? imageProvider = _imageBytes != null
        ? MemoryImage(_imageBytes!)
        : (user?.profilePhoto?.isNotEmpty ?? false)
            ? NetworkImage(user!.profilePhoto!)
            : null;

    return Scaffold(
      backgroundColor: surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.providerSettings),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Edit Provider Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: AppTheme.providerLight,
                                  backgroundImage: imageProvider as ImageProvider<Object>?,
                                  child: imageProvider == null
                                      ? Text(
                                          user?.initials ?? 'P',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.providerPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.providerPrimary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user?.fullName ?? 'Provider Profile',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Edit the details that power your provider account and service identity.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Basic Details',
                      cardColor: cardColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _input(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  validator: (value) =>
                                      value == null || value.trim().length < 2
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _input(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _phoneController,
                            label: 'Phone',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return 'Required';
                              if (!RegExp(r'^[0-9]{10}$')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Professional Details',
                      cardColor: cardColor,
                      child: Column(
                        children: [
                          _input(
                            controller: _bioController,
                            label: 'Bio',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _experienceController,
                            label: 'Experience (years)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return null;
                              final years = int.tryParse(value.trim());
                              if (years == null || years < 0 || years > 60) {
                                return 'Use a value between 0 and 60';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _specializationsController,
                            label: 'Specializations',
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Address',
                      cardColor: cardColor,
                      child: Column(
                        children: [
                          _input(
                              controller: _streetController, label: 'Street'),
                          const SizedBox(height: 12),
                          _input(controller: _cityController, label: 'City'),
                          const SizedBox(height: 12),
                          _input(controller: _stateController, label: 'State'),
                          const SizedBox(height: 12),
                          _input(
                            controller: _pincodeController,
                            label: 'Pincode',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return null;
                              if (!RegExp(r'^[0-9]{6}$')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid 6-digit pincode';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _input(
                              controller: _countryController, label: 'Country'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.providerPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
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

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final api = context.read<ApiService>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      String? avatarUrl;
      if (_imageBytes != null && _imageName != null) {
        avatarUrl = await api.uploadProviderImage(
          imageBytes: _imageBytes!,
          imageName: _imageName!,
        );
      }

      final ok = await auth.updateProfile({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'specializations': _specializationsController.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pinCode': _pincodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
        if (avatarUrl != null) 'avatar': avatarUrl,
      });

      if (!mounted) return;
      if (ok) {
        await auth.refreshProfile();
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Provider profile updated successfully.')),
        );
        Navigator.of(context).pop();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Unable to update profile.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save provider profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.cardColor,
  });

  final String title;
  final Widget child;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
