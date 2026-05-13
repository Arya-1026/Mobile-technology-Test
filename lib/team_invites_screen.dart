import 'package:flutter/material.dart';

import 'models.dart';
import 'team_service.dart';

class TeamInvitesScreen extends StatelessWidget {
  const TeamInvitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Team invites'),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<TeamInvite>>(
        stream: TeamService.myInvites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final invites = snapshot.data!;
          if (invites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      size: 62, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Одоогоор invite байхгүй байна',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _InviteCard(invite: invites[index]),
          );
        },
      ),
    );
  }
}

class _InviteCard extends StatefulWidget {
  final TeamInvite invite;

  const _InviteCard({required this.invite});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool loading = false;

  Future<void> _respond(bool accepted) async {
    setState(() => loading = true);
    try {
      await TeamService.respondInvite(widget.invite, accepted);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Invite accepted' : 'Invite rejected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_2_outlined,
                    color: Color(0xFFFF6A00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.teamName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(
                      invite.competitionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _meta(Icons.person_outline, 'Leader', invite.leaderName),
          _meta(Icons.category_outlined, 'Sport', invite.sportCategory),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : () => _respond(false),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: loading ? null : () => _respond(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C400),
                    foregroundColor: Colors.black,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
