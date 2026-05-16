import 'media_models.dart' show MediaSource, MediaStream;

/// Represents an audio or subtitle track.
class TrackInfo {
  final int index;
  final String language;
  final String title;
  final String codec;
  final String type; // 'audio' or 'subtitle'

  const TrackInfo({
    required this.index,
    this.language = '',
    this.title = '',
    this.codec = '',
    required this.type,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    return TrackInfo(
      index: json['Index'] as int? ?? 0,
      language: json['Language'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      codec: json['Codec'] as String? ?? '',
      type: json['Type'] as String? ?? '',
    );
  }

  bool get isAudio => type == 'audio';
  bool get isSubtitle => type == 'subtitle';

  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (language.isNotEmpty && codec.isNotEmpty) {
      return '$language ($codec)';
    }
    if (language.isNotEmpty) return language;
    if (codec.isNotEmpty) return codec;
    return 'Track ${index + 1}';
  }
}

/// Playback info from Emby's PlaybackInfo API response.
///
/// Replaces the existing [MediaStreamInfo] wrapper in media_models.dart
/// with a more accurately named class.
class PlaybackInfo {
  final List<MediaSourceInfo> mediaSources;
  final String playSessionId;

  const PlaybackInfo({
    this.mediaSources = const [],
    this.playSessionId = '',
  });

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      mediaSources: (json['MediaSources'] as List<dynamic>?)
              ?.map((e) => MediaSourceInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      playSessionId: json['PlaySessionId'] as String? ?? '',
    );
  }

  MediaSourceInfo? get firstSource =>
      mediaSources.isNotEmpty ? mediaSources.first : null;
}

/// Extended media source info with streaming URLs.
///
/// Superset of [MediaSource] from media_models.dart, adding path,
/// direct stream URL, and transcode URL fields.
class MediaSourceInfo {
  final String id;
  final String name;
  final String container;
  final String path;
  final int size;
  final int bitrate;
  final List<MediaStreamInfo> mediaStreams;
  final String directStreamUrl;
  final String transcodeUrl;

  const MediaSourceInfo({
    required this.id,
    this.name = '',
    this.container = '',
    this.path = '',
    this.size = 0,
    this.bitrate = 0,
    this.mediaStreams = const [],
    this.directStreamUrl = '',
    this.transcodeUrl = '',
  });

  factory MediaSourceInfo.fromJson(Map<String, dynamic> json) {
    return MediaSourceInfo(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      container: json['Container'] as String? ?? '',
      path: json['Path'] as String? ?? '',
      size: json['Size'] as int? ?? 0,
      bitrate: json['Bitrate'] as int? ?? 0,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
              ?.map((e) =>
                  MediaStreamInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      directStreamUrl: json['DirectStreamUrl'] as String? ?? '',
      transcodeUrl: json['TranscodingUrl'] as String? ?? '',
    );
  }

  /// Convert to the simpler [MediaSource] model from media_models.
  MediaSource toMediaSource() {
    return MediaSource(
      id: id,
      name: name,
      container: container,
      size: size,
      bitrate: bitrate,
      mediaStreams: mediaStreams
          .map((s) => MediaStream(
                type: s.type,
                codec: s.codec,
                language: s.language,
                displayTitle: s.displayTitle,
                width: s.width,
                height: s.height,
                bitRate: s.bitrate,
                index: s.index,
              ))
          .toList(),
    );
  }

  bool get hasDirectStream => directStreamUrl.isNotEmpty;
  bool get hasTranscode => transcodeUrl.isNotEmpty;

  String get sizeText {
    if (size <= 0) return '';
    if (size < 1024 * 1024) return '${(size / 1024).round()} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).round()} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  List<MediaStreamInfo> get videoStreams =>
      mediaStreams.where((s) => s.isVideo).toList();

  List<MediaStreamInfo> get audioStreams =>
      mediaStreams.where((s) => s.isAudio).toList();

  List<MediaStreamInfo> get subtitleStreams =>
      mediaStreams.where((s) => s.isSubtitle).toList();
}

/// Detailed info for a single media stream (audio, video, or subtitle).
///
/// This replaces the per-stream data that was previously in
/// [MediaStream] from media_models.dart, with a richer model
/// for playback use.
class MediaStreamInfo {
  final String type;
  final int index;
  final String codec;
  final String language;
  final String displayTitle;
  final int width;
  final int height;
  final int bitrate;

  const MediaStreamInfo({
    required this.type,
    this.index = 0,
    this.codec = '',
    this.language = '',
    this.displayTitle = '',
    this.width = 0,
    this.height = 0,
    this.bitrate = 0,
  });

  factory MediaStreamInfo.fromJson(Map<String, dynamic> json) {
    return MediaStreamInfo(
      type: json['Type'] as String? ?? '',
      index: json['Index'] as int? ?? 0,
      codec: json['Codec'] as String? ?? '',
      language: json['Language'] as String? ?? '',
      displayTitle: json['DisplayTitle'] as String? ?? '',
      width: json['Width'] as int? ?? 0,
      height: json['Height'] as int? ?? 0,
      bitrate: json['BitRate'] as int? ?? 0,
    );
  }

  bool get isVideo => type == 'Video';
  bool get isAudio => type == 'Audio';
  bool get isSubtitle => type == 'Subtitle';

  String get resolution {
    if (width == 0 || height == 0) return '';
    if (height >= 2160) return '4K';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return '${width}x$height';
  }

  /// Convert to the simpler [MediaStream] model from media_models.
  MediaStream toMediaStream() {
    return MediaStream(
      type: type,
      codec: codec,
      language: language,
      displayTitle: displayTitle,
      width: width,
      height: height,
      bitRate: bitrate,
      index: index,
    );
  }
}

/// Events emitted by the media player.
enum PlayerEvent {
  play,
  pause,
  seek,
  positionChanged,
  durationChanged,
  stateChanged,
  error,
  completed,
  buffering,
  buffered,
  tracksChanged,
}

/// Playback speed options.
enum PlaybackSpeed {
  half(0.5, '0.5x'),
  normal(1.0, '1.0x'),
  onePointFive(1.5, '1.5x'),
  double_(2.0, '2.0x');

  final double value;
  final String display;

  const PlaybackSpeed(this.value, this.display);
}
