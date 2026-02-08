import 'package:flutter/material.dart';
import 'database_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = DatabaseService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final data = await db.getCurrentUserProfile();

      if (data != null) {
        _nameCtrl.text = data['name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
      }
    } catch (e) {
      debugPrint('Profile load error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _updateProfile() async {
    setState(() => _isLoading = true);
    await db.updateProfile(_nameCtrl.text, _phoneCtrl.text);
    setState(() => _isLoading = false);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
  }

  void _logout() async {
    await db.logout();
    if(mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C2),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 30),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}