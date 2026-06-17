import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Go 后端进程管理服务
///
/// 负责：
/// - 启动 Go 后端子进程
/// - 健康检查
/// - 应用退出时自动清理
class BackendService {
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
  /// 1. 查找 Go 二进制文件
  /// 2. 启动子进程
  /// 3. 等待健康检查通过
  Future<void> start() async {
    if (_started) return;

    try {
      final binaryPath = await _resolveBinaryPath();
      debugPrint('[BackendService] Starting: $binaryPath');

      // 启动子进程
      _process = await Process.start(
        binaryPath,
        [],
        environment: {'PORT': '$_port'},
        mode: ProcessStartMode.detached,
      );

      // 监听进程退出
      _process!.exitCode.then((code) {
        debugPrint('[BackendService] Process exited with code $code');
        _started = false;
        _process = null;
      });

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

  /// 停止后端
  Future<void> stop() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    if (_process != null) {
      debugPrint('[BackendService] Stopping...');
      _process!.kill(ProcessSignal.sigterm);

      // 等待退出，超时则强杀
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

  /// 查找 Go 二进制文件路径
  Future<String> _resolveBinaryPath() async {
    final exeName = Platform.isWindows ? 'aether-server.exe' : 'aether-server';

    // 策略 1: 与可执行文件同目录（打包后的位置）
    final appDir = _getAppDir();
    final bundled = '$appDir/$exeName';
    if (await File(bundled).exists()) return bundled;

    // 策略 2: 从 assets 解压（Android / 首次运行）
    final extracted = await _extractFromAssets(exeName);
    if (extracted != null) return extracted;

    // 策略 3: 系统 PATH（开发模式）
    if (!Platform.isAndroid && !Platform.isIOS) {
      final which = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(which, [exeName]);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim().split('\n').first;
      }
    }

    throw Exception('Go backend binary not found: $exeName');
  }

  /// 获取应用目录
  String _getAppDir() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // 可执行文件所在目录
      return File(Platform.resolvedExecutable).parent.path;
    }
    return '.';
  }

  /// 从 assets 解压二进制（Android）
  Future<String?> _extractFromAssets(String exeName) async {
    if (!Platform.isAndroid) return null;

    try {
      final appDir = await getApplicationSupportDirectory();
      final targetPath = '${appDir.path}/$exeName';
      final targetFile = File(targetPath);

      // 检查是否已解压
      if (await targetFile.exists()) return targetPath;

      // 从 assets 复制
      // 注意：需要在 pubspec.yaml 中声明 assets
      // assets:
      //   - assets/bin/aether-server
      // 实际路径取决于 Android 的 asset 打包方式
      debugPrint('[BackendService] Extracting backend to $targetPath');

      // 对于 Android，二进制通常放在 lib/ 目录下
      // 使用 rootBundle 加载
      // 这里返回 null，让调用方处理
      return null;
    } catch (e) {
      debugPrint('[BackendService] Extract failed: $e');
      return null;
    }
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
    if (!_started || _process == null) return;

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
