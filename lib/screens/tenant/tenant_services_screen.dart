import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_media_image.dart';

class TenantServicesScreen extends StatefulWidget {
  const TenantServicesScreen({super.key});
  @override
  State<TenantServicesScreen> createState() => _TenantServicesScreenState();
}

class _TenantServicesScreenState extends State<TenantServicesScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  late final AnimationController _fabCtrl;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surface => _isDark ? const Color(0xFF121212) : AppTheme.surface;
  Color get _txtP => _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS => _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _txtH => _isDark ? const Color(0xFF616161) : AppTheme.textHint;
  Color get _div => _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;
  Color get _inputBg => _isDark ? const Color(0xFF2A2A2A) : Colors.white;

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
    await context
        .read<ServiceCatalogService>()
        .fetchServicesForAdmin(tenantId: id);
  }

  List<ServiceModel> _filtered(List<ServiceModel> all) {
    var list = all;
    if (_filter == 'Active') list = list.where((s) => s.isActive).toList();
    if (_filter == 'Inactive') list = list.where((s) => !s.isActive).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _deleteService(ServiceModel s, ServiceCatalogService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Service',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _txtP)),
        content: Text('Delete "${s.name}"? This cannot be undone.',
            style:
                TextStyle(fontFamily: 'Poppins', fontSize: 14, color: _txtS)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(fontFamily: 'Poppins', color: _txtS))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusInactive,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final deleted = await svc.deleteService(s.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          deleted
              ? '"${s.name}" removed'
              : (svc.error ?? 'Failed to remove service'),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor:
            deleted ? AppTheme.statusInactive : AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── View service detail bottom sheet ─────────────────────────────────
  void _viewService(ServiceModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceDetailSheet(
        service: s,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onEdit: () {
          Navigator.pop(context);
          _editService(s);
        },
      ),
    );
  }

  // ── Edit service bottom sheet ─────────────────────────────────────────
  void _editService(ServiceModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceEditSheet(
        service: s,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        div: _div,
        inputBg: _inputBg,
        onSave: (data, {imageBytes, imageName}) async {
          Navigator.pop(context);
          final svc = context.read<ServiceCatalogService>();
          await svc.updateService(
            s.id,
            data,
            imageBytes: imageBytes,
            imageName: imageName,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Service updated successfully',
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

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ServiceCatalogService>();
    final filtered = _filtered(svc.services);

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context, svc),
        // Filter chips
        Container(
          color: _cardBg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
              children: ['All', 'Active', 'Inactive'].map((f) {
            final sel = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? AppTheme.tenantPrimary : _txtS)),
                selected: sel,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor:
                    AppTheme.tenantLight.withOpacity(_isDark ? 0.25 : 1),
                checkmarkColor: AppTheme.tenantPrimary,
                backgroundColor:
                    _isDark ? const Color(0xFF2A2A2A) : AppTheme.surface,
                side: BorderSide(color: sel ? AppTheme.tenantPrimary : _div),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            );
          }).toList()),
        ),
        _statsStrip(svc),
        Expanded(
          child: svc.isLoading
              ? _skeleton()
              : filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.tenantPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ServiceCard(
                          key: ValueKey(filtered[i].id),
                          service: filtered[i],
                          index: i,
                          isDark: _isDark,
                          cardBg: _cardBg,
                          txtP: _txtP,
                          txtS: _txtS,
                          txtH: _txtH,
                          div: _div,
                          onToggle: (v) => svc
                              .updateService(filtered[i].id, {'isActive': v}),
                          onDelete: () => _deleteService(filtered[i], svc),
                          onView: () => _viewService(filtered[i]),
                          onEdit: () => _editService(filtered[i]),
                        ),
                      ),
                    ),
        ),
      ]),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.addService),
          backgroundColor: AppTheme.tenantPrimary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Service',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ServiceCatalogService svc) {
    final active = svc.services.where((s) => s.isActive).length;
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
                padding: const EdgeInsets.fromLTRB(18, 17, 15, 15),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Services',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('$active active  ·  ${svc.services.length} total',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75))),
                      ])),
                  IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => context.go(AppRoutes.addService),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.25))),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search services by name or skills...',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: _isDark
                              ? Colors.white.withOpacity(0.5)
                              : AppTheme.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: _isDark
                              ? Colors.white.withOpacity(0.8)
                              : AppTheme.textSecondary,
                          size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: _isDark
                                      ? Colors.white.withOpacity(0.8)
                                      : AppTheme.textSecondary,
                                  size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )),
          ])),
    );
  }

  Widget _statsStrip(ServiceCatalogService svc) {
    final active = svc.services.where((s) => s.isActive).length;
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Row(children: [
        _pill('${svc.services.length}', 'Total', AppTheme.textPrimary,
            _isDark ? const Color(0xFF2A2A2A) : AppTheme.surface),
        const SizedBox(width: 8),
        _pill('$active', 'Active', AppTheme.statusCompleted,
            _isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9)),
        const SizedBox(width: 8),
        _pill(
            '${svc.services.length - active}',
            'Inactive',
            AppTheme.statusInactive,
            _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFEBEE)),
      ]),
    );
  }

  Widget _pill(String n, String l, Color color, Color bg) => Expanded(
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
              style:
                  TextStyle(fontFamily: 'Poppins', fontSize: 10, color: _txtS)),
        ]),
      ));

  Widget _skeleton() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 110,
          decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(16))));

  Widget _empty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.home_repair_service_outlined, size: 56, color: _txtH),
        const SizedBox(height: 16),
        Text(_query.isNotEmpty ? 'No results' : 'No services yet',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _txtP)),
        const SizedBox(height: 8),
        Text(
            _query.isNotEmpty
                ? 'Try a different search'
                : 'Tap + Add Service to create one',
            style:
                TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
        if (_query.isEmpty) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.addService),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tenantPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Service',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ]));
}

// ══════════════════════════════════════════════════════════════════════
//  SERVICE CARD
// ══════════════════════════════════════════════════════════════════════
class _ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete, onView, onEdit;

  const _ServiceCard(
      {super.key,
      required this.service,
      required this.index,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onToggle,
      required this.onDelete,
      required this.onView,
      required this.onEdit});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = widget.service.isActive;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _catColor {
    switch (widget.service.category) {
      case 'beauty':
        return const Color(0xFFEC4899);
      case 'wellness':
        return const Color(0xFF8B5CF6);
      case 'healthcare':
        return const Color(0xFF06B6D4);
      case 'fitness':
        return const Color(0xFF10B981);
      case 'consulting':
        return const Color(0xFFF59E0B);
      case 'automotive':
        return const Color(0xFF6366F1);
      case 'home_services':
        return const Color(0xFF84CC16);
      default:
        return AppTheme.tenantPrimary;
    }
  }

  String get _catLabel {
    final c = widget.service.category;
    return c.isEmpty
        ? 'General'
        : c[0].toUpperCase() + c.substring(1).replaceAll('_', ' ');
  }

  Widget _fallbackIcon(Color cat) {
    return Center(
      child: Icon(
        Icons.home_repair_service_rounded,
        color: cat,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final cat = _catColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
          opacity: _ctrl.value,
          child: Transform.translate(
              offset: Offset(0, 24 * (1 - _ctrl.value)), child: child)),
      child: GestureDetector(
        onTap: widget.onView,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: _active ? cat.withOpacity(0.2) : widget.div),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.28 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                AppMediaImage(
                  imageUrl: widget.service.imageUrl,
                  fallbackIcon: Icons.home_repair_service_rounded,
                  accent: cat,
                  width: 54,
                  height: 54,
                  radius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.name,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.txtP),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: cat.withOpacity(widget.isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_catLabel,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cat)),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.currency_rupee_rounded,
                            size: 12, color: AppTheme.tenantPrimary),
                        Text(s.pricing.toStringAsFixed(0),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.tenantPrimary)),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded,
                            size: 12, color: widget.txtH),
                        const SizedBox(width: 3),
                        Text(s.durationDisplay,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: widget.txtS)),
                      ]),
                    ])),
                // Toggle + menu
                Column(children: [
                  Switch(
                    value: _active,
                    activeColor: AppTheme.tenantPrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) {
                      setState(() => _active = v);
                      widget.onToggle(v);
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: widget.txtH, size: 20),
                    color: widget.cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (v) {
                      if (v == 'view') widget.onView();
                      if (v == 'edit') widget.onEdit();
                      if (v == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => [
                      _menuItem('view', Icons.visibility_outlined,
                          'View Details', widget.txtP),
                      _menuItem('edit', Icons.edit_outlined, 'Edit Service',
                          AppTheme.tenantPrimary),
                      const PopupMenuDivider(),
                      _menuItem('delete', Icons.delete_outline_rounded,
                          'Delete', AppTheme.statusInactive,
                          color: AppTheme.statusInactive),
                    ],
                  ),
                ]),
              ]),
            ),
            // Status footer
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: _active
                    ? cat.withOpacity(widget.isDark ? 0.07 : 0.04)
                    : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Row(children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _active
                            ? AppTheme.statusCompleted
                            : AppTheme.statusInactive)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        _active
                            ? 'Active — visible to customers'
                            : 'Inactive — hidden from booking',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: _active
                                ? AppTheme.statusCompleted
                                : AppTheme.statusInactive))),
                Icon(Icons.chevron_right_rounded, size: 16, color: widget.txtH),
                Text('Tap to view',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: widget.txtH)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
          String val, IconData icon, String label, Color txtColor,
          {Color? color}) =>
      PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, size: 17, color: color ?? txtColor),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: color ?? txtColor)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════
//  SERVICE DETAIL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════
class _ServiceDetailSheet extends StatelessWidget {
  final ServiceModel service;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onEdit;

  const _ServiceDetailSheet(
      {required this.service,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),

        // ✅ 🔥 ADD IMAGE HERE
        if (service.imageUrl != null && service.imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              service.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,

              // ✅ fallback (important)
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: AppTheme.tenantPrimary.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.home_repair_service_rounded,
                  color: AppTheme.tenantPrimary, size: 26)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(s.name,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: txtP)),
                Text(s.category,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 12, color: txtS)),
              ])),
        ]),
        const SizedBox(height: 20),

        // Info grid
        Wrap(spacing: 12, runSpacing: 12, children: [
          _infoChip(Icons.currency_rupee_rounded,
              '${s.pricing.toStringAsFixed(0)}', '  Price'),
          _infoChip(Icons.access_time_rounded, s.durationDisplay, '  Duration'),
          _infoChip(
              Icons.group_outlined, '${s.providerIds.length}', '  Providers'),
          _infoChip(
              s.isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              s.isActive ? 'Active' : 'Inactive',
              '',
              color: s.isActive
                  ? AppTheme.statusCompleted
                  : AppTheme.statusInactive),
        ]),
        const SizedBox(height: 18),
        // Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: div),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Description',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: txtS)),
            const SizedBox(height: 6),
            Text(s.description,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: txtP,
                    height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tenantPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon:
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: const Text('Edit Service',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            )),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String value, String label, {Color? color}) {
    final c = color ?? AppTheme.tenantPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 15),
        Text('$value$label',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  SERVICE EDIT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════
class _ServiceEditSheet extends StatefulWidget {
  final ServiceModel service;
  final bool isDark;
  final Color cardBg, txtP, txtS, div, inputBg;
  final Future<void> Function(Map<String, dynamic>,
      {Uint8List? imageBytes, String? imageName}) onSave;

  const _ServiceEditSheet(
      {required this.service,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.div,
      required this.inputBg,
      required this.onSave});

  @override
  State<_ServiceEditSheet> createState() => _ServiceEditSheetState();
}

class _ServiceEditSheetState extends State<_ServiceEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durCtrl;
  late String _category;
  late bool _isActive;
  bool _saving = false;
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s.name);
    _descCtrl = TextEditingController(text: s.description);
    _priceCtrl = TextEditingController(text: s.pricing.toStringAsFixed(0));
    _durCtrl = TextEditingController(text: s.duration.toString());
    _category = s.category;
    _isActive = s.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    }
  }

  InputDecoration _deco(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Poppins', color: widget.txtS),
        filled: true,
        fillColor: widget.inputBg,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppTheme.tenantPrimary)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.div)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.div)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.tenantPrimary, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Text('Edit Service',
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
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.div),
                    color: widget.inputBg,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : (widget.service.imageUrl != null &&
                                widget.service.imageUrl!.isNotEmpty)
                            ? Image.network(
                                widget.service.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined,
                                      color: widget.txtS),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tap to upload image",
                                    style: TextStyle(color: widget.txtS),
                                  ),
                                ],
                              ),
                  ),
                ),

                // ✅ SHOW OVERLAY ONLY IF IMAGE EXISTS
                if (_imageBytes != null ||
                    (widget.service.imageUrl != null &&
                        widget.service.imageUrl!.isNotEmpty))
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: Colors.white),
                            SizedBox(height: 6),
                            Text(
                              "Tap to change image",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Name
          TextField(
              controller: _nameCtrl,
              style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
              decoration: _deco('Service name',
                  icon: Icons.home_repair_service_outlined)),
          const SizedBox(height: 12),
          // Category dropdown
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: widget.cardBg,
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14, color: widget.txtP),
            decoration: _deco('Category', icon: Icons.category_outlined),
            items: AppConstants.serviceCategories
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                        c[0].toUpperCase() +
                            c.substring(1).replaceAll('_', ' '),
                        style: TextStyle(
                            fontFamily: 'Poppins', color: widget.txtP))))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          // Price + Duration row
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
                    decoration: _deco('Price (₹)',
                        icon: Icons.currency_rupee_rounded))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _durCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
                    decoration: _deco('Duration (mins)',
                        icon: Icons.access_time_rounded))),
          ]),
          const SizedBox(height: 12),
          // Description
          TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
              decoration: _deco('Description')),
          const SizedBox(height: 12),
          // Active toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.div),
            ),
            child: Row(children: [
              Icon(Icons.toggle_on_outlined,
                  color: AppTheme.tenantPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Active (visible to customers)',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: widget.txtP))),
              Switch(
                value: _isActive,
                activeColor: AppTheme.tenantPrimary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ]),
          ),
          const SizedBox(height: 20),
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
                          'pricing': double.tryParse(_priceCtrl.text.trim()) ??
                              widget.service.pricing,
                          'duration': int.tryParse(_durCtrl.text.trim()) ??
                              widget.service.duration,
                          'isActive': _isActive,
                        }, imageBytes: _imageBytes, imageName: _imageName);
                        setState(() => _saving = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tenantPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
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
        ]),
      ),
    );
  }
}
