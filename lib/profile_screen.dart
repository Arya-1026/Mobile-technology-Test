import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'login_screen.dart';
import 'competition_form_screen.dart';
import 'competition_detail_screen.dart';
import 'competition_service.dart';
import 'models.dart';

import 'change_password_screen.dart';
import 'my_registrations_screen.dart';
import 'achievements_screen.dart';
import 'my_requests_screen.dart';
import 'team_invites_screen.dart';
import 'team_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout().timeout(const Duration(seconds: 4));
    } finally {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType:
              field == 'phone' ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болих'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5C400),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      field: result,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title шинэчлэгдлээ'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D2D2D),
      ),
    );
  }

  Future<void> _sendOrganizerRequest(BuildContext context) async {
    try {
      await CompetitionService.sendOrganizerRequest();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Зохион байгуулагч болох хүсэлт илгээгдлээ!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF2D2D2D),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа гарлаа: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    const orange = Color(0xFFFF6A00);
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
            final photoUrl =
                data['photoUrl'] ?? firebaseUser.photoURL ?? '';
            final phone = data['phone'] ?? '';
            final registerNumber = data['registerNumber'] ?? '';
            final canCreate = data['canCreateCompetition'] ?? false;
            final activeRole = data['activeRole'] ?? 'participant';
            final isAdmin = data['role'] == 'admin';

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('organizerRequests')
                  .doc(firebaseUser.uid)
                  .snapshots(),
              builder: (context, reqSnap) {
                final reqData =
                    reqSnap.data?.data() as Map<String, dynamic>?;
                final reqStatus = reqData?['status'] as String?;
                final reqReason = reqData?['rejectionReason'] as String? ?? '';

                return Stack(
                  children: [
                    // Yellow header
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
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                      child: Column(
                        children: [
                          // Header row
                          Row(
                            children: [
                              const Icon(Icons.settings,
                                  color: Colors.white, size: 28),
                              const Spacer(),
                              if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Profile card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: _cardDecoration(),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor:
                                              Colors.grey.shade200,
                                          backgroundImage:
                                              photoUrl.isNotEmpty
                                                  ? NetworkImage(photoUrl)
                                                  : null,
                                          child: photoUrl.isEmpty
                                              ? const Icon(Icons.person,
                                                  size: 42,
                                                  color: Colors.grey)
                                              : null,
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: canCreate
                                                  ? Colors.green
                                                  : Colors.orange,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 2),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Role badge
                                          _roleBadge(
                                            activeRole: activeRole,
                                            canCreate: canCreate,
                                            isAdmin: isAdmin,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: yellow),
                                      onPressed: () => _updateUserField(
                                        context: context,
                                        uid: firebaseUser.uid,
                                        field: 'name',
                                        title: 'Нэр солих',
                                        oldValue: name,
                                      ),
                                    ),
                                  ],
                                ),

                                // Role switch (only if canCreate or admin)
                                if (canCreate && !isAdmin) ...[
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
                                  _roleSwitcher(
                                    context: context,
                                    uid: firebaseUser.uid,
                                    activeRole: activeRole,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Organizer request section (if not admin, not already organizer)
                          if (!isAdmin)
                            _organizerRequestCard(
                              context: context,
                              canCreate: canCreate,
                              reqStatus: reqStatus,
                              reqReason: reqReason,
                              activeRole: activeRole,
                              uid: firebaseUser.uid,
                              orange: orange,
                              yellow: yellow,
                            ),

                          const SizedBox(height: 14),

                          _registeredCompetitionsList(),

                          const SizedBox(height: 14),

                          // Menu items
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
                                  onTap: () => _updateUserField(
                                    context: context,
                                    uid: firebaseUser.uid,
                                    field: 'phone',
                                    title: 'Утасны дугаар солих',
                                    oldValue: phone,
                                  ),
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
                                  onTap: () => _updateUserField(
                                    context: context,
                                    uid: firebaseUser.uid,
                                    field: 'registerNumber',
                                    title: 'Регистрийн дугаар солих',
                                    oldValue: registerNumber,
                                  ),
                                ),
                                _menu(
                                  icon: Icons.lock_outline,
                                  title: 'Нууц үг солих',
                                  subtitle: '',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  ),
                                ),
                                _menu(
                                  icon: Icons.send_outlined,
                                  title: 'Оролцох хүсэлтүүд',
                                  subtitle: 'Тэмцээнд оролцох хүсэлтүүд',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyRequestsScreen(),
                                    ),
                                  ),
                                ),
                                _menu(
                                  icon: Icons.mark_email_unread_outlined,
                                  title: 'Team invites',
                                  subtitle: 'Багийн урилга, accept / reject',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TeamInvitesScreen(),
                                    ),
                                  ),
                                ),
                                _menu(
                                  icon: Icons.emoji_events_outlined,
                                  title: 'Оролцсон тэмцээнүүд',
                                  subtitle: '',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyRegistrationsScreen(),
                                    ),
                                  ),
                                ),
                                _menu(
                                  icon: Icons.workspace_premium_outlined,
                                  title: 'Амжилтууд',
                                  subtitle: '',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AchievementsScreen(),
                                    ),
                                  ),
                                ),
                                _menu(
                                  icon: Icons.delete_outline,
                                  title: 'Хэрэглэгчийн бүртгэл устгах',
                                  subtitle: '',
                                  iconColor: Colors.red,
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
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
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Устгах'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    final user =
                                        FirebaseAuth.instance.currentUser;
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

                          // My created competitions (only for organizers)
                          if (canCreate || isAdmin) ...[
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
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      decoration: _cardDecoration(),
                                      child: ListTile(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CompetitionDetailScreen(
                                              item: item,
                                            ),
                                          ),
                                        ),
                                        leading: _statusDot(item.status),
                                        title: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _statusChip(item.status),
                                            const SizedBox(height: 2),
                                            Text(item.date,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                            if (item.status == 'rejected' &&
                                                item.rejectionReason
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  'Шалтгаан: ${item.rejectionReason}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
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
                                              await CompetitionService
                                                  .deleteCompetition(item.id);
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
                          ],

                          const SizedBox(height: 18),

                          Container(
                            decoration: _cardDecoration(),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.logout, color: Colors.red),
                              title: const Text(
                                'Гарах',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () => _logout(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _roleBadge({
    required String activeRole,
    required bool canCreate,
    required bool isAdmin,
  }) {
    if (isAdmin) {
      return _badge('Админ', Colors.purple);
    }
    if (canCreate) {
      return _badge(
        activeRole == 'organizer' ? 'Зохион байгуулагч' : 'Оролцогч',
        activeRole == 'organizer' ? Colors.green : const Color(0xFFFF6A00),
      );
    }
    return _badge('Оролцогч', const Color(0xFFFF6A00));
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _roleSwitcher({
    required BuildContext context,
    required String uid,
    required String activeRole,
  }) {
    const yellow = Color(0xFFF5C400);
    final isOrganizer = activeRole == 'organizer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Идэвхтэй роль',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (activeRole != 'participant') {
                      await CompetitionService.switchActiveRole(
                          uid, 'participant');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isOrganizer ? yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Оролцогч',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: !isOrganizer ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (activeRole != 'organizer') {
                      await CompetitionService.switchActiveRole(
                          uid, 'organizer');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isOrganizer ? yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Зохион байгуулагч',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isOrganizer ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _organizerRequestCard({
    required BuildContext context,
    required bool canCreate,
    required String? reqStatus,
    required String reqReason,
    required String activeRole,
    required String uid,
    required Color orange,
    required Color yellow,
  }) {
    if (canCreate) return const SizedBox.shrink();

    if (reqStatus == null) {
      // No request yet
      return Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sports_score, color: orange, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Тэмцээн зохион байгуулагч болох',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Тэмцээн үүсгэхийн тулд эхлээд зохион байгуулагчийн эрх авах хүсэлт илгээнэ үү.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendOrganizerRequest(context),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Хүсэлт илгээх',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    if (reqStatus == 'pending') {
      return _requestStatusCard(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.orange,
        title: 'Хүсэлт хүлээгдэж байна',
        subtitle: 'Админ таны хүсэлтийг хянаж байна. Түр хүлээнэ үү.',
        bgColor: const Color(0xFFFFF8E7),
        borderColor: Colors.orange.withValues(alpha: 0.3),
      );
    }

    if (reqStatus == 'rejected') {
      return _requestStatusCard(
        icon: Icons.cancel_outlined,
        iconColor: Colors.red,
        title: 'Хүсэлт татгалзагдсан',
        subtitle: reqReason.isNotEmpty
            ? 'Шалтгаан: $reqReason'
            : 'Таны хүсэлт татгалзагдлаа.',
        bgColor: const Color(0xFFFFEEEE),
        borderColor: Colors.red.withValues(alpha: 0.3),
        trailing: TextButton(
          onPressed: () => _sendOrganizerRequest(context),
          child: const Text(
            'Дахин илгээх',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _requestStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _registeredCompetitionsList() {
    return StreamBuilder<List<RegisteredCompetition>>(
      stream: TeamService.myRegisteredCompetitions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final items = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Бүртгүүлсэн тэмцээнүүд',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Одоогоор бүртгүүлсэн тэмцээн байхгүй байна',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              else
                ...items.map((item) => _registeredCompetitionTile(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _registeredCompetitionTile(RegisteredCompetition item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.competitionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _miniChip(Icons.category_outlined, item.category),
              _miniChip(Icons.calendar_month_outlined, item.date),
              _miniChip(Icons.place_outlined, item.location),
              _miniChip(Icons.verified_outlined, item.registrationStatus),
              _miniChip(
                Icons.groups_2_outlined,
                item.teamName.isEmpty ? 'Ганцаарчилсан' : item.teamName,
              ),
            ],
          ),
          if (item.matchResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${item.resultStatus} · ${item.score} · ${item.matchResult}',
              style: TextStyle(
                color: item.resultStatus == 'Won' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  static BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _statusDot(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Нийтлэгдсэн';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Татгалзсан';
        break;
      default:
        color = Colors.orange;
        label = 'Хянагдаж байна';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    const yellow = Color(0xFFF5C400);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: iconColor ?? yellow),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle, style: const TextStyle(fontSize: 12))
              : null,
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
