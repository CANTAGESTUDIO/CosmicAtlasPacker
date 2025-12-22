import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'crash_report.dart';

/// 크래시 로그 파일 저장 관리 클래스
class CrashLogStorage {
  CrashLogStorage._();

  static CrashLogStorage? _instance;
  static CrashLogStorage get instance => _instance ??= CrashLogStorage._();

  static const String _logDirName = 'crash_logs';
  static const String _logFilePrefix = 'crash_';
  static const String _logFileExtension = '.log';
  static const int _maxLogFiles = 10;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  Directory? _logDirectory;
  File? _currentLogFile;

  /// 로그 디렉토리 초기화
  Future<void> initialize() async {
    final appSupportDir = await getApplicationSupportDirectory();
    _logDirectory = Directory(path.join(appSupportDir.path, _logDirName));

    if (!await _logDirectory!.exists()) {
      await _logDirectory!.create(recursive: true);
    }

    await _rotateLogsIfNeeded();
    _currentLogFile = await _getCurrentLogFile();
  }

  /// 크래시 리포트를 파일에 저장
  Future<void> saveCrashReport(CrashReport report) async {
    if (_currentLogFile == null) {
      await initialize();
    }

    try {
      final logContent = report.toLogFormat();
      await _currentLogFile!.writeAsString(
        logContent,
        mode: FileMode.append,
        flush: true,
      );

      // 파일 크기 체크 후 로테이션
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxLogFileSize) {
        await _rotateLogsIfNeeded();
        _currentLogFile = await _getCurrentLogFile();
      }
    } catch (e) {
      // 로그 저장 실패 시 콘솔에만 출력 (재귀 방지)
      // ignore: avoid_print
      print('Failed to save crash report: $e');
    }
  }

  /// 현재 로그 파일 가져오기 (없으면 생성)
  Future<File> _getCurrentLogFile() async {
    final today = DateTime.now();
    final fileName = '$_logFilePrefix${_formatDate(today)}$_logFileExtension';
    final file = File(path.join(_logDirectory!.path, fileName));

    if (!await file.exists()) {
      await file.create();
      await file.writeAsString(_generateLogHeader());
    }

    return file;
  }

  /// 로그 파일 헤더 생성
  String _generateLogHeader() {
    return '''
════════════════════════════════════════════════════════════
COSMIC ATLAS PACKER - CRASH LOG
Created: ${DateTime.now().toIso8601String()}
════════════════════════════════════════════════════════════

''';
  }

  /// 날짜 포맷팅 (yyyyMMdd)
  String _formatDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// 오래된 로그 파일 정리
  Future<void> _rotateLogsIfNeeded() async {
    if (_logDirectory == null) return;

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) =>
              entity is File &&
              entity.path.contains(_logFilePrefix) &&
              entity.path.endsWith(_logFileExtension))
          .cast<File>()
          .toList();

      if (files.length > _maxLogFiles) {
        // 수정 시간 기준 정렬
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        });

        // 오래된 파일 삭제
        final filesToDelete = files.take(files.length - _maxLogFiles);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      // 로그 로테이션 실패 무시
    }
  }

  /// 모든 크래시 로그 파일 경로 목록 반환
  Future<List<String>> getLogFilePaths() async {
    if (_logDirectory == null) {
      await initialize();
    }

    try {
      final files = await _logDirectory!
          .list()
          .where((entity) =>
              entity is File &&
              entity.path.contains(_logFilePrefix) &&
              entity.path.endsWith(_logFileExtension))
          .cast<File>()
          .toList();

      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified); // 최신순
      });

      return files.map((f) => f.path).toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 로그 파일 내용 읽기
  Future<String?> readLogFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      // 읽기 실패
    }
    return null;
  }

  /// 모든 로그 파일 삭제
  Future<void> clearAllLogs() async {
    if (_logDirectory == null) {
      await initialize();
    }

    try {
      final files = await _logDirectory!.list().toList();
      for (final entity in files) {
        if (entity is File) {
          await entity.delete();
        }
      }
      _currentLogFile = null;
    } catch (e) {
      // 삭제 실패 무시
    }
  }

  /// 로그 디렉토리 경로 반환
  String? get logDirectoryPath => _logDirectory?.path;
}
