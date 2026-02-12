import 'package:flutter/material.dart';
import '../../services/database_service.dart';

void showForgotPasswordDialog(BuildContext context) {
  final resetEmailCtrl = TextEditingController();
  final dbService = DatabaseService();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your email to receive a reset link.'),
          const SizedBox(height: 10),
          TextField(
            controller: resetEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final email = resetEmailCtrl.text.trim();
            if (email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your email')),
              );
              return;
            }

            Navigator.pop(context); // Close dialog

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sending reset link...')),
            );

            try {
              await dbService.resetPassword(email);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Check your email for a password reset link'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}