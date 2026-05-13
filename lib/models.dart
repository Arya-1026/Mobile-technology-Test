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

  TeamMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  factory TeamMember.fromMap(Map<String, dynamic> data) {
    return TeamMember(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'email': email, 'photoUrl': photoUrl};
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

  factory CompetitionItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? toDate(dynamic value) =>
        value is Timestamp ? value.toDate() : null;

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
      imageUrl: data['imageUrl'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
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
