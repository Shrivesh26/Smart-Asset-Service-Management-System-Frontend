// ═══════════════════════════════════════════════════════════════
//  user_order_history_screen.dart
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key});

  @override
  State<UserOrderHistoryScreen> createState() =>
      _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BookingService>().fetchBookingsForUser());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: svc.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.userPrimary))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildList(svc.bookings),
                    _buildList(svc.bookings
                        .where((b) => !b.isCancelled && !b.isCompleted)
                        .toList()),
                    _buildList(svc.completedBookings),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 15, 16, 4),
            child: Row(children: [
              Expanded(
                child: Text('My Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
              ),
            ]),
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            padding: const EdgeInsets.only(bottom: 4),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildList(List<BookingModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.userPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 36, color: AppTheme.userPrimary),
          ),
          const SizedBox(height: 16),
          Text('No orders here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _txtP,
              )),
          const SizedBox(height: 6),
          Text('Your orders will appear here',
              style: TextStyle(fontSize: 13, color: _txtS)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppTheme.userPrimary,
      onRefresh: () => context.read<BookingService>().fetchBookingsForUser(),
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildBookingCard(items[i]),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel b) {
    final displayStatus = b.userFacingStatusLabel;

    return GestureDetector(
      onTap: () => context
          .go(AppRoutes.userOrderStatus.replaceAll(':orderId', b.id)),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.getStatusBgColor(displayStatus),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.home_repair_service_outlined,
                color: AppTheme.getStatusColor(displayStatus),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.serviceName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txtP,
                      )),
                  const SizedBox(height: 4),
                  Text(b.storeName,
                      style: TextStyle(fontSize: 12, color: _txtS)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: _txtS),
                    const SizedBox(width: 4),
                    Text(b.preferredDate,
                        style: TextStyle(fontSize: 11, color: _txtS)),
                    if (b.shouldShowProviderToUser) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.person_outline_rounded,
                          size: 11, color: _txtS),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(b.assignedProviderName ?? '',
                            style: TextStyle(fontSize: 11, color: _txtS),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _statusBadge(displayStatus),
              const SizedBox(height: 6),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: _txtS),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getStatusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.getStatusColor(status),
          )),
    );
  }
}
