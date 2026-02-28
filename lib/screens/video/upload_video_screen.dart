import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/video_service.dart';

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({super.key});

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _service = VideoService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _videoFile;
  File? _thumbnailFile;
  bool _isUploading = false;
  String _selectedLevel = 'Beginner';

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _thumbnailFile = File(picked.path));
  }

  Future<void> _startUpload() async {
    if (_videoFile == null || _thumbnailFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video, a cover image, and enter a title.")),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _service.uploadVideo(
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile!,
        title: _titleController.text,
        description: _descController.text,
        skillLevel: _selectedLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚀 Video uploaded successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(title: const Text("Upload Tutorial"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: _buildUploadBox(
                file: _videoFile,
                label: "Select Tutorial Video",
                icon: Icons.video_library,
                isImage: false,
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isUploading ? null : _pickThumbnail,
              child: _buildUploadBox(
                file: _thumbnailFile,
                label: "Select Cover Image",
                icon: Icons.add_photo_alternate,
                isImage: true,
              ),
            ),

            const SizedBox(height: 20),
            _field("Title *", _titleController),
            _field("Description", _descController, maxLines: 3),
            const SizedBox(height: 10),
            const Text("Skill Level", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedLevel,
              isExpanded: true,
              items: ['Beginner', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: _isUploading ? null : (v) => setState(() => _selectedLevel = v!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isUploading ? null : _startUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              child: _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }

// Helper widget to build the upload boxes
  Widget _buildUploadBox({required File? file, required String label, required IconData icon, required bool isImage}) {
    return Container(
      height: 150, width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3D5),
        borderRadius: BorderRadius.circular(20),
        image: (isImage && file != null) ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
      ),
      child: file != null && !isImage
          ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 50))
          : (file == null)
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 40, color: Colors.brown), Text(label)])
          : null,
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      TextField(controller: controller, maxLines: maxLines, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
      const SizedBox(height: 15),
    ]);
  }
}