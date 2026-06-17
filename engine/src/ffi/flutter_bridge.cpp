#include "ffi/flutter_bridge.h"
#include "core/playback_engine.h"
#include <cstring>

using namespace aether;

// ── Helper to cast handle ──
static inline PlaybackEngine* as_engine(void* handle) {
    return static_cast<PlaybackEngine*>(handle);
}

// ── Lifecycle ──

void* engine_create() {
    return new (std::nothrow) PlaybackEngine();
}

void engine_destroy(void* handle) {
    if (handle) {
        delete as_engine(handle);
    }
}

int engine_initialize(void* handle) {
    if (!handle) return -1;
    return as_engine(handle)->initialize() ? 0 : -1;
}

// ── Media Operations ──

int engine_open(void* handle, const char* url, const char* headers_json) {
    if (!handle || !url) return -1;
    return as_engine(handle)->open(
        url,
        headers_json ? headers_json : ""
    ) ? 0 : -1;
}

void engine_play(void* handle) {
    if (handle) as_engine(handle)->play();
}

void engine_pause(void* handle) {
    if (handle) as_engine(handle)->pause();
}

void engine_toggle_play(void* handle) {
    if (handle) as_engine(handle)->togglePlay();
}

void engine_seek(void* handle, double position_seconds) {
    if (handle) as_engine(handle)->seek(position_seconds);
}

void engine_stop(void* handle) {
    if (handle) as_engine(handle)->stop();
}

// ── Property Setters ──

void engine_set_volume(void* handle, double volume) {
    if (handle) as_engine(handle)->setVolume(volume);
}

void engine_set_playback_speed(void* handle, double speed) {
    if (handle) as_engine(handle)->setPlaybackSpeed(speed);
}

void engine_set_audio_track(void* handle, int index) {
    if (handle) as_engine(handle)->setAudioTrack(index);
}

void engine_set_subtitle_track(void* handle, int index) {
    if (handle) as_engine(handle)->setSubtitleTrack(index);
}

// ── Property Getters ──

double engine_get_position(void* handle) {
    return handle ? as_engine(handle)->getPosition() : 0.0;
}

double engine_get_duration(void* handle) {
    return handle ? as_engine(handle)->getDuration() : 0.0;
}

double engine_get_volume(void* handle) {
    return handle ? as_engine(handle)->getVolume() : 100.0;
}

double engine_get_playback_speed(void* handle) {
    return handle ? as_engine(handle)->getPlaybackSpeed() : 1.0;
}

int engine_get_state(void* handle) {
    return handle ? static_cast<int>(as_engine(handle)->getState()) : 0;
}

int engine_is_playing(void* handle) {
    return handle && as_engine(handle)->isPlaying() ? 1 : 0;
}

int engine_is_buffering(void* handle) {
    return handle && as_engine(handle)->isBuffering() ? 1 : 0;
}

// ── Callbacks ──

void engine_set_state_callback(void* handle, StateCallbackFn fn) {
    if (!handle) return;
    as_engine(handle)->setStateCallback([fn](EngineState state) {
        if (fn) fn(static_cast<int>(state));
    });
}

void engine_set_position_callback(void* handle, PositionCallbackFn fn) {
    if (!handle) return;
    as_engine(handle)->setPositionCallback([fn](double seconds) {
        if (fn) fn(seconds);
    });
}

void engine_set_duration_callback(void* handle, DurationCallbackFn fn) {
    if (!handle) return;
    as_engine(handle)->setDurationCallback([fn](double seconds) {
        if (fn) fn(seconds);
    });
}

void engine_set_buffering_callback(void* handle, BufferingCallbackFn fn) {
    if (!handle) return;
    as_engine(handle)->setBufferingCallback([fn](bool buffering) {
        if (fn) fn(buffering ? 1 : 0);
    });
}

void engine_set_completion_callback(void* handle, CompletionCallbackFn fn) {
    if (!handle) return;
    as_engine(handle)->setCompletionCallback([fn]() {
        if (fn) fn();
    });
}
