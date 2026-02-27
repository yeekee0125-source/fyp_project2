class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? recipeId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.recipeId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      isRead: map['is_read'] == true,
      recipeId: map['recipe_id']?.toString(),
    );
  }
}