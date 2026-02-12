import 'package:flutter/material.dart';
import '../../services/feedback_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = FeedbackService();
  final List<String> _tabs = ["All", "Pending", "In Progress", "Resolved"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  // Helper for Rating Badge Colors
  Color _getRatingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating <= 2) return Colors.redAccent;
    if (rating == 3) return Colors.orangeAccent;
    return Colors.green;
  }

  // Suggestion logic for the Admin
  String _getReplySuggestion(int? rating) {
    if (rating == null) return "";
    if (rating <= 2) return "Tip: Apologize for the trouble and ask for more details.";
    if (rating == 3) return "Tip: Thank them for the feedback and mention we're improving.";
    return "Tip: Thank them for the support and encourage them to share!";
  }

  // Urgent logic (1-star and older than 24 hours)
  bool _isUrgent(int? rating, DateTime createdAt, String status) {
    if (status == "Resolved") return false;
    final hoursDifference = DateTime.now().difference(createdAt).inHours;
    return (rating != null && rating == 1 && hoursDifference >= 24);
  }

  void _showReplyDialog(String feedbackId, String? currentReply, int? rating) {
    final replyCtrl = TextEditingController(text: currentReply);
    final suggestion = _getReplySuggestion(rating);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reply to User", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(suggestion, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ),
            TextField(
              controller: replyCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter your response...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await _service.replyToFeedback(feedbackId, replyCtrl.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Send Reply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        title: const Text("Feedback Management", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.brown,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getAdminFeedbackStream(_tabs[_tabController.index]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No feedback found."));
                }

                final data = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final DateTime createdAt = DateTime.parse(item['created_at']).toLocal();
                    final String timeDisplay = timeago.format(createdAt);
                    final bool urgent = _isUrgent(item['rating'], createdAt, item['status']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        // LEADING: Standard User Icon
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.orange),
                        ),
                        // TITLE: Name + Rating Badge + Urgent Flag
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(item['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRatingColor(item['rating']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "⭐ ${item['rating'] ?? '?'}",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRatingColor(item['rating'])),
                              ),
                            ),
                            if (urgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                child: const Text("URGENT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Text("Category: ${item['reason'] ?? 'General'}", style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text(timeDisplay, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("User Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(item['description'] ?? "No description provided"),
                                const Divider(height: 20),
                                if (item['admin_reply'] != null && item['admin_reply'].toString().isNotEmpty) ...[
                                  const Text("Your Previous Reply:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                                  Text(item['admin_reply']),
                                  const SizedBox(height: 15),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.reply, size: 18),
                                        label: const Text("Reply"),
                                        onPressed: () => _showReplyDialog(item['id'].toString(), item['admin_reply'], item['rating']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    DropdownButton<String>(
                                      value: item['status'],
                                      underline: const SizedBox(),
                                      style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
                                      items: ["Pending", "In Progress", "Resolved"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) => _service.updateStatus(item['id'].toString(), val!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}