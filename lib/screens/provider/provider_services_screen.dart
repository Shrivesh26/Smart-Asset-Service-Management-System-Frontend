import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});
  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  static const _tabLabels = ['All', 'Pending', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BookingService>().fetchBookingsForProvider());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BookingModel> _filtered(BookingService svc, int i) {
    List<BookingModel> base;
    switch (i) {
      case 1:
        base = svc.pendingBookings;
        break;
      case 2:
        base = svc.inProgressBookings;
        break;
      case 3:
        base = svc.completedBookings;
        break;
      default:
        base = svc.bookings;
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base
        .where((b) =>
            b.serviceName.toLowerCase().contains(q) ||
            b.userName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();
    final counts = [
      svc.bookings.length,
      svc.pendingBookings.length,
      svc.inProgressBookings.length,
      svc.completedBookings.length,
    ];

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _isDark
                      ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                      : [AppTheme.providerDark, AppTheme.providerPrimary])),
          child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 16, 12),
                    child: Row(children: [
                      // IconButton(
                      //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      //       color: Colors.white, size: 20),
                      //   onPressed: () =>
                      //       context.go(AppRoutes.providerDashboard),
                      // ),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('My Services',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('${svc.bookings.length} total assignments',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75))),
                          ])),
                    ])),

                // Search
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: _isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8)),
                        decoration: InputDecoration(
                          hintText: 'Search by service or customer...',
                          hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: _isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: _isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8), size: 18),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: _isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                                      size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  })
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    )),

                // Tabs
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: _tabLabels.asMap().entries.map((e) {
                    final cnt = counts[e.key];
                    final sel = _tabs.index == e.key;
                    return Tab(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(e.value),
                      if (cnt > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$cnt',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ]));
                  }).toList(),
                  onTap: (_) => setState(() {}),
                ),
              ])),
        ),

        // ── Tab views ────────────────────────────────────────────────
        Expanded(
          child: svc.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.providerPrimary))
              : TabBarView(
                  controller: _tabs,
                  children: List.generate(_tabLabels.length, (i) {
                    final list = _filtered(svc, i);
                    if (list.isEmpty) return _emptyTab(i);
                    return RefreshIndicator(
                      color: AppTheme.providerPrimary,
                      onRefresh: () => context
                          .read<BookingService>()
                          .fetchBookingsForProvider(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: list.length,
                        itemBuilder: (_, j) => _JobCard(
                          key: ValueKey(list[j].id),
                          booking: list[j],
                          index: j,
                          isDark: _isDark,
                          cardBg: _cardBg,
                          txtP: _txtP,
                          txtS: _txtS,
                          txtH: _txtH,
                          div: _div,
                          onTap: () => context.go(AppRoutes.providerTaskDetail
                              .replaceAll(':taskId', list[j].id)),
                        ),
                      ),
                    );
                  }),
                ),
        ),
      ]),
    );
  }

  Widget _emptyTab(int i) {
    final msgs = [
      'No services',
      'No pending jobs',
      'Nothing in progress',
      'No completed jobs'
    ];
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
              color: _isDark ? AppTheme.darkCard : AppTheme.providerLight,
              shape: BoxShape.circle),
          child: Icon(Icons.assignment_outlined,
              size: 32, color: AppTheme.providerPrimary.withOpacity(0.6))),
      const SizedBox(height: 14),
      Text(_query.isNotEmpty ? 'No results for "$_query"' : msgs[i],
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _txtP)),
      const SizedBox(height: 6),
      Text(_query.isNotEmpty ? 'Try a different search' : 'All caught up!',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════════════
//  JOB CARD — explicit cardBg color, never transparent
// ══════════════════════════════════════════════════════════════════════
class _JobCard extends StatefulWidget {
  final BookingModel booking;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onTap;

  const _JobCard(
      {super.key,
      required this.booking,
      required this.index,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onTap});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final displayStatus = b.providerFacingStatusLabel;
    final statusColor = AppTheme.getStatusColor(displayStatus);
    final statusBg = AppTheme.getStatusBgColor(displayStatus);
    final isActive = b.isInProgress;

    // Show meaningful text even if model fields are empty (fallback labels)
    final displayName = b.serviceName.isNotEmpty ? b.serviceName : 'Service';
    final displayCustomer = b.userName.isNotEmpty ? b.userName : 'Customer';
    final displayAddr = b.userAddress.isNotEmpty ? b.userAddress : 'No address';
    final displayDate = (b.scheduledDate?.isNotEmpty == true)
        ? '${b.scheduledDate}  ·  ${b.scheduledTime ?? ''}'
        : (b.preferredDate.isNotEmpty
            ? '${b.preferredDate}  ·  ${b.preferredTime}'
            : 'Date not set');

    return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
            opacity: _ctrl.value,
            child: Transform.translate(
                offset: Offset(0, 20 * (1 - _ctrl.value)), child: child)),
        child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(widget.isDark ? 0.28 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(children: [
                // ✅ MAIN CARD
                Container(
                  decoration: BoxDecoration(
                    color: widget.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.div, width: 0.8),
                  ),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top row ───────────────────────────────────────────────
                            Row(children: [
                              Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                      color: statusBg
                                          .withOpacity(widget.isDark ? 0.5 : 1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(
                                      Icons.home_repair_service_outlined,
                                      size: 20,
                                      color: statusColor)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(displayName,
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: widget.txtP),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(
                                        '#${b.id.length > 6 ? b.id.substring(0, 6).toUpperCase() : b.id}',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            color: widget.txtH)),
                                  ])),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: statusBg
                                        .withOpacity(widget.isDark ? 0.5 : 1),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isActive) ...[
                                        Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                                color:
                                                    AppTheme.statusInProgress,
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(displayStatus,
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor)),
                                    ]),
                              ),
                            ]),

                            const SizedBox(height: 10),

                            // ── Info rows ──────────────────────────────────────────────
                            _row(Icons.person_outline_rounded, displayCustomer),
                            const SizedBox(height: 4),
                            _row(Icons.location_on_outlined, displayAddr),
                            const SizedBox(height: 4),
                            _row(Icons.calendar_today_outlined, displayDate),
                            if (b.assignedAssetName?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              _row(Icons.inventory_2_outlined,
                                  b.assignedAssetName!),
                            ],

                            const SizedBox(height: 8),

                            // ── Tap hint ──────────────────────────────────────────────
                            const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Tap to update status →',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          color: AppTheme.providerPrimary,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          ])),
                ),

                Positioned(
                  left: 0,
                  top: 9,
                  bottom: 9,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            )));
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: widget.txtH),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, color: widget.txtS),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);
}
