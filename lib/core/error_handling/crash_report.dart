import 'dart:io';

import 'package:flutter/foundation.dart';

/// 크래시 리포트 데이터 모델
class CrashReport {
  CrashReport({
    required this.timestamp,
    required this.errorType,
    required this.errorMessage,
    required this.stackTrace,
    required this.appVersion,
    required this.platform,
    this.osVersion,
    this.additionalInfo,
  });

  final DateTime timestamp;
  final String errorType;
  final String errorMessage;
  final String stackTrace;
  final String appVersion;
  final String platform;
  final String? osVersion;
  final Map<String, dynamic>? additionalInfo;

  /// 시스템 정보를 자동으로 수집하여 CrashReport 생성
  factory CrashReport.fromError({
    required Object error,
    required StackTrace? stackTrace,
    required String appVersion,
    Map<String, dynamic>? additionalInfo,
  }) {
    return CrashReport(
      timestamp: DateTime.now(),
      errorType: error.runtimeType.toString(),
      errorMessage: _sanitizeErrorMessage(error.toString()),
      stackTrace: _sanitizeStackTrace(stackTrace?.toString() ?? 'No stack trace'),
      appVersion: appVersion,
      platform: getPlatformName(),
      osVersion: Platform.operatingSystemVersion,
      additionalInfo: additionalInfo,
    );
  }

  /// 민감 정보를 필터링한 에러 메시지
  static String _sanitizeErrorMessage(String message) {
    return _filterSensitiveInfo(message);
  }

  /// 민감 정보를 필터링한 스택 트레이스
  static String _sanitizeStackTrace(String trace) {
    return _filterSensitiveInfo(trace);
  }

  /// 민감 정보 필터링 (파일 경로의 사용자명 등)
  static String _filterSensitiveInfo(String input) {
    // 사용자 홈 디렉토리 경로 마스킹
    final homeDir = Platform.environment['HOME'] ??
                    Platform.environment['USERPROFILE'] ?? '';
    if (homeDir.isNotEmpty) {
      input = input.replaceAll(homeDir, '~');
    }

    // 사용자명 패턴 마스킹 (/Users/username/, /home/username/, C:\Users\username\)
    input = input.replaceAll(
      RegExp(r'(/Users/|/home/|C:\\Users\\)[^/\\]+'),
      r'$1[USER]',
    );

    // 이메일 주소 마스킹
    input = input.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL]',
    );

    // API 키, 토큰 패턴 마스킹
    input = input.replaceAll(
      RegExp(r'(api[_-]?key|token|secret|password|auth)[=:]\s*[^\s,;]+', caseSensitive: false),
      r'$1=[REDACTED]',
    );

    return input;
  }

  /// 플랫폼 이름 반환
  static String getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 로그 파일용 포맷 문자열로 변환
  String toLogFormat() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 60);
    buffer.writeln('CRASH REPORT');
    buffer.writeln('═' * 60);
    buffer.writeln('Timestamp: ${timestamp.toIso8601String()}');
    buffer.writeln('App Version: $appVersion');
    buffer.writeln('Platform: $platform');
    if (osVersion != null) {
      buffer.writeln('OS Version: $osVersion');
    }
    buffer.writeln('─' * 60);
    buffer.writeln('Error Type: $errorType');
    buffer.writeln('Error Message: $errorMessage');
    buffer.writeln('─' * 60);
    buffer.writeln('Stack Trace:');
    buffer.writeln(stackTrace);
    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      buffer.writeln('─' * 60);
      buffer.writeln('Additional Info:');
      additionalInfo!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    buffer.writeln('═' * 60);
    buffer.writeln();
    return buffer.toString();
  }

  /// JSON 형태로 변환 (향후 원격 전송용)
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
      'appVersion': appVersion,
      'platform': platform,
      'osVersion': osVersion,
      'additionalInfo': additionalInfo,
    };
  }
}
