import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

class CompetitionService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference get _col => _db.collection('competitions');

  static Stream<List<CompetitionItem>> approvedCompetitions({String? category}) {
    Query query = _col.where('status', isEqualTo: 'approved');
    if (category != null && category != 'Бүгд') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((s) => s.docs.map((d) => CompetitionItem.fromDoc(d)).toList());
  }

  static Stream<List<CompetitionItem>> allCompetitions() {
    return _col.snapshots().map((s) => s.docs.map((d) => CompetitionItem.fromDoc(d)).toList());
  }

  static Stream<List<CompetitionItem>> myCompetitions() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _col.where('ownerId', isEqualTo: uid).snapshots().map((s) => s.docs.map((d) => CompetitionItem.fromDoc(d)).toList());
  }

  static Future<void> addCompetition(CompetitionItem item) async {
    await _col.add(item.toMap());
  }

  static Future<void> updateCompetition(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  static Future<void> deleteCompetition(String id) async {
    await _col.doc(id).delete();
  }

  static Future<void> changeStatus(String id, String status) async {
    await _col.doc(id).update({'status': status});
  }

  static Future<void> registerToCompetition(CompetitionItem item, {List<TeamMember> team = const []}) async {
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
