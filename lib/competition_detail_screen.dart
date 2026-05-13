import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'competition_service.dart';
import 'competition_results_screen.dart';
import 'team_management_screen.dart';
import 'team_service.dart';

class CompetitionDetailScreen extends StatefulWidget {
  final CompetitionItem item;

  const CompetitionDetailScreen({super.key, required this.item});

  @override
  State<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _TeamCard extends StatefulWidget {
  final CompetitionTeam team;
  final Color orange;

  const _TeamCard({required this.team, required this.orange});

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool hovered = false;

  bool get isLeader =>
      FirebaseAuth.instance.currentUser?.uid == widget.team.leaderId;

  Future<void> _openInviteSheet() async {
    final controller = TextEditingController();
    List<AppUser> results = [];
    bool searching = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> runSearch(String value) async {
              setSheetState(() => searching = true);
              results = await TeamService.searchUsers(value);
              if (context.mounted) setSheetState(() => searching = false);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Гишүүн урих',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    onChanged: runSearch,
                    decoration: InputDecoration(
                      hintText: 'Email, username, нэрээр хайх',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.text.trim().isEmpty
                          ? null
                          : () async {
                              try {
                                await TeamService.sendInviteByEmail(
                                  team: widget.team,
                                  email: controller.text,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email invite илгээгдлээ'),
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
                            },
                      icon: const Icon(Icons.alternate_email_rounded),
                      label: const Text('Энэ email рүү invite илгээх'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: searching
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty
                            ? Center(
                                child: Text(
                                  controller.text.length < 2
                                      ? 'Хайхын тулд 2+ тэмдэгт бичнэ үү'
                                      : 'Бүртгэлтэй хэрэглэгч олдсонгүй',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            : ListView.separated(
                                itemCount: results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = results[index];
                                  return _UserInviteTile(
                                    user: user,
                                    team: widget.team,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }

  void _openTeamInfo() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final team = widget.team;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool sending = false;

            Future<void> sendEmail() async {
              if (emailCtrl.text.trim().isEmpty) return;
              setSheetState(() => sending = true);
              try {
                await TeamService.sendInviteByEmail(
                  team: team,
                  email: emailCtrl.text.trim(),
                );
                if (!context.mounted) return;
                emailCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite амжилттай илгээгдлээ'),
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
              } finally {
                if (context.mounted) setSheetState(() => sending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('Ахлагч: ${team.leaderName}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Тэмцээн: ${team.competitionTitle}',
                                style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Гишүүд',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ...team.members.map(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _memberAvatar(member, 36),
                          title: Text(member.name),
                          subtitle: Text(member.position),
                        ),
                      ),
                      if (isLeader) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text('Гишүүн урих',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                          'Бүртгэлтэй болон бүртгэлгүй хэрэглэгчийн email-аар invite илгээх боломжтой.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'email@example.com',
                                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: sending ? null : sendEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5C400),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.black),
                                      )
                                    : const Text('Илгээх',
                                        style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openInviteSheet();
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Нэрээр/username-аар хайж урих'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => emailCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        onTap: _openTeamInfo,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: widget.orange.withValues(alpha: hovered ? 0.20 : 0.08),
              blurRadius: hovered ? 22 : 14,
              offset: Offset(0, hovered ? 12 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _teamLogo(team),
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
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Leader: ${team.leaderName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                _avatarStack(team.members),
              ],
            ),
            if (team.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                team.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: team.members.map((member) {
                final canRemove = isLeader && member.uid != team.leaderId;
                return Chip(
                  avatar: _memberAvatar(member, 18),
                  label: Text('${member.name} · ${member.position}'),
                  deleteIcon: canRemove ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: canRemove
                      ? () async {
                          await TeamService.removeMember(team, member.uid);
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.group_outlined, size: 17, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${team.members.length}/${team.maxMembers} members',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isLeader)
                  TextButton.icon(
                    onPressed: _openInviteSheet,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Invite'),
                  ),
              ],
            ),
            if (isLeader)
              StreamBuilder<List<TeamInvite>>(
                stream: TeamService.pendingInvitesForTeam(team.id),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '$count invite pending',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _teamLogo(CompetitionTeam team) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: team.logoUrl.isEmpty
          ? Container(
              width: 54,
              height: 54,
              color: const Color(0xFFFFF3D1),
              child: Icon(Icons.groups_2_outlined, color: widget.orange),
            )
          : Image.network(
              team.logoUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: const Color(0xFFFFF3D1),
                child: Icon(Icons.groups_2_outlined, color: widget.orange),
              ),
            ),
    );
  }

  Widget _avatarStack(List<TeamMember> members) {
    final visible = members.take(3).toList();
    return SizedBox(
      width: 64,
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(left: i * 17, child: _memberAvatar(visible[i], 28)),
        ],
      ),
    );
  }

  Widget _memberAvatar(TeamMember member, double size) {
    return CircleAvatar(
      radius: size / 2,
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
}

class _UserInviteTile extends StatefulWidget {
  final AppUser user;
  final CompetitionTeam team;

  const _UserInviteTile({required this.user, required this.team});

  @override
  State<_UserInviteTile> createState() => _UserInviteTileState();
}

class _UserInviteTileState extends State<_UserInviteTile> {
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
      setState(() => sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty
                ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700)),
                Text(
                  user.sportPreferences.isEmpty
                      ? 'Sport type: not set'
                      : 'Sport type: ${user.sportPreferences.take(2).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'Username: ${user.uid}',
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

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen> {
  bool isExpanded = false;
  bool isBookmarked = false;
  bool isSending = false;
  String? myRequestStatus; // null | 'pending' | 'accepted' | 'rejected'
  bool loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadMyStatus();
  }

  Future<void> _loadMyStatus() async {
    final status =
        await CompetitionService.getMyRequestStatus(widget.item.id);
    if (mounted) {
      setState(() {
        myRequestStatus = status;
        loadingStatus = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Эхлээд нэвтрэнэ үү');
      return;
    }

    setState(() => isSending = true);
    try {
      await CompetitionService.sendParticipationRequest(widget.item);
      if (!mounted) return;
      setState(() {
        myRequestStatus = 'pending';
        isSending = false;
      });
      _showSnack('Оролцох хүсэлт амжилттай илгээгдлээ!');
    } catch (e) {
      if (!mounted) return;
      setState(() => isSending = false);
      _showSnack('Алдаа гарлаа: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    const yellow = Color(0xFFF5C400);
    const orange = Color(0xFFFF6A00);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Expandable image header ───────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: yellow,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? orange : Colors.black,
                    ),
                    onPressed: () =>
                        setState(() => isBookmarked = !isBookmarked),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.black),
                    onPressed: () => _showSnack('Түгээх хэсэг удахгүй нэмэгдэнэ'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _networkImage(item.imageUrl, double.infinity),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x0D000000),
                            Color(0x8C000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.organizationName.isEmpty
                                ? 'Зохион байгуулагч'
                                : item.organizationName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.tags.map((tag) => _tag(tag)).toList(),
                    ),

                    const SizedBox(height: 18),

                    // Info card
                    _infoCard(item, orange),

                    const SizedBox(height: 18),

                    if (TeamService.isTeamCompetition(item)) ...[
                      _teamSection(item, orange),
                      const SizedBox(height: 18),
                    ],

                    if (FirebaseAuth.instance.currentUser?.uid ==
                        item.ownerId) ...[
                      _sectionTitle('Тэмцээний үр дүн'),
                      const SizedBox(height: 10),
                      _resultEntryCard(item, orange),
                      const SizedBox(height: 18),
                    ],

                    // Description
                    _descriptionSection(orange),

                    const SizedBox(height: 18),

                    // Prizes (if available)
                    if (item.prizes.isNotEmpty) ...[
                      _sectionTitle('Шагнал'),
                      const SizedBox(height: 10),
                      _textCard(item.prizes, Icons.workspace_premium_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Rules (if available)
                    if (item.rules.isNotEmpty) ...[
                      _sectionTitle('Дүрэм журам'),
                      const SizedBox(height: 10),
                      _textCard(item.rules, Icons.gavel_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Contact info
                    if (item.contactInfo.isNotEmpty) ...[
                      _sectionTitle('Холбоо барих'),
                      const SizedBox(height: 10),
                      _textCard(
                          item.contactInfo, Icons.contact_phone_outlined, orange),
                      const SizedBox(height: 18),
                    ],

                    // Poster
                    _sectionTitle('Poster'),
                    const SizedBox(height: 12),
                    _posterWidget(item.posterUrl),

                    // Link
                    if (item.linkText.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('Холбоос'),
                      const SizedBox(height: 10),
                      _linkCard(item.linkText, orange),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom action bar ─────────────────────────────────────────────
      bottomNavigationBar: _bottomBar(orange),
    );
  }

  Widget _infoCard(CompetitionItem item, Color orange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.calendar_month_outlined,
            title: 'Бүртгэлийн хугацаа',
            value: item.date,
            orange: orange,
          ),
          if (item.registrationDeadline != null) ...[
            const Divider(),
            _infoRow(
              icon: Icons.event_busy_outlined,
              title: 'Бүртгэл хаагдах',
              value:
                  '${item.registrationDeadline!.year}.${item.registrationDeadline!.month.toString().padLeft(2, '0')}.${item.registrationDeadline!.day.toString().padLeft(2, '0')}',
              orange: orange,
            ),
          ],
          const Divider(),
          _infoRow(
            icon: Icons.category_outlined,
            title: 'Ангилал',
            value: item.category,
            orange: orange,
          ),
          const Divider(),
          _infoRow(
            icon: Icons.people_outline,
            title: 'Оролцох хэлбэр',
            value: item.participationType.isEmpty ? 'Тодорхойгүй' : item.participationType,
            orange: orange,
          ),
          if (item.location.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.place_outlined,
              title: 'Байршил',
              value: item.location,
              orange: orange,
            ),
          ],
          if (item.ageCategory.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.person_outline,
              title: 'Насны ангилал',
              value: item.ageCategory,
              orange: orange,
            ),
          ],
          if (item.genderCategory.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.wc_outlined,
              title: 'Хүйсийн ангилал',
              value: item.genderCategory,
              orange: orange,
            ),
          ],
          if (item.maxParticipants > 0) ...[
            const Divider(),
            _infoRow(
              icon: Icons.group_outlined,
              title: 'Дээд хязгаар',
              value: '${item.maxParticipants} оролцогч',
              orange: orange,
            ),
          ],
          const Divider(),
          _infoRow(
            icon: Icons.payments_outlined,
            title: 'Хураамж',
            value: item.fee.isEmpty ? 'Үнэгүй' : item.fee,
            orange: orange,
          ),
          if (item.materials.isNotEmpty) ...[
            const Divider(),
            _infoRow(
              icon: Icons.fact_check_outlined,
              title: 'Бүрдүүлэх материал',
              value: item.materials,
              orange: orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _descriptionSection(Color orange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Тайлбар'),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  setState(() => isExpanded = !isExpanded),
              icon: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: orange,
              ),
              label: Text(
                isExpanded ? 'Хураах' : 'Дэлгэрэнгүй',
                style: TextStyle(
                    color: orange, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Text(
            widget.item.fullDescription.isEmpty
                ? 'Тайлбар оруулаагүй байна.'
                : widget.item.fullDescription,
            maxLines: isExpanded ? null : 7,
            overflow: isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _teamSection(CompetitionItem item, Color orange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Registered Teams'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamManagementScreen(competition: item),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Баг үүсгэх'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<CompetitionTeam>>(
          stream: TeamService.teamsForCompetition(item.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 120,
                decoration: _cardDecoration(),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final teams = snapshot.data!;
            if (teams.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Icon(Icons.groups_2_outlined,
                        size: 42, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Одоогоор бүртгэгдсэн баг байхгүй',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Эхний багийг үүсгээд гишүүдээ invite хийнэ үү.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 640;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: teams
                      .map(
                        (team) => SizedBox(
                          width: wide
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth,
                          child: _TeamCard(team: team, orange: orange),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _resultEntryCard(CompetitionItem item, Color orange) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompetitionResultsScreen(competition: item),
        ),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
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
              child: Icon(Icons.scoreboard_outlined, color: orange),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bracket болон match result',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text('Баг оноох, winner/loser, score хадгалах'),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(Color orange) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () =>
                    setState(() => isBookmarked = !isBookmarked),
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  color: orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _requestButton(orange)),
          ],
        ),
      ),
    );
  }

  Widget _requestButton(Color orange) {
    if (TeamService.isTeamCompetition(widget.item)) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamManagementScreen(competition: widget.item),
            ),
          ),
          icon: const Icon(Icons.groups_2_outlined),
          label: const Text(
            'Баг үүсгэх / Team management',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (loadingStatus) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (myRequestStatus == 'pending') {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'Хүлээгдэж байна...',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (myRequestStatus == 'accepted') {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Бүртгэгдсэн',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (myRequestStatus == 'rejected') {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isSending ? null : _sendRequest,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(
            'Дахин хүсэлт илгээх',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    // No request yet
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSending ? null : _sendRequest,
        icon: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          isSending ? 'Илгээж байна...' : 'Оролцох хүсэлт илгээх',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    );
  }

  Widget _tag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFFF5C400).withValues(alpha: 0.4)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF6B5600),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color orange,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard(String text, IconData icon, Color orange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(String url, Color orange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(Icons.link, color: orange),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterWidget(String url) {
    if (url.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 42, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        height: 230,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.white,
          child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 42, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _networkImage(String url, double height) {
    if (url.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 45, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.broken_image_outlined,
            size: 45, color: Colors.grey),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
