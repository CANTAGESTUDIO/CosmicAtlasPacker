import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 메모리 사용량 스냅샷
class MemorySnapshot {
  const MemorySnapshot({
    required this.timestamp,
    required this.usedHeapSizeMB,
    required this.externalSizeMB,
    this.imageCount,
    this.imageCacheSizeMB,
  });

  final DateTime timestamp;
  final double usedHeapSizeMB;
  final double externalSizeMB;
  final int? imageCount;
  final double? imageCacheSizeMB;

  double get totalMB => usedHeapSizeMB + externalSizeMB;

  @override
  String toString() {
    return 'Memory[heap: ${usedHeapSizeMB.toStringAsFixed(1)}MB, '
        'external: ${externalSizeMB.toStringAsFixed(1)}MB, '
        'total: ${totalMB.toStringAsFixed(1)}MB]';
  }
}

/// 메모리 경고 레벨
enum MemoryWarningLevel {
  normal,
  warning,  // 70% 이상
  critical, // 85% 이상
}

/// 메모리 경고 콜백 타입
typedef MemoryWarningCallback = void Function(MemoryWarningLevel level, MemorySnapshot snapshot);

/// 메모리 모니터링 서비스
/// 주기적으로 메모리 사용량을 체크하고 경고 발생
class MemoryMonitor {
  MemoryMonitor._();

  static MemoryMonitor? _instance;
  static MemoryMonitor get instance => _instance ??= MemoryMonitor._();

  Timer? _monitorTimer;
  final List<MemorySnapshot> _history = [];
  static const int _maxHistorySize = 100;

  /// 메모리 임계값 (MB 단위)
  double _warningThresholdMB = 500;  // 500MB
  double _criticalThresholdMB = 800; // 800MB

  /// 경고 콜백
  MemoryWarningCallback? onMemoryWarning;

  /// 현재 경고 레벨
  MemoryWarningLevel _currentLevel = MemoryWarningLevel.normal;
  MemoryWarningLevel get currentLevel => _currentLevel;

  /// 모니터링 시작
  void startMonitoring({
    Duration interval = const Duration(seconds: 30),
    double? warningThresholdMB,
    double? criticalThresholdMB,
  }) {
    if (warningThresholdMB != null) _warningThresholdMB = warningThresholdMB;
    if (criticalThresholdMB != null) _criticalThresholdMB = criticalThresholdMB;

    stopMonitoring();

    _monitorTimer = Timer.periodic(interval, (_) => _checkMemory());

    // 초기 체크
    _checkMemory();

    if (kDebugMode) {
      debugPrint('[MemoryMonitor] Started with interval: $interval');
    }
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// 현재 메모리 스냅샷 가져오기
  MemorySnapshot takeSnapshot({
    int? imageCount,
    double? imageCacheSizeMB,
  }) {
    final info = ProcessInfo.currentRss;
    final heapSizeMB = info / (1024 * 1024);

    return MemorySnapshot(
      timestamp: DateTime.now(),
      usedHeapSizeMB: heapSizeMB,
      externalSizeMB: 0, // 플랫폼별로 추가 가능
      imageCount: imageCount,
      imageCacheSizeMB: imageCacheSizeMB,
    );
  }

  /// 메모리 체크 및 경고 발생
  void _checkMemory() {
    final snapshot = takeSnapshot();
    _addToHistory(snapshot);

    final newLevel = _evaluateLevel(snapshot);

    // 레벨이 변경되었거나 critical 상태면 콜백 호출
    if (newLevel != _currentLevel || newLevel == MemoryWarningLevel.critical) {
      _currentLevel = newLevel;
      onMemoryWarning?.call(newLevel, snapshot);

      if (kDebugMode && newLevel != MemoryWarningLevel.normal) {
        debugPrint('[MemoryMonitor] Warning: $newLevel - $snapshot');
      }
    }

    // Critical 상태에서 GC 힌트
    if (newLevel == MemoryWarningLevel.critical) {
      _suggestGC();
    }
  }

  /// 메모리 레벨 평가
  MemoryWarningLevel _evaluateLevel(MemorySnapshot snapshot) {
    if (snapshot.totalMB >= _criticalThresholdMB) {
      return MemoryWarningLevel.critical;
    } else if (snapshot.totalMB >= _warningThresholdMB) {
      return MemoryWarningLevel.warning;
    }
    return MemoryWarningLevel.normal;
  }

  /// 히스토리에 추가
  void _addToHistory(MemorySnapshot snapshot) {
    _history.add(snapshot);
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// GC 힌트 제공 (VM에게 GC 수행 제안)
  void _suggestGC() {
    // Timeline 이벤트로 GC 힌트 제공
    developer.Timeline.instantSync('MemoryPressure');

    if (kDebugMode) {
      debugPrint('[MemoryMonitor] Memory pressure high, suggesting GC');
    }
  }

  /// 메모리 히스토리 가져오기
  List<MemorySnapshot> getHistory() => List.unmodifiable(_history);

  /// 평균 메모리 사용량 (최근 N개 샘플)
  double getAverageUsageMB({int samples = 10}) {
    if (_history.isEmpty) return 0;

    final recentSamples = _history.length > samples
        ? _history.sublist(_history.length - samples)
        : _history;

    final total = recentSamples.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.totalMB,
    );

    return total / recentSamples.length;
  }

  /// 메모리 증가 추세 감지
  bool isMemoryIncreasing({int samples = 5}) {
    if (_history.length < samples) return false;

    final recentSamples = _history.sublist(_history.length - samples);
    double previousValue = recentSamples.first.totalMB;
    int increasingCount = 0;

    for (int i = 1; i < recentSamples.length; i++) {
      if (recentSamples[i].totalMB > previousValue) {
        increasingCount++;
      }
      previousValue = recentSamples[i].totalMB;
    }

    // 80% 이상 증가 추세면 true
    return increasingCount >= (samples * 0.8);
  }

  /// 히스토리 초기화
  void clearHistory() {
    _history.clear();
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _history.clear();
    _instance = null;
  }
}
