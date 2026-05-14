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
      length: 4,
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Тэмцээн хүсэлт'),
              Tab(text: 'Бүх тэмцээн'),
              Tab(text: 'Зохион байгуулагч'),
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
            _CompetitionRequestsTab(onlyPending: true),
            _CompetitionRequestsTab(onlyPending: false),
            _OrganizerRequestsTab(),
            _UserListTab(),
          ],
        ),
      ),
    );
  }
}

// ── Competition approval tab ──────────────────────────────────────────────────

class _CompetitionRequestsTab extends StatelessWidget {
  final bool onlyPending;
  const _CompetitionRequestsTab({required this.onlyPending});

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
            return _CompetitionCard(item: item);
          },
        );
      },
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final CompetitionItem item;
  const _CompetitionCard({required this.item});

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _rejectWithReason(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Татгалзах шалтгаан',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Шалтгааныг оруулна уу...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болих'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Татгалзах'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await CompetitionService.changeStatus(
      item.id,
      'rejected',
      rejectionReason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6A00);
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + title header
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: item.displayImageUrl.isNotEmpty
                ? Image.network(
                    item.displayImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} · ${item.ownerEmail}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                if (item.status == 'rejected' &&
                    item.rejectionReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Шалтгаан: ${item.rejectionReason}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    if (item.status != 'approved')
                      Expanded(
                        child: _actionBtn(
                          label: 'Зөвшөөрөх',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          onTap: () => CompetitionService.changeStatus(
                              item.id, 'approved'),
                        ),
                      ),
                    if (item.status != 'approved') const SizedBox(width: 8),
                    if (item.status != 'rejected')
                      Expanded(
                        child: _actionBtn(
                          label: 'Татгалзах',
                          icon: Icons.cancel_outlined,
                          color: Colors.red,
                          onTap: () => _rejectWithReason(context),
                        ),
                      ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.edit_outlined,
                      color: orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompetitionFormScreen(
                              editItem: item, isAdmin: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _iconBtn(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () =>
                          CompetitionService.deleteCompetition(item.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Organizer requests tab ────────────────────────────────────────────────────

class _OrganizerRequestsTab extends StatelessWidget {
  const _OrganizerRequestsTab();

  Future<void> _rejectWithReason(
      BuildContext context, OrganizerRequest req) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Татгалзах шалтгаан',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Шалтгааныг оруулна уу...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болих'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Татгалзах'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await CompetitionService.updateOrganizerRequest(
      req.uid,
      'rejected',
      rejectionReason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrganizerRequest>>(
      stream: CompetitionService.allOrganizerRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return const Center(
            child: Text('Зохион байгуулагч болох хүсэлт байхгүй'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final req = requests[i];
            final statusColor = _statusColor(req.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFFF5C400).withValues(alpha: 0.2),
                          child: Text(
                            req.name.isNotEmpty
                                ? req.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF5C400),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                req.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            req.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (req.status == 'rejected' &&
                        req.rejectionReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Шалтгаан: ${req.rejectionReason}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.red),
                        ),
                      ),
                    if (req.status == 'pending') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _actionBtn(
                              label: 'Зөвшөөрөх',
                              color: Colors.green,
                              icon: Icons.check_circle_outline,
                              onTap: () =>
                                  CompetitionService.updateOrganizerRequest(
                                      req.uid, 'accepted'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _actionBtn(
                              label: 'Татгалзах',
                              color: Colors.red,
                              icon: Icons.cancel_outlined,
                              onTap: () =>
                                  _rejectWithReason(context, req),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (req.status == 'accepted') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: _actionBtn(
                          label: 'Эрхийг цуцлах',
                          color: Colors.red,
                          icon: Icons.remove_circle_outline,
                          onTap: () =>
                              CompetitionService.revokeOrganizerRole(
                                  req.uid),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User list tab ─────────────────────────────────────────────────────────────

class _UserListTab extends StatelessWidget {
  const _UserListTab();

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
            final canCreate = data['canCreateCompetition'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  backgroundColor:
                      const Color(0xFFF5C400).withValues(alpha: 0.2),
                  child: photoUrl.isEmpty
                      ? Text(
                          (data['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF5C400),
                          ),
                        )
                      : null,
                ),
                title: Text(
                  data['name'] ?? 'Нэргүй хэрэглэгч',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _chip(
                          label: data['role'] ?? 'viewer',
                          color: data['role'] == 'admin'
                              ? Colors.purple
                              : Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        if (canCreate)
                          _chip(
                            label: 'Зохион байгуулагч',
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
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

  Widget _chip({required String label, required Color color}) {
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
}
