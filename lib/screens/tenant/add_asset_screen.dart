import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/asset_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});
  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _qtyCtrl      = TextEditingController(text: '1');
  final _costCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _picker       = ImagePicker();

  String _category = AppConstants.assetCategories.first;
  String _status = 'available';
  List<XFile>    _images     = [];
  List<Uint8List> _imageBytes = [];

  // ── Dark helpers ──────────────────────────────────────────────────────
  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surface => _isDark ? const Color(0xFF121212) : AppTheme.surface;
  Color get _inputBg => _isDark ? const Color(0xFF2A2A2A) : Colors.white;
  Color get _txtP    => _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _div     => _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _qtyCtrl.dispose();  _costCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
        maxWidth: 1280, maxHeight: 1280, imageQuality: 82);
    if (picked.isEmpty) return;
    final limited = picked.take(3).toList();
    final bytes = await Future.wait(limited.map((x) => x.readAsBytes()));
    setState(() { _images = limited; _imageBytes = bytes; });

    if (picked.length > 3 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Maximum 3 asset images are allowed'),
      ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final svc  = context.read<AssetService>();
    final quantity = int.parse(_qtyCtrl.text.trim());
    final price = double.parse(_costCtrl.text.trim());

    svc.clearError();

    final ok = await svc.createAsset(
      adminId:           auth.currentUser?.id ?? '',
      name:              _nameCtrl.text.trim(),
      category:          _category,
      description:       _descCtrl.text.trim(), 
      location:          _locationCtrl.text.trim(),
      assetNumber:       'ASSET-${DateTime.now().millisecondsSinceEpoch}',
      price:             price,
      quantity:          quantity,
      purchaseDate:      DateTime.now(),
      status:            _status,
      imageBytesList:    _imageBytes,
      imageNames:        _images.map((image) => image.name).toList(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Asset added successfully!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.statusCompleted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(svc.error ?? 'Failed to add asset',
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Asset Name ──────────────────────────────────────────
                _label('Asset Name *'),
                const SizedBox(height: 6),
                _textField(
                  ctrl: _nameCtrl, hint: 'e.g. Drill Machine, Ladder',
                  icon: Icons.inventory_2_outlined,
                  validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Category ────────────────────────────────────────────
                _label('Category *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: _cardBg,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP),
                  decoration: _deco('', icon: Icons.category_outlined),
                  items: AppConstants.assetCategories
                      .map((c) => DropdownMenuItem(value: c,
                          child: Text(c, style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14, color: _txtP))))
                      .toList(),
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
                  decoration: _deco('Describe the asset, its condition and use...'),
                  validator: (v) => v!.trim().isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Quantity + Cost ─────────────────────────────────────
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Quantity *'),
                    const SizedBox(height: 6),
                    _textField(
                      ctrl: _qtyCtrl, hint: '1',
                      icon: Icons.layers_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1) return 'Min 1';
                        return null;
                      },
                    ),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Cost (₹) *'),
                    const SizedBox(height: 6),
                    _textField(
                      ctrl: _costCtrl, hint: '0',
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ])),
                ]),
                const SizedBox(height: 16),

                // ── Location ────────────────────────────────────────────
                _label('Location (optional)'),
                const SizedBox(height: 6),
                _textField(
                  ctrl: _locationCtrl,
                  hint: 'e.g. Warehouse A, Office Store',
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: 16),

                // ── Images ──────────────────────────────────────────────
                _label('Status *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: _cardBg,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP),
                  decoration: _deco('', icon: Icons.build_circle_outlined),
                  items: [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP)),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? 'available'),
                ),
                const SizedBox(height: 16),

                _label('Asset Images'),
                const SizedBox(height: 6),
                _imagePicker(),
                const SizedBox(height: 32),

                // ── Submit ───────────────────────────────────────────────
                Consumer<AssetService>(builder: (_, svc, __) {
                  if (svc.error != null) {
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
                        Expanded(child: Text(svc.error!,
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontSize: 13, color: AppTheme.statusInactive))),
                      ]),
                    );
                  }
                  return _submitBtn(
                    svc.isLoading ? null : _submit,
                    svc.isLoading ? 'Adding Asset...' : 'Add Asset',
                    svc.isLoading,
                  );
                }),
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
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary])),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add Asset',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Create inventory items for your workspace',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: Colors.white70)),
          ])),
        ]),
      )),
    );
  }

  // ── Image picker ──────────────────────────────────────────────────────
  Widget _imagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _imageBytes.isEmpty ? 100 : 145,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageBytes.isNotEmpty ? AppTheme.tenantPrimary : _div,
            width: _imageBytes.isNotEmpty ? 1.5 : 1,
          ),
        ),
        child: _imageBytes.isEmpty
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.tenantPrimary, size: 24)),
                const SizedBox(height: 8),
                const Text('Tap to add asset images',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w500, color: AppTheme.tenantPrimary)),
                const SizedBox(height: 2),
                Text('Up to 3 images',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: _txtS)),
              ])
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${_images.length} image${_images.length == 1 ? '' : 's'}',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: FontWeight.w600, color: _txtP)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() { _images = []; _imageBytes = []; }),
                      child: const Text('Clear', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 12,
                          color: AppTheme.statusInactive, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageBytes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_imageBytes[i],
                          width: 95, fit: BoxFit.cover)),
                  )),
                ]),
              ),
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────
  Widget _label(String t) => Text(t, style: TextStyle(fontFamily: 'Poppins',
      fontSize: 13, fontWeight: FontWeight.w500, color: _txtP));

  InputDecoration _deco(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: 'Poppins', color: _txtS),
    filled: true, fillColor: _inputBg,
    prefixIcon: icon != null
        ? Icon(icon, size: 20, color: AppTheme.tenantPrimary) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _div)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _div)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.tenantPrimary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.statusInactive)),
  );

  Widget _textField({
    required TextEditingController ctrl, required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP),
      decoration: _deco(hint, icon: icon),
      validator: validator,
    );
  }

  Widget _submitBtn(VoidCallback? onPressed, String label, bool loading) {
    return Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF4C3793), const Color(0xFF7C3AED)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: AppTheme.tenantPrimary.withOpacity(0.35),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontFamily: 'Poppins',
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
