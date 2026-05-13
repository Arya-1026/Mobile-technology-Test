import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'competition_form_screen.dart';
import 'competition_service.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _sendRequest(BuildContext context) async {
    try {
      await CompetitionService.sendOrganizerRequest();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Зохион байгуулагч болох хүсэлт илгээгдлээ!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        title: const Text(
          'Зохион байгуулагч болох',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};
          final canCreate = userData['canCreateCompetition'] ?? false;

          if (canCreate) {
            return _GrantedView(uid: uid);
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('organizerRequests')
                .doc(uid)
                .snapshots(),
            builder: (context, reqSnap) {
              final reqData =
                  reqSnap.data?.data() as Map<String, dynamic>?;
              final status = reqData?['status'] as String?;
              final reason =
                  reqData?['rejectionReason'] as String? ?? '';

              if (status == 'pending') {
                return _PendingView();
              }

              if (status == 'rejected') {
                return _RejectedView(
                  reason: reason,
                  onRetry: () => _sendRequest(context),
                );
              }

              // No request or no status
              return _NoRequestView(
                onSend: () => _sendRequest(context),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Sub-views ─────────────────────────────────────────────────────────────────

class _GrantedView extends StatelessWidget {
  final String uid;
  const _GrantedView({required this.uid});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Та тэмцээн зохион байгуулагч байна!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Профайл хэсгээс "Зохион байгуулагч" горимд шилжиж тэмцээн үүсгэх боломжтой.',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompetitionFormScreen()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Тэмцээн нэмэх',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingView extends StatelessWidget {
  const _PendingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Colors.orange, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Хүсэлт хянагдаж байна',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Таны зохион байгуулагч болох хүсэлтийг админ хянаж байна. Зөвшөөрөгдсөний дараа мэдэгдэнэ.',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedView extends StatelessWidget {
  final String reason;
  final VoidCallback onRetry;
  const _RejectedView({required this.reason, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: Colors.red, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Хүсэлт татгалзагдлаа',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Шалтгаан: $reason',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.red, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Дахин хүсэлт илгээх',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRequestView extends StatelessWidget {
  final VoidCallback onSend;
  const _NoRequestView({required this.onSend});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF6A00);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_score_rounded,
                color: orange, size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'Тэмцээн зохион байгуулагч болох',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Тэмцээн үүсгэхийн тулд эхлээд зохион байгуулагчийн эрх авах хүсэлт илгээнэ үү. Админ таны хүсэлтийг хянаж зөвшөөрснөөр тэмцээн нэмэх боломжтой болно.',
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade600, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Steps
          _step('1', 'Хүсэлт илгээх',
              'Доорх товчийг дарж хүсэлт илгээнэ үү'),
          _step('2', 'Хянуулах',
              'Админ таны мэдээллийг шалгана'),
          _step('3', 'Тэмцээн нэмэх',
              'Зөвшөөрөгдсөний дараа тэмцээн үүсгэх боломжтой'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'Хүсэлт илгээх',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5C400),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
