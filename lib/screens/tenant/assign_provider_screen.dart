import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../models/asset_model.dart';
import '../../services/asset_service.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/provider_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_media_image.dart';

class AssignProviderScreen extends StatefulWidget {
  final String orderId;
  const AssignProviderScreen({super.key, required this.orderId});
  @override
  State<AssignProviderScreen> createState() => _AssignProviderScreenState();
}

class _AssignProviderScreenState extends State<AssignProviderScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  // Selections
  UserModel?   _provider;
  final List<AssetModel> _assets = [];
  DateTime?    _date;
  String?      _timeSlot;

  bool _submitting = false;

  late final AnimationController _slideCtrl;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _inputBg => _isDark ? AppTheme.darkInput : Colors.white;

  static const _timeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
    '06:00 PM',
  ];

  static const _steps = [
    'Provider', 'Asset', 'Schedule', 'Confirm',
  ];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authId = context.read<AuthService>().currentUser?.id;
      await Future.wait([
        context.read<BookingService>().fetchBookingById(widget.orderId),
        context.read<ProviderService>().fetchProviders(adminId: authId),
        context.read<AssetService>().fetchAssets(adminId: authId),
      ]);
      if (mounted) _slideCtrl.forward();
    });
  }

  @override void dispose() { _slideCtrl.dispose(); super.dispose(); }

  void _nextStep() {
    if (_step < _steps.length - 1) {
      _slideCtrl.reset();
      setState(() => _step++);
      _slideCtrl.forward();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      _slideCtrl.reset();
      setState(() => _step--);
      _slideCtrl.forward();
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0: return _provider != null;
      case 1: return true; // asset optional
      case 2: return _date != null && _timeSlot != null;
      case 3: return true;
      default: return false;
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final svc = context.read<BookingService>();
    final ok  = await svc.assignProviderToBooking(
      widget.orderId,
      providerId:   _provider!.id,
      assetIds:     _assets.map((asset) => asset.id).toList(),
      scheduledDate: '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
      scheduledTime: _timeSlot!,
    );
    setState(() => _submitting = false);
    if (ok) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Provider assigned successfully!'),
      backgroundColor: AppTheme.statusCompleted,
    ),
  );

  await Future.delayed(const Duration(milliseconds: 800));

  if (!mounted) return;
  context.go(AppRoutes.tenantOrders);
} else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(svc.error ?? 'Failed to assign provider',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppTheme.statusCancelled,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bkSvc  = context.watch<BookingService>();
    final prSvc  = context.watch<ProviderService>();
    final asSvc  = context.watch<AssetService>();
    final booking = bkSvc.selectedBooking;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _header(context, booking),
        _stepIndicator(),
        Expanded(
          child: bkSvc.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppTheme.tenantPrimary))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim, child: SlideTransition(
                          position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero).animate(anim),
                          child: child)),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _stepBody(prSvc, asSvc, booking),
                  ),
                ),
        ),
        _footer(booking),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _header(BuildContext ctx, BookingModel? b) {
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
            onPressed: () => ctx.pop(),
          ),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assign Provider', style: TextStyle(
                fontFamily: 'Poppins', fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white)),
            if (b != null)
              Text(b.serviceName, style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      )),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────
  Widget _stepIndicator() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: _steps.asMap().entries.map((e) {
          final i    = e.key;
          final done = i < _step;
          final curr = i == _step;
          return Expanded(child: Row(children: [
            Expanded(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || curr
                        ? AppTheme.tenantPrimary
                        : (_isDark ? AppTheme.darkInput : AppTheme.surface),
                    border: Border.all(
                        color: done || curr
                            ? AppTheme.tenantPrimary : _div,
                        width: curr ? 2 : 1),
                  ),
                  child: Icon(done ? Icons.check_rounded : Icons.circle,
                      size: done ? 14 : 8,
                      color: done || curr ? Colors.white : _div),
                ),
              ]),
              const SizedBox(height: 5),
              Text(e.value, textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: curr ? FontWeight.w700 : FontWeight.w400,
                      color: curr ? AppTheme.tenantPrimary : _txtS)),
            ])),
            if (i < _steps.length - 1)
              Expanded(child: Container(height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: done ? AppTheme.tenantPrimary : _div)),
          ]));
        }).toList(),
      ),
    );
  }

  // ── Step body ─────────────────────────────────────────────────────────
  Widget _stepBody(ProviderService prSvc, AssetService asSvc,
      BookingModel? booking) {
    switch (_step) {
      case 0: return _step0Providers(prSvc);
      case 1: return _step1Assets(asSvc);
      case 2: return _step2Schedule();
      case 3: return _step3Confirm(booking);
      default: return const SizedBox.shrink();
    }
  }

  // Step 0 — Select provider
  Widget _step0Providers(ProviderService svc) {
    final active = svc.providers.where((p) => p.isActive).toList();
    if (svc.isLoading) {
      return const Center(child: CircularProgressIndicator(
          color: AppTheme.tenantPrimary));
    }
    if (active.isEmpty) {
      return _emptyStep(Icons.engineering_outlined,
          'No active providers', 'Add providers first from the Providers tab.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (_, i) {
        final p   = active[i];
        final sel = _provider?.id == p.id;
        return GestureDetector(
          onTap: () => setState(() => _provider = p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel
                  ? AppTheme.tenantPrimary.withOpacity(_isDark ? 0.18 : 0.08)
                  : _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: sel ? AppTheme.tenantPrimary : _div,
                  width: sel ? 1.5 : 1),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: Row(children: [
              CircleAvatar(radius: 22,
                backgroundColor: AppTheme.tenantPrimary.withOpacity(0.15),
                child: Text(p.initials, style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tenantPrimary))),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.fullName, style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 14, fontWeight: FontWeight.w600, color: _txtP)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 12,
                      color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text('${p.rating.toStringAsFixed(1)}  ·  '
                      '${p.completedJobs} jobs',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          color: _txtS)),
                ]),
                if (p.specializations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, runSpacing: 4,
                      children: p.specializations.take(2).map((s) =>
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.tenantPrimary.withOpacity(
                                _isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(s, style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 9,
                              color: AppTheme.tenantPrimary,
                              fontWeight: FontWeight.w600)),
                        )).toList()),
                ],
              ])),
              if (sel)
                Container(width: 26, height: 26,
                  decoration: const BoxDecoration(
                      color: AppTheme.tenantPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 15)),
            ]),
          ),
        );
      },
    );
  }

  // Step 1 — Select asset (optional)
  Widget _step1Assets(AssetService svc) {
    final available = svc.assets.where((a) => a.isAvailable).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.tenantPrimary.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.tenantPrimary, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Asset assignment is optional.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: _txtP))),
          ]),
        ),
        // Skip option
        GestureDetector(
          onTap: () => setState(_assets.clear),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _assets.isEmpty
                  ? AppTheme.tenantPrimary.withOpacity(_isDark ? 0.15 : 0.07)
                  : _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _assets.isEmpty ? AppTheme.tenantPrimary : _div,
                  width: _assets.isEmpty ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.do_not_disturb_alt_rounded,
                    color: AppTheme.tenantPrimary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text('No asset needed',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w600, color: _txtP))),
              if (_assets.isEmpty)
                Container(width: 24, height: 24,
                  decoration: const BoxDecoration(
                      color: AppTheme.tenantPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)),
            ]),
          ),
        ),
        if (available.isNotEmpty) ...[
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Available Assets',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                    fontWeight: FontWeight.w600, color: _txtP))),
          ...available.map((a) {
            final sel = _assets.any((asset) => asset.id == a.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _assets.removeWhere((asset) => asset.id == a.id);
                } else {
                  _assets.add(a);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.tenantPrimary.withOpacity(_isDark ? 0.15 : 0.07)
                      : _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? AppTheme.tenantPrimary : _div,
                      width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  AppMediaImage(
                    imageUrl: a.imageUrl,
                    fallbackIcon: Icons.inventory_2_rounded,
                    accent: AppTheme.statusCompleted,
                    width: 42,
                    height: 42,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.name, style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: _txtP)),
                    const SizedBox(height: 3),
                    Text('${a.category}  ·  Qty: ${a.quantityAvailable}',
                        style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 11, color: _txtS)),
                  ])),
                  if (sel)
                    Container(width: 24, height: 24,
                      decoration: const BoxDecoration(
                          color: AppTheme.tenantPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)),
                ]),
              ),
            );
          }),
        ] else
          _emptyStep(Icons.inventory_2_outlined,
              'No available assets', 'All assets are currently in use.'),
      ]),
    );
  }

  // Step 2 — Schedule
  Widget _step2Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date picker
        Text('Select Date', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14, fontWeight: FontWeight.w600, color: _txtP)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppTheme.tenantPrimary,
                    brightness: _isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _date = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _date != null
                  ? AppTheme.tenantPrimary.withOpacity(_isDark ? 0.15 : 0.07)
                  : _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _date != null ? AppTheme.tenantPrimary : _div,
                  width: _date != null ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calendar_month_outlined,
                    color: AppTheme.tenantPrimary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _date == null
                    ? 'Tap to choose a date'
                    : '${_date!.day} ${_monthName(_date!.month)} ${_date!.year}',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                    fontWeight: _date != null
                        ? FontWeight.w600 : FontWeight.w400,
                    color: _date != null ? AppTheme.tenantPrimary : _txtS),
              )),
              Icon(Icons.chevron_right_rounded,
                  color: _txtH, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Text('Select Time Slot', style: TextStyle(fontFamily: 'Poppins',
            fontSize: 14, fontWeight: FontWeight.w600, color: _txtP)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10,
              mainAxisSpacing: 10, childAspectRatio: 2.2),
          itemCount: _timeSlots.length,
          itemBuilder: (_, i) {
            final slot = _timeSlots[i];
            final sel  = _timeSlot == slot;
            return GestureDetector(
              onTap: () => setState(() => _timeSlot = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.tenantPrimary
                      : (_isDark ? AppTheme.darkInput : AppTheme.surface),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppTheme.tenantPrimary : _div,
                  ),
                ),
                child: Center(child: Text(slot, style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : _txtP))),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // Step 3 — Confirm
  Widget _step3Confirm(BookingModel? booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppTheme.tenantPrimary.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppTheme.tenantPrimary.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.assignment_turned_in_outlined,
                    color: AppTheme.tenantPrimary, size: 20)),
              const SizedBox(width: 12),
              Text('Assignment Summary', style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 15,
                  fontWeight: FontWeight.w700, color: _txtP)),
            ]),
            const SizedBox(height: 18),
            Divider(color: _div, height: 1),
            const SizedBox(height: 16),
            if (booking != null) ...[
              _confirmRow('Service', booking.serviceName,
                  Icons.home_repair_service_outlined),
              _confirmRow('Customer', booking.userName,
                  Icons.person_outline_rounded),
            ],
            _confirmRow('Provider', _provider?.fullName ?? '—',
                Icons.engineering_outlined),
            _confirmRow('Assets', _assets.isEmpty
                ? 'No asset'
                : _assets.map((asset) => asset.name).join(', '),
                Icons.inventory_2_outlined),
            _confirmRow('Date',
                _date != null
                    ? '${_date!.day} ${_monthName(_date!.month)} ${_date!.year}'
                    : '—',
                Icons.calendar_today_outlined),
            _confirmRow('Time', _timeSlot ?? '—',
                Icons.access_time_rounded),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.statusCompleted.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.statusCompleted.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.statusCompleted, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
                'The provider will be notified once assigned. '
                'The tenant view will update to "Assigned" while the user sees "Finding a provider..." until the provider accepts.',
                style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12, color: _txtP, height: 1.5))),
          ]),
        ),
      ]),
    );
  }

  Widget _confirmRow(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 30, height: 30,
        decoration: BoxDecoration(
            color: AppTheme.tenantPrimary.withOpacity(_isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.tenantPrimary, size: 15)),
      const SizedBox(width: 10),
      SizedBox(width: 80, child: Text('$label:',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _txtS))),
      Expanded(child: Text(value, style: TextStyle(fontFamily: 'Poppins',
          fontSize: 13, fontWeight: FontWeight.w600, color: _txtP))),
    ]),
  );

  // ── Footer nav ────────────────────────────────────────────────────────
  Widget _footer(BookingModel? booking) {
    final isLast = _step == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _div)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(_isDark ? 0.3 : 0.06),
          blurRadius: 10, offset: const Offset(0, -3),
        )],
      ),
      child: Row(children: [
        if (_step > 0)
          Expanded(child: OutlinedButton(
            onPressed: _prevStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.tenantPrimary,
              side: BorderSide(color: AppTheme.tenantPrimary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('← Back', style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600)),
          )),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(flex: 2, child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _canProceed
                  ? (_isDark
                      ? [const Color(0xFF3B0764), AppTheme.tenantPrimary]
                      : [AppTheme.tenantDark, AppTheme.tenantPrimary])
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _canProceed ? [BoxShadow(
              color: AppTheme.tenantPrimary.withOpacity(0.35),
              blurRadius: 10, offset: const Offset(0, 4),
            )] : [],
          ),
          child: ElevatedButton(
            onPressed: _canProceed
                ? (isLast ? (_submitting ? null : _submit) : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(
                    isLast ? 'Confirm & Assign' : 'Next →',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
                        fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        )),
      ]),
    );
  }

  Widget _emptyStep(IconData icon, String title, String sub) =>
      Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 52, color: AppTheme.tenantPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
              fontWeight: FontWeight.w600, color: _txtP)),
          const SizedBox(height: 8),
          Text(sub, textAlign: TextAlign.center, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
        ]),
      ));

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
