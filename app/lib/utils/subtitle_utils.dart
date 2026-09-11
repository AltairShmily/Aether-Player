import '../services/player_engine.dart';

/// 当前字幕的短标签，用于播放器底栏字幕按钮旁的角标（中 / 英 / 关）。
///
/// 让用户不打开任何菜单就能知道当前生效的是哪条字幕 —— 此前字幕只藏在
/// 设置弹窗里，底栏看不出是否开了中字。
///
/// Emby 返回的语言代码形式不统一（zh / chi / zh-cn / 简体中文…），
/// 故做多形式归并；无法识别时退回原始代码的前两字符，至少能区分不同轨道。
String subtitleShortLabel(List<TrackInfo> tracks, int currentIndex) {
  if (currentIndex < 0) return '关';

  final match = tracks.where((t) => t.index == currentIndex);
  if (match.isEmpty) return '关';

  final track = match.first;
  final raw = (track.language.isNotEmpty ? track.language : track.title)
      .trim()
      .toLowerCase();
  if (raw.isEmpty) return '字';

  if (raw.startsWith('zh') || raw.startsWith('chi') || raw.contains('中文')) {
    return '中';
  }
  if (raw.startsWith('en') || raw.startsWith('eng') || raw.contains('英')) {
    return '英';
  }
  if (raw.startsWith('ja') || raw.startsWith('jpn') || raw.contains('日')) {
    return '日';
  }
  if (raw.startsWith('ko') || raw.startsWith('kor') || raw.contains('韩')) {
    return '韩';
  }
  return raw.length > 2 ? raw.substring(0, 2) : raw;
}
