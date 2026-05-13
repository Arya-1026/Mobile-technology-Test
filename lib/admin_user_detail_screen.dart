import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminUserDetailScreen({
    super.key,
    required this.uid,
    required this.userData,
  });

  Future<void> _approveOrganizer(BuildContext context) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'canCreateCompetition': true,
    });

    await FirebaseFirestore.instance
        .collection('organizerRequests')
        .doc(uid)
        .set({
          'uid': uid,
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? '',
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Тэмцээн зохиох эрх олголоо')));
  }

  Future<void> _removeOrganizer(BuildContext context) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'canCreateCompetition': false,
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Эрхийг цуцаллаа')));
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final photoUrl = userData['photoUrl'] ?? '';
    final canCreate = userData['canCreateCompetition'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Хэрэглэгчийн мэдээлэл'),
        backgroundColor: yellow,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(
                userData['name'] ?? 'Нэргүй',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${userData['email'] ?? ''}\n'
                'role: ${userData['role'] ?? 'viewer'}\n'
                'Тэмцээн үүсгэх эрх: ${canCreate ? 'Тийм' : 'Үгүй'}',
              ),
              isThreeLine: true,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveOrganizer(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Эрх олгох'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _removeOrganizer(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Эрх цуцлах'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Үүсгэсэн тэмцээнүүд',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('competitions')
                .where('ownerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Энэ хэрэглэгч тэмцээн үүсгээгүй байна'),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final item = CompetitionItem.fromDoc(doc);

                  return Card(
                    child: ListTile(
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Төлөв: ${item.status}\n'
                        'Төрөл: ${item.category}\n'
                        '${item.date}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
