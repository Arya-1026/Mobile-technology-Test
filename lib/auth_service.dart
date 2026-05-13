import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'models.dart';
import 'team_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await _createUserIfNotExists(user);
        await TeamService.linkPendingEmailInvites(user);
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw Exception('Google-р нэвтрэхэд алдаа гарлаа: ${e.description}');
    } catch (e) {
      throw Exception('Google-р нэвтрэхэд алдаа гарлаа: $e');
    }
  }

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    List<String> sportPreferences = const [],
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user == null) return 'Хэрэглэгч үүсгэхэд алдаа гарлаа';

      await user.updateDisplayName(name);

      final appUser = AppUser(
        uid: user.uid,
        name: name,
        email: email,
        photoUrl: '',
        role: 'viewer',
        phone: '',
        registerNumber: '',
        canCreateCompetition: false,
        sportPreferences: sportPreferences,
        activeRole: 'participant',
      );

      await _db.collection('users').doc(user.uid).set(appUser.toMap());
      await TeamService.linkPendingEmailInvites(user);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Бүртгэл амжилтгүй боллоо';
    } catch (e) {
      return 'Бүртгэл амжилтгүй боллоо: $e';
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user != null) {
        await _createUserIfNotExists(user);
        await TeamService.linkPendingEmailInvites(user);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Нэвтрэлт амжилтгүй боллоо';
    } catch (e) {
      return 'Нэвтрэлт амжилтгүй боллоо: $e';
    }
  }

  static Future<AppUser?> getCurrentAppUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromMap(doc.id, doc.data()!);
  }

  static Future<bool> isAdmin() async {
    final AppUser? appUser = await getCurrentAppUser();
    return appUser?.role == 'admin';
  }

  static Future<void> logout() async {
    await _auth.signOut();

    try {
      await GoogleSignIn.instance.signOut().timeout(
            const Duration(seconds: 3),
          );
    } catch (_) {
      // Email/password users may not have an active Google session.
    }
  }

  static Future<void> _createUserIfNotExists(User user) async {
    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection('users').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();

    if (!userDoc.exists) {
      final appUser = AppUser(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        role: 'viewer',
        phone: '',
        registerNumber: '',
        canCreateCompetition: false,
        sportPreferences: [],
        activeRole: 'participant',
      );

      await userRef.set({
        ...appUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Нууц үг сэргээх имэйл илгээхэд алдаа гарлаа';
    } catch (e) {
      return 'Нууц үг сэргээх имэйл илгээхэд алдаа гарлаа: $e';
    }
  }
}
