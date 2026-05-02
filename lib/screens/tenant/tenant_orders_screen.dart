import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class TenantOrdersScreen extends StatefulWidget {
  const TenantOrdersScreen({super.key});
  @override
  State<TenantOrdersScreen> createState() => _TenantOrdersScreenState();
}

class _TenantOrdersScreenState extends State<TenantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  // ── Tab config: index 4 = Cancelled ──────────────────────────────────
  static const _tabLabels = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled'];

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkSurface : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() =>
      context.read<BookingService>().fetchBookingsForAdmin();

  List<BookingModel> _forTab(BookingService svc, int idx) {
    List<BookingModel> base;
    switch (idx) {
      case 1:  base = svc.pendingBookings;    break;
      case 2:  base = svc.inProgressBookings; break;
      case 3:  base = svc.completedBookings;  break;
      case 4:  base = svc.cancelledBookings;  break;
      default: base = svc.bookings;
    }
    if (_query.isEmpty) return base;
    final q = _query.toLowerCase();
    return base.where((b) =>
        b.serviceName.toLowerCase().contains(q) ||
        b.userName.toLowerCase().contains(q) ||
        b.id.toLowerCase().contains(q)).toList();
  }

  // ── Cancel booking (before assignment only) ───────────────────────────
  Future<void> _cancelBooking(BookingModel b) async {
    if (b.isCompleted || b.isCancelled) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Cancel Order',
            style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700, color: _txtP)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.statusInactive.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.statusInactive.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.statusInactive, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                  'This order is unassigned and can be cancelled. '
                  'Once cancelled it cannot be undone.',
                  style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 12, color: _txtP))),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Cancel "${b.serviceName}" for ${b.userName}?',
              style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 13, color: _txtS)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Order',
                style: TextStyle(fontFamily: 'Poppins', color: _txtS)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Order',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final svc = context.read<BookingService>();
      final ok = await svc.cancelBooking(b.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Order cancelled' : svc.error ?? 'Failed to cancel',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: ok ? AppTheme.statusInactive : AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();
    final w   = MediaQuery.of(context).size.width;

    // Tab counts
    final counts = [
      svc.bookings.length,
      svc.pendingBookings.length,
      svc.inProgressBookings.length,
      svc.completedBookings.length,
      svc.cancelledBookings.length,
    ];

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────
        _buildHeader(context, svc),

        // ── Summary strip ──────────────────────────────────────────────
        _summaryStrip(svc),

        // ── Tab bar ────────────────────────────────────────────────────
        Container(
          color: _cardBg,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontFamily: 'Poppins',
                fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12),
            labelColor: AppTheme.tenantPrimary,
            unselectedLabelColor: _txtS,
            indicatorColor: AppTheme.tenantPrimary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _tabLabels.asMap().entries.map((e) {
              final sel = _tabs.index == e.key;
              final cnt = counts[e.key];
              // Cancelled tab gets red badge
              final badgeColor = e.key == 4
                  ? AppTheme.statusInactive
                  : AppTheme.tenantPrimary;
              return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e.value),
                if (cnt > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel
                          ? badgeColor
                          : (_isDark ? AppTheme.darkInput : AppTheme.surface),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$cnt', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : _txtS)),
                  ),
                ],
              ]));
            }).toList(),
            onTap: (_) => setState(() {}),
          ),
        ),
        Divider(height: 1, color: _div),

        // ── Tab views ──────────────────────────────────────────────────
        Expanded(
          child: svc.isLoading
              ? _skeleton()
              : TabBarView(
                  controller: _tabs,
                  children: List.generate(_tabLabels.length, (i) {
                    final list = _forTab(svc, i);
                    if (list.isEmpty) return _emptyTab(i);
                    return RefreshIndicator(
                      color: AppTheme.tenantPrimary,
                      onRefresh: _load,
                      child: w > 700
                          ? _gridView(list)
                          : _listView(list),
                    );
                  }),
                ),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, BookingService svc) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF181C31), AppTheme.tenantDark]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary])),
      child: SafeArea(bottom: false, child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 15, 15),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Service Orders',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${svc.totalOrders} total  ·  '
                  '${svc.requestedBookings.length} need attention',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                      color: Colors.white.withOpacity(0.75))),
            ])),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isDark
                        ? Colors.white.withOpacity(0.14)
                        : Colors.white.withOpacity(0.55))),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _isDark ? Colors.white : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by service, customer, or ID...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _isDark
                      ? Colors.white.withOpacity(0.6)
                      : AppTheme.textSecondary,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: _isDark
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.textSecondary,
                    size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: _isDark
                                ? Colors.white.withOpacity(0.8)
                                : AppTheme.textSecondary,
                            size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ])),
    );
  }

  // ── Summary strip ─────────────────────────────────────────────────────
  Widget _summaryStrip(BookingService svc) {
    final items = [
      (svc.requestedBookings.length, 'Requested',  AppTheme.statusRequested),
      (svc.assignedBookings.length,  'Assigned',   AppTheme.statusAssigned),
      (svc.inProgressCount,           'In Progress', AppTheme.statusInProgress),
      (svc.completedCount,            'Completed',  AppTheme.statusCompleted),
      (svc.cancelledBookings.length,  'Cancelled',  AppTheme.statusInactive),
    ];
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(children: items.map((item) {
        final (n, l, c) = item;
        return Expanded(child: Column(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: n.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(v.toInt().toString(),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: c)),
          ),
          const SizedBox(height: 2),
          Text(l, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 9, color: _txtS)),
        ]));
      }).toList()),
    );
  }

  // ── List view ─────────────────────────────────────────────────────────
  Widget _listView(List<BookingModel> orders) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(
        key: ValueKey(orders[i].id),
        booking: orders[i],
        index: i,
        isDark: _isDark, cardBg: _cardBg,
        txtP: _txtP, txtS: _txtS, txtH: _txtH, div: _div,
        onTap: () => context.go(
            AppRoutes.orderDetail.replaceAll(':orderId', orders[i].id)),
        onAssign: () => context.go(
            AppRoutes.assignProvider.replaceAll(':orderId', orders[i].id)),
        onCancel: !orders[i].isCompleted && !orders[i].isCancelled
            ? () => _cancelBooking(orders[i])
            : null,
      ),
    );
  }

  // ── Grid (tablet) ─────────────────────────────────────────────────────
  Widget _gridView(List<BookingModel> orders) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14,
          mainAxisSpacing: 14, childAspectRatio: 0.98),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(
        key: ValueKey(orders[i].id),
        booking: orders[i], index: i,
        isDark: _isDark, cardBg: _cardBg,
        txtP: _txtP, txtS: _txtS, txtH: _txtH, div: _div,
        onTap: () => context.go(
            AppRoutes.orderDetail.replaceAll(':orderId', orders[i].id)),
        onAssign: () => context.go(
            AppRoutes.assignProvider.replaceAll(':orderId', orders[i].id)),
        onCancel: !orders[i].isCompleted && !orders[i].isCancelled
            ? () => _cancelBooking(orders[i])
            : null,
      ),
    );
  }

  Widget _skeleton() => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: 4,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 12), height: 120,
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(18)),
    ),
  );

  Widget _emptyTab(int tabIdx) {
    final msgs = [
      'No orders found', 'No pending orders',
      'Nothing in progress', 'No completed orders', 'No cancelled orders',
    ];
    final icons = [
      Icons.receipt_long_outlined, Icons.hourglass_empty_rounded,
      Icons.pending_actions_outlined, Icons.task_alt_rounded,
      Icons.cancel_outlined,
    ];
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(
              color: _isDark ? AppTheme.darkSurface : AppTheme.tenantLight,
              shape: BoxShape.circle),
          child: Icon(icons[tabIdx], size: 34,
              color: tabIdx == 4
                  ? AppTheme.statusInactive.withOpacity(0.6)
                  : AppTheme.tenantPrimary.withOpacity(0.6))),
      const SizedBox(height: 16),
      Text(_query.isNotEmpty ? 'No results for "$_query"' : msgs[tabIdx],
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w500, color: _txtP)),
      const SizedBox(height: 8),
      Text(_query.isNotEmpty ? 'Try a different search' : 'All caught up!',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  ORDER CARD — supports cancelled state + cancel action
// ══════════════════════════════════════════════════════════════════════
class _OrderCard extends StatefulWidget {
  final BookingModel booking;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onTap, onAssign;
  final VoidCallback? onCancel;

  const _OrderCard({
    super.key, required this.booking, required this.index,
    required this.isDark, required this.cardBg,
    required this.txtP, required this.txtS, required this.txtH,
    required this.div, required this.onTap, required this.onAssign,
    this.onCancel,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    Future.delayed(Duration(milliseconds: widget.index * 55),
        () { if (mounted) _ctrl.forward(); });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b           = widget.booking;
    final isCancelled = b.isCancelled;
    final needsAssign = (b.isRequested || b.isProviderRejected) && !isCancelled;
    final displayStatus = b.tenantFacingStatusLabel;
    final statusColor = AppTheme.getStatusColor(displayStatus);
    final statusBg    = AppTheme.getStatusBgColor(displayStatus);
    final cardColor = widget.isDark
        ? (isCancelled ? const Color(0xFF2A1E28) : AppTheme.darkCard)
        : (isCancelled ? const Color(0xFFFFF3F3) : widget.cardBg);
    final borderColor = isCancelled
        ? AppTheme.statusInactive.withOpacity(widget.isDark ? 0.38 : 0.25)
        : needsAssign
            ? (widget.isDark
                ? AppTheme.tenantPrimary.withOpacity(0.45)
                : AppTheme.statusPending.withOpacity(0.4))
            : widget.div;
    final iconChipBg = widget.isDark
        ? statusColor.withOpacity(0.16)
        : statusBg;
    final statusChipBg = widget.isDark
        ? statusColor.withOpacity(0.14)
        : statusBg;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(opacity: _ctrl.value,
          child: Transform.translate(
              offset: Offset(0, 22 * (1 - _ctrl.value)), child: child)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: (isCancelled || needsAssign) ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.18 : 0.05),
              blurRadius: widget.isDark ? 18 : 10,
              offset: const Offset(0, 4),
            )],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Top row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Cancelled shows strikethrough overlay
                Stack(children: [
                  Container(width: 46, height: 46,
                    decoration: BoxDecoration(
                        color: iconChipBg,
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(Icons.receipt_outlined,
                        size: 22, color: statusColor)),
                  if (isCancelled)
                    Container(width: 46, height: 46,
                        decoration: BoxDecoration(
                            color: AppTheme.statusInactive.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.block_rounded,
                            size: 20, color: AppTheme.statusInactive)),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.serviceName,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? widget.txtS
                              : widget.txtP,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('#${b.id.length > 6 ? b.id.substring(0, 6).toUpperCase() : b.id}',
                      style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 10, color: widget.txtH)),
                ])),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusChipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: statusColor)),
                    const SizedBox(width: 4),
                    Text(displayStatus, style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: statusColor)),
                  ]),
                ),
              ]),
            ),

            // ── Info rows ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(children: [
                _infoRow(Icons.person_outline_rounded, b.userName),
                const SizedBox(height: 4),
                _infoRow(Icons.location_on_outlined,
                    b.userAddress.isEmpty ? 'No address' : b.userAddress),
                const SizedBox(height: 4),
                _infoRow(Icons.calendar_today_outlined,
                    '${b.preferredDate}  ·  ${b.preferredTime}'),
                if (b.hasProvider) ...[
                  const SizedBox(height: 4),
                  _infoRow(Icons.engineering_outlined,
                      b.assignedProviderName ?? ''),
                ],
              ]),
            ),

            // ── Action footer ─────────────────────────────────────────
            if (!isCancelled) ...[
              if (needsAssign) ...[
                // Assign button + optional cancel
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: widget.onAssign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tenantPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.assignment_ind_outlined,
                            color: Colors.white, size: 15),
                        label: Text(b.isProviderRejected ? 'Reassign' : 'Assign',
                            style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                    if (widget.onCancel != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusInactive,
                            side: BorderSide(
                                color: AppTheme.statusInactive.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 14, color: AppTheme.statusInactive),
                          label: const Text('Cancel',
                              style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ]),
                ),
              ] else
                const SizedBox(height: 14),
            ] else ...[
              // Cancelled banner
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.statusInactive.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.statusInactive.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.statusInactive),
                    const SizedBox(width: 7),
                    Text(b.cancellationLabel,
                        style: const TextStyle(fontFamily: 'Poppins',
                            fontSize: 11, color: AppTheme.statusInactive)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 12, color: widget.txtH),
    const SizedBox(width: 5),
    Expanded(child: Text(text,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
            color: widget.txtS),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}
