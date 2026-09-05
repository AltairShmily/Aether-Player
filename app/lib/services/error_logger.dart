import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 将未捕获异常落盘，使 release 构建下的崩溃可事后诊断。
///
/// main() 的 runZonedGuarded / FlutterError.onError 是唯一能看到这些异常的
/// 地方，而 debugPrint 在 release 包中无人观察，因此必须持久化。
class ErrorLogger {
  ErrorLogger._();

  static const String _fileName = 'aether_errors.log';

  /// 超过该体积后丢弃前半部分，避免日志无限增长
  static const int _maxBytes = 256 * 1024;

  static File? _file;
  static bool _failed = false;

  /// 解析日志文件位置。失败时静默降级 —— 日志能力不应影响应用启动。
  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/$_fileName');
    } catch (e) {
      _failed = true;
      debugPrint('[ErrorLogger] init failed: $e');
    }
  }

  /// 日志文件路径，供设置页「导出诊断日志」使用；未就绪时为 null
  static String? get path => _file?.path;

  static Future<void> log(
    String source,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    debugPrint('[$source] $error');
    final file = _file;
    if (file == null || _failed) return;

    try {
      final buffer = StringBuffer()
        ..writeln('--- ${DateTime.now().toIso8601String()} [$source] ---')
        ..writeln(error);
      if (stackTrace != null) buffer.writeln(stackTrace);

      await file.writeAsString(buffer.toString(), mode: FileMode.append);
      await _trimIfTooLarge(file);
    } catch (_) {
      // 写日志失败不能再抛异常，否则会递归触发错误处理
      _failed = true;
    }
  }

  static Future<void> _trimIfTooLarge(File file) async {
    final bytes = await file.length();
    if (bytes <= _maxBytes) return;
    // 按字符而非字节裁剪：UTF-8 下字节数大于字符数，
    // 用字节长度做索引会抛 RangeError
    final content = await file.readAsString();
    await file.writeAsString(content.substring(content.length ~/ 2));
  }

  /// 清空日志
  static Future<void> clear() async {
    final file = _file;
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      _failed = true;
    }
  }
}
