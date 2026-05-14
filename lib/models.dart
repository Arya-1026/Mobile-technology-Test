import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'viewer' | 'admin'
  final String photoUrl;
  final String phone;
  final String registerNumber;
  final bool canCreateCompetition;
  final List<String> friends;
  final List<String> sportPreferences;
  final String activeRole; // 'participant' | 'organizer'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
    this.phone = '',
    this.registerNumber = '',
    this.canCreateCompetition = false,
    this.friends = const [],
    this.sportPreferences = const [],
    this.activeRole = 'participant',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'viewer',
      photoUrl: data['photoUrl'] ?? '',
      phone: data['phone'] ?? '',
      registerNumber: data['registerNumber'] ?? '',
      canCreateCompetition: data['canCreateCompetition'] ?? false,
      friends: List<String>.from(data['friends'] ?? []),
      sportPreferences: List<String>.from(data['sportPreferences'] ?? []),
      activeRole: data['activeRole'] ?? 'participant',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'phone': phone,
      'registerNumber': registerNumber,
      'canCreateCompetition': canCreateCompetition,
      'friends': friends,
      'sportPreferences': sportPreferences,
      'activeRole': activeRole,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TeamMember {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String position;

  TeamMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.position = 'Member',
  });

  factory TeamMember.fromMap(Map<String, dynamic> data) {
    return TeamMember(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      position: data['position'] ?? 'Member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'position': position,
    };
  }
}

class CompetitionTeam {
  final String id;
  final String competitionId;
  final String competitionTitle;
  final String sportCategory;
  final String competitionDate;
  final String competitionLocation;
  final String name;
  final String description;
  final String logoUrl;
  final String leaderId;
  final String leaderName;
  final String leaderEmail;
  final int maxMembers;
  final List<String> memberIds;
  final List<TeamMember> members;
  final DateTime? createdAt;

  CompetitionTeam({
    required this.id,
    required this.competitionId,
    required this.competitionTitle,
    required this.sportCategory,
    this.competitionDate = '',
    this.competitionLocation = '',
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.leaderId,
    required this.leaderName,
    required this.leaderEmail,
    required this.maxMembers,
    required this.memberIds,
    required this.members,
    this.createdAt,
  });

  factory CompetitionTeam.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompetitionTeam(
      id: doc.id,
      competitionId: data['competitionId'] ?? '',
      competitionTitle: data['competitionTitle'] ?? '',
      sportCategory: data['sportCategory'] ?? '',
      competitionDate: data['competitionDate'] ?? '',
      competitionLocation: data['competitionLocation'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      leaderId: data['leaderId'] ?? '',
      leaderName: data['leaderName'] ?? '',
      leaderEmail: data['leaderEmail'] ?? '',
      maxMembers: (data['maxMembers'] ?? 5) as int,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: (data['members'] as List<dynamic>? ?? [])
          .map((e) => TeamMember.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class TeamInvite {
  final String id;
  final String teamId;
  final String teamName;
  final String competitionId;
  final String competitionTitle;
  final String sportCategory;
  final String leaderId;
  final String leaderName;
  final String toUid;
  final String toEmail;
  final String toName;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  TeamInvite({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.competitionId,
    required this.competitionTitle,
    required this.sportCategory,
    required this.leaderId,
    required this.leaderName,
    required this.toUid,
    required this.toEmail,
    required this.toName,
    required this.status,
    this.expiresAt,
    this.createdAt,
  });

  factory TeamInvite.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamInvite(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      competitionId: data['competitionId'] ?? '',
      competitionTitle: data['competitionTitle'] ?? '',
      sportCategory: data['sportCategory'] ?? '',
      leaderId: data['leaderId'] ?? '',
      leaderName: data['leaderName'] ?? '',
      toUid: data['toUid'] ?? '',
      toEmail: data['toEmail'] ?? '',
      toName: data['toName'] ?? '',
      status: data['status'] ?? 'Pending',
      expiresAt: data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class RegisteredCompetition {
  final String id;
  final String userId;
  final String competitionId;
  final String competitionTitle;
  final String category;
  final String date;
  final String location;
  final String registrationStatus;
  final String teamId;
  final String teamName;
  final String participationType;
  final String matchResult;
  final String resultStatus;
  final String score;
  final String tournamentStatus;
  final String currentRound;
  final String nextOpponent;
  final String matchTime;
  final String bracketSummary;
  final String eliminatedRound;
  final String finalResult;
  final List<Map<String, dynamic>> matchHistory;
  final DateTime? createdAt;

  RegisteredCompetition({
    required this.id,
    required this.userId,
    required this.competitionId,
    required this.competitionTitle,
    required this.category,
    required this.date,
    required this.location,
    required this.registrationStatus,
    required this.teamId,
    required this.teamName,
    required this.participationType,
    this.matchResult = '',
    this.resultStatus = '',
    this.score = '',
    this.tournamentStatus = 'Active',
    this.currentRound = '',
    this.nextOpponent = '',
    this.matchTime = '',
    this.bracketSummary = '',
    this.eliminatedRound = '',
    this.finalResult = '',
    this.matchHistory = const [],
    this.createdAt,
  });

  factory RegisteredCompetition.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegisteredCompetition(
      id: doc.id,
      userId: data['userId'] ?? '',
      competitionId: data['competitionId'] ?? '',
      competitionTitle: data['competitionTitle'] ?? '',
      category: data['category'] ?? '',
      date: data['date'] ?? '',
      location: data['location'] ?? '',
      registrationStatus: data['registrationStatus'] ?? 'Registered',
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      participationType: data['participationType'] ?? 'Individual',
      matchResult: data['matchResult'] ?? '',
      resultStatus: data['resultStatus'] ?? '',
      score: data['score'] ?? '',
      tournamentStatus: data['tournamentStatus'] ?? 'Active',
      currentRound: data['currentRound'] ?? '',
      nextOpponent: data['nextOpponent'] ?? '',
      matchTime: data['matchTime'] ?? '',
      bracketSummary: data['bracketSummary'] ?? '',
      eliminatedRound: data['eliminatedRound'] ?? '',
      finalResult: data['finalResult'] ?? '',
      matchHistory: (data['matchHistory'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class BracketMatch {
  final String id;
  final String competitionId;
  final int round;
  final int matchNo;
  final String teamAId;
  final String teamAName;
  final String teamBId;
  final String teamBName;
  final String winnerTeamId;
  final String loserTeamId;
  final String score;
  final String status;
  final String note;
  final String matchTime;
  final DateTime? updatedAt;

  BracketMatch({
    required this.id,
    required this.competitionId,
    required this.round,
    required this.matchNo,
    required this.teamAId,
    required this.teamAName,
    required this.teamBId,
    required this.teamBName,
    this.winnerTeamId = '',
    this.loserTeamId = '',
    this.score = '',
    this.status = 'Scheduled',
    this.note = '',
    this.matchTime = '',
    this.updatedAt,
  });

  factory BracketMatch.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BracketMatch(
      id: doc.id,
      competitionId: data['competitionId'] ?? '',
      round: (data['round'] ?? 1) as int,
      matchNo: (data['matchNo'] ?? 1) as int,
      teamAId: data['teamAId'] ?? '',
      teamAName: data['teamAName'] ?? '',
      teamBId: data['teamBId'] ?? '',
      teamBName: data['teamBName'] ?? '',
      winnerTeamId: data['winnerTeamId'] ?? '',
      loserTeamId: data['loserTeamId'] ?? '',
      score: data['score'] ?? '',
      status: data['status'] ?? 'Scheduled',
      note: data['note'] ?? '',
      matchTime: data['matchTime'] ?? '',
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class MatchResult {
  final String id;
  final String competitionId;
  final String matchId;
  final int round;
  final int matchNo;
  final String winnerTeamId;
  final String winnerTeamName;
  final String loserTeamId;
  final String loserTeamName;
  final String score;
  final String status;
  final String note;
  final DateTime? updatedAt;

  MatchResult({
    required this.id,
    required this.competitionId,
    required this.matchId,
    required this.round,
    required this.matchNo,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.loserTeamId,
    required this.loserTeamName,
    required this.score,
    required this.status,
    required this.note,
    this.updatedAt,
  });

  factory MatchResult.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchResult(
      id: doc.id,
      competitionId: data['competitionId'] ?? '',
      matchId: data['matchId'] ?? '',
      round: (data['round'] ?? 1) as int,
      matchNo: (data['matchNo'] ?? 1) as int,
      winnerTeamId: data['winnerTeamId'] ?? '',
      winnerTeamName: data['winnerTeamName'] ?? '',
      loserTeamId: data['loserTeamId'] ?? '',
      loserTeamName: data['loserTeamName'] ?? '',
      score: data['score'] ?? '',
      status: data['status'] ?? '',
      note: data['note'] ?? '',
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class TeamNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;

  TeamNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.createdAt,
  });

  factory TeamNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      read: data['read'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

class CompetitionItem {
  final String id;
  final String title;
  final String subtitle;
  final String fullDescription;
  final String category;
  final List<String> tags;
  final String scope;
  final String participationType;
  final String organizerType;
  final String organizationName;
  final String fee;
  final String materials;
  final String imageUrl;
  final String posterUrl;
  final String linkText;
  final String ownerId;
  final String ownerEmail;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String rejectionReason;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? registrationDeadline;
  final DateTime? createdAt;
  // New fields
  final String location;
  final String ageCategory;
  final int maxParticipants;
  final int maxTeamMembers;
  final String genderCategory;
  final String prizes;
  final String rules;
  final String contactInfo;

  CompetitionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fullDescription,
    required this.category,
    required this.tags,
    required this.scope,
    required this.participationType,
    required this.organizerType,
    required this.organizationName,
    required this.fee,
    required this.materials,
    required this.imageUrl,
    required this.posterUrl,
    required this.linkText,
    required this.ownerId,
    required this.ownerEmail,
    required this.status,
    this.rejectionReason = '',
    this.registrationStart,
    this.registrationEnd,
    this.registrationDeadline,
    this.createdAt,
    this.location = '',
    this.ageCategory = 'Бүх насны',
    this.maxParticipants = 0,
    this.maxTeamMembers = 5,
    this.genderCategory = 'Бүх хүйс',
    this.prizes = '',
    this.rules = '',
    this.contactInfo = '',
  });

  String get date {
    if (registrationStart == null || registrationEnd == null) {
      return 'Огноо оруулаагүй';
    }
    return '${registrationStart!.year}.${registrationStart!.month.toString().padLeft(2, '0')}.${registrationStart!.day.toString().padLeft(2, '0')} - ${registrationEnd!.year}.${registrationEnd!.month.toString().padLeft(2, '0')}.${registrationEnd!.day.toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Нийтлэгдсэн';
      case 'rejected':
        return 'Татгалзсан';
      default:
        return 'Хүлээгдэж байна';
    }
  }

  String get displayImageUrl => imageUrl.isNotEmpty ? imageUrl : posterUrl;
  String get displayPosterUrl => posterUrl.isNotEmpty ? posterUrl : imageUrl;

  factory CompetitionItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? toDate(dynamic value) =>
        value is Timestamp ? value.toDate() : null;
    String firstString(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    return CompetitionItem(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      fullDescription: data['fullDescription'] ?? data['description'] ?? '',
      category: data['category'] ?? 'Багийн',
      tags: List<String>.from(data['tags'] ?? []),
      scope: data['scope'] ?? '',
      participationType: data['participationType'] ?? '',
      organizerType: data['organizerType'] ?? 'Хувь хүн',
      organizationName: data['organizationName'] ?? '',
      fee: data['fee'] ?? '',
      materials: data['materials'] ?? '',
      imageUrl: firstString([
        'imageUrl',
        'imageURL',
        'image',
        'coverUrl',
        'coverImage',
        'thumbnailUrl',
        'photoUrl',
      ]),
      posterUrl: firstString([
        'posterUrl',
        'posterURL',
        'poster',
        'posterImageUrl',
        'bannerUrl',
      ]),
      linkText: data['linkText'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'] ?? '',
      registrationStart: toDate(data['registrationStart']),
      registrationEnd: toDate(data['registrationEnd']),
      registrationDeadline: toDate(data['registrationDeadline']),
      createdAt: toDate(data['createdAt']),
      location: data['location'] ?? '',
      ageCategory: data['ageCategory'] ?? 'Бүх насны',
      maxParticipants: (data['maxParticipants'] ?? 0) as int,
      maxTeamMembers: (data['maxTeamMembers'] ?? 5) as int,
      genderCategory: data['genderCategory'] ?? 'Бүх хүйс',
      prizes: data['prizes'] ?? '',
      rules: data['rules'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'fullDescription': fullDescription,
      'category': category,
      'tags': tags,
      'scope': scope,
      'participationType': participationType,
      'organizerType': organizerType,
      'organizationName': organizationName,
      'fee': fee,
      'materials': materials,
      'imageUrl': imageUrl,
      'posterUrl': posterUrl,
      'coverUrl': imageUrl,
      'thumbnailUrl': imageUrl,
      'linkText': linkText,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'status': status,
      'rejectionReason': rejectionReason,
      'registrationStart': registrationStart == null
          ? null
          : Timestamp.fromDate(registrationStart!),
      'registrationEnd': registrationEnd == null
          ? null
          : Timestamp.fromDate(registrationEnd!),
      'registrationDeadline': registrationDeadline == null
          ? null
          : Timestamp.fromDate(registrationDeadline!),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'location': location,
      'ageCategory': ageCategory,
      'maxParticipants': maxParticipants,
      'maxTeamMembers': maxTeamMembers,
      'genderCategory': genderCategory,
      'prizes': prizes,
      'rules': rules,
      'contactInfo': contactInfo,
    };
  }
}

class ParticipationRequest {
  final String id;
  final String competitionId;
  final String competitionTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhotoUrl;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String rejectionReason;
  final DateTime? createdAt;

  ParticipationRequest({
    required this.id,
    required this.competitionId,
    required this.competitionTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl = '',
    required this.status,
    this.rejectionReason = '',
    this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'Зөвшөөрөгдсөн';
      case 'rejected':
        return 'Татгалзсан';
      default:
        return 'Хүлээгдэж байна';
    }
  }

  factory ParticipationRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParticipationRequest(
      id: doc.id,
      competitionId: data['competitionId'] ?? '',
      competitionTitle: data['competitionTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'competitionId': competitionId,
      'competitionTitle': competitionTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class OrganizerRequest {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String rejectionReason;
  final DateTime? createdAt;

  OrganizerRequest({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.status,
    this.rejectionReason = '',
    this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'Зөвшөөрөгдсөн';
      case 'rejected':
        return 'Татгалзсан';
      default:
        return 'Хүлээгдэж байна';
    }
  }

  factory OrganizerRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganizerRequest(
      id: doc.id,
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
