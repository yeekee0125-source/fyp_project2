import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/feedback_service.dart';
import '../ai_chatbot/chat_page.dart';

class UserMessagePage extends StatefulWidget {
  const UserMessagePage({super.key});

  @override
  State<UserMessagePage> createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> with SingleTickerProviderStateMixin {
  final _service = FeedbackService();
  final _msgController = TextEditingController();
  final ScrollController _modalScrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_modalScrollController.hasClients) {
        _modalScrollController.animateTo(
          _modalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFFBE6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabToggle(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSupportTabContent(),
                    const ChatPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.orange,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.brown,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(
            child: Center(
              child: Text("Support", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Tab(
            child: Center(
              child: Text("AI Coach", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTabContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: tickets.length,
          itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
        );
      },
    );
  }


  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Support Center",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "How can we help you today?",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.brown.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No active tickets", style: TextStyle(color: Colors.brown, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    bool isResolved = ticket['status'] == 'Resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isResolved ? Colors.green[50] : Colors.orange[50],
            child: Icon(
              isResolved ? Icons.check_circle_outline : Icons.pending_outlined,
              color: isResolved ? Colors.green : Colors.orange,
            ),
          ),
          title: Text(ticket['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              ticket['status'],
              style: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.w600),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () => _showChatModal(ticket),
        ),
      ),
    );
  }

  void _showChatModal(Map<String, dynamic> initialData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBE6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            _buildModalHeader(initialData),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getUserStream(),
                builder: (context, snapshot) {
                  final currentTicket = snapshot.data?.firstWhere(
                        (t) => t['id'].toString() == initialData['id'].toString(),
                    orElse: () => initialData,
                  );
                  final List history = currentTicket?['chat_history'] ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _modalScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: history.length,
                    itemBuilder: (context, i) => _buildBubble(history[i]),
                  );
                },
              ),
            ),
            if (initialData['status'] != 'Resolved') _buildInput(initialData['id'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.support_agent, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['reason'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Online Support", style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey))
            ],
          ),
          const Divider(height: 30),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic chat) {
    bool isMe = chat['sender'] == 'user';
    DateTime dt = DateTime.parse(chat['time']).toLocal();
    String time = DateFormat('hh:mm a').format(dt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 2, left: isMe ? 50 : 0, right: isMe ? 0 : 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.orange : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Text(chat['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String feedbackId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(hintText: "Describe your issue...", contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                final text = _msgController.text.trim();
                if (text.isEmpty) return;
                _msgController.clear();
                await _service.sendMessage(feedbackId, text, 'user');
                _scrollToBottom();
              },
              child: const CircleAvatar(radius: 24, backgroundColor: Colors.orange, child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}