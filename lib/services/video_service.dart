import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideoService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // UPLOAD logic
  Future<void> uploadVideo({
    required File videoFile,
    required String title,
    required String description,
    required String skillLevel,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '$currentUserId/$fileName';

      // 1. Storage Upload
      await _supabase.storage.from('tutorial_videos').upload(
        filePath,
        videoFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Get Public URL
      final String videoUrl = _supabase.storage.from('tutorial_videos').getPublicUrl(filePath);

      // 3. Database Insert
      await _supabase.from('videos').insert({
        'user_id': currentUserId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'skill_level': skillLevel,
      });

      print("Upload successful for: $title");
    } catch (e) {
      print("Upload Error: $e");
      rethrow;
    }
  }

  Stream<List<VideoModel>> getVideoStream(String level) {
    // If 'All', we don't apply .eq() at all to avoid the filter logic
    if (level == 'All') {
      return _supabase
          .from('videos')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
    }

    // If a specific level is selected, .eq() MUST come immediately after .stream()
    return _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('skill_level', level) // Filter applied first
        .order('created_at', ascending: false) // Order applied second
        .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
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
        await _supabase.from('videos').delete().eq('id', videoId);
      } else {
        throw Exception("Unauthorized");
      }
    } catch (e) {
      print("Delete Error: $e");
      rethrow;
    }
  }
  Future<void> updateVideoDetails(String videoId, String newTitle, String newDesc) async {
    await _supabase.from('videos').update({
      'title': newTitle,
      'description': newDesc,
    }).eq('id', videoId);
  }

  Stream<List<VideoModel>> getMyVideosStream() {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return Stream.value([]);

    return _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // Filter by the logged-in user at the database level
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
  }
}