import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideoService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // UPLOAD logic
  Future<void> uploadVideo({
    required File videoFile,
    required File thumbnailFile,
    required String title,
    required String description,
    required String skillLevel,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Storage Upload for VIDEO
      final videoName = '$timestamp.mp4';
      final videoPath = '$currentUserId/$videoName';
      await _supabase.storage.from('tutorial_videos').upload(videoPath, videoFile);
      final String videoUrl = _supabase.storage.from('tutorial_videos').getPublicUrl(videoPath);

      // 2. Storage Upload for THUMBNAIL
      final thumbName = '$timestamp.jpg';
      final thumbPath = '$currentUserId/$thumbName';
      await _supabase.storage.from('thumbnails').upload(thumbPath, thumbnailFile);
      final String thumbnailUrl = _supabase.storage.from('thumbnails').getPublicUrl(thumbPath);

      // 3. Database Insert with BOTH URLs
      await _supabase.from('videos').insert({
        'user_id': currentUserId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl, // Saving the image URL here
        'skill_level': skillLevel,
      });

      print("Upload successful: $title with thumbnail");
    } catch (e) {
      print("Upload Error: $e");
      rethrow;
    }
  }

  Stream<List<VideoModel>> getVideoStream(String level) {
    var stream = _supabase
        .from('videos')
        .stream(primaryKey: ['id']);

    if (level != 'All') {
      return stream
          .map((data) => data
          .where((json) => json['skill_level'] == level)
          .map((json) => VideoModel.fromJson(json))
          .toList());
    }

    return stream.map((data) =>
        data.map((json) => VideoModel.fromJson(json)).toList()
    );
  }

  // DELETE logic
  Future<void> deleteVideo(String videoId, String uploaderId) async {
    try {
      final userRes = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .maybeSingle();
      bool isAdmin = userRes != null && userRes['role'] == 'admin';
      if (currentUserId == uploaderId || isAdmin) {
        final response = await _supabase
            .from('videos')
            .delete()
            .eq('id', videoId)
            .select();
        if (response.isEmpty) {
          throw Exception("No record found to delete or RLS policy blocked the action.");
        }
        print("Delete successful for UUID: $videoId");
      } else {
        throw Exception("Unauthorized: You do not have permission to delete this.");
      }
    } catch (e) {
      print("Delete Error: $e");
      rethrow;
    }
  }

  Future<void> updateVideoDetails(String videoId, String newTitle, String newDesc, String newLevel) async {
    await _supabase.from('videos').update({
      'title': newTitle,
      'description': newDesc,
      'skill_level': newLevel,
    }).eq('id', videoId);
  }

  Stream<List<VideoModel>> getMyVideosStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
  }


}