import 'dart:convert';

class SavedServer {
  final String id;
  final String serverUrl;
  final String username;
  final String serverName;
  final String? userId;
  final DateTime lastLoginAt;

  SavedServer({
    required this.id,
    required this.serverUrl,
    required this.username,
    required this.serverName,
    this.userId,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverUrl': serverUrl,
        'username': username,
        'serverName': serverName,
        'userId': userId,
        'lastLoginAt': lastLoginAt.toIso8601String(),
      };

  /// 类型不符时返回 null —— `as String?` 只对 null 宽容，
  /// 字段值是数字等非字符串类型时仍会抛 TypeError。
  static String? _asString(Object? value) => value is String ? value : null;

  /// 容错解析单条记录；字段缺失或类型不符时返回 null 由调用方跳过。
  ///
  /// 存储中的历史脏数据不应导致用户丢失**全部**已保存的服务器。
  static SavedServer? tryFromJson(Map<String, dynamic> json) {
    final id = _asString(json['id']);
    final serverUrl = _asString(json['serverUrl']);
    final username = _asString(json['username']);
    if (id == null || serverUrl == null || username == null) return null;

    return SavedServer(
      id: id,
      serverUrl: serverUrl,
      username: username,
      serverName: _asString(json['serverName']) ?? serverUrl,
      userId: _asString(json['userId']),
      // DateTime.parse 遇到非法值会抛异常，这里必须用 tryParse
      lastLoginAt:
          DateTime.tryParse(_asString(json['lastLoginAt']) ?? '') ??
              DateTime.now(),
    );
  }

  static List<SavedServer> listFromJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(tryFromJson)
        .nonNulls
        .toList();
  }

  static String listToJson(List<SavedServer> servers) {
    return jsonEncode(servers.map((s) => s.toJson()).toList());
  }

  SavedServer copyWith({
    String? id,
    String? serverUrl,
    String? username,
    String? serverName,
    String? userId,
    DateTime? lastLoginAt,
  }) {
    return SavedServer(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      serverName: serverName ?? this.serverName,
      userId: userId ?? this.userId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
