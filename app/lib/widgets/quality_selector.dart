import 'package:flutter/material.dart';
import '../models/playback_models.dart';
import '../services/playback_strategy.dart';
import '../theme/app_colors.dart';

class QualityOption {
  final String label;
  final PlayMode mode;
  final int? maxHeight;
  final int? maxBitrate;

  const QualityOption({
    required this.label,
    required this.mode,
    this.maxHeight,
    this.maxBitrate,
  });
}

class QualitySelector extends StatelessWidget {
  final List<QualityOption> options;
  final QualityOption? current;
  final ValueChanged<QualityOption> onSelected;

  const QualitySelector({
    super.key,
    required this.options,
    this.current,
    required this.onSelected,
  });

  static List<QualityOption> fromMediaSource(MediaSourceInfo source) {
    final options = <QualityOption>[];

    if (source.supportsDirectPlay || source.hasDirectStream) {
      final videoStream = source.mediaStreams
          .where((s) => s.type == 'Video')
          .fold<PlaybackStreamInfo?>(null, (prev, s) =>
              (prev == null || s.height > prev.height) ? s : prev);

      final label = videoStream != null && videoStream.height > 0
          ? '原始画质 (${videoStream.height}p)'
          : '原始画质';

      options.add(QualityOption(label: label, mode: PlayMode.directPlay));
    }

    if (source.supportsTranscoding) {
      options.addAll([
        const QualityOption(label: '1080p · 20 Mbps', mode: PlayMode.transcode, maxHeight: 1080, maxBitrate: 20000000),
        const QualityOption(label: '720p · 10 Mbps', mode: PlayMode.transcode, maxHeight: 720, maxBitrate: 10000000),
        const QualityOption(label: '480p · 5 Mbps', mode: PlayMode.transcode, maxHeight: 480, maxBitrate: 5000000),
        const QualityOption(label: '360p · 2 Mbps', mode: PlayMode.transcode, maxHeight: 360, maxBitrate: 2000000),
      ]);
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: const BoxDecoration(
        color: AppColors.deepVoid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '画质选择',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = current?.label == opt.label;
                return ListTile(
                  title: Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.celestialCyan
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.celestialCyan)
                      : null,
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
