import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/aether_progress.dart';
import '../widgets/glass_panel.dart';

/// Aether 视频播放器 OSD 控制栏
///
/// 全屏播放时的控制界面，包含：
/// - 顶部栏：返回、标题、设置
/// - 底部栏：进度条、播放控制、音量、全屏
/// - 自动隐藏（3秒无操作后淡出）
class VideoOsd extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isMuted;
  final double volume;
  final double playbackSpeed;

  final VoidCallback? onBack;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onFullscreen;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onSettings;
  final VoidCallback? onSubtitles;
  final Widget? settingsPanel;

  const VideoOsd({
    super.key,
    required this.title,
    this.subtitle = '',
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.onBack,
    this.onPlayPause,
    this.onSeekForward,
    this.onSeekBackward,
    this.onMuteToggle,
    this.onFullscreen,
    this.onVolumeChanged,
    this.onSeek,
    this.onSettings,
    this.onSubtitles,
    this.settingsPanel,
  });

  @override
  State<VideoOsd> createState() => _VideoOsdState();
}

class _VideoOsdState extends State<VideoOsd>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _hideTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    _hideTimer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        if (_hideTimer.isCompleted && _visible) {
          _hideOsd();
        }
      });
    _resetHideTimer();
  }

  @override
  void didUpdateWidget(VideoOsd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _resetHideTimer();
      } else {
        _showOsd();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hideTimer.dispose();
    super.dispose();
  }

  void _showOsd() {
    _hideTimer.reset();
    if (!_visible) {
      setState(() => _visible = true);
      _fadeController.forward();
    }
  }

  void _hideOsd() {
    if (_visible) {
      _fadeController.reverse().then((_) {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  void _resetHideTimer() {
    _hideTimer.reset();
    _hideTimer.forward();
  }

  void _onTap() {
    _resetHideTimer();
    if (!_visible) {
      _showOsd();
    } else {
      // 单击 = 暂停/播放
      widget.onPlayPause?.call();
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: _onTap,
      onDoubleTap: widget.onPlayPause,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                // ── 顶部渐变遮罩 ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            MediaQuery.of(context).padding.top + 8,
                            16,
                            0,
                          ),
                          child: Row(
                            children: [
                              // 返回
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 24),
                                onPressed: widget.onBack,
                              ),
                              const SizedBox(width: 8),
                              // 标题
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.subtitle.isNotEmpty)
                                      Text(
                                        widget.subtitle,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              // 字幕
                              if (widget.onSubtitles != null)
                                IconButton(
                                  icon: const Icon(Icons.subtitles_rounded,
                                      color: Colors.white70, size: 22),
                                  onPressed: widget.onSubtitles,
                                ),
                              // 设置
                              if (widget.onSettings != null)
                                IconButton(
                                  icon: const Icon(Icons.settings_rounded,
                                      color: Colors.white70, size: 22),
                                  onPressed: widget.onSettings,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 底部控制栏 ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            40,
                            20,
                            MediaQuery.of(context).padding.bottom + 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── 进度条 ──
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(widget.position),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AetherProgress.video(
                                      value: progress,
                                      elapsed: '',
                                      remaining: _formatDuration(
                                          widget.duration - widget.position),
                                      onChanged: widget.onSeek,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDuration(widget.duration),
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // ── 控制按钮 ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 随机
                                  IconButton(
                                    icon: const Icon(Icons.shuffle_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 8),
                                  // 后退10s
                                  IconButton(
                                    icon: const Icon(Icons.replay_10_rounded,
                                        color: Colors.white, size: 28),
                                    onPressed: widget.onSeekBackward,
                                  ),
                                  const SizedBox(width: 16),
                                  // 播放/暂停
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.celestialCyan,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.celestialCyan
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        widget.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: AppColors.deepVoid,
                                        size: 32,
                                      ),
                                      onPressed: widget.onPlayPause,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 前进30s
                                  IconButton(
                                    icon: const Icon(Icons.forward_30_rounded,
                                        color: Colors.white, size: 28),
                                    onPressed: widget.onSeekForward,
                                  ),
                                  const SizedBox(width: 8),
                                  // 循环
                                  IconButton(
                                    icon: const Icon(Icons.repeat_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                    onPressed: () {},
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ── 音量 + 速度 + 全屏 ──
                              Row(
                                children: [
                                  // 静音
                                  IconButton(
                                    icon: Icon(
                                      widget.isMuted
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: widget.onMuteToggle,
                                  ),
                                  // 音量滑块
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor:
                                            AppColors.celestialCyan,
                                        inactiveTrackColor: AppColors.cosmicGray,
                                        thumbColor: AppColors.celestialCyan,
                                        overlayColor: AppColors.celestialCyan
                                            .withValues(alpha: 0.12),
                                        trackHeight: 2,
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                                enabledThumbRadius: 5),
                                      ),
                                      child: Slider(
                                        value: widget.isMuted
                                            ? 0
                                            : widget.volume,
                                        onChanged: widget.onVolumeChanged,
                                      ),
                                    ),
                                  ),
                                  // 速度
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.stardust,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '${widget.playbackSpeed}x',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // 全屏
                                  IconButton(
                                    icon: const Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 24),
                                    onPressed: widget.onFullscreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 中央播放按钮（暂停时显示） ──
                if (!widget.isPlaying)
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.celestialCyan.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.celestialCyan.withValues(alpha: 0.4),
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

                // ── 设置面板 ──
                if (widget.settingsPanel != null)
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 60,
                    child: widget.settingsPanel!,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
