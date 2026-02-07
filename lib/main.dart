import 'package:flutter/material.dart';
import 'package:fyp_project2/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart';
import 'database_service.dart';
import 'reset_password.dart';
import 'home_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

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

class KitchenBuddyApp extends StatefulWidget {
  const KitchenBuddyApp({super.key});

  @override
  State<KitchenBuddyApp> createState() => _KitchenBuddyAppState();
}


class _KitchenBuddyAppState extends State<KitchenBuddyApp> {

  @override
  void initState() {
    super.initState();
    // 2. Listen for Password Recovery Global Event
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        // 3. Force navigation to ChangePasswordPage immediately
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in for initial screen
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: navigatorKey, // 4. Attach the key here!
      debugShowCheckedModeBanner: false,
      title: 'KitchenBuddy',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF3C2),
      ),
      // If logged in go to Home, else Login
      home: session != null ? const HomePage() : const LoginPage(),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitchenBuddy',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return FutureBuilder<bool>(
      future: db.isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!
            ? const AdminDashboard()
            : const HomePage();
      },
    );
  }
}


