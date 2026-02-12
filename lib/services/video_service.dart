import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideoService {
  final _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // UPLOAD logic with Error Handling
  Future<void> uploadVideo({
    required File videoFile,
    required String title,
    required String description,
    required String skillLevel,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '$currentUserId/$fileName'; // Organized by User ID

      // 1. Upload to Storage
      // Ensure bucket 'tutorial_videos' is created in Supabase Dashboard
      await _supabase.storage.from('tutorial_videos').upload(
        filePath,
        videoFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Get Public URL
      final String videoUrl =
      _supabase.storage.from('tutorial_videos').getPublicUrl(filePath);

      // 3. Insert to Video Table
      // Ensure 'videos' table RLS allow INSERTs
      await _supabase.from('videos').insert({
        'user_id': currentUserId,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'skill_level': skillLevel,
      });

      print("Upload successful for: $title");
    } on StorageException catch (e) {
      print("Storage Error: ${e.message}");
      rethrow;
    } on PostgrestException catch (e) {
      print("Database Error: ${e.message}");
      rethrow;
    } catch (e) {
      print("Unexpected Error: $e");
      rethrow;
    }
  }

  // STREAM: Real-time updates based on skill level
  Stream<List<VideoModel>> getVideoStream(String level) {
    if (level == 'All') {
      return _supabase
          .from('videos')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
    }

    return _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('skill_level', level)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => VideoModel.fromJson(json)).toList());
  }

  // DELETE logic: Admin or Owner permissions
  Future<void> deleteVideo(String videoId, String uploaderId) async {
    try {
      final userRes = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .single();

      bool isAdmin = userRes['role'] == 'admin';

      if (currentUserId == uploaderId || isAdmin) {
        await _supabase.from('videos').delete().eq('id', videoId);
      } else {
        throw Exception("Unauthorized: You do not have permission to delete this.");
      }
    } catch (e) {
      print("Delete Error: $e");
      rethrow;
    }
  }
}