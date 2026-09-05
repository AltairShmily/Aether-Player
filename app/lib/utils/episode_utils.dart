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
