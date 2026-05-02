import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
 
import '../../services/api_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
 
class UserStoresScreen extends StatefulWidget {
  const UserStoresScreen({super.key});
 
  @override
  State<UserStoresScreen> createState() => _UserStoresScreenState();
}
 
class _UserStoresScreenState extends State<UserStoresScreen> {
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';
 
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
    _load();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final resp = await context.read<ApiService>().getStores();
      setState(() {
        _stores = List<Map<String, dynamic>>.from(
            resp['stores'] as List? ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _stores
        : _stores
            .where((s) => (s['store_name'] as String? ?? '')
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();
 
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // Header
        Container(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.go(AppRoutes.userMarketplace),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Browse Stores',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                        Text('${_stores.length} stores available',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75))),
                      ],
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(color: _txtP, fontSize: 14,),
                    decoration: InputDecoration(
                      hintText: 'Search stores...',
                      hintStyle:
                          TextStyle(color: _txtS, fontSize: 14),
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
                      // border: InputBorder.none,
                      filled: false,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
 
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.userPrimary))
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.userPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.store_outlined,
                              size: 36, color: AppTheme.userPrimary),
                        ),
                        const SizedBox(height: 16),
                        Text('No stores found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _txtP)),
                        const SizedBox(height: 6),
                        Text('Try a different search term',
                            style:
                                TextStyle(fontSize: 13, color: _txtS)),
                      ]))
                  : RefreshIndicator(
                      color: AppTheme.userPrimary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final s = filtered[i];
                          return _buildStoreCard(s);
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
 
  Widget _buildStoreCard(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () => context.go(
          AppRoutes.userServices
              .replaceAll(':storeId', s['id'].toString())),
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.userPrimary.withOpacity(0.18),
                    AppTheme.userPrimary.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.store_outlined,
                  color: AppTheme.userPrimary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['store_name'] as String? ?? 'Store',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _txtP,
                      )),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_city_outlined,
                        size: 12, color: _txtS),
                    const SizedBox(width: 4),
                    Text(
                      '${s['store_city'] ?? ''}, ${s['store_state'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: _txtS),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: _txtS),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s['store_address'] as String? ?? '',
                        style:
                            TextStyle(fontSize: 11, color: _txtS),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.userPrimary.withOpacity(_isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: AppTheme.userPrimary),
            ),
          ]),
        ),
      ),
    );
  }
}