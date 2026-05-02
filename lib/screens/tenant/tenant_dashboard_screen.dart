import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/asset_service.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/provider_service.dart';
import '../../services/service_catalog_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});
  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen>
    with TickerProviderStateMixin {

  late final AnimationController _staggerCtrl;
  late final AnimationController _chartCtrl;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>>  _cardSlides;

  bool  get _isDark      => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg      => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surfaceBg   => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _textPrimary => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _textSec     => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _textHint    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _divider     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  List<Color> get _headerGrad => _isDark
      ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
      : [AppTheme.tenantDark, AppTheme.tenantPrimary];
  Color _iconBg(Color light, Color dark) => _isDark ? dark : light;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _chartCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600));
    _cardFades = List.generate(4, (i) {
      final s = i * 0.12, e = (i * 0.12 + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(s, e, curve: Curves.easeOut)));
    });
    _cardSlides = List.generate(4, (i) {
      final s = i * 0.12, e = (i * 0.12 + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
          .animate(CurvedAnimation(parent: _staggerCtrl,
              curve: Interval(s, e, curve: Curves.easeOutCubic)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _chartCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthService>();
    final tenantId = auth.currentUser?.id;
    _staggerCtrl.reset();
    _chartCtrl.reset();
    await Future.wait([
      context.read<ServiceCatalogService>().fetchServicesForAdmin(tenantId: tenantId),
      context.read<AssetService>().fetchAssets(adminId: tenantId),
      context.read<ProviderService>().fetchProviders(adminId: tenantId),
      context.read<BookingService>().fetchBookingsForAdmin(),
      context.read<NotificationService>().fetchUnreadCount(),
    ]);
    if (mounted) {
      _staggerCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300),
          () { if (mounted) _chartCtrl.forward(); });
    }
  }

  List<_DayBar> _weeklyData(List<BookingModel> bookings) {
    final now = DateTime.now();
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return _DayBar(labels[date.weekday - 1], 0, date);
    });
    for (final b in bookings) {
      try {
        final d = DateTime.parse(b.preferredDate);
        final diff = now.difference(d).inDays;
        if (diff >= 0 && diff < 7) {
          for (final day in days) {
            if (day.date.year == d.year && day.date.month == d.month &&
                day.date.day == d.day) { day.count++; break; }
          }
        }
      } catch (_) {}
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthService>();
    final services  = context.watch<ServiceCatalogService>();
    final assets    = context.watch<AssetService>();
    final providers = context.watch<ProviderService>();
    final bookings  = context.watch<BookingService>();
    final notifications = context.watch<NotificationService>();
    final user      = auth.currentUser;
    final hasUnread = notifications.unreadCount > 0;
    final hour      = DateTime.now().hour;
    final greeting  = hour < 12 ? 'Good morning,'
        : hour < 17 ? 'Good afternoon,' : 'Good evening,';
    final weekly    = _weeklyData(bookings.bookings);

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: RefreshIndicator(
        color: AppTheme.tenantPrimary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true, stretch: true, elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: _isDark ? const Color(0xFF1A0533) : AppTheme.tenantDark,
              actions: [
                Stack(alignment: Alignment.center, children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 26),
                    onPressed: () => context.go(AppRoutes.tenantNotifications),
                  ),
                  if (hasUnread)
                    Positioned(right: 8, top: 8,
                        child: Container(width: 9, height: 9,
                          decoration: BoxDecoration(
                              color: AppTheme.statusCancelled,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5)),
                        )),
                ]),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                collapseMode: CollapseMode.parallax,
                titlePadding: EdgeInsets.zero,
                background: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: _headerGrad)),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 46, 20, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(greeting, style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 13, color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 3),
                        Text('${user?.fullName ?? 'Tenant'} 👋',
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontSize: 22, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (user?.businessName != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.store_outlined, color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(user!.businessName!,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                                      color: Colors.white.withOpacity(0.9))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            _chip('${bookings.pendingCount}', 'Open Orders',
                                AppTheme.statusPending),
                            const SizedBox(width: 8),
                            _chip('${assets.outOfStockCount}', 'Low Stock',
                                AppTheme.statusInProgress),
                            const SizedBox(width: 8),
                            _chip('${bookings.requestedBookings.length}',
                                'Unassigned', Colors.white.withOpacity(0.6)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(delegate: SliverChildListDelegate([

                _sectionLabel('Overview'),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25,
                  children: [
                    _statCard(idx: 0, icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: _iconBg(const Color(0xFFF3E8FF), const Color(0xFF2D1B69)),
                        label: 'Total Assets', value: assets.totalCount,
                        sub: '${assets.availableCount} available',
                        subColor: AppTheme.statusCompleted),
                    _statCard(idx: 1, icon: Icons.home_repair_service_rounded,
                        iconColor: const Color(0xFF059669),
                        iconBg: _iconBg(const Color(0xFFD1FAE5), const Color(0xFF064E3B)),
                        label: 'Active Services',
                        value: services.availableServices.length,
                        sub: '${services.services.length} total',
                        subColor: AppTheme.textSecondary),
                    _statCard(idx: 2, icon: Icons.engineering_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: _iconBg(const Color(0xFFFEF3C7), const Color(0xFF78350F)),
                        label: 'Providers', value: providers.totalCount,
                        sub: '${providers.activeCount} active',
                        subColor: AppTheme.statusCompleted),
                    _statCard(idx: 3, icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFFEC4899),
                        iconBg: _iconBg(const Color(0xFFFCE7F3), const Color(0xFF831843)),
                        label: 'Total Orders', value: bookings.totalOrders,
                        sub: '${bookings.completedCount} completed',
                        subColor: AppTheme.statusCompleted),
                  ],
                ),
                const SizedBox(height: 28),

                _sectionLabel('Order Status'),
                const SizedBox(height: 14),
                _donutCard(bookings),
                const SizedBox(height: 28),

                _sectionLabel('Weekly Bookings'),
                const SizedBox(height: 14),
                _weeklyCard(weekly),
                const SizedBox(height: 28),

                _sectionLabel('Quick Actions'),
                const SizedBox(height: 14),
                Row(children: [
                  _action(icon: Icons.add_box_outlined, label: 'Add\nAsset',
                      color: const Color(0xFF7C3AED),
                      bg: _iconBg(const Color(0xFFF3E8FF), const Color(0xFF2D1B69)),
                      onTap: () => context.go(AppRoutes.addAsset)),
                  const SizedBox(width: 10),
                  _action(icon: Icons.person_add_outlined, label: 'Add\nProvider',
                      color: AppTheme.providerPrimary,
                      bg: _iconBg(AppTheme.providerLight, const Color(0xFF064E3B)),
                      onTap: () => context.go(AppRoutes.addProvider)),
                  const SizedBox(width: 10),
                  _action(icon: Icons.add_circle_outline_rounded, label: 'Add\nService',
                      color: AppTheme.tenantPrimary,
                      bg: _iconBg(AppTheme.tenantLight, const Color(0xFF3D1A6E)),
                      onTap: () => context.go(AppRoutes.addService)),
                  const SizedBox(width: 10),
                  _action(icon: Icons.assignment_ind_outlined, label: 'Assign\nOrder',
                      color: AppTheme.userPrimary,
                      bg: _iconBg(AppTheme.userLight, const Color(0xFF052E16)),
                      onTap: () => context.go(AppRoutes.tenantOrders)),
                ]),
                const SizedBox(height: 28),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _sectionLabel('Recent Activity'),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.tenantOrders),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppTheme.tenantPrimary),
                    label: const Text('View All', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13,
                        color: AppTheme.tenantPrimary)),
                  ),
                ]),
                const SizedBox(height: 12),

                if (bookings.isLoading)
                  _skeleton()
                else if (bookings.bookings.isEmpty)
                  _emptyState(Icons.receipt_long_outlined, 'No orders yet')
                else
                  ...bookings.bookings.take(5).toList().asMap().entries
                      .map((e) => _activityCard(e.value, e.key)),

                const SizedBox(height: 28),
                _sectionLabel('Order Summary'),
                const SizedBox(height: 14),
                _summaryCard(bookings),
                const SizedBox(height: 16),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _chip(String count, String label, Color dotColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(count, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
          fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
          color: Colors.white.withOpacity(0.85))),
    ]),
  );

  Widget _sectionLabel(String t) => Row(children: [
    Container(width: 3, height: 18,
        decoration: BoxDecoration(color: AppTheme.tenantPrimary,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
        fontWeight: FontWeight.w600, color: _textPrimary)),
  ]);

  Widget _statCard({required int idx, required IconData icon,
      required Color iconColor, required Color iconBg,
      required String label, required int value,
      required String sub, required Color subColor}) {
    return FadeTransition(
      opacity: _cardFades[idx],
      child: SlideTransition(
        position: _cardSlides[idx],
        child: _PressCard(onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.35 : 0.07),
                    blurRadius: 14, offset: const Offset(0, 5))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: iconBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 22)),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 1400), curve: Curves.easeOut,
                builder: (_, v, __) => Text(v.toInt().toString(),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 28,
                        fontWeight: FontWeight.w700, color: _textPrimary)),
              ),
              Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                  color: _textSec, fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: subColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(child: Text(sub, style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 10, color: subColor), overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _donutCard(BookingService bk) {
    final segs = [
      _Seg('Completed', bk.completedCount, AppTheme.statusCompleted),
      _Seg('In Progress', bk.inProgressCount, AppTheme.statusInProgress),
      _Seg('Accepted', bk.bookings.where((b) => b.status == 'Accepted').length, AppTheme.statusAccepted),
      _Seg('Assigned', bk.assignedBookings.length, AppTheme.statusAssigned),
      _Seg('Requested', bk.requestedBookings.length, AppTheme.statusRequested),
      _Seg('Cancelled', bk.cancelledBookings.length, AppTheme.statusCancelled),
    ];
    final total = bk.totalOrders;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.35 : 0.07),
              blurRadius: 14, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Breakdown', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13, color: _textSec)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.tenantLight.withOpacity(_isDark ? 0.25 : 1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$total total', style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600,
                color: AppTheme.tenantPrimary)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          SizedBox(width: 120, height: 120,
            child: total == 0
                ? Center(child: Text('No data yet', style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: _textHint)))
                : AnimatedBuilder(
                    animation: _chartCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _DonutPainter(segs: segs,
                          progress: _chartCtrl.value, total: total, stroke: 18),
                      child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: total.toDouble()),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => Text(v.toInt().toString(),
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 22,
                                  fontWeight: FontWeight.w700, color: _textPrimary)),
                        ),
                        Text('Orders', style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 9, color: _textSec)),
                      ])),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(children: segs.map((s) {
            final pct = total > 0 ? ((s.value / total) * 100).round() : 0;
            return Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: s.color,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(s.label, style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 11, color: _textSec))),
                Text('${s.value}', style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
                const SizedBox(width: 4),
                SizedBox(width: 30, child: Text('$pct%', style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 10, color: _textHint))),
              ]),
            );
          }).toList())),
        ]),
      ]),
    );
  }

  Widget _weeklyCard(List<_DayBar> days) {
    final maxVal = days.fold(0, (m, d) => math.max(m, d.count));
    final today  = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.35 : 0.07),
              blurRadius: 14, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Last 7 days', style: TextStyle(fontFamily: 'Poppins',
              fontSize: 13, color: _textSec)),
          Text('${days.fold(0, (s, d) => s + d.count)} bookings',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppTheme.tenantPrimary)),
        ]),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _chartCtrl,
          builder: (_, __) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final isToday = day.date.day == today.day && day.date.month == today.month;
              final frac = maxVal == 0 ? 0.0 : day.count / maxVal;
              final barH = (60 * frac * _chartCtrl.value).clamp(4.0, 60.0);
              return Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.end, children: [
                if (day.count > 0)
                  Padding(padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${day.count}', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday ? AppTheme.tenantPrimary : _textSec)))
                else
                  const SizedBox(height: 18),
                Container(
                  height: barH,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: isToday
                          ? [AppTheme.tenantDark, AppTheme.tenantPrimary]
                          : [
                              _isDark ? const Color(0xFF2D1B69) : AppTheme.tenantLight,
                              _isDark ? const Color(0xFF4C3793) : const Color(0xFFD8B4FE),
                            ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(day.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? AppTheme.tenantPrimary : _textSec)),
              ]));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _action({required IconData icon, required String label,
      required Color color, required Color bg, required VoidCallback onTap}) {
    return Expanded(
      child: _PressCard(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.18))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(
                fontFamily: 'Poppins', fontSize: 10,
                fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _activityCard(BookingModel b, int idx) {
    final displayStatus = b.tenantFacingStatusLabel;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + idx * 90),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.orderDetail.replaceAll(':orderId', b.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.25 : 0.05),
                  blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppTheme.getStatusBgColor(displayStatus),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.receipt_outlined, size: 20,
                    color: AppTheme.getStatusColor(displayStatus))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(b.serviceName, style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 12, color: _textHint),
                const SizedBox(width: 4),
                Expanded(child: Text('${b.userName} · ${b.preferredDate}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        color: _textSec),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.getStatusBgColor(displayStatus),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(displayStatus, style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppTheme.getStatusColor(displayStatus))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _summaryCard(BookingService bk) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.35 : 0.07),
            blurRadius: 14, offset: const Offset(0, 5))]),
    child: Row(children: [
      _sumItem('${bk.requestedBookings.length}', 'Requested', AppTheme.statusRequested),
      _vDiv(),
      _sumItem('${bk.assignedBookings.length}',  'Assigned',  AppTheme.statusAssigned),
      _vDiv(),
      _sumItem('${bk.inProgressCount}',           'In Progress', AppTheme.statusInProgress),
      _vDiv(),
      _sumItem('${bk.completedCount}',            'Completed',      AppTheme.statusCompleted),
    ]),
  );

  Widget _sumItem(String n, String label, Color color) =>
      Expanded(child: Column(children: [
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: double.tryParse(n) ?? 0),
      duration: const Duration(milliseconds: 1200), curve: Curves.easeOut,
      builder: (_, v, __) => Text(v.toInt().toString(),
          style: TextStyle(fontFamily: 'Poppins', fontSize: 20,
              fontWeight: FontWeight.w700, color: color)),
    ),
    const SizedBox(height: 4),
    Text(label, textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _textSec)),
  ]));

  Widget _vDiv() => Container(width: 1, height: 36, color: _divider);

  Widget _skeleton() => Column(children: List.generate(3, (_) => Container(
      margin: const EdgeInsets.only(bottom: 10), height: 72,
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(14)))));

  Widget _emptyState(IconData icon, String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(color: _surfaceBg, shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: _textHint)),
      const SizedBox(height: 14),
      Text(msg, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _textSec)),
    ]),
  );
}

class _Seg { final String label; final int value; final Color color;
  const _Seg(this.label, this.value, this.color); }
class _DayBar { final String label; int count; final DateTime date;
  _DayBar(this.label, this.count, this.date); }

class _DonutPainter extends CustomPainter {
  final List<_Seg> segs; final double progress; final int total; final double stroke;
  const _DonutPainter({required this.segs, required this.progress,
      required this.total, required this.stroke});
  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2 - 2;
    canvas.drawCircle(center, radius,
        Paint()..color = Colors.grey.withOpacity(0.1)
          ..style = PaintingStyle.stroke..strokeWidth = stroke);
    double startAngle = -math.pi / 2;
    const gap = 0.05;
    for (final s in segs) {
      if (s.value <= 0) continue;
      final frac  = s.value / total;
      final sweep = math.max(0.0, (frac * 2 * math.pi - gap) * progress);
      if (sweep > 0) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
            startAngle, sweep, false,
            Paint()..color = s.color..style = PaintingStyle.stroke
              ..strokeWidth = stroke..strokeCap = StrokeCap.round);
      }
      startAngle += frac * 2 * math.pi;
    }
  }
  @override bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.total != total;
}

class _PressCard extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _PressCard({required this.child, required this.onTap});
  @override State<_PressCard> createState() => _PressCardState();
}
class _PressCardState extends State<_PressCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.94, upperBound: 1.0)..value = 1.0;
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.reverse(),
    onTapUp:   (_) { _ctrl.forward(); widget.onTap(); },
    onTapCancel: () => _ctrl.forward(),
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(scale: _ctrl.value, child: child),
      child: widget.child,
    ),
  );
}
