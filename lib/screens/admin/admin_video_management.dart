import 'package:flutter/material.dart';
import '../../services/video_service.dart';
import '../../models/video_model.dart';

class AdminVideoManagementPage extends StatefulWidget {
  const AdminVideoManagementPage({super.key});

  @override
  State<AdminVideoManagementPage> createState() => _AdminVideoManagementPageState();
}

class _AdminVideoManagementPageState extends State<AdminVideoManagementPage> {
  final VideoService _videoService = VideoService();

  void _handleDelete(VideoModel video) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${video.title}'? This will remove the video and thumbnail forever."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _videoService.deleteVideo(video.id.toString(), video.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video removed by Admin")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        title: const Text("VIDEO CONTENT CONTROL",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<VideoModel>>(
        stream: _videoService.getVideoStream('All'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return const Center(
                child: Text("No videos found in system.",
                    style: TextStyle(color: Colors.brown, fontSize: 16))
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),

                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: video.thumbnailUrl.isNotEmpty
                        ? Image.network(
                      video.thumbnailUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70, height: 70,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                        : Container(
                      width: 70, height: 70,
                      color: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.videocam, color: Colors.orange),
                    ),
                  ),

                  title: Text(
                      video.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "Difficulty: ${video.skillLevel}",
                        style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
                    onPressed: () => _handleDelete(video),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}