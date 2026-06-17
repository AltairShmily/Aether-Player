import '../models/playback_models.dart';

/// Playback delivery mode selected by the strategy engine.
enum PlayMode {
  /// Stream the file directly with no server-side processing.
  directPlay,

  /// Stream via the direct stream URL (remuxed, not transcoded).
  directStream,

  /// Server-side transcode required.
  transcode,
}

/// The result of a playback strategy decision.
class PlaybackDecision {
  /// The selected playback mode.
  final PlayMode mode;

  /// The URL to use for playback.
  final String streamUrl;

  /// Human-readable explanation of why this mode was chosen.
  final String reason;

  const PlaybackDecision({
    required this.mode,
    required this.streamUrl,
    required this.reason,
  });

  @override
  String toString() =>
      'PlaybackDecision(mode: $mode, url: $streamUrl, reason: $reason)';
}

/// Determines the optimal playback delivery strategy for a media source.
///
/// Follows a preference order: direct play → direct stream → transcode.
/// Falls back gracefully when the preferred mode is unavailable.
class PlaybackStrategy {
  PlaybackStrategy._();

  /// Automatically selects the best playback mode for [source].
  ///
  /// Preference order:
  /// 1. Direct play / direct stream — when a direct stream URL is available.
  /// 2. Transcode — server-side transcode URL.
  ///
  /// Falls back to any available URL if none of the above match cleanly.
  /// Throws [StateError] if the source provides no usable URL at all.
  static PlaybackDecision auto(MediaSourceInfo source) {
    // Best case: direct stream URL available (direct play or direct stream).
    // The current model doesn't distinguish between direct play and direct
    // stream capabilities, so we treat a non-empty directStreamUrl as
    // direct play by default — the server has confirmed compatibility.
    if (source.hasDirectStream) {
      return PlaybackDecision(
        mode: PlayMode.directPlay,
        streamUrl: source.directStreamUrl,
        reason: 'File is natively compatible; direct stream URL available.',
      );
    }

    // Transcode — server will re-encode the stream.
    if (source.hasTranscode) {
      return PlaybackDecision(
        mode: PlayMode.transcode,
        streamUrl: source.transcodeUrl,
        reason: 'No direct path available; server transcode selected.',
      );
    }

    // Fallback: try transcode URL even if hasTranscode was false
    // (handles edge cases where getter logic differs from raw field).
    if (source.transcodeUrl.isNotEmpty) {
      return PlaybackDecision(
        mode: PlayMode.transcode,
        streamUrl: source.transcodeUrl,
        reason: 'Fallback to transcode URL.',
      );
    }

    throw StateError(
      'No playback URL available for source "${source.name}" '
      '(id: ${source.id}). The server did not provide a direct stream '
      'or transcode URL.',
    );
  }

  /// Forces transcoded playback for [source], regardless of compatibility.
  ///
  /// Uses the transcode URL when available, otherwise falls back to [auto].
  static PlaybackDecision forceTranscode(MediaSourceInfo source) {
    if (source.hasTranscode) {
      return PlaybackDecision(
        mode: PlayMode.transcode,
        streamUrl: source.transcodeUrl,
        reason: 'Transcode explicitly forced.',
      );
    }

    // No transcode URL — fall back to best available option.
    return auto(source);
  }
}
