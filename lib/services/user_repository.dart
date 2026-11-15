import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

/// Reads and manages the crew's profiles in `users/{uid}`.
///
/// The very first account that signs in claims the admin role, once, guarded
/// by the `meta/admin` document and the Firestore rules. The admin then adds
/// the workers.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  static const _creatorAppName = 'userCreator';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  DocumentReference<Map<String, dynamic>> get _adminMarker =>
      _db.doc('meta/admin');

  /// Emits null while the signed-in account has no profile yet.
  Stream<AppUser?> watchProfile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Everyone, the admin first, then by name.
  Stream<List<AppUser>> watchAll() => _users.snapshots().map((snap) {
    final list = snap.docs.map(AppUser.fromDoc).toList();
    list.sort((a, b) {
      if (a.role != b.role) return a.role.index.compareTo(b.role.index);
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return list;
  });

  /// True when nobody has claimed the admin role yet. Asks the server: the
  /// cache of a fresh install knows nothing.
  Future<bool> canClaimAdmin() async {
    final marker = await _adminMarker.get(
      const GetOptions(source: Source.server),
    );
    return !marker.exists;
  }

  /// Makes [user] the admin. Fails (permission denied) if already claimed.
  Future<void> claimAdmin(
    User user, {
    required String firstName,
    required String lastName,
  }) async {
    final profile = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: UserRole.admin,
      disabled: false,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    final batch = _db.batch()
      ..set(_users.doc(user.uid), profile.toNewDocMap())
      ..set(_adminMarker, {'uid': user.uid});
    await batch.commit();
  }

  /// Creates a Firebase Auth account plus its profile, without signing the
  /// admin out: a secondary Firebase app does the sign-up, so the main app
  /// keeps its session. If the profile cannot be written, the new account is
  /// deleted again, or its email would stay taken with nobody behind it.
  Future<void> createWorker({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final app = await _creatorApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = AppUser(
        uid: cred.user!.uid,
        email: email.trim(),
        role: UserRole.worker,
        disabled: false,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
      );
      try {
        await _users.doc(profile.uid).set(profile.toNewDocMap());
      } catch (_) {
        await cred.user!.delete().catchError((Object _) {});
        rethrow;
      }
    } finally {
      await auth.signOut();
    }
  }

  Future<void> updateProfile(
    String uid, {
    required String firstName,
    required String lastName,
    required String phone,
  }) => _users.doc(uid).update({
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'phone': phone.trim(),
  });

  /// Switching a worker off or back on. Their records stay either way.
  Future<void> setDisabled(String uid, bool disabled) =>
      _users.doc(uid).update({'disabled': disabled});

  Future<FirebaseApp> _creatorApp() async {
    for (final app in Firebase.apps) {
      if (app.name == _creatorAppName) return app;
    }
    return Firebase.initializeApp(
      name: _creatorAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
