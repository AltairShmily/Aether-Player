import 'package:aether/services/player_engine.dart';
import 'package:aether/utils/subtitle_utils.dart';
import 'package:flutter_test/flutter_test.dart';

TrackInfo _track(int index, {String language = '', String title = ''}) {
  return TrackInfo(
    index: index,
    language: language,
    title: title,
    type: 'subtitle',
  );
}

void main() {
  group('subtitleShortLabel', () {
    test('未选字幕（索引为负）返回「关」', () {
      expect(subtitleShortLabel([_track(0, language: 'zh')], -1), '关');
      expect(subtitleShortLabel([_track(0, language: 'zh')], -2), '关');
    });

    test('索引在列表中不存在时返回「关」', () {
      expect(subtitleShortLabel([_track(0, language: 'zh')], 5), '关');
      expect(subtitleShortLabel([], 0), '关');
    });

    // Emby 返回的语言代码形式不统一，必须都能归并到同一个短标签
    test('中文的多种写法都归并为「中」', () {
      for (final lang in ['zh', 'zh-CN', 'zh-hans', 'chi', 'chinese', '简体中文']) {
        expect(
          subtitleShortLabel([_track(0, language: lang)], 0),
          '中',
          reason: 'language=$lang',
        );
      }
    });

    test('英文的多种写法都归并为「英」', () {
      for (final lang in ['en', 'en-US', 'eng', 'english', '英语']) {
        expect(
          subtitleShortLabel([_track(0, language: lang)], 0),
          '英',
          reason: 'language=$lang',
        );
      }
    });

    test('日文与韩文分别归并', () {
      expect(subtitleShortLabel([_track(0, language: 'ja')], 0), '日');
      expect(subtitleShortLabel([_track(0, language: 'jpn')], 0), '日');
      expect(subtitleShortLabel([_track(0, language: 'ko')], 0), '韩');
      expect(subtitleShortLabel([_track(0, language: 'kor')], 0), '韩');
    });

    test('大小写不敏感', () {
      expect(subtitleShortLabel([_track(0, language: 'ZH')], 0), '中');
      expect(subtitleShortLabel([_track(0, language: 'Eng')], 0), '英');
    });

    test('语言为空时退回标题', () {
      expect(
        subtitleShortLabel([_track(0, title: 'Chinese Simplified')], 0),
        '中',
      );
    });

    test('语言与标题都为空时返回「字」', () {
      expect(subtitleShortLabel([_track(0)], 0), '字');
    });

    test('无法识别的语言退回前两字符，仍能区分不同轨道', () {
      expect(subtitleShortLabel([_track(0, language: 'fr')], 0), 'fr');
      expect(subtitleShortLabel([_track(0, language: 'deu')], 0), 'de');
      expect(subtitleShortLabel([_track(0, language: 'ru')], 0), 'ru');
    });

    test('按索引取对应轨道，而非列表首项', () {
      final tracks = [
        _track(0, language: 'en'),
        _track(1, language: 'zh'),
        _track(2, language: 'ja'),
      ];
      expect(subtitleShortLabel(tracks, 0), '英');
      expect(subtitleShortLabel(tracks, 1), '中');
      expect(subtitleShortLabel(tracks, 2), '日');
    });

    test('索引不从 0 开始时也能正确匹配', () {
      final tracks = [
        _track(3, language: 'zh'),
        _track(7, language: 'en'),
      ];
      expect(subtitleShortLabel(tracks, 3), '中');
      expect(subtitleShortLabel(tracks, 7), '英');
      // 不存在的索引
      expect(subtitleShortLabel(tracks, 0), '关');
    });
  });
}
