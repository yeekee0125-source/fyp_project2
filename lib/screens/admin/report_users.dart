import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminReportedUsers extends StatefulWidget {
  const AdminReportedUsers({super.key});

  @override
  State<AdminReportedUsers> createState() => _AdminReportedUsersState();
}

class _AdminReportedUsersState extends State<AdminReportedUsers> {
  final db = DatabaseService();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // 1. Fetch data once when the page loads
  Future<void> _fetchReports() async {
    try {
      final reports = await db.fetchReportedUsers();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Handle the action and instantly update the UI
  void _handleAction(String reportId, String status) async {
    // Optimistic UI Update: Instantly remove it from the screen
    setState(() {
      _reports.removeWhere((r) => r['id'] == reportId);
    });

    try {
      // Update the database in the background
      await db.updateReportStatus(reportId, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'banned' ? 'User Banned' : 'Report Marked as Reviewed'),
            backgroundColor: status == 'banned' ? Colors.red : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // If the database fails, re-fetch the list to correct the UI
      _fetchReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC), // Matching your admin theme
      appBar: AppBar(
        title: const Text('Reported Users', style: TextStyle(color: Colors.brown)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _reports.isEmpty
          ? const Center(child: Text('No reports to review.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _reports.length,
        itemBuilder: (_, i) {
          final r = _reports[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              ),
              title: Text(
                  r['users']['email'] ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text("Reason: ${r['reason']}"),
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) => _handleAction(r['id'], value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'reviewed',
                      child: Text('Mark Reviewed')
                  ),
                  PopupMenuItem(
                      value: 'banned',
                      child: Text('Ban User', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}