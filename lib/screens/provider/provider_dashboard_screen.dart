import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _staggerCtrl;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard   : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    _staggerCtrl.reset();
    await Future.wait([
      context.read<BookingService>().fetchBookingsForProvider(),
      context.read<NotificationService>().fetchUnreadCount(),
    ]);
    if (mounted) _staggerCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthService>();
    final bkSvc  = context.watch<BookingService>();
    final notifications = context.watch<NotificationService>();
    final user   = auth.currentUser;
    final active = bkSvc.inProgressBookings.isNotEmpty
        ? bkSvc.inProgressBookings.first : null;

    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning,'
        : hour < 17 ? 'Good afternoon,' : 'Good evening,';

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: AppTheme.providerPrimary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 250,
              pinned: true, stretch: true, elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: _isDark
                  ? const Color(0xFF451A03) : AppTheme.providerDark,
              actions: [
                Stack(alignment: Alignment.center, children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 26),
                    onPressed: () =>
                        context.go(AppRoutes.providerNotifications),
                  ),
                  if (notifications.unreadCount > 0)
                    Positioned(right: 8, top: 8,
                        child: Container(width: 9, height: 9,
                          decoration: BoxDecoration(
                              color: AppTheme.statusCancelled,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1.5)),
                        )),
                ]),
                const SizedBox(width: 6),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                collapseMode: CollapseMode.parallax,
                titlePadding: EdgeInsets.zero,
                background: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: _isDark
                        ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                        : [AppTheme.providerDark, AppTheme.providerPrimary],
                  )),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 46, 72, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting, style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8))),
                          const SizedBox(height: 3),
                          Text('${user?.fullName ?? 'Provider'} 👋',
                              style: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 21, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (user?.skillCategory != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(user!.skillCategory!,
                                  style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9))),
                            ),
                          ],
                          const SizedBox(height: 14),
                          // ── 3-stat row — FIXED overflow ────────────
                          // Use IntrinsicHeight + Row instead of fixed height
                          Row(children: [
                            _headerStat(
                                '${bkSvc.pendingBookings.length}',
                                'Assigned',
                                Icons.assignment_outlined),
                            const SizedBox(width: 8),
                            _headerStat(
                                '${bkSvc.inProgressCount}',
                                'In Progress',
                                Icons.pending_actions_outlined),
                            const SizedBox(width: 8),
                            _headerStat(
                                '${bkSvc.completedCount}',
                                'Completed',
                                Icons.check_circle_outline_rounded),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // ── Stat cards ──────────────────────────────────────────
                _sectionLabel('Overview'),
                const SizedBox(height: 14),
                Row(children: [
                  _statCard(0,
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: _isDark
                          ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
                      label: 'Rating',
                      value: user?.rating.toStringAsFixed(1) ?? '0.0',
                      isString: true),
                  const SizedBox(width: 12),
                  _statCard(1,
                      icon: Icons.work_history_outlined,
                      iconColor: AppTheme.providerPrimary,
                      iconBg: _isDark
                          ? const Color(0xFF451A03) : AppTheme.providerLight,
                      label: 'Total Jobs',
                      value: '${bkSvc.bookings.length}'),
                  const SizedBox(width: 12),
                  _statCard(2,
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.statusCompleted,
                      iconBg: _isDark
                          ? const Color(0xFF052E16) : const Color(0xFFECFDF5),
                      label: 'Completed',
                      value: '${bkSvc.completedCount}'),
                ]),
                const SizedBox(height: 28),

                // ── Active job ──────────────────────────────────────────
                if (active != null) ...[
                  _sectionLabel('Current Job'),
                  const SizedBox(height: 14),
                  _activeJobCard(active),
                  const SizedBox(height: 28),
                ],

                // ── Recent assigned ─────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  _sectionLabel('Assigned Services'),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.providerServices),
                    icon: const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppTheme.providerPrimary),
                    label: const Text('View All', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13,
                        color: AppTheme.providerPrimary)),
                  ),
                ]),
                const SizedBox(height: 12),

                if (bkSvc.isLoading)
                  _skeleton()
                else if (bkSvc.pendingBookings.isEmpty)
                  _empty()
                else
                  ...bkSvc.pendingBookings.take(5).toList()
                      .asMap().entries
                      .map((e) => _jobCard(e.value, e.key)),

                const SizedBox(height: 16),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header stat box — FIXED: no fixed height, content determines size ─
  Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(child: Container(
      // No fixed height — let Column determine it
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Poppins',
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 1),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                color: Colors.white.withOpacity(0.85)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _sectionLabel(String t) => Row(children: [
    Container(width: 3, height: 18,
        decoration: BoxDecoration(color: AppTheme.providerPrimary,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
        fontWeight: FontWeight.w600, color: _txtP)),
  ]);

  Widget _statCard(int idx, {
    required IconData icon, required Color iconColor,
    required Color iconBg, required String label,
    required String value, bool isString = false,
  }) {
    final startDelay  = idx * 0.2;
    final endProgress = (startDelay + 0.5).clamp(0.0, 1.0);
    final fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(startDelay, endProgress, curve: Curves.easeOut)));
    final slide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerCtrl,
            curve: Interval(startDelay, endProgress,
                curve: Curves.easeOutCubic)));

    return Expanded(child: FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(_isDark ? 0.3 : 0.06),
                blurRadius: 12, offset: const Offset(0, 4),
              )]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: iconBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(height: 12),
            isString
                ? Text(value, style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 22, fontWeight: FontWeight.w700, color: _txtP))
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0,
                        end: double.tryParse(value) ?? 0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Text(v.toInt().toString(),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 22,
                            fontWeight: FontWeight.w700, color: _txtP))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                color: _txtS, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    ));
  }

  Widget _activeJobCard(BookingModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF451A03), const Color(0xFF78350F)]
              : [AppTheme.providerDark, AppTheme.providerPrimary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: AppTheme.providerPrimary.withOpacity(0.35),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Currently Working On', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 3),
          Text(job.serviceName, style: const TextStyle(fontFamily: 'Poppins',
              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(job.userName.isNotEmpty ? job.userName : 'Customer',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: Colors.white.withOpacity(0.85))),
        ])),
        GestureDetector(
          onTap: () => context.go(
              AppRoutes.providerTaskDetail.replaceAll(':taskId', job.id)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: const Text('View', style: TextStyle(fontFamily: 'Poppins',
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _jobCard(BookingModel b, int idx) {
    final anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval((idx * 0.08).clamp(0.0, 0.6),
            ((idx * 0.08) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOut)));

    Widget buildCard(Widget child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child),
    );

    return buildCard(GestureDetector(
      onTap: () => context.go(
          AppRoutes.providerTaskDetail.replaceAll(':taskId', b.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: AppTheme.getStatusColor(b.status), width: 4),
              top: BorderSide(color: _div),
              right: BorderSide(color: _div),
              bottom: BorderSide(color: _div),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(child: Text(
                  b.serviceName.isNotEmpty ? b.serviceName : 'Service',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w600, color: _txtP),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.getStatusBgColor(b.providerFacingStatusLabel)
                          .withOpacity(_isDark ? 0.5 : 1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(b.providerFacingStatusLabel, style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.getStatusColor(b.providerFacingStatusLabel))),
                ),
              ]),
            const SizedBox(height: 8),
            _infoRow(Icons.person_outline_rounded,
                b.userName.isNotEmpty ? b.userName : 'Customer'),
            const SizedBox(height: 4),
            _infoRow(Icons.location_on_outlined,
                b.userAddress.isNotEmpty ? b.userAddress : 'No address'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today_outlined,
                (b.scheduledDate?.isNotEmpty == true)
                    ? '${b.scheduledDate}  ·  ${b.scheduledTime ?? ''}'
                    : '${b.preferredDate}  ·  ${b.preferredTime}'),
            if (b.assignedAssetName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.inventory_2_outlined, b.assignedAssetName!),
            ],
            const SizedBox(height: 6),
            const Align(alignment: Alignment.centerRight,
              child: Text('Tap to update status →',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      color: AppTheme.providerPrimary,
                      fontWeight: FontWeight.w600))),
          ]),
        ),
      ),
    )));
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: _txtH),
    const SizedBox(width: 5),
    Expanded(child: Text(text, style: TextStyle(fontFamily: 'Poppins',
        fontSize: 12, color: _txtS),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);

  Widget _skeleton() => Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 12), height: 90,
        decoration: BoxDecoration(color: _cardBg,
            borderRadius: BorderRadius.circular(16)))));

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(children: [
      Container(width: 70, height: 70,
          decoration: BoxDecoration(
              color: _isDark ? AppTheme.darkCard : AppTheme.providerLight,
              shape: BoxShape.circle),
          child: Icon(Icons.home_repair_service_outlined, size: 34,
              color: AppTheme.providerPrimary.withOpacity(0.5))),
      const SizedBox(height: 16),
      Text('No assigned jobs yet', style: TextStyle(fontFamily: 'Poppins',
          fontSize: 15, fontWeight: FontWeight.w500, color: _txtP)),
      const SizedBox(height: 6),
      Text('Your admin will assign jobs to you soon',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
    ]),
  );
}
