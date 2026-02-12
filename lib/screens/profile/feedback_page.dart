import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';

class UserFeedbackPage extends StatefulWidget {
  const UserFeedbackPage({super.key});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final _service = FeedbackService();
  int _selectedRating = 3;
  String _selectedReason = "Bug Report";
  final _descCtrl = TextEditingController();

  final List<String> _reasons = ["Bug Report", "Feature Request", "Content Feedback", "Other"];
  final List<String> _emojis = ["😠", "🙁", "😐", "🙂", "😁"];

  // Helper to show success and navigate back
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("Thank you!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your voice heard, you help us to improve.", textAlign: TextAlign.center),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to Profile/Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Okay", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: FutureBuilder<Map<String, dynamic>?>(
          // Fetches the name from the 'users' table via the service
          future: _service.getUserProfile(_service.currentUserId),
          builder: (context, snapshot) {
            final name = snapshot.data?['name'] ?? "User";
            return Text("Hello, $name",
                style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold));
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Feedback", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 20),

            // 1. Rating Section
            _buildCard("Rate your experience", Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) => GestureDetector(
                onTap: () => setState(() => _selectedRating = index + 1),
                child: AnimatedScale(
                  scale: _selectedRating == index + 1 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Opacity(
                    opacity: _selectedRating == index + 1 ? 1.0 : 0.3,
                    child: Text(_emojis[index], style: const TextStyle(fontSize: 40)),
                  ),
                ),
              )),
            )),

            const SizedBox(height: 20),

            // 2. Reason Dropdown
            _buildCard("Reason", DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReason,
                isExpanded: true,
                items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedReason = val!),
              ),
            )),

            const SizedBox(height: 20),

            // 3. Description Input
            _buildCard("Description", TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Tell us more about your experience...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14)
              ),
            )),

            const SizedBox(height: 30),

            // 4. Submit Button
            ElevatedButton(
              onPressed: () async {
                if (_descCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please provide a description")),
                  );
                  return;
                }

                // Calls the updated submitFeedback in FeedbackService
                await _service.submitFeedback(
                    rating: _selectedRating,
                    reason: _selectedReason,
                    description: _descCtrl.text.trim()
                );

                _showSuccessDialog();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: const Text("Upload", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}