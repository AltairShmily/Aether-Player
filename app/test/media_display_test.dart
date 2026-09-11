import 'package:aether/models/media_models.dart';
import 'package:aether/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

MediaItem _item({
  required String type,
  String name = '条目名',
  String seriesName = '',
  int indexNumber = 0,
  int parentIndexNumber = 0,
}) {
  return MediaItem(
    id: 'id-1',
    name: name,
    type: type,
    seriesName: seriesName,
    indexNumber: indexNumber,
    parentIndexNumber: parentIndexNumber,
  );
}

void main() {
  group('MediaItem.displayTitle', () {
    test('电影与剧集直接用 name', () {
      expect(_item(type: 'Movie', name: '星际穿越').displayTitle, '星际穿越');
      expect(_item(type: 'Series', name: '切尔诺贝利').displayTitle, '切尔诺贝利');
    });

    test('单集带上剧集名与集号，否则「第 3 集」无法辨认属于哪部剧', () {
      final ep = _item(
        type: 'Episode',
        name: '第 3 集',
        seriesName: '绝命毒师',
        parentIndexNumber: 1,
        indexNumber: 3,
      );
      expect(ep.displayTitle, '绝命毒师 - S01E03');
    });

    test('集号与季号补零到两位', () {
      final ep = _item(
        type: 'Episode',
        seriesName: '某剧',
        parentIndexNumber: 12,
        indexNumber: 7,
      );
      expect(ep.displayTitle, '某剧 - S12E07');
    });

    test('单集缺集号时只带剧集名', () {
      final ep = _item(type: 'Episode', name: 'OVA', seriesName: '某剧');
      expect(ep.displayTitle, '某剧');
    });

    test('单集缺剧集名时退回 name，不产出「 - S01E03」这种残缺标题', () {
      final ep = _item(
        type: 'Episode',
        name: '第 3 集',
        parentIndexNumber: 1,
        indexNumber: 3,
      );
      expect(ep.displayTitle, '第 3 集');
    });
  });

  group('ApiClient.imageProxyUrl', () {
    test('默认取 Primary 且不附加空的 maxWidth', () {
      expect(
        ApiClient.imageProxyUrl('abc'),
        '${ApiClient.proxyBaseUrl}/api/images/abc/Primary',
      );
    });

    test('指定图片类型与宽度上限', () {
      expect(
        ApiClient.imageProxyUrl('abc', type: 'Backdrop', maxWidth: 800),
        '${ApiClient.proxyBaseUrl}/api/images/abc/Backdrop?maxWidth=800',
      );
    });

    test('一律指向本地代理，而不是远端 Emby（token 不落到前端 URL 上）', () {
      expect(ApiClient.imageProxyUrl('abc'), startsWith('http://localhost:'));
    });
  });
}
