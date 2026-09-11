import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../screens/episode_detail_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../widgets/aether_page_route.dart';

/// 按条目类型选出对应的详情页。
///
/// 「判断类型 → 选详情页」这段逻辑此前在 home_tab（3 处）、
/// phone_library_screen、tv_home_screen 各写了一遍：
/// 新增一种详情页时要同步五处，漏一处就是点了没反应或跳错页。
Widget detailPageFor(MediaItem item) {
  if (item.isSeries) return SeriesDetailScreen(series: item);
  if (item.isEpisode) return EpisodeDetailScreen(item: item);
  return MediaDetailScreen(item: item);
}

/// 打开条目对应的详情页（统一的右滑转场）。
///
/// 需要在 pop 之后再跳转的场景（例如搜索结果先关掉弹窗）不能用本函数：
/// 那时 context 已失效，应自行捕获 NavigatorState 并配合 [detailPageFor]。
void openMediaItem(BuildContext context, MediaItem item) {
  Navigator.of(context).push(
    AetherPageRoute(
      page: detailPageFor(item),
      type: AetherTransitionType.slideFromRight,
    ),
  );
}
