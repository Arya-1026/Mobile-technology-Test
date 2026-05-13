import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Төхөөрөмжийн жагсаалт'),
        backgroundColor: yellow,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android, color: yellow),
              title: const Text('Одоогийн төхөөрөмж'),
              subtitle: Text(user?.email ?? ''),
              trailing: const Icon(Icons.verified, color: Colors.green),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Firebase Auth default байдлаар төхөөрөмж бүрийн дэлгэрэнгүй жагсаалтыг хадгалдаггүй. Хэрэв хүсвэл дараа нь login history collection үүсгэж болно.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
