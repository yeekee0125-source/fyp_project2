import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<NotificationModel>> getUserNotifications() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) =>
        data.map((map) => NotificationModel.fromMap(map)).toList());
  }

  Future<void> createNotification({
    required String targetUserId,
    required String title,
    required String message,
    String? recipeId,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': targetUserId,
      'title': title,
      'message': message,
      'recipe_id': recipeId,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', user.id);
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', user.id);
  }
}