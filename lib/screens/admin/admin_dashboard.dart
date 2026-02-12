import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../auth/login.dart';
import 'report_users.dart';
import 'pending_recipes.dart';
import 'admin_feedback_page.dart';
// Note: Import your Feedback and Video management screens here once created

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ADMIN CONTROL CENTER',
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: () async {
              await DatabaseService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Profile/Dashboard Quick View (Teammate's CRUD context)
            _buildAdminProfileCard(),

            const SizedBox(height: 30),

            // 2. Recipe Management (Teammate Code)
            _buildAdminTile(
              context,
              title: "Recipe Management",
              subtitle: "Approve or reject pending recipes",
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPendingRecipes())),
            ),

            // 3. Video Management (Placeholder for later)
            _buildAdminTile(
              context,
              title: "Video Management",
              subtitle: "Manage cooking tutorials and shorts",
              icon: Icons.play_circle_fill,
              color: Colors.blueAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video Management Service coming soon!")));
              },
            ),

            // 4. Reported Users (Teammate Code)
            _buildAdminTile(
              context,
              title: "Reported Users",
              subtitle: "Review community reports and bans",
              icon: Icons.gavel_rounded,
              color: Colors.redAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportedUsers())),
            ),

            // 5. Feedback Management (Linked)
            _buildAdminTile(
              context,
              title: "Feedback Management",
              subtitle: "View and resolve user complaints",
              icon: Icons.feedback_rounded,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminFeedbackPage())
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5A5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.brown, child: Icon(Icons.shield, color: Colors.white)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("System Administrator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Main Dashboard (CRUD Ready)", style: TextStyle(fontSize: 13, color: Colors.brown)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}