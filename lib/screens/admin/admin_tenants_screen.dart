import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

enum _TenantFilter { all, active, inactive, pending }

class AdminTenantsScreen extends StatefulWidget {
  const AdminTenantsScreen({super.key});

  @override
  State<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}

class _AdminTenantsScreenState extends State<AdminTenantsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  _TenantFilter _activeFilter = _TenantFilter.all;
  List<_TenantModel> _allTenants = [];
  List<_TenantModel> _filtered = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _searchCtrl.addListener(_applyFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTenants());
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      // Replace with your actual API call:
      // final res = await context.read<ApiService>().getTenants();
      await Future.delayed(const Duration(milliseconds: 800)); // simulate
      final mock = _mockTenants();
      if (!mounted) return;
      setState(() {
        _allTenants = mock;
        _isLoading = false;
      });
      _applyFilter();
      _animController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allTenants.where((t) {
        final matchSearch = q.isEmpty ||
            t.name.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q) ||
            t.domain.toLowerCase().contains(q);
        final matchFilter = _activeFilter == _TenantFilter.all ||
            (_activeFilter == _TenantFilter.active && t.status == 'active') ||
            (_activeFilter == _TenantFilter.inactive && t.status == 'inactive') ||
            (_activeFilter == _TenantFilter.pending && t.status == 'pending');
        return matchSearch && matchFilter;
      }).toList();
    });
  }

  void _setFilter(_TenantFilter f) {
    setState(() => _activeFilter = f);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonList()
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppTheme.adminPrimary,
                        onRefresh: _loadTenants,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildTenantCard(_filtered[i], i),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTenantSheet,
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Tenant',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.adminPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenants',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Manage all platform tenants',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderStat('Total', '${_allTenants.length}'),
              const SizedBox(width: 12),
              _buildHeaderStat(
                'Active',
                '${_allTenants.where((t) => t.status == 'active').length}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.adminPrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search tenants by name, email or domain…',
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('All', _TenantFilter.all, Icons.apps_rounded),
      ('Active', _TenantFilter.active, Icons.check_circle_rounded),
      ('Inactive', _TenantFilter.inactive, Icons.cancel_rounded),
      ('Pending', _TenantFilter.pending, Icons.hourglass_top_rounded),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _activeFilter == f.$2;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  f.$1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
                avatar: Icon(
                  f.$3,
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                selected: isSelected,
                onSelected: (_) => _setFilter(f.$2),
                selectedColor: AppTheme.adminPrimary,
                backgroundColor: AppTheme.surface,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppTheme.adminPrimary : Colors.grey.shade200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTenantCard(_TenantModel tenant, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTenantDetails(tenant),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTenantAvatar(tenant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              tenant.domain,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(tenant.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMeta(Icons.people_outline_rounded, '${tenant.userCount} users'),
                      const SizedBox(width: 16),
                      _buildMeta(Icons.receipt_outlined, '${tenant.bookings} bookings'),
                      const SizedBox(width: 16),
                      _buildMeta(Icons.calendar_today_outlined,
                          'Joined ${tenant.joinedDate}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('View Details',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.adminPrimary,
                            side: const BorderSide(color: AppTheme.adminPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => _showTenantOptions(context, tenant),
                        icon: const Icon(Icons.more_vert_rounded),
                        color: AppTheme.textSecondary,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantAvatar(_TenantModel tenant) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tenant.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          tenant.initials,
          style: TextStyle(
            color: tenant.color,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cfg.$1,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            cfg.$2,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cfg.$1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.adminPrimary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_outlined,
              color: AppTheme.adminPrimary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No tenants found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              _setFilter(_TenantFilter.all);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear filters',
                style: TextStyle(fontFamily: 'Poppins')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.adminPrimary,
              side: const BorderSide(color: AppTheme.adminPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmer(width: 46, height: 46, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmer(width: 140, height: 14),
                        const SizedBox(height: 6),
                        _shimmer(width: 90, height: 11),
                      ],
                    ),
                  ),
                  _shimmer(width: 65, height: 24, radius: 20),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                _shimmer(width: 80, height: 11),
                const SizedBox(width: 16),
                _shimmer(width: 90, height: 11),
                const SizedBox(width: 16),
                _shimmer(width: 70, height: 11),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer({double? width, double? height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _showTenantDetails(_TenantModel tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTenantAvatar(tenant),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tenant.name,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: AppTheme.textPrimary)),
                                Text(tenant.domain,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          _buildStatusChip(tenant.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...[
                        ('Contact Email', tenant.email, Icons.email_outlined),
                        ('Domain', tenant.domain, Icons.language_rounded),
                        ('Total Users', '${tenant.userCount}', Icons.people_outline_rounded),
                        ('Total Bookings', '${tenant.bookings}', Icons.receipt_long_rounded),
                        ('Joined Date', tenant.joinedDate, Icons.calendar_today_rounded),
                        ('Subscription', tenant.plan, Icons.workspace_premium_rounded),
                      ].map((row) => _detailRow(row.$3, row.$1, row.$2)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit Tenant',
                                  style: TextStyle(fontFamily: 'Poppins')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.adminPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Close',
                                style: TextStyle(fontFamily: 'Poppins')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.adminPrimary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.adminPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 11, color: AppTheme.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showTenantOptions(BuildContext context, _TenantModel tenant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(tenant.name,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
            ...[
              (Icons.edit_rounded, 'Edit Tenant', AppTheme.adminPrimary),
              (Icons.people_rounded, 'Manage Users', AppTheme.tenantPrimary),
              (tenant.status == 'active'
                  ? Icons.block_rounded
                  : Icons.check_circle_rounded,
              tenant.status == 'active' ? 'Deactivate' : 'Activate',
              tenant.status == 'active' ? Colors.orange : AppTheme.statusActive),
              (Icons.delete_rounded, 'Delete Tenant', AppTheme.statusInactive),
            ].map((opt) => ListTile(
                  leading: Icon(opt.$1, color: opt.$3, size: 20),
                  title: Text(opt.$2,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: opt.$3)),
                  onTap: () => Navigator.pop(context),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAddTenantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Add New Tenant',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppTheme.textPrimary)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _formField('Company Name', Icons.apartment_rounded),
              const SizedBox(height: 14),
              _formField('Contact Email', Icons.email_outlined),
              const SizedBox(height: 14),
              _formField('Domain', Icons.language_rounded),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Create Tenant',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(String hint, IconData icon) {
    return TextField(
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.adminPrimary, size: 20),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.adminPrimary, width: 1.5),
        ),
      ),
    );
  }

  (Color, String) _statusConfig(String status) {
    switch (status) {
      case 'active':
        return (AppTheme.statusActive, 'Active');
      case 'inactive':
        return (AppTheme.statusInactive, 'Inactive');
      case 'pending':
        return (Colors.orange, 'Pending');
      default:
        return (AppTheme.textSecondary, status);
    }
  }

  List<_TenantModel> _mockTenants() => [
        _TenantModel(
          id: '1',
          name: 'Acme Corporation',
          email: 'admin@acme.com',
          domain: 'acme.platform.io',
          status: 'active',
          userCount: 142,
          bookings: 834,
          joinedDate: 'Jan 2024',
          plan: 'Enterprise',
          color: AppTheme.tenantPrimary,
        ),
        _TenantModel(
          id: '2',
          name: 'TechVentures Ltd',
          email: 'ops@techventures.io',
          domain: 'techventures.platform.io',
          status: 'active',
          userCount: 87,
          bookings: 412,
          joinedDate: 'Mar 2024',
          plan: 'Pro',
          color: const Color(0xFF7C3AED),
        ),
        _TenantModel(
          id: '3',
          name: 'Global Health Co',
          email: 'admin@globalhealth.co',
          domain: 'globalhealth.platform.io',
          status: 'pending',
          userCount: 12,
          bookings: 0,
          joinedDate: 'Apr 2025',
          plan: 'Starter',
          color: Colors.teal,
        ),
        _TenantModel(
          id: '4',
          name: 'RetailPlus Inc',
          email: 'tech@retailplus.com',
          domain: 'retailplus.platform.io',
          status: 'inactive',
          userCount: 56,
          bookings: 220,
          joinedDate: 'Aug 2023',
          plan: 'Pro',
          color: Colors.orange,
        ),
        _TenantModel(
          id: '5',
          name: 'Nova Solutions',
          email: 'hello@novasolutions.io',
          domain: 'nova.platform.io',
          status: 'active',
          userCount: 33,
          bookings: 156,
          joinedDate: 'Nov 2024',
          plan: 'Starter',
          color: Colors.indigo,
        ),
      ];
}

class _TenantModel {
  final String id, name, email, domain, status, joinedDate, plan;
  final int userCount, bookings;
  final Color color;

  const _TenantModel({
    required this.id,
    required this.name,
    required this.email,
    required this.domain,
    required this.status,
    required this.userCount,
    required this.bookings,
    required this.joinedDate,
    required this.plan,
    required this.color,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}