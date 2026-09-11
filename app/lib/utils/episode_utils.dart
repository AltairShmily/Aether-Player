import '../models/media_models.dart';

/// Merge episodes with the same IndexNumber (episode number) into a single
/// [MergedEpisode] with multiple versions.
///
/// This handles the case where the same episode exists in multiple qualities
/// (e.g. 1080p / 4K) and should be presented as one entry with selectable
/// versions.
///
/// Episodes without a usable IndexNumber cannot be matched against each other,
/// so each becomes its own entry and the original relative order is kept.
/// They are listed after the numbered episodes rather than interleaved, which
/// avoids specials jumping to the top of the list.
List<MergedEpisode> mergeEpisodes(List<MediaItem> raw) {
  final Map<int, List<MediaItem>> grouped = {};
  final List<MediaItem> unnumbered = [];

  // 用 for-in 而非索引遍历，并以 indexNumber 直接作键。
  // 此前无编号剧集的键取 raw.indexOf(ep)：既是 O(n²)，又会与真实的
  // indexNumber 撞键（某集编号为 3，另一无编号集恰好位于列表第 3 位时，
  // 两者共用键 3 被错误合并，导致其中一集凭空消失）。
  for (final ep in raw) {
    if (ep.indexNumber > 0) {
      grouped.putIfAbsent(ep.indexNumber, () => []).add(ep);
    } else {
      unnumbered.add(ep);
    }
  }

  final keys = grouped.keys.toList()..sort();
  return [
    for (final key in keys) _mergeVersions(grouped[key]!),
    for (final ep in unnumbered) _mergeVersions([ep]),
  ];
}

/// 「接着看」的选集结果
class ResumeTarget {
  /// 应当播放的那一集
  final MergedEpisode episode;

  /// 该集是否带有未看完的播放进度，决定按钮文案是「继续播放」还是「播放」
  final bool hasProgress;

  const ResumeTarget({required this.episode, required this.hasProgress});
}

/// 选出主播放按钮应当播放的那一集。
///
/// 此前按钮固定播 `_episodes.first`，完全不看进度，用户每次进详情页
/// 都要自己翻到上次看到的那一集。
///
/// 优先级：
/// 1. 有播放进度且未看完的**最后**一集 —— 用户最可能想接着看的
/// 2. 第一个未看完的集
/// 3. 第一集（全部看完时从头开始）
///
/// 抽为纯函数而非写在 widget 内，因为进度选集的分支容易出错，需要单测覆盖。
///
/// 注：设计规格原文第 2 条为「若无则 played == true 数量最少的下一集」，
/// 措辞含糊，此处按「第一个未看完的集」实现。
///
/// [episodes] 为空时返回 null。
ResumeTarget? pickResumeEpisode(List<MergedEpisode> episodes) {
  if (episodes.isEmpty) return null;

  MergedEpisode? lastInProgress;
  for (final ep in episodes) {
    final userData = ep.primary.userData;
    if (userData != null &&
        userData.playbackPositionTicks > 0 &&
        !userData.played) {
      lastInProgress = ep; // 不 break：要的是最后一集
    }
  }
  if (lastInProgress != null) {
    return ResumeTarget(episode: lastInProgress, hasProgress: true);
  }

  for (final ep in episodes) {
    if (ep.primary.userData?.played != true) {
      return ResumeTarget(episode: ep, hasProgress: false);
    }
  }

  return ResumeTarget(episode: episodes.first, hasProgress: false);
}

/// 将同一集的多个版本合并为一条记录。
MergedEpisode _mergeVersions(List<MediaItem> items) {
  // Pick the primary version: prefer the one with an image, then the first
  final primary = items.firstWhere(
    (e) => e.hasPrimaryImage,
    orElse: () => items.first,
  );
  final versions = items
      .map((e) => EpisodeVersion(id: e.id, name: e.name))
      .toList();
  return MergedEpisode(primary: primary, versions: versions);
}
