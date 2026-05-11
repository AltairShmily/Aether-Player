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

  factory SavedServer.fromJson(Map<String, dynamic> json) => SavedServer(
        id: json['id'] as String,
        serverUrl: json['serverUrl'] as String,
        username: json['username'] as String,
        serverName: json['serverName'] as String,
        userId: json['userId'] as String?,
        lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      );

  static List<SavedServer> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => SavedServer.fromJson(e as Map<String, dynamic>)).toList();
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
