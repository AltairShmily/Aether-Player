import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/aether_progress.dart';
import '../widgets/aether_button.dart';
import '../widgets/glass_panel.dart';

/// Aether 音频播放器全屏页面
///
/// 特性：
/// - 旋转专辑封面（播放时缓慢旋转）
/// - 封面背后径向发光（提取主色调）
/// - 渐变进度条
/// - 发光播放按钮
class AudioPlayerPage extends StatefulWidget {
  final String title;
  final String artist;
  final String? album;
  final String? imageUrl;
  final Map<String, String>? imageHeaders;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isShuffled;
  final String repeatMode; // 'off', 'all', 'one'

  final VoidCallback? onBack;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onFavorite;
  final bool isFavorited;

  const AudioPlayerPage({
    super.key,
    required this.title,
    this.artist = '',
    this.album,
    this.imageUrl,
    this.imageHeaders,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isShuffled = false,
    this.repeatMode = 'off',
    this.onBack,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
    this.onSeek,
    this.onFavorite,
    this.isFavorited = false,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Stack(
        children: [
          // ── 背景发光 ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.novaPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── 内容 ──
          SafeArea(
            child: Column(
              children: [
                // ── 顶部栏 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textPrimary, size: 28),
                        onPressed: widget.onBack,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              '正在播放',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              widget.album ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          widget.isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: widget.isFavorited
                              ? AppColors.plasmaPink
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: widget.onFavorite,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── 旋转封面 ──
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.novaPurple.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: AppColors.celestialCyan.withValues(alpha: 0.15),
                          blurRadius: 60,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.imageUrl != null
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                              headers: widget.imageHeaders,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── 歌曲信息 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.artist,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── 进度条 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AetherProgress.video(
                    value: progress,
                    elapsed: _formatDuration(widget.position),
                    remaining: _formatDuration(
                        widget.duration - widget.position),
                    onChanged: widget.onSeek,
                  ),
                ),

                const SizedBox(height: 20),

                // ── 控制按钮 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 随机
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: widget.isShuffled
                              ? AppColors.celestialCyan
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: widget.onShuffle,
                      ),
                      // 上一首
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: Colors.white, size: 32),
                        onPressed: widget.onPrevious,
                      ),
                      // 播放/暂停
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.celestialCyan.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.deepVoid,
                            size: 36,
                          ),
                          onPressed: widget.onPlayPause,
                        ),
                      ),
                      // 下一首
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white, size: 32),
                        onPressed: widget.onNext,
                      ),
                      // 循环
                      IconButton(
                        icon: Icon(
                          widget.repeatMode == 'off'
                              ? Icons.repeat_rounded
                              : widget.repeatMode == 'one'
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                          color: widget.repeatMode != 'off'
                              ? AppColors.celestialCyan
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: widget.onRepeat,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.nebulaDark,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: AppColors.cosmicGray,
        ),
      ),
    );
  }
}
