import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<BookingService>().fetchBookingsForUser(),
      context.read<ServiceCatalogService>().fetchMarketplaceServices(),
      context.read<NotificationService>().fetchUnreadCount(),
    ]);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Theme helpers ──────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

  // ── Responsive helpers ─────────────────────────────────────────────────
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;
  bool get _isTablet => _screenWidth >= 600;
  bool get _isLargeTablet => _screenWidth >= 840;
  double get _horizontalPadding => _isTablet ? 28.0 : 18.0;
  double get _cardRadius => _isTablet ? 24.0 : 20.0;
  int get _categoryGridCount => _isLargeTablet ? 4 : (_isTablet ? 3 : 3);
  double get _categoryAspectRatio => _isTablet ? 1.0 : 0.9;
  double get _featuredCardWidth => _isTablet ? 240.0 : 200.0;
  double get _featuredCardHeight => _isTablet ? 160.0 : 140.0;
  double get _headerExpandedHeight => _isTablet ? 190.0 : 160.0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final bookingSvc = context.watch<BookingService>();
    final serviceSvc = context.watch<ServiceCatalogService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: AppTheme.userPrimary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // ── Collapsible header ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: _headerExpandedHeight,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.userDark,
              automaticallyImplyLeading: false,
              actions: [
                _notificationBell(),
                _avatarAction(user),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _headerBackground(user),
              ),
            ),

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                    vertical: 20,
                  ),
                  child: _isLargeTablet
                      ? _buildWideLayout(bookingSvc, serviceSvc)
                      : _buildNarrowLayout(bookingSvc, serviceSvc),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Narrow layout (phone + small tablet) ──────────────────────────────
  Widget _buildNarrowLayout(
      BookingService bookingSvc, ServiceCatalogService serviceSvc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickStats(bookingSvc),
        const SizedBox(height: 26),
        _sectionHeader('Featured Services', () {
          context.go(AppRoutes.userMarketplace);
        }),
        const SizedBox(height: 12),
        _buildFeaturedCarousel(serviceSvc.services),
        const SizedBox(height: 26),
        _sectionHeader('Browse Categories', () {
          context.go(AppRoutes.userMarketplace);
        }),
        const SizedBox(height: 12),
        _buildCategoryGrid(serviceSvc.categories),
        const SizedBox(height: 26),
        _sectionHeader('Recent Bookings', () {
          context.go(AppRoutes.userOrderHistory);
        }),
        const SizedBox(height: 12),
        _buildBookingsList(bookingSvc),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Wide layout (large tablet / desktop) ──────────────────────────────
  Widget _buildWideLayout(
  BookingService bookingSvc,
  ServiceCatalogService serviceSvc, 
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildQuickStats(bookingSvc),
      const SizedBox(height: 26),

      _sectionHeader('Featured Services', () {
        context.go(AppRoutes.userMarketplace);
      }),
      const SizedBox(height: 12),
      _buildFeaturedCarousel(serviceSvc.services),

      const SizedBox(height: 26),

      _sectionHeader('Browse Categories', () {
        context.go(AppRoutes.userMarketplace);
      }),
      const SizedBox(height: 12),
      _buildCategoryGrid(serviceSvc.categories),

      const SizedBox(height: 26),

      // ✅ NOW bookings are back BELOW
      _sectionHeader('Recent Bookings', () {
        context.go(AppRoutes.userOrderHistory);
      }),
      const SizedBox(height: 12),
      _buildBookingsList(bookingSvc),

      const SizedBox(height: 80),
    ],
  );
}

  // ── Header background ──────────────────────────────────────────────────
  Widget _headerBackground(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _isTablet ? 40 : 30,
                10,
                100,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Good ${_greeting()}',
                    style: TextStyle(
                      fontSize: _isTablet ? 16 : 14,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user?.fullName?.split(' ').first ?? 'User'} 👋',
                    style: TextStyle(
                      fontSize: _isTablet ? 30 : 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar actions ────────────────────────────────────────────────────
  Widget _notificationBell() {
    final hasNew = context.watch<NotificationService>().unreadCount > 0;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 24),
          onPressed: () => context.go(AppRoutes.userNotifications),
        ),
        if (hasNew)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.userDark, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarAction(dynamic user) {
    final url = user?.profilePhoto as String?;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.userSettings),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage:
                (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
            child: (url == null || url.isEmpty)
                ? Text(
                    user?.initials ?? 'U',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Quick stats ────────────────────────────────────────────────────────
  // FIX: Removed incorrect `Positioned` wrapper — it is only valid inside a
  //      Stack. Using it inside a Container caused a RenderObject exception
  //      that prevented the entire dashboard from rendering.
  Widget _buildQuickStats(BookingService svc) {
    final active =
        svc.bookings.where((b) => !b.isCancelled && !b.isCompleted).length;
    final completed = svc.completedBookings.length;
    final total = svc.bookings.length;

    return Container(
      padding: EdgeInsets.all(_isTablet ? 22 : 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      // ✅ FIXED: was `Positioned(child: Row(...))` — Positioned must live
      //           inside a Stack; using it here crashed the widget tree.
      child: Row(
        children: [
          _statItem('Total', '$total', Icons.receipt_long_outlined,
              AppTheme.userPrimary),
          _statDivider(),
          _statItem('Active', '$active', Icons.sync_rounded,
              const Color(0xFFF59E0B)),
          _statDivider(),
          _statItem('Done', '$completed', Icons.check_circle_outline,
              AppTheme.statusCompleted),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    final iconSize = _isTablet ? 44.0 : 40.0;
    final iconBoxRadius = _isTablet ? 14.0 : 12.0;

    return Expanded(
      child: Column(children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(iconBoxRadius),
          ),
          child: Icon(icon, color: color, size: _isTablet ? 22 : 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: _isTablet ? 24 : 20,
            fontWeight: FontWeight.w800,
            color: _txtP,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: _isTablet ? 12 : 11,
            color: _txtS,
          ),
        ),
      ]),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 50,
        color: _isDark ? AppTheme.darkDivider : AppTheme.dividerColor,
      );

  // ── Section header ─────────────────────────────────────────────────────
  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: _isTablet ? 19 : 17,
            fontWeight: FontWeight.w700,
            color: _txtP,
            letterSpacing: -0.2,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(children: [
            Text(
              'See all',
              style: TextStyle(
                fontSize: _isTablet ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.userPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppTheme.userPrimary),
          ]),
        ),
      ],
    );
  }

  // ── Featured carousel ──────────────────────────────────────────────────
  Widget _buildFeaturedCarousel(List<ServiceModel> services) {
    if (services.isEmpty) {
      return Container(
        height: _featuredCardHeight,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No services available',
              style: TextStyle(color: _txtS, fontSize: 13)),
        ),
      );
    }

    final featured = services.take(5).toList();
    final gradients = [
      [const Color(0xFF0A3D2E), AppTheme.userPrimary],
      [const Color(0xFF1E3A5F), const Color(0xFF2563EB)],
      [const Color(0xFF4A0E2E), const Color(0xFFDB2777)],
      [const Color(0xFF3D1A00), const Color(0xFFD97706)],
      [const Color(0xFF1A0050), const Color(0xFF7C3AED)],
    ];

    return SizedBox(
      height: _featuredCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final s = featured[i];
          final g = gradients[i % gradients.length];
          return GestureDetector(
            onTap: () => context.go(
                '${AppRoutes.bookService}?serviceId=${s.id}&storeId=${s.tenantId}'),
            child: Container(
              width: _featuredCardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [g[0], g[1]],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: g[1].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                  const Spacer(),
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: _isTablet ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      s.durationDisplay,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      s.priceDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Category grid ──────────────────────────────────────────────────────
  Widget _buildCategoryGrid(List<String> categories) {
    final catData = <String, _CatMeta>{
      'beauty': _CatMeta(Icons.face_retouching_natural_rounded,
          const Color(0xFFDB2777), 'Beauty'),
      'wellness':
          _CatMeta(Icons.spa_outlined, const Color(0xFF0F766E), 'Wellness'),
      'healthcare': _CatMeta(
          Icons.local_hospital_outlined, const Color(0xFF2563EB), 'Healthcare'),
      'fitness': _CatMeta(
          Icons.fitness_center_rounded, const Color(0xFFD97706), 'Fitness'),
      'consulting': _CatMeta(
          Icons.support_agent_rounded, const Color(0xFF7C3AED), 'Consulting'),
      'automotive': _CatMeta(Icons.directions_car_filled_outlined,
          const Color(0xFFB45309), 'Auto'),
      'home_services': _CatMeta(Icons.home_repair_service_outlined,
          AppTheme.userPrimary, 'Home'),
      'cleaning': _CatMeta(Icons.cleaning_services_outlined,
          const Color(0xFF0891B2), 'Cleaning'),
    };

    final displayed = categories.isEmpty
        ? catData.keys.take(6).toList()
        : categories.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _categoryGridCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: _categoryAspectRatio,
      ),
      itemCount: displayed.length,
      itemBuilder: (_, i) {
        final cat = displayed[i];
        final meta = catData[cat] ??
            _CatMeta(Icons.miscellaneous_services_rounded, AppTheme.userPrimary,
                cat);
        return GestureDetector(
          onTap: () =>
              context.go('${AppRoutes.userMarketplace}?category=$cat'),
          child: Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: _isTablet ? 56 : 50,
                  height: _isTablet ? 56 : 50,
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(meta.icon, color: meta.color,
                      size: _isTablet ? 28 : 26),
                ),
                const SizedBox(height: 8),
                Text(
                  meta.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isTablet ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: _txtP,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bookings list (extracted for reuse in wide layout) ─────────────────
  Widget _buildBookingsList(BookingService bookingSvc) {
    if (bookingSvc.isLoading) return _shimmerBookings();
    if (bookingSvc.bookings.isEmpty) return _emptyBookings();
    return Column(
      children: bookingSvc.bookings
          .take(3)
          .map((b) => _buildBookingCard(b))
          .toList(),
    );
  }

  // ── Booking card ───────────────────────────────────────────────────────
  Widget _buildBookingCard(BookingModel b) {
    final displayStatus = b.userFacingStatusLabel;

    return GestureDetector(
      onTap: () => context
          .go(AppRoutes.userOrderStatus.replaceAll(':orderId', b.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(_isTablet ? 18 : 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: _isTablet ? 54 : 48,
            height: _isTablet ? 54 : 48,
            decoration: BoxDecoration(
              color: AppTheme.getStatusBgColor(displayStatus),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.home_repair_service_outlined,
              color: AppTheme.getStatusColor(displayStatus),
              size: _isTablet ? 26 : 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.serviceName,
                  style: TextStyle(
                    fontSize: _isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
                const SizedBox(height: 3),
                Text(b.storeName,
                    style: TextStyle(fontSize: 12, color: _txtS)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 11, color: _txtS),
                  const SizedBox(width: 4),
                  Text(b.preferredDate,
                      style: TextStyle(fontSize: 11, color: _txtS)),
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _statusBadge(displayStatus),
            const SizedBox(height: 6),
            if (b.isInProgress)
              Text(
                'Track →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.userPrimary,
                ),
              ),
          ]),
        ]),
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
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.getStatusColor(status),
        ),
      ),
    );
  }

  // ── Shimmer loader ─────────────────────────────────────────────────────
  Widget _shimmerBookings() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 78,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  // ── Empty bookings ─────────────────────────────────────────────────────
  Widget _emptyBookings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.userPrimary.withOpacity(0.12),
        ),
      ),
      child: Column(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.userPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.receipt_long_outlined,
              size: 30, color: AppTheme.userPrimary),
        ),
        const SizedBox(height: 14),
        Text(
          'No bookings yet',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _txtP,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse services and place your first booking',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _txtS, height: 1.4),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.userMarketplace),
          icon: const Icon(Icons.explore_outlined, size: 18),
          label: const Text('Browse Services'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.userPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _CatMeta {
  const _CatMeta(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}