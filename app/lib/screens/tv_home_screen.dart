// ══════════════════════════════════════════════════════════════════════════════
//  tv_home_screen.dart — Android TV 全屏主界面
// ══════════════════════════════════════════════════════════════════════════════
//
//  专为大屏 TV 设计的沉浸式首页，支持 D-Pad 焦点导航。
//  布局自上而下：顶部导航栏 → 推荐横幅 → 最近更新 → 媒体库 → 热门动漫
//
//  依赖:
//    - Riverpod (ConsumerStatefulWidget)
//    - AppColors 色彩系统 (Celestial Glow Theme)
//    - homeProvider / authProvider 数据层
//    - MediaItem / MediaFolder 模型
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../providers/home_provider.dart';
import '../providers/auth_provider.dart';
import '../models/media_models.dart';
import 'series_detail_screen.dart';
import 'episode_detail_screen.dart';
import 'media_detail_screen.dart';
import 'tv_search_overlay.dart';
import '../widgets/aether_page_route.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TV 主界面
// ══════════════════════════════════════════════════════════════════════════════

class TvHomeScreen extends ConsumerStatefulWidget {
  const TvHomeScreen({super.key});

  @override
  ConsumerState<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends ConsumerState<TvHomeScreen> {
  // ── 时钟定时器 ──
  Timer? _clockTimer;
  String _clockText = '';
  String _serverUrl = 'http://localhost:19800';

  // ── 顶部导航栏 ──
  final List<_TabItem> _tabs = [
    _TabItem(label: '主页', icon: Icons.home_rounded),
    _TabItem(label: '电影', icon: Icons.movie_rounded),
    _TabItem(label: '剧集', icon: Icons.tv_rounded),
    _TabItem(label: '动漫', icon: Icons.animation_rounded),
    _TabItem(label: '设置', icon: Icons.settings_rounded),
  ];
  int _activeTabIndex = 0;

  // ── 焦点节点 (用于 D-Pad 导航) ──
  final FocusNode _scaffoldFocusNode = FocusNode();
  final FocusNode _bannerFocusNode = FocusNode();
  final List<FocusNode> _cardFocusNodes = [];
  final List<FocusNode> _libraryFocusNodes = [];
  final List<FocusNode> _tabFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) => _updateClock());

    // 初始化 tab 焦点节点
    for (int i = 0; i < _tabs.length; i++) {
      _tabFocusNodes.add(FocusNode());
    }

    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServerUrl();
      ref.read(homeProvider.notifier).loadAll();
    });
  }

  Future<void> _loadServerUrl() async {
    final url = await ref.read(storageServiceProvider).getServerUrl();
    if (mounted && url != null) setState(() => _serverUrl = url);
  }

  /// 更新时钟显示 (HH:mm 格式)
  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _clockText =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scaffoldFocusNode.dispose();
    _bannerFocusNode.dispose();
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    for (final node in _libraryFocusNodes) {
      node.dispose();
    }
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ── D-Pad 按键处理 ──
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // 这里可以扩展更复杂的焦点路由逻辑
    // 目前依赖 Flutter 内置 FocusTraversalGroup 处理方向键
    return KeyEventResult.ignored;
  }

  // ── 导航到媒体详情 ──
  void _navigateToItem(MediaItem item) {
    Widget destination;
    if (item.isSeries) {
      destination = SeriesDetailScreen(series: item);
    } else if (item.isEpisode) {
      destination = EpisodeDetailScreen(item: item);
    } else {
      destination = MediaDetailScreen(item: item);
    }
    Navigator.of(context).push(AetherPageRoute(page: destination, type: AetherTransitionType.slideFromRight));
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Focus(
        focusNode: _scaffoldFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: FocusTraversalGroup(
          child: Stack(
            children: [
              // ── 主内容区 ──
              _buildMainContent(homeState, authState),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  主内容区 (可滚动)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent(HomeState homeState, AuthState authState) {
    return Column(
      children: [
        // ── 顶部导航栏 ──
        _buildTopBar(authState),

        // ── 可滚动内容 ──
        Expanded(
          child: _buildTabContent(homeState),
        ),
      ],
    );
  }

  Widget _buildTabContent(HomeState homeState) {
    switch (_activeTabIndex) {
      case 0: // 主页
        return _buildHomeTab(homeState);
      case 1: // 电影
        return _buildLibraryTab(homeState, 'movies', '电影');
      case 2: // 剧集
        return _buildLibraryTab(homeState, 'tvshows', '剧集');
      case 3: // 动漫
        return _buildAnimeTab(homeState);
      case 4: // 设置
        return _buildSettingsTab();
      default:
        return _buildHomeTab(homeState);
    }
  }

  Widget _buildHomeTab(HomeState homeState) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // ── 推荐横幅 ──
          _buildFeaturedBanner(homeState),
          const SizedBox(height: 36),
          // ── 最近更新 ──
          if (homeState.resumeItems.isNotEmpty)
            _TvSection(
              title: '最近更新',
              child: _TvMediaRow(
                items: homeState.resumeItems,
                focusNodes: _cardFocusNodes,
                onItemTap: _navigateToItem,
                serverUrl: _serverUrl,
              ),
            ),
          const SizedBox(height: 36),
          // ── 媒体库 ──
          if (homeState.libraries.isNotEmpty)
            _TvSection(
              title: '媒体库',
              child: _TvLibraryRow(
                libraries: homeState.libraries,
                libraryItems: homeState.libraryItems,
                focusNodes: _libraryFocusNodes,
              ),
            ),
          const SizedBox(height: 36),
          // ── 热门动漫 ──
          if (_getAnimeItems(homeState).isNotEmpty)
            _TvSection(
              title: '热门动漫',
              child: _TvMediaRow(
                items: _getAnimeItems(homeState),
                onItemTap: _navigateToItem,
                serverUrl: _serverUrl,
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(HomeState homeState, String collectionType, String title) {
    // 查找对应类型的库
    MediaFolder? targetLib;
    for (final lib in homeState.libraries) {
      if (lib.collectionType == collectionType) {
        targetLib = lib;
        break;
      }
    }
    final items = targetLib != null ? (homeState.libraryItems[targetLib.id] ?? <MediaItem>[]) : <MediaItem>[];

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (items.isNotEmpty)
            _TvSection(
              title: title,
              child: _TvMediaRow(
                items: items,
                onItemTap: _navigateToItem,
                serverUrl: _serverUrl,
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(
                  '暂无内容',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAnimeTab(HomeState homeState) {
    final animeItems = _getAnimeItems(homeState);

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (animeItems.isNotEmpty)
            _TvSection(
              title: '热门动漫',
              child: _TvMediaRow(
                items: animeItems,
                onItemTap: _navigateToItem,
                serverUrl: _serverUrl,
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(
                  '暂无动漫内容',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          // 播放设置
          _buildSettingsGroup('播放', [
            _buildSettingsRow('自动播放下一集', '当前集结束后自动播放下一集', true),
            _buildSettingsRow('硬件加速', '使用 GPU 进行视频解码', true),
          ]),
          const SizedBox(height: 24),
          // 外观设置
          _buildSettingsGroup('外观', [
            _buildSettingsRow('深色模式', '界面主题颜色方案', true, value: '深色'),
            _buildSettingsRow('噪点纹理', '界面元素启用噪点效果', true),
          ]),
          const SizedBox(height: 24),
          // 网络设置
          _buildSettingsGroup('网络', [
            _buildSettingsRow('远程访问', '允许通过互联网连接服务器', false),
            _buildSettingsRow('带宽限制', '远程播放时的最大带宽', true, value: '自动'),
          ]),
          const SizedBox(height: 24),
          // 关于
          _buildSettingsGroup('关于', [
            _buildSettingsRow('版本', '', false, value: 'v1.0.0-dev'),
            _buildSettingsRow('架构', '', false, value: 'Flutter + Go + MPV'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.celestialCyan,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.nebulaDark,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(String label, String description, bool isToggle, {String? value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          if (isToggle && value == null)
            Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.celestialCyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.deepVoid,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 获取动漫项目 ──
  List<MediaItem> _getAnimeItems(HomeState homeState) {
    // 查找动漫类型的 library
    for (final lib in homeState.libraries) {
      if (lib.collectionType == 'tvshows' &&
          lib.name.toLowerCase().contains('动漫')) {
        return homeState.libraryItems[lib.id] ?? [];
      }
    }
    // 如果找不到专门的动漫库，返回空列表
    return [];
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  顶部导航栏
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(AuthState authState) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 56, right: 56),
      height: 80,
      child: Row(
        children: [
          // ── Logo ──
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.celestialCyan, AppColors.novaPurple],
            ).createShader(bounds),
            child: const Text(
              'AETHER',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.white, // ShaderMask 会替换颜色
              ),
            ),
          ),

          const SizedBox(width: 48),

          // ── Tab 导航按钮 ──
          Row(
            children: List.generate(_tabs.length, (index) {
              final isActive = _activeTabIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Focus(
                  focusNode: _tabFocusNodes[index],
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _activeTabIndex = index);
                      // TODO: 实现对应 tab 的内容切换
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.celestialCyan
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tabs[index].label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppColors.deepVoid
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // ── 搜索图标 ──
          Focus(
            child: GestureDetector(
              onTap: () {
                TvSearchOverlay.show(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ── 时钟 ──
          Text(
            _clockText,
            style: const TextStyle(
              fontFamily: 'DM Mono',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  推荐横幅 (21:9 比例)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildFeaturedBanner(HomeState homeState) {
    final featuredItem =
        homeState.resumeItems.isNotEmpty ? homeState.resumeItems.first : null;
    final imageUrl = featuredItem != null
        ? '$_serverUrl/api/images/${featuredItem.id}/Backdrop?maxWidth=800'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Focus(
        focusNode: _bannerFocusNode,
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return AnimatedScale(
              scale: isFocused ? 1.01 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isFocused
                      ? Border.all(
                          color: AppColors.celestialCyan,
                          width: 3,
                        )
                      : null,
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color:
                                AppColors.celestialCyan.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── 背景图 / 渐变占位 ──
                        if (imageUrl != null && featuredItem != null)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderGradient(),
                          )
                        else
                          _buildPlaceholderGradient(),

                        // ── 左侧暗色渐变遮罩 ──
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xD90A0E14), // 85% deepVoid
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.6],
                            ),
                          ),
                        ),

                        // ── 底部渐变遮罩 ──
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x800A0E14), // 50% deepVoid
                              ],
                              stops: [0.5, 1.0],
                            ),
                          ),
                        ),

                        // ── 内容区域 (左下方) ──
                        if (featuredItem != null)
                          Positioned(
                            left: 48,
                            bottom: 36,
                            right: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 推荐观看徽章
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.celestialCyan
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.celestialCyan
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    '推荐观看',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.celestialCyan,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 标题
                                Text(
                                  featuredItem.isEpisode
                                      ? featuredItem.seriesName
                                      : featuredItem.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // 简介
                                Text(
                                  featuredItem.overview.isNotEmpty
                                      ? featuredItem.overview
                                      : '暂无简介',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 16),

                                // 播放按钮
                                GestureDetector(
                                  onTap: () => _navigateToItem(featuredItem),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 28, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.celestialCyan, AppColors.novaPurple],
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.celestialCyan.withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.deepVoid,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '立即播放',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.deepVoid,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 渐变占位背景
  Widget _buildPlaceholderGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.nebulaDark,
            AppColors.stardust,
            AppColors.nebulaDark,
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TabItem — 导航栏 Tab 数据
// ══════════════════════════════════════════════════════════════════════════════

class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem({required this.label, required this.icon});
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TvSection — TV 章节组件 (标题 + 3px 渐变线)
// ══════════════════════════════════════════════════════════════════════════════

class _TvSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _TvSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 标题栏 ──
        Padding(
          padding: const EdgeInsets.only(left: 56, bottom: 16),
          child: Row(
            children: [
              // 3px 强调色渐变线
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        // ── 内容 ──
        child,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TvMediaRow — TV 媒体卡片横向滚动行
// ══════════════════════════════════════════════════════════════════════════════

class _TvMediaRow extends StatelessWidget {
  final List<MediaItem> items;
  final List<FocusNode>? focusNodes;
  final Function(MediaItem) onItemTap;
  final String serverUrl;

  const _TvMediaRow({
    required this.items,
    this.focusNodes,
    required this.onItemTap,
    this.serverUrl = 'http://localhost:19800',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 56),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          final focusNode =
              focusNodes != null && index < focusNodes!.length
                  ? focusNodes![index]
                  : null;
          return _TvMediaCard(
            item: item,
            focusNode: focusNode,
            isFirst: index == 0,
            onTap: () => onItemTap(item),
            serverUrl: serverUrl,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TvMediaCard — 单个 TV 媒体卡片 (190px 宽, 2:3 海报)
// ══════════════════════════════════════════════════════════════════════════════

class _TvMediaCard extends StatelessWidget {
  final MediaItem item;
  final FocusNode? focusNode;
  final bool isFirst;
  final VoidCallback onTap;
  final String serverUrl;

  const _TvMediaCard({
    required this.item,
    this.focusNode,
    this.isFirst = false,
    required this.onTap,
    this.serverUrl = 'http://localhost:19800',
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        '$serverUrl/api/images/${item.id}/Primary?maxWidth=300';

    return SizedBox(
      width: 190,
      child: Focus(
        focusNode: focusNode,
        autofocus: isFirst,
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: onTap,
              child: AnimatedScale(
                scale: isFocused ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 海报 (2:3 比例) ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 190,
                      height: 285, // 2:3 ratio (190 * 1.5)
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isFocused
                            ? Border.all(
                                color: AppColors.celestialCyan,
                                width: 3,
                              )
                            : null,
                        boxShadow: isFocused
                            ? [
                                AppColors.glowCyan(blur: 24, spread: 4),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 海报背景
                            Container(
                              color: AppColors.stardust,
                              child: item.hasPrimaryImage
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPosterPlaceholder(),
                                    )
                                  : _buildPosterPlaceholder(),
                            ),

                            // 底部渐变遮罩
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xCC0A0E14),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 类型标签 (右上角)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.deepVoid.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isSeries
                                      ? '剧集'
                                      : item.isMovie
                                          ? '电影'
                                          : '影片',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.celestialCyan,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── 标题 ──
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // ── 年份 ──
                    if (item.productionYear > 0)
                      Text(
                        '${item.productionYear}',
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 海报占位图
  Widget _buildPosterPlaceholder() {
    return Container(
      color: AppColors.stardust,
      child: const Center(
        child: Icon(
          Icons.movie_rounded,
          color: AppColors.textTertiary,
          size: 48,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TvLibraryRow — 媒体库卡片横向滚动行
// ══════════════════════════════════════════════════════════════════════════════

class _TvLibraryRow extends StatelessWidget {
  final List<MediaFolder> libraries;
  final Map<String, List<MediaItem>> libraryItems;
  final List<FocusNode> focusNodes;

  const _TvLibraryRow({
    required this.libraries,
    required this.libraryItems,
    required this.focusNodes,
  });

  @override
  Widget build(BuildContext context) {
    // 确保 focusNodes 数量足够
    while (focusNodes.length < libraries.length) {
      focusNodes.add(FocusNode());
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 56),
        itemCount: libraries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final lib = libraries[index];
          final itemCount = libraryItems[lib.id]?.length ?? 0;
          return _TvLibraryCard(
            library: lib,
            index: index,
            itemCount: itemCount,
            focusNode: focusNodes[index],
            isFirst: index == 0,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TvLibraryCard — 单个媒体库卡片 (260px 宽, 16:9 比例)
// ══════════════════════════════════════════════════════════════════════════════

class _TvLibraryCard extends StatelessWidget {
  final MediaFolder library;
  final int index;
  final int itemCount;
  final FocusNode focusNode;
  final bool isFirst;

  const _TvLibraryCard({
    required this.library,
    required this.index,
    required this.itemCount,
    required this.focusNode,
    this.isFirst = false,
  });

  /// 根据库类型获取对应图标
  IconData _getLibraryIcon(String collectionType) {
    switch (collectionType) {
      case 'movies':
        return Icons.movie_rounded;
      case 'tvshows':
        return Icons.tv_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  /// 获取库类型的渐变色
  LinearGradient _getLibraryGradient(int index) {
    final colors = AppColors.gradientPalette;
    final startColor = colors[index % colors.length];
    final endColor = colors[(index + 3) % colors.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startColor, endColor],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 146, // 16:9 ratio (260 / 16 * 9)
      child: Focus(
        focusNode: focusNode,
        autofocus: isFirst,
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: () {
                // TODO: 导航到库详情页
              },
              child: AnimatedScale(
                scale: isFocused ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isFocused
                        ? Border.all(
                            color: AppColors.celestialCyan,
                            width: 3,
                          )
                        : null,
                    boxShadow: isFocused
                        ? [
                            AppColors.glowCyan(blur: 20, spread: 2),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── 渐变背景 ──
                        Container(
                          decoration: BoxDecoration(
                            gradient: _getLibraryGradient(index),
                          ),
                        ),

                        // ── 底部渐变遮罩 ──
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xCC0A0E14),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── 内容区域 ──
                        Positioned(
                          left: 20,
                          bottom: 16,
                          right: 20,
                          child: Row(
                            children: [
                              // 图标
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.deepVoid.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getLibraryIcon(library.collectionType),
                                  color: AppColors.celestialCyan,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // 名称和数量
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      library.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$itemCount 部内容',
                                      style: const TextStyle(
                                        fontFamily: 'DM Mono',
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
