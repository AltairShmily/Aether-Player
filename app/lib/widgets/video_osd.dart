import 'dart:ui';

import 'package:flutter/material.dart';

import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../utils/subtitle_utils.dart';

// ══════════════════════════════════════════════════════════════════
//  视频 OSD —— 全屏播放的控制层
// ══════════════════════════════════════════════════════════════════
//
// 全屏播放器的控制层：进度条 + 播放控制 + 字幕/音轨/倍速/画质/音量。
//
// 原先作为 _PlayerControlsOverlay 私有在 screens/player_page.dart 里，
// 而本文件另有一套从未被引用的 VideoOsd（0 个导入），两套并行实现
// 意味着任何一处改动都只修了一半。现统一收敛到这里：
// 播放页只负责组装回调，桌面与手机共用同一套控件、只换布局密度。

// ══════════════════════════════════════════════════════════════════
//  进度条
// ══════════════════════════════════════════════════════════════════

/// 可拖拽进度条。
///
/// 拖拽状态必须本地持有：Slider 的 onChanged 在拖动中每移动一像素触发一次，
/// 若直接透传给播放器会产生数十次 seek，造成画面抖动与无谓的服务端压力。
/// 因此拖动期间只更新本地值，松手（onChangeEnd）才真正 seek。
class _ProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;

  /// 已缓冲到的位置；null 表示当前引擎不上报，此时不画缓冲段
  final Duration? buffered;

  final ValueChanged<double> onSeek;

  const _ProgressBar({
    required this.progress,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.buffered,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  /// 滑块半径。缓冲段必须与 Slider 的轨道几何对齐，
  /// 而轨道两端各内缩一个滑块半径，否则缓冲段会超出轨道头尾
  static const double _thumbRadius = 6;

  static const double _trackHeight = 4;

  bool _dragging = false;
  double _dragProgress = 0;

  /// 拖动时左侧标签显示目标时间，让用户知道松手后会跳到哪里
  Duration get _displayPosition {
    if (!_dragging) return widget.position;
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return widget.position;
    return Duration(milliseconds: (totalMs * _dragProgress).round());
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = (_dragging ? _dragProgress : widget.progress).clamp(
      0.0,
      1.0,
    );

    final totalMs = widget.duration.inMilliseconds;
    final buffered = widget.buffered;
    // 引擎不上报或时长未知时不画缓冲段：画在 0 处会被误读成"完全没缓冲"
    final bufferedValue = (buffered != null && totalMs > 0)
        ? (buffered.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : null;

    return Row(
      children: [
        // 当前位置（拖动时为跳转目标位置）
        Text(
          PlayerController.formatDuration(_displayPosition),
          style: const TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        // 进度滑块
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (bufferedValue != null && bufferedValue > sliderValue)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BufferTrackPainter(
                      from: sliderValue,
                      to: bufferedValue,
                      thumbRadius: _thumbRadius,
                      trackHeight: _trackHeight,
                    ),
                  ),
                ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.celestialCyan,
                  inactiveTrackColor: AppColors.cosmicGray,
                  thumbColor: AppColors.celestialCyan,
                  overlayColor: AppColors.celestialCyan.withValues(alpha: 0.12),
                  trackHeight: _trackHeight,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: _thumbRadius,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: sliderValue,
                  onChangeStart: (v) => setState(() {
                    _dragging = true;
                    _dragProgress = v;
                  }),
                  onChanged: (v) => setState(() => _dragProgress = v),
                  onChangeEnd: (v) {
                    setState(() => _dragging = false);
                    widget.onSeek(v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 总时长
        Text(
          PlayerController.formatDuration(widget.duration),
          style: const TextStyle(
            fontFamily: 'DM Mono',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// 进度条上「已播放 → 已缓冲」那一段的绘制。
///
/// 只画进度之后的部分：已播放段由 Slider 的青色轨道覆盖，
/// 全画会与它重叠并在边缘露出杂色。
class _BufferTrackPainter extends CustomPainter {
  final double from;
  final double to;
  final double thumbRadius;
  final double trackHeight;

  _BufferTrackPainter({
    required this.from,
    required this.to,
    required this.thumbRadius,
    required this.trackHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Slider 的轨道两端各内缩一个滑块半径
    final trackWidth = size.width - thumbRadius * 2;
    if (trackWidth <= 0) return;

    final left = thumbRadius + trackWidth * from;
    final right = thumbRadius + trackWidth * to;
    if (right - left < 1) return;

    final top = (size.height - trackHeight) / 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, top + trackHeight),
        Radius.circular(trackHeight / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BufferTrackPainter old) =>
      old.from != from ||
      old.to != to ||
      old.thumbRadius != thumbRadius ||
      old.trackHeight != trackHeight;
}

// ══════════════════════════════════════════════════════════════════
//  播放器控制面板覆盖层
// ══════════════════════════════════════════════════════════════════

/// 全屏播放器控制面板
///
/// 包含：
/// - 顶部：返回按钮、标题、设置菜单
/// - 底部：进度条、播放控制、时间标签、倍速、音轨、字幕
class VideoOsd extends StatelessWidget {
  final PlayerUiState state;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteToggle;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onAudioTrackSelected;
  final ValueChanged<int> onSubtitleTrackSelected;
  final VoidCallback? onQualityPressed;
  final VoidCallback? onSkipNext;

  const VideoOsd({
    super.key,
    required this.state,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onVolumeChanged,
    required this.onMuteToggle,
    required this.onSpeedChanged,
    required this.onAudioTrackSelected,
    required this.onSubtitleTrackSelected,
    this.onQualityPressed,
    this.onSkipNext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: state.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Stack(
        children: [
          // ── 顶部渐变遮罩 + 返回/标题 ──
          _buildTopBar(context),

          // ── 底部渐变遮罩 + 控制栏 ──
          _buildBottomBar(context),

          // ── 中央播放按钮（暂停时显示） ──
          if (!state.isPlaying && !state.isBuffering)
            Center(
              child: GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.celestialCyan.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.celestialCyan.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.celestialCyan,
                    size: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 顶部控制栏（返回 + 标题 + 设置）
  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.of(context).padding.top + 4,
              16,
              0,
            ),
            child: Row(
              children: [
                // 返回按钮
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 26),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                // 标题
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.title.isNotEmpty ? state.title : '正在播放',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 统一设置按钮
                IconButton(
                  icon: const Icon(Icons.settings_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: () => _showSettingsSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 底部控制栏（进度条 + 播放控制 + 功能按钮）
  Widget _buildBottomBar(BuildContext context) {
    final progress = state.progress;
    final isMuted = state.volume == 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              32,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 进度条 ──
                _buildProgressBar(progress),

                const SizedBox(height: 12),

                // ── 控制按钮行 ──
                _buildControlButtons(context, isMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 进度条（可拖拽）
  Widget _buildProgressBar(double progress) {
    return _ProgressBar(
      progress: progress,
      position: state.position,
      duration: state.duration,
      buffered: state.bufferedPosition,
      onSeek: onSeek,
    );
  }

  /// 控制按钮行
  Widget _buildControlButtons(BuildContext context, bool isMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── 左侧：快退 + 播放/暂停 + 快进 + 下一集 ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快退 10s
            IconButton(
              icon: const Icon(Icons.replay_10_rounded,
                  color: Colors.white, size: 28),
              onPressed: onSeekBackward,
            ),

            const SizedBox(width: 12),

            // 播放 / 暂停
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.celestialCyan,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.celestialCyan.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: AppColors.deepVoid,
                  size: 30,
                ),
                onPressed: onPlayPause,
              ),
            ),

            const SizedBox(width: 12),

            // 快进 30s
            IconButton(
              icon: const Icon(Icons.forward_30_rounded,
                  color: Colors.white, size: 28),
              onPressed: onSeekForward,
            ),

            // 下一集按钮（仅在有 seriesId 时显示）
            if (onSkipNext != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: Colors.white, size: 28),
                onPressed: onSkipNext,
              ),
            ],
          ],
        ),

        // ── 右侧：字幕 + 音量 + 倍速 + 设置 ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 字幕一级入口 + 当前语言角标 ──
            // 此前字幕只藏在设置弹窗里，底栏看不出当前是否开了中字
            PopupMenuButton<int>(
              tooltip: '字幕',
              initialValue: state.currentSubtitleTrack,
              onSelected: onSubtitleTrackSelected,
              color: AppColors.stardust,
              enabled: state.subtitleTracks.isNotEmpty,
              position: PopupMenuPosition.over,
              itemBuilder: (ctx) => [
                PopupMenuItem<int>(
                  value: -1,
                  child: Text(
                    '关闭字幕',
                    style: TextStyle(
                      color: state.currentSubtitleTrack < 0
                          ? AppColors.celestialCyan
                          : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                for (final track in state.subtitleTracks)
                  PopupMenuItem<int>(
                    value: track.index,
                    child: Text(
                      // player_engine 的 TrackInfo 无 displayTitle，
                      // 依次退回 title → language → 序号
                      track.title.isNotEmpty
                          ? track.title
                          : (track.language.isNotEmpty
                              ? track.language
                              : '字幕 ${track.index + 1}'),
                      style: TextStyle(
                        color: track.index == state.currentSubtitleTrack
                            ? AppColors.celestialCyan
                            : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.currentSubtitleTrack >= 0
                          ? Icons.subtitles_rounded
                          : Icons.subtitles_off_rounded,
                      color: state.currentSubtitleTrack >= 0
                          ? AppColors.celestialCyan
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    // 语言角标：不打开菜单也能看出当前是中字还是英文
                    Text(
                      subtitleShortLabel(
                        state.subtitleTracks,
                        state.currentSubtitleTrack,
                      ),
                      style: TextStyle(
                        color: state.currentSubtitleTrack >= 0
                            ? AppColors.celestialCyan
                            : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // 音量图标 + 滑块（合并）
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              onPressed: onMuteToggle,
            ),
            // 音量滑条宽度随屏幕自适应：固定 70px 在平板/电视上难以拖动。
            // 取屏宽 20%、上限 120，下限 56 保证窄屏仍可拖动
            SizedBox(
              width: (MediaQuery.sizeOf(context).width * 0.2)
                  .clamp(56.0, 120.0),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.celestialCyan,
                  inactiveTrackColor: AppColors.cosmicGray,
                  thumbColor: AppColors.celestialCyan,
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 4),
                ),
                child: Slider(
                  value: isMuted ? 0 : state.volume,
                  onChanged: onVolumeChanged,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 倍速：直选菜单，当前值常显
            // 原实现是点击循环切下一档，想选 1.5x 得反复点到轮到它，
            // 且看不到有哪些档位可选
            PopupMenuButton<double>(
              tooltip: '倍速',
              initialValue: state.playbackSpeed,
              onSelected: onSpeedChanged,
              color: AppColors.stardust,
              position: PopupMenuPosition.over,
              itemBuilder: (ctx) => [
                for (final speed in state.speedOptions)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: speed == state.playbackSpeed
                              ? const Icon(Icons.check_rounded,
                                  size: 15, color: AppColors.celestialCyan)
                              : null,
                        ),
                        Text(
                          '${speed}x',
                          style: TextStyle(
                            color: speed == state.playbackSpeed
                                ? AppColors.celestialCyan
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontFamily: 'DM Mono',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.stardust,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.borderSubtle, width: 0.5),
                  ),
                  child: Text(
                    '${state.playbackSpeed}x',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'DM Mono',
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // ── 画质一级入口 ──
            // 此前只能经右侧设置弹窗进入，路径过深
            if (onQualityPressed != null)
              IconButton(
                tooltip: '画质',
                icon: const Icon(Icons.high_quality_rounded,
                    color: AppColors.textSecondary, size: 22),
                onPressed: onQualityPressed,
              ),

            // 统一设置菜单按钮
            IconButton(
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.white70, size: 22),
              onPressed: () => _showSettingsSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  /// 统一设置面板（底部弹出）
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: AppColors.stardust,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽条
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cosmicGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 标题
                const Text(
                  '设置',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // ── 倍速选择 ──
                const Text(
                  '🎬 倍速',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.speedOptions.map((speed) {
                    final isSelected = state.playbackSpeed == speed;
                    return GestureDetector(
                      onTap: () {
                        onSpeedChanged(speed);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.deepVoid,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.celestialCyan
                                : AppColors.borderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.deepVoid
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── 音频轨道 ──
                if (state.audioTracks.length > 1) ...[
                  const Text(
                    '🎵 音轨',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.audioTracks.asMap().entries.map((entry) {
                    final isSelected = state.currentAudioTrack == entry.key;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        entry.value.title.isNotEmpty
                            ? entry.value.title
                            : '轨道 ${entry.key + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.celestialCyan, size: 20)
                          : null,
                      onTap: () {
                        onAudioTrackSelected(entry.key);
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── 字幕轨道 ──
                if (state.subtitleTracks.isNotEmpty) ...[
                  const Text(
                    '📝 字幕',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 关闭字幕选项
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      '关闭字幕',
                      style: TextStyle(
                        color: state.currentSubtitleTrack < 0
                            ? AppColors.celestialCyan
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: state.currentSubtitleTrack < 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: state.currentSubtitleTrack < 0
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.celestialCyan, size: 20)
                        : null,
                    onTap: () {
                      onSubtitleTrackSelected(-1);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  ...state.subtitleTracks.asMap().entries.map((entry) {
                    final isSelected =
                        state.currentSubtitleTrack == entry.key;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        entry.value.title.isNotEmpty
                            ? entry.value.title
                            : '轨道 ${entry.key + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.celestialCyan
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.celestialCyan, size: 20)
                          : null,
                      onTap: () {
                        onSubtitleTrackSelected(entry.key);
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── 画质选项 ──
                if (onQualityPressed != null) ...[
                  const Text(
                    '🎨 画质',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      '画质设置',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onQualityPressed!();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
