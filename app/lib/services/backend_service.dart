import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


/// Go 后端进程管理服务
///
/// 负责：
/// - 启动 Go 后端（Android: gomobile .aar via MethodChannel，桌面: 子进程）
/// - 健康检查
/// - 应用退出时自动清理
class BackendService {
  // ── MethodChannel（Android gomobile） ──
  static const _channel = MethodChannel('com.example.aether/backend');

  Process? _process;
  final int _port = 19800;
  bool _started = false;
  Timer? _healthCheckTimer;

  /// 后端是否已就绪
  bool get isReady => _started;

  /// 后端端口
  int get port => _port;

  /// 后端基础 URL
  String get baseUrl => 'http://localhost:$_port';

  /// 启动 Go 后端
  ///
  /// 流程：
  /// 1. 检查端口是否已被占用（已有后端运行）
  /// 2. Android: 通过 MethodChannel 调用 gomobile .aar
  /// 3. 桌面: 查找 Go 二进制文件，启动子进程
  /// 4. 等待健康检查通过
  Future<void> start() async {
    if (_started) return;

    try {
      // 先检查端口是否已被占用（可能已有后端在运行）
      if (await _isPortInUse()) {
        debugPrint('[BackendService] Port $_port already in use, skipping start');
        _started = true;
        _healthCheckTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _checkHealth(),
        );
        return;
      }

      if (Platform.isAndroid) {
        await _startViaMethodChannel();
      } else {
        await _startViaProcess();
      }

      // 等待后端就绪（最多 10 秒）
      await _waitForReady();
      _started = true;
      debugPrint('[BackendService] Ready on port $_port');

      // 启动健康检查定时器
      _healthCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkHealth(),
      );
    } catch (e) {
      debugPrint('[BackendService] Failed to start: $e');
      _started = false;
      rethrow;
    }
  }

  /// Android: 通过 MethodChannel 调用 gomobile .aar
  Future<void> _startViaMethodChannel() async {
    debugPrint('[BackendService] Starting via MethodChannel (gomobile)');
    try {
      final result = await _channel.invokeMethod<bool>(
        'startServer',
        {'port': _port},
      );
      if (result != true) {
        throw Exception('MethodChannel startServer returned false');
      }
    } on PlatformException catch (e) {
      throw Exception('MethodChannel error: ${e.message}');
    }
  }

  /// 桌面: 通过子进程启动 Go 二进制
  Future<void> _startViaProcess() async {
    final binaryPath = await _resolveBinaryPath();
    debugPrint('[BackendService] Starting process: $binaryPath');

    _process = await Process.start(
      binaryPath,
      [],
      environment: {'PORT': '$_port'},
    );

    _process!.exitCode.then((code) {
      debugPrint('[BackendService] Process exited with code $code');
      _started = false;
      _process = null;
    });
  }

  /// 检查端口是否已被占用
  Future<bool> _isPortInUse() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final request = await client.getUrl(Uri.parse('$baseUrl/api/health'));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 停止后端
  Future<void> stop() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('stopServer');
      } catch (e) {
        debugPrint('[BackendService] MethodChannel stop error: $e');
      }
      _started = false;
      debugPrint('[BackendService] Stopped (gomobile)');
      return;
    }

    if (_process != null) {
      debugPrint('[BackendService] Stopping...');
      _process!.kill(ProcessSignal.sigterm);

      try {
        await _process!.exitCode.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            _process!.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (_) {
        _process!.kill(ProcessSignal.sigkill);
      }

      _process = null;
      _started = false;
      debugPrint('[BackendService] Stopped');
    }
  }

  /// 查找 Go 二进制文件路径（仅桌面平台）
  Future<String> _resolveBinaryPath() async {
    final exeName = Platform.isWindows ? 'aether-server.exe' : 'aether-server';

    // 策略 1: 与可执行文件同目录（打包后的位置）
    final appDir = _getAppDir();
    final bundled = '$appDir/$exeName';
    if (await File(bundled).exists()) return bundled;

    // 策略 2: 系统 PATH（开发模式）
    final which = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(which, [exeName]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim().split('\n').first;
    }

    throw Exception('Go backend binary not found: $exeName');
  }

  /// 获取应用目录
  String _getAppDir() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return File(Platform.resolvedExecutable).parent.path;
    }
    return '.';
  }

  /// 等待后端就绪
  Future<void> _waitForReady() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);

    for (int i = 0; i < 50; i++) {
      try {
        final request = await client.getUrl(Uri.parse('$baseUrl/api/health'));
        final response = await request.close();
        if (response.statusCode == 200) {
          client.close();
          return;
        }
      } catch (_) {
        // 还没就绪，继续等
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    client.close();
    throw Exception('Backend health check timeout');
  }

  /// 健康检查
  Future<void> _checkHealth() async {
    if (!_started) return;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse('$baseUrl/api/health'));
      final response = await request.close();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('[BackendService] Health check failed, restarting...');
        _started = false;
        await start();
      }
    } catch (e) {
      debugPrint('[BackendService] Health check error: $e');
    }
  }
}
