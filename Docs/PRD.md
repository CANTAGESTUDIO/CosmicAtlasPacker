# CosmicAtlasPacker PRD - Flutter Desktop 텍스처 패킹 에디터

> Unity Sprite Atlas/Editor 스타일의 텍스처 패킹 도구
> BatchRenderer + Rive 호환 출력

---

## 1. 개요

### 1.1 프로젝트 정보

| 항목 | 내용 |
|------|------|
| 프로젝트명 | CosmicAtlasPacker |
| 플랫폼 | Flutter Desktop (macOS/Windows/Linux) |
| 상태관리 | Riverpod |
| 출력 | PNG 아틀라스 + JSON 메타데이터 |
| 호환 | BatchRenderer (drawVertices), Rive assetLoader |

### 1.2 목표

기존 텍스처 패킹 도구들(flame_texturepacker, flame_fire_atlas, binpack)의 한계를 극복하고, BatchRenderer와 Rive 모두 호환되는 통합 텍스처 패킹 솔루션 제공.

### 1.3 핵심 차별점

| 기존 도구 | 한계 | CosmicAtlasPacker 해결책 |
|-----------|------|-----------------|
| flame_texturepacker | 외부 도구 의존 (TexturePacker) | 자체 에디터 내장 |
| flame_fire_atlas | Fire Atlas Editor 전용 | 독립 실행 |
| binpack | 알고리즘만 제공, UI 없음 | 완전한 GUI 에디터 |
| 모든 도구 | Rive 연동 미지원 | Rive assetLoader 호환 출력 |

---

## 2. 핵심 기능

### 2.1 자동 슬라이싱 (Unity 스타일)
- 투명도 기반 자동 스프라이트 감지 (Flood Fill 알고리즘)
- 그리드 슬라이싱 (Cell Size / Cell Count)
- 수동 사각형 편집 (드래그)

### 2.2 Pivot/Anchor 설정
- 9개 프리셋 버튼 (3x3 그리드)
  - TopLeft, TopCenter, TopRight
  - CenterLeft, Center, CenterRight
  - BottomLeft, BottomCenter, BottomRight
- Custom Pivot 좌표 입력 (0.0~1.0 normalized)
- 시각적 피봇 드래그 핸들

### 2.3 애니메이션 시퀀스 정의
- 프레임 순서 드래그&드롭
- 프레임 타이밍 (duration in seconds)
- 루프/핑퐁 설정
- flipX/flipY 지원 (좌우/상하 반전)

### 2.4 9-Slice Border 설정
- L/R/T/B 경계 입력 (픽셀 단위)
- 시각적 드래그로 경계 조절
- 9-slice 프리뷰 (리사이즈 시뮬레이션)

### 2.5 스프라이트 ID 관리
- 고유 ID 부여 및 편집 UI
- 중복 ID 검증 (실시간)
- ID로 스프라이트 참조 (BatchRenderer, Rive)

---

## 3. 프로젝트 구조

```
texture_packer_editor/
├── lib/
│   ├── main.dart                           # 앱 엔트리포인트
│   │
│   ├── core/                               # 핵심 유틸리티
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # 앱 상수
│   │   │   └── editor_constants.dart       # 에디터 상수 (그리드, 줌 레벨 등)
│   │   ├── extensions/
│   │   │   ├── image_extension.dart        # dart:ui Image 확장
│   │   │   ├── rect_extension.dart         # Rect 확장
│   │   │   └── color_extension.dart        # Color 확장
│   │   └── utils/
│   │       ├── image_utils.dart            # 이미지 처리 유틸
│   │       ├── file_utils.dart             # 파일 I/O 유틸
│   │       └── math_utils.dart             # 수학 연산 유틸
│   │
│   ├── models/                             # 데이터 모델
│   │   ├── sprite_data.dart                # 개별 스프라이트 정보
│   │   ├── animation_sequence.dart         # 애니메이션 시퀀스
│   │   ├── pivot_point.dart                # 피봇 포인트
│   │   ├── nine_slice_border.dart          # 9-슬라이스 경계
│   │   ├── atlas_project.dart              # 프로젝트 전체 데이터
│   │   ├── atlas_metadata.dart             # 내보내기용 메타데이터
│   │   └── enums/
│   │       ├── pivot_preset.dart           # 피봇 프리셋 (9개)
│   │       ├── slice_mode.dart             # 슬라이싱 모드
│   │       └── tool_mode.dart              # 에디터 툴 모드
│   │
│   ├── services/                           # 비즈니스 로직
│   │   ├── image_slicer_service.dart       # 자동 슬라이싱 알고리즘
│   │   ├── bin_packer_service.dart         # 빈 패킹 알고리즘
│   │   ├── export_service.dart             # PNG + JSON 내보내기
│   │   ├── project_service.dart            # 프로젝트 저장/로드
│   │   └── validation_service.dart         # ID 중복 검증 등
│   │
│   ├── providers/                          # Riverpod 상태 관리
│   │   ├── project_provider.dart           # 프로젝트 상태
│   │   ├── editor_state_provider.dart      # 에디터 UI 상태
│   │   ├── selection_provider.dart         # 선택된 스프라이트
│   │   ├── tool_provider.dart              # 현재 툴 상태
│   │   ├── history_provider.dart           # Undo/Redo 히스토리
│   │   └── preview_provider.dart           # 프리뷰 상태
│   │
│   ├── widgets/                            # UI 컴포넌트
│   │   ├── panels/
│   │   │   ├── source_panel.dart           # 소스 이미지 패널
│   │   │   ├── atlas_preview_panel.dart    # 아틀라스 프리뷰 패널
│   │   │   ├── sprite_list_panel.dart      # 스프라이트 목록 패널
│   │   │   ├── properties_panel.dart       # 속성 편집 패널
│   │   │   └── animation_panel.dart        # 애니메이션 시퀀스 패널
│   │   │
│   │   ├── canvas/
│   │   │   ├── source_canvas.dart          # 소스 이미지 캔버스
│   │   │   ├── atlas_canvas.dart           # 아틀라스 캔버스
│   │   │   ├── sprite_selection_overlay.dart # 선택 영역 오버레이
│   │   │   ├── grid_overlay.dart           # 그리드 오버레이
│   │   │   ├── pivot_handle.dart           # 피봇 드래그 핸들
│   │   │   └── nine_slice_handles.dart     # 9-슬라이스 경계 핸들
│   │   │
│   │   ├── dialogs/
│   │   │   ├── grid_slice_dialog.dart      # 그리드 슬라이싱 설정
│   │   │   ├── export_dialog.dart          # 내보내기 옵션
│   │   │   ├── animation_editor_dialog.dart # 애니메이션 편집
│   │   │   └── project_settings_dialog.dart # 프로젝트 설정
│   │   │
│   │   ├── toolbar/
│   │   │   ├── main_toolbar.dart           # 메인 툴바
│   │   │   ├── slice_tools.dart            # 슬라이싱 툴
│   │   │   └── zoom_controls.dart          # 줌 컨트롤
│   │   │
│   │   └── common/
│   │       ├── pivot_preset_selector.dart  # 피봇 프리셋 선택기
│   │       ├── sprite_thumbnail.dart       # 스프라이트 썸네일
│   │       ├── animation_timeline.dart     # 애니메이션 타임라인
│   │       └── nine_slice_preview.dart     # 9-슬라이스 프리뷰
│   │
│   ├── screens/
│   │   └── editor_screen.dart              # 메인 에디터 화면
│   │
│   └── theme/
│       ├── app_theme.dart                  # 앱 테마
│       ├── editor_colors.dart              # 에디터 색상
│       └── editor_icons.dart               # 커스텀 아이콘
│
├── assets/
│   └── icons/                              # 툴바 아이콘
│
└── pubspec.yaml
```

---

## 4. UI 레이아웃

### 4.1 메인 화면 구조

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
│   │ [+ New] | enemy_walk: [0] [1] [0] [1] | Loop | 0.1s                  │
│   │         | enemy_attack: [2] [3] [4]   | Once | 0.08s                 │
│   └──────────────────────────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────────────────────────┤
│  STATUS: 24 sprites | Atlas: 1024x512 | Memory: ~2.1MB                    │
└───────────────────────────────────────────────────────────────────────────┘
```

### 4.2 패널 상세

**Source Panel (소스 이미지 패널)**
- 소스 이미지 표시 (줌/팬 지원)
- 슬라이싱 오버레이 (사각형 선택 영역 표시)
- 드래그로 사각형 선택
- 투명도 기반 자동 감지 영역 하이라이트

**Atlas Preview Panel (아틀라스 프리뷰 패널)**
- 패킹된 아틀라스 실시간 프리뷰
- 선택된 스프라이트 하이라이트
- 줌/팬 지원
- 아틀라스 크기 정보 표시

**Properties Panel (속성 패널)**
- 스프라이트 ID 편집 (텍스트 필드)
- 위치/크기 정보 (읽기 전용)
- 9개 피봇 프리셋 버튼 (3x3 그리드)
- 커스텀 피봇 X/Y 입력
- 9-슬라이스 경계 입력 (L/R/T/B)
- 9-슬라이스 프리뷰 버튼

**Sprite List Panel (스프라이트 목록)**
- 가로 스크롤 썸네일 리스트
- 드래그&드롭으로 순서 변경
- 다중 선택 지원 (Shift/Ctrl+Click)
- 우클릭 컨텍스트 메뉴 (삭제, 복제, 이름 변경)

**Animation Panel (애니메이션 패널)**
- 애니메이션 시퀀스 목록
- 타임라인 에디터
- 프레임 드래그&드롭
- 루프/핑퐁 토글
- 프레임 타이밍 조절
- 애니메이션 프리뷰 재생

---

## 5. 핵심 알고리즘

### 5.1 빈 패킹 (MaxRects Best Short Side Fit)

```dart
/// MaxRects 빈 패킹 알고리즘
/// Unity Sprite Atlas와 유사한 방식
class BinPackerService {

  PackingResult pack({
    required List<SpriteData> sprites,
    required AtlasSettings settings,
  }) {
    // 1. 스프라이트를 면적 기준 내림차순 정렬 (큰 것부터)
    final sorted = [...sprites]
      ..sort((a, b) {
        final areaA = a.sourceRect.width * a.sourceRect.height;
        final areaB = b.sourceRect.width * b.sourceRect.height;
        return areaB.compareTo(areaA);
      });

    // 2. 초기 빈 사각형 (전체 아틀라스 영역)
    final freeRects = <Rect>[
      Rect.fromLTWH(0, 0, settings.maxWidth.toDouble(), settings.maxHeight.toDouble()),
    ];

    final placements = <String, Rect>{};

    for (final sprite in sorted) {
      // 3. Best Short Side Fit (BSSF) 휴리스틱으로 최적 위치 찾기
      final (bestRect, bestIndex) = _findBestPosition(freeRects, spriteWidth, spriteHeight);

      if (bestRect == null) {
        return PackingResult.failed('Cannot fit sprite ${sprite.id}');
      }

      // 4. 스프라이트 배치
      placements[sprite.id] = Rect.fromLTWH(...);

      // 5. 빈 영역 분할 (Guillotine Split)
      _splitFreeRect(freeRects, bestIndex, placedRect);
    }

    return PackingResult.success(placements: placements, ...);
  }

  /// Best Short Side Fit - 짧은 변 차이가 최소인 위치 찾기
  (Rect?, int) _findBestPosition(List<Rect> freeRects, int width, int height) {
    // 각 빈 사각형에 대해 short side fit 계산
    // 가장 fit이 좋은 위치 반환
  }
}
```

### 5.2 자동 슬라이싱 (투명도 기반)

```dart
/// 투명도 기반 자동 스프라이트 감지
class ImageSlicerService {

  List<Rect> autoSlice({
    required Uint8List imageBytes,
    required int width,
    required int height,
    int alphaThreshold = 0,
    int minSpriteSize = 4,
  }) {
    // 1. 알파 채널 추출하여 2D 배열 생성
    final alphaMap = _extractAlphaMap(imageBytes, width, height);

    // 2. 불투명 픽셀을 1, 투명 픽셀을 0으로 변환
    final binaryMap = List.generate(height, (y) =>
      List.generate(width, (x) => alphaMap[y][x] > alphaThreshold ? 1 : 0));

    // 3. Connected Components 분석 (Flood Fill)
    final visited = List.generate(height, (_) => List.filled(width, false));
    final sprites = <Rect>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (binaryMap[y][x] == 1 && !visited[y][x]) {
          // 새로운 컴포넌트 발견 - 바운딩 박스 계산
          final bounds = _floodFillBounds(binaryMap, visited, x, y, width, height);
          if (bounds.width >= minSpriteSize && bounds.height >= minSpriteSize) {
            sprites.add(bounds);
          }
        }
      }
    }

    return sprites;
  }

  /// 그리드 슬라이싱 (Cell Size 기반)
  List<Rect> gridSliceByCellSize({
    required int imageWidth,
    required int imageHeight,
    required int cellWidth,
    required int cellHeight,
    int offsetX = 0,
    int offsetY = 0,
  }) {
    final sprites = <Rect>[];
    for (int y = offsetY; y + cellHeight <= imageHeight; y += cellHeight) {
      for (int x = offsetX; x + cellWidth <= imageWidth; x += cellWidth) {
        sprites.add(Rect.fromLTWH(x, y, cellWidth, cellHeight));
      }
    }
    return sprites;
  }

  /// 그리드 슬라이싱 (Cell Count 기반)
  List<Rect> gridSliceByCellCount({
    required int imageWidth,
    required int imageHeight,
    required int columns,
    required int rows,
  }) {
    final cellWidth = imageWidth ~/ columns;
    final cellHeight = imageHeight ~/ rows;
    return gridSliceByCellSize(...);
  }
}
```

---

## 6. 데이터 모델

### 6.1 스프라이트 데이터

```dart
@freezed
class SpriteData with _$SpriteData {
  const factory SpriteData({
    required String id,                    // 고유 ID (spriteId)
    required String sourceFile,            // 원본 파일 경로
    required Rect sourceRect,              // 원본에서의 위치
    required Rect packedRect,              // 아틀라스에서의 위치
    required PivotPoint pivot,             // 피봇 포인트
    NineSliceBorder? nineSlice,            // 9-슬라이스 (optional)
    @Default({}) Map<String, dynamic> customData,
  }) = _SpriteData;
}
```

### 6.2 피봇 포인트

```dart
@freezed
class PivotPoint with _$PivotPoint {
  const factory PivotPoint({
    required double x,  // 0.0 ~ 1.0 (normalized)
    required double y,  // 0.0 ~ 1.0 (normalized)
    @Default(PivotPreset.center) PivotPreset preset,
  }) = _PivotPoint;

  factory PivotPoint.fromPreset(PivotPreset preset) {
    return switch (preset) {
      PivotPreset.topLeft     => PivotPoint(x: 0.0, y: 0.0, preset: preset),
      PivotPreset.topCenter   => PivotPoint(x: 0.5, y: 0.0, preset: preset),
      PivotPreset.topRight    => PivotPoint(x: 1.0, y: 0.0, preset: preset),
      PivotPreset.centerLeft  => PivotPoint(x: 0.0, y: 0.5, preset: preset),
      PivotPreset.center      => PivotPoint(x: 0.5, y: 0.5, preset: preset),
      PivotPreset.centerRight => PivotPoint(x: 1.0, y: 0.5, preset: preset),
      PivotPreset.bottomLeft  => PivotPoint(x: 0.0, y: 1.0, preset: preset),
      PivotPreset.bottomCenter=> PivotPoint(x: 0.5, y: 1.0, preset: preset),
      PivotPreset.bottomRight => PivotPoint(x: 1.0, y: 1.0, preset: preset),
      PivotPreset.custom      => PivotPoint(x: 0.5, y: 0.5, preset: preset),
    };
  }
}

enum PivotPreset {
  topLeft, topCenter, topRight,
  centerLeft, center, centerRight,
  bottomLeft, bottomCenter, bottomRight,
  custom,
}
```

### 6.3 애니메이션 시퀀스

```dart
@freezed
class AnimationSequence with _$AnimationSequence {
  const factory AnimationSequence({
    required String id,                    // 애니메이션 ID
    required String name,                  // 표시 이름
    required List<AnimationFrame> frames,  // 프레임 목록
    @Default(true) bool loop,              // 루프 여부
    @Default(false) bool pingPong,         // 핑퐁 재생
  }) = _AnimationSequence;
}

@freezed
class AnimationFrame with _$AnimationFrame {
  const factory AnimationFrame({
    required String spriteId,              // 참조하는 스프라이트 ID
    required double duration,              // 프레임 지속 시간 (초)
    @Default(false) bool flipX,            // X 플립
    @Default(false) bool flipY,            // Y 플립
  }) = _AnimationFrame;
}
```

### 6.4 아틀라스 설정

```dart
@freezed
class AtlasSettings with _$AtlasSettings {
  const factory AtlasSettings({
    @Default(2048) int maxWidth,
    @Default(2048) int maxHeight,
    @Default(2) int padding,               // 스프라이트 간 패딩
    @Default(1) int extrude,               // 엣지 익스트루드 (bleeding 방지)
    @Default(true) bool trimTransparent,   // 투명 영역 트림
    @Default(true) bool powerOfTwo,        // 2의 제곱 크기로
    @Default(false) bool forceSquare,      // 정사각형 강제
  }) = _AtlasSettings;
}
```

---

## 7. 메타데이터 JSON 스키마

### 7.1 출력 JSON 형식

```json
{
  "version": "1.0.0",
  "generator": "AtlasEdit",
  "atlas": {
    "file": "sprites_atlas.png",
    "width": 1024,
    "height": 512,
    "format": "RGBA8888"
  },
  "sprites": {
    "enemy_idle": {
      "frame": {
        "x": 0,
        "y": 0,
        "w": 64,
        "h": 64
      },
      "pivot": {
        "x": 0.5,
        "y": 1.0
      },
      "nineSlice": null
    },
    "enemy_walk_0": {
      "frame": {
        "x": 64,
        "y": 0,
        "w": 64,
        "h": 64
      },
      "pivot": {
        "x": 0.5,
        "y": 1.0
      },
      "nineSlice": null
    },
    "button_normal": {
      "frame": {
        "x": 0,
        "y": 64,
        "w": 128,
        "h": 48
      },
      "pivot": {
        "x": 0.5,
        "y": 0.5
      },
      "nineSlice": {
        "left": 12,
        "right": 12,
        "top": 12,
        "bottom": 12
      }
    }
  },
  "animations": {
    "enemy_walk": {
      "frames": [
        { "spriteId": "enemy_walk_0", "duration": 0.1, "flipX": false },
        { "spriteId": "enemy_walk_1", "duration": 0.1, "flipX": false }
      ],
      "loop": true,
      "pingPong": false
    },
    "enemy_attack": {
      "frames": [
        { "spriteId": "enemy_attack_0", "duration": 0.08 },
        { "spriteId": "enemy_attack_1", "duration": 0.08 },
        { "spriteId": "enemy_attack_2", "duration": 0.12 }
      ],
      "loop": false,
      "pingPong": false
    }
  },
  "meta": {
    "createdAt": "2025-12-22T10:30:00Z",
    "app": "AtlasEdit",
    "appVersion": "1.0.0"
  }
}
```

---

## 8. 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 코드 생성
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # 파일 I/O
  file_picker: ^6.1.1
  path_provider: ^2.1.2
  path: ^1.8.3

  # 이미지 처리
  image: ^4.1.3

  # UI
  multi_split_view: ^2.4.0
  flutter_colorpicker: ^1.0.3

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.6
  riverpod_generator: ^2.3.11
  json_serializable: ^6.7.1
```

---

## 9. 구현 우선순위

### Phase 1: MVP (핵심)
1. 이미지 로드 및 표시
2. 수동 사각형 슬라이싱
3. 그리드 슬라이싱
4. 스프라이트 ID 편집 UI
5. 빈 패킹 알고리즘
6. PNG + JSON 내보내기

### Phase 2: 편의 기능
1. 투명도 기반 자동 슬라이싱
2. 피봇 프리셋 및 커스텀 피봇
3. 프로젝트 저장/로드 (.atlas)
4. ID 중복 검증

### Phase 3: 고급 기능
1. 애니메이션 시퀀스 편집기
2. 9-슬라이스 경계 설정
3. Undo/Redo
4. 다중 소스 이미지

### Phase 4: 폴리싱
1. 드래그&드롭 개선
2. 키보드 단축키
3. 프리뷰 애니메이션 재생
4. 다크/라이트 테마

---

## 10. 호환성 참조 코드

### 10.1 현재 BatchRenderer 전체 코드

> 이 코드는 dont-touch-my-acorn 프로젝트에서 사용 중인 BatchRenderer입니다.
> AtlasEdit의 출력 JSON은 이 렌더러와 100% 호환되어야 합니다.

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 고성능 배치 렌더러
/// drawVertices를 사용하여 대량의 스프라이트를 한 번의 드로우콜로 렌더링
class BatchRenderer {
  // drawVertices 제한: 16,383개 쿼드 (65,532 정점 / 4)
  static const int maxQuadsPerBatch = 16383;
  static const int verticesPerQuad = 4;
  static const int indicesPerQuad = 6;
  static const int floatsPerVertex = 2; // x, y

  // 사전 할당된 버퍼 (게임 시작 시 한 번만!)
  late final Float32List _positions;
  late final Float32List _texCoords;
  late final Int32List _colors;
  late final Uint16List _indices;
  late final Paint _paint;

  final ui.Image _atlas;
  final double _spriteWidth;
  final double _spriteHeight;
  final int _spritesPerRow;
  final double _atlasWidth;
  final double _atlasHeight;

  BatchRenderer({
    required ui.Image atlas,
    required double spriteWidth,
    required double spriteHeight,
    required int spritesPerRow,
  })  : _atlas = atlas,
        _spriteWidth = spriteWidth,
        _spriteHeight = spriteHeight,
        _spritesPerRow = spritesPerRow,
        _atlasWidth = atlas.width.toDouble(),
        _atlasHeight = atlas.height.toDouble() {
    _initBuffers();
  }

  void _initBuffers() {
    const maxVertices = maxQuadsPerBatch * verticesPerQuad;
    const maxIndices = maxQuadsPerBatch * indicesPerQuad;

    _positions = Float32List(maxVertices * floatsPerVertex);
    _texCoords = Float32List(maxVertices * floatsPerVertex);
    _colors = Int32List(maxVertices);
    _indices = Uint16List(maxIndices);

    // 인덱스 사전 생성 (고정값)
    for (int i = 0; i < maxQuadsPerBatch; i++) {
      final indexOffset = i * indicesPerQuad;
      final vertexOffset = i * verticesPerQuad;

      _indices[indexOffset + 0] = vertexOffset + 0;
      _indices[indexOffset + 1] = vertexOffset + 1;
      _indices[indexOffset + 2] = vertexOffset + 2;
      _indices[indexOffset + 3] = vertexOffset + 2;
      _indices[indexOffset + 4] = vertexOffset + 3;
      _indices[indexOffset + 5] = vertexOffset + 0;
    }

    _paint = Paint()
      ..shader = ui.ImageShader(
        _atlas,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      )
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.low;
  }

  /// 단일 쿼드 버퍼 채우기
  void _fillQuad(
    int quadIndex,
    double x,
    double y,
    int spriteFrame, {
    int color = 0xFFFFFFFF,
    double scale = 1.0,
    double scaleY = 1.0,  // Y축 개별 스케일
  }) {
    final posOffset = quadIndex * verticesPerQuad * floatsPerVertex;
    final texOffset = quadIndex * verticesPerQuad * floatsPerVertex;
    final colorOffset = quadIndex * verticesPerQuad;

    // 스프라이트 크기 (스케일 적용, Y축은 별도)
    final w = _spriteWidth * scale;
    final h = _spriteHeight * scale * scaleY;

    // 중심 기준 오프셋
    final halfW = w / 2;
    final fullH = h;  // 발 기준 피봇을 위해 전체 높이 사용

    // 위치 버퍼 (4개 정점) - 발(bottom) 기준 피봇
    _positions[posOffset + 0] = x - halfW; // top-left x
    _positions[posOffset + 1] = y - fullH; // top-left y
    _positions[posOffset + 2] = x + halfW; // top-right x
    _positions[posOffset + 3] = y - fullH; // top-right y
    _positions[posOffset + 4] = x + halfW; // bottom-right x
    _positions[posOffset + 5] = y;         // bottom-right y
    _positions[posOffset + 6] = x - halfW; // bottom-left x
    _positions[posOffset + 7] = y;         // bottom-left y

    // 텍스처 좌표 계산 (ImageShader는 픽셀 좌표를 사용!)
    final col = spriteFrame % _spritesPerRow;
    final row = spriteFrame ~/ _spritesPerRow;

    // 픽셀 좌표로 설정 (UV 0~1이 아님!)
    final tx0 = col * _spriteWidth;
    final ty0 = row * _spriteHeight;
    final tx1 = (col + 1) * _spriteWidth;
    final ty1 = (row + 1) * _spriteHeight;

    _texCoords[texOffset + 0] = tx0;
    _texCoords[texOffset + 1] = ty0;
    _texCoords[texOffset + 2] = tx1;
    _texCoords[texOffset + 3] = ty0;
    _texCoords[texOffset + 4] = tx1;
    _texCoords[texOffset + 5] = ty1;
    _texCoords[texOffset + 6] = tx0;
    _texCoords[texOffset + 7] = ty1;

    // 색상 버퍼
    _colors[colorOffset + 0] = color;
    _colors[colorOffset + 1] = color;
    _colors[colorOffset + 2] = color;
    _colors[colorOffset + 3] = color;
  }

  /// 버퍼 내용을 화면에 렌더링 (drawVertices + ImageShader)
  void _flush(Canvas canvas, int quadCount) {
    if (quadCount == 0) return;

    final vertexCount = quadCount * verticesPerQuad;
    final indexCount = quadCount * indicesPerQuad;

    // colors 버퍼 없이 생성 - ImageShader가 텍스처 색상을 그대로 사용
    final vertices = ui.Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(_positions, 0, vertexCount * floatsPerVertex),
      textureCoordinates:
          Float32List.sublistView(_texCoords, 0, vertexCount * floatsPerVertex),
      indices: Uint16List.sublistView(_indices, 0, indexCount),
    );

    // srcOver로 투명도 올바르게 블렌딩
    canvas.drawVertices(vertices, BlendMode.srcOver, _paint);
  }

  /// 오브젝트 리스트 배치 렌더링
  void render<T>(
    Canvas canvas,
    Iterable<T> objects, {
    required bool Function(T) isActive,
    required double Function(T) getX,
    required double Function(T) getY,
    required int Function(T) getFrame,
    int Function(T)? getColor,
    double Function(T)? getScale,
    double Function(T)? getScaleY,  // Y축 개별 스케일
  }) {
    int quadCount = 0;

    for (final obj in objects) {
      if (!isActive(obj)) continue;

      _fillQuad(
        quadCount,
        getX(obj),
        getY(obj),
        getFrame(obj),
        color: getColor?.call(obj) ?? 0xFFFFFFFF,
        scale: getScale?.call(obj) ?? 1.0,
        scaleY: getScaleY?.call(obj) ?? 1.0,
      );
      quadCount++;

      // 배치 한계 도달 시 플러시
      if (quadCount >= maxQuadsPerBatch) {
        _flush(canvas, quadCount);
        quadCount = 0;
      }
    }

    // 남은 쿼드 렌더링
    if (quadCount > 0) {
      _flush(canvas, quadCount);
    }
  }
}
```

### 10.2 BatchRenderer 사용 예시

```dart
// 아틀라스 로드 및 초기화
final atlasImage = await game.images.load('enemy_atlas.png');

_batchRenderer = BatchRenderer(
  atlas: atlasImage,
  spriteWidth: 512.0,   // 각 스프라이트 크기
  spriteHeight: 512.0,
  spritesPerRow: 2,     // 한 행에 2개 (Left=0, Right=1)
);

// 렌더링 (1 draw call로 모든 적 렌더링)
_batchRenderer.render<EnemyEntity>(
  canvas,
  _pool.activeObjects,
  isActive: (e) => e.active,
  getX: (e) => e.x,
  getY: (e) => e.y,
  getFrame: (e) => e.facingRight ? 1 : 0,  // 방향으로 프레임 선택
  getScale: (e) => 64.0 / 512.0,           // 렌더 크기 / 스프라이트 크기
  getScaleY: (e) => scaleY,                // Y축 애니메이션
);
```

### 10.3 현재 BatchRenderer의 제한사항

| 제한 | 현재 상태 | 개선 필요 |
|------|---------|---------|
| **고정 스프라이트 크기** | 모든 프레임이 동일 크기 | 가변 크기 지원 필요 |
| **격자 배치** | row/col 기반 인덱싱 | 자유 배치 지원 필요 |
| **피봇** | 하드코딩 (bottom-center) | 메타데이터 기반 피봇 |
| **프레임 참조** | int 인덱스 | string ID 기반 참조 |

### 10.4 가변 크기 BatchRenderer 확장안

```dart
/// 스프라이트 프레임 정보
class SpriteFrame {
  final int x, y, width, height;
  final double pivotX, pivotY;  // 0.0~1.0 normalized
  final NineSlice? nineSlice;

  SpriteFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.pivotX = 0.5,
    this.pivotY = 1.0,  // bottom-center 기본값
    this.nineSlice,
  });
}

/// 가변 크기 스프라이트 지원 BatchRenderer
class VariableSizeBatchRenderer {
  final ui.Image _atlas;
  final Map<String, SpriteFrame> _frames;  // ID -> 프레임 정보

  VariableSizeBatchRenderer({
    required ui.Image atlas,
    required Map<String, SpriteFrame> frames,
  }) : _atlas = atlas, _frames = frames;

  void _fillQuadVariable(
    int quadIndex,
    double x,
    double y,
    String spriteId, {
    double scale = 1.0,
    double scaleY = 1.0,
    bool flipX = false,
    bool flipY = false,
  }) {
    final frame = _frames[spriteId];
    if (frame == null) return;

    // 스프라이트 크기
    final w = frame.width * scale;
    final h = frame.height * scale * scaleY;

    // 피봇 기반 오프셋 계산
    final offsetX = w * frame.pivotX;
    final offsetY = h * frame.pivotY;

    // 위치 버퍼 (피봇 적용)
    _positions[posOffset + 0] = x - offsetX;       // top-left
    _positions[posOffset + 1] = y - offsetY;
    _positions[posOffset + 2] = x - offsetX + w;   // top-right
    _positions[posOffset + 3] = y - offsetY;
    _positions[posOffset + 4] = x - offsetX + w;   // bottom-right
    _positions[posOffset + 5] = y - offsetY + h;
    _positions[posOffset + 6] = x - offsetX;       // bottom-left
    _positions[posOffset + 7] = y - offsetY + h;

    // 텍스처 좌표 (픽셀 좌표)
    var tx0 = frame.x.toDouble();
    var ty0 = frame.y.toDouble();
    var tx1 = (frame.x + frame.width).toDouble();
    var ty1 = (frame.y + frame.height).toDouble();

    // Flip 처리
    if (flipX) { final temp = tx0; tx0 = tx1; tx1 = temp; }
    if (flipY) { final temp = ty0; ty0 = ty1; ty1 = temp; }

    _texCoords[texOffset + 0] = tx0;
    _texCoords[texOffset + 1] = ty0;
    // ... 나머지 텍스처 좌표
  }
}
```

### 10.5 Rive assetLoader 연동 예시

```dart
// Rive에서 아틀라스 이미지 사용
RiveFile.asset(
  'assets/animations/character.riv',
  assetLoader: (asset, bytes) async {
    if (asset is ImageAsset) {
      // 아틀라스에서 해당 이미지 ID로 검색
      final frame = atlasLoader.getFrame(asset.name);
      if (frame != null) {
        // 아틀라스에서 해당 영역 크롭
        final croppedImage = await _cropFromAtlas(
          atlasLoader.atlasImage,
          frame.x, frame.y, frame.width, frame.height,
        );
        asset.image = croppedImage;
        return true;  // 직접 처리함
      }
    }
    return false;  // 런타임에 위임
  },
);
```

---

## 11. 다음 단계

1. **새 Flutter Desktop 프로젝트 생성** (`texture_packer_editor/` 또는 `atlas_edit/`)
2. **Phase 1 MVP 구현** (이미지 로드 → 슬라이싱 → 패킹 → 내보내기)
3. **게임 프로젝트에 VariableSizeBatchRenderer 추가**
4. **메타데이터 로더 통합**

---

*Generated by Claude Code - 2025-12-22*
