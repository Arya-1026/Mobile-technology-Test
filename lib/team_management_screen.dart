import 'package:flutter/material.dart';

import 'models.dart';
import 'team_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final CompetitionItem competition;

  const TeamManagementScreen({super.key, required this.competition});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (nameController.text.trim().isEmpty) {
      _snack('Багийн нэр оруулна уу');
      return;
    }

    setState(() => saving = true);
    try {
      await TeamService.createTeam(
        competition: widget.competition,
        name: nameController.text,
        description: descriptionController.text,
        logoUrl: '',
      );
      if (!mounted) return;
      nameController.clear();
      descriptionController.clear();
      _snack('Баг амжилттай үүслээ. Одоо гишүүдээ invite хийнэ үү.');
    } catch (e) {
      if (!mounted) return;
      _snack('Алдаа: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Багийн бүртгэл'),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<CompetitionTeam>>(
        stream: TeamService.myLeaderTeamsForCompetition(widget.competition.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final myTeams = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _competitionHeader(),
              const SizedBox(height: 14),
              if (myTeams.isNotEmpty) ...[
                const Text(
                  'Таны үүсгэсэн баг',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...myTeams.map((team) => _MyTeamCard(team: team)),
                const SizedBox(height: 16),
              ] else ...[
                _createTeamCard(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _competitionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Color(0xFFFF6A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.competition.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.competition.category} • ${widget.competition.maxTeamMembers} гишүүн хүртэл',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createTeamCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Шинэ баг үүсгэх',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _field(nameController, 'Багийн нэр', Icons.groups_outlined),
          _field(
            descriptionController,
            'Багийн тайлбар',
            Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Баг үүссэний дараа энэ хуудсан дээрээс шууд гишүүдээ email, нэр эсвэл username-ээр хайж invite илгээнэ.',
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _createTeam,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                saving ? 'Үүсгэж байна...' : 'Баг үүсгэх',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C400),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}

class _MyTeamCard extends StatelessWidget {
  final CompetitionTeam team;

  const _MyTeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _teamIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${team.members.length}/${team.maxMembers} гишүүн • Ахлагч: ${team.leaderName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (team.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              team.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: team.members
                .map(
                  (member) => Chip(
                    avatar: _memberAvatar(member),
                    label: Text('${member.name} - ${member.position}'),
                    deleteIcon: member.uid != team.leaderId
                        ? const Icon(Icons.person_remove_outlined, size: 18)
                        : null,
                    onDeleted: member.uid != team.leaderId
                        ? () => _confirmRemove(context, member)
                        : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          _InvitePanel(team: team),
        ],
      ),
    );
  }

  Widget _teamIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.groups_2_outlined, color: Color(0xFFFF6A00)),
    );
  }

  Widget _memberAvatar(TeamMember member) {
    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      backgroundImage:
          member.photoUrl.isNotEmpty ? NetworkImage(member.photoUrl) : null,
      child: member.photoUrl.isEmpty
          ? Text(
              member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            )
          : null,
    );
  }

  Future<void> _confirmRemove(BuildContext context, TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('${member.name} гишүүнийг багаас хасах уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await TeamService.removeMember(team, member.uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Гишүүн багаас хасагдлаа'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _InvitePanel extends StatefulWidget {
  final CompetitionTeam team;

  const _InvitePanel({required this.team});

  @override
  State<_InvitePanel> createState() => _InvitePanelState();
}

class _InvitePanelState extends State<_InvitePanel> {
  final emailController = TextEditingController();
  final searchController = TextEditingController();
  List<AppUser> results = [];
  bool sendingEmail = false;
  bool searching = false;

  @override
  void dispose() {
    emailController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailInvite() async {
    if (emailController.text.trim().isEmpty) return;
    setState(() => sendingEmail = true);
    try {
      await TeamService.sendInviteByEmail(
        team: widget.team,
        email: emailController.text,
      );
      if (!mounted) return;
      emailController.clear();
      _snack('Invite амжилттай илгээгдлээ');
    } catch (e) {
      if (!mounted) return;
      _snack('Алдаа: $e');
    } finally {
      if (mounted) setState(() => sendingEmail = false);
    }
  }

  Future<void> _search(String value) async {
    if (value.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() => searching = true);
    try {
      final found = await TeamService.searchUsers(value);
      if (!mounted) return;
      setState(() => results = found);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Гишүүн invite хийх',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'email@example.com',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: sendingEmail || emailController.text.trim().isEmpty
                      ? null
                      : _sendEmailInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C400),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: sendingEmail
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Илгээх',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Бүртгэлтэй хэрэглэгчийг нэр, email, username-ээр хайх',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (searching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (results.isEmpty)
            Text(
              searchController.text.length < 2
                  ? 'Хайхын тулд 2+ тэмдэгт бичнэ үү.'
                  : 'Хэрэглэгч олдсонгүй. Email invite ашиглаж болно.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...results.map(
              (user) => _SearchUserTile(team: widget.team, user: user),
            ),
          const SizedBox(height: 8),
          StreamBuilder<List<TeamInvite>>(
            stream: TeamService.invitesForTeam(widget.team.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Invite list алдаа: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                );
              }
              final invites = snapshot.data ?? const <TeamInvite>[];
              if (invites.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sent invites',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...invites.map((invite) => _SentInviteTile(invite: invite)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SentInviteTile extends StatelessWidget {
  final TeamInvite invite;

  const _SentInviteTile({required this.invite});

  @override
  Widget build(BuildContext context) {
    final color = _inviteStatusColor(invite.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_inviteStatusIcon(invite.status), color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.toEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${invite.teamName} - ${invite.status}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          _statusPill(invite.status),
        ],
      ),
    );
  }
}

Widget _statusPill(String status) {
  final color = _inviteStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    ),
  );
}

Color _inviteStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'expired':
      return Colors.grey;
    default:
      return Colors.orange;
  }
}

IconData _inviteStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return Icons.check_circle_outline;
    case 'rejected':
      return Icons.cancel_outlined;
    case 'expired':
      return Icons.timer_off_outlined;
    default:
      return Icons.hourglass_top_outlined;
  }
}

class _SearchUserTile extends StatefulWidget {
  final CompetitionTeam team;
  final AppUser user;

  const _SearchUserTile({required this.team, required this.user});

  @override
  State<_SearchUserTile> createState() => _SearchUserTileState();
}

class _SearchUserTileState extends State<_SearchUserTile> {
  bool sending = false;

  Future<void> _invite() async {
    setState(() => sending = true);
    try {
      await TeamService.sendInvite(team: widget.team, user: widget.user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite илгээгдлээ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty
                ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  user.sportPreferences.isEmpty
                      ? 'Sport type: not set'
                      : 'Sport type: ${user.sportPreferences.take(2).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: sending ? null : _invite,
            child: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Invite'),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
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
