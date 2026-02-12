import 'package:flutter/material.dart';
import '../recipe/upload_selection_screen.dart';
import 'home_page.dart';
import '../profile/profile_page.dart';
import '../user_message_page.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});
  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  // This is the source of truth for your screens
  final List<Widget> _pages = [
    const HomePage(),             // Index 0
    const Center(child: Text("Calorie Calculator")), // Index 1
    const SizedBox(),              // Index 2 (Spacer for FAB)
    const UserMessagePage(),      // Index 3 (The actual Notification UI)
    const ProfilePage(),          // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadSelectionScreen()));
        },
        child: const Icon(Icons.add_circle, size: 55, color: Colors.orange),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, Icons.home, "Home"),
            _navItem(1, Icons.local_fire_department_outlined, Icons.local_fire_department, "Calorie"),
            const SizedBox(width: 40),
            _navItem(3, Icons.message_outlined, Icons.message, "Messages"),
            _navItem(4, Icons.person_outline, Icons.person, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        debugPrint("Current Index Changed to: $_currentIndex"); // This helps you see if it's working
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? Colors.orange : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.orange : Colors.grey)),
        ],
      ),
    );
  }
}