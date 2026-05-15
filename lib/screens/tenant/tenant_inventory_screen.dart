import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/asset_model.dart';
import '../../services/asset_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class TenantInventoryScreen extends StatefulWidget {
  const TenantInventoryScreen({super.key});
  @override
  State<TenantInventoryScreen> createState() => _TenantInventoryScreenState();
}

class _TenantInventoryScreenState extends State<TenantInventoryScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  String _sort = 'Name';
  bool _grid = false;
  late final AnimationController _fabCtrl;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surface =>
      _isDark ? const Color(0xFF121212) : AppTheme.surface;
  Color get _txtP =>
      _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _txtH =>
      _isDark ? const Color(0xFF616161) : AppTheme.textHint;
  Color get _div =>
      _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;
  Color get _inputBg =>
      _isDark ? const Color(0xFF2A2A2A) : Colors.white;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<AuthService>().currentUser?.id;
    await context.read<AssetService>().fetchAssets(adminId: id);
  }

  List<AssetModel> _processed(List<AssetModel> all) {
    var list = List<AssetModel>.from(all);
    if (_filter == 'Available') {
      list = list.where((a) => a.status.toLowerCase() == 'available').toList();
    } else if (_filter == 'Assigned') {
      list = list.where((a) => a.status.toLowerCase() == 'assigned').toList();
    } else if (_filter == 'Maintenance') {
      list =
          list.where((a) => a.status.toLowerCase() == 'maintenance').toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.category.toLowerCase().contains(q))
          .toList();
    }
    switch (_sort) {
      case 'Cost ↑':
        list.sort((a, b) => a.cost.compareTo(b.cost));
        break;
      case 'Cost ↓':
        list.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'Qty':
        list.sort(
            (a, b) => b.quantityAvailable.compareTo(a.quantityAvailable));
        break;
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  void _viewAsset(AssetModel a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AssetDetailSheet(
        asset: a,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onEdit: () {
          Navigator.pop(context);
          _editAsset(a);
        },
      ),
    );
  }

  void _editAsset(AssetModel a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AssetEditSheet(
        asset: a,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        div: _div,
        inputBg: _inputBg,
        onSave: (data) async {
          Navigator.pop(context);
          final svc = context.read<AssetService>();
          final rawImageBytes = data.remove('images');
          final rawImageNames = data.remove('imageNames');
          final imageBytes = rawImageBytes is List
              ? rawImageBytes.whereType<Uint8List>().toList()
              : <Uint8List>[];
          final imageNames = rawImageNames is List
              ? rawImageNames.map((n) => n.toString()).toList()
              : <String>[];
          await svc.updateAsset(a.id, data,
              imageBytesList: imageBytes, imageNames: imageNames);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Asset updated',
                  style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: AppTheme.statusCompleted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
      ),
    );
  }

  Future<void> _deleteAsset(AssetModel a, AssetService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Asset',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _txtP)),
        content: Text('Delete "${a.name}"? This cannot be undone.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14, color: _txtS)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      TextStyle(fontFamily: 'Poppins', color: _txtS))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusInactive,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final deleted = await svc.deleteAsset(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          deleted
              ? '"${a.name}" deleted'
              : (svc.error ?? 'Failed to delete asset'),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AssetService>();
    final processed = _processed(svc.assets);
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context, svc),
        _buildToolbar(),
        _statsStrip(svc),
        Expanded(
          child: svc.isLoading
              ? _skeleton()
              : processed.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.tenantPrimary,
                      onRefresh: _load,
                      child: _grid
                          ? _buildGrid(processed, w, svc)
                          : _buildList(processed, svc),
                    ),
        ),
      ]),
      floatingActionButton: ScaleTransition(
        scale:
            CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.addAsset),
          backgroundColor: AppTheme.tenantPrimary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Asset',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AssetService svc) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
                  : [AppTheme.tenantDark, AppTheme.tenantPrimary])),
      child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(19, 17, 15, 15),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Inventory',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(
                            '${svc.totalCount} assets  ·  ${svc.availableCount} available',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75))),
                      ])),
                  IconButton(
                    icon: Icon(
                        _grid
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 22),
                    onPressed: () => setState(() => _grid = !_grid),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => context.go(AppRoutes.addAsset),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25))),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search assets by name or category...',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.white70, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              })
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )),
          ])),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(children: [
        Expanded(
            child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children:
                  ['All', 'Available', 'Assigned', 'Maintenance'].map((f) {
            final sel = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(f,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                        color:
                            sel ? AppTheme.tenantPrimary : _txtS)),
                selected: sel,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppTheme.tenantLight
                    .withOpacity(_isDark ? 0.25 : 1),
                checkmarkColor: AppTheme.tenantPrimary,
                backgroundColor: _isDark
                    ? const Color(0xFF2A2A2A)
                    : AppTheme.surface,
                side: BorderSide(
                    color: sel ? AppTheme.tenantPrimary : _div),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList()),
        )),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _isDark
                ? const Color(0xFF2A2A2A)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _div),
          ),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
            value: _sort,
            isDense: true,
            icon: Icon(Icons.sort_rounded, size: 14, color: _txtS),
            dropdownColor:
                _isDark ? const Color(0xFF2A2A2A) : Colors.white,
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 11, color: _txtP),
            items: ['Name', 'Cost ↑', 'Cost ↓', 'Qty']
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sort = v!),
          )),
        ),
      ]),
    );
  }

  Widget _statsStrip(AssetService svc) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(children: [
        _pill('${svc.totalCount}', 'Total', AppTheme.textPrimary,
            _isDark ? const Color(0xFF2A2A2A) : AppTheme.surface),
        const SizedBox(width: 8),
        _pill('${svc.availableCount}', 'Available',
            AppTheme.statusCompleted,
            _isDark
                ? const Color(0xFF064E3B)
                : const Color(0xFFE8F5E9)),
        const SizedBox(width: 8),
        _pill('${svc.outOfStockCount}', 'Assigned',
            AppTheme.statusInactive,
            _isDark
                ? const Color(0xFF7F1D1D)
                : const Color(0xFFFFEBEE)),
      ]),
    );
  }

  Widget _pill(String n, String l, Color color, Color bg) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(n,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(l,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: _txtS)),
        ]),
      ));

  Widget _buildList(List<AssetModel> assets, AssetService svc) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: assets.length,
      itemBuilder: (_, i) => _AssetListCard(
        key: ValueKey(assets[i].id),
        asset: assets[i],
        index: i,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onView: () => _viewAsset(assets[i]),
        onEdit: () => _editAsset(assets[i]),
        onDelete: () => _deleteAsset(assets[i], svc),
      ),
    );
  }

  Widget _buildGrid(
      List<AssetModel> assets, double w, AssetService svc) {
    final cols = w > 600 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82),
      itemCount: assets.length,
      itemBuilder: (_, i) => _AssetGridCard(
        key: ValueKey(assets[i].id),
        asset: assets[i],
        index: i,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        onView: () => _viewAsset(assets[i]),
        onDelete: () => _deleteAsset(assets[i], svc),
      ),
    );
  }

  Widget _skeleton() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16))));

  Widget _empty() => Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
        Icon(Icons.inventory_2_outlined, size: 56, color: _txtH),
        const SizedBox(height: 16),
        Text(
            _query.isNotEmpty ? 'No results' : 'No assets yet',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _txtP)),
        const SizedBox(height: 8),
        Text(
            _query.isNotEmpty
                ? 'Try a different search'
                : 'Tap + Add Asset to get started',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _txtS)),
        if (_query.isEmpty) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.addAsset),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tenantPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12)),
            icon:
                const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Asset',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ]));
}

// ══════════════════════════════════════════════════════════════════════
//  IMAGE CAROUSEL
//  • 0 images → nothing rendered
//  • 1 image  → full-width hero (no arrows, no dots)
//  • 2-3 imgs → PageView with prev/next arrows + dot indicators
// ══════════════════════════════════════════════════════════════════════
class _NetworkImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final bool isDark;

  const _NetworkImageCarousel({
    required this.imageUrls,
    required this.isDark,
  });

  @override
  State<_NetworkImageCarousel> createState() =>
      _NetworkImageCarouselState();
}

class _NetworkImageCarouselState
    extends State<_NetworkImageCarousel> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    // ── Single image: full-width hero ──────────────────────────────
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          urls.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(200),
        ),
      );
    }

    // ── 2-3 images: carousel ───────────────────────────────────────
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // PageView
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: urls.length,
                  onPageChanged: (i) =>
                      setState(() => _current = i),
                  itemBuilder: (_, i) => Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(200),
                  ),
                ),
              ),
            ),

            // Left arrow
            if (_current > 0)
              Positioned(
                left: 8,
                child: _arrowBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),

            // Right arrow
            if (_current < urls.length - 1)
              Positioned(
                right: 8,
                child: _arrowBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),

            // Image counter badge (top-right)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_current + 1} / ${urls.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),

        // Dot indicators
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: active ? 22 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? AppTheme.tenantPrimary
                    : (widget.isDark
                        ? Colors.white30
                        : Colors.black26),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _arrowBtn(
          {required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _placeholder(double height) => Container(
        height: height,
        color: AppTheme.tenantPrimary.withOpacity(0.1),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AppTheme.tenantPrimary, size: 32),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════
//  MEMORY IMAGE CAROUSEL  (used in edit sheet preview)
// ══════════════════════════════════════════════════════════════════════
class _MemoryImageCarousel extends StatefulWidget {
  final List<Uint8List> imageBytes;
  final bool isDark;
  final VoidCallback onTap; // tap anywhere to re-pick

  const _MemoryImageCarousel({
    required this.imageBytes,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_MemoryImageCarousel> createState() =>
      _MemoryImageCarouselState();
}

class _MemoryImageCarouselState
    extends State<_MemoryImageCarousel> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = widget.imageBytes;
    if (bytes.isEmpty) return const SizedBox.shrink();

    if (bytes.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes.first,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: bytes.length,
                  onPageChanged: (i) =>
                      setState(() => _current = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: widget.onTap,
                    child: Image.memory(bytes[i],
                        fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            if (_current > 0)
              Positioned(
                left: 6,
                child: _arrow(
                  Icons.chevron_left_rounded,
                  () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            if (_current < bytes.length - 1)
              Positioned(
                right: 6,
                child: _arrow(
                  Icons.chevron_right_rounded,
                  () => _pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_current + 1}/${bytes.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(bytes.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? AppTheme.tenantPrimary
                    : (widget.isDark
                        ? Colors.white30
                        : Colors.black26),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════
//  ASSET LIST CARD
// ══════════════════════════════════════════════════════════════════════
class _AssetListCard extends StatefulWidget {
  final AssetModel asset;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onView, onEdit, onDelete;

  const _AssetListCard(
      {super.key,
      required this.asset,
      required this.index,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onView,
      required this.onEdit,
      required this.onDelete});

  @override
  State<_AssetListCard> createState() => _AssetListCardState();
}

class _AssetListCardState extends State<_AssetListCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _catColor(String cat) {
    const m = {
      'IT Equipment': Color(0xFF6366F1),
      'Furniture': Color(0xFF8B5CF6),
      'Vehicles': Color(0xFF06B6D4),
      'Machinery': Color(0xFFF59E0B),
    };
    return m[cat] ?? AppTheme.tenantPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    final cat = _catColor(a.category);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
          opacity: _ctrl.value,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - _ctrl.value)),
              child: child)),
      child: GestureDetector(
        onTap: widget.onView,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.div),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(widget.isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(children: [
            // Thumbnail (first image or icon)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: AppTheme.getStatusColor(a.status)
                      .withOpacity(widget.isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: a.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        a.imageUrls.first,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_rounded,
                            color: AppTheme.getStatusColor(a.status)),
                      ),
                    )
                  : Icon(Icons.inventory_2_rounded,
                      color: AppTheme.getStatusColor(a.status)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.name,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.txtP),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: cat
                              .withOpacity(widget.isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(a.category,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cat))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.currency_rupee_rounded,
                        size: 12, color: AppTheme.tenantPrimary),
                    Text(a.cost.toStringAsFixed(0),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.tenantPrimary)),
                    const SizedBox(width: 12),
                    Icon(Icons.layers_outlined,
                        size: 12, color: widget.txtH),
                    const SizedBox(width: 3),
                    Text('Qty: ${a.quantityAvailable}',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: widget.txtS)),
                    // Show image count badge if multiple images
                    if (a.imageUrls.length > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.tenantPrimary
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 10,
                                  color: AppTheme.tenantPrimary),
                              const SizedBox(width: 2),
                              Text('${a.imageUrls.length}',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.tenantPrimary)),
                            ]),
                      ),
                    ],
                  ]),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.getStatusColor(a.status)
                          .withOpacity(widget.isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(a.status,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              AppTheme.getStatusColor(a.status)))),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: widget.txtH),
                color: widget.cardBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'view') widget.onView();
                  if (v == 'edit') widget.onEdit();
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  _mi('view', Icons.visibility_outlined, 'View',
                      widget.txtP),
                  _mi('edit', Icons.edit_outlined, 'Edit',
                      AppTheme.tenantPrimary),
                  const PopupMenuDivider(),
                  _mi('delete', Icons.delete_outline_rounded, 'Delete',
                      AppTheme.statusInactive,
                      color: AppTheme.statusInactive),
                ],
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _mi(
          String v, IconData icon, String label, Color c,
          {Color? color}) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, size: 16, color: color ?? c),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: color ?? c)),
          ]));
}

// ══════════════════════════════════════════════════════════════════════
//  ASSET GRID CARD
// ══════════════════════════════════════════════════════════════════════
class _AssetGridCard extends StatefulWidget {
  final AssetModel asset;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS;
  final VoidCallback onView, onDelete;

  const _AssetGridCard(
      {super.key,
      required this.asset,
      required this.index,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.onView,
      required this.onDelete});

  @override
  State<_AssetGridCard> createState() => _AssetGridCardState();
}

class _AssetGridCardState extends State<_AssetGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    Future.delayed(Duration(milliseconds: widget.index * 40), () {
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
    final a = widget.asset;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
          opacity: _ctrl.value,
          child: Transform.scale(
              scale: 0.85 + 0.15 * _ctrl.value, child: child)),
      child: GestureDetector(
        onTap: widget.onView,
        onLongPress: widget.onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(widget.isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status accent bar
                Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(a.status),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)))),
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image or icon thumbnail
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: AppTheme.getStatusColor(
                                        a.status)
                                    .withOpacity(
                                        widget.isDark ? 0.2 : 0.1),
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: a.imageUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Image.network(
                                      a.imageUrls.first,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(
                                              Icons
                                                  .inventory_2_rounded,
                                              color: AppTheme
                                                  .getStatusColor(
                                                      a.status),
                                              size: 24),
                                    ),
                                  )
                                : Icon(Icons.inventory_2_rounded,
                                    color: AppTheme.getStatusColor(
                                        a.status),
                                    size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text(a.name,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.txtP),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(a.category,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: widget.txtS)),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '₹${a.cost.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppTheme.tenantPrimary)),
                                Row(children: [
                                  Text('×${a.quantityAvailable}',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: widget.txtS)),
                                  if (a.imageUrls.length > 1) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                        Icons
                                            .photo_library_outlined,
                                        size: 12,
                                        color: AppTheme.tenantPrimary
                                            .withOpacity(0.7)),
                                  ],
                                ]),
                              ]),
                        ])),
              ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  ASSET DETAIL SHEET  (with _NetworkImageCarousel)
// ══════════════════════════════════════════════════════════════════════
class _AssetDetailSheet extends StatelessWidget {
  final AssetModel asset;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onEdit;

  const _AssetDetailSheet(
      {required this.asset,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final a = asset;
    return Container(
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),

          // Title row
          Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(a.status)
                        .withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.inventory_2_rounded,
                    color: AppTheme.getStatusColor(a.status),
                    size: 26)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.name,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: txtP)),
                  Text(a.category,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: txtS)),
                ])),
          ]),

          // ── IMAGE CAROUSEL ────────────────────────────────────────
          if (a.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _NetworkImageCarousel(
              imageUrls: a.imageUrls,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 20),

          // Info chips
          Wrap(spacing: 10, runSpacing: 10, children: [
            _chip(Icons.currency_rupee_rounded,
                'Price: ${a.cost.toStringAsFixed(0)}',
                AppTheme.tenantPrimary),
            _chip(Icons.layers_outlined,
                'Qty: ${a.quantityAvailable}',
                AppTheme.tenantPrimary),
            _chip(
                a.status.toLowerCase() == 'maintenance'
                    ? Icons.build_circle_outlined
                    : a.status.toLowerCase() == 'assigned'
                        ? Icons.assignment_turned_in_outlined
                        : Icons.check_circle_outline_rounded,
                a.status,
                AppTheme.getStatusColor(a.status)),
            if (a.location.isNotEmpty)
              _chip(Icons.place_outlined, a.location,
                  AppTheme.textSecondary),
          ]),

          // Description
          if (a.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: div),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: txtS)),
                      const SizedBox(height: 6),
                      Text(a.description,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: txtP,
                              height: 1.5)),
                    ])),
          ],

          const SizedBox(height: 20),

          // Edit button
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tenantPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 18),
                label: const Text('Edit Asset',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              )),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]));
}

// ══════════════════════════════════════════════════════════════════════
//  ASSET EDIT SHEET  (with _MemoryImageCarousel)
// ══════════════════════════════════════════════════════════════════════
class _AssetEditSheet extends StatefulWidget {
  final AssetModel asset;
  final bool isDark;
  final Color cardBg, txtP, txtS, div, inputBg;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AssetEditSheet(
      {required this.asset,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.div,
      required this.inputBg,
      required this.onSave});

  @override
  State<_AssetEditSheet> createState() => _AssetEditSheetState();
}

class _AssetEditSheetState extends State<_AssetEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late String _category;
  late String _status;
  bool _saving = false;
  List<XFile> _images = [];
  List<Uint8List> _imageBytes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _nameCtrl = TextEditingController(text: a.name);
    _descCtrl = TextEditingController(text: a.description);
    _qtyCtrl =
        TextEditingController(text: a.quantityAvailable.toString());
    _costCtrl =
        TextEditingController(text: a.cost.toStringAsFixed(0));
    _category = a.category;
    _status = a.status.toLowerCase();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  // Max 3 images; uses readAsBytes() for web safety
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    final limited = picked.take(3).toList();
    final bytes =
        await Future.wait(limited.map((x) => x.readAsBytes()));
    setState(() {
      _images = limited;
      _imageBytes = bytes;
    });
  }

  InputDecoration _deco(String hint, {IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Poppins', color: widget.txtS),
        filled: true,
        fillColor: widget.inputBg,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppTheme.tenantPrimary)
            : null,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.div)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.div)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppTheme.tenantPrimary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color:
                        widget.isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),

        Row(children: [
          Text('Edit Asset',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.txtP)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: widget.txtS),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
        const SizedBox(height: 14),

        // Fields
        TextField(
            controller: _nameCtrl,
            style: TextStyle(
                fontFamily: 'Poppins', color: widget.txtP),
            decoration:
                _deco('Asset name', icon: Icons.inventory_2_outlined)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: widget.cardBg,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: widget.txtP),
          decoration:
              _deco('Category', icon: Icons.category_outlined),
          items: AppConstants.assetCategories
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: widget.txtP))))
              .toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontFamily: 'Poppins', color: widget.txtP),
                  decoration: _deco('Quantity',
                      icon: Icons.layers_outlined))),
          const SizedBox(width: 12),
          Expanded(
              child: TextField(
                  controller: _costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: TextStyle(
                      fontFamily: 'Poppins', color: widget.txtP),
                  decoration: _deco('Cost (₹)',
                      icon: Icons.currency_rupee_rounded))),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(
                fontFamily: 'Poppins', color: widget.txtP),
            decoration: _deco('Description')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status == 'assigned' ? 'available' : _status,
          dropdownColor: widget.cardBg,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: widget.txtP),
          decoration: _deco('Status',
              icon: Icons.build_circle_outlined),
          items: [
            DropdownMenuItem(
              value: 'available',
              child: Text('Available',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: widget.txtP)),
            ),
            DropdownMenuItem(
              value: 'maintenance',
              child: Text('Maintenance',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: widget.txtP)),
            ),
          ],
          onChanged: (v) =>
              setState(() => _status = v ?? 'available'),
        ),
        const SizedBox(height: 20),

        // ── IMAGE PICKER (carousel preview or placeholder) ─────────
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Images (max 3)',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.txtP)),
            const Spacer(),
            TextButton.icon(
              onPressed: _imageBytes.length < 3 ? _pickImages : null,
              icon: Icon(Icons.add_photo_alternate_outlined,
                  size: 16, color: AppTheme.tenantPrimary),
              label: Text(
                _imageBytes.isEmpty ? 'Add Photos' : 'Change',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppTheme.tenantPrimary),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_imageBytes.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary.withOpacity(0.05),
                  border: Border.all(
                      color: AppTheme.tenantPrimary.withOpacity(0.3),
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: AppTheme.tenantPrimary
                              .withOpacity(0.6)),
                      const SizedBox(height: 8),
                      Text('Tap to add images (max 3)',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppTheme.tenantPrimary
                                  .withOpacity(0.7))),
                    ]),
              ),
            )
          else
            _MemoryImageCarousel(
              imageBytes: _imageBytes,
              isDark: widget.isDark,
              onTap: _pickImages,
            ),
        ]),

        const SizedBox(height: 20),

        // Save button
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave({
                        'name': _nameCtrl.text.trim(),
                        'category': _category,
                        'description': _descCtrl.text.trim(),
                        'quantity': int.tryParse(
                                _qtyCtrl.text.trim()) ??
                            widget.asset.quantity,
                        'value': double.tryParse(
                                _costCtrl.text.trim()) ??
                            widget.asset.cost,
                        'status': _status,
                        'images': _imageBytes,
                        'imageNames':
                            _images.map((e) => e.name).toList(),
                      });
                      setState(() => _saving = false);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tenantPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            )),
      ])),
    );
  }
}