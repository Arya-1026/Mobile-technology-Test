import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'competition_form_screen.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestPermission(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('organizerRequests')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Эрх авах хүсэлт админ руу илгээгдлээ')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Нэвтрээгүй байна')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Тэмцээн зохиох эрх'),
        backgroundColor: yellow,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final canCreate = data?['canCreateCompetition'] ?? false;

          if (canCreate) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Та тэмцээн үүсгэх эрхтэй байна',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CompetitionFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Тэмцээн нэмэх'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: yellow, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Тэмцээн үүсгэхийн тулд админаас эрх авах шаардлагатай',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _requestPermission(context),
                      child: const Text('Эрх авах хүсэлт илгээх'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
