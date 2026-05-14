import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';

class TeamService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference get _teams => _db.collection('teams');
  static CollectionReference get _invites => _db.collection('teamInvites');
  static CollectionReference get _notifications =>
      _db.collection('teamNotifications');
  static CollectionReference get _registered =>
      _db.collection('registeredCompetitions');
  static CollectionReference get _matches => _db.collection('bracketMatches');
  static CollectionReference get _matchResults =>
      _db.collection('matchResults');
  static CollectionReference get _competitions => _db.collection('competitions');

  static bool isTeamCompetition(CompetitionItem item) {
    final value = '${item.participationType} ${item.tags.join(' ')}';
    return value.contains('Баг') ||
        value.contains('Ð‘Ð°Ð³') ||
        value.toLowerCase().contains('team');
  }

  static Stream<List<CompetitionTeam>> teamsForCompetition(String competitionId) {
    return _teams
        .where('competitionId', isEqualTo: competitionId)
        .snapshots()
        .map((s) => s.docs.map((d) => CompetitionTeam.fromDoc(d)).toList());
  }

  static Stream<List<CompetitionTeam>> myLeaderTeamsForCompetition(
    String competitionId,
  ) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _teams
        .where('competitionId', isEqualTo: competitionId)
        .where('leaderId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => CompetitionTeam.fromDoc(d)).toList());
  }

  static Stream<List<TeamInvite>> myInvites() {
    final user = _auth.currentUser;
    final rawEmail = user?.email?.trim();
    final email = rawEmail?.toLowerCase();
    if (user == null) return const Stream.empty();

    final controller = StreamController<List<TeamInvite>>();
    final uidItems = <String, TeamInvite>{};
    final lowerEmailItems = <String, TeamInvite>{};
    final rawEmailItems = <String, TeamInvite>{};
    late final StreamSubscription uidSub;
    StreamSubscription? lowerEmailSub;
    StreamSubscription? rawEmailSub;

    void emit() {
      final merged = <String, TeamInvite>{
        ...uidItems,
        ...lowerEmailItems,
        ...rawEmailItems,
      }.values.toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      if (!controller.isClosed) controller.add(merged);
    }

    uidSub = _invites
        .where('toUid', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      uidItems
        ..clear()
        ..addEntries(snapshot.docs.map((d) {
          final invite = TeamInvite.fromDoc(d);
          return MapEntry(invite.id, invite);
        }));
      emit();
    }, onError: controller.addError);

    if (email != null && email.isNotEmpty) {
      lowerEmailSub = _invites
          .where('toEmail', isEqualTo: email)
          .snapshots()
          .listen((snapshot) {
        lowerEmailItems
          ..clear()
          ..addEntries(snapshot.docs.map((d) {
            final invite = TeamInvite.fromDoc(d);
            return MapEntry(invite.id, invite);
          }));
        emit();
      }, onError: (_) {
        lowerEmailItems.clear();
        emit();
      });
    }

    if (rawEmail != null && rawEmail.isNotEmpty && rawEmail != email) {
      rawEmailSub = _invites
          .where('toEmail', isEqualTo: rawEmail)
          .snapshots()
          .listen((snapshot) {
        rawEmailItems
          ..clear()
          ..addEntries(snapshot.docs.map((d) {
            final invite = TeamInvite.fromDoc(d);
            return MapEntry(invite.id, invite);
          }));
        emit();
      }, onError: (_) {
        rawEmailItems.clear();
        emit();
      });
    }

    controller.onCancel = () async {
      await uidSub.cancel();
      await lowerEmailSub?.cancel();
      await rawEmailSub?.cancel();
    };

    return controller.stream;
  }

  static Stream<List<TeamInvite>> pendingInvitesForTeam(String teamId) {
    return _invites
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TeamInvite.fromDoc(d))
            .where((invite) => invite.status.toLowerCase() == 'pending')
            .toList());
  }

  static Stream<List<TeamInvite>> invitesForTeam(String teamId) {
    return _invites
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((s) => s.docs.map((d) => TeamInvite.fromDoc(d)).toList());
  }

  static Stream<List<TeamNotification>> myNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _notifications
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => TeamNotification.fromDoc(d)).toList());
  }

  static Stream<List<RegisteredCompetition>> myRegisteredCompetitions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _registered
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RegisteredCompetition.fromDoc(d))
            .toList());
  }

  static Stream<List<BracketMatch>> matchesForCompetition(String competitionId) {
    return _matches
        .where('competitionId', isEqualTo: competitionId)
        .snapshots()
        .map((s) => s.docs.map((d) => BracketMatch.fromDoc(d)).toList()
          ..sort((a, b) {
            final round = a.round.compareTo(b.round);
            return round != 0 ? round : a.matchNo.compareTo(b.matchNo);
          }));
  }

  static Future<List<AppUser>> searchUsers(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return [];
    final currentUid = _auth.currentUser?.uid;

    final snap = await _db.collection('users').limit(50).get();
    return snap.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .where((user) {
      if (user.uid == currentUid) return false;
      final haystack =
          '${user.name} ${user.email} ${user.uid} ${user.sportPreferences.join(' ')}'
              .toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  static Future<String> createTeam({
    required CompetitionItem competition,
    required String name,
    required String description,
    required String logoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    final existing = await _teams
        .where('competitionId', isEqualTo: competition.id)
        .where('memberIds', arrayContains: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Та энэ тэмцээнд аль хэдийн нэг багт бүртгэлтэй байна');
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final leaderName = userData['name'] ?? user.displayName ?? 'Team leader';
    final leaderPhoto = userData['photoUrl'] ?? user.photoURL ?? '';

    final leader = TeamMember(
      uid: user.uid,
      name: leaderName,
      email: user.email ?? '',
      photoUrl: leaderPhoto,
      position: 'Leader',
    );

    final doc = await _teams.add({
      'competitionId': competition.id,
      'competitionTitle': competition.title,
      'sportCategory': competition.category,
      'competitionDate': competition.date,
      'competitionLocation': competition.location,
      'name': name.trim(),
      'description': description.trim(),
      'logoUrl': logoUrl.trim(),
      'leaderId': user.uid,
      'leaderName': leaderName,
      'leaderEmail': user.email ?? '',
      'maxMembers': competition.maxTeamMembers,
      'memberIds': [user.uid],
      'members': [leader.toMap()],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _upsertRegisteredCompetition(
      userId: user.uid,
      competitionId: competition.id,
      competitionTitle: competition.title,
      category: competition.category,
      date: competition.date,
      location: competition.location,
      teamId: doc.id,
      teamName: name.trim(),
      participationType: 'Team',
      status: 'Registered',
    );

    await _notify(
      user.uid,
      'Баг үүсгэлээ',
      '${competition.title} тэмцээнд $name баг амжилттай үүслээ.',
      'team_created',
    );
    return doc.id;
  }

  static Future<void> sendInvite({
    required CompetitionTeam team,
    required AppUser user,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Нэвтрээгүй байна');
    if (team.leaderId != currentUser.uid) {
      throw Exception('Зөвхөн багийн ахлагч invite илгээх боломжтой');
    }

    final normalizedEmail = user.email.trim().toLowerCase();

    final membership = await _teams
        .where('competitionId', isEqualTo: team.competitionId)
        .where('memberIds', arrayContains: user.uid)
        .limit(1)
        .get();
    if (membership.docs.isNotEmpty) {
      throw Exception('Энэ хэрэглэгч тухайн тэмцээнд аль хэдийн багтай байна');
    }

    final duplicate = await _invites
        .where('competitionId', isEqualTo: team.competitionId)
        .where('toEmail', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: 'Pending')
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw Exception('Энэ хэрэглэгчид invite аль хэдийн илгээгдсэн байна');
    }

    await _invites.add({
      'teamId': team.id,
      'teamName': team.name,
      'competitionId': team.competitionId,
      'competitionTitle': team.competitionTitle,
      'sportCategory': team.sportCategory,
      'leaderId': team.leaderId,
      'leaderName': team.leaderName,
      'toUid': user.uid,
      'toEmail': normalizedEmail,
      'toName': user.name,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _notify(
      user.uid,
      'Team invite ирлээ',
      '${team.leaderName} таныг ${team.name} багт урьсан байна.',
      'team_invite',
    );
  }

  static Future<void> sendInviteByEmail({
    required CompetitionTeam team,
    required String email,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Нэвтрээгүй байна');
    if (team.leaderId != currentUser.uid) {
      throw Exception('Зөвхөн багийн ахлагч invite илгээх боломжтой');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@')) {
      throw Exception('Зөв email хаяг оруулна уу');
    }

    final userSnap = await _db
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (userSnap.docs.isNotEmpty) {
      final user = AppUser.fromMap(userSnap.docs.first.id, userSnap.docs.first.data());
      await sendInvite(team: team, user: user);
      return;
    }

    final duplicate = await _invites
        .where('competitionId', isEqualTo: team.competitionId)
        .where('toEmail', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: 'Pending')
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw Exception('Энэ email рүү тухайн тэмцээнд pending invite аль хэдийн илгээгдсэн байна');
    }

    await _invites.add({
      'teamId': team.id,
      'teamName': team.name,
      'competitionId': team.competitionId,
      'competitionTitle': team.competitionTitle,
      'sportCategory': team.sportCategory,
      'leaderId': team.leaderId,
      'leaderName': team.leaderName,
      'toUid': '',
      'toEmail': normalizedEmail,
      'toName': normalizedEmail,
      'status': 'Pending',
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> linkPendingEmailInvites(User user) async {
    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return;

    final snap = await _invites
        .where('toEmail', isEqualTo: email)
        .get();
    for (final doc in snap.docs) {
      final invite = TeamInvite.fromDoc(doc);
      if (invite.status.toLowerCase() != 'pending') continue;
      if (invite.expiresAt != null && invite.expiresAt!.isBefore(DateTime.now())) {
        await doc.reference.update({'status': 'Expired'});
        continue;
      }
      if (invite.toUid.isNotEmpty && invite.toUid != user.uid) {
        continue;
      }
      final wasUnlinked = invite.toUid.isEmpty;
      await doc.reference.update({
        'toUid': user.uid,
        'toName': user.displayName ?? email,
      });
      if (wasUnlinked) {
        await _notify(
          user.uid,
          'Team invite ирлээ',
          '${invite.leaderName} таныг ${invite.teamName} багт урьсан байна. Accept эсвэл reject хийнэ үү.',
          'team_invite',
        );
      }
    }
  }

  static Future<void> syncMyEmailInvites() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');
    await linkPendingEmailInvites(user);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _notifications.doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> respondInvite(TeamInvite invite, bool accepted) async {
    final user = _auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    final inviteEmail = invite.toEmail.trim().toLowerCase();
    final canRespond = user != null &&
        (user.uid == invite.toUid ||
            (invite.toUid.isEmpty && email == inviteEmail));
    if (!canRespond) {
      throw Exception('Invite хүлээн авах эрхгүй байна');
    }
    final currentUser = user!;
    final currentEmail = email!;

    await _db.runTransaction((transaction) async {
      final inviteRef = _invites.doc(invite.id);
      final inviteSnap = await transaction.get(inviteRef);
      if (!inviteSnap.exists) throw Exception('Invite олдсонгүй');
      final inviteData = inviteSnap.data() as Map<String, dynamic>;
      if (inviteData['status'] != 'Pending') {
        throw Exception('Invite аль хэдийн шийдвэрлэгдсэн байна');
      }
      final storedUid = (inviteData['toUid'] ?? '') as String;
      final storedEmail =
          ((inviteData['toEmail'] ?? '') as String).trim().toLowerCase();
      if (storedUid.isNotEmpty && storedUid != currentUser.uid) {
        throw Exception('Invite хүлээн авах эрхгүй байна');
      }
      if (storedUid.isEmpty && storedEmail != currentEmail) {
        throw Exception('Invite хүлээн авах эрхгүй байна');
      }

      if (!accepted) {
        transaction.update(inviteRef, {
          'toUid': currentUser.uid,
          'toName': currentUser.displayName ?? invite.toName,
          'status': 'Rejected',
        });
        return;
      }

      final teamRef = _teams.doc(invite.teamId);
      final teamSnap = await transaction.get(teamRef);
      if (!teamSnap.exists) throw Exception('Баг олдсонгүй');
      final teamData = teamSnap.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(teamData['memberIds'] ?? []);
      if (memberIds.contains(currentUser.uid)) {
        transaction.update(inviteRef, {
          'toUid': currentUser.uid,
          'toName': currentUser.displayName ?? invite.toName,
          'status': 'Accepted',
        });
        return;
      }
      final maxMembers = (teamData['maxMembers'] ?? 5) as int;
      if (memberIds.length >= maxMembers) {
        throw Exception('Багийн гишүүдийн лимит дүүрсэн байна');
      }

      final existingMembership = await _teams
          .where('competitionId', isEqualTo: invite.competitionId)
          .where('memberIds', arrayContains: currentUser.uid)
          .limit(1)
          .get();
      if (existingMembership.docs.isNotEmpty) {
        throw Exception('Та энэ тэмцээнд аль хэдийн нэг багт байна');
      }

      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};
      final member = TeamMember(
        uid: currentUser.uid,
        name: userData['name'] ?? currentUser.displayName ?? invite.toName,
        email: currentUser.email ?? invite.toEmail,
        photoUrl: userData['photoUrl'] ?? currentUser.photoURL ?? '',
        position: 'Member',
      );

      transaction.update(teamRef, {
        'memberIds': [...memberIds, currentUser.uid],
        'members': [...(teamData['members'] as List<dynamic>? ?? []), member.toMap()],
      });
      transaction.update(inviteRef, {
        'toUid': currentUser.uid,
        'toName': userData['name'] ?? currentUser.displayName ?? invite.toName,
        'status': 'Accepted',
      });
    });

    await _notify(
      invite.leaderId,
      accepted ? 'Invite accepted' : 'Invite rejected',
      accepted
          ? '${invite.toName} ${invite.teamName} багт нэгдлээ.'
          : '${invite.toName} ${invite.teamName} багийн invite-ийг татгалзлаа.',
      accepted ? 'invite_accepted' : 'invite_rejected',
    );

    if (accepted) {
      final teamDoc = await _teams.doc(invite.teamId).get();
      if (teamDoc.exists) {
        final team = CompetitionTeam.fromDoc(teamDoc);
        await _upsertRegisteredCompetition(
          userId: invite.toUid.isEmpty ? _auth.currentUser!.uid : invite.toUid,
          competitionId: team.competitionId,
          competitionTitle: team.competitionTitle,
          category: team.sportCategory,
          date: team.competitionDate,
          location: team.competitionLocation,
          teamId: team.id,
          teamName: team.name,
          participationType: 'Team',
          status: 'Registered',
        );
      }
    }
  }

  static Future<void> assignTeamToMatchSlot({
    required BracketMatch match,
    required CompetitionTeam team,
    required bool slotA,
  }) async {
    if (team.competitionId != match.competitionId) {
      throw Exception('Энэ баг тухайн тэмцээнд бүртгэлгүй байна');
    }
    if (slotA && team.id == match.teamBId) {
      throw Exception('Нэг багийг хоёр slot дээр зэрэг оноох боломжгүй');
    }
    if (!slotA && team.id == match.teamAId) {
      throw Exception('Нэг багийг хоёр slot дээр зэрэг оноох боломжгүй');
    }

    await _matches.doc(match.id).set({
      'competitionId': match.competitionId,
      'round': match.round,
      'matchNo': match.matchNo,
      if (slotA) 'teamAId': team.id,
      if (slotA) 'teamAName': team.name,
      if (!slotA) 'teamBId': team.id,
      if (!slotA) 'teamBName': team.name,
      'winnerTeamId': '',
      'loserTeamId': '',
      'score': '',
      'status': match.winnerTeamId.isNotEmpty ? 'Scheduled' : match.status,
      'note': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final updatedMatch = BracketMatch.fromDoc(await _matches.doc(match.id).get());
    await _syncMatchParticipants(updatedMatch);
  }

  static Future<void> createDefaultMatches(String competitionId) async {
    final existing =
        await _matches.where('competitionId', isEqualTo: competitionId).limit(1).get();
    if (existing.docs.isNotEmpty) return;
    for (var i = 1; i <= 4; i++) {
      await _matches.add({
        'competitionId': competitionId,
        'round': 1,
        'matchNo': i,
        'teamAId': '',
        'teamAName': '',
        'teamBId': '',
        'teamBName': '',
        'winnerTeamId': '',
        'loserTeamId': '',
        'score': '',
        'status': 'Scheduled',
        'note': '',
        'matchTime': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> createManualMatch(String competitionId, {int round = 1}) async {
    final existing =
        await _matches.where('competitionId', isEqualTo: competitionId).get();
    var nextMatchNo = 1;
    for (final doc in existing.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['round'] ?? 1) != round) continue;
      final matchNo = (data['matchNo'] ?? 0) as int;
      if (matchNo >= nextMatchNo) nextMatchNo = matchNo + 1;
    }
    await _matches.add({
      'competitionId': competitionId,
      'round': round,
      'matchNo': nextMatchNo,
      'teamAId': '',
      'teamAName': '',
      'teamBId': '',
      'teamBName': '',
      'winnerTeamId': '',
      'loserTeamId': '',
      'score': '',
      'status': 'Scheduled',
      'note': '',
      'matchTime': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMatch(BracketMatch match) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    final competitionDoc = await _competitions.doc(match.competitionId).get();
    if (competitionDoc.exists) {
      final data = competitionDoc.data() as Map<String, dynamic>;
      if ((data['ownerId'] ?? '') != user.uid) {
        throw Exception('Зөвхөн зохион байгуулагч match устгах боломжтой');
      }
    }

    await _matchResults.doc(match.id).delete().catchError((_) {});
    await _matches.doc(match.id).delete();

    await _removeDeletedMatchFromTeam(match.teamAId, match);
    await _removeDeletedMatchFromTeam(match.teamBId, match);
    await _clearAdvancedSlotFromDeletedMatch(match);
  }

  static Future<void> saveMatchResult({
    required BracketMatch match,
    required String winnerTeamId,
    required String score,
    required String status,
    required String note,
    String matchTime = '',
  }) async {
    if (match.teamAId.isEmpty || match.teamBId.isEmpty) {
      throw Exception('Match дээр хоёр багийг эхлээд онооно уу');
    }
    if (winnerTeamId != match.teamAId && winnerTeamId != match.teamBId) {
      throw Exception('Winner нь энэ match-ийн баг байх ёстой');
    }

    final loserTeamId =
        winnerTeamId == match.teamAId ? match.teamBId : match.teamAId;
    final winnerTeamName =
        winnerTeamId == match.teamAId ? match.teamAName : match.teamBName;
    final loserTeamName =
        loserTeamId == match.teamAId ? match.teamAName : match.teamBName;
    final resultData = {
      'competitionId': match.competitionId,
      'matchId': match.id,
      'round': match.round,
      'matchNo': match.matchNo,
      'winnerTeamId': winnerTeamId,
      'winnerTeamName': winnerTeamName,
      'loserTeamId': loserTeamId,
      'loserTeamName': loserTeamName,
      'score': score,
      'status': status,
      'note': note,
      if (matchTime.isNotEmpty) 'matchTime': matchTime,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _matches.doc(match.id).set(resultData, SetOptions(merge: true));
    await _matchResults.doc(match.id).set({
      ...resultData,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _writeResultForTeam(
      match.teamAId,
      match,
      winnerTeamId,
      score,
      status,
      matchTime.isNotEmpty ? matchTime : match.matchTime,
    );
    await _writeResultForTeam(
      match.teamBId,
      match,
      winnerTeamId,
      score,
      status,
      matchTime.isNotEmpty ? matchTime : match.matchTime,
    );
    await _advanceWinnerToNextRound(match, winnerTeamId, winnerTeamName);
  }

  static Future<void> _removeDeletedMatchFromTeam(
    String teamId,
    BracketMatch match,
  ) async {
    if (teamId.isEmpty) return;
    final teamDoc = await _teams.doc(teamId).get();
    if (!teamDoc.exists) return;
    final team = CompetitionTeam.fromDoc(teamDoc);
    final summary = 'Round ${match.round} / Match ${match.matchNo}';

    for (final memberId in team.memberIds) {
      final registeredId = '${match.competitionId}_$memberId';
      final registeredDoc = await _registered.doc(registeredId).get();
      if (!registeredDoc.exists) continue;

      final data = registeredDoc.data() as Map<String, dynamic>;
      final history = (data['matchHistory'] as List<dynamic>? ?? [])
          .where((item) {
            if (item is Map && item['matchId'] == match.id) return false;
            return true;
          })
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
          .toList();
      final shouldClearProgress = (data['bracketSummary'] ?? '') == summary;
      final shouldClearResult = (data['matchResult'] ?? '')
          .toString()
          .startsWith('Match ${match.matchNo}:');

      await _registered.doc(registeredId).set({
        'matchHistory': history,
        if (shouldClearProgress) 'currentRound': '',
        if (shouldClearProgress) 'nextOpponent': '',
        if (shouldClearProgress) 'matchTime': '',
        if (shouldClearProgress) 'bracketSummary': '',
        if (shouldClearResult) 'matchResult': '',
        if (shouldClearResult) 'resultStatus': '',
        if (shouldClearResult) 'score': '',
        if (shouldClearResult) 'tournamentStatus': 'Active',
        if (shouldClearResult) 'registrationStatus': 'Registered',
        if (shouldClearResult) 'eliminatedRound': '',
        if (shouldClearResult) 'finalResult': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> _clearAdvancedSlotFromDeletedMatch(
    BracketMatch match,
  ) async {
    if (match.winnerTeamId.isEmpty) return;
    final nextRound = match.round + 1;
    final nextMatchNo = ((match.matchNo - 1) ~/ 2) + 1;
    final snap =
        await _matches.where('competitionId', isEqualTo: match.competitionId).get();

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['round'] ?? 1) != nextRound ||
          (data['matchNo'] ?? 1) != nextMatchNo) {
        continue;
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if ((data['teamAId'] ?? '') == match.winnerTeamId) {
        updates.addAll({'teamAId': '', 'teamAName': ''});
      }
      if ((data['teamBId'] ?? '') == match.winnerTeamId) {
        updates.addAll({'teamBId': '', 'teamBName': ''});
      }
      if (updates.length > 1) {
        await doc.reference.set(updates, SetOptions(merge: true));
      }
    }
  }

  static Future<void> _writeResultForTeam(
    String teamId,
    BracketMatch match,
    String winnerTeamId,
    String score,
    String status,
    String matchTime,
  ) async {
    if (teamId.isEmpty) return;
    final teamDoc = await _teams.doc(teamId).get();
    if (!teamDoc.exists) return;
    final team = CompetitionTeam.fromDoc(teamDoc);
    final resultStatus = teamId == winnerTeamId ? 'Won' : 'Lost';
    final opponentName = teamId == match.teamAId ? match.teamBName : match.teamAName;
    final isEliminated = resultStatus == 'Lost';
    final historyItem = {
      'matchId': match.id,
      'round': match.round,
      'matchNo': match.matchNo,
      'opponentTeam': opponentName,
      'score': score,
      'result': resultStatus,
      'status': status,
      'matchTime': matchTime,
      'updatedAt': Timestamp.now(),
    };
    for (final memberId in team.memberIds) {
      await _upsertRegisteredCompetition(
        userId: memberId,
        competitionId: team.competitionId,
        competitionTitle: team.competitionTitle,
        category: team.sportCategory,
        date: team.competitionDate,
        location: team.competitionLocation,
        teamId: team.id,
        teamName: team.name,
        participationType: 'Team',
        status: isEliminated ? 'Archived' : 'Active',
        matchResult: 'Match ${match.matchNo}: $status',
        resultStatus: resultStatus,
        score: score,
        tournamentStatus: isEliminated ? 'Eliminated' : 'Active',
        currentRound: 'Round ${match.round}',
        nextOpponent: isEliminated ? '' : 'TBD',
        matchTime: matchTime,
        bracketSummary: 'Round ${match.round} / Match ${match.matchNo}',
        eliminatedRound: isEliminated ? 'Round ${match.round}' : '',
        finalResult: isEliminated ? 'Eliminated by $opponentName' : 'Advanced',
        matchHistoryItem: historyItem,
      );
    }
  }

  static Future<void> _advanceWinnerToNextRound(
    BracketMatch match,
    String winnerTeamId,
    String winnerTeamName,
  ) async {
    final nextRound = match.round + 1;
    final nextMatchNo = ((match.matchNo - 1) ~/ 2) + 1;
    final slotA = match.matchNo.isOdd;

    final existingMatches =
        await _matches.where('competitionId', isEqualTo: match.competitionId).get();
    QueryDocumentSnapshot? existingDoc;
    for (final doc in existingMatches.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['round'] ?? 1) == nextRound &&
          (data['matchNo'] ?? 1) == nextMatchNo) {
        existingDoc = doc;
        break;
      }
    }

    final data = {
      'competitionId': match.competitionId,
      'round': nextRound,
      'matchNo': nextMatchNo,
      if (slotA) 'teamAId': winnerTeamId,
      if (slotA) 'teamAName': winnerTeamName,
      if (!slotA) 'teamBId': winnerTeamId,
      if (!slotA) 'teamBName': winnerTeamName,
      'status': 'Scheduled',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final DocumentReference ref;
    if (existingDoc == null) {
      ref = await _matches.add({
        ...data,
        if (slotA) 'teamBId': '',
        if (slotA) 'teamBName': '',
        if (!slotA) 'teamAId': '',
        if (!slotA) 'teamAName': '',
        'winnerTeamId': '',
        'loserTeamId': '',
        'score': '',
        'note': '',
        'matchTime': '',
      });
    } else {
      ref = existingDoc.reference;
      await ref.set(data, SetOptions(merge: true));
    }

    final nextSnap = await ref.get();
    final nextMatch = BracketMatch.fromDoc(nextSnap);
    final winnerTeamDoc = await _teams.doc(winnerTeamId).get();
    if (!winnerTeamDoc.exists) return;
    final winnerTeam = CompetitionTeam.fromDoc(winnerTeamDoc);
    final opponentName =
        winnerTeamId == nextMatch.teamAId ? nextMatch.teamBName : nextMatch.teamAName;
    final opponentTeamId =
        winnerTeamId == nextMatch.teamAId ? nextMatch.teamBId : nextMatch.teamAId;
    for (final memberId in winnerTeam.memberIds) {
      await _upsertRegisteredCompetition(
        userId: memberId,
        competitionId: winnerTeam.competitionId,
        competitionTitle: winnerTeam.competitionTitle,
        category: winnerTeam.sportCategory,
        date: winnerTeam.competitionDate,
        location: winnerTeam.competitionLocation,
        teamId: winnerTeam.id,
        teamName: winnerTeam.name,
        participationType: 'Team',
        status: 'Active',
        tournamentStatus: 'Active',
        currentRound: 'Round $nextRound',
        nextOpponent: opponentName.isEmpty ? 'TBD' : opponentName,
        bracketSummary: 'Round $nextRound / Match $nextMatchNo',
      );
      await _notify(
        memberId,
        'Bracket updated',
        '${winnerTeam.name} Round $nextRound руу шалгарлаа. Next opponent: ${opponentName.isEmpty ? 'TBD' : opponentName}.',
        'bracket_update',
      );
    }

    if (opponentTeamId.isNotEmpty) {
      final opponentTeamDoc = await _teams.doc(opponentTeamId).get();
      if (opponentTeamDoc.exists) {
        final opponentTeam = CompetitionTeam.fromDoc(opponentTeamDoc);
        for (final memberId in opponentTeam.memberIds) {
          await _upsertRegisteredCompetition(
            userId: memberId,
            competitionId: opponentTeam.competitionId,
            competitionTitle: opponentTeam.competitionTitle,
            category: opponentTeam.sportCategory,
            date: opponentTeam.competitionDate,
            location: opponentTeam.competitionLocation,
            teamId: opponentTeam.id,
            teamName: opponentTeam.name,
            participationType: 'Team',
            status: 'Active',
            tournamentStatus: 'Active',
            currentRound: 'Round $nextRound',
            nextOpponent: winnerTeamName,
            bracketSummary: 'Round $nextRound / Match $nextMatchNo',
          );
          await _notify(
            memberId,
            'Next match updated',
            '${opponentTeam.name} багийн next opponent: $winnerTeamName.',
            'next_match',
          );
        }
      }
    }
  }

  static Future<void> _syncMatchParticipants(BracketMatch match) async {
    if (match.teamAId.isNotEmpty) {
      final teamDoc = await _teams.doc(match.teamAId).get();
      if (teamDoc.exists) {
        await _syncBracketAssignmentForTeam(
          team: CompetitionTeam.fromDoc(teamDoc),
          match: match,
          slotA: true,
        );
      }
    }
    if (match.teamBId.isNotEmpty) {
      final teamDoc = await _teams.doc(match.teamBId).get();
      if (teamDoc.exists) {
        await _syncBracketAssignmentForTeam(
          team: CompetitionTeam.fromDoc(teamDoc),
          match: match,
          slotA: false,
        );
      }
    }
  }

  static Future<void> _syncBracketAssignmentForTeam({
    required CompetitionTeam team,
    required BracketMatch match,
    required bool slotA,
  }) async {
    final opponentName = slotA ? match.teamBName : match.teamAName;
    for (final memberId in team.memberIds) {
      await _upsertRegisteredCompetition(
        userId: memberId,
        competitionId: team.competitionId,
        competitionTitle: team.competitionTitle,
        category: team.sportCategory,
        date: team.competitionDate,
        location: team.competitionLocation,
        teamId: team.id,
        teamName: team.name,
        participationType: 'Team',
        status: 'Active',
        tournamentStatus: 'Active',
        currentRound: 'Round ${match.round}',
        nextOpponent: opponentName.isEmpty ? 'TBD' : opponentName,
        matchTime: match.matchTime,
        bracketSummary: 'Round ${match.round} / Match ${match.matchNo}',
      );
      await _notify(
        memberId,
        'Bracket updated',
        '${team.name} баг Round ${match.round}, Match ${match.matchNo} дээр оноогдлоо.',
        'bracket_update',
      );
    }
  }

  static Future<void> _upsertRegisteredCompetition({
    required String userId,
    required String competitionId,
    required String competitionTitle,
    required String category,
    required String date,
    required String location,
    required String teamId,
    required String teamName,
    required String participationType,
    required String status,
    String matchResult = '',
    String resultStatus = '',
    String score = '',
    String tournamentStatus = '',
    String currentRound = '',
    String nextOpponent = '',
    String matchTime = '',
    String bracketSummary = '',
    String eliminatedRound = '',
    String finalResult = '',
    Map<String, dynamic>? matchHistoryItem,
  }) async {
    final id = '${competitionId}_$userId';
    await _registered.doc(id).set({
      'userId': userId,
      'competitionId': competitionId,
      'competitionTitle': competitionTitle,
      'category': category,
      if (date.isNotEmpty) 'date': date,
      if (location.isNotEmpty) 'location': location,
      'registrationStatus': status,
      'teamId': teamId,
      'teamName': teamName,
      'participationType': participationType,
      if (tournamentStatus.isNotEmpty) 'tournamentStatus': tournamentStatus,
      if (currentRound.isNotEmpty) 'currentRound': currentRound,
      if (nextOpponent.isNotEmpty) 'nextOpponent': nextOpponent,
      if (matchTime.isNotEmpty) 'matchTime': matchTime,
      if (bracketSummary.isNotEmpty) 'bracketSummary': bracketSummary,
      if (eliminatedRound.isNotEmpty) 'eliminatedRound': eliminatedRound,
      if (finalResult.isNotEmpty) 'finalResult': finalResult,
      if (matchResult.isNotEmpty) 'matchResult': matchResult,
      if (resultStatus.isNotEmpty) 'resultStatus': resultStatus,
      if (score.isNotEmpty) 'score': score,
      if (matchHistoryItem != null)
        'matchHistory': FieldValue.arrayUnion([matchHistoryItem]),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeMember(CompetitionTeam team, String memberUid) async {
    final user = _auth.currentUser;
    if (user == null || team.leaderId != user.uid) {
      throw Exception('Зөвхөн багийн ахлагч гишүүн хасах боломжтой');
    }
    if (memberUid == team.leaderId) {
      throw Exception('Багийн ахлагчийг хасах боломжгүй');
    }

    final members = team.members.where((m) => m.uid != memberUid).toList();
    final memberIds = team.memberIds.where((id) => id != memberUid).toList();
    await _teams.doc(team.id).update({
      'members': members.map((m) => m.toMap()).toList(),
      'memberIds': memberIds,
    });
    await _registered.doc('${team.competitionId}_$memberUid').set({
      'registrationStatus': 'Removed',
      'teamId': '',
      'teamName': '',
      'participationType': 'Team',
      'removedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _notify(
      memberUid,
      'Багаас хасагдлаа',
      '${team.name} багаас таныг хассан байна.',
      'member_removed',
    );
  }

  static Future<void> _notify(
    String userId,
    String title,
    String body,
    String type,
  ) async {
    await _notifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
