import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/provider_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class TenantProvidersScreen extends StatefulWidget {
  const TenantProvidersScreen({super.key});
  @override
  State<TenantProvidersScreen> createState() => _TenantProvidersScreenState();
}

class _TenantProvidersScreenState extends State<TenantProvidersScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  late final AnimationController _fabCtrl;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _inputBg => _isDark ? AppTheme.darkInput : Colors.white;

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
    await context.read<ProviderService>().fetchProviders(adminId: id);
  }

  List<UserModel> _filtered(List<UserModel> all) {
    var list = all;
    if (_filter == 'Active') list = list.where((p) => p.isActive).toList();
    if (_filter == 'Inactive') list = list.where((p) => !p.isActive).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              p.fullName.toLowerCase().contains(q) ||
              p.email.toLowerCase().contains(q) ||
              p.specializations.join(' ').toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _viewProvider(UserModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProviderDetailSheet(
        provider: p,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onEdit: () {
          Navigator.pop(context);
          _editProvider(p);
        },
        onToggle: () {
          Navigator.pop(context);
          _toggleStatus(p);
        },
      ),
    );
  }

  void _editProvider(UserModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProviderEditSheet(
        provider: p,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        div: _div,
        inputBg: _inputBg,
        onSave: (data) async {
          Navigator.pop(context);
          final svc = context.read<ProviderService>();
          await svc.updateProvider(p.id, data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Provider updated',
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

  Future<void> _toggleStatus(UserModel p) async {
    final newStatus = !p.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${newStatus ? 'Enable' : 'Disable'} Provider',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _txtP)),
        content: Text(
            'Are you sure you want to ${newStatus ? 'enable' : 'disable'} '
            '${p.fullName}?',
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
              backgroundColor: newStatus
                  ? AppTheme.providerPrimary
                  : AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(newStatus ? 'Enable' : 'Disable',
                style: const TextStyle(
                    fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<ProviderService>()
          .toggleProviderStatus(p.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${p.fullName} ${newStatus ? 'enabled' : 'disabled'}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor:
              newStatus ? AppTheme.statusCompleted : AppTheme.statusInactive,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ProviderService>();
    final filtered = _filtered(svc.providers);
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context, svc),
        _buildFilterBar(),
        _statsStrip(svc),
        Expanded(
          child: svc.isLoading
              ? _skeleton()
              : filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.tenantPrimary,
                      onRefresh: _load,
                      child:
                          w > 700 ? _buildGrid(filtered) : _buildList(filtered),
                    ),
        ),
      ]),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.addProvider),
          backgroundColor: AppTheme.tenantPrimary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Add Provider',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProviderService svc) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF3B0764), AppTheme.tenantDark]
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
                        const Text('Service Providers',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(
                            '${svc.totalCount} total  ·  ${svc.activeCount} active',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75))),
                      ])),
                  IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => context.go(AppRoutes.addProvider),
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
                      hintText: 'Search providers by name, email, or skills...',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: _isDark
                              ? Colors.white.withOpacity(0.6)
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

  Widget _buildFilterBar() {
    return Container(
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
              backgroundColor: _isDark ? AppTheme.darkInput : AppTheme.surface,
              side: BorderSide(color: sel ? AppTheme.tenantPrimary : _div),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ));
      }).toList()),
    );
  }

  Widget _statsStrip(ProviderService svc) {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(children: [
        _pill('${svc.totalCount}', 'Total', AppTheme.textPrimary,
            _isDark ? AppTheme.darkInput : AppTheme.surface),
        const SizedBox(width: 8),
        _pill('${svc.activeCount}', 'Active', AppTheme.statusCompleted,
            _isDark ? const Color(0xFF052E16) : const Color(0xFFECFDF5)),
        const SizedBox(width: 8),
        _pill('${svc.inactiveCount}', 'Inactive', AppTheme.statusInactive,
            _isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2)),
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

  Widget _buildList(List<UserModel> providers) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: providers.length,
      itemBuilder: (_, i) => _ProviderCard(
        key: ValueKey(providers[i].id),
        provider: providers[i],
        index: i,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onView: () => _viewProvider(providers[i]),
        onEdit: () => _editProvider(providers[i]),
        onToggle: () => _toggleStatus(providers[i]),
        onAssign: () => context.go(AppRoutes.tenantOrders),
      ),
    );
  }

  Widget _buildGrid(List<UserModel> providers) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.75),
      itemCount: providers.length,
      itemBuilder: (_, i) => _ProviderCard(
        key: ValueKey(providers[i].id),
        provider: providers[i],
        index: i,
        isDark: _isDark,
        cardBg: _cardBg,
        txtP: _txtP,
        txtS: _txtS,
        txtH: _txtH,
        div: _div,
        onView: () => _viewProvider(providers[i]),
        onEdit: () => _editProvider(providers[i]),
        onToggle: () => _toggleStatus(providers[i]),
        onAssign: () => context.go(AppRoutes.tenantOrders),
      ),
    );
  }

  Widget _skeleton() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 140,
          decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(18))));

  Widget _empty() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.engineering_outlined, size: 56, color: _txtH),
        const SizedBox(height: 16),
        Text(_query.isNotEmpty ? 'No results' : 'No providers yet',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _txtP)),
        const SizedBox(height: 8),
        Text(
            _query.isNotEmpty
                ? 'Try a different search'
                : 'Add your first service provider',
            style:
                TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
        if (_query.isEmpty) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.addProvider),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tenantPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(14)),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: const Text('Add Provider',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ]));
}

// ══════════════════════════════════════════════════════════════════════
//  PROVIDER CARD
// ══════════════════════════════════════════════════════════════════════
class _ProviderCard extends StatefulWidget {
  final UserModel provider;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onView, onEdit, onToggle, onAssign;

  const _ProviderCard(
      {super.key,
      required this.provider,
      required this.index,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onView,
      required this.onEdit,
      required this.onToggle,
      required this.onAssign});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    Future.delayed(Duration(milliseconds: widget.index * 65), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Color> get _avatarGrad {
    const palettes = [
      [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
      [Color(0xFF10B981), Color(0xFF059669)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ];
    final idx = widget.provider.fullName.codeUnits.fold(0, (a, b) => a + b) %
        palettes.length;
    return palettes[idx];
  }

  Widget _fallbackAvatar(UserModel p, List<Color> grad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          p.initials,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final grad = _avatarGrad;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
          opacity: _ctrl.value,
          child: Transform.translate(
              offset: Offset(0, 25 * (1 - _ctrl.value)), child: child)),
      child: GestureDetector(
        onTap: widget.onView,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: p.isActive
                  ? AppTheme.tenantPrimary.withOpacity(0.18)
                  : widget.div,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(children: [
            // Top row
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: (p.profilePhoto != null &&
                                  p.profilePhoto!.isNotEmpty)
                              ? Image.network(
                                  p.profilePhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fallbackAvatar(p, grad),
                                )
                              : _fallbackAvatar(p, grad),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p.fullName,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: widget.txtP),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(p.email,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: widget.txtH),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            if (p.specializations.isNotEmpty)
                              Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: p.specializations
                                      .take(2)
                                      .map((s) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: grad[0].withOpacity(
                                                    widget.isDark ? 0.2 : 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Text(s,
                                                style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color: grad[0])),
                                          ))
                                      .toList()),
                          ])),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: (p.isActive
                                    ? AppTheme.statusCompleted
                                    : AppTheme.statusInactive)
                                .withOpacity(widget.isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.isActive
                                      ? AppTheme.statusCompleted
                                      : AppTheme.statusInactive)),
                          const SizedBox(width: 4),
                          Text(p.isActive ? 'Active' : 'Off',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: p.isActive
                                      ? AppTheme.statusCompleted
                                      : AppTheme.statusInactive)),
                        ]),
                      ),
                    ])),

            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                _stat(Icons.star_rounded, p.rating.toStringAsFixed(1),
                    const Color(0xFFF59E0B)),
                Container(
                    width: 1,
                    height: 18,
                    color: widget.div,
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                _stat(Icons.check_circle_outline_rounded,
                    '${p.completedJobs ?? 0} jobs', AppTheme.statusCompleted),
                Container(
                    width: 1,
                    height: 18,
                    color: widget.div,
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                _stat(Icons.work_outline_rounded, '${p.experience} yrs',
                    widget.txtS),
              ]),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20))),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: widget.onView,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tenantPrimary,
                    side: BorderSide(
                        color: AppTheme.tenantPrimary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.visibility_outlined,
                      size: 14, color: AppTheme.tenantPrimary),
                  label: const Text('View',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: widget.onToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.isActive
                        ? AppTheme.statusInactive
                            .withOpacity(widget.isDark ? 0.15 : 0.08)
                        : AppTheme.statusCompleted
                            .withOpacity(widget.isDark ? 0.15 : 0.08),
                    foregroundColor: p.isActive
                        ? AppTheme.statusInactive
                        : AppTheme.statusCompleted,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                    p.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 14,
                  ),
                  label: Text(p.isActive ? 'Disable' : 'Enable',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: widget.txtH, size: 20),
                  color: widget.cardBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit();
                    if (v == 'assign') widget.onAssign();
                  },
                  itemBuilder: (_) => [
                    _mi('edit', Icons.edit_outlined, 'Edit',
                        AppTheme.tenantPrimary),
                    _mi('assign', Icons.assignment_ind_outlined, 'Assign Order',
                        widget.txtP),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) => Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis)),
      ]));

  PopupMenuItem<String> _mi(String v, IconData icon, String label, Color c) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 8),
            Text(label,
                style:
                    TextStyle(fontFamily: 'Poppins', fontSize: 13, color: c)),
          ]));
}

// ══════════════════════════════════════════════════════════════════════
//  PROVIDER DETAIL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════
class _ProviderDetailSheet extends StatelessWidget {
  final UserModel provider;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final VoidCallback onEdit, onToggle;

  const _ProviderDetailSheet(
      {required this.provider,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.txtH,
      required this.div,
      required this.onEdit,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    return Container(
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 18),
        // Header
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                AppTheme.tenantPrimary.withOpacity(isDark ? 0.2 : 0.12),
            backgroundImage:
                (p.profilePhoto != null && p.profilePhoto!.isNotEmpty)
                    ? NetworkImage(p.profilePhoto!)
                    : null,
            child: (p.profilePhoto == null || p.profilePhoto!.isEmpty)
                ? Text(
                    p.initials,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tenantPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p.fullName,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: txtP)),
                Text(p.email,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 12, color: txtS)),
              ])),
        ]),
        const SizedBox(height: 20),
        // Info chips
        Wrap(spacing: 10, runSpacing: 10, children: [
          _chip(Icons.phone_outlined, p.phone.isEmpty ? 'No phone' : p.phone),
          _chip(Icons.star_rounded, p.rating.toStringAsFixed(1),
              color: const Color(0xFFF59E0B)),
          _chip(Icons.check_circle_outline_rounded,
              '${p.completedJobs ?? 0} jobs',
              color: AppTheme.statusCompleted),
          _chip(Icons.work_outline_rounded, '${p.experience} yrs exp'),
          _chip(
            p.isActive ? Icons.circle : Icons.circle_outlined,
            p.isActive ? 'Active' : 'Inactive',
            color:
                p.isActive ? AppTheme.statusCompleted : AppTheme.statusInactive,
          ),
        ]),
        if (p.specializations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Specializations',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: txtS))),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.specializations
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppTheme.tenantPrimary
                                .withOpacity(isDark ? 0.18 : 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppTheme.tenantPrimary.withOpacity(0.2))),
                        child: Text(s,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tenantPrimary)),
                      ))
                  .toList()),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            onPressed: onToggle,
            style: OutlinedButton.styleFrom(
              foregroundColor: p.isActive
                  ? AppTheme.statusInactive
                  : AppTheme.statusCompleted,
              side: BorderSide(
                  color: (p.isActive
                          ? AppTheme.statusInactive
                          : AppTheme.statusCompleted)
                      .withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: Icon(
                p.isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                size: 16),
            label: Text(p.isActive ? 'Disable Provider' : 'Enable Provider',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tenantPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            label: const Text('Edit Profile',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          )),
        ]),
      ])),
    );
  }

  Widget _chip(IconData icon, String label,
          {Color color = AppTheme.tenantPrimary}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]));
}

// ══════════════════════════════════════════════════════════════════════
//  PROVIDER EDIT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════
class _ProviderEditSheet extends StatefulWidget {
  final UserModel provider;
  final bool isDark;
  final Color cardBg, txtP, txtS, div, inputBg;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _ProviderEditSheet(
      {required this.provider,
      required this.isDark,
      required this.cardBg,
      required this.txtP,
      required this.txtS,
      required this.div,
      required this.inputBg,
      required this.onSave});

  @override
  State<_ProviderEditSheet> createState() => _ProviderEditSheetState();
}

class _ProviderEditSheetState extends State<_ProviderEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late String _skill;
  late String _experience;
  bool _saving = false;

  String _experienceOptionForCurrentValue(String? value) {
    final years = int.tryParse((value ?? '').trim()) ?? 0;
    if (years >= 10) return AppConstants.experienceOptions[4];
    if (years >= 5) return AppConstants.experienceOptions[3];
    if (years >= 2) return AppConstants.experienceOptions[2];
    if (years >= 1) return AppConstants.experienceOptions[1];
    return AppConstants.experienceOptions[0];
  }

  int _experienceYearsFromOption(String value) {
    if (value == AppConstants.experienceOptions[4]) return 10;
    if (value == AppConstants.experienceOptions[3]) return 5;
    if (value == AppConstants.experienceOptions[2]) return 2;
    if (value == AppConstants.experienceOptions[1]) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _nameCtrl = TextEditingController(text: p.fullName);
    _phoneCtrl = TextEditingController(text: p.phone);
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _skill = p.skillCategory ?? AppConstants.skillCategories.first;
    _experience = _experienceOptionForCurrentValue(p.experience);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Text('Edit Provider',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.txtP)),
          const Spacer(),
          IconButton(
              icon: Icon(Icons.close_rounded, color: widget.txtS),
              onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        TextField(
            controller: _nameCtrl,
            style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
            decoration: _deco('Full name', icon: Icons.badge_outlined)),
        const SizedBox(height: 12),
        TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
            decoration: _deco('Phone number', icon: Icons.phone_outlined)),
        const SizedBox(height: 12),
        // Skill dropdown
        DropdownButtonFormField<String>(
          value: AppConstants.skillCategories.contains(_skill)
              ? _skill
              : AppConstants.skillCategories.first,
          dropdownColor: widget.cardBg,
          style: TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: widget.txtP),
          decoration: _deco('Skill category', icon: Icons.engineering_outlined),
          items: AppConstants.skillCategories
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      style: TextStyle(
                          fontFamily: 'Poppins', color: widget.txtP))))
              .toList(),
          onChanged: (v) => setState(() => _skill = v!),
        ),
        const SizedBox(height: 12),
        // Experience dropdown
        DropdownButtonFormField<String>(
          value: AppConstants.experienceOptions.contains(_experience)
              ? _experience
              : AppConstants.experienceOptions.first,
          dropdownColor: widget.cardBg,
          style: TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: widget.txtP),
          decoration: _deco('Experience', icon: Icons.work_outline_rounded),
          items: AppConstants.experienceOptions
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: TextStyle(
                          fontFamily: 'Poppins', color: widget.txtP))))
              .toList(),
          onChanged: (v) => setState(() => _experience = v!),
        ),
        const SizedBox(height: 12),
        TextField(
            controller: _bioCtrl,
            maxLines: 3,
            style: TextStyle(fontFamily: 'Poppins', color: widget.txtP),
            decoration: _deco('Bio / notes')),
        const SizedBox(height: 20),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave({
                        'firstName': _nameCtrl.text.trim().split(' ').first,
                        'lastName':
                            _nameCtrl.text.trim().split(' ').skip(1).join(' '),
                        'phone': _phoneCtrl.text.trim(),
                        'bio': _bioCtrl.text.trim(),
                        'experience': _experienceYearsFromOption(_experience),
                        'specializations': [_skill],
                      });
                      setState(() => _saving = false);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tenantPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
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
