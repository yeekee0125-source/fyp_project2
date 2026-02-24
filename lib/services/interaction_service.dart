import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionService {
  final _supabase = Supabase.instance.client;
  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // --- LIKES LOGIC ---
  Future<int> getLikeCount(int recipeId) async {
    final res = await _supabase.from('likes').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Stream<int> getLikeCountStream(int recipeId) {
    return _supabase
        .from('likes')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .map((list) => list.length);
  }

  Future<bool> isLiked(int recipeId) async {
    if (currentUserId.isEmpty) return false;
    final res = await _supabase.from('likes').select().eq('user_id', currentUserId).eq('recipe_id', recipeId).maybeSingle();
    return res != null;
  }

  Future<void> toggleLike(int recipeId, bool currentStatus) async {
    if (currentUserId.isEmpty) return;
    if (currentStatus) {
      await _supabase.from('likes').delete().match({'user_id': currentUserId, 'recipe_id': recipeId});
    } else {
      await _supabase.from('likes').insert({'user_id': currentUserId, 'recipe_id': recipeId});
    }
  }

  // --- SAVES LOGIC ---
  Future<int> getSaveCount(int recipeId) async {
    final res = await _supabase.from('saves').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Stream<int> getSaveCountStream(int recipeId) {
    return _supabase
        .from('saves')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .map((list) => list.length);
  }

  Future<bool> isSaved(int recipeId) async {
    if (currentUserId.isEmpty) return false;
    final res = await _supabase.from('saves').select().eq('user_id', currentUserId).eq('recipe_id', recipeId).maybeSingle();
    return res != null;
  }

  Future<void> toggleSave(int recipeId, bool currentStatus) async {
    if (currentUserId.isEmpty) return;
    if (currentStatus) {
      await _supabase.from('saves').delete().match({'user_id': currentUserId, 'recipe_id': recipeId});
    } else {
      await _supabase.from('saves').insert({'user_id': currentUserId, 'recipe_id': recipeId});
    }
  }

  // --- COMMENTS LOGIC ---
  Future<int> getCommentCount(int recipeId) async {
    final res = await _supabase.from('comments').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Future<void> postComment(int recipeId, String content) async {
    if (currentUserId.isEmpty) return;
    await _supabase.from('comments').insert({'user_id': currentUserId, 'recipe_id': recipeId, 'content': content});
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(int recipeId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: false)
        .asyncMap((comments) async {
      List<Map<String, dynamic>> enrichedComments = [];
      for (var comment in comments) {
        final userRes = await _supabase
            .from('users')
            .select('name')
            .eq('id', comment['user_id'])
            .maybeSingle();
        comment['user_name'] = userRes?['name'] ?? 'Unknown User';
        enrichedComments.add(comment);
      }
      return enrichedComments;
    });
  }

  Future<void> deleteComment(dynamic commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId).eq('user_id', currentUserId);
  }

  // --- PROFILE & FOLLOW LOGIC ---
  Future<Map<String, dynamic>?> getCreatorProfile(String creatorId) async {
    try {
      if (creatorId.isEmpty) return null;
      return await _supabase.from('users').select('name').eq('id', creatorId).maybeSingle();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Stream<int> getFollowerCountStream(String targetUserId) {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .eq('following_id', targetUserId)
        .map((list) => list.length);
  }

  Stream<bool> isFollowingStream(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .eq('follower_id', currentUserId)
        .map((data) => data.any((row) => row['following_id'] == targetUserId));
  }

  Future<void> toggleFollow(String targetUserId, bool isCurrentlyFollowing) async {
    if (currentUserId.isEmpty || currentUserId == targetUserId) return;
    try {
      if (isCurrentlyFollowing) {
        await _supabase.from('follows').delete().eq('follower_id', currentUserId).eq('following_id', targetUserId);
      } else {
        await _supabase.from('follows').insert({'follower_id': currentUserId, 'following_id': targetUserId});
      }
    } catch (e) {
      debugPrint('Follow Error: $e');
    }
  }
}