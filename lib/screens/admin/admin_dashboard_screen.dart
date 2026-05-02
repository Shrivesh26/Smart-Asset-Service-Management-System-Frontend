import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await context.read<ApiService>().getAdminDashboardStats();
      await context.read<NotificationService>().fetchUnreadCount();
      if (!mounted) return;
      setState(() {
        _stats = response['data'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stats = {};
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        color: AppTheme.adminPrimary,
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(user),
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildSkeletonLoader()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildStatsGrid(),
                              const SizedBox(height: 28),
                              _buildQuickActionsSection(),
                              const SizedBox(height: 28),
                              _buildRecentActivitySection(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic user) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.adminPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.gradientForRole('admin'),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildAvatar(user),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationBell(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAdminBadge(),
                ],
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadStats,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAvatar(dynamic user) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    final hasUnread = context.watch<NotificationService>().unreadCount > 0;
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 20),
        ),
        if (hasUnread)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.adminPrimary, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified_rounded, color: Colors.white, size: 12),
          SizedBox(width: 5),
          Text(
            'Platform Administrator',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        label: 'Total Tenants',
        value: '${_stats?['tenants'] ?? 0}',
        icon: Icons.apartment_rounded,
        color: AppTheme.tenantPrimary,
        trend: '+2 this month',
        trendUp: true,
      ),
      _StatData(
        label: 'Active Providers',
        value: '${_stats?['providers'] ?? 0}',
        icon: Icons.verified_user_rounded,
        color: AppTheme.statusActive,
        trend: '+5 this week',
        trendUp: true,
      ),
      _StatData(
        label: 'Total Bookings',
        value: '${_stats?['bookings'] ?? 0}',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.adminPrimary,
        trend: '12 pending',
        trendUp: false,
      ),
      _StatData(
        label: 'Platform Revenue',
        value: '\$${_stats?['revenue'] ?? '0'}',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF7C3AED),
        trend: '+18% MoM',
        trendUp: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Overview', Icons.bar_chart_rounded),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) => _buildStatCard(stats[i]),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stat.trendUp
                      ? AppTheme.statusActive.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stat.trend,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: stat.trendUp ? AppTheme.statusActive : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: stat.color,
                ),
              ),
              Text(
                stat.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      _ActionData(
        label: 'Add Tenant',
        icon: Icons.add_business_rounded,
        color: AppTheme.tenantPrimary,
      ),
      _ActionData(
        label: 'View Reports',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _ActionData(
        label: 'Manage Providers',
        icon: Icons.manage_accounts_rounded,
        color: AppTheme.statusActive,
      ),
      _ActionData(
        label: 'Audit Logs',
        icon: Icons.history_rounded,
        color: AppTheme.adminPrimary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Quick Actions', Icons.flash_on_rounded),
        const SizedBox(height: 14),
        Row(
          children: actions
              .map((a) => Expanded(child: _buildActionChip(a)))
              .toList()
              .expand((w) => [w, const SizedBox(width: 8)])
              .toList()
            ..removeLast(),
        ),
      ],
    );
  }

  Widget _buildActionChip(_ActionData action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = [
      _ActivityData(
        title: 'New tenant registered',
        subtitle: 'Acme Corp joined the platform',
        time: '2 min ago',
        icon: Icons.apartment_rounded,
        color: AppTheme.tenantPrimary,
      ),
      _ActivityData(
        title: 'Provider approved',
        subtitle: 'Dr. Sarah Kofi is now active',
        time: '18 min ago',
        icon: Icons.verified_user_rounded,
        color: AppTheme.statusActive,
      ),
      _ActivityData(
        title: 'Booking completed',
        subtitle: 'Booking #2481 marked complete',
        time: '1 hr ago',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.adminPrimary,
      ),
      _ActivityData(
        title: 'System alert',
        subtitle: 'Storage usage reached 80%',
        time: '3 hr ago',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange.shade600,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recent Activity', Icons.timeline_rounded),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 62,
            ),
            itemBuilder: (_, i) => _buildActivityTile(activities[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(_ActivityData activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(activity.icon, color: activity.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => _shimmerBox(height: null, radius: 16),
          ),
          const SizedBox(height: 28),
          ...List.generate(
              3,
              (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _shimmerBox(height: 60, radius: 12),
                  )),
        ],
      ),
    );
  }

  Widget _shimmerBox({double? height, double radius = 8}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.adminPrimary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatData {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  final bool trendUp;
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendUp,
  });
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  const _ActionData({required this.label, required this.icon, required this.color});
}

class _ActivityData {
  final String title, subtitle, time;
  final IconData icon;
  final Color color;
  const _ActivityData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}
