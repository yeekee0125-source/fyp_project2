import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  final _supabase = Supabase.instance.client;

  // Helper to get the current logged-in user's ID
  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // 1. Get user profile (for personalizing headers)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await _supabase.from('users').select('name').eq('id', userId).maybeSingle();
    } catch (e) {
      return null;
    }
  }

  // 2. USER: Initial Feedback Submission
  // Sets status to 'Pending'
  Future<void> submitFeedback({
    required int rating,
    required String reason,
    required String description
  }) async {
    if (currentUserId.isEmpty) return;
    await _supabase.from('feedback').insert({
      'user_id': currentUserId,
      'rating': rating,
      'reason': reason,
      'description': description,
      'status': 'Pending',
    });
  }

  // 3. ADMIN: Get stream of all feedback (filtered by status)
  Stream<List<Map<String, dynamic>>> getAdminFeedbackStream(String statusFilter) {
    return _supabase
        .from('feedback')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((list) async {
      List<Map<String, dynamic>> enriched = [];
      for (var item in list) {
        // Filter logic
        if (statusFilter != 'All' && item['status'] != statusFilter) continue;

        // Fetch user name to show in Admin list
        final userRes = await _supabase
            .from('users')
            .select('name')
            .eq('id', item['user_id'])
            .maybeSingle();

        item['user_name'] = userRes?['name'] ?? 'User';
        enriched.add(item);
      }
      return enriched;
    });
  }

  // 4. ADMIN: Reply to user feedback
  // Moves status to 'In Progress'
  Future<void> replyToFeedback(String feedbackId, String replyText) async {
    await _supabase.from('feedback').update({
      'admin_reply': replyText,
      'status': 'In Progress',
    }).eq('id', feedbackId);
  }

  // 5. USER: Reply back to Admin
  // Keeps status at 'In Progress' so Admin knows a response arrived
  Future<void> sendUserReply(String feedbackId, String replyText) async {
    await _supabase.from('feedback').update({
      'user_reply': replyText,
      'status': 'In Progress',
    }).eq('id', feedbackId);
  }

  // 6. ADMIN: Mark case as finished
  // Moves status to 'Resolved' - this will hide the input box for the user
  Future<void> resolveFeedback(String feedbackId) async {
    await _supabase.from('feedback').update({
      'status': 'Resolved',
    }).eq('id', feedbackId);
  }

  // 7. USER: Real-time stream of personal notifications/replies
  Stream<List<Map<String, dynamic>>> getUserFeedbackStream(String userId) {
    return _supabase
        .from('feedback')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // 8. SHARED: Manual status update helper
  Future<void> updateStatus(String id, String status) async {
    await _supabase.from('feedback').update({'status': status}).eq('id', id);
  }
}