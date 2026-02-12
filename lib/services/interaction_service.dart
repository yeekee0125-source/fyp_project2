import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionService {
  final _supabase = Supabase.instance.client;
  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // Fetch real-time count from DB for accurate display on page load
  Future<int> getLikeCount(int recipeId) async {
    final res = await _supabase.from('likes').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Future<int> getSaveCount(int recipeId) async {
    final res = await _supabase.from('saves').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Future<int> getCommentCount(int recipeId) async {
    final res = await _supabase.from('comments').select('id').eq('recipe_id', recipeId);
    return res.length;
  }

  Future<bool> isLiked(int recipeId) async {
    final res = await _supabase.from('likes').select().eq('user_id', currentUserId).eq('recipe_id', recipeId).maybeSingle();
    return res != null;
  }

  Future<void> toggleLike(int recipeId, bool currentStatus) async {
    if (currentStatus) {
      // DISLIKE: Delete from Supabase
      await _supabase.from('likes').delete().match({'user_id': currentUserId, 'recipe_id': recipeId});
    } else {
      // LIKE: Insert to Supabase
      await _supabase.from('likes').insert({'user_id': currentUserId, 'recipe_id': recipeId});
    }
  }

  Future<bool> isSaved(int recipeId) async {
    final res = await _supabase.from('saves').select().eq('user_id', currentUserId).eq('recipe_id', recipeId).maybeSingle();
    return res != null;
  }

  Future<void> toggleSave(int recipeId, bool currentStatus) async {
    if (currentStatus) {
      // UNSAVE: Delete from Supabase
      await _supabase.from('saves').delete().match({'user_id': currentUserId, 'recipe_id': recipeId});
    } else {
      // SAVE: Insert to Supabase
      await _supabase.from('saves').insert({'user_id': currentUserId, 'recipe_id': recipeId});
    }
  }

  // --- COMMENTS ---
  Future<void> postComment(int recipeId, String content) async {
    await _supabase.from('comments').insert({'user_id': currentUserId, 'recipe_id': recipeId, 'content': content});
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(int recipeId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
    // This part is key: it tells Supabase to include the user's name
        .order('created_at', ascending: false)
        .asyncMap((comments) async {
      // Since Supabase stream doesn't support direct joins easily,
      // we fetch the user names for the comments in this list.
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
  /// Listens to the 'likes' table and returns the current count for a recipe
  Stream<int> getLikeCountStream(int recipeId) {
    return _supabase
        .from('likes')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .map((list) => list.length);
  }

  /// Listens to the 'saves' table and returns the current count for a recipe
  Stream<int> getSaveCountStream(int recipeId) {
    return _supabase
        .from('saves')
        .stream(primaryKey: ['id'])
        .eq('recipe_id', recipeId)
        .map((list) => list.length);
  }

/// Fetches creator info from the 'users' table
  Future<Map<String, dynamic>?> getCreatorProfile(String creatorId) async {
    try {
      if (creatorId.isEmpty) return null;

      final res = await _supabase
          .from('users')
          .select('name') // Only fetch the name
          .eq('id', creatorId)
          .maybeSingle();

      return res;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // --- FOLLOW LOGIC ---

  /// NEW: Listens to the 'follows' table and returns the total follower count for a user
  Stream<int> getFollowerCountStream(String targetUserId) {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .eq('following_id', targetUserId) // Count where this person is being followed
        .map((list) => list.length);
  }

  /// Real-time follow status listener (checks if current user follows target)
  Stream<bool> isFollowingStream(String targetUserId) {
    if (currentUserId.isEmpty) return Stream.value(false);

    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .eq('follower_id', currentUserId)
        .map((data) {
      return data.any((row) => row['following_id'] == targetUserId);
    });
  }

  Future<void> toggleFollow(String targetUserId, bool isCurrentlyFollowing) async {
    if (currentUserId.isEmpty) return;
    if (currentUserId == targetUserId) return; // Prevent self-following

    try {
      if (isCurrentlyFollowing) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);
      } else {
        await _supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });
      }
    } catch (e) {
      debugPrint('Follow Error: $e');
    }
  }
}