import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// LRU (Least Recently Used) 이미지 캐시 매니저
/// Flutter의 ImageCache를 보완하여 명확한 메모리 제어 제공
class LruImageCache {
  LruImageCache._();

  static LruImageCache? _instance;
  static LruImageCache get instance => _instance ??= LruImageCache._();

  final LruCache<String, Uint8List> _cache = LruCache(maximumSize: 50);
  final LruCache<String, ui.Image> _decodedCache = LruCache(maximumSize: 30);

  /// 최대 캐시 크기 (메모리 MB)
  double _maxCacheMemoryMB = 128;
  double get maxCacheMemoryMB => _maxCacheMemoryMB;

  /// 현재 캐시된 이미지 수
  int get cachedImageCount => _cache.length + _decodedCache.length;

  /// 현재 캐시 메모리 사용량 (추정)
  double get estimatedMemoryUsageMB => _cache.estimatedMemoryUsage / (1024 * 1024);

  /// 최대 캐시 메모리 설정
  void setMaxMemory(double maxMB) {
    _maxCacheMemoryMB = maxMB;
    _enforceMemoryLimit();
  }

  /// 이미지를 캐시에 저장 (원본 바이트)
  void put(String key, Uint8List bytes) {
    if (bytes.isEmpty) return;

    _cache.put(key, bytes);
    _enforceMemoryLimit();
  }

  /// 이미지를 캐시에 저장 (디코딩된 이미지)
  void putDecoded(String key, ui.Image? image) {
    if (image == null) return;

    _decodedCache.put(key, image);
    _enforceMemoryLimit();
  }

  /// 원본 바이트 가져오기
  Uint8List? get(String key) => _cache.get(key);

  /// 디코딩된 이미지 가져오기
  ui.Image? getDecoded(String key) => _decodedCache.get(key);

  /// 캐시에서 제거
  void remove(String key) {
    _cache.remove(key);
    _decodedCache.remove(key);
  }

  /// 모든 캐시 클리어
  void clear() {
    _cache.clear();
    _decodedCache.clear();
  }

  /// 메모리 제한 강제 적용
  void _enforceMemoryLimit() {
    while (estimatedMemoryUsageMB > _maxCacheMemoryMB) {
      // 가장 오래된 항목 제거 (LRU)
      _cache.removeOldest();
      _decodedCache.removeOldest();

      // 안전 장치: 0MB가 되면 중단
      if (_cache.isEmpty && _decodedCache.isEmpty) break;
    }
  }

  /// 캐시 상태 정보 반환
  Map<String, dynamic> getStats() {
    return {
      'cachedCount': cachedImageCount,
      'byteCacheCount': _cache.length,
      'decodedCacheCount': _decodedCache.length,
      'estimatedMemoryMB': estimatedMemoryUsageMB.toFixed(2),
      'maxMemoryMB': _maxCacheMemoryMB,
    };
  }
}

/// 간단한 LRU 캐시 구현
class LruCache<K, V> {
  final int maximumSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap();

  LruCache({this.maximumSize = 50});

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;

  V? get(K key) {
    if (!_map.containsKey(key)) return null;

    // 접근한 항목을 맨 뒤로 이동 (LRU)
    final value = _map.remove(key)!;
    _map[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      // 기존 항목 제거하고 다시 추가 (순서 업데이트)
      _map.remove(key);
    }

    _map[key] = value;

    // 크기 제한 초과 시 가장 오래된 항목 제거
    while (_map.length > maximumSize) {
      _map.remove(_map.keys.first);
    }
  }

  void remove(K key) {
    _map.remove(key);
  }

  void removeOldest() {
    if (_map.isNotEmpty) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() {
    _map.clear();
  }

  double get estimatedMemoryUsage {
    // 대략적인 메모리 사용량 추정
    // 실제 구현에서는 이미지 크기에 따라 계산
    return _map.length * 1024 * 1024; // 1MB per item estimate
  }
}

extension DoubleExtension on double {
  String toFixed(int decimals) => toStringAsFixed(decimals);
}
