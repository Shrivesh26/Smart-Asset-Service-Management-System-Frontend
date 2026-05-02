import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});
  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _maxAdvanceCtrl = TextEditingController(text: '5');
  final _picker = ImagePicker();

  String _category = AppConstants.serviceCategories.first;
  bool _allowCancellation = true;
  XFile? _image;
  Uint8List? _imageBytes;

  // ── Dark helpers ──────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surface => _isDark ? const Color(0xFF121212) : AppTheme.surface;
  Color get _inputBg => _isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get _txtP => _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS => _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _div => _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _maxAdvanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _image = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final svc = context.read<ServiceCatalogService>();
    svc.clearError();

    final ok = await svc.createService(
      tenantId: auth.currentUser?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _category,
      description: _descCtrl.text.trim(),
      pricing: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      duration: int.tryParse(_durationCtrl.text.trim()) ?? 10,
      maxAdvanceDays: int.tryParse(_maxAdvanceCtrl.text.trim()) ?? 5,
      allowCancellation: _allowCancellation,
      imageBytes: _imageBytes,
      imageName: _image?.name,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Service added successfully!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.statusCompleted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(svc.error ?? 'Failed to add service',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Service Name ────────────────────────────────────────
                    _label('Service Name *'),
                    const SizedBox(height: 6),
                    _textField(
                      ctrl: _nameCtrl,
                      hint: 'e.g. Haircut, AC Repair',
                      icon: Icons.home_repair_service_outlined,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Category ────────────────────────────────────────────
                    _label('Category *'),
                    const SizedBox(height: 6),
                    _dropdown<String>(
                      value: _category,
                      items: AppConstants.serviceCategories,
                      label: (c) =>
                          c[0].toUpperCase() +
                          c.substring(1).replaceAll('_', ' '),
                      onChanged: (v) => setState(() => _category = v!),
                      validator: (v) => v == null ? 'Pick a category' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Description ─────────────────────────────────────────
                    _label('Description *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: TextStyle(fontFamily: 'Poppins', color: _txtP),
                      decoration:
                          _deco('Describe what this service includes...'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Price + Duration ────────────────────────────────────
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                _label('Price (₹) *'),
                                const SizedBox(height: 6),
                                _textField(
                                  ctrl: _priceCtrl,
                                  hint: '0',
                                  icon: Icons.currency_rupee_rounded,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (v) {
                                    if (v!.trim().isEmpty) return 'Required';
                                    if (double.tryParse(v.trim()) == null)
                                      return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ])),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                _label('Duration (mins) *'),
                                const SizedBox(height: 6),
                                _textField(
                                  ctrl: _durationCtrl,
                                  hint: 'e.g. 60',
                                  icon: Icons.access_time_rounded,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v!.trim().isEmpty) return 'Required';
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n < 5) return 'Min 5 mins';
                                    if (n > 480) return 'Max 480 mins';
                                    return null;
                                  },
                                ),
                              ])),
                        ]),
                    const SizedBox(height: 16),

                    // ── Images ──────────────────────────────────────────────
                    _label('Service Images (1 recommended)'),
                    const SizedBox(height: 6),
                    _imagePicker(),
                    const SizedBox(height: 16),

                    // ── Cancellation toggle ─────────────────────────────────
                    _settingsCard(),
                    const SizedBox(height: 32),

                    // ── Error banner ─────────────────────────────────────────
                    Consumer<ServiceCatalogService>(builder: (_, svc, __) {
                      if (svc.error == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.statusInactive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.statusInactive.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppTheme.statusInactive, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(svc.error!,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppTheme.statusInactive))),
                        ]),
                      );
                    }),

                    // ── Submit ───────────────────────────────────────────────
                    Consumer<ServiceCatalogService>(
                      builder: (_, svc, __) => _submitBtn(
                          svc.isLoading ? null : _submit,
                          svc.isLoading ? 'Adding Service...' : 'Add Service',
                          svc.isLoading),
                    ),
                    const SizedBox(height: 24),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
                  : [AppTheme.tenantDark, AppTheme.tenantPrimary])),
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Add New Service',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('Create a service for your workspace',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white70)),
                  ])),
            ]),
          )),
    );
  }

  // ── Settings card (cancellation) ──────────────────────────────────────
  Widget _settingsCard() {
  return Container(
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _div),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary
                      .withOpacity(_isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.tenantPrimary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Booking Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _txtP,
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: _div),

        // ✅ MAX ADVANCE DAYS
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Max Advance Booking Days',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _txtP,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _maxAdvanceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'Poppins', color: _txtP),
                decoration: _deco('e.g. 10 days'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Min 1 day';
                  if (n > 15) return 'Max 15 days';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text(
                'Customers can book this service up to these many days in advance.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _txtS,
                ),
              ),
            ],
          ),
        ),

        // ✅ ALLOW CANCELLATION
        SwitchListTile.adaptive(
          value: _allowCancellation,
          activeColor: AppTheme.tenantPrimary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          title: Text(
            'Allow Cancellation',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _txtP,
            ),
          ),
          subtitle: Text(
            'Customers can cancel this service before it starts.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: _txtS,
            ),
          ),
          onChanged: (v) => setState(() => _allowCancellation = v),
        ),
      ],
    ),
  );
}
  // Widget _settingsCard() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: _cardBg,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: _div),
  //     ),
  //     child: Column(children: [
  //       Padding(
  //         padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
  //         child: Row(children: [
  //           Container(
  //               width: 32,
  //               height: 32,
  //               decoration: BoxDecoration(
  //                   color:
  //                       AppTheme.tenantPrimary.withOpacity(_isDark ? 0.2 : 0.1),
  //                   borderRadius: BorderRadius.circular(10)),
  //               child: const Icon(Icons.tune_rounded,
  //                   color: AppTheme.tenantPrimary, size: 17)),
  //           const SizedBox(width: 10),
  //           Text('Booking Settings',
  //               style: TextStyle(
  //                   fontFamily: 'Poppins',
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: _txtP)),
  //         ]),
  //       ),
  //       Divider(height: 1, color: _div),
  //       SwitchListTile.adaptive(
  //         value: _allowCancellation,
  //         activeColor: AppTheme.tenantPrimary,
  //         contentPadding:
  //             const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
  //         title: Text('Allow Cancellation',
  //             style: TextStyle(
  //                 fontFamily: 'Poppins',
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w500,
  //                 color: _txtP)),
  //         subtitle: Text('Customers can cancel this service before it starts.',
  //             style:
  //                 TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _txtS)),
  //         onChanged: (v) => setState(() => _allowCancellation = v),
  //       ),
  //     ]),
  //   );
  // }

  // ── Image picker ──────────────────────────────────────────────────────
  Widget _imagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageBytes != null ? AppTheme.tenantPrimary : _div,
            width: _imageBytes != null ? 1.5 : 1,
          ),
        ),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.tenantPrimary
                          .withOpacity(_isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppTheme.tenantPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Service Image',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.tenantPrimary,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _image = null;
                        _imageBytes = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────
  Widget _label(String t) => Text(t,
      style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _txtP));

  InputDecoration _deco(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Poppins', color: _txtS),
        filled: true,
        fillColor: _inputBg,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: AppTheme.tenantPrimary)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _div)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.tenantPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.statusInactive)),
      );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP),
      decoration: _deco(hint, icon: icon),
      validator: validator,
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: _cardBg,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP),
      decoration: _deco(''),
      items: items
          .map((i) => DropdownMenuItem(
              value: i,
              child: Text(label(i),
                  style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 14, color: _txtP))))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _submitBtn(VoidCallback? onPressed, String label, bool loading) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF4C3793), const Color(0xFF7C3AED)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tenantPrimary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
      ),
    );
  }
}
