# PUBLIC Specification

> **Stage**: PUBLIC
> **Last Modified**: 2025-12-22
> **Status**: Draft

---

## Summary

MVP 기능을 기반으로 고급 기능과 폴리싱을 완료하여 공개 배포 가능한 완성도를 달성합니다.
애니메이션 시퀀스 편집기, 9-Slice Border, Undo/Redo, 다중 소스 이미지, 키보드 단축키 등을 구현합니다.

---

## 1. Goals

| 목표 | 설명 |
|------|------|
| 애니메이션 편집기 | 프레임 시퀀스 정의, 타이밍, 루프/핑퐁 설정 |
| 9-Slice Border | UI 요소용 경계 설정 및 프리뷰 |
| Undo/Redo | 모든 편집 작업 취소/재실행 |
| 다중 소스 이미지 | 여러 이미지를 하나의 아틀라스로 패킹 |
| UX 폴리싱 | 드래그&드롭, 키보드 단축키, 테마 |

---

## 2. Scope

### 2.1 Phase 3: 고급 기능

| 기능 | 상세 |
|------|------|
| 애니메이션 시퀀스 편집기 | 프레임 순서 드래그&드롭 |
| 프레임 타이밍 | duration (초 단위) 설정 |
| 루프/핑퐁 설정 | 애니메이션 재생 모드 |
| flipX/flipY 지원 | 프레임별 좌우/상하 반전 |
| 애니메이션 프리뷰 | 실시간 재생 미리보기 |
| 9-Slice Border 설정 | L/R/T/B 경계 입력 (픽셀 단위) |
| 9-Slice 시각적 편집 | 드래그로 경계 조절 |
| 9-Slice 프리뷰 | 리사이즈 시뮬레이션 |
| Undo/Redo | Command 패턴 기반 히스토리 |
| 다중 소스 이미지 | 여러 PNG 파일 동시 로드 |
| 소스별 슬라이싱 | 각 소스 이미지 개별 편집 |

### 2.2 Phase 4: 폴리싱

| 기능 | 상세 |
|------|------|
| 드래그&드롭 개선 | 스프라이트 목록 순서 변경 |
| 파일 드래그&드롭 | 이미지 파일 직접 드롭 |
| 키보드 단축키 | Cmd+S (저장), Cmd+Z (실행취소), Cmd+E (내보내기) 등 |
| 다크/라이트 테마 | 테마 전환 지원 |
| 줌 컨트롤 개선 | 마우스 휠 줌, 핏 투 윈도우 |
| 상태 표시줄 | 스프라이트 수, 아틀라스 크기, 메모리 사용량 |
| 내보내기 옵션 다이얼로그 | 아틀라스 설정 조절 UI |
| 프로젝트 설정 다이얼로그 | 전역 설정 UI |

---

## 3. Technical Specifications

### 3.1 추가 의존성

```yaml
dependencies:
  # 기존 MVP 의존성 +
  multi_split_view: ^2.4.0       # 패널 분할
  flutter_colorpicker: ^1.0.3    # 색상 선택
  desktop_drop: ^0.4.4           # 파일 드래그&드롭
  window_manager: ^0.3.8         # 윈도우 관리
```

### 3.2 애니메이션 시퀀스 데이터 모델

```dart
@freezed
class AnimationSequence with _$AnimationSequence {
  const factory AnimationSequence({
    required String id,
    required String name,
    required List<AnimationFrame> frames,
    @Default(true) bool loop,
    @Default(false) bool pingPong,
  }) = _AnimationSequence;
}

@freezed
class AnimationFrame with _$AnimationFrame {
  const factory AnimationFrame({
    required String spriteId,
    required double duration,  // 초 단위
    @Default(false) bool flipX,
    @Default(false) bool flipY,
  }) = _AnimationFrame;
}
```

### 3.3 9-Slice Border 데이터 모델

```dart
@freezed
class NineSliceBorder with _$NineSliceBorder {
  const factory NineSliceBorder({
    required int left,
    required int right,
    required int top,
    required int bottom,
  }) = _NineSliceBorder;
}
```

### 3.4 Undo/Redo 시스템 (Command 패턴)

```dart
abstract class EditorCommand {
  void execute();
  void undo();
  String get description;
}

class CommandHistory {
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];
  static const int maxHistorySize = 50;

  void execute(EditorCommand command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.execute();
      _undoStack.add(command);
    }
  }
}
```

### 3.5 키보드 단축키 매핑

| 단축키 | 동작 |
|--------|------|
| Cmd/Ctrl + N | 새 프로젝트 |
| Cmd/Ctrl + O | 프로젝트 열기 |
| Cmd/Ctrl + S | 프로젝트 저장 |
| Cmd/Ctrl + Shift + S | 다른 이름으로 저장 |
| Cmd/Ctrl + E | 내보내기 |
| Cmd/Ctrl + Z | 실행 취소 |
| Cmd/Ctrl + Shift + Z | 다시 실행 |
| Cmd/Ctrl + A | 전체 선택 |
| Delete/Backspace | 선택 항목 삭제 |
| Cmd/Ctrl + D | 선택 항목 복제 |
| Space + 드래그 | 캔버스 팬 |
| Cmd/Ctrl + 휠 | 줌 인/아웃 |
| 0 | 줌 100% |
| Cmd/Ctrl + 0 | 핏 투 윈도우 |

---

## 4. Modules

### 4.1 Models 모듈 (추가)

| 파일 | 역할 |
|------|------|
| `lib/models/animation_sequence.dart` | 애니메이션 시퀀스 모델 |
| `lib/models/nine_slice_border.dart` | 9-Slice 경계 모델 |
| `lib/models/editor_command.dart` | Command 패턴 기본 클래스 |

### 4.2 Providers 모듈 (추가)

| 파일 | 역할 |
|------|------|
| `lib/providers/history_provider.dart` | Undo/Redo 히스토리 |
| `lib/providers/preview_provider.dart` | 프리뷰 상태 (애니메이션 재생) |

### 4.3 Widgets 모듈 (추가)

| 파일 | 역할 |
|------|------|
| `lib/widgets/panels/animation_panel.dart` | 애니메이션 시퀀스 패널 |
| `lib/widgets/common/animation_timeline.dart` | 애니메이션 타임라인 |
| `lib/widgets/common/nine_slice_preview.dart` | 9-Slice 프리뷰 |
| `lib/widgets/canvas/nine_slice_handles.dart` | 9-Slice 경계 핸들 |
| `lib/widgets/dialogs/animation_editor_dialog.dart` | 애니메이션 편집 다이얼로그 |
| `lib/widgets/dialogs/export_dialog.dart` | 내보내기 옵션 다이얼로그 |
| `lib/widgets/dialogs/project_settings_dialog.dart` | 프로젝트 설정 다이얼로그 |
| `lib/widgets/toolbar/main_toolbar.dart` | 메인 툴바 |
| `lib/widgets/toolbar/slice_tools.dart` | 슬라이싱 툴 버튼 |
| `lib/widgets/toolbar/zoom_controls.dart` | 줌 컨트롤 |

### 4.4 Theme 모듈

| 파일 | 역할 |
|------|------|
| `lib/theme/app_theme.dart` | 다크/라이트 테마 정의 |
| `lib/theme/editor_colors.dart` | 에디터 색상 상수 |
| `lib/theme/editor_icons.dart` | 커스텀 아이콘 |

---

## 5. Deliverables

| 산출물 | 설명 |
|--------|------|
| 애니메이션 편집기 | 시퀀스 생성/편집/프리뷰 |
| 9-Slice 시스템 | 경계 설정 + 시각적 편집 + 프리뷰 |
| Undo/Redo | 50단계 히스토리 |
| 다중 소스 지원 | 여러 이미지 동시 편집 |
| 완성된 UI/UX | 드래그&드롭, 단축키, 테마 |
| 내보내기 다이얼로그 | 아틀라스 설정 UI |
| Rive 호환 출력 | assetLoader 연동 가능한 메타데이터 |

---

## 6. Risks & Mitigations

| 리스크 | 영향 | 완화 방안 |
|--------|------|----------|
| Undo/Redo 메모리 사용 | 중간 | 히스토리 크기 제한, 스냅샷 최적화 |
| 다중 소스 복잡도 증가 | 중간 | 소스별 탭 UI, 명확한 상태 분리 |
| 애니메이션 프리뷰 성능 | 낮음 | 프레임 캐싱, 저해상도 프리뷰 |
| 플랫폼별 단축키 차이 | 낮음 | Platform.isMacOS 분기, 설정 커스터마이징 |

---

## 7. Notes

- PUBLIC 단계 완료 시 Unity Sprite Editor와 유사한 완성도 달성 목표
- 모든 출력은 BatchRenderer + Rive 호환성 유지 필수
- 테마는 macOS 기본 다크 모드 연동 고려
- 키보드 단축키는 Figma/Photoshop 컨벤션 참고
- 애니메이션 편집기는 향후 Spine/DragonBones 수준 확장 고려하여 설계

---

## 8. UI Layout (최종)

```
┌────────────────────────────────────────────────────────────────────────────┐
│  [FILE] [EDIT] [VIEW] [TOOLS] [HELP]                              [EXPORT] │
├────────────────────────────────────────────────────────────────────────────┤
│  ┌─ TOOLBAR ──────────────────────────────────────────────────────────────┐ │
│  │ [Select] [Rect] [Auto] [Grid] | [Zoom-] [100%] [Zoom+] | [Grid Toggle] │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
├──────────────────────┬─────────────────────────────┬──────────────────────┤
│                      │                             │                      │
│   SOURCE PANEL       │     ATLAS PREVIEW          │   PROPERTIES PANEL   │
│   ┌──────────────┐   │     ┌─────────────────┐    │   ┌────────────────┐ │
│   │              │   │     │                 │    │   │ Sprite ID:     │ │
│   │  [SourceImg] │   │     │   [Packed       │    │   │ ┌────────────┐ │ │
│   │              │   │     │    Atlas]       │    │   │ │ enemy_idle │ │ │
│   │   + Slice    │   │     │                 │    │   │ └────────────┘ │ │
│   │   Overlay    │   │     │   + Sprite      │    │   ├────────────────┤ │
│   │              │   │     │     Rects       │    │   │ Position:      │ │
│   │              │   │     │                 │    │   │ X: 128  Y: 256 │ │
│   │              │   │     │                 │    │   │ W: 64   H: 64  │ │
│   │              │   │     │                 │    │   ├────────────────┤ │
│   └──────────────┘   │     └─────────────────┘    │   │ Pivot:         │ │
│                      │                             │   │ [●][●][●]      │ │
│                      │                             │   │ [●][●][●]      │ │
│                      │                             │   │ [●][●][●]      │ │
│                      │                             │   │ Custom: X Y    │ │
│                      │                             │   ├────────────────┤ │
│                      │                             │   │ 9-Slice:       │ │
│                      │                             │   │ L:__ R:__ T:__ │ │
│                      │                             │   │ B:__           │ │
│                      │                             │   │ [Preview]      │ │
│                      │                             │   └────────────────┘ │
├──────────────────────┴─────────────────────────────┴──────────────────────┤
│   SPRITE LIST                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐ │
│   │ [■ enemy_idle] [■ enemy_walk_0] [■ enemy_walk_1] [■ enemy_attack]    │ │
│   └──────────────────────────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────────────────────────┤
│   ANIMATION SEQUENCES                                                      │
│   ┌──────────────────────────────────────────────────────────────────────┐ │
│   │ [+ New] | enemy_walk: [0] [1] [0] [1] | Loop | 0.1s                  │ │
│   │         | enemy_attack: [2] [3] [4]   | Once | 0.08s                 │ │
│   └──────────────────────────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────────────────────────┤
│  STATUS: 24 sprites | Atlas: 1024x512 | Memory: ~2.1MB                    │
└───────────────────────────────────────────────────────────────────────────┘
```

---

*Generated by Claude Code - 2025-12-22*
