import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/provider_service.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});
  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();
  final _bioCtrl         = TextEditingController();
  final _picker          = ImagePicker();

  String _skill          = AppConstants.skillCategories.first;
  String _experience     = AppConstants.experienceOptions.first;
  bool   _obscurePass    = true;
  bool   _obscureConfirm = true;
  XFile?     _photo;
  Uint8List? _photoBytes;
  final List<String> _selectedServiceIds = [];

  // ── Dark helpers ──────────────────────────────────────────────────────
  bool  get _isDark    => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg    => _isDark ? AppTheme.darkCard    : Colors.white;
  Color get _surface   => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _inputBg   => _isDark ? AppTheme.darkInput   : Colors.white;
  Color get _txtP      => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS      => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _div       => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AuthService>().currentUser?.id;
      context.read<ServiceCatalogService>()
          .fetchServicesForAdmin(tenantId: id);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();    _emailCtrl.dispose();
    _phoneCtrl.dispose();   _addressCtrl.dispose();
    _passwordCtrl.dispose();_confirmCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── Pick provider photo ───────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _photo = picked; _photoBytes = bytes; });
  }

  // ── Generate random password ──────────────────────────────────────────
  void _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#!';
    final ts   = DateTime.now().millisecondsSinceEpoch;
    final pass = List.generate(
        12, (i) => chars[(ts + i * 13) % chars.length]).join();
    setState(() {
      _passwordCtrl.text    = pass;
      _confirmCtrl.text     = pass;
      _obscurePass          = false;
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final svc  = context.read<ProviderService>();

    final ok = await svc.createProvider(
      adminId:            auth.currentUser?.id ?? '',
      fullName:           _nameCtrl.text.trim(),
      email:              _emailCtrl.text.trim(),
      phone:              _phoneCtrl.text.trim(),
      address:            _addressCtrl.text.trim(),
      skillCategory:      _skill,
      experience:         _experience,
      password:           _passwordCtrl.text.trim(),
      assignedServiceIds: _selectedServiceIds,
      idProof:            '',
      certifications:     _bioCtrl.text.trim(),
      imageBytes:         _photoBytes,
      imageName:          _photo?.name,
    );

    if (!mounted) return;

    if (ok) {
      await _showCredentials();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(svc.error ?? 'Failed to create provider',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _showCredentials() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.statusCompleted.withOpacity(0.12),
              shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.statusCompleted, size: 22)),
          const SizedBox(width: 12),
          Text('Provider Created!', style: TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w700, fontSize: 18, color: _txtP)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Share these login credentials with the provider:',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  color: _txtS)),
          const SizedBox(height: 16),
          _credRow('Email',    _emailCtrl.text.trim()),
          const SizedBox(height: 8),
          _credRow('Password', _passwordCtrl.text.trim()),
          const SizedBox(height: 8),
          _credRow('Role',     'Service Provider'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.statusPending.withOpacity(
                  _isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.statusPending.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.statusPending, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                  'Save these credentials now. '
                  'Password cannot be retrieved later.',
                  style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12, color: _txtP))),
            ]),
          ),
        ]),
        actions: [
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tenantPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: const Text('Done — Go Back',
                style: TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600, color: Colors.white)),
          )),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isDark ? AppTheme.darkInput : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _div),
      ),
      child: Row(children: [
        Text('$label:', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 12, fontWeight: FontWeight.w500, color: _txtS)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontFamily: 'Poppins',
            fontSize: 13, fontWeight: FontWeight.w700, color: _txtP),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svcCatalog = context.watch<ServiceCatalogService>();
    final providerSvc = context.watch<ProviderService>();

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                // ── Info note ──────────────────────────────────────────
                _infoNote(),
                const SizedBox(height: 24),

                // ── SECTION 1: Basic Info ──────────────────────────────
                _sectionHeader('Basic Information',
                    Icons.person_outline_rounded),
                const SizedBox(height: 16),

                // Full name
                _label('Full Name *'),
                const SizedBox(height: 6),
                _textField(ctrl: _nameCtrl, hint: 'Provider full name',
                    icon: Icons.badge_outlined,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Name is required' : null),
                const SizedBox(height: 14),

                // Email
                _label('Email *'),
                const SizedBox(height: 6),
                _textField(ctrl: _emailCtrl,
                    hint: 'Email used for login',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v.trim())) return 'Invalid email';
                      return null;
                    }),
                const SizedBox(height: 14),

                // Phone + Address row
                Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _label('Phone *'),
                    const SizedBox(height: 6),
                    _textField(ctrl: _phoneCtrl, hint: '+91 XXXXX XXXXX',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Phone required' : null),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _label('Address'),
                    const SizedBox(height: 6),
                    _textField(ctrl: _addressCtrl,
                        hint: 'Provider address',
                        icon: Icons.location_on_outlined),
                  ])),
                ]),
                const SizedBox(height: 24),

                // ── SECTION 2: Profile Photo ───────────────────────────
                _sectionHeader('Profile Photo',
                    Icons.photo_camera_outlined),
                const SizedBox(height: 8),
                Text('A photo makes the provider easier to identify.',
                    style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12, color: _txtS)),
                const SizedBox(height: 14),
                _photoPicker(),
                const SizedBox(height: 24),

                // ── SECTION 3: Skill & Experience ──────────────────────
                _sectionHeader('Skill & Experience',
                    Icons.engineering_outlined),
                const SizedBox(height: 16),

                _label('Skill Category *'),
                const SizedBox(height: 6),
                _dropdown<String>(
                  value: _skill,
                  items: AppConstants.skillCategories,
                  label: (s) => s,
                  onChanged: (v) => setState(() => _skill = v!),
                ),
                const SizedBox(height: 14),

                _label('Experience *'),
                const SizedBox(height: 6),
                _dropdown<String>(
                  value: _experience,
                  items: AppConstants.experienceOptions,
                  label: (s) => s,
                  onChanged: (v) => setState(() => _experience = v!),
                ),
                const SizedBox(height: 14),

                _label('Bio / Notes (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  style: TextStyle(fontFamily: 'Poppins', color: _txtP),
                  decoration: _deco('Certifications, skills, notes...'),
                ),
                const SizedBox(height: 24),

                // ── SECTION 4: Assign Services ─────────────────────────
                _sectionHeader('Assign Services',
                    Icons.home_repair_service_outlined),
                const SizedBox(height: 8),
                Text('Select services this provider can perform.',
                    style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12, color: _txtS)),
                const SizedBox(height: 14),

                if (svcCatalog.isLoading)
                  const Center(child: CircularProgressIndicator(
                      color: AppTheme.tenantPrimary))
                else if (svcCatalog.services.isEmpty)
                  _noServicesNote()
                else
                  _serviceList(svcCatalog),
                const SizedBox(height: 24),

                // ── SECTION 5: Login Credentials ───────────────────────
                _sectionHeader('Login Credentials',
                    Icons.lock_outline_rounded),
                const SizedBox(height: 8),
                Text('The provider will use these credentials to login.',
                    style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 12, color: _txtS)),
                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: _generatePassword,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 16,
                      color: AppTheme.tenantPrimary),
                  label: const Text('Generate Strong Password',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                          color: AppTheme.tenantPrimary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.tenantPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                _label('Password *'),
                const SizedBox(height: 6),
                _passField(ctrl: _passwordCtrl,
                    hint: 'Min 6 characters',
                    obscure: _obscurePass,
                    toggle: () => setState(() => _obscurePass = !_obscurePass),
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Password required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    }),
                const SizedBox(height: 14),

                _label('Confirm Password *'),
                const SizedBox(height: 6),
                _passField(ctrl: _confirmCtrl,
                    hint: 'Re-enter password',
                    obscure: _obscureConfirm,
                    toggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Confirm your password';
                      if (v != _passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    }),
                const SizedBox(height: 32),

                // ── Error banner ────────────────────────────────────────
                if (providerSvc.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.statusInactive.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.statusInactive.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.statusInactive, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(providerSvc.error!,
                          style: const TextStyle(fontFamily: 'Poppins',
                              fontSize: 13, color: AppTheme.statusInactive))),
                    ]),
                  ),

                // ── Submit ──────────────────────────────────────────────
                _submitBtn(providerSvc),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF3B0764), AppTheme.tenantDark]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary])),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 22),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add Provider',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Create a provider account for your workspace',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: Colors.white70)),
          ])),
        ]),
      )),
    );
  }

  // ── Info note ─────────────────────────────────────────────────────────
  Widget _infoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.tenantPrimary.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: AppTheme.tenantPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: RichText(text: TextSpan(
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                color: _txtP, height: 1.5),
            children: const [
              TextSpan(text: 'Important: ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: 'Provider accounts are created by Tenant admin. '
                  'Share the email and password with them after creation.'),
            ]))),
      ]),
    );
  }

  // ── Photo picker ──────────────────────────────────────────────────────
  Widget _photoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _photoBytes != null ? 130 : 100,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _photoBytes != null
                ? AppTheme.tenantPrimary : _div,
            width: _photoBytes != null ? 1.5 : 1,
          ),
        ),
        child: _photoBytes != null
            ? Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(_photoBytes!,
                      width: double.infinity, height: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(top: 8, right: 8,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _iconBtn(Icons.edit_rounded, () => _pickPhoto()),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.close_rounded, () =>
                        setState(() { _photo = null; _photoBytes = null; }),
                        color: AppTheme.statusInactive),
                  ]),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary.withOpacity(
                        _isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.add_a_photo_outlined,
                      color: AppTheme.tenantPrimary, size: 22)),
                const SizedBox(height: 8),
                const Text('Tap to add profile photo',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.tenantPrimary)),
                const SizedBox(height: 2),
              ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.black54,
            shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ── Service checkbox list ─────────────────────────────────────────────
  Widget _serviceList(ServiceCatalogService cat) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _div),
      ),
      child: Column(children: cat.services.asMap().entries.map((e) {
        final i   = e.key;
        final svc = e.value;
        final sel = _selectedServiceIds.contains(svc.id);
        return Column(children: [
          if (i > 0) Divider(height: 1, color: _div),
          CheckboxListTile(
            value: sel,
            onChanged: (v) => setState(() {
              v == true
                  ? _selectedServiceIds.add(svc.id)
                  : _selectedServiceIds.remove(svc.id);
            }),
            activeColor: AppTheme.tenantPrimary,
            checkColor: Colors.white,
            title: Text(svc.name, style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14, color: _txtP)),
            subtitle: Row(children: [
              Text(svc.category, style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 11, color: _txtS)),
              const SizedBox(width: 10),
              Text(svc.priceDisplay, style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tenantPrimary)),
            ]),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ]);
      }).toList()),
    );
  }

  Widget _noServicesNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDark ? AppTheme.darkInput : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _div),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: _txtS, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('No services yet — add services first.',
            style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13, color: _txtS))),
      ]),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────
  Widget _submitBtn(ProviderService svc) {
    return Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF4C1D95), AppTheme.tenantPrimary]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: AppTheme.tenantPrimary.withOpacity(0.35),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: ElevatedButton.icon(
        onPressed: svc.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: svc.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.person_add_rounded,
                color: Colors.white, size: 20),
        label: Text(
          svc.isLoading ? 'Creating Account...' : 'Create Provider Account',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.tenantPrimary, size: 20)),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
          fontWeight: FontWeight.w600, color: _txtP)),
    ]);
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _div)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _div)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppTheme.tenantPrimary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.statusInactive)),
  );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboard,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP),
      decoration: _deco(hint, icon: icon),
      validator: validator,
    );
  }

  Widget _passField({
    required TextEditingController ctrl,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, obscureText: obscure,
      style: TextStyle(fontFamily: 'Poppins', color: _txtP),
      decoration: _deco(hint, icon: Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined
              : Icons.visibility_outlined, size: 20, color: _txtS),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: _cardBg,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtP),
      decoration: _deco(''),
      items: items.map((i) => DropdownMenuItem(value: i,
          child: Text(label(i), style: TextStyle(fontFamily: 'Poppins',
              fontSize: 14, color: _txtP)))).toList(),
      onChanged: onChanged,
    );
  }
}