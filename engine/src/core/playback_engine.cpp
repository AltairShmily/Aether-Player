#include "core/playback_engine.h"
#include <cstdint>
#include <cstring>
#include <sstream>
#include <algorithm>

namespace aether {

// ── Constructor / Destructor ──────────────────────────────────

PlaybackEngine::PlaybackEngine() = default;

PlaybackEngine::~PlaybackEngine() {
    dispose();
}

// ── Initialization ────────────────────────────────────────────

bool PlaybackEngine::initialize() {
    _handle = mpv_create();
    if (!_handle) return false;

    // Configure mpv
    mpv_set_option_string(_handle, "terminal", "no");
    mpv_set_option_string(_handle, "msg-level", "all=no");

    // Request log messages so we can detect errors
    mpv_request_log_messages(_handle, "error");

    if (mpv_initialize(_handle) < 0) {
        mpv_terminate_destroy(_handle);
        _handle = nullptr;
        return false;
    }

    // Observe properties for real-time updates
    mpv_observe_property(_handle, 0, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(_handle, 0, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(_handle, 0, "pause", MPV_FORMAT_FLAG);
    // libmpv 没有 "buffering" 属性，observe 不存在的属性会静默失败。
    // cache-buffering-state 是 0-100 的 double，表示缓存填充进度，
    // 小于 100 即处于缓冲中
    mpv_observe_property(_handle, 0, "cache-buffering-state", MPV_FORMAT_DOUBLE);
    mpv_observe_property(_handle, 0, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(_handle, 0, "speed", MPV_FORMAT_DOUBLE);
    mpv_observe_property(_handle, 0, "track-list", MPV_FORMAT_NODE);
    mpv_observe_property(_handle, 0, "idle-active", MPV_FORMAT_FLAG);

    // Start event loop
    _running = true;
    _eventThread = std::thread(&PlaybackEngine::eventLoop, this);

    _state = EngineState::Idle;
    return true;
}

// ── Open ──────────────────────────────────────────────────────

bool PlaybackEngine::open(const std::string& url, const std::string& headers_json) {
    if (!_handle) return false;

    _state = EngineState::Buffering;
    if (_stateCallback) _stateCallback(EngineState::Buffering);

    // Set HTTP headers if provided
    if (!headers_json.empty()) {
        mpv_set_option_string(_handle, "http-header-fields", headers_json.c_str());
    }

    // Load the file
    const char* cmd[] = {"loadfile", url.c_str(), nullptr};
    int result = mpv_command(_handle, cmd);
    return result >= 0;
}

// ── Playback Controls ─────────────────────────────────────────

void PlaybackEngine::play() {
    if (!_handle) return;
    int flag = 0;
    mpv_set_property(_handle, "pause", MPV_FORMAT_FLAG, &flag);
}

void PlaybackEngine::pause() {
    if (!_handle) return;
    int flag = 1;
    mpv_set_property(_handle, "pause", MPV_FORMAT_FLAG, &flag);
}

void PlaybackEngine::togglePlay() {
    if (!_handle) return;
    int flag = 0;
    mpv_get_property(_handle, "pause", MPV_FORMAT_FLAG, &flag);
    flag = !flag;
    mpv_set_property(_handle, "pause", MPV_FORMAT_FLAG, &flag);
}

void PlaybackEngine::seek(double position_seconds) {
    if (!_handle) return;
    std::string pos = std::to_string(position_seconds);
    const char* cmd[] = {"seek", pos.c_str(), "absolute", nullptr};
    mpv_command(_handle, cmd);
}

void PlaybackEngine::stop() {
    if (!_handle) return;
    mpv_command_string(_handle, "stop");
    _state = EngineState::Stopped;
    _position = 0.0;
    _duration = 0.0;
    if (_stateCallback) _stateCallback(EngineState::Stopped);
    if (_positionCallback) _positionCallback(0.0);
    if (_durationCallback) _durationCallback(0.0);
}

// ── Property Setters ──────────────────────────────────────────

void PlaybackEngine::setVolume(double volume) {
    if (!_handle) return;
    _volume = volume;
    mpv_set_property(_handle, "volume", MPV_FORMAT_DOUBLE, &volume);
}

void PlaybackEngine::setPlaybackSpeed(double speed) {
    if (!_handle) return;
    _playbackSpeed = speed;
    mpv_set_property(_handle, "speed", MPV_FORMAT_DOUBLE, &speed);
}

void PlaybackEngine::setAudioTrack(int index) {
    if (!_handle) return;
    // mpv uses 1-based track IDs for "aid"
    // We need to map our 0-based filtered index to mpv's track ID
    std::lock_guard<std::mutex> lock(_tracksMutex);
    if (index >= 0 && index < static_cast<int>(_audioTracks.size())) {
        // MPV_FORMAT_INT64 要求传入 8 字节整型；用 int 会让 mpv 读到
        // 栈上相邻的垃圾数据，属未定义行为
        int64_t mpv_id = _audioTracks[index].index + 1; // mpv track IDs are 1-based
        mpv_set_property(_handle, "aid", MPV_FORMAT_INT64, &mpv_id);
        _currentAudioTrackIndex = index;
    }
}

void PlaybackEngine::setSubtitleTrack(int index) {
    if (!_handle) return;
    if (index == -1) {
        // Disable subtitles
        int flag = 0;
        mpv_set_property(_handle, "sub-visibility", MPV_FORMAT_FLAG, &flag);
        _currentSubtitleTrackIndex = -1;
    } else {
        std::lock_guard<std::mutex> lock(_tracksMutex);
        if (index >= 0 && index < static_cast<int>(_subtitleTracks.size())) {
            // 同 aid：MPV_FORMAT_INT64 必须传 8 字节整型
            int64_t mpv_id = _subtitleTracks[index].index + 1;
            mpv_set_property(_handle, "sid", MPV_FORMAT_INT64, &mpv_id);
            int flag = 1;
            mpv_set_property(_handle, "sub-visibility", MPV_FORMAT_FLAG, &flag);
            _currentSubtitleTrackIndex = index;
        }
    }
}

// ── Property Getters ──────────────────────────────────────────

double PlaybackEngine::getPosition() const { return _position.load(); }
double PlaybackEngine::getDuration() const { return _duration.load(); }
double PlaybackEngine::getVolume() const { return _volume.load(); }
double PlaybackEngine::getPlaybackSpeed() const { return _playbackSpeed.load(); }
EngineState PlaybackEngine::getState() const { return _state.load(); }
bool PlaybackEngine::isPlaying() const { return _state == EngineState::Playing; }
bool PlaybackEngine::isBuffering() const { return _isBuffering.load(); }

std::vector<EngineTrackInfo> PlaybackEngine::getAudioTracks() const {
    std::lock_guard<std::mutex> lock(_tracksMutex);
    return _audioTracks;
}

std::vector<EngineTrackInfo> PlaybackEngine::getSubtitleTracks() const {
    std::lock_guard<std::mutex> lock(_tracksMutex);
    return _subtitleTracks;
}

int PlaybackEngine::getCurrentAudioTrackIndex() const {
    return _currentAudioTrackIndex;
}

int PlaybackEngine::getCurrentSubtitleTrackIndex() const {
    return _currentSubtitleTrackIndex;
}

// ── Callbacks ─────────────────────────────────────────────────

void PlaybackEngine::setStateCallback(StateCallback cb) { _stateCallback = std::move(cb); }
void PlaybackEngine::setPositionCallback(PositionCallback cb) { _positionCallback = std::move(cb); }
void PlaybackEngine::setDurationCallback(DurationCallback cb) { _durationCallback = std::move(cb); }
void PlaybackEngine::setBufferingCallback(BufferingCallback cb) { _bufferingCallback = std::move(cb); }
void PlaybackEngine::setCompletionCallback(CompletionCallback cb) { _completionCallback = std::move(cb); }
void PlaybackEngine::setTracksCallback(TracksCallback cb) { _tracksCallback = std::move(cb); }

// ── Dispose ───────────────────────────────────────────────────

void PlaybackEngine::dispose() {
    _running = false;
    if (_eventThread.joinable()) {
        _eventThread.join();
    }
    if (_handle) {
        mpv_terminate_destroy(_handle);
        _handle = nullptr;
    }
}

// ── Event Loop ────────────────────────────────────────────────

void PlaybackEngine::eventLoop() {
    while (_running && _handle) {
        mpv_event* event = mpv_wait_event(_handle, 0.1); // 100ms timeout
        if (event->event_id == MPV_EVENT_NONE) continue;
        if (event->event_id == MPV_EVENT_SHUTDOWN) break;
        handleEvent(event);
    }
}

void PlaybackEngine::handleEvent(mpv_event* event) {
    switch (event->event_id) {
        case MPV_EVENT_LOG_MESSAGE: {
            // Log errors could be forwarded if needed
            break;
        }
        case MPV_EVENT_FILE_LOADED: {
            // Media loaded, refresh tracks
            refreshTracks();
            break;
        }
        case MPV_EVENT_END_FILE: {
            auto* data = static_cast<mpv_event_end_file*>(event->data);
            if (data->reason == MPV_END_FILE_REASON_EOF) {
                _state = EngineState::Stopped;
                if (_stateCallback) _stateCallback(EngineState::Stopped);
                if (_completionCallback) _completionCallback();
            } else if (data->reason == MPV_END_FILE_REASON_ERROR) {
                _state = EngineState::Error;
                if (_stateCallback) _stateCallback(EngineState::Error);
            }
            break;
        }
        case MPV_EVENT_PROPERTY_CHANGE: {
            auto* prop = static_cast<mpv_event_property*>(event->data);
            if (!prop->name) break;

            if (strcmp(prop->name, "time-pos") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                double pos = *static_cast<double*>(prop->data);
                _position = pos;
                if (_positionCallback) _positionCallback(pos);
            }
            else if (strcmp(prop->name, "duration") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                double dur = *static_cast<double*>(prop->data);
                _duration = dur;
                if (_durationCallback) _durationCallback(dur);
            }
            else if (strcmp(prop->name, "pause") == 0 && prop->format == MPV_FORMAT_FLAG) {
                int paused = *static_cast<int*>(prop->data);
                if (paused) {
                    if (_state == EngineState::Playing || _state == EngineState::Buffering) {
                        _state = EngineState::Paused;
                        if (_stateCallback) _stateCallback(EngineState::Paused);
                    }
                } else {
                    _state = EngineState::Playing;
                    if (_stateCallback) _stateCallback(EngineState::Playing);
                }
            }
            else if (strcmp(prop->name, "cache-buffering-state") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                // 0-100 的缓存填充进度，小于 100 表示仍在缓冲
                const bool buffering = *static_cast<double*>(prop->data) < 100.0;
                _isBuffering = buffering;
                if (_bufferingCallback) _bufferingCallback(buffering);
                if (buffering) {
                    _state = EngineState::Buffering;
                    if (_stateCallback) _stateCallback(EngineState::Buffering);
                } else if (_state == EngineState::Buffering) {
                    // 缓冲结束必须恢复播放态，否则状态机会永久停留在 Buffering，
                    // UI 的缓冲指示再也无法消失
                    _state = EngineState::Playing;
                    if (_stateCallback) _stateCallback(EngineState::Playing);
                }
            }
            else if (strcmp(prop->name, "volume") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                _volume = *static_cast<double*>(prop->data);
            }
            else if (strcmp(prop->name, "speed") == 0 && prop->format == MPV_FORMAT_DOUBLE) {
                _playbackSpeed = *static_cast<double*>(prop->data);
            }
            else if (strcmp(prop->name, "track-list") == 0 && prop->format == MPV_FORMAT_NODE) {
                // Track list changed
                refreshTracks();
            }
            break;
        }
        default:
            break;
    }
}

// ── Track Management ──────────────────────────────────────────

void PlaybackEngine::refreshTracks() {
    if (!_handle) return;

    mpv_node node;
    if (mpv_get_property(_handle, "track-list", MPV_FORMAT_NODE, &node) < 0) return;

    std::vector<EngineTrackInfo> audioTracks;
    std::vector<EngineTrackInfo> subtitleTracks;

    if (node.format == MPV_FORMAT_NODE_ARRAY) {
        mpv_node_list* list = node.u.list;
        for (int i = 0; i < list->num; i++) {
            mpv_node& item = list->values[i];
            if (item.format != MPV_FORMAT_NODE_MAP) continue;

            mpv_node_list* map = item.u.list;
            std::string type;
            int id = -1;
            std::string lang, title, codec;

            for (int j = 0; j < map->num; j++) {
                const char* key = map->keys[j];
                mpv_node& val = map->values[j];

                if (strcmp(key, "type") == 0 && val.format == MPV_FORMAT_STRING) {
                    type = val.u.string;
                } else if (strcmp(key, "id") == 0 && val.format == MPV_FORMAT_INT64) {
                    id = static_cast<int>(val.u.int64);
                } else if (strcmp(key, "lang") == 0 && val.format == MPV_FORMAT_STRING) {
                    lang = val.u.string ? val.u.string : "";
                } else if (strcmp(key, "title") == 0 && val.format == MPV_FORMAT_STRING) {
                    title = val.u.string ? val.u.string : "";
                } else if (strcmp(key, "codec") == 0 && val.format == MPV_FORMAT_STRING) {
                    codec = val.u.string ? val.u.string : "";
                }
            }

            EngineTrackInfo info;
            info.index = id - 1; // Convert to 0-based
            info.language = lang;
            info.title = title;
            info.codec = codec;
            info.type = type;

            if (type == "audio") {
                audioTracks.push_back(info);
            } else if (type == "sub") {
                info.type = "subtitle";
                subtitleTracks.push_back(info);
            }
        }
    }

    mpv_free_node_contents(&node);

    {
        std::lock_guard<std::mutex> lock(_tracksMutex);
        _audioTracks = std::move(audioTracks);
        _subtitleTracks = std::move(subtitleTracks);
    }

    updateCurrentTracks();

    if (_tracksCallback) {
        std::lock_guard<std::mutex> lock(_tracksMutex);
        _tracksCallback(_audioTracks, _subtitleTracks);
    }
}

void PlaybackEngine::updateCurrentTracks() {
    if (!_handle) return;

    int64_t aid = -1, sid = -1;
    mpv_get_property(_handle, "aid", MPV_FORMAT_INT64, &aid);
    mpv_get_property(_handle, "sid", MPV_FORMAT_INT64, &sid);

    std::lock_guard<std::mutex> lock(_tracksMutex);

    // Find current audio track index
    _currentAudioTrackIndex = -1;
    for (size_t i = 0; i < _audioTracks.size(); i++) {
        if (_audioTracks[i].index == static_cast<int>(aid - 1)) {
            _currentAudioTrackIndex = static_cast<int>(i);
            break;
        }
    }

    // Find current subtitle track index
    _currentSubtitleTrackIndex = -1;
    if (sid > 0) {
        for (size_t i = 0; i < _subtitleTracks.size(); i++) {
            if (_subtitleTracks[i].index == static_cast<int>(sid - 1)) {
                _currentSubtitleTrackIndex = static_cast<int>(i);
                break;
            }
        }
    }
}

} // namespace aether
