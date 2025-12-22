# Information Architecture - CosmicAtlasPacker

> Flutter Desktop 텍스처 패킹 에디터의 정보 구조
> **Last Updated**: 2025-12-22

---

## 1. 전체 애플리케이션 구조

```
[CosmicAtlasPacker]
 │
 ├─[[Editor Workspace]]                    ← 핵심 작업 공간 (메인 화면)
 │  │
 │  ├─[Menu Bar]                           ← 네이티브 메뉴 바
 │  │  ├─File
 │  │  │  ├─New Project
 │  │  │  ├─Open Project (.atlas)
 │  │  │  ├─Save Project
 │  │  │  ├─Save Project As...
 │  │  │  ├─Import Source Image...
 │  │  │  ├─Export Atlas...
 │  │  │  └─Quit
 │  │  │
 │  │  ├─Edit
 │  │  │  ├─Undo (Phase 3)
 │  │  │  ├─Redo (Phase 3)
 │  │  │  ├─Delete Selected
 │  │  │  ├─Duplicate Selected
 │  │  │  └─Select All
 │  │  │
 │  │  ├─View
 │  │  │  ├─Zoom In
 │  │  │  ├─Zoom Out
 │  │  │  ├─Zoom to Fit
 │  │  │  ├─Reset Zoom
 │  │  │  ├─Toggle Grid
 │  │  │  └─Toggle Panels
 │  │  │
 │  │  ├─Tools
 │  │  │  ├─Select Tool
 │  │  │  ├─Rectangle Tool
 │  │  │  ├─Auto Slice (Transparency)
 │  │  │  └─Grid Slice...
 │  │  │
 │  │  └─Help
 │  │     ├─Documentation
 │  │     ├─Keyboard Shortcuts
 │  │     └─About
 │  │
 │  ├─[Main Toolbar]                       ← 툴바 (빠른 액세스)
 │  │  ├─{Tool Buttons}
 │  │  │  ├─Select
 │  │  │  ├─Rect
 │  │  │  ├─Auto Slice
 │  │  │  └─Grid Slice
 │  │  │
 │  │  ├─{Zoom Controls}
 │  │  │  ├─Zoom Out [-]
 │  │  │  ├─Zoom Level [100%]
 │  │  │  └─Zoom In [+]
 │  │  │
 │  │  └─{View Options}
 │  │     ├─Grid Toggle
 │  │     └─Export Button
 │  │
 │  ├─[Canvas Area]                        ← 캔버스 영역 (3-분할)
 │  │  │
 │  │  ├─[[Source Panel]]                  ← 소스 이미지 패널 (좌측)
 │  │  │  ├─{Source Canvas}
 │  │  │  │  ├─Source Image Display
 │  │  │  │  ├─Slice Overlay Rectangles
 │  │  │  │  ├─Selection Highlight
 │  │  │  │  └─Grid Overlay
 │  │  │  │
 │  │  │  └─{Canvas Controls}
 │  │  │     ├─Pan (드래그)
 │  │  │     ├─Zoom (휠)
 │  │  │     └─Rectangle Selection (드래그)
 │  │  │
 │  │  ├─[[Atlas Preview Panel]]           ← 아틀라스 미리보기 (중앙)
 │  │  │  ├─{Atlas Canvas}
 │  │  │  │  ├─Packed Atlas Display
 │  │  │  │  ├─Sprite Rectangles
 │  │  │  │  ├─Selected Sprite Highlight
 │  │  │  │  └─Atlas Size Info
 │  │  │  │
 │  │  │  └─{Canvas Controls}
 │  │  │     ├─Pan (드래그)
 │  │  │     └─Zoom (휠)
 │  │  │
 │  │  └─[[Properties Panel]]              ← 속성 패널 (우측)
 │  │     ├─{Sprite ID Section}
 │  │     │  ├─ID TextField
 │  │     │  └─Validation Indicator
 │  │     │
 │  │     ├─{Position/Size Section}
 │  │     │  ├─X Position (읽기 전용)
 │  │     │  ├─Y Position (읽기 전용)
 │  │     │  ├─Width (읽기 전용)
 │  │     │  └─Height (읽기 전용)
 │  │     │
 │  │     ├─{Pivot Section} (MVP)
 │  │     │  ├─Pivot Preset Grid (3x3)
 │  │     │  └─Custom Pivot X/Y Input
 │  │     │
 │  │     └─{9-Slice Section} (Phase 3)
 │  │        ├─L/R/T/B Border Input
 │  │        └─Preview Button
 │  │
 │  ├─[Bottom Panels]                      ← 하단 패널 영역
 │  │  │
 │  │  ├─[[Sprite List Panel]]             ← 스프라이트 목록 (상단)
 │  │  │  ├─{Sprite Thumbnails}
 │  │  │  │  ├─Thumbnail + ID Label
 │  │  │  │  ├─Selection State
 │  │  │  │  └─Context Menu (우클릭)
 │  │  │  │
 │  │  │  └─{List Controls}
 │  │  │     ├─Vertical Scroll
 │  │  │     ├─Multi-Selection
 │  │  │     └─Drag & Drop (순서 변경)
 │  │  │
 │  │  └─[[Animation Panel]] (Phase 3)     ← 애니메이션 시퀀스 (하단)
 │  │     ├─{Sequence List}
 │  │     │  ├─Sequence Name
 │  │     │  ├─Frame List
 │  │     │  └─Loop/PingPong Settings
 │  │     │
 │  │     └─{Animation Controls}
 │  │        ├─New Sequence Button
 │  │        ├─Edit Button
 │  │        └─Delete Button
 │  │
 │  └─[Status Bar]                         ← 상태 표시줄
 │     ├─Sprite Count
 │     ├─Atlas Size
 │     ├─Memory Usage
 │     └─Current Tool
 │
 ├─(Grid Slice Dialog)                     ← 그리드 슬라이싱 설정 모달
 │  ├─Slice Mode (Cell Size / Cell Count)
 │  ├─Cell Width / Height
 │  ├─Columns / Rows
 │  ├─Offset X / Y
 │  └─[Apply] [Cancel]
 │
 ├─(Auto Slice Settings Dialog) (MVP)     ← 자동 슬라이싱 설정 모달
 │  ├─Alpha Threshold (0~255)
 │  ├─Min Sprite Size
 │  └─[Apply] [Cancel]
 │
 ├─(Export Dialog)                         ← 내보내기 옵션 모달
 │  ├─Atlas Settings
 │  │  ├─Max Width / Height
 │  │  ├─Padding
 │  │  ├─Extrude
 │  │  └─Power of Two / Force Square
 │  │
 │  ├─Output Paths
 │  │  ├─PNG Output Path
 │  │  └─JSON Output Path
 │  │
 │  └─[Export] [Cancel]
 │
 ├─(Animation Editor Dialog) (Phase 3)    ← 애니메이션 편집 모달
 │  ├─{Frame Timeline}
 │  │  ├─Frame Thumbnails
 │  │  ├─Duration Slider
 │  │  └─FlipX/FlipY Toggle
 │  │
 │  ├─{Sequence Settings}
 │  │  ├─Sequence Name
 │  │  ├─Loop Toggle
 │  │  └─PingPong Toggle
 │  │
 │  ├─{Preview Player}
 │  │  └─Animation Playback
 │  │
 │  └─[Save] [Cancel]
 │
 ├─(9-Slice Preview Dialog) (Phase 3)     ← 9-슬라이스 미리보기 모달
 │  ├─{Preview Canvas}
 │  │  └─Resize Simulation
 │  │
 │  └─[Close]
 │
 └─(Project Settings Dialog)               ← 프로젝트 설정 모달
    ├─Project Name
    ├─Default Atlas Settings
    └─[Save] [Cancel]
```

---

## 2. 정보 계층 구조

### 2.1 핵심 컨텐츠 (1-Click)

| 컨텐츠 | 위치 | 접근 경로 |
|--------|------|----------|
| 소스 이미지 작업 | Source Panel | 메인 화면 좌측 |
| 아틀라스 미리보기 | Atlas Preview Panel | 메인 화면 중앙 |
| 스프라이트 속성 편집 | Properties Panel | 메인 화면 우측 |
| 스프라이트 목록 | Sprite List Panel | 메인 화면 하단 |

### 2.2 주요 기능 (2-Click)

| 기능 | 접근 경로 | 단축키 |
|------|----------|--------|
| 그리드 슬라이싱 | Toolbar → Grid Slice | Cmd+G |
| 자동 슬라이싱 | Toolbar → Auto Slice | Cmd+A |
| 프로젝트 저장 | Menu → File → Save | Cmd+S |
| 아틀라스 내보내기 | Toolbar → Export / Menu → File → Export | Cmd+E |

### 2.3 설정/옵션 (2~3-Click)

| 설정 | 접근 경로 |
|------|----------|
| 그리드 슬라이싱 옵션 | Toolbar → Grid Slice → Dialog |
| 자동 슬라이싱 옵션 | Toolbar → Auto Slice → Dialog |
| 내보내기 옵션 | Toolbar → Export → Dialog |
| 애니메이션 편집 | Animation Panel → Edit → Dialog |
| 9-Slice 미리보기 | Properties Panel → 9-Slice → Preview |

---

## 3. 네비게이션 구조

### 3.1 패널 간 네비게이션

```
[Source Panel] ←──────────────┐
      │                       │
      ↓                       │
[Sprite List Panel] ←─────────┤─── 스프라이트 선택 동기화
      │                       │
      ↓                       │
[Properties Panel] ───────────┘
      │
      ↓
[Atlas Preview Panel] ←──────── 패킹 결과 자동 업데이트
```

### 3.2 워크플로우 기반 네비게이션

```
1. 이미지 로드
   File Menu → Import Source Image
   ↓
2. 슬라이싱
   Toolbar → Auto/Grid/Manual Slice
   ↓
3. 스프라이트 편집
   Sprite List → 선택 → Properties 편집
   ↓
4. 아틀라스 확인
   Atlas Preview Panel → 패킹 결과 확인
   ↓
5. 내보내기
   Toolbar → Export → Dialog → PNG + JSON
```

---

## 4. 컨텐츠 분류

### 4.1 입력 (Input)

| 카테고리 | 항목 |
|----------|------|
| 소스 파일 | PNG 이미지 |
| 프로젝트 파일 | .atlas JSON |

### 4.2 편집 (Edit)

| 카테고리 | 항목 |
|----------|------|
| 슬라이싱 | 수동, 그리드, 자동 |
| 스프라이트 속성 | ID, 피봇, 9-Slice |
| 애니메이션 | 시퀀스, 프레임, 타이밍 |

### 4.3 출력 (Output)

| 카테고리 | 항목 |
|----------|------|
| 아틀라스 이미지 | PNG 파일 |
| 메타데이터 | JSON 파일 |
| 프로젝트 | .atlas JSON |

---

## 5. 정보 그룹핑

### 5.1 캔버스 영역 (시각적 작업)

- **Source Panel**: 원본 이미지 + 슬라이싱 오버레이
- **Atlas Preview Panel**: 패킹 결과 미리보기
- **패널 역할 명확화**: Source = 편집, Atlas = 결과 확인

### 5.2 제어 영역 (입력/설정)

- **Toolbar**: 툴 선택, 줌 컨트롤
- **Properties Panel**: 선택된 스프라이트 속성
- **Sprite List Panel**: 전체 스프라이트 개요

### 5.3 모달 다이얼로그 (집중 작업)

- **Grid Slice Dialog**: 그리드 설정
- **Export Dialog**: 내보내기 옵션
- **Animation Editor**: 복잡한 애니메이션 편집

---

## 6. IA 설계 원칙 준수

### 6.1 3-Click Rule

| 기능 | 클릭 수 | 경로 |
|------|---------|------|
| 슬라이싱 | 1 Click | Toolbar → Tool |
| 속성 편집 | 1 Click | Properties Panel |
| 내보내기 | 2 Click | Toolbar → Export → Dialog |
| 애니메이션 편집 | 2 Click | Animation Panel → Edit |

✅ **모든 핵심 기능이 3-Click 이내 접근 가능**

### 6.2 메뉴 항목 수

| 메뉴 | 항목 수 | 상태 |
|------|---------|------|
| File | 7개 | ✅ 7±2 범위 |
| Edit | 5개 | ✅ 7±2 범위 |
| View | 6개 | ✅ 7±2 범위 |
| Tools | 4개 | ✅ 7±2 범위 |
| Help | 3개 | ✅ 7±2 범위 |

✅ **모든 메뉴가 권장 범위 준수**

### 6.3 계층 깊이

| 영역 | 최대 깊이 | 예시 |
|------|----------|------|
| 메뉴 바 | 2 Level | Menu → Action |
| 캔버스 | 3 Level | Panel → Canvas → Overlay |
| 다이얼로그 | 2 Level | Dialog → Section |

✅ **4 Level 이하 권장 준수**

---

## 7. 정보 아키텍처 개선 사항 (ux-ui-specialist 분석 반영)

### 7.1 Critical 이슈 반영

| 이슈 | IA 해결책 |
|------|----------|
| Source Panel vs Atlas Preview 역할 혼동 | **명확한 패널 분리**: Source = 편집 작업, Atlas = 읽기 전용 결과 확인 |
| Sprite List 가로 스크롤 문제 | **수직 그리드 레이아웃**: 썸네일 + ID 라벨, 세로 스크롤 |
| ID 중복 검증 피드백 부재 | **Properties Panel 내 실시간 검증 인디케이터** 추가 |

### 7.2 Major 이슈 반영

| 이슈 | IA 해결책 |
|------|----------|
| 9-Slice 설정 공간 부족 | **Collapsible Section** 또는 **별도 다이얼로그** |
| Animation Panel 복잡도 | **별도 Animation Editor Dialog**로 분리 |
| Toolbar 활성 툴 피드백 | **Toolbar 내 Tool Buttons에 선택 상태 표시** |

---

## 8. 정보 흐름 (Information Flow)

```
[Source Image Import]
       ↓
[Source Panel Display]
       ↓
[Slicing Tool Selection] ────→ [Grid Slice Dialog] (옵션 설정)
       ↓                   └──→ [Auto Slice Dialog] (옵션 설정)
[Slice Rectangles Created]
       ↓
[Sprite List Panel Update] ←──────────┐
       ↓                               │
[Sprite Selection] ───────────────────┤
       ↓                               │
[Properties Panel Display] ───────────┤
       │                               │
       ├─ ID 편집 ──→ Validation      │
       ├─ Pivot 설정                  │ 양방향 동기화
       └─ 9-Slice 설정                │
       ↓                               │
[Bin Packer Service] ─────────────────┤
       ↓                               │
[Atlas Preview Panel Update] ─────────┘
       ↓
[Export Dialog]
       ↓
[PNG + JSON Output]
```

---

*Generated by UX Architect - 2025-12-22*
