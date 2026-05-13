import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Амжилтууд'), backgroundColor: yellow),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registrations')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final result = data['result'] ?? '';
            return result != 'Оролцсон' && result.toString().isNotEmpty;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text('Одоогоор бүртгэгдсэн амжилт байхгүй'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium, color: yellow),
                  title: Text(data['competitionTitle'] ?? ''),
                  subtitle: Text('Амжилт: ${data['result'] ?? ''}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
