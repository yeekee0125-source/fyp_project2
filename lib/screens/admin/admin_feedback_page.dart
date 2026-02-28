import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/feedback_service.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        title: const Text("Admin Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((status) => _buildList(status)).toList(),
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getAdminStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(child: Text("No $status tickets found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];

            // We use FutureBuilder to get the user's name from the 'users' table
            return FutureBuilder<Map<String, dynamic>?>(
                future: _service.getUserProfile(item['user_id']),
                builder: (context, userSnapshot) {
                  String userName = userSnapshot.data?['name'] ?? "Loading user...";

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(item['status']).withOpacity(0.2),
                        child: Text(item['rating'].toString(), style: TextStyle(color: _getStatusColor(item['status']), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item['reason'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Subtitle now shows the Sender's Name
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From: $userName", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.w500)),
                          Text("Status: ${item['status']}"),
                        ],
                      ),
                      children: [
                        const Divider(),
                        _buildChatHistory(item['chat_history'] ?? [], userName),
                        _buildAdminControls(item),
                      ],
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  Widget _buildChatHistory(List<dynamic> history, String userName) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: history.length,
        itemBuilder: (context, i) {
          final msg = history[i];
          final bool isAdmin = msg['sender'] == 'admin';
          final DateTime dt = DateTime.parse(msg['time']).toLocal();
          final String time = DateFormat('MMM d, hh:mm a').format(dt);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Label showing who sent the message
                Text(
                  isAdmin ? "Admin" : userName,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(msg['message']),
                ),
                Text(time, style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminControls(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.reply, size: 18),
              label: const Text("Reply"),
              onPressed: () => _showReplyDialog(item['id'].toString()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: item['status'],
              underline: const SizedBox(),
              items: ["Pending", "In Progress", "Resolved"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: (val) => _service.updateStatus(item['id'].toString(), val!),
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String id) {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin Response"),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Enter your message...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                _service.sendMessage(id, ctrl.text.trim(), 'admin');
                Navigator.pop(context);
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.red;
      case 'In Progress': return Colors.orange;
      case 'Resolved': return Colors.green;
      default: return Colors.grey;
    }
  }
}