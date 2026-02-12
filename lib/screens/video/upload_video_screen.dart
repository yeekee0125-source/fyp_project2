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
  bool _isUploading = false;
  String _selectedLevel = 'Beginner';

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoFile = File(picked.path));
  }

  Future<void> _startUpload() async {
    if (_videoFile == null || _titleController.text.isEmpty) return;
    setState(() => _isUploading = true);
    try {
      await _service.uploadVideo(
        videoFile: _videoFile!,
        title: _titleController.text,
        description: _descController.text,
        skillLevel: _selectedLevel,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
              child: Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFE8E3D5), borderRadius: BorderRadius.circular(20)),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : _videoFile != null
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 50)
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload, size: 40), Text("Tap to upload video")]),
              ),
            ),
            const SizedBox(height: 20),
            _field("Title *", _titleController),
            _field("Description", _descController, maxLines: 3),
            const SizedBox(height: 20),
            const Text("Skill Level", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedLevel,
              isExpanded: true,
              items: ['Beginner', 'Intermediate', 'Advanced'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLevel = v!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isUploading ? null : _startUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
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