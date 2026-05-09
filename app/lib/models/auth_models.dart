class ServerInfo {
  final String serverName;
  final String version;
  final String id;

  ServerInfo({
    required this.serverName,
    required this.version,
    required this.id,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      serverName: json['ServerName'] ?? '',
      version: json['Version'] ?? '',
      id: json['Id'] ?? '',
    );
  }
}

class UserInfo {
  final String id;
  final String name;

  UserInfo({
    required this.id,
    required this.name,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['Id'] ?? '',
      name: json['Name'] ?? '',
    );
  }
}

class AuthResult {
  final String token;
  final UserInfo user;
  final ServerInfo server;

  AuthResult({
    required this.token,
    required this.user,
    required this.server,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['AccessToken'] ?? '',
      user: UserInfo.fromJson(json['User'] ?? {}),
      server: ServerInfo.fromJson(json['Server'] ?? {}),
    );
  }
}
