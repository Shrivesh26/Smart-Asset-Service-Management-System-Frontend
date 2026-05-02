import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService extends ChangeNotifier {
  final ApiService _api;

  NotificationService(this._api);

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int  _unreadCount = 0;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────
  List<NotificationModel> get notifications     => _notifications;
  List<NotificationModel> get unreadList        =>
      _notifications.where((n) => !n.isRead).toList();
  List<NotificationModel> get readList          =>
      _notifications.where((n) => n.isRead).toList();
  bool   get isLoading   => _isLoading;
  int    get unreadCount => _unreadCount;
  String? get error      => _error;

  // ── Fetch all notifications ───────────────────────────────────────────
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.getNotifications();
      final list = (resp['notifications'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _notifications = list;
      _unreadCount   = list.where((n) => !n.isRead).length;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch only unread count (lightweight — for badge dot) ─────────────
  Future<void> fetchUnreadCount() async {
    try {
      final resp = await _api.getNotifications();
      final list = (resp['notifications'] as List<dynamic>? ?? [])
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = list.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {
      // silently fail — badge just won't show
    }
  }

  // ── Mark single notification as read ─────────────────────────────────
  Future<void> markRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        final n = _notifications[idx];
        _notifications[idx] = NotificationModel(
          id: n.id, type: n.type, title: n.title,
          message: n.message, isRead: true, createdAt: n.createdAt,
          bookingId: n.bookingId,
        );
        _unreadCount = _notifications.where((x) => !x.isRead).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Mark all as read ──────────────────────────────────────────────────
  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      _notifications = _notifications.map((n) => NotificationModel(
            id: n.id, type: n.type, title: n.title,
            message: n.message, isRead: true, createdAt: n.createdAt,
            bookingId: n.bookingId,
          )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Optimistically add a new notification (for push) ─────────────────
  void addNotification(NotificationModel n) {
    _notifications.insert(0, n);
    if (!n.isRead) _unreadCount++;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}