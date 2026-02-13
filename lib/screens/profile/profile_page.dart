// import 'package:flutter/material.dart';
// import '../../services/database_service.dart';
// import '../auth/login.dart';
//
// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   final db = DatabaseService();
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }
//
//   void _loadProfile() async {
//     try {
//       final data = await db.getCurrentUserProfile();
//
//       if (data != null) {
//         _nameCtrl.text = data['name'] ?? '';
//         _phoneCtrl.text = data['phone'] ?? '';
//       }
//     } catch (e) {
//       debugPrint('Profile load error: $e');
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load profile')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//
//   void _updateProfile() async {
//     setState(() => _isLoading = true);
//     await db.updateProfile(_nameCtrl.text, _phoneCtrl.text);
//     setState(() => _isLoading = false);
//     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
//   }
//
//   void _logout() async {
//     await db.logout();
//     if(mounted) {
//       Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const LoginPage()),
//               (route) => false
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF3C2),
//       appBar: AppBar(
//         title: const Text("My Profile", style: TextStyle(color: Colors.black)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const CircleAvatar(radius: 50, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 50, color: Colors.white)),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _nameCtrl,
//               decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _phoneCtrl,
//               decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _updateProfile,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
//                 child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
//               ),
//             ),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               child: TextButton.icon(
//                 onPressed: _logout,
//                 icon: const Icon(Icons.logout, color: Colors.red),
//                 label: const Text("Logout", style: TextStyle(color: Colors.red)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../auth/login.dart';
import '../recipe/recipe_list.dart';
import '../video/my_video_page.dart';
import 'feedback_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = DatabaseService();
  String _name = "Loading...";
  String _phone = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final data = await db.getCurrentUserProfile();
      if (data != null && mounted) {
        setState(() {
          _name = data['name'] ?? 'User Name';
          _phone = data['phone'] ?? 'No phone added';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFFFFF3C2), // Matching the beige background
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),

              // Full Name Input
              _buildDialogTextField(nameCtrl, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),

              // Phone Number Input
              _buildDialogTextField(phoneCtrl, "Phone Number", Icons.phone_android_outlined),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.brown)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await db.updateProfile(nameCtrl.text, phoneCtrl.text);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadProfile(); // Refresh the data
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile Updated!'))
                          );
                        }
                      },
                      child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the dialog text fields
  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.brown),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C2),
      appBar: AppBar(
        title: const Text("User Account", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          children: [
            // 1. Profile Avatar & Info
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(_name,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            Text(_phone, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // 2. Manage My Video Tutorials
            _buildMenuButton(
              icon: Icons.play_circle_outline,
              title: "Manage My Video Tutorials",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyVideosPage())
                );
              },
            ),

            // 3. Insights
            _buildMenuButton(
              icon: Icons.bar_chart_rounded,
              title: "Insights",
              color: Colors.brown,
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsPage()));
              },
            ),

            // 4. Feedback
            _buildMenuButton(
              icon: Icons.chat_bubble_outline_rounded,
              title: "Give a Feedback",
              color: Colors.orangeAccent,
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const UserFeedbackPage()));
              },
            ),

            // 5. Manage My Recipes
            _buildMenuButton(
              icon: Icons.restaurant_menu,
              title: "Manage My Recipes",
              color: Colors.green,
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeListPage()));
              },
            ),

            // 6. Edit Profile Details (CRUD)
            _buildMenuButton(
              icon: Icons.edit_note,
              title: "Edit Profile Details",
              color: Colors.blue,
              onTap: _showEditProfileDialog,
            ),

            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await db.logout();
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.brown)),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}