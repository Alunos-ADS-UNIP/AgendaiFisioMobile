enum UserRole {
  patient,
  professional,
  admin;

  static UserRole fromApi(String value) => switch (value.trim().toLowerCase()) {
    'paciente' => UserRole.patient,
    'profissional' => UserRole.professional,
    'admin' || 'administrador' => UserRole.admin,
    _ => throw const FormatException('Perfil de usuário inválido.'),
  };

  String get label => switch (this) {
    UserRole.patient => 'Paciente',
    UserRole.professional => 'Profissional',
    UserRole.admin => 'Administrador',
  };
}

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.userId,
    required this.email,
    required this.role,
    this.profileId,
  });

  final String userId;
  final String? profileId;
  final String email;
  final UserRole role;

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      userId: (json['usuarioId'] ?? json['userId']).toString(),
      profileId: (json['perfilId'] ?? json['profileId'])?.toString(),
      email: json['email']?.toString() ?? '',
      role: UserRole.fromApi(
        (json['tipoUsuario'] ?? json['role'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'usuarioId': userId,
    'perfilId': profileId,
    'email': email,
    'tipoUsuario': role.label,
  };
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAtUtc,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAtUtc;
  final AuthenticatedUser user;

  bool isExpiredAt(DateTime instant) => !expiresAtUtc.isAfter(instant.toUtc());

  factory AuthSession.fromLoginJson(Map<String, dynamic> json) {
    final token = (json['accessToken'] ?? json['token'])?.toString() ?? '';
    final expires = DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '');
    final userJson = json['usuario'];
    if (token.isEmpty || expires == null || userJson is! Map) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    return AuthSession(
      accessToken: token,
      expiresAtUtc: expires.toUtc(),
      user: AuthenticatedUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken']?.toString() ?? '',
    expiresAtUtc: DateTime.parse(json['expiresAtUtc'].toString()).toUtc(),
    user: AuthenticatedUser.fromJson(
      Map<String, dynamic>.from(json['usuario'] as Map),
    ),
  );

  AuthSession copyWith({AuthenticatedUser? user}) => AuthSession(
    accessToken: accessToken,
    expiresAtUtc: expiresAtUtc,
    user: user ?? this.user,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
    'usuario': user.toJson(),
  };
}
