import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard       : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground  : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _div     => _isDark ? AppTheme.darkDivider     : AppTheme.dividerColor;

  // Full 5-step timeline (tenant sees all steps)
  static const _timeline = [
    'Requested', 'Assigned', 'Accepted', 'In Progress', 'Completed',
  ];

  int _stepFor(String status) {
    switch (status) {
      case AppConstants.statusRequested:  return 0;
      case AppConstants.statusAssigned:   return 1;
      case AppConstants.statusAccepted:   return 2;
      case AppConstants.statusInProgress: return 3;
      case AppConstants.statusCompleted:  return 4;
      default:                            return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BookingService>().fetchBookingById(widget.orderId);
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.w700, color: _txtP)),
        content: Text(
          'This will cancel the booking and release any assigned assets.',
          style: TextStyle(color: _txtS, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Booking', style: TextStyle(color: _txtS)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final svc = context.read<BookingService>();
    final ok = await svc.cancelBooking(booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Booking cancelled.' : (svc.error ?? 'Could not cancel.')),
        backgroundColor: ok ? AppTheme.statusCompleted : AppTheme.statusInactive,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<BookingService>();
    final booking = svc.selectedBooking;
    final w       = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context, booking),
        Expanded(
          child: svc.isLoading || booking == null
              ? _skeleton()
              : FadeTransition(
                  opacity: _fadeCtrl,
                  child: w > 700
                      ? _wideLayout(booking)
                      : _narrowLayout(booking),
                ),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext ctx, BookingModel? b) {
    final isCancelled = b?.status == AppConstants.statusCancelled;
    final needsReassign = b?.isProviderRejected == true;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => ctx.pop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Details',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (b != null)
                    Text(
                      '#${b.id.length > 8 ? b.id.substring(0, 8).toUpperCase() : b.id}',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75)),
                    ),
                ],
              ),
            ),
            // Only show Assign button when status is Requested and not cancelled
            if (b != null && (b.isRequested || needsReassign) && !isCancelled)
              ElevatedButton.icon(
                onPressed: () => ctx.push(
                    AppRoutes.assignProvider.replaceAll(':orderId', b.id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.tenantPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.assignment_ind_outlined, size: 15),
                label: Text(needsReassign ? 'Reassign' : 'Assign',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            // Show cancelled badge in header
            if (isCancelled)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cancel_outlined,
                      color: AppTheme.statusCancelled, size: 14),
                  SizedBox(width: 5),
                  Text('Cancelled',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusCancelled)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Narrow layout ──────────────────────────────────────────────────────
  Widget _narrowLayout(BookingModel b) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _statusBanner(b),
        const SizedBox(height: 14),
        _timelineCard(b.status),
        const SizedBox(height: 14),
        _section('Customer', Icons.person_outline_rounded, [
          _row('Name',    b.userName),
          _row('Phone',   b.userPhone.isEmpty ? '—' : b.userPhone),
          _row('Address', b.userAddress.isEmpty ? '—' : b.userAddress),
        ]),
        const SizedBox(height: 14),
        _section('Service', Icons.home_repair_service_outlined, [
          _row('Service',     b.serviceName),
          _row('Category',    b.serviceCategory.isEmpty ? '—' : b.serviceCategory),
          _row('Description', b.problemDescription.isEmpty ? '—' : b.problemDescription),
        ]),
        const SizedBox(height: 14),
        _section('Schedule', Icons.calendar_today_outlined, [
          _row('Preferred Date', b.preferredDate),
          _row('Preferred Time', b.preferredTime),
          if (b.scheduledDate?.isNotEmpty == true)
            _row('Scheduled', '${b.scheduledDate}  ·  ${b.scheduledTime ?? '—'}'),
        ]),
        if (b.hasProvider) ...[
          const SizedBox(height: 14),
          _section('Assigned Provider', Icons.engineering_outlined, [
            _row('Provider', b.assignedProviderName ?? '—'),
            _row('Phone',    b.assignedProviderPhone ?? '—'),
          ]),
        ],
        if (b.assignedAssetName != null) ...[
          const SizedBox(height: 14),
          _section('Asset', Icons.inventory_2_outlined, [
            _row('Asset', b.assignedAssetName!),
            _row('Estimated Cost', _money(b.assignedAssetPrice)),
          ]),
        ],
        const SizedBox(height: 14),
        _costBreakdownCard(b),
        const SizedBox(height: 16),
        _actionArea(b),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Wide layout (tablet) ───────────────────────────────────────────────
  Widget _wideLayout(BookingModel b) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 5, child: Column(children: [
          _statusBanner(b),
          const SizedBox(height: 14),
          _timelineCard(b.status),
          const SizedBox(height: 14),
          _section('Schedule', Icons.calendar_today_outlined, [
            _row('Preferred', '${b.preferredDate}  ·  ${b.preferredTime}'),
            if (b.scheduledDate?.isNotEmpty == true)
              _row('Scheduled', '${b.scheduledDate}  ·  ${b.scheduledTime ?? '—'}'),
          ]),
          const SizedBox(height: 14),
          _actionArea(b),
        ])),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: Column(children: [
          _section('Customer', Icons.person_outline_rounded, [
            _row('Name',    b.userName),
            _row('Phone',   b.userPhone.isEmpty ? '—' : b.userPhone),
            _row('Address', b.userAddress.isEmpty ? '—' : b.userAddress),
          ]),
          const SizedBox(height: 14),
          _section('Service', Icons.home_repair_service_outlined, [
            _row('Service',  b.serviceName),
            _row('Category', b.serviceCategory.isEmpty ? '—' : b.serviceCategory),
            _row('Notes',    b.problemDescription.isEmpty ? '—' : b.problemDescription),
          ]),
          if (b.hasProvider) ...[
            const SizedBox(height: 14),
            _section('Provider', Icons.engineering_outlined, [
              _row('Assigned', b.assignedProviderName ?? '—'),
              _row('Phone',    b.assignedProviderPhone ?? '—'),
            ]),
          ],
          if (b.assignedAssetName != null) ...[
            const SizedBox(height: 14),
            _section('Asset', Icons.inventory_2_outlined, [
              _row('Asset', b.assignedAssetName!),
              _row('Estimated Cost', _money(b.assignedAssetPrice)),
            ]),
          ],
          const SizedBox(height: 14),
          _costBreakdownCard(b),
        ])),
      ]),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────
  Widget _statusBanner(BookingModel b) {
    final isCancelled = b.status == AppConstants.statusCancelled;
    final displayStatus = b.tenantFacingStatusLabel;
    final sc = isCancelled
        ? AppTheme.statusInactive
        : AppTheme.getStatusColor(displayStatus);
    final sb = isCancelled
        ? AppTheme.statusInactive.withOpacity(0.5)
        : AppTheme.getStatusBgColor(displayStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sb.withOpacity(_isDark ? 0.35 : .6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: sc.withOpacity(_isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isCancelled
                ? Icons.cancel_outlined
                : Icons.receipt_long_rounded,
            color: sc,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _txtP),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: sc)),
              const SizedBox(width: 6),
              Text(displayStatus,
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sc)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── 5-step timeline card with cancelled overlay ────────────────────────
  Widget _timelineCard(String current) {
    final isCancelled = current == AppConstants.statusCancelled;
    final booking = context.read<BookingService>().selectedBooking;
    final currIdx = isCancelled
        ? -1
        : booking?.isProviderRejected == true
            ? 1
            : _stepFor(current);

    return _card('Order Timeline', Icons.timeline_rounded,
      Column(
        children: _timeline.asMap().entries.map((e) {
          final idx    = e.key;
          final step   = e.value;
          final done   = !isCancelled && idx <= currIdx;
          final curr   = !isCancelled && idx == currIdx;
          final isLast = idx == _timeline.length - 1;

          Color dotColor, borderColor;
          if (isCancelled) {
            dotColor    = _isDark ? AppTheme.darkInput : Colors.grey.shade100;
            borderColor = AppTheme.statusInactive.withOpacity(0.25);
          } else if (done) {
            dotColor    = AppTheme.tenantPrimary;
            borderColor = AppTheme.tenantPrimary;
          } else if (curr) {
            dotColor    = _isDark ? AppTheme.darkInput : AppTheme.surface;
            borderColor = AppTheme.tenantPrimary;
          } else {
            dotColor    = _isDark ? AppTheme.darkInput : AppTheme.surface;
            borderColor = _div;
          }

          final lineColor = (!isCancelled && idx < currIdx)
              ? AppTheme.tenantPrimary
              : isCancelled
                  ? AppTheme.statusInactive.withOpacity(0.2)
                  : _div;

          final textColor = isCancelled
              ? _txtS.withOpacity(0.5)
              : curr
                  ? AppTheme.tenantPrimary
                  : done
                      ? _txtP
                      : _txtS;

          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 28, child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: borderColor,
                      width: curr ? 2.5 : 1.5),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle,
                  size: done ? 14 : 8,
                  color: done ? Colors.white : borderColor,
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 26, color: lineColor),
            ])),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(children: [
                  Expanded(
                    child: Text(step,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: curr
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: textColor)),
                  ),
                  if (curr && !isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tenantPrimary
                            .withOpacity(_isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Current',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tenantPrimary)),
                    ),
                  if (isCancelled && idx == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.statusInactive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Cancelled',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusInactive)),
                    ),
                ]),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  // ── Action area ────────────────────────────────────────────────────────
  Widget _actionArea(BookingModel b) {
    final isCancelled = b.status == AppConstants.statusCancelled;
    final needsReassign = b.isProviderRejected;

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.statusCancelled.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.statusCancelled.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.statusCancelled, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This order was cancelled before being assigned.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppTheme.statusCancelled),
            ),
          ),
        ]),
      );
    }

    if (needsReassign) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.statusInactive.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.statusInactive.withOpacity(0.25),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.statusInactive, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'The assigned provider rejected this booking. Reassign a new provider to continue.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _txtP,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go(
              AppRoutes.assignProvider.replaceAll(':orderId', b.id),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tenantPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.assignment_ind_rounded,
                color: Colors.white, size: 18),
            label: const Text('Reassign Provider',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ),
        if (b.canTenantCancel) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(b),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel Booking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statusInactive,
                side: const BorderSide(color: AppTheme.statusInactive),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]);
    }

    if (b.isRequested) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.statusPending.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.statusPending.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.statusPending, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Waiting for provider assignment.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: _txtP)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go(
                AppRoutes.assignProvider.replaceAll(':orderId', b.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tenantPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.assignment_ind_rounded,
                color: Colors.white, size: 18),
            label: const Text('Assign Provider',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]);
    }

    if (b.canTenantCancel) {
      return Column(children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _cancelBooking(b),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel Booking'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.statusInactive,
              side: const BorderSide(color: AppTheme.statusInactive),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]);
    }

    return const SizedBox.shrink();
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  Widget _costBreakdownCard(BookingModel b) {
    final cost = b.costBreakdown;
    final rows = <Widget>[
      _row('Service', _money(cost.service)),
      if (cost.provider > 0) _row('Provider', _money(cost.provider)),
      if (cost.assignedAsset > 0)
        _row(
          b.isCompleted ? 'Assigned Asset' : 'Asset Estimate',
          _money(cost.assignedAsset),
        ),
      if (cost.additionalAssets > 0)
        _row('Extra Assets', _money(cost.additionalAssets)),
      if (b.additionalAssets.isNotEmpty) ...[
        const SizedBox(height: 6),
        ...b.additionalAssets.map((asset) => _row(
              asset['name']?.toString() ?? 'Extra asset',
              _money((asset['price'] as num?)?.toDouble() ?? 0),
            )),
      ],
      Divider(height: 18, color: _div),
      _row(cost.isFinal ? 'Final Total' : 'Estimated Total', _money(cost.total)),
    ];

    return _card(
      cost.isFinal ? 'Final Cost Breakdown' : 'Estimated Cost Breakdown',
      Icons.receipt_long_outlined,
      Column(children: rows),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _card(String title, IconData icon, Widget body) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.tenantPrimary
                .withOpacity(_isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.tenantPrimary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _txtP)),
      ]),
      const SizedBox(height: 12),
      Divider(height: 1, color: _div),
      const SizedBox(height: 12),
      body,
    ]),
  );

  Widget _section(String title, IconData icon, List<Widget> rows) =>
      _card(title, icon, Column(children: rows));

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 100,
        child: Text('$label:',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: _txtS)),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _txtP)),
      ),
    ]),
  );

  Widget _skeleton() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(height: 80, decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(16))),
      const SizedBox(height: 14),
      Container(height: 240, decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(16))),
      const SizedBox(height: 14),
      Container(height: 130, decoration: BoxDecoration(
          color: _cardBg, borderRadius: BorderRadius.circular(16))),
    ]),
  );
}
