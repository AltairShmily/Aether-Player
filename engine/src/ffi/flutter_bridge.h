#pragma once

/// Flutter FFI Bridge — C interface for Dart dart:ffi
///
/// All functions use extern "C" linkage for FFI compatibility.
/// Engine handle is an opaque pointer (void*).

#ifdef _WIN32
    #define AETHER_EXPORT __declspec(dllexport)
#else
    #define AETHER_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// Callback function types (matching Dart FFI signatures)
typedef void (*StateCallbackFn)(int state);
typedef void (*PositionCallbackFn)(double seconds);
typedef void (*DurationCallbackFn)(double seconds);
typedef void (*BufferingCallbackFn)(int buffering);
typedef void (*CompletionCallbackFn)();

/// Create a new playback engine instance. Returns opaque handle.
AETHER_EXPORT void* engine_create();

/// Destroy engine and free all resources.
AETHER_EXPORT void engine_destroy(void* handle);

/// Initialize the engine (must call before any other operation). Returns 0 on success.
AETHER_EXPORT int engine_initialize(void* handle);

/// Open a media URL. headers_json is a string of HTTP headers.
/// Returns 0 on success.
AETHER_EXPORT int engine_open(void* handle, const char* url, const char* headers_json);

/// Start playback.
AETHER_EXPORT void engine_play(void* handle);

/// Pause playback.
AETHER_EXPORT void engine_pause(void* handle);

/// Toggle play/pause.
AETHER_EXPORT void engine_toggle_play(void* handle);

/// Seek to position (in seconds).
AETHER_EXPORT void engine_seek(void* handle, double position_seconds);

/// Stop playback.
AETHER_EXPORT void engine_stop(void* handle);

/// Set volume (0.0 - 100.0).
AETHER_EXPORT void engine_set_volume(void* handle, double volume);

/// Set playback speed/rate.
AETHER_EXPORT void engine_set_playback_speed(void* handle, double speed);

/// Set audio track by index (0-based).
AETHER_EXPORT void engine_set_audio_track(void* handle, int index);

/// Set subtitle track by index (-1 = off).
AETHER_EXPORT void engine_set_subtitle_track(void* handle, int index);

/// Get current position in seconds.
AETHER_EXPORT double engine_get_position(void* handle);

/// Get duration in seconds.
AETHER_EXPORT double engine_get_duration(void* handle);

/// Get volume (0.0 - 100.0).
AETHER_EXPORT double engine_get_volume(void* handle);

/// Get playback speed.
AETHER_EXPORT double engine_get_playback_speed(void* handle);

/// Get player state (int matching EngineState enum).
AETHER_EXPORT int engine_get_state(void* handle);

/// Check if currently playing (1 = yes, 0 = no).
AETHER_EXPORT int engine_is_playing(void* handle);

/// Check if currently buffering (1 = yes, 0 = no).
AETHER_EXPORT int engine_is_buffering(void* handle);

/// Set state change callback.
AETHER_EXPORT void engine_set_state_callback(void* handle, StateCallbackFn fn);

/// Set position update callback.
AETHER_EXPORT void engine_set_position_callback(void* handle, PositionCallbackFn fn);

/// Set duration change callback.
AETHER_EXPORT void engine_set_duration_callback(void* handle, DurationCallbackFn fn);

/// Set buffering callback.
AETHER_EXPORT void engine_set_buffering_callback(void* handle, BufferingCallbackFn fn);

/// Set playback completion callback.
AETHER_EXPORT void engine_set_completion_callback(void* handle, CompletionCallbackFn fn);

#ifdef __cplusplus
}
#endif
