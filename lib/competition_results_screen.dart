import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  @override
  void initState() {
    super.initState();
    TeamService.createDefaultMatches(widget.competition.id);
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFF5C400);
    final isOrganizer = FirebaseAuth.instance.currentUser?.uid ==
        widget.competition.ownerId;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Тэмцээний үр дүн'),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<BracketMatch>>(
        stream: TeamService.matchesForCompetition(widget.competition.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.competition.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (!isOrganizer)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Зөвхөн тэмцээний зохион байгуулагч баг оноох болон үр дүн оруулах боломжтой.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ...matches.map((match) =>
                  _MatchCard(match: match, isOrganizer: isOrganizer)),
            ],
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final BracketMatch match;
  final bool isOrganizer;

  const _MatchCard({required this.match, required this.isOrganizer});

  Future<void> _selectTeam(BuildContext context, bool slotA) async {
    final teams =
        await TeamService.teamsForCompetition(match.competitionId).first;
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<CompetitionTeam>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Баг сонгох',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (teams.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Энэ тэмцээнд бүртгэгдсэн баг байхгүй байна'),
            ),
          ...teams.map(
            (team) => ListTile(
              leading: const Icon(Icons.groups_2_outlined),
              title: Text(team.name),
              subtitle: Text('${team.members.length}/${team.maxMembers}'),
              onTap: () => Navigator.pop(context, team),
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await TeamService.assignTeamToMatchSlot(
      match: match,
      team: selected,
      slotA: slotA,
    );
  }

  Future<void> _openResultForm(BuildContext context) async {
    final score = TextEditingController(text: match.score);
    final note = TextEditingController(text: match.note);
    var status = match.status;
    var winnerTeamId = match.winnerTeamId.isEmpty
        ? match.teamAId
        : match.winnerTeamId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Match result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: winnerTeamId.isEmpty ? null : winnerTeamId,
                  decoration: const InputDecoration(labelText: 'Winner'),
                  items: [
                    if (match.teamAId.isNotEmpty)
                      DropdownMenuItem(
                        value: match.teamAId,
                        child: Text(match.teamAName),
                      ),
                    if (match.teamBId.isNotEmpty)
                      DropdownMenuItem(
                        value: match.teamBId,
                        child: Text(match.teamBName),
                      ),
                  ],
                  onChanged: (value) => setState(() => winnerTeamId = value ?? ''),
                ),
                TextField(
                  controller: score,
                  decoration: const InputDecoration(labelText: 'Score'),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                    DropdownMenuItem(value: 'Live', child: Text('Live')),
                    DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (value) => setState(() => status = value ?? status),
                ),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Тайлбар'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Болих'),
            ),
            ElevatedButton(
              onPressed: winnerTeamId.isEmpty
                  ? null
                  : () async {
                      await TeamService.saveMatchResult(
                        match: match,
                        winnerTeamId: winnerTeamId,
                        score: score.text.trim(),
                        status: status,
                        note: note.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Хадгалах'),
            ),
          ],
        ),
      ),
    );
    score.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Text('Round ${match.round} · Match ${match.matchNo}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _slot(context, match.teamAName, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Expanded(child: _slot(context, match.teamBName, false)),
            ],
          ),
          const SizedBox(height: 10),
          if (match.score.isNotEmpty)
            Text(
              '${match.status} · ${match.score}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          if (isOrganizer)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: match.teamAId.isEmpty || match.teamBId.isEmpty
                    ? null
                    : () => _openResultForm(context),
                icon: const Icon(Icons.scoreboard_outlined),
                label: const Text('Үр дүн оруулах'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slot(BuildContext context, String name, bool slotA) {
    final isEmpty = name.isEmpty;
    return InkWell(
      onTap: isOrganizer && isEmpty ? () => _selectTeam(context, slotA) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEmpty
              ? (isOrganizer
                  ? const Color(0xFFFFF3D1)
                  : const Color(0xFFF8F8F8))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEmpty
                ? (isOrganizer
                    ? const Color(0xFFF5C400)
                    : Colors.grey.shade300)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isEmpty && isOrganizer)
              const Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF6A00)),
            if (isEmpty && isOrganizer) const SizedBox(width: 4),
            Flexible(
              child: Text(
                isEmpty
                    ? (isOrganizer ? 'Баг оноох' : 'TBD')
                    : name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isEmpty ? Colors.grey.shade600 : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
