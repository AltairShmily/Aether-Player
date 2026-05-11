import 'package:flutter/material.dart';
import '../models/media_models.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.imageUrlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = imageUrlBuilder(item.id, type: 'Primary', maxWidth: 300);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: item.hasPrimaryImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        headers: const {'Accept': 'image/*'},
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildPlaceholder(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                children: [
                  if (item.productionYear > 0)
                    Text(
                      '${item.productionYear}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  if (item.communityRating > 0) ...[
                    if (item.productionYear > 0) const SizedBox(width: 8),
                    Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      item.communityRating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (item.durationText.isNotEmpty)
                    Text(
                      item.durationText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        item.type == 'Movie'
            ? Icons.movie_outlined
            : item.type == 'Series'
                ? Icons.tv_outlined
                : item.type == 'Audio'
                    ? Icons.music_note_outlined
                    : Icons.video_file_outlined,
        size: 40,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}

class SearchHintCard extends StatelessWidget {
  final SearchHint hint;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  const SearchHintCard({
    super.key,
    required this.hint,
    required this.onTap,
    required this.imageUrlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = imageUrlBuilder(hint.id, type: 'Primary', maxWidth: 200);

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: hint.hasImage
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  headers: const {'Accept': 'image/*'},
                  errorBuilder: (_, __, ___) => _buildSmallPlaceholder(theme),
                )
              : _buildSmallPlaceholder(theme),
        ),
      ),
      title: Text(
        hint.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _typeLabel(hint.type),
          if (hint.productionYear > 0) '${hint.productionYear}',
        ].where((s) => s.isNotEmpty).join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: hint.communityRating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                const SizedBox(width: 2),
                Text(
                  hint.communityRating.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'Movie':
        return '电影';
      case 'Series':
        return '剧集';
      case 'Episode':
        return '剧集';
      case 'Audio':
        return '音乐';
      case 'MusicAlbum':
        return '专辑';
      default:
        return type;
    }
  }

  Widget _buildSmallPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
