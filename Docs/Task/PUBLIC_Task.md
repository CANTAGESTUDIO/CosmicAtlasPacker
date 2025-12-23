# PUBLIC Tasks

> 이 파일은 Archon 칸반보드와 양방향 동기화됩니다.
> Available Tags: #feature, #bugfix, #refactor, #test, #docs, #ui, #api, #db, #config, #chore
> Priority: !high, !medium, !low
> Deadline: Deadline(yyyy:MM:dd)
> Subtask: 2-space indent

## Backlog

## Worker1
- [ ] 텍스처 패커 모드 / 애니메이션 모드 전환 기능 구현 #feature !high @진행중
  - [ ] EditorMode enum 생성 및 editorModeProvider 추가
    <!-- Best Practice Tree -->
    - Enum Design
      - Clear, descriptive names
      - Future-proof extensibility
      - Default value definition
    - State Management
      - StateProvider usage
      - Provider initialization timing
      - Access pattern consistency
  - [ ] EditorToolbar에 모드 전환 토글 버튼(세그먼티드 버튼) 추가
    <!-- Best Practice Tree -->
    - Toggle Button UI
      - Segmented button pattern
      - Visual mode distinction
      - Active/inactive state styling
    - Labels & Icons
      - Descriptive icons
      - Korean label support
      - Tooltip accessibility
    - State Handling
      - Provider subscription
      - Mode toggle logic
      - Visual feedback timing
  - [ ] AnimationSettingsPanel 독립 컴포넌트로 분리 생성
    <!-- Best Practice Tree -->
    - Component Interface
      - Read-only props for data
      - Callback props for actions
      - Minimal internal state
    - Reusability
      - Identify reusable logic
      - Extract to shared utilities
      - Avoid coupled dependencies
    - Testing
      - Isolated unit tests
      - Widget testing coverage
      - Mock provider inputs
  - [ ] EditorScreen에서 _buildMainContent() 메서드 모드별 분기 구현
    <!-- Best Practice Tree -->
    - Code Organization
      - Single responsibility methods
      - Clear separation of concerns
      - Avoid nested conditionals
    - Refactoring Approach
      - Extract existing layout
      - Preserve current functionality
      - Maintain test coverage
    - State Handling
      - Provider watch pattern
      - Conditional rendering logic
      - Performance optimization
  - [ ] _buildTexturePackerLayout() 메서드로 기존 레이아웃 분리
    <!-- Best Practice Tree -->
    - Extraction Strategy
      - Zero breaking changes
      - Preserve controller refs
      - Maintain layout behavior
    - Controller Management
      - Keep controller lifecycle
      - Preserve split ratios
      - Maintain resize handlers
    - Code Clarity
      - Descriptive method name
      - Documentation comments
      - Minimal side effects
  - [ ] _buildAnimationLayout() 메서드로 애니메이션 모드 레이아웃 구현
    <!-- Best Practice Tree -->
    - Layout Structure
      - MultiSplitView pattern
      - Horizontal/vertical nesting
      - Panel size definitions
    - Controller Setup
      - Reuse existing controllers
      - Configure split ratios
      - Handle panel resizing
    - Data Binding
      - ref.watch for provider
      - Pass source image ref
      - Update trigger handling
  - [ ] MultiSourcePanel에서 애니메이션 모드 시 AtlasPreview UI로 아틀라스 표시 처리
    <!-- Best Practice Tree -->
    - Mode Branching Logic
      - Clear mode check
      - Early return pattern
      - Minimal conditional depth
    - Atlas View Component
      - Reuse AtlasPreviewPanel
      - Pass correct image data
      - Maintain preview behavior
    - Sidebar Handling
      - Hide source sidebar
      - Layout space adjustment
      - Smooth transition effect
  - [ ] UI 디자인 세부사항 적용 (패널 크기, 헤더, 토글 버튼 스타일)
    <!-- Best Practice Tree -->
    - Panel Dimensions
      - Fixed panel widths
      - Responsive layout handling
      - EditorColors theme tokens
    - Header Styling
      - Consistent height (28px)
      - EditorColors.background
      - Font sizing alignment
    - Toggle Button Design
      - Follow design system
      - Active state colors
      - Hover interaction states
  - [ ] 모드 전환 시 상태 유지 및 드래그 앤 드롭 지원 구현
    <!-- Best Practice Tree -->
    - State Persistence
      - Independent mode states
      - Provider isolation
      - No data loss on switch
    - Drag & Drop Integration
      - Reuse existing components
      - Frame drag to timeline
      - Drop zone handling
    - Data Flow
      - Frame to sprite mapping
      - Atlas source reference
      - Animation data sync
  - [ ] 통합 테스트 (모드 전환, 각 패널 기능, 상태 유지)
    <!-- Best Practice Tree -->
    - Test Coverage
      - Mode toggle scenarios
      - Each panel functionality
      - State persistence verification
    - Edge Cases
      - Empty data handling
      - Error state recovery
      - Performance under load
    - User Workflow
      - Complete task scenarios
      - Integration testing
      - Regression prevention

## Worker2

## Worker3
- [x] 배경색 제거 설정 다이얼로그 UI 개선 #ui !medium ✓완료
  - [x] 현재 배경색 제거 다이얼로그 구조 분석
  - [x] 배경색 선택 컨트롤 개선 (ColorPicker 통합)
  - [x] 허용 오차(Tolerance) 슬라이더 UI 구현
  - [x] 배경색 제거 옵션 UI 추가 (부드러운 가장자리 등)
  - [x] 배경색 제거 프리뷰 패널 구현
  - [x] 다이얼로그 버튼 레이아웃 및 상호작용 개선

## Review
- [ ] 오토슬라이스 설정 다이얼로그 UI 개선 #ui !medium ✓진행완료
  - [x] 현재 오토슬라이스 다이얼로그 구조 분석
  - [x] 오토슬라이스 파라미터별 시각적 컨트롤 디자인
  - [x] 설정 프리셋 UI 컴포넌트 구현
  - [x] 오토슬라이스 결과 프리뷰 패널 추가
  - [x] 다이얼로그 버튼 레이아웃 및 상호작용 개선
  - [x] 배경색 제거 설정 UI 오토슬라이스 다이얼로그 내 통합
- [ ] 그리드 슬라이스 설정 다이얼로그 UI 개선 #ui !medium ✓진행완료
  - [x] 현재 그리드 슬라이스 다이얼로그 구조 분석
  - [x] 그리드 행/열 설정 UI 디자인 및 구현
  - [x] 셀 간격(Padding) 설정 컨트롤 추가
  - [x] 그리드 옵션 설정 UI 구현 (구분선 표시, 셀명명 등)
  - [x] 그리드 프리뷰 오버레이 위젯 구현
  - [x] 다이얼로그 버튼 레이아웃 및 상호작용 개선
- [ ] 프로젝트 설정 다이얼로그 구현 #settings !low
  - [x] ProjectSettings 모델 생성
  - [x] ProjectSettingsProvider 생성
  - [x] 프로젝트명 편집 UI
  - [x] 기본 아틀라스 설정 UI
  - [x] 자동 저장 옵션 UI
  - [x] 설정 다이얼로그 레이아웃 조립
  - [x] 메뉴에 Settings 항목 추가 (Cmd+,)
- [ ] 상태 표시줄 구현 #ui !low
  - [x] StatusBar 위젯 생성 (하단 고정 Container)
  - [x] 스프라이트 개수 표시 위젯
  - [x] 아틀라스 크기 표시 위젯
  - [x] 메모리 사용량 표시 위젯
  - [x] 현재 줌 레벨 표시 위젯
  - [x] 메인 레이아웃에 StatusBar 통합
- [ ] 테마 시스템 구현 #theme !medium
  - [x] AppTheme 다크/라이트 정의
  - [x] 에디터 색상 상수 정의
  - [x] 시스템 테마 연동 (macOS)
  - [x] 테마 전환 UI
- [ ] 줌 컨트롤 개선 #canvas !medium
  - [x] 마우스 휠 줌 개선 (부드러운 줌)
  - [x] 핏 투 윈도우 기능
  - [x] 줌 레벨 인디케이터
  - [x] 줌 프리셋 버튼 (25%, 50%, 100%, 200%)
- [ ] 내보내기 다이얼로그 구현 #export !medium
  - [x] ExportDialogSettings 모델 (출력 경로, 파일명, 포맷 옵션)
  - [x] 아틀라스 설정 조절 UI (크기, 패딩, 옵션)
  - [x] 출력 파일명/경로 설정 UI
  - [x] 프리뷰 패널 (변경사항 미리보기, 효율성 표시)
  - [x] Export/Cancel 버튼 및 내보내기 로직
  - [x] 메뉴 연동 (Cmd+E)
- [ ] 드래그&드롭 개선 #ux !medium
  - [x] 스프라이트 목록 순서 드래그&드롭
  - [x] 파일 드래그&드롭 (desktop_drop)
  - [x] 드롭 영역 시각적 피드백
- [ ] 키보드 단축키 시스템 구현 #shortcuts !medium
  - [x] Shortcuts 위젯으로 단축키 등록
  - [x] 파일 작업 단축키 (Cmd+N/O/S/E)
  - [x] 편집 단축키 (Cmd+Z/A, Delete)
  - [x] 뷰 단축키 (줌, 그리드 토글)
  - [x] 툴 단축키 (V/R/G/A)
- [ ] 다중 소스 이미지 지원 #multiimage !high
  - [x] 여러 PNG 파일 동시 로드
  - [x] 소스 이미지별 탭 UI
  - [x] 소스별 독립적 슬라이싱
  - [x] 통합 아틀라스 패킹
  - [x] 파일 드래그&드롭으로 추가
- [ ] Undo/Redo 시스템 구현 #history !high
  - [x] EditorCommand 추상 클래스 설계
  - [x] CommandHistory 스택 관리 클래스
  - [x] 주요 편집 작업 Command 구현
  - [x] HistoryProvider로 상태 관리
  - [x] 메뉴/단축키 연동 (Cmd+Z, Cmd+Shift+Z)
- [ ] 애니메이션 시퀀스 편집기 구현 #animation !high
  - [x] AnimationSequence 모델 설계 (freezed)
  - [x] AnimationFrame 모델 설계 (spriteId, duration, flipX, flipY)
  - [x] 애니메이션 타임라인 위젯
  - [x] 프레임 순서 드래그&드롭 구현
  - [x] 프레임 타이밍 (duration) 편집 UI
  - [x] loop/pingPong 설정 토글
  - [x] flipX/flipY 프레임별 설정
  - [x] 애니메이션 실시간 프리뷰 재생
- [ ] 9-Slice Border 시스템 구현 #nineslice !high
  - [x] NineSliceBorder 모델 설계
  - [x] L/R/T/B 경계 입력 UI
  - [x] 캔버스에서 9-Slice 경계 드래그 핸들
  - [x] 9-Slice 리사이즈 프리뷰

## Done

