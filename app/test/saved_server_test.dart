import 'package:aether/models/saved_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedServer.listFromJson', () {
    test('正常列表可完整解析', () {
      final json = '''
      [
        {
          "id": "s1",
          "serverUrl": "http://192.168.1.10:8096",
          "username": "alice",
          "serverName": "Home",
          "userId": "u1",
          "lastLoginAt": "2026-01-02T03:04:05.000Z"
        }
      ]
      ''';

      final result = SavedServer.listFromJson(json);

      expect(result, hasLength(1));
      expect(result.single.id, 's1');
      expect(result.single.username, 'alice');
      expect(result.single.lastLoginAt.year, 2026);
    });

    test('toJson / listFromJson 往返一致', () {
      final servers = [
        SavedServer(
          id: 's1',
          serverUrl: 'http://a:8096',
          username: 'alice',
          serverName: 'A',
          userId: 'u1',
          lastLoginAt: DateTime.utc(2026, 3, 4, 5, 6),
        ),
        SavedServer(
          id: 's2',
          serverUrl: 'http://b:8096',
          username: 'bob',
          serverName: 'B',
          lastLoginAt: DateTime.utc(2026, 3, 4, 5, 7),
        ),
      ];

      final restored = SavedServer.listFromJson(SavedServer.listToJson(servers));

      expect(restored, hasLength(2));
      expect(restored[0].id, 's1');
      expect(restored[1].username, 'bob');
      // userId 为可空字段，未设置时应保持 null
      expect(restored[1].userId, isNull);
    });

    // 回归：此前任一字段强制 cast 失败或日期非法都会让整个列表解析抛异常，
    // 用户因此丢失全部已保存的服务器
    test('单条脏数据被跳过，其余记录保留', () {
      final json = '''
      [
        {"id": "good1", "serverUrl": "http://a", "username": "alice",
         "serverName": "A", "lastLoginAt": "2026-01-01T00:00:00.000Z"},
        {"id": "bad-missing-fields", "serverUrl": "http://b"},
        {"id": "good2", "serverUrl": "http://c", "username": "carol",
         "serverName": "C", "lastLoginAt": "2026-01-02T00:00:00.000Z"}
      ]
      ''';

      final result = SavedServer.listFromJson(json);

      expect(result.map((s) => s.id), ['good1', 'good2']);
    });

    test('非法日期回退而非抛异常', () {
      final json = '''
      [{"id": "s1", "serverUrl": "http://a", "username": "alice",
        "serverName": "A", "lastLoginAt": "not-a-date"}]
      ''';

      final result = SavedServer.listFromJson(json);

      expect(result, hasLength(1));
      expect(result.single.lastLoginAt, isA<DateTime>());
    });

    test('字段类型不符时跳过该条', () {
      final json = '''
      [{"id": 12345, "serverUrl": "http://a", "username": "alice",
        "serverName": "A", "lastLoginAt": "2026-01-01T00:00:00.000Z"}]
      ''';

      expect(SavedServer.listFromJson(json), isEmpty);
    });

    test('serverName 缺失时回退到服务器地址', () {
      final json = '''
      [{"id": "s1", "serverUrl": "http://a:8096", "username": "alice",
        "lastLoginAt": "2026-01-01T00:00:00.000Z"}]
      ''';

      final result = SavedServer.listFromJson(json);

      expect(result.single.serverName, 'http://a:8096');
    });

    test('顶层不是列表时返回空列表', () {
      expect(SavedServer.listFromJson('{"id": "s1"}'), isEmpty);
      expect(SavedServer.listFromJson('"just a string"'), isEmpty);
      expect(SavedServer.listFromJson('null'), isEmpty);
    });

    test('列表中的非对象元素被忽略', () {
      final json = '''
      ["garbage", 42, null,
       {"id": "s1", "serverUrl": "http://a", "username": "alice",
        "serverName": "A", "lastLoginAt": "2026-01-01T00:00:00.000Z"}]
      ''';

      final result = SavedServer.listFromJson(json);

      expect(result, hasLength(1));
      expect(result.single.id, 's1');
    });

    test('空列表返回空结果', () {
      expect(SavedServer.listFromJson('[]'), isEmpty);
    });
  });

  group('SavedServer.tryFromJson', () {
    test('缺少必填字段返回 null', () {
      expect(SavedServer.tryFromJson({'id': 's1'}), isNull);
      expect(
        SavedServer.tryFromJson({'serverUrl': 'http://a', 'username': 'alice'}),
        isNull,
      );
    });
  });
}
