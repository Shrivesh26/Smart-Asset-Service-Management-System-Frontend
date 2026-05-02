class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? bookingId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.bookingId,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:            json['_id']?.toString()
                        ?? json['id']?.toString()   ?? '',
      type:          json['type']?.toString()       ?? '',
      title:         json['title']?.toString()      ?? '',
      message:       json['message']?.toString()    ?? '',
      isRead:        json['is_read'] as bool?
                        ?? json['isRead'] as bool?
                        ?? false,
      bookingId:     json['booking_id']?.toString()
                        ?? json['bookingId']?.toString(),
      createdAt:     _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':             id,
      'type':           type,
      'title':          title,
      'message':        message,
      'is_read':        isRead,
      'booking_id':     bookingId,
      'created_at':     createdAt.toIso8601String(),
    };
  }

  // Human-readable time ago
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id:            id,
      type:          type,
      title:         title,
      message:       message,
      isRead:        isRead ?? this.isRead,
      bookingId:     bookingId,
      createdAt:     createdAt,
    );
  }
}
