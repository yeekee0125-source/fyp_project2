import 'package:flutter/material.dart';
import 'package:fyp_project2/screens/auth/login.dart';
import 'package:fyp_project2/screens/profile/profile_page.dart';
import 'package:fyp_project2/screens/recipe/upload_selection_screen.dart';
import 'package:fyp_project2/screens/user_message_page.dart';
import 'package:fyp_project2/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/home/home_page.dart';

// Keys for navigation and snackbars
final navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

const String url = 'https://ivmmxdmqzkzkkencnhue.supabase.co';
const String key = 'sb_publishable_ipmlvwO4J3IXnT18CUR4Jw_C-XDEq4Y';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: url,
      anonKey: key,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      )
  );

  runApp(const KitchenBuddyApp());
}

class KitchenBuddyApp extends StatelessWidget {
  const KitchenBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF3C2),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decision maker: Shows Login, Admin Dashboard, or User Home
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return const LoginPage();

    return FutureBuilder<bool>(
      future: DatabaseService().isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return (snapshot.data == true)
            ? const AdminDashboard()
            : const MainNavigationContainer();
      },
    );
  }
}

/// The Main Shell for the User App
class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});
  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  // These widgets align with the indices 0, 1, 2, 3, 4
  final List<Widget> _pages = [
    const HomePage(),                              // Index 0
    const Center(child: Text("Calorie Calculator")),  // Index 1
    const SizedBox(),                               // Index 2 (Empty for FAB)
    const UserMessagePage(),                       // Index 3 (Functional Message Page)
    const ProfilePage(),                           // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // preserves state of pages (e.g. scroll position in messages)
      body: IndexedStack(index: _currentIndex, children: _pages),

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

            const SizedBox(width: 40), // Space for FAB

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
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.orange : Colors.grey
          ),
          Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.orange : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )
          ),
        ],
      ),
    );
  }
}