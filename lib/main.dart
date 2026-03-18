import 'package:flutter/material.dart';
import 'package:fyp_project2/screens/auth/login.dart';
import 'package:fyp_project2/screens/auth/reset_password.dart';
import 'package:fyp_project2/screens/profile/profile_page.dart';
import 'package:fyp_project2/screens/recipe/upload_selection_screen.dart';
import 'package:fyp_project2/screens/user_message_page.dart';
import 'package:fyp_project2/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_calorie_scan/calorie_estimate_page.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/home/home_page.dart';
import 'dart:async';

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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

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

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});
  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CalorieEstimationPage(),
    const SizedBox(),
    const UserMessagePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Check if the keyboard is visible
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // 2. This ensures the body adjusts when keyboard appears
      resizeToAvoidBottomInset: true,

      body: IndexedStack(index: _currentIndex, children: _pages),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 3. Only show the FAB if the keyboard is NOT visible
      floatingActionButton: isKeyboardVisible
          ? null
          : FloatingActionButton(
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
        // 4. Hide the bottom bar too if keyboard is visible for a cleaner look
        child: isKeyboardVisible
            ? const SizedBox.shrink()
            : Row(
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