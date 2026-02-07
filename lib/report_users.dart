import 'package:flutter/material.dart';
import 'database_service.dart';

class AdminReportedUsers extends StatelessWidget {
  const AdminReportedUsers({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Reported Users')),
      body: FutureBuilder(
        future: db.fetchReportedUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final reports = snapshot.data!;
          if (reports.isEmpty) return const Center(child: Text('No reports'));

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r = reports[i];
              return Card(
                child: ListTile(
                  title: Text(r['users']['email']),
                  subtitle: Text(r['reason']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => db.updateReportStatus(r['id'], value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'reviewed', child: Text('Mark Reviewed')),
                      PopupMenuItem(value: 'banned', child: Text('Ban User')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
