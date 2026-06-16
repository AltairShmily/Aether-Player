import '../models/media_models.dart';

/// Merge episodes with the same IndexNumber (episode number) into a single
/// [MergedEpisode] with multiple versions.
///
/// This handles the case where the same episode exists in multiple qualities
/// (e.g. 1080p / 4K) and should be presented as one entry with selectable
/// versions.
List<MergedEpisode> mergeEpisodes(List<MediaItem> raw) {
  final Map<int, List<MediaItem>> grouped = {};
  for (final ep in raw) {
    final key = ep.indexNumber > 0 ? ep.indexNumber : raw.indexOf(ep);
    grouped.putIfAbsent(key, () => []).add(ep);
  }

  final keys = grouped.keys.toList()..sort();
  return keys.map((key) {
    final items = grouped[key]!;
    // Pick the primary version: prefer the one with an image, then the first
    final primary = items.firstWhere(
      (e) => e.hasPrimaryImage,
      orElse: () => items.first,
    );
    final versions = items
        .map((e) => EpisodeVersion(id: e.id, name: e.name))
        .toList();
    return MergedEpisode(primary: primary, versions: versions);
  }).toList();
}
