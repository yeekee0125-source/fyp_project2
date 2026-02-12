import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/feedback_service.dart';

class UserMessagePage extends StatefulWidget {
  const UserMessagePage({super.key});

  @override
  State<UserMessagePage> createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> {
  final _service = FeedbackService();
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Messages",
            style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: Column(
        children: [
          _buildInteractionHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getUserFeedbackStream(_service.currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text("No messages yet.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final DateTime createdAt = DateTime.parse(item['created_at']).toLocal();

                    // UI LOGIC: Glow orange if Admin is handling it (In Progress)
                    // Grey out once it is finally Resolved.
                    bool isActive = item['status'] == 'In Progress';

                    return _buildMessageItem(
                      title: "KitchenBuddy Support",
                      subtitle: item['admin_reply'] ?? item['description'],
                      time: timeago.format(createdAt),
                      status: item['status'],
                      isOrange: isActive,
                      onTap: () => _showChatDetails(item),
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

  Widget _buildInteractionHeader() {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE58F),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _interactionBtn(Icons.favorite_border, "Likes", true),
          _interactionBtn(Icons.chat_bubble_outline, "Comments", false),
          _interactionBtn(Icons.people_outline, "Following", true),
        ],
      ),
    );
  }

  Widget _interactionBtn(IconData icon, String label, bool dot) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(icon, size: 30, color: Colors.brown[800]),
            if (dot)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.brown)),
      ],
    );
  }

  Widget _buildMessageItem({
    required String title,
    required String subtitle,
    required String time,
    required String status,
    required bool isOrange,
    required VoidCallback onTap
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isOrange ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(Icons.support_agent, color: isOrange ? Colors.orange : Colors.grey),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOrange ? Colors.orange : Colors.brown[300])),
          ],
        ),
      ),
    );
  }

  void _showChatDetails(Map<String, dynamic> feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBE6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Support Case", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: feedback['status'] == 'Resolved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(feedback['status'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: feedback['status'] == 'Resolved' ? Colors.green : Colors.orange)),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Conversation Flow
            _chatBubble(message: feedback['description'], isMe: true, label: "Initial Query"),

            if (feedback['admin_reply'] != null)
              _chatBubble(message: feedback['admin_reply'], isMe: false, label: "Admin Response"),

            if (feedback['user_reply'] != null)
              _chatBubble(message: feedback['user_reply'], isMe: true, label: "Your Follow-up"),

            const Divider(height: 30),

            // INPUT LOGIC: Only show input if case is NOT Resolved
            if (feedback['status'] != 'Resolved')
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: "Write a reply...",
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange),
                    onPressed: () async {
                      final text = _replyController.text.trim();
                      if (text.isNotEmpty) {
                        await _service.sendUserReply(feedback['id'].toString(), text);
                        _replyController.clear();
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text("This conversation has been resolved and closed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble({required String message, required bool isMe, required String label}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFFE58F) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Text(message, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}