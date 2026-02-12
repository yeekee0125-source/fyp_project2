import 'package:flutter/material.dart';
import '../../services/recipe_service.dart';
import 'package:flutter/material.dart';

import '../video/upload_video_screen.dart';


class UploadSelectionScreen extends StatelessWidget {
  const UploadSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Upload Recipe", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Content Type",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 25),
            Row(
              children: [
                // 1. Existing Recipe Button
                _buildCard(
                  context,
                  title: "Recipe Photo",
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFFFFE58F),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecipePage())),
                ),
                const SizedBox(width: 15),
                // 2. Updated Tutorial Video Button
                _buildCard(
                  context,
                  title: "Tutorial Video",
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFFFFE58F),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoUploadPage())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.brown, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
        ),
      ),
    );
  }
}