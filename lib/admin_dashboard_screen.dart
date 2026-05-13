import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'competition_form_screen.dart';
import 'competition_service.dart';
import 'login_screen.dart';
import 'models.dart';
import 'admin_user_detail_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final bool showAppBarLogout;

  const AdminDashboardScreen({super.key, this.showAppBarLogout = true});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    const orange = Color(0xFFFF6A00);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (showAppBarLogout)
              IconButton(
                tooltip: 'Гарах',
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded),
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Хүсэлтүүд'),
              Tab(text: 'Бүх тэмцээн'),
              Tab(text: 'Хэрэглэгчид'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompetitionFormScreen(isAdmin: true),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Тэмцээн нэмэх',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const TabBarView(
          children: [
            AdminCompetitionList(onlyPending: true),
            AdminCompetitionList(onlyPending: false),
            UserListTab(),
          ],
        ),
      ),
    );
  }
}

class AdminCompetitionList extends StatelessWidget {
  final bool onlyPending;

  const AdminCompetitionList({super.key, required this.onlyPending});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CompetitionItem>>(
      stream: CompetitionService.allCompetitions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data!;

        if (onlyPending) {
          items = items.where((e) => e.status == 'pending').toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Text(
              onlyPending ? 'Шинэ хүсэлт байхгүй байна' : 'Тэмцээн байхгүй',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl.isEmpty
                      ? Container(
                          width: 58,
                          height: 58,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image),
                        )
                      : Image.network(
                          item.imageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Төрөл: ${item.category}\n'
                  'Төлөв: ${item.status}\n'
                  'Илгээсэн: ${item.ownerEmail}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'approve') {
                      await CompetitionService.changeStatus(
                        item.id,
                        'approved',
                      );
                    }

                    if (value == 'reject') {
                      await CompetitionService.changeStatus(
                        item.id,
                        'rejected',
                      );
                    }

                    if (value == 'edit') {
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompetitionFormScreen(
                            editItem: item,
                            isAdmin: true,
                          ),
                        ),
                      );
                    }

                    if (value == 'delete') {
                      await CompetitionService.deleteCompetition(item.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'approve', child: Text('Зөвшөөрөх')),
                    PopupMenuItem(value: 'reject', child: Text('Татгалзах')),
                    PopupMenuItem(value: 'edit', child: Text('Засах')),
                    PopupMenuItem(value: 'delete', child: Text('Устгах')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserListTab extends StatelessWidget {
  const UserListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('Хэрэглэгч байхгүй'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final photoUrl = data['photoUrl'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person_outline)
                      : null,
                ),
                title: Text(
                  data['name'] ?? 'Нэргүй хэрэглэгч',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${data['email'] ?? ''}\n'
                  'role: ${data['role'] ?? 'viewer'}\n'
                  'Тэмцээн үүсгэх эрх: ${(data['canCreateCompetition'] ?? false) ? 'Тийм' : 'Үгүй'}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailScreen(
                        uid: users[index].id,
                        userData: data,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
