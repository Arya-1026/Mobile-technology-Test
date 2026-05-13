import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оролцсон тэмцээнүүд'),
        backgroundColor: yellow,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Одоогоор тэмцээнд бүртгүүлээгүй байна'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.emoji_events_outlined,
                    color: yellow,
                  ),
                  title: Text(data['competitionTitle'] ?? ''),
                  subtitle: Text('Амжилт: ${data['result'] ?? 'Оролцсон'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
