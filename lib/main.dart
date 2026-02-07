import 'package:flutter/material.dart';
import 'package:fyp_project2/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password.dart';
import 'home_page.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'KitchenBuddy',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        // ⛔ No session → Login
        if (session == null) {
          return const LoginPage();
        }

        // 🔑 Password Recovery Session
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const ChangePasswordPage();
        }

        // ✅ Normal Login
        return const HomePage();
      },
    );
  }
}

