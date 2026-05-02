// ═══════════════════════════════════════════════════════════════
//  user_notifications_screen.dart
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final resp = await context.read<ApiService>().getNotifications();
      final list = resp['notifications'] as List<dynamic>? ?? [];
      setState(() {
        _notifications = list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 15, 16, 20),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          )),
                      if (unreadCount > 0)
                        Text('$unreadCount unread',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
                if (_notifications.any((n) => !n.isRead))
                  TextButton(
                    onPressed: () async {
                      await context
                          .read<ApiService>()
                          .markAllNotificationsRead();
                      await context
                          .read<NotificationService>()
                          .fetchUnreadCount();
                      _load();
                    },
                    child: const Text('Mark all read',
                        style:
                            TextStyle(color: Colors.white, fontSize: 13)),
                  ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.userPrimary))
              : _notifications.isEmpty
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
                          child: const Icon(
                            Icons.notifications_off_outlined,
                            size: 36,
                            color: AppTheme.userPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('No notifications',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _txtP)),
                        const SizedBox(height: 6),
                        Text("You're all caught up!",
                            style:
                                TextStyle(fontSize: 13, color: _txtS)),
                      ]),
                    )
                  : RefreshIndicator(
                      color: AppTheme.userPrimary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final n = _notifications[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: !n.isRead
                                  ? Border.all(
                                      color: AppTheme.userPrimary
                                          .withOpacity(0.18))
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(_isDark ? 0.18 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.userPrimary
                                      .withOpacity(n.isRead ? 0.08 : 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.notifications_outlined,
                                    color: AppTheme.userPrimary, size: 22),
                              ),
                              title: Text(n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: _txtP,
                                  )),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(n.message,
                                      style: TextStyle(
                                          fontSize: 12, color: _txtS)),
                                  const SizedBox(height: 4),
                                  Text(n.timeAgo,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _txtS.withOpacity(0.7))),
                                ],
                              ),
                              trailing: !n.isRead
                                  ? Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.userPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}
