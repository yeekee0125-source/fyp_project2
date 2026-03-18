import 'package:flutter/material.dart';
import '../../services/video_service.dart';
import '../../models/video_model.dart';
import 'video_player_page.dart';

class MyVideosPage extends StatefulWidget {
  const MyVideosPage({super.key});

  @override
  State<MyVideosPage> createState() => _MyVideosPageState();
}

class _MyVideosPageState extends State<MyVideosPage> {
  final VideoService _videoService = VideoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C2),
      appBar: AppBar(
        title: const Text("Manage My Tutorials",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: StreamBuilder<List<VideoModel>>(
        stream: _videoService.getMyVideosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final myVideos = snapshot.data ?? [];

          if (myVideos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 80, color: Colors.brown.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  const Text("No videos found in your account.",
                      style: TextStyle(color: Colors.brown, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: myVideos.length,
            itemBuilder: (context, index) {
              final video = myVideos[index];
              return _buildVideoItem(video);
            },
          );
        },
      ),
    );
  }

  Widget _buildVideoItem(VideoModel video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(
                videoUrl: video.videoUrl,
                thumbnailUrl: video.thumbnailUrl,
                title: video.title,
              ),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 80,
            height: 60,
            color: Colors.grey[200],
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (video.thumbnailUrl.isNotEmpty)
                  Image.network(
                    video.thumbnailUrl,
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
                  )
                else
                  const Icon(Icons.videocam, color: Colors.grey),

                Container(
                  decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
        title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Level: ${video.skillLevel}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(video),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(video),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE LOGIC
  void _showEditDialog(VideoModel video) {
    final titleController = TextEditingController(text: video.title);
    String selectedLevel = video.skillLevel;
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Tutorial"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  enabled: !isUpdating,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(labelText: "Skill Level"),
                  items: ['Beginner', 'Intermediate', 'Advanced']
                      .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                      .toList(),
                  onChanged: isUpdating ? null : (value) {
                    setDialogState(() => selectedLevel = value!);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isUpdating ? null : () async {
                  setDialogState(() => isUpdating = true);

                  try {
                    await _videoService.updateVideoDetails(
                      video.id,
                      titleController.text,
                      video.description,
                      selectedLevel,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tutorial updated successfully!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isUpdating = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                    );
                  }
                },
                child: isUpdating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save Changes"),
              )
            ],
          );
        },
      ),
    );
  }

  // DELETE LOGIC
  void _confirmDelete(VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Video?"),
        content: const Text("Are you sure you want to delete this tutorial?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _videoService.deleteVideo(video.id, video.userId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}