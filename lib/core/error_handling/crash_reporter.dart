import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import 'crash_log_storage.dart';
import 'crash_report.dart';

/// 앱 전역 크래시 리포팅 관리 클래스
class CrashReporter {
  CrashReporter._();

  static CrashReporter? _instance;
  static CrashReporter get instance => _instance ??= CrashReporter._();

  final CrashLogStorage _storage = CrashLogStorage.instance;
  bool _isInitialized = false;

  /// 크래시 리포터 초기화
  /// 앱 시작 시 main() 함수에서 호출 필요
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _storage.initialize();
    _setupErrorHandlers();
    _isInitialized = true;
  }

  /// Flutter 및 Dart 에러 핸들러 설정
  void _setupErrorHandlers() {
    // Flutter framework 에러 핸들러
    FlutterError.onError = _handleFlutterError;

    // Dart async 에러 핸들러 (PlatformDispatcher)
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  /// Flutter framework 에러 처리
  void _handleFlutterError(FlutterErrorDetails details) {
    // 기본 에러 출력 (디버그 모드에서)
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }

    // 크래시 리포트 저장
    _recordError(
      error: details.exception,
      stackTrace: details.stack,
      additionalInfo: {
        'context': details.context?.toString(),
        'library': details.library,
        'silent': details.silent,
      },
    );
  }

  /// Platform 에러 처리 (uncaught async errors)
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Platform Error: $error');
      // ignore: avoid_print
      print('Stack Trace: $stackTrace');
    }

    _recordError(
      error: error,
      stackTrace: stackTrace,
      additionalInfo: {'source': 'PlatformDispatcher'},
    );

    // true를 반환하면 에러가 처리된 것으로 간주
    return true;
  }

  /// 에러 기록
  Future<void> _recordError({
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    final report = CrashReport.fromError(
      error: error,
      stackTrace: stackTrace,
      appVersion: AppConstants.appVersion,
      additionalInfo: additionalInfo,
    );

    await _storage.saveCrashReport(report);
  }

  /// 수동으로 에러 기록 (try-catch에서 사용)
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    await _recordError(
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      additionalInfo: additionalInfo,
    );
  }

  /// 비치명적 이슈 기록 (경고 수준)
  Future<void> recordWarning(
    String message, {
    Map<String, dynamic>? additionalInfo,
  }) async {
    final report = CrashReport(
      timestamp: DateTime.now(),
      errorType: 'Warning',
      errorMessage: message,
      stackTrace: StackTrace.current.toString(),
      appVersion: AppConstants.appVersion,
      platform: CrashReport.getPlatformName(),
      additionalInfo: additionalInfo,
    );

    await _storage.saveCrashReport(report);
  }

  /// 로그 파일 경로 목록 가져오기
  Future<List<String>> getLogFilePaths() => _storage.getLogFilePaths();

  /// 로그 파일 내용 읽기
  Future<String?> readLogFile(String path) => _storage.readLogFile(path);

  /// 모든 로그 삭제
  Future<void> clearLogs() => _storage.clearAllLogs();

  /// 로그 디렉토리 경로
  String? get logDirectoryPath => _storage.logDirectoryPath;
}

/// runApp을 감싸는 에러 핸들링 래퍼
/// 모든 Zone 에러를 캐치하여 크래시 리포터로 전달
void runAppWithCrashReporting(Widget app) {
  runZonedGuarded(
    () async {
      // ensureInitialized와 runApp을 같은 Zone에서 실행
      WidgetsFlutterBinding.ensureInitialized();
      await CrashReporter.instance.initialize();
      runApp(app);
    },
    (error, stackTrace) {
      CrashReporter.instance.recordError(error, stackTrace: stackTrace);
    },
  );
}

/// Isolate 에러 핸들러 설정 (별도 Isolate 사용 시)
void setupIsolateErrorHandler(Isolate isolate) {
  final receivePort = ReceivePort();
  isolate.addErrorListener(receivePort.sendPort);

  receivePort.listen((dynamic message) {
    if (message is List && message.length >= 2) {
      final error = message[0];
      final stackTrace = message[1];
      CrashReporter.instance.recordError(
        error,
        stackTrace: stackTrace is StackTrace
            ? stackTrace
            : StackTrace.fromString(stackTrace.toString()),
        additionalInfo: {'source': 'Isolate'},
      );
    }
  });
}
