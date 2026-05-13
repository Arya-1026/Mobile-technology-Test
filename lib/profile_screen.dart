import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'login_screen.dart';
import 'competition_form_screen.dart';
import 'competition_service.dart';
import 'models.dart';

import 'change_password_screen.dart';
import 'devices_screen.dart';
import 'my_registrations_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _updateUserField({
    required BuildContext context,
    required String uid,
    required String field,
    required String title,
    required String oldValue,
  }) async {
    final controller = TextEditingController(text: oldValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: field == 'phone'
                ? TextInputType.phone
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: title,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Хадгалах'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: result,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title шинэчлэгдлээ')));
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(body: Center(child: Text('Нэвтрээгүй байна')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() ?? {};

            final name =
                data['name'] ?? firebaseUser.displayName ?? 'Хэрэглэгч';
            final email = data['email'] ?? firebaseUser.email ?? '';
            final photoUrl = data['photoUrl'] ?? firebaseUser.photoURL ?? '';
            final phone = data['phone'] ?? '';
            final registerNumber = data['registerNumber'] ?? '';
            final canCreate = data['canCreateCompetition'] ?? false;

            return Stack(
              children: [
                Container(
                  height: 165,
                  decoration: const BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(34),
                      bottomRight: Radius.circular(34),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.white, size: 30),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    email,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    canCreate
                                        ? 'Тэмцээн үүсгэх эрхтэй'
                                        : 'Viewer хэрэглэгч',
                                    style: TextStyle(
                                      color: canCreate
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: yellow),
                              onPressed: () {
                                _updateUserField(
                                  context: context,
                                  uid: firebaseUser.uid,
                                  field: 'name',
                                  title: 'Нэр солих',
                                  oldValue: name,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () {
                          if (!canCreate) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Тэмцээн нэмэхийн тулд эхлээд Эрх хэсгээс хүсэлт илгээнэ үү',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CompetitionFormScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: yellow,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: yellow.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add_box_rounded, color: Colors.white),
                              SizedBox(width: 14),
                              Text(
                                'Тэмцээн нэмэх',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            _menu(
                              icon: Icons.phone_outlined,
                              title: 'Утасны дугаар',
                              subtitle: phone.isEmpty
                                  ? 'Баталгаажаагүй'
                                  : phone,
                              onTap: () {
                                _updateUserField(
                                  context: context,
                                  uid: firebaseUser.uid,
                                  field: 'phone',
                                  title: 'Утасны дугаар солих',
                                  oldValue: phone,
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.email_outlined,
                              title: 'И-Мэйл',
                              subtitle: email,
                              onTap: () {},
                            ),
                            _menu(
                              icon: Icons.app_registration_outlined,
                              title: 'Регистрийн дугаар',
                              subtitle: registerNumber.isEmpty
                                  ? 'Оруулаагүй'
                                  : registerNumber,
                              onTap: () {
                                _updateUserField(
                                  context: context,
                                  uid: firebaseUser.uid,
                                  field: 'registerNumber',
                                  title: 'Регистрийн дугаар солих',
                                  oldValue: registerNumber,
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.lock_outline,
                              title: 'Нууц үг солих',
                              subtitle: '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChangePasswordScreen(),
                                  ),
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.devices_outlined,
                              title: 'Төхөөрөмжийн жагсаалт',
                              subtitle: '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DevicesScreen(),
                                  ),
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.emoji_events_outlined,
                              title: 'Оролцсон тэмцээнүүд',
                              subtitle: '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MyRegistrationsScreen(),
                                  ),
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.workspace_premium_outlined,
                              title: 'Амжилтууд',
                              subtitle: '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AchievementsScreen(),
                                  ),
                                );
                              },
                            ),
                            _menu(
                              icon: Icons.delete_outline,
                              title: 'Хэрэглэгчийн бүртгэл устгах',
                              subtitle: '',
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Бүртгэл устгах'),
                                    content: const Text(
                                      'Та бүртгэлээ устгахдаа итгэлтэй байна уу?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Болих'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Устгах'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .delete();
                                await user.delete();

                                if (!context.mounted) return;

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Миний зохион байгуулсан тэмцээнүүд',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      StreamBuilder<List<CompetitionItem>>(
                        stream: CompetitionService.myCompetitions(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final items = snapshot.data!;

                          if (items.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: _cardDecoration(),
                              child: const Text(
                                'Одоогоор тэмцээн нэмээгүй байна',
                              ),
                            );
                          }

                          return Column(
                            children: items.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: _cardDecoration(),
                                child: ListTile(
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Төлөв: ${item.status}\n${item.date}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CompetitionFormScreen(
                                                  editItem: item,
                                                ),
                                          ),
                                        );
                                      }

                                      if (value == 'delete') {
                                        await CompetitionService.deleteCompetition(
                                          item.id,
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Засах'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Устгах'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        decoration: _cardDecoration(),
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Гарах',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _logout(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const yellow = Color(0xFFF5C400);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: yellow),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle, style: const TextStyle(fontSize: 12))
              : null,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: yellow,
            size: 16,
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
