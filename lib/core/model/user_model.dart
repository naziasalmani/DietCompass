/// DietCompass — Authenticated User Domain Model
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone = '',
    this.countryCode = '+91',
    this.accountType = 'individual',
    this.avatarUrl = '',
    this.isEmailVerified = false,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String countryCode;
  final String accountType;
  final String avatarUrl;
  final bool isEmailVerified;
  final DateTime? createdAt;

  /// Parse from backend JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '+91',
      accountType: json['accountType']?.toString() ?? 'individual',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      isEmailVerified: json['isEmailVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Serialize to JSON for local persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'countryCode': countryCode,
      'accountType': accountType,
      'avatarUrl': avatarUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? countryCode,
    String? accountType,
    String? avatarUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      accountType: accountType ?? this.accountType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Holds Access and Refresh Token pair returned from backend
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
    };
  }
}

/// Standardized Authentication Operation Result
class AuthResult {
  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.tokens,
    this.statusCode,
  });

  final bool success;
  final String? message;
  final UserModel? user;
  final AuthTokens? tokens;
  final int? statusCode;

  factory AuthResult.success({
    UserModel? user,
    AuthTokens? tokens,
    String? message,
  }) {
    return AuthResult(
      success: true,
      user: user,
      tokens: tokens,
      message: message,
      statusCode: 200,
    );
  }

  factory AuthResult.failure({
    required String message,
    int? statusCode,
  }) {
    return AuthResult(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
