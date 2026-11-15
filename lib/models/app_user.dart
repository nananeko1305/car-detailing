import 'package:cloud_firestore/cloud_firestore.dart';

/// admin: runs the crew, adds and removes workers, edits the price list.
/// worker: everyone else. Everybody sees everything.
enum UserRole { admin, worker }

UserRole roleFromName(String? name) =>
    name == 'admin' ? UserRole.admin : UserRole.worker;

/// Profile stored in `users/{uid}`. Decides who may use the app and who may
/// manage it.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.disabled,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
  });

  final String uid;
  final String email;
  final UserRole role;

  /// Switched off by the admin: cannot sign in to anything, records stay.
  final bool disabled;
  final String firstName;
  final String lastName;
  final String phone;

  bool get isAdmin => role == UserRole.admin;

  /// Jobs and wallet entries may be deleted only by their author or the
  /// admin; `firestore.rules` says the same.
  bool canDelete(String authorId) => isAdmin || uid == authorId;

  /// "First Last", or the email while no name is set.
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  /// "Marko", or the email while no name is set; for tight lists.
  String get shortName => firstName.trim().isEmpty ? displayName : firstName;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      role: roleFromName(data['role'] as String?),
      disabled: data['disabled'] as bool? ?? false,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
    );
  }

  /// A new profile: the fields `firestore.rules` require on create, no more.
  Map<String, dynamic> toNewDocMap() => {
    'email': email,
    'role': role.name,
    'disabled': false,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
