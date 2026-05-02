import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});
  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _all  = [];
  bool _loading = true;
  String _filter = 'All';
  late final AnimationController _stagger;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _unreadBg => _isDark
      ? AppTheme.providerPrimary.withOpacity(0.1)
      : AppTheme.providerLight;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _load();
  }

  @override
  void dispose() { _stagger.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await context.read<ApiService>().getNotifications();
      final list = (resp['notifications'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _all = list; _loading = false; });
      _stagger.forward(from: 0);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAll() async {
    await context.read<ApiService>().markAllNotificationsRead();
    await context.read<NotificationService>().fetchUnreadCount();
    setState(() {
      _all = _all.map((n) => NotificationModel(
          id: n.id, type: n.type, title: n.title,
          message: n.message, isRead: true,
          createdAt: n.createdAt)).toList();
    });
  }

  List<NotificationModel> get _filtered {
    switch (_filter) {
      case 'Unread': return _all.where((n) => !n.isRead).toList();
      case 'Read':   return _all.where((n) => n.isRead).toList();
      default:       return _all;
    }
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  IconData _icon(String type) {
    switch (type) {
      case 'assignment':    return Icons.assignment_ind_outlined;
      case 'status_update': return Icons.update_rounded;
      case 'new_booking':   return Icons.work_outline_rounded;
      case 'completed':     return Icons.check_circle_outline_rounded;
      default:              return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                  : [AppTheme.providerDark, AppTheme.providerPrimary])),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 20),
            child: Row(children: [
              // IconButton(
              //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
              //       color: Colors.white, size: 20),
              //   onPressed: () => context.go(AppRoutes.providerDashboard),
              // ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Notifications',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                Text('$_unreadCount unread',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        color: Colors.white.withOpacity(0.75))),
              ])),
              if (_unreadCount > 0) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('$_unreadCount',
                      style: const TextStyle(fontFamily: 'Poppins',
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                TextButton(
                  onPressed: _markAll,
                  child: const Text('Mark all read',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          )),
        ),

        // ── Filter chips ─────────────────────────────────────────────
        Container(
          color: _cardBg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(children: ['All', 'Unread', 'Read'].map((f) {
            final sel = _filter == f;
            final cnt = f == 'All' ? _all.length
                : f == 'Unread' ? _unreadCount
                : _all.length - _unreadCount;
            return Padding(padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('$f${cnt > 0 ? ' ($cnt)' : ''}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? AppTheme.providerPrimary : _txtS)),
                selected: sel,
                onSelected: (_) {
                  setState(() => _filter = f);
                  _stagger.forward(from: 0);
                },
                selectedColor: AppTheme.providerLight
                    .withOpacity(_isDark ? 0.25 : 1),
                checkmarkColor: AppTheme.providerPrimary,
                backgroundColor: _isDark ? AppTheme.darkInput : AppTheme.surface,
                side: BorderSide(
                    color: sel ? AppTheme.providerPrimary : _div),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                visualDensity: VisualDensity.compact,
              ));
          }).toList()),
        ),

        // ── List ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(
                  color: AppTheme.providerPrimary))
              : _filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.providerPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _NotifCard(
                          key: ValueKey(_filtered[i].id),
                          notification: _filtered[i], index: i,
                          isDark: _isDark, cardBg: _cardBg,
                          unreadBg: _unreadBg,
                          txtP: _txtP, txtS: _txtS, txtH: _txtH, div: _div,
                          icon: _icon(_filtered[i].type),
                          staggerCtrl: _stagger,
                          onTap: () async {
                            final n = _filtered[i];
                            if (!n.isRead) {
                              await context.read<ApiService>()
                                  .markNotificationRead(n.id);
                              await context
                                  .read<NotificationService>()
                                  .fetchUnreadCount();
                              setState(() {
                                final idx = _all.indexWhere(
                                    (x) => x.id == n.id);
                                if (idx != -1) {
                                  _all[idx] = NotificationModel(
                                      id: n.id, type: n.type,
                                      title: n.title, message: n.message,
                                      isRead: true, createdAt: n.createdAt);
                                }
                              });
                            }
                            if (n.bookingId?.isNotEmpty == true && mounted) {
                              context.go(AppRoutes.providerTaskDetail
                                  .replaceAll(':taskId', n.bookingId!));
                            }
                          },
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 70, height: 70,
        decoration: BoxDecoration(
            color: _isDark ? AppTheme.darkCard : AppTheme.providerLight,
            shape: BoxShape.circle),
        child: Icon(Icons.notifications_off_outlined, size: 34,
            color: AppTheme.providerPrimary.withOpacity(0.5))),
    const SizedBox(height: 16),
    Text(_filter == 'All' ? 'No notifications yet'
        : 'No $_filter notifications',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
            fontWeight: FontWeight.w500, color: _txtP)),
    const SizedBox(height: 6),
    Text('All caught up!',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
  ]));
}

// ══════════════════════════════════════════════════════════════════════
//  NOTIFICATION CARD
// ══════════════════════════════════════════════════════════════════════
class _NotifCard extends StatefulWidget {
  final NotificationModel notification;
  final int index;
  final bool isDark;
  final Color cardBg, unreadBg, txtP, txtS, txtH, div;
  final IconData icon;
  final AnimationController staggerCtrl;
  final VoidCallback onTap;

  const _NotifCard({super.key, required this.notification, required this.index,
    required this.isDark, required this.cardBg, required this.unreadBg,
    required this.txtP, required this.txtS, required this.txtH,
    required this.div, required this.icon, required this.staggerCtrl,
    required this.onTap});

  @override State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    widget.staggerCtrl.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final delay  = widget.index * 0.07;
    final val    = ((widget.staggerCtrl.value - delay) / 0.4).clamp(0.0, 1.0);
    _ctrl.value  = val;
  }

  @override
  void dispose() {
    widget.staggerCtrl.removeListener(_sync);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n    = widget.notification;
    final read = n.isRead;

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: read ? widget.cardBg : widget.unreadBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: read
                        ? widget.div
                        : AppTheme.providerPrimary,
                    width: read ? 1 : 3),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              leading: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.providerPrimary.withOpacity(
                      widget.isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(13)),
                child: Icon(widget.icon,
                    color: AppTheme.providerPrimary, size: 22)),
              title: Text(n.title, style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: read ? FontWeight.w400 : FontWeight.w600,
                  color: widget.txtP)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 3),
                Text(n.message, style: TextStyle(fontFamily: 'Poppins',
                    fontSize: 12, color: widget.txtS),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.access_time_rounded,
                      size: 11, color: widget.txtH),
                  const SizedBox(width: 3),
                  Text(n.timeAgo, style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 11, color: widget.txtH)),
                  if (!read) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.providerPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20)),
                      child: const Text('New', style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.providerPrimary)),
                    ),
                  ],
                ]),
              ]),
              trailing: !read
                  ? Container(width: 9, height: 9,
                      decoration: const BoxDecoration(
                          color: AppTheme.providerPrimary,
                          shape: BoxShape.circle))
                  : Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: widget.txtH),
            ),
          ),
        ),
      ),
    );

    return FadeTransition(
      opacity: _ctrl,
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: card),
    );
  }
}
