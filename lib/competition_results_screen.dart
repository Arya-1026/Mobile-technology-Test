import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'team_service.dart';

class CompetitionResultsScreen extends StatefulWidget {
  final CompetitionItem competition;

  const CompetitionResultsScreen({super.key, required this.competition});

  @override
  State<CompetitionResultsScreen> createState() =>
      _CompetitionResultsScreenState();
}

class _CompetitionResultsScreenState extends State<CompetitionResultsScreen> {
  static const _bg = Color(0xFF060713);
  static const _panel = Color(0xFF101323);
  static const _yellow = Color(0xFFF5C400);
  static const _cyan = Color(0xFF19E6FF);
  static const _pink = Color(0xFFFF3DF2);

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser?.uid == widget.competition.ownerId) {
      TeamService.createDefaultMatches(widget.competition.id);
    }
  }

  Future<void> _addMatch() async {
    try {
      await TeamService.createManualMatch(widget.competition.id);
      if (!mounted) return;
      _toast('Шинэ match нэмэгдлээ');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrganizer =
        FirebaseAuth.instance.currentUser?.uid == widget.competition.ownerId;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Тэмцээний үр дүн',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060713), Color(0xFF14101F), Color(0xFF071B24)],
          ),
        ),
        child: StreamBuilder<List<BracketMatch>>(
          stream: TeamService.matchesForCompetition(widget.competition.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.warning_amber_rounded,
                title: 'Bracket уншихад алдаа гарлаа',
                message: snapshot.error.toString(),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _yellow),
              );
            }
            final matches = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _HeaderCard(
                  title: widget.competition.title,
                  isOrganizer: isOrganizer,
                  onAddMatch: _addMatch,
                ),
                const SizedBox(height: 14),
                if (!isOrganizer)
                  const _InfoBanner(
                    text:
                        'Зөвхөн тэмцээний зохион байгуулагч bracket засах болон үр дүн оруулах боломжтой.',
                  )
                else
                  const _InfoBanner(
                    text:
                        'Slot дээр дарж баг онооно. Хоёр баг оноосны дараа result form нээгдэнэ.',
                  ),
                const SizedBox(height: 14),
                if (matches.isEmpty)
                  const _MessageState(
                    icon: Icons.account_tree_outlined,
                    title: 'Bracket хоосон байна',
                    message: 'Add match дарж эхний match үүсгэнэ үү.',
                  )
                else
                  ...matches.map(
                    (match) => _MatchCard(
                      match: match,
                      isOrganizer: isOrganizer,
                      onFeedback: _toast,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final bool isOrganizer;
  final VoidCallback onAddMatch;

  const _HeaderCard({
    required this.title,
    required this.isOrganizer,
    required this.onAddMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101323).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C400).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5C400).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5C400), Color(0xFFFF3DF2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3DF2).withValues(alpha: 0.28),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Live bracket control',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _NeonButton(
                icon: Icons.add_rounded,
                label: 'Add match',
                onPressed: onAddMatch,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final BracketMatch match;
  final bool isOrganizer;
  final void Function(String message, {bool error}) onFeedback;

  const _MatchCard({
    required this.match,
    required this.isOrganizer,
    required this.onFeedback,
  });

  Future<void> _selectTeam(BuildContext context, bool slotA) async {
    try {
      final teams =
          await TeamService.teamsForCompetition(match.competitionId).first;
      if (!context.mounted) return;

      final otherTeamId = slotA ? match.teamBId : match.teamAId;
      final available = teams.where((team) => team.id != otherTeamId).toList();

      final selected = await showModalBottomSheet<CompetitionTeam>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _TeamPickerSheet(
          teams: available,
          currentTeamId: slotA ? match.teamAId : match.teamBId,
        ),
      );
      if (selected == null) return;
      await TeamService.assignTeamToMatchSlot(
        match: match,
        team: selected,
        slotA: slotA,
      );
      onFeedback('${selected.name} slot дээр оноогдлоо');
    } catch (e) {
      onFeedback(e.toString(), error: true);
    }
  }

  Future<void> _openResultForm(BuildContext context) async {
    if (match.teamAId.isEmpty || match.teamBId.isEmpty) {
      onFeedback(
        'Эхлээд хоёр slot дээр баг онооно уу. Slot дээр дарж баг сонгоно.',
        error: true,
      );
      return;
    }

    final score = TextEditingController(text: match.score);
    final note = TextEditingController(text: match.note);
    final matchTime = TextEditingController(text: match.matchTime);
    var status = match.status;
    var winnerTeamId =
        match.winnerTeamId.isEmpty ? match.teamAId : match.winnerTeamId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final canSave =
              winnerTeamId.isNotEmpty && score.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: const Color(0xFF101323),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: const Color(0xFF19E6FF).withValues(alpha: 0.45),
              ),
            ),
            title: const Text(
              'Match result',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NeonInput(
                    controller: matchTime,
                    label: 'Match time',
                    hint: '2026-05-14 18:00',
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: winnerTeamId.isEmpty ? null : winnerTeamId,
                    dropdownColor: const Color(0xFF15192C),
                    iconEnabledColor: const Color(0xFFF5C400),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _fieldDecoration(
                      'Winner',
                      Icons.emoji_events_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: match.teamAId,
                        child: Text(match.teamAName),
                      ),
                      DropdownMenuItem(
                        value: match.teamBId,
                        child: Text(match.teamBName),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => winnerTeamId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  _NeonInput(
                    controller: score,
                    label: 'Score',
                    hint: '2 - 1',
                    icon: Icons.scoreboard_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF15192C),
                    iconEnabledColor: const Color(0xFFF5C400),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration:
                        _fieldDecoration('Status', Icons.radio_button_checked),
                    items: const [
                      DropdownMenuItem(
                        value: 'Scheduled',
                        child: Text('Scheduled'),
                      ),
                      DropdownMenuItem(value: 'Live', child: Text('Live')),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => status = value ?? status),
                  ),
                  const SizedBox(height: 12),
                  _NeonInput(
                    controller: note,
                    label: 'Тайлбар',
                    hint: 'Match-ийн тэмдэглэл',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Болих',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
              ),
              _NeonButton(
                icon: Icons.save_outlined,
                label: 'Хадгалах',
                compact: true,
                onPressed: canSave
                    ? () async {
                        try {
                          await TeamService.saveMatchResult(
                            match: match,
                            winnerTeamId: winnerTeamId,
                            score: score.text.trim(),
                            status: status,
                            note: note.text.trim(),
                            matchTime: matchTime.text.trim(),
                          );
                          if (context.mounted) Navigator.pop(context);
                          onFeedback('Үр дүн хадгалагдлаа');
                        } catch (e) {
                          onFeedback(e.toString(), error: true);
                        }
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
    score.dispose();
    note.dispose();
    matchTime.dispose();
  }

  Future<void> _confirmDeleteMatch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101323),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.55),
          ),
        ),
        title: const Text(
          'Match устгах уу?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Round ${match.round} · Match ${match.matchNo}-ийг устгана. Хэрэв result орсон бол холбоотой result/history мөн цэвэрлэгдэнэ.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Болих',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Устгах'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TeamService.deleteMatch(match);
      onFeedback('Match устгагдлаа');
    } catch (e) {
      onFeedback(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = match.teamAId.isNotEmpty && match.teamBId.isNotEmpty;
    final hasResult = match.winnerTeamId.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101323).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ready
              ? const Color(0xFF19E6FF).withValues(alpha: 0.44)
              : const Color(0xFFF5C400).withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: (ready ? const Color(0xFF19E6FF) : const Color(0xFFF5C400))
                .withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundBadge(round: match.round, matchNo: match.matchNo),
              const Spacer(),
              _StatusPill(status: match.status, ready: ready),
              if (isOrganizer) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Match устгах',
                  child: InkWell(
                    onTap: () => _confirmDeleteMatch(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (match.matchTime.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaLine(icon: Icons.schedule_outlined, text: match.matchTime),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _slot(context, match.teamAName, true)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF3DF2).withValues(alpha: 0.18),
                  border: Border.all(
                    color: const Color(0xFFFF3DF2).withValues(alpha: 0.45),
                  ),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(child: _slot(context, match.teamBName, false)),
            ],
          ),
          if (match.score.isNotEmpty || hasResult) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (match.score.isNotEmpty)
                  _resultChip(
                    Icons.scoreboard_outlined,
                    '${match.status} · ${match.score}',
                    const Color(0xFF19E6FF),
                  ),
                if (hasResult)
                  _resultChip(
                    Icons.emoji_events_outlined,
                    'Winner: ${match.winnerTeamId == match.teamAId ? match.teamAName : match.teamBName}',
                    Colors.greenAccent,
                  ),
                if (match.loserTeamId.isNotEmpty)
                  _resultChip(
                    Icons.close_rounded,
                    'Loser: ${match.loserTeamId == match.teamAId ? match.teamAName : match.teamBName}',
                    Colors.redAccent,
                  ),
              ],
            ),
          ],
          if (match.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaLine(icon: Icons.notes_outlined, text: match.note),
          ],
          if (isOrganizer) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _NeonButton(
                icon: Icons.scoreboard_outlined,
                label: ready ? 'Үр дүн оруулах' : 'Эхлээд 2 баг онооно',
                onPressed: () => _openResultForm(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _slot(BuildContext context, String name, bool slotA) {
    final isEmpty = name.isEmpty;
    return InkWell(
      onTap: isOrganizer ? () => _selectTeam(context, slotA) : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isEmpty
              ? const Color(0xFFF5C400).withValues(alpha: 0.10)
              : const Color(0xFF15192C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEmpty
                ? const Color(0xFFF5C400).withValues(alpha: 0.75)
                : const Color(0xFF19E6FF).withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: (isEmpty ? const Color(0xFFF5C400) : const Color(0xFF19E6FF))
                  .withValues(alpha: 0.12),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.add_rounded : Icons.groups_2_outlined,
              size: 17,
              color: isEmpty ? const Color(0xFFF5C400) : const Color(0xFF19E6FF),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isEmpty ? 'Баг оноох' : name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEmpty ? const Color(0xFFFFE680) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPickerSheet extends StatelessWidget {
  final List<CompetitionTeam> teams;
  final String currentTeamId;

  const _TeamPickerSheet({
    required this.teams,
    required this.currentTeamId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101323),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF19E6FF).withValues(alpha: 0.36),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF19E6FF).withValues(alpha: 0.16),
              blurRadius: 28,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Баг сонгох',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Зөвхөн энэ тэмцээнд бүртгэлтэй багууд харагдана.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 14),
              if (teams.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(
                    'Сонгох боломжтой баг алга байна.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final selected = team.id == currentTeamId;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFF5C400)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        tileColor: selected
                            ? const Color(0xFFF5C400).withValues(alpha: 0.12)
                            : const Color(0xFF15192C),
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF19E6FF).withValues(alpha: 0.14),
                          child: const Icon(
                            Icons.groups_2_outlined,
                            color: Color(0xFF19E6FF),
                          ),
                        ),
                        title: Text(
                          team.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          '${team.members.length}/${team.maxMembers} гишүүн',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFFF5C400))
                            : const Icon(Icons.chevron_right,
                                color: Colors.white54),
                        onTap: () => Navigator.pop(context, team),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: teams.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  final int round;
  final int matchNo;

  const _RoundBadge({required this.round, required this.matchNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5C400), Color(0xFFFF3DF2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Round $round · Match $matchNo',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool ready;

  const _StatusPill({required this.status, required this.ready});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Completed'
        ? Colors.greenAccent
        : status == 'Live'
            ? const Color(0xFFFF3DF2)
            : ready
                ? const Color(0xFF19E6FF)
                : const Color(0xFFF5C400);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        ready ? status : 'Waiting teams',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.58)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF19E6FF).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF19E6FF).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF19E6FF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFFF5C400)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.64)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  const _NeonButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                colors: [Color(0xFFF5C400), Color(0xFFFF3DF2)],
              ),
        color: onPressed == null ? Colors.white.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFF3DF2).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 16 : 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: onPressed == null ? Colors.white38 : Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 10 : 14,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _NeonInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _NeonInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: _fieldDecoration(label, icon).copyWith(hintText: hint),
    );
  }
}

InputDecoration _fieldDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.66)),
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.32)),
    prefixIcon: Icon(icon, color: const Color(0xFF19E6FF), size: 19),
    filled: true,
    fillColor: const Color(0xFF15192C),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: const Color(0xFF19E6FF).withValues(alpha: 0.24),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF5C400), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.redAccent.withValues(alpha: 0.8)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}
