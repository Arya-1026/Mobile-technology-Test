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
      body: StreamBuilder<List<TeamNotification>>(
        stream: TeamService.myNotifications(),
        builder: (context, notificationSnap) {
          if (notificationSnap.hasError) {
            return _ErrorState(error: notificationSnap.error.toString());
          }
          if (!notificationSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = notificationSnap.data!
              .where((item) => item.type == 'team_invite')
              .toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          return StreamBuilder<List<TeamInvite>>(
            stream: TeamService.myInvites(),
            builder: (context, inviteSnap) {
              if (inviteSnap.hasError) {
                return _ErrorState(error: inviteSnap.error.toString());
              }
              if (!inviteSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allInvites = inviteSnap.data!;
              final pendingInvites = allInvites
                  .where((invite) => invite.status.toLowerCase() == 'pending')
                  .toList();
              final historyInvites = allInvites
                  .where((invite) => invite.status.toLowerCase() != 'pending')
                  .toList();

              if (notifications.isEmpty && allInvites.isEmpty) {
                return const _EmptyState();
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (notifications.isNotEmpty) ...[
                    const _SectionTitle('Notifications'),
                    const SizedBox(height: 10),
                    ...notifications.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NotificationCard(
                          notification: item,
                          matchingInvite: _findMatchingInvite(
                            item,
                            pendingInvites,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const _SectionTitle('Pending invites'),
                  const SizedBox(height: 10),
                  if (pendingInvites.isEmpty)
                    const _NoPendingInviteCard()
                  else
                    ...pendingInvites.map(
                      (invite) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InviteCard(invite: invite),
                      ),
                    ),
                  if (historyInvites.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionTitle('Invite history'),
                    const SizedBox(height: 10),
                    ...historyInvites.map(
                      (invite) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InviteCard(invite: invite),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

TeamInvite? _findMatchingInvite(
  TeamNotification notification,
  List<TeamInvite> pendingInvites,
) {
  for (final invite in pendingInvites) {
    if (notification.body.contains(invite.teamName) ||
        notification.body.contains(invite.competitionTitle)) {
      return invite;
    }
  }
  return pendingInvites.length == 1 ? pendingInvites.first : null;
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_unread_outlined,
              size: 62, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Odoogoor invite baihgui baina',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPendingInviteCard extends StatefulWidget {
  const _NoPendingInviteCard();

  @override
  State<_NoPendingInviteCard> createState() => _NoPendingInviteCardState();
}

class _NoPendingInviteCardState extends State<_NoPendingInviteCard> {
  bool loading = false;

  Future<void> _sync() async {
    setState(() => loading = true);
    try {
      await TeamService.syncMyEmailInvites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite-uudiig dahin shalgalaa'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aldaa: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Accept hiih pending invite alga baina. Email invite say irsen bol dahin shalgana uu.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: loading ? null : _sync,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Check'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(color: const Color(0xFFFFEEEE)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Invite unshihad aldaa garlaa',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final TeamNotification notification;
  final TeamInvite? matchingInvite;

  const _NotificationCard({
    required this.notification,
    required this.matchingInvite,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool loading = false;
  bool responding = false;

  Future<void> _markRead() async {
    setState(() => loading = true);
    try {
      await TeamService.markNotificationRead(widget.notification.id);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _respond(bool accepted) async {
    final invite = widget.matchingInvite;
    if (invite == null) return;
    setState(() => responding = true);
    try {
      await TeamService.respondInvite(invite, accepted);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? 'Invite accepted' : 'Invite rejected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aldaa: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.notification;
    final hasAction = widget.matchingInvite != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        color: item.read ? Colors.white : const Color(0xFFFFF8E1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5C400).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFFF6A00),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasAction) ...[
                ElevatedButton(
                  onPressed: responding ? null : () => _respond(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C400),
                    foregroundColor: Colors.black,
                  ),
                  child: responding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept'),
                ),
                TextButton(
                  onPressed: responding ? null : () => _respond(false),
                  child: const Text('Reject'),
                ),
              ],
              if (!item.read)
                TextButton(
                  onPressed: loading ? null : _markRead,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Read'),
                ),
            ],
          ),
        ],
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
        SnackBar(
          content: Text('Aldaa: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final isPending = invite.status.toLowerCase() == 'pending';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
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
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
          _meta(Icons.alternate_email_rounded, 'Email', invite.toEmail),
          _meta(Icons.info_outline, 'Status', invite.status),
          if (isPending) ...[
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

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.055),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
