import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/booking_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class ProviderTaskDetailScreen extends StatefulWidget {
  final String taskId;
  const ProviderTaskDetailScreen({super.key, required this.taskId});
  @override
  State<ProviderTaskDetailScreen> createState() =>
      _ProviderTaskDetailScreenState();
}

class _ProviderTaskDetailScreenState extends State<ProviderTaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  // ── Status flow (provider can only move forward) ──────────────────────
  static const _flow = {
    'Assigned': 'Accepted',
    'Accepted': 'In Progress',
    'In Progress': 'Completed',
  };

  static const _allSteps = [
    'New Job Assigned', 'Accepted', 'In Progress', 'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BookingService>().fetchBookingById(widget.taskId);
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  String? _nextStatusForBooking(dynamic booking) {
    if (booking.isAssigned || booking.isProviderPending) {
      return AppConstants.statusAccepted;
    }
    return _flow[booking.status];
  }

  Future<void> _updateStatus(String nextStatus) async {
    final booking = context.read<BookingService>().selectedBooking;
    if (nextStatus == AppConstants.statusCompleted &&
        booking?.assignedAssetName != null &&
        booking?.assignedAssetConfirmedUsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Confirm whether the assigned asset was used before completing.',
          ),
          backgroundColor: AppTheme.statusInactive,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Confirm',
            textColor: Colors.white,
            onPressed: () {
              final current = context.read<BookingService>().selectedBooking;
              if (current != null) _editCostDetails(current);
            },
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.2 : 0.1),
              shape: BoxShape.circle),
            child: const Icon(Icons.update_rounded,
                color: AppTheme.providerPrimary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text('Update Status',
              style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700, fontSize: 16, color: _txtP))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Move this job to:', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13, color: _txtS)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.providerPrimary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: AppTheme.providerPrimary, size: 18),
              const SizedBox(width: 10),
              Text('"$nextStatus"',
                  style: const TextStyle(fontFamily: 'Poppins',
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppTheme.providerPrimary)),
            ]),
          ),
          if (nextStatus == 'Completed') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.statusCompleted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.statusCompleted.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.statusCompleted, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'This will mark the job as complete and notify the admin and customer.',
                    style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 11, color: _txtP))),
              ]),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not yet', style: TextStyle(fontFamily: 'Poppins',
                color: _txtS)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.providerPrimary, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Container(
              width: 180, height: 36, alignment: Alignment.center,
              child: Text('Confirm → $nextStatus',
                style: const TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<BookingService>()
        .updateBookingStatus(widget.taskId, nextStatus);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Job moved to "$nextStatus"'
            '${nextStatus == 'Completed' ? ' — Great work! 🎉' : ''}',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: nextStatus == 'Completed'
            ? AppTheme.statusCompleted : AppTheme.providerPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (nextStatus == 'Completed') context.pop();
    }
  }

  Future<void> _rejectBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject Job',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _txtP,
          ),
        ),
        content: Text(
          'Rejecting this job will return it to the tenant for reassignment.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Job', style: TextStyle(color: _txtS)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context
        .read<BookingService>()
        .updateBookingStatus(widget.taskId, 'Rejected');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Job rejected and returned for reassignment.' : 'Could not reject job.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor:
            ok ? AppTheme.statusInactive : AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) context.pop();
  }

  Future<void> _editCostDetails(dynamic booking) async {
    bool? used = booking.assignedAssetConfirmedUsed;
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final extras = booking.additionalAssets
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Assets Used',
              style: TextStyle(fontWeight: FontWeight.w700, color: _txtP)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (booking.assignedAssetName != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    booking.assignedAssetName,
                    style: TextStyle(fontWeight: FontWeight.w700, color: _txtP),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Used'),
                      selected: used == true,
                      onSelected: (_) => setState(() => used = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Not Used'),
                      selected: used == false,
                      onSelected: (_) => setState(() => used = false),
                    ),
                  ],
                ),
              ],
              if (booking.isInProgress) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Additional asset'),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                      if (name.isEmpty) return;
                      setState(() {
                        extras.add({'name': name, 'price': price});
                        nameCtrl.clear();
                        priceCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ),
                ...extras.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['name']?.toString() ?? ''),
                      subtitle: const Text('Additional asset used'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_money((item['price'] as num?)?.toDouble() ?? 0)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => extras.removeAt(index)),
                        ),
                      ]),
                    );
                }),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Close', style: TextStyle(color: _txtS)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.providerPrimary),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    if (saved != true || !mounted) return;

    final ok = await context.read<BookingService>().updateBookingCosts(
          widget.taskId,
          assignedAssetConfirmedUsed: used,
          additionalAssets: booking.isInProgress ? extras : null,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cost details updated.' : 'Could not update costs.'),
        backgroundColor: ok ? AppTheme.statusCompleted : AppTheme.statusInactive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<BookingService>();
    final booking = svc.selectedBooking;
    final w       = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                  : [AppTheme.providerDark, AppTheme.providerPrimary])),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Task Details',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                if (booking != null)
                  Text('#${booking.id.length > 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id}',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                          color: Colors.white.withOpacity(0.75))),
              ])),
              if (booking != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.getStatusColor(
                                booking.providerFacingStatusLabel))),
                    const SizedBox(width: 6),
                    Text(booking.providerFacingStatusLabel, style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 11,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
            ]),
          )),
        ),

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

  // ── Narrow layout ─────────────────────────────────────────────────────
  Widget _narrowLayout(b) {
    final next = _nextStatusForBooking(b);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _statusBanner(b),
            const SizedBox(height: 14),
            _timeline(b.status),
            const SizedBox(height: 14),
            _infoCard('Customer', Icons.person_outline_rounded, [
              _row('Name',    b.userName),
              _row('Phone',   b.userPhone.isEmpty ? '—' : b.userPhone),
              _row('Address', b.userAddress.isEmpty ? '—' : b.userAddress),
            ]),
            const SizedBox(height: 14),
            _infoCard('Service', Icons.home_repair_service_outlined, [
              _row('Service',  b.serviceName),
              _row('Category', b.serviceCategory.isEmpty ? '—' : b.serviceCategory),
              _row('Issue',    b.problemDescription.isEmpty
                  ? 'No details' : b.problemDescription),
            ]),
            const SizedBox(height: 14),
            _infoCard('Schedule', Icons.calendar_today_outlined, [
              _row('Scheduled',
                  '${b.scheduledDate ?? b.preferredDate}  ·  ${b.scheduledTime ?? b.preferredTime}'),
            ]),
            if (b.assignedAssetName != null) ...[
              const SizedBox(height: 14),
              _infoCard('Assigned Asset', Icons.inventory_2_outlined, [
                _row('Asset', b.assignedAssetName!),
                _row('Estimated Cost', _money(b.assignedAssetPrice)),
                _row(
                  'Usage',
                  b.assignedAssetConfirmedUsed == null
                      ? 'Not confirmed'
                      : b.assignedAssetConfirmedUsed == true
                          ? 'Used'
                          : 'Not used',
                ),
              ]),
            ],
            const SizedBox(height: 14),
            _costBreakdownCard(b),
            const SizedBox(height: 16),
          ]),
        ),
      ),
      // ── Sticky action footer ────────────────────────────────────────
      if (next != null) _actionFooter(next),
    ]);
  }

  // ── Wide layout (tablet) ──────────────────────────────────────────────
  Widget _wideLayout(b) {
    final next = _nextStatusForBooking(b);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 5, child: Column(children: [
              _statusBanner(b),
              const SizedBox(height: 14),
              _timeline(b.status),
              const SizedBox(height: 14),
              _infoCard('Schedule', Icons.calendar_today_outlined, [
                _row('Scheduled',
                    '${b.scheduledDate ?? b.preferredDate}  ·  ${b.scheduledTime ?? b.preferredTime}'),
              ]),
            ])),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: Column(children: [
              _infoCard('Customer', Icons.person_outline_rounded, [
                _row('Name',    b.userName),
                _row('Phone',   b.userPhone.isEmpty ? '—' : b.userPhone),
                _row('Address', b.userAddress.isEmpty ? '—' : b.userAddress),
              ]),
              const SizedBox(height: 14),
              _infoCard('Service', Icons.home_repair_service_outlined, [
                _row('Service',  b.serviceName),
                _row('Issue',    b.problemDescription.isEmpty
                    ? 'No details' : b.problemDescription),
              ]),
              if (b.assignedAssetName != null) ...[
                const SizedBox(height: 14),
                _infoCard('Asset', Icons.inventory_2_outlined, [
                  _row('Asset', b.assignedAssetName!),
                  _row('Estimated Cost', _money(b.assignedAssetPrice)),
                  _row(
                    'Usage',
                    b.assignedAssetConfirmedUsed == null
                        ? 'Not confirmed'
                        : b.assignedAssetConfirmedUsed == true
                            ? 'Used'
                            : 'Not used',
                  ),
                ]),
              ],
              const SizedBox(height: 14),
              _costBreakdownCard(b),
            ])),
          ]),
        ),
      ),
      if (next != null) _actionFooter(next),
    ]);
  }

  // ── Status banner ─────────────────────────────────────────────────────
  Widget _statusBanner(b) {
    final displayStatus = b.providerFacingStatusLabel;
    final sc = AppTheme.getStatusColor(displayStatus);
    final sb = AppTheme.getStatusBgColor(displayStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sb.withOpacity(_isDark ? 0.4 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(
              color: sc.withOpacity(_isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(Icons.home_repair_service_rounded,
              color: sc, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.serviceName, style: TextStyle(fontFamily: 'Poppins',
              fontSize: 16, fontWeight: FontWeight.w700, color: _txtP),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: sc)),
            const SizedBox(width: 6),
            Text(displayStatus, style: TextStyle(fontFamily: 'Poppins',
                fontSize: 13, fontWeight: FontWeight.w600, color: sc)),
          ]),
        ])),
      ]),
    );
  }

  // ── Animated timeline ─────────────────────────────────────────────────
  Widget _timeline(String current) {
    final booking = context.read<BookingService>().selectedBooking;
    final currentLabel = booking?.providerFacingStatusLabel ?? current;
    final currIdx = _allSteps.indexOf(currentLabel);
    return _card('Progress Timeline', Icons.timeline_rounded,
      Column(children: _allSteps.asMap().entries.map((e) {
        final idx    = e.key;
        final status = e.value;
        final done   = idx <= currIdx;
        final curr   = idx == currIdx;
        final isLast = idx == _allSteps.length - 1;

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 24, child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppTheme.providerPrimary
                    : (_isDark ? AppTheme.darkInput : AppTheme.surface),
                border: Border.all(
                  color: done
                      ? AppTheme.providerPrimary : _div,
                  width: curr ? 2.5 : 1.5,
                ),
              ),
              child: Icon(done ? Icons.check_rounded : Icons.circle,
                  size: done ? 13 : 7,
                  color: done ? Colors.white : _div),
            ),
            if (!isLast)
              Container(width: 2, height: 28,
                  color: idx < currIdx
                      ? AppTheme.providerPrimary : _div),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(children: [
              Expanded(child: Text(status, style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: curr ? FontWeight.w700 : FontWeight.w400,
                  color: curr ? AppTheme.providerPrimary
                      : done ? _txtP : _txtS))),
              if (curr)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.providerPrimary.withOpacity(
                        _isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('Current', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.providerPrimary)),
                ),
            ]),
          )),
        ]);
      }).toList()),
    );
  }

  // ── Sticky action footer ──────────────────────────────────────────────
  Widget _actionFooter(String next) {
    final booking = context.read<BookingService>().selectedBooking;
    final canReject = booking != null && (booking.isAssigned || booking.isProviderPending);

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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Progress steps
        _compactStepRow(),
        const SizedBox(height: 14),
        // Action button
        Row(children: [
          if (booking != null &&
              (booking.isAccepted || booking.isInProgress)) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editCostDetails(booking),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.providerPrimary,
                  side: BorderSide(
                    color: AppTheme.providerPrimary.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text(
                  'Costs',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (canReject) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _rejectBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.statusInactive,
                  side: BorderSide(
                    color: AppTheme.statusInactive.withOpacity(0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'Reject',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: canReject ? 2 : 1,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDark
                      ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                      : [AppTheme.providerDark, AppTheme.providerPrimary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                  color: AppTheme.providerPrimary.withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                )],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(next),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 18),
                label: Text('Mark as "$next"',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _compactStepRow() {
    final svc     = context.read<BookingService>();
    final booking = svc.selectedBooking;
    if (booking == null) return const SizedBox.shrink();
    final currIdx = _allSteps.indexOf(booking.providerFacingStatusLabel);

    return Row(
      children: _allSteps.asMap().entries.map((e) {
        final idx  = e.key;
        final done = idx <= currIdx;
        final curr = idx == currIdx;
        return Expanded(child: Row(children: [
          Expanded(child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppTheme.providerPrimary
                    : (_isDark ? AppTheme.darkInput : AppTheme.surface),
                border: Border.all(
                    color: done ? AppTheme.providerPrimary : _div,
                    width: curr ? 2 : 1),
              ),
              child: Icon(done ? Icons.check_rounded : Icons.circle,
                  size: done ? 14 : 7,
                  color: done ? Colors.white : _div),
            ),
            const SizedBox(height: 3),
            Text(e.value, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 8,
                    fontWeight: curr ? FontWeight.w700 : FontWeight.w400,
                    color: curr ? AppTheme.providerPrimary : _txtS)),
          ])),
          if (idx < _allSteps.length - 1)
            Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18),
                color: idx < currIdx ? AppTheme.providerPrimary : _div)),
        ]));
      }).toList(),
    );
  }

  // ── Reusable section card ─────────────────────────────────────────────
  Widget _card(String title, IconData icon, Widget body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.providerPrimary, size: 17)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w600, color: _txtP)),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: _div),
        const SizedBox(height: 12),
        body,
      ]),
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> rows) =>
      _card(title, icon, Column(children: rows));

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  Widget _costBreakdownCard(b) {
    final cost = b.costBreakdown;
    return _card(
      cost.isFinal ? 'Final Cost Breakdown' : 'Estimated Cost Breakdown',
      Icons.receipt_long_outlined,
      Column(children: [
        _row('Service', _money(cost.service)),
        if (cost.provider > 0) _row('Provider', _money(cost.provider)),
        if (cost.assignedAsset > 0)
          _row(cost.isFinal ? 'Assigned Asset' : 'Asset Estimate',
              _money(cost.assignedAsset)),
        if (cost.additionalAssets > 0)
          _row('Extra Assets', _money(cost.additionalAssets)),
        if (b.additionalAssets.isNotEmpty) ...[
          const SizedBox(height: 6),
          _additionalAssetsList(b.additionalAssets),
        ],
        Divider(height: 18, color: _div),
        _row(cost.isFinal ? 'Final Total' : 'Estimated Total',
            _money(cost.total)),
      ]),
    );
  }

  Widget _additionalAssetsList(List<Map<String, dynamic>> assets) {
    return Column(
      children: assets.map((asset) {
        final name = asset['name']?.toString().trim();
        final price = (asset['price'] as num?)?.toDouble() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.providerPrimary.withOpacity(_isDark ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.providerPrimary.withOpacity(0.14),
            ),
          ),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.providerPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppTheme.providerPrimary, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name?.isNotEmpty == true ? name! : 'Additional asset',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _txtP),
              ),
            ),
            Text(_money(price),
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _txtP)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text('$label:', style: TextStyle(
          fontFamily: 'Poppins', fontSize: 12, color: _txtS))),
      Expanded(child: Text(value, style: TextStyle(fontFamily: 'Poppins',
          fontSize: 13, fontWeight: FontWeight.w500, color: _txtP))),
    ]),
  );

  Widget _skeleton() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(height: 80, decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(16))),
      const SizedBox(height: 14),
      Container(height: 200, decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(16))),
      const SizedBox(height: 14),
      Container(height: 120, decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(16))),
    ]),
  );
}
