/// 嵌套 JSON 字段缺失或类型不符时回退到空 Map，避免整体解析抛异常。
Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

/// 类型不符时回退到 [fallback] —— `as String?` 只对 null 宽容，
/// 服务器把 Id 等字段返回为数字时仍会抛 TypeError 并导致登录失败。
String _asString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

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
      serverName: _asString(json['ServerName']),
      version: _asString(json['Version']),
      id: _asString(json['Id']),
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
      id: _asString(json['Id']),
      name: _asString(json['Name']),
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
      token: _asString(json['AccessToken']),
      user: UserInfo.fromJson(_asMap(json['User'])),
      server: ServerInfo.fromJson(_asMap(json['Server'])),
    );
  }
}
