import 'package:aether/models/media_models.dart';
import 'package:aether/utils/episode_utils.dart';
import 'package:flutter_test/flutter_test.dart';

MediaItem _ep({
  required String id,
  String name = '',
  int indexNumber = 0,
  String? imageTag,
}) {
  return MediaItem(
    id: id,
    name: name.isEmpty ? id : name,
    type: 'Episode',
    indexNumber: indexNumber,
    primaryImageTag: imageTag,
  );
}

void main() {
  group('mergeEpisodes', () {
    test('空列表返回空结果', () {
      expect(mergeEpisodes([]), isEmpty);
    });

    test('同一集编号的多个版本合并为一条', () {
      final result = mergeEpisodes([
        _ep(id: 'a', indexNumber: 1),
        _ep(id: 'b', indexNumber: 1),
      ]);

      expect(result, hasLength(1));
      expect(result.single.versions.map((v) => v.id), ['a', 'b']);
    });

    test('有编号剧集按编号升序排列', () {
      final result = mergeEpisodes([
        _ep(id: 'e3', indexNumber: 3),
        _ep(id: 'e1', indexNumber: 1),
        _ep(id: 'e10', indexNumber: 10),
        _ep(id: 'e2', indexNumber: 2),
      ]);

      expect(
        result.map((m) => m.primary.id),
        ['e1', 'e2', 'e3', 'e10'],
      );
    });

    // 回归用例：此前无编号剧集的合并键取 raw.indexOf(ep)，
    // 会与真实的 indexNumber 撞键，导致其中一集凭空消失。
    test('无编号剧集不与编号相同的剧集错误合并', () {
      final result = mergeEpisodes([
        _ep(id: 'x'), // 无编号，位于列表第 0 位
        _ep(id: 'y'), // 无编号，位于列表第 1 位
        _ep(id: 'z'), // 无编号，位于列表第 2 位
        _ep(id: 'ep3', indexNumber: 3),
      ]);

      // 4 条输入必须产出 4 条结果，任何一条都不能被吞掉
      expect(result, hasLength(4));
      expect(result.map((m) => m.primary.id).toSet(),
          {'ep3', 'x', 'y', 'z'});
    });

    test('撞键场景：编号 3 与列表第 3 位的无编号集共存', () {
      final result = mergeEpisodes([
        _ep(id: 'u0'),
        _ep(id: 'u1'),
        _ep(id: 'u2'),
        _ep(id: 'u3'), // 旧实现中 indexOf == 3，会与下面的编号 3 撞键
        _ep(id: 'ep3', indexNumber: 3),
      ]);

      expect(result, hasLength(5));
      final ep3 = result.firstWhere((m) => m.primary.id == 'ep3');
      expect(ep3.versions, hasLength(1),
          reason: '编号 3 的剧集不应吸收无编号剧集');
    });

    test('无编号剧集各自独立成条并保持原始相对顺序', () {
      final result = mergeEpisodes([
        _ep(id: 'u1'),
        _ep(id: 'u2'),
      ]);

      expect(result.map((m) => m.primary.id), ['u1', 'u2']);
      expect(result.every((m) => m.versions.length == 1), isTrue);
    });

    test('无编号剧集排在有编号剧集之后', () {
      final result = mergeEpisodes([
        _ep(id: 'special'),
        _ep(id: 'e1', indexNumber: 1),
      ]);

      expect(result.map((m) => m.primary.id), ['e1', 'special']);
    });

    test('主版本优先选取带图片的那一条', () {
      final result = mergeEpisodes([
        _ep(id: 'no-image', indexNumber: 5),
        _ep(id: 'with-image', indexNumber: 5, imageTag: 'tag'),
      ]);

      expect(result.single.primary.id, 'with-image');
      // 版本列表仍保留全部条目
      expect(result.single.versions, hasLength(2));
    });

    test('全部无图片时回退到第一条', () {
      final result = mergeEpisodes([
        _ep(id: 'first', indexNumber: 7),
        _ep(id: 'second', indexNumber: 7),
      ]);

      expect(result.single.primary.id, 'first');
    });

    test('indexNumber 为负数时按无编号处理', () {
      final result = mergeEpisodes([
        _ep(id: 'neg', indexNumber: -1),
        _ep(id: 'e1', indexNumber: 1),
      ]);

      expect(result, hasLength(2));
      expect(result.map((m) => m.primary.id), ['e1', 'neg']);
    });
  });
}
