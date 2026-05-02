import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_asset_service/utils/app_routes.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

class TenantNotificationsScreen extends StatefulWidget {
  const TenantNotificationsScreen({super.key});
  @override
  State<TenantNotificationsScreen> createState() =>
      _TenantNotificationsScreenState();
}

class _TenantNotificationsScreenState
    extends State<TenantNotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter  = 'All'; // All | Unread | Read

  late final AnimationController _listCtrl;

  // ── Dark helpers ──────────────────────────────────────────────────────
  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surface => _isDark ? const Color(0xFF121212) : AppTheme.surface;
  Color get _txtP    => _isDark ? Colors.white : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? const Color(0xFF616161) : AppTheme.textHint;
  Color get _div     => _isDark ? const Color(0xFF2D2D2D) : AppTheme.dividerColor;
  Color get _unreadBg => _isDark
      ? AppTheme.tenantPrimary.withOpacity(0.1)
      : AppTheme.tenantLight;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _load();
  }

  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api  = context.read<ApiService>();
      final resp = await api.getNotifications();
      final list = (resp['notifications'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _notifications = list;
        _isLoading     = false;
      });
      _listCtrl.forward(from: 0);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await context.read<ApiService>().markAllNotificationsRead();
    await context.read<NotificationService>().fetchUnreadCount();
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id, type: n.type, title: n.title,
                message: n.message, isRead: true,
                createdAt: n.createdAt))
          .toList();
    });
  }

  List<NotificationModel> get _filtered {
    switch (_filter) {
      case 'Unread': return _notifications.where((n) => !n.isRead).toList();
      case 'Read':   return _notifications.where((n) => n.isRead).toList();
      default:       return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_booking':   return Icons.add_circle_outline_rounded;
      case 'status_update': return Icons.update_rounded;
      case 'assignment':    return Icons.assignment_ind_outlined;
      case 'completed':     return Icons.check_circle_outline_rounded;
      default:              return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_booking':   return AppTheme.tenantPrimary;
      case 'status_update': return AppTheme.statusInProgress;
      case 'completed':     return AppTheme.statusCompleted;
      case 'assignment':    return const Color(0xFFD97706);
      default:              return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(context),
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? _skeleton()
              : _filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.tenantPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _NotifCard(
                          key: ValueKey(_filtered[i].id),
                          notification: _filtered[i],
                          index: i,
                          isDark: _isDark,
                          cardBg: _cardBg,
                          unreadBg: _unreadBg,
                          txtP: _txtP,
                          txtS: _txtS,
                          txtH: _txtH,
                          div: _div,
                          icon: _iconForType(_filtered[i].type),
                          color: _colorForType(_filtered[i].type),
                          listController: _listCtrl,
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A0533), const Color(0xFF3D1A6E)]
              : [AppTheme.tenantDark, AppTheme.tenantPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.go(AppRoutes.tenantDashboard),
            ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifications',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                Text('$_unreadCount unread',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        color: Colors.white.withOpacity(0.75))),
              ],
            )),
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: const Text('Mark all read',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(children: ['All', 'Unread', 'Read'].map((f) {
        final sel = _filter == f;
        final cnt = f == 'All' ? _notifications.length
            : f == 'Unread' ? _unreadCount
            : _notifications.length - _unreadCount;
        return Padding(padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text('$f ${cnt > 0 ? '($cnt)' : ''}',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? AppTheme.tenantPrimary : _txtS)),
            selected: sel,
            onSelected: (_) {
              setState(() => _filter = f);
              _listCtrl.forward(from: 0);
            },
            selectedColor: AppTheme.tenantLight.withOpacity(_isDark ? 0.25 : 1),
            checkmarkColor: AppTheme.tenantPrimary,
            backgroundColor: _isDark ? const Color(0xFF2A2A2A) : AppTheme.surface,
            side: BorderSide(color: sel ? AppTheme.tenantPrimary : _div),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList()),
    );
  }

  Widget _skeleton() => ListView.builder(
    padding: const EdgeInsets.all(16), itemCount: 5,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 10), height: 78,
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 72, height: 72,
          decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E1E1E) : AppTheme.tenantLight,
              shape: BoxShape.circle),
          child: Icon(Icons.notifications_off_outlined, size: 34,
              color: AppTheme.tenantPrimary.withOpacity(0.5))),
      const SizedBox(height: 16),
      Text(_filter == 'All' ? 'No notifications yet' : 'No $_filter notifications',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w500, color: _txtP)),
      const SizedBox(height: 6),
      Text('All caught up!',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
    ],
  ));
}

// ══════════════════════════════════════════════════════════════════════
//  NOTIFICATION CARD (staggered entrance)
// ══════════════════════════════════════════════════════════════════════

class _NotifCard extends StatefulWidget {
  final NotificationModel notification;
  final int index;
  final bool isDark;
  final Color cardBg, unreadBg, txtP, txtS, txtH, div;
  final IconData icon;
  final Color color;
  final AnimationController listController;

  const _NotifCard({
    super.key,
    required this.notification,
    required this.index,
    required this.isDark,
    required this.cardBg,
    required this.unreadBg,
    required this.txtP,
    required this.txtS,
    required this.txtH,
    required this.div,
    required this.icon,
    required this.color,
    required this.listController,
  });

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 420));

    final start = (widget.index * 0.08).clamp(0.0, 0.7);
    final end   = (start + 0.4).clamp(0.0, 1.0);

    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic)));

    // Sync with parent list controller
    widget.listController.addListener(_syncAnim);
    _syncAnim();
  }

  void _syncAnim() {
    if (!mounted) return;
    if (widget.listController.value > 0) {
      _ctrl.value = widget.listController.value;
    }
  }

  @override
  void dispose() {
    widget.listController.removeListener(_syncAnim);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n     = widget.notification;
    final read  = n.isRead;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.statusInactive.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.statusInactive, size: 24),
          ),
          onDismissed: (_) {/* handle delete */},
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: read ? widget.cardBg : widget.unreadBg,
              borderRadius: BorderRadius.circular(16),
              border: read
                  ? Border.all(color: widget.div)
                  : Border.all(
                      color: AppTheme.tenantPrimary.withOpacity(0.2)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(
                      widget.isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              title: Text(n.title, style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 14,
                  fontWeight: read ? FontWeight.w400 : FontWeight.w600,
                  color: widget.txtP)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Text(n.message, style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: widget.txtS),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: widget.txtH),
                    const SizedBox(width: 3),
                    Text(n.timeAgo, style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 11, color: widget.txtH)),
                  ]),
                ],
              ),
              trailing: !read
                  ? Container(width: 9, height: 9,
                      decoration: const BoxDecoration(
                          color: AppTheme.tenantPrimary,
                          shape: BoxShape.circle))
                  : Icon(Icons.swipe_left_alt_rounded,
                      size: 14, color: widget.txtH),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
