class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] ?? false,
    );
  }
}