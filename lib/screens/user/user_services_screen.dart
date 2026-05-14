import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import 'marketplace_service_card.dart';

class UserServicesScreen extends StatefulWidget {
  final String storeId;
  const UserServicesScreen({super.key, required this.storeId});

  @override
  State<UserServicesScreen> createState() => _UserServicesScreenState();
}

class _UserServicesScreenState extends State<UserServicesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  bool get _isMarketplace => widget.storeId.trim().isEmpty;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final category = uri.queryParameters['category'];
    final query = uri.queryParameters['query'];
    if (category != null && category != _selectedCategory) {
      setState(() => _selectedCategory = category);
    }
    if (query != null && query != _query) {
      setState(() {
        _query = query;
        _searchCtrl.text = query;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    if (_isMarketplace) {
      await context.read<ServiceCatalogService>().fetchMarketplaceServices();
    } else {
      await context
          .read<ServiceCatalogService>()
          .fetchServicesForStore(widget.storeId);
    }
  }

  List<ServiceModel> _filterServices(List<ServiceModel> source) {
    var list = source.where((s) => s.isActive).toList();
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((s) => s.category == _selectedCategory).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q) ||
              s.businessName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ServiceCatalogService>();
    final source =
        _isMarketplace ? catalog.services : catalog.storeServices;
    final services = _filterServices(source);
    final categories =
        source.map((s) => s.category).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: AppTheme.userPrimary,
        onRefresh: _loadServices,
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(source, categories)),

            // ── Category chips ──────────────────────────────────────
            if (categories.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildCategoryChips(categories),
              ),

            // ── Body ────────────────────────────────────────────────
            if (catalog.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.userPrimary),
                ),
              )
            else if (services.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final svc = services[i];
                      return MarketplaceServiceCard(
                        service: svc,
                        icon: _iconFor(svc.category),
                        accent: _accentFor(svc.category),
                        onTap: () => context.go(
                          '${AppRoutes.bookService}'
                          '?serviceId=${svc.id}&storeId=${svc.tenantId}',
                        ),
                      );
                    },
                    childCount: services.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Gradient header ────────────────────────────────────────────────────
  Widget _buildHeader(List<ServiceModel> source, List<String> categories) {
    final heading =
        _isMarketplace ? 'Service Marketplace' : 'Store Services';
    final subtitle = _isMarketplace
        ? 'Discover services from every partner on the platform.'
        : 'Browse everything available from this business.';

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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(children: [
                if (!_isMarketplace)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (!_isMarketplace) const SizedBox(width: 8),
                Expanded(
                  child: Text(heading,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      )),
                ),
                if (_isMarketplace)
                  TextButton(
                    onPressed: () => context.go(AppRoutes.userStores),
                    child: const Text('Stores',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.78),
                    height: 1.4,
                  )),
              const SizedBox(height: 18),

              // Stats row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(children: [
                  _statTile('${source.length}', 'Services'),
                  const SizedBox(width: 12),
                  _statTile('${categories.length}', 'Categories'),
                  const SizedBox(width: 12),
                  _statTile(
                    _isMarketplace
                        ? '${source.map((s) => s.tenantId).toSet().length}'
                        : '1',
                    _isMarketplace ? 'Partners' : 'Store',
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: _txtP, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search service, category, or business...',
                    hintStyle:
                        TextStyle(color: _txtS, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.userPrimary, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: _txtS, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            }),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.72),
              )),
        ]),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────
  Widget _buildCategoryChips(List<String> categories) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip(label: 'All', selected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null)),
            ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _chip(
                    label: cat.replaceAll('_', ' '),
                    selected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory =
                        _selectedCategory == cat ? null : cat),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _chip(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.userPrimary
              : _card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.userPrimary
                : _isDark
                    ? AppTheme.darkDivider
                    : AppTheme.dividerColor,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _txtS,
            )),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.userPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.travel_explore_rounded,
                size: 40, color: AppTheme.userPrimary),
          ),
          const SizedBox(height: 18),
          Text('No services found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _txtP,
              )),
          const SizedBox(height: 8),
          Text(
            'Try another keyword or remove the category filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: _txtS, height: 1.5),
          ),
          if (_query.isNotEmpty || _selectedCategory != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _query = '';
                _selectedCategory = null;
                _searchCtrl.clear();
              }),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.userPrimary,
                side: const BorderSide(color: AppTheme.userPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  IconData _iconFor(String category) {
    switch (category) {
      case 'beauty':
        return Icons.face_retouching_natural_rounded;
      case 'wellness':
        return Icons.spa_outlined;
      case 'healthcare':
        return Icons.local_hospital_outlined;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'consulting':
        return Icons.support_agent_rounded;
      case 'automotive':
        return Icons.directions_car_filled_outlined;
      case 'home_services':
        return Icons.home_repair_service_outlined;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  Color _accentFor(String category) {
    switch (category) {
      case 'beauty':
        return const Color(0xFFDB2777);
      case 'wellness':
        return const Color(0xFF0F766E);
      case 'healthcare':
        return const Color(0xFF2563EB);
      case 'fitness':
        return const Color(0xFFD97706);
      case 'consulting':
        return const Color(0xFF7C3AED);
      case 'automotive':
        return const Color(0xFFB45309);
      case 'home_services':
        return const Color(0xFF166534);
      default:
        return AppTheme.userPrimary;
    }
  }
}