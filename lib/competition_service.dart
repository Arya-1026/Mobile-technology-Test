import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class CompetitionService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference get _col => _db.collection('competitions');
  static CollectionReference get _requests =>
      _db.collection('competitionRequests');

  // ---- Competition CRUD ----

  static Stream<List<CompetitionItem>> approvedCompetitions({
    String? category,
    List<String>? preferredCategories,
  }) {
    Query query = _col.where('status', isEqualTo: 'approved');
    if (category != null && category != 'Бүгд') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((s) {
      final items =
          s.docs.map((d) => CompetitionItem.fromDoc(d)).toList();
      if (preferredCategories != null && preferredCategories.isNotEmpty) {
        items.sort((a, b) {
          final aMatch = preferredCategories.contains(a.category) ? 0 : 1;
          final bMatch = preferredCategories.contains(b.category) ? 0 : 1;
          return aMatch.compareTo(bMatch);
        });
      }
      return items;
    });
  }

  static Stream<List<CompetitionItem>> allCompetitions() {
    return _col.snapshots().map(
          (s) => s.docs.map((d) => CompetitionItem.fromDoc(d)).toList(),
        );
  }

  static Stream<List<CompetitionItem>> myCompetitions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _col
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => CompetitionItem.fromDoc(d)).toList());
  }

  static Future<void> addCompetition(CompetitionItem item) async {
    await _col.add(item.toMap());
  }

  static Future<void> updateCompetition(
      String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  static Future<void> deleteCompetition(String id) async {
    await _col.doc(id).delete();
  }

  static Future<void> changeStatus(
    String id,
    String status, {
    String rejectionReason = '',
  }) async {
    await _col.doc(id).update({
      'status': status,
      'rejectionReason': rejectionReason,
    });
  }

  // ---- Participation Requests ----

  /// Send a participation request for a competition
  static Future<void> sendParticipationRequest(CompetitionItem item) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    // Check if already requested
    final existing = await _requests
        .where('competitionId', isEqualTo: item.id)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Та энэ тэмцээнд аль хэдийн хүсэлт илгээсэн байна');
    }

    final userDoc =
        await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _requests.add({
      'competitionId': item.id,
      'competitionTitle': item.title,
      'userId': user.uid,
      'userName': userData['name'] ?? user.displayName ?? '',
      'userEmail': user.email ?? '',
      'userPhotoUrl': userData['photoUrl'] ?? user.photoURL ?? '',
      'status': 'pending',
      'rejectionReason': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get my participation requests (for participant)
  static Stream<List<ParticipationRequest>> myParticipationRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _requests
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ParticipationRequest.fromDoc(d)).toList());
  }

  /// Get requests for a specific competition (for organizer)
  static Stream<List<ParticipationRequest>> competitionParticipationRequests(
      String competitionId) {
    return _requests
        .where('competitionId', isEqualTo: competitionId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ParticipationRequest.fromDoc(d)).toList());
  }

  /// Update participation request status (accept/reject)
  static Future<void> updateParticipationRequest(
    String requestId,
    String status, {
    String rejectionReason = '',
  }) async {
    await _requests.doc(requestId).update({
      'status': status,
      'rejectionReason': rejectionReason,
    });
  }

  /// Get current user's request status for a competition
  static Future<String?> getMyRequestStatus(String competitionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap = await _requests
        .where('competitionId', isEqualTo: competitionId)
        .where('userId', isEqualTo: uid)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first['status'] as String?;
  }

  // ---- Organizer Requests ----

  static Future<void> sendOrganizerRequest() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    final userDoc =
        await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _db.collection('organizerRequests').doc(user.uid).set({
      'uid': user.uid,
      'name': userData['name'] ?? user.displayName ?? '',
      'email': user.email ?? '',
      'status': 'pending',
      'rejectionReason': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<OrganizerRequest>> allOrganizerRequests() {
    return _db
        .collection('organizerRequests')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => OrganizerRequest.fromDoc(d)).toList());
  }

  static Future<void> updateOrganizerRequest(
    String uid,
    String status, {
    String rejectionReason = '',
  }) async {
    final batch = _db.batch();

    batch.update(_db.collection('organizerRequests').doc(uid), {
      'status': status,
      'rejectionReason': rejectionReason,
    });

    if (status == 'accepted') {
      batch.update(_db.collection('users').doc(uid), {
        'canCreateCompetition': true,
      });
    } else if (status == 'rejected') {
      batch.update(_db.collection('users').doc(uid), {
        'canCreateCompetition': false,
      });
    }

    await batch.commit();
  }

  static Future<void> revokeOrganizerRole(String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'canCreateCompetition': false,
      'activeRole': 'participant',
    });
    batch.update(_db.collection('organizerRequests').doc(uid), {
      'status': 'rejected',
      'rejectionReason': 'Админ эрхийг цуцаллаа',
    });
    await batch.commit();
  }

  /// Switch user's active role
  static Future<void> switchActiveRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'activeRole': role});
  }

  // Legacy: register directly (keep for backward compat)
  static Future<void> registerToCompetition(
    CompetitionItem item, {
    List<TeamMember> team = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    await _db.collection('registrations').add({
      'competitionId': item.id,
      'competitionTitle': item.title,
      'userId': user.uid,
      'userEmail': user.email,
      'teamMembers': team.map((e) => e.toMap()).toList(),
      'result': 'Оролцсон',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
