import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/interaction_service.dart';
import '../auth/login.dart';
import '../recipe/recipe_list.dart';
import '../video/my_video_page.dart';
import 'feedback_page.dart';
import 'insight_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = DatabaseService();
  final _interactionService = InteractionService();
  final supabase = Supabase.instance.client;
  String _name = "Loading...";
  String _phone = "";
  String? _profileImageUrl;

  bool _isLoading = true;
  bool _isUploadingImage = false;

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
          _profileImageUrl = data['profile_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return; // User canceled

    setState(() => _isUploadingImage = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Upload to Supabase Storage bucket named 'avatars'
      await supabase.storage.from('avatars').upload(fileName, file);

      // 2. Get the public URL of the uploaded image
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // 3. Save the URL to the 'users' table in the database
      await supabase.from('users').update({'profile_image_url': imageUrl}).eq('id', userId);

      // 4. Update the UI
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBE6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Estimation History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8D7A66))),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('calorie_scans')
                    .select()
                    .eq('user_id', supabase.auth.currentUser?.id ?? '')
                    .order('scanned_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Database Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No history found."),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];

                      DateTime date = DateTime.parse(item['scanned_at']);
                      String formattedDate = DateFormat('MMM dd, yyyy • h:mm a').format(date);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item['image_url'] != null
                                ? Image.network(
                              item['image_url'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: Colors.orange),
                            )
                                : const Icon(Icons.description_outlined, color: Colors.grey),
                          ),
                          title: Text(item['detected_dish'] ?? "Unknown",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${item['portion_size'] ?? "Medium"} • $formattedDate"),
                          trailing: Text("${item['estimated_calorie']} kcal",
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFFFFF3C2),
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

              _buildDialogTextField(nameCtrl, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),

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
                          _loadProfile();
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
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // The main avatar
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.orange.withOpacity(0.3),
                  backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, size: 55, color: Colors.orange)
                      : null,
                ),

                // The loading spinner or camera icon overlay
                if (_isUploadingImage)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                else
                  GestureDetector(
                    onTap: _pickAndUploadImage, // Triggers the gallery
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            Text(_phone, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _buildFollowerStats(),
            const SizedBox(height: 30),

            _buildMenuButton(
              icon: Icons.history,
              title: "My Estimation History",
              color: Colors.purple,
              onTap: _showHistoryBottomSheet,
            ),

            _buildMenuButton(
              icon: Icons.play_circle_outline,
              title: "Manage My Video Tutorials",
              color: Colors.orange,
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVideosPage())); },
            ),

            _buildMenuButton(
              icon: Icons.bar_chart_rounded,
              title: "Insights",
              color: Colors.brown,
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => UserInsightsPage(userName: _name))); },
            ),

            _buildMenuButton(
              icon: Icons.chat_bubble_outline_rounded,
              title: "Give a Feedback",
              color: Colors.orangeAccent,
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const UserFeedbackPage())); },
            ),

            _buildMenuButton(
              icon: Icons.restaurant_menu,
              title: "Manage My Recipes",
              color: Colors.green,
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeListPage())); },
            ),

            _buildMenuButton(
              icon: Icons.edit_note,
              title: "Edit Profile Details",
              color: Colors.blue,
              onTap: _showEditProfileDialog,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await db.logout();
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerStats() {
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    return StreamBuilder<int>(
      stream: _interactionService.getFollowerCountStream(currentUserId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_outlined, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                "$count",
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "Followers",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.brown.withOpacity(0.7)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStat(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.brown.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuButton({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}