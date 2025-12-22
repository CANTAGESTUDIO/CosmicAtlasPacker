import 'package:flutter/foundation.dart';

/// Dispose 상태 추적을 위한 Mixin
/// StatefulWidget의 State나 ChangeNotifier에서 사용
mixin DisposableStateMixin {
  bool _isDisposed = false;

  /// 이미 dispose 되었는지 확인
  bool get isDisposed => _isDisposed;

  /// dispose 호출 전 상태 체크
  @protected
  void markDisposed() {
    if (_isDisposed) {
      if (kDebugMode) {
        debugPrint('[Warning] $runtimeType already disposed');
      }
      return;
    }
    _isDisposed = true;
  }

  /// 안전한 작업 실행 (dispose 후 무시)
  @protected
  void safeExecute(VoidCallback action) {
    if (!_isDisposed) {
      action();
    }
  }

  /// 안전한 비동기 작업 실행 (dispose 후 무시)
  @protected
  Future<T?> safeExecuteAsync<T>(Future<T> Function() action) async {
    if (!_isDisposed) {
      return await action();
    }
    return null;
  }
}

/// 리스너 정리를 위한 Mixin
mixin ListenerCleanupMixin {
  final List<_ListenerRegistration> _registrations = [];

  /// 리스너 등록 및 자동 정리 예약
  void registerListener<T>({
    required Listenable listenable,
    required VoidCallback listener,
  }) {
    listenable.addListener(listener);
    _registrations.add(_ListenerRegistration(
      listenable: listenable,
      listener: listener,
    ));
  }

  /// 등록된 모든 리스너 제거
  @protected
  void cleanupAllListeners() {
    for (final reg in _registrations) {
      reg.listenable.removeListener(reg.listener);
    }
    _registrations.clear();
  }
}

class _ListenerRegistration {
  _ListenerRegistration({
    required this.listenable,
    required this.listener,
  });

  final Listenable listenable;
  final VoidCallback listener;
}

/// StreamSubscription 정리를 위한 Mixin
mixin StreamCleanupMixin {
  final List<dynamic> _subscriptions = [];

  /// StreamSubscription 등록 및 자동 정리 예약
  void registerSubscription<T>(dynamic subscription) {
    _subscriptions.add(subscription);
  }

  /// 등록된 모든 구독 취소
  @protected
  Future<void> cancelAllSubscriptions() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }
}

/// 이미지 리소스 정리를 위한 Mixin
/// ui.Image 등의 네이티브 리소스 dispose 관리
mixin ImageResourceMixin {
  final List<dynamic> _imageResources = [];

  /// 이미지 리소스 등록
  void registerImageResource(dynamic resource) {
    _imageResources.add(resource);
  }

  /// 이미지 리소스 제거
  void unregisterImageResource(dynamic resource) {
    _imageResources.remove(resource);
  }

  /// 등록된 모든 이미지 리소스 dispose
  @protected
  void disposeAllImages() {
    for (final resource in _imageResources) {
      try {
        resource.dispose();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Warning] Failed to dispose image resource: $e');
        }
      }
    }
    _imageResources.clear();
  }

  /// 현재 등록된 이미지 수
  int get registeredImageCount => _imageResources.length;
}
