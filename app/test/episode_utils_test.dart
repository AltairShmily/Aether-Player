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

/// 构造带播放进度的合并集，用于 pickResumeEpisode 测试
MergedEpisode _merged(
  String id, {
  int indexNumber = 0,
  int positionTicks = 0,
  bool played = false,
}) {
  final item = MediaItem(
    id: id,
    name: id,
    type: 'Episode',
    indexNumber: indexNumber,
    parentIndexNumber: 1,
    userData: UserData(
      playbackPositionTicks: positionTicks,
      played: played,
      playedPercentage: positionTicks > 0 ? 50 : 0,
    ),
  );
  return MergedEpisode(
    primary: item,
    versions: [EpisodeVersion(id: id, name: id)],
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

  group('pickResumeEpisode', () {
    test('空列表返回 null', () {
      expect(pickResumeEpisode([]), isNull);
    });

    test('全部无进度时取第一集，且标记为无进度', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1),
        _merged('e2', indexNumber: 2),
      ]);

      expect(target, isNotNull);
      expect(target!.episode.primary.id, 'e1');
      expect(target.hasProgress, isFalse);
    });

    test('有未看完的进度时取该集', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1),
        _merged('e2', indexNumber: 2, positionTicks: 12345),
        _merged('e3', indexNumber: 3),
      ]);

      expect(target!.episode.primary.id, 'e2');
      expect(target.hasProgress, isTrue);
    });

    // 关键分支：取「最后」一集而非第一集，用户可能跳着看
    test('多集都有进度时取最后一集', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1, positionTicks: 100),
        _merged('e2', indexNumber: 2, positionTicks: 200),
        _merged('e3', indexNumber: 3, positionTicks: 300),
      ]);

      expect(target!.episode.primary.id, 'e3');
      expect(target.hasProgress, isTrue);
    });

    // 关键分支：已看完的集即使留有进度也不应被当作「接着看」目标
    test('有进度但已看完的集被跳过', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1, positionTicks: 999, played: true),
        _merged('e2', indexNumber: 2),
        _merged('e3', indexNumber: 3),
      ]);

      expect(target!.episode.primary.id, 'e2');
      expect(target.hasProgress, isFalse);
    });

    test('全部看完时回到第一集', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1, played: true),
        _merged('e2', indexNumber: 2, played: true),
      ]);

      expect(target!.episode.primary.id, 'e1');
      expect(target.hasProgress, isFalse);
    });

    test('进度为 0 不算在看，即便未标记已看完', () {
      final target = pickResumeEpisode([
        _merged('e1', indexNumber: 1, positionTicks: 0),
        _merged('e2', indexNumber: 2, positionTicks: 500),
      ]);

      expect(target!.episode.primary.id, 'e2');
      expect(target.hasProgress, isTrue);
    });

    test('目标集带有 SxxExx 标签供按钮文案使用', () {
      final target = pickResumeEpisode([
        _merged('e3', indexNumber: 3, positionTicks: 500),
      ]);

      expect(target!.episode.primary.episodeLabel, 'S01E03');
    });
  });
}
