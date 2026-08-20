/// DietCompass — AuthUser model
///
/// Immutable snapshot of the authenticated user returned by the backend.
/// Matches the shape of [User.toJSON()] from the Express server:
///   { _id, fullName, username, email, phone, countryCode, accountType }
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.accountType,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String countryCode;
  final String accountType;

  /// Parse from the backend JSON object (data.user field).
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '+91',
      accountType: json['accountType'] as String? ?? 'individual',
    );
  }

  /// Display name helper — falls back to username then email local part.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return email.split('@').first;
  }

  /// First character of the display name, upper-cased (for avatar initials).
  String get avatarInitial {
    final n = displayName;
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  String toString() =>
      'AuthUser(id: $id, username: $username, email: $email)';
}
