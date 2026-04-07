import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true; // 🔥 Removed 'final' so it can toggle

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🔥 DIRECT SUPABASE REGISTRATION
      await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          data: {
            'name': _nameCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'role': 'user', // Default role
          }
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              //app title
              Center(
                child: Column(
                  children: const [
                    Text('Kitchen', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFFB84C))),
                    Text('Buddy', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFFB84C))),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              //rounded container for form
              Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE59D),
                    borderRadius: BorderRadius.all(Radius.circular(60)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hello!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                        const Text('Nice to meet you here', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.brown)),
                        const SizedBox(height: 30),

                        // Full Name Field
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.orange, width: 10)),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 10),

                        //email field
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email is required';
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // phone Field
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Phone",
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.orange, width: 10)),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter your phone' : null,
                        ),
                        const SizedBox(height: 10),

                        // Password Field
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            // 🔥 Added suffix icon to toggle password visibility
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.orange, width: 10)),
                          ),
                          validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 10),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.orange, width: 10)),
                          ),
                          validator: (value) => (value != _passwordCtrl.text) ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 30),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA726),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                                child: const Text('Login', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}