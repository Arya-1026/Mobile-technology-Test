import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String photoUrl;
  final String phone;
  final String registerNumber;
  final bool canCreateCompetition;
  final List<String> friends;

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
  final String status; // pending | approved | rejected
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? createdAt;

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
    this.registrationStart,
    this.registrationEnd,
    this.createdAt,
  });

  String get date {
    if (registrationStart == null || registrationEnd == null)
      return 'Огноо оруулаагүй';
    return '${registrationStart!.year}.${registrationStart!.month}.${registrationStart!.day} - ${registrationEnd!.year}.${registrationEnd!.month}.${registrationEnd!.day}';
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
      registrationStart: toDate(data['registrationStart']),
      registrationEnd: toDate(data['registrationEnd']),
      createdAt: toDate(data['createdAt']),
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
      'registrationStart': registrationStart == null
          ? null
          : Timestamp.fromDate(registrationStart!),
      'registrationEnd': registrationEnd == null
          ? null
          : Timestamp.fromDate(registrationEnd!),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }
}
