#pragma once

#include <string>
#include <functional>
#include <vector>
#include <atomic>
#include <thread>
#include <mutex>
#include <mpv/client.h>

namespace aether {

/// Player state matching Dart's PlayerState enum
enum class EngineState {
    Idle = 0,
    Playing = 1,
    Paused = 2,
    Buffering = 3,
    Stopped = 4,
    Error = 5,
};

/// Track info matching Dart's TrackInfo
struct EngineTrackInfo {
    int index;
    std::string language;
    std::string title;
    std::string codec;
    std::string type; // "audio" or "subtitle"
};

/// Callback types
using StateCallback    = std::function<void(EngineState)>;
using PositionCallback = std::function<void(double seconds)>;
using DurationCallback = std::function<void(double seconds)>;
using BufferingCallback = std::function<void(bool)>;
using CompletionCallback = std::function<void()>;
using TracksCallback   = std::function<void(const std::vector<EngineTrackInfo>&,
                                             const std::vector<EngineTrackInfo>&)>;

/// C++ wrapper around libmpv
///
/// Provides a clean RAII interface for media playback.
/// Runs its own event loop thread for mpv events.
class PlaybackEngine {
public:
    PlaybackEngine();
    ~PlaybackEngine();

    // Non-copyable, non-movable
    PlaybackEngine(const PlaybackEngine&) = delete;
    PlaybackEngine& operator=(const PlaybackEngine&) = delete;

    /// Initialize the mpv instance. Returns true on success.
    bool initialize();

    /// Open a media URL with optional HTTP headers (JSON format)
    bool open(const std::string& url, const std::string& headers_json = "");

    /// Playback controls
    void play();
    void pause();
    void togglePlay();
    void seek(double position_seconds);
    void stop();

    /// Set volume (0.0 - 100.0, mpv range)
    void setVolume(double volume);

    /// Set playback speed/rate
    void setPlaybackSpeed(double speed);

    /// Set audio track by index (0-based, after filtering auto/no)
    void setAudioTrack(int index);

    /// Set subtitle track by index (-1 = off, 0+ = track index)
    void setSubtitleTrack(int index);

    /// Getters
    double getPosition() const;
    double getDuration() const;
    double getVolume() const;
    double getPlaybackSpeed() const;
    EngineState getState() const;
    bool isPlaying() const;
    bool isBuffering() const;

    /// Get current tracks
    std::vector<EngineTrackInfo> getAudioTracks() const;
    std::vector<EngineTrackInfo> getSubtitleTracks() const;
    int getCurrentAudioTrackIndex() const;
    int getCurrentSubtitleTrackIndex() const;

    /// Callbacks
    void setStateCallback(StateCallback cb);
    void setPositionCallback(PositionCallback cb);
    void setDurationCallback(DurationCallback cb);
    void setBufferingCallback(BufferingCallback cb);
    void setCompletionCallback(CompletionCallback cb);
    void setTracksCallback(TracksCallback cb);

    /// Release all resources
    void dispose();

private:
    /// Event loop thread function
    void eventLoop();

    /// Handle a single mpv event
    void handleEvent(mpv_event* event);

    /// Refresh track list from mpv
    void refreshTracks();

    /// Update current track indices
    void updateCurrentTracks();

    mpv_handle* _handle = nullptr;
    std::thread _eventThread;
    std::atomic<bool> _running{false};

    // Cached state
    std::atomic<EngineState> _state{EngineState::Idle};
    std::atomic<double> _position{0.0};
    std::atomic<double> _duration{0.0};
    std::atomic<double> _volume{100.0};
    std::atomic<double> _playbackSpeed{1.0};
    std::atomic<bool> _isBuffering{false};

    // Tracks
    mutable std::mutex _tracksMutex;
    std::vector<EngineTrackInfo> _audioTracks;
    std::vector<EngineTrackInfo> _subtitleTracks;
    int _currentAudioTrackIndex = -1;
    int _currentSubtitleTrackIndex = -1;

    // Callbacks
    StateCallback _stateCallback;
    PositionCallback _positionCallback;
    DurationCallback _durationCallback;
    BufferingCallback _bufferingCallback;
    CompletionCallback _completionCallback;
    TracksCallback _tracksCallback;
};

} // namespace aether
