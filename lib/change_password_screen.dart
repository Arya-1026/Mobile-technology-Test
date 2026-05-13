import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool loading = false;

  Future<void> sendResetEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.isEmpty) return;

    setState(() => loading = true);

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!mounted) return;
    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$email рүү нууц үг солих имэйл илгээгдлээ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Нууц үг солих'),
        backgroundColor: yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 90, color: yellow),
            const SizedBox(height: 20),
            const Text(
              'Нууц үгээ солихын тулд таны и-мэйл рүү reset link илгээнэ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.white,
                ),
                child: Text(loading ? 'Илгээж байна...' : 'Reset имэйл илгээх'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
