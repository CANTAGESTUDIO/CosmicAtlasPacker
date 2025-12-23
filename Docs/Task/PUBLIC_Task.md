---
created: 2025-12-23T15:10
updated: 2025-12-24T01:05
---
# PUBLIC Tasks

> 이 파일은 Archon 칸반보드와 양방향 동기화됩니다.
> Available Tags: #feature, #bugfix, #refactor, #test, #docs, #ui, #api, #db, #config, #chore
> Priority: !high, !medium, !low
> Deadline: Deadline(yyyy:MM:dd)
> Subtask: 2-space indent

## Backlog

## Review
- [ ] 텍스처 패커 모드 / 애니메이션 모드 전환 기능 구현 #feature !high ✓진행완료
  - [x] EditorMode enum 생성 및 editorModeProvider 추가
  - [x] EditorToolbar에 모드 전환 토글 버튼(세그먼티드 버튼) 추가
  - [x] EditorScreen에서 _buildMainContent() 메서드 모드별 분기 구현
  - [x] _buildTexturePackerLayout() 메서드로 기존 레이아웃 분리
  - [x] _buildAnimationLayout() 메서드로 애니메이션 모드 레이아웃 구현 (플레이스홀더)
  - [ ] AnimationSettingsPanel 독립 컴포넌트로 분리 생성 (향후 구현)
  - [ ] 모드 전환 시 상태 유지 및 드래그 앤 드롭 지원 구현 (향후 구현)
- [ ] 텍스처 패킹 세팅 다이얼로그 구현 #feature #ui #settings !high ✓진행완료
  - [x] TextureCompressionSettings 모델 생성 (freezed)
    <!-- Best Practice Tree -->
    - Data Model Design
      - freezed 사용한 불변 모델
      - copyWith, equality 자동 생성
      - JSON 직렬화 지원
    - Model Fields
      - Android/iOS 별 압축 포맷
      - ASTC 블록 크기 옵션
      - 게임 타입 프리셋
      - 온보딩 완료 상태
    - Validation
      - 필수 필드 검증
      - 포맷 호환성 체크
      - 기본값 설정
    - [ ] lib/data/models/texture_compression_settings.dart 파일 생성
      <!-- Best Practice Tree -->
      - File Organization
        - models 디렉토리 구조 준수
        - 파일명 snake_case 사용
        - 패키지 레벨 import 가능성 고려
      - Documentation
        - 클래스 레벨 주석 추가
        - 각 필드 용도 설명
        - 사용 예시 포함
    - [ ] TextureCompressionFormat enum 정의
      <!-- Best Practice Tree -->
      - Enum Design
        - 명확한 포맷 이름 (ETC2_4BIT, ETC2_8BIT, ASTC_4X4 등)
        - 확장 가능한 구조 고려
        - JSON 직렬화 지원 (JsonValue enum)
      - Platform Separation
        - Android 지원 포맷 그룹
        - iOS 지원 포맷 그룹
        - 공통 포맷 식별
    - [ ] ASTCBlockSize enum 정의
      <!-- Best Practice Tree -->
      - Block Size Options
        - 4x4, 6x6, 8x8, 10x10, 12x12 정의
        - 텍스트 표현 (toDisplayString) 메서드
        - 압축률 메타데이터 연동
      - Quality Metrics
        - 블록 크기별 품질 수준
        - 압축 효율성 비교
        - 호환성 플래그
    - [ ] GameType enum 정의
      <!-- Best Practice Tree -->
      - Game Categories
        - casual2D, action2D, rpg3D, highEnd3D
        - 한국어 표시명 메서드
        - 각 타입 설명 툴팁 텍스트
      - Preset Association
        - 각 게임 타입별 기본 설정
        - 프리셋 적용 메서드
        - 커스텀 옵션 플래그
    - [ ] TextureCompressionSettings 클래스 필드 정의
      <!-- Best Practice Tree -->
      - Required Fields
        - androidFormat: TextureCompressionFormat
        - iosFormat: TextureCompressionFormat
        - astcBlockSize: ASTCBlockSize
        - gameType: GameType
        - exportType: ExportType (sprite/font)
      - Optional Fields
        - fallbackFormat: TextureCompressionFormat?
        - customPreset: bool
        - onboardingCompleted: bool
    - [ ] freezed 어노테이션 및 copyWith 메서드 추가
      <!-- Best Practice Tree -->
      - Freezed Setup
        - @freezed 어노테이션 추가
        - @JsonSerializable() 어노테이션
        - part 선언 (part '...')
      - Immutable Pattern
        - final 필드 사용
        - private 생성자
        - factory 생성자 제공
    - [ ] JSON 직렬화 코드 생성 및 검증
      <!-- Best Practice Tree -->
      - Code Generation
        - flutter pub run build_runner build 실행
        - 생성 코드 검토
        - .g.dart 파일 확인
      - Serialization Testing
        - fromJson/toJson 단위 테스트
        - null 처리 검증
        - enum 직렬화 확인
    - [ ] 기본 설정 팩토리 메서드 생성
      <!-- Best Practice Tree -->
      - Default Presets
        - factory default() 메서드
        - 2D 캐주얼 기본값
        - 게임 타입별 프리셋 팩토리
      - Validation Methods
        - validate() 메서드
        - 포맷 호환성 체크
        - 필수 필드 검증 로직
  - [ ] TexturePackingSettingsProvider 생성
    <!-- Best Practice Tree -->
    - Provider Architecture
      - StateNotifier 패턴 사용
      - 로컬 스토리지 연동 (UserDefaults)
      - 상태 변경 알림
    - State Management
      - 현재 설정 상태 저장
      - 설정 업데이트 메서드
      - 프리셋 적용 로직
    - Provider Scope
      - 앱 레벨 스코프 설정
      - 다른 Provider와 연동
      - 의존성 주입 패턴
    - [ ] lib/providers/texture_packing_settings_provider.dart 파일 생성
      <!-- Best Practice Tree -->
      - Provider Pattern
        - StateNotifier<T> 상속
        - TextureCompressionSettings 상태 관리
        - 이벤트 기반 업데이트
      - Architecture
        - 단일 책임 원칙 준수
        - 불변 상태 업데이트
        - 재사용 가능한 로직 분리
    - [ ] LocalStorageService 생성 및 연동
      <!-- Best Practice Tree -->
      - Storage Implementation
        - shared_preferences 패키지 사용
        - JSON 직렬화/역직렬화
        - 저장소 키 상수 정의
      - Persistence Layer
        - loadSettings() 메서드
        - saveSettings() 메서드
        - 기본값 로드 fallback
    - [ ] TexturePackingSettingsState 및 Events 정의
      <!-- Best Practice Tree -->
      - State Management
        - TextureCompressionSettings 초기 상태
        - 로딩/성공/에러 상태
        - 상태 변화 이력 추적
      - Event Types
        - UpdateFormat
        - UpdateGameType
        - UpdateOnboardingProgress
        - ResetToPreset
    - [ ] 프리셋 적용 로직 구현
      <!-- Best Practice Tree -->
      - Preset System
        - applyGameTypePreset() 메서드
        - 각 게임 타입별 설정 맵
        - 커스텀 변경 감지
      - Validation
        - 프리셋 적용 전 호환성 체크
        - 경고 메시지 생성
        - 롤백 기능 지원
    - [ ] Provider 앱 레벨 등록
      <!-- Best Practice Tree -->
      - Provider Registration
        - main.dart에 ProviderScope 추가
        - ChangeNotifierProvider 등록
        - ProviderContainer 구성
      - Dependency Injection
        - 다른 Provider와 연동 필요 시
        - ref/watch 패턴 사용
        - 테스트 용이성 고려
  - [ ] OnboardingStepper 위젯 구현 (6단계 온보딩)
    <!-- Best Practice Tree -->
    - Stepper UI Component
      - 단계별 진행 표시 (Step 1~6)
      - 이전/다음 버튼 네비게이션
      - Skip 버튼 및 진행률 표시
    - Onboarding Steps
      - Step 1: 타겟 기기 정의 (Android API, iOS, RAM)
      - Step 2: 그래픽 품질 수준 (게임 장르, 텍스처 상세도)
      - Step 3: 메모리 예산 설정 (전체 한도, 텍스처 할당량)
      - Step 4: 압축 전략 (기본 포맷, 폴백, 오버라이드)
      - Step 5: 빌드 시간 및 CI/CD 영향
      - Step 6: QA 테스트 계획 (검증 기기, 프로파일링)
    - State Persistence
      - 온보딩 진행 상태 저장
      - 중단 시점부터 재개 지원
      - 완료 시 재시작 옵션
    - [ ] lib/widgets/dialogs/texture_settings/onboarding_stepper.dart 파일 생성
      <!-- Best Practice Tree -->
      - Widget Structure
        - StatefulWidget 사용
        - 단계별 컨텐츠 동적 렌더링
        - 상태 관리 (currentStep)
      - UI Components
        - 단계 인디케이터 (dots/numbers)
        - 네비게이션 버튼 컨테이너
        - Skip 버튼 (마지막 단계 제외)
    - [ ] Step 1: 타겟 기기 정의 UI 구현
      <!-- Best Practice Tree -->
      - Target Device Form
        - Android API Level 드롭다운 (21, 24, 28, 30+)
        - iOS 버전 드롭다운 (iOS 10, 12, 13+)
        - RAM 용량 슬라이더 (1GB ~ 6GB)
      - Input Validation
        - 필수 입력 항목 표시
        - 호환성 체크 메시지
        - 다음 단계 활성화 조건
    - [ ] Step 2: 그래픽 품질 수준 UI 구현
      <!-- Best Practice Tree -->
      - Quality Settings
        - 게임 장르 셀렉트 (캐주얼, 액션, RPG, 하이엔드)
        - 텍스처 상세도 슬라이더 (Low ~ Ultra)
        - 스크린샷/예시 표시
      - Auto-suggestion
        - 선택한 게임 장르별 권장 설정
        - 다음 단계에 자동 적용
        - 커스텀 옵션 허용
    - [ ] Step 3: 메모리 예산 설정 UI 구현
      <!-- Best Practice Tree -->
      - Memory Budget Form
        - 전체 메모리 한도 슬라이더 (50MB ~ 500MB)
        - 텍스처 할당 비율 (10% ~ 80%)
        - 실시간 계산 표시
      - Visual Feedback
        - 프로그레스 바 시각화
        - 권장 값 가이드라인 표시
        - 초과 시 경고 메시지
    - [ ] Step 4: 압축 전략 UI 구현
      <!-- Best Practice Tree -->
      - Compression Strategy
        - 기본 포맷 선택 (ETC2/ASTC)
        - 폴백 포맷 선택
        - ASTC 블록 크기 선택
      - Override Options
        - 플랫폼별 오버라이드 체크박스
        - 커스텀 설정 저장
        - 프리셋과 차이점 표시
    - [ ] Step 5: 빌드 시간 및 CI/CD 영향 UI 구현
      <!-- Best Practice Tree -->
      - Build Impact Analysis
        - 선택한 포맷별 빌드 시간 예상
        - 압축 시간 대비 품질 트레이드오프
        - CI/CD 파이프라인 영향 표시
      - Recommendations
        - 개발용 추천 설정
        - 프로덕션용 추천 설정
        - A/B 테스트 옵션
    - [ ] Step 6: QA 테스트 계획 UI 구현
      <!-- Best Practice Tree -->
      - QA Planning Form
        - 검증 기기 목록 체크박스
        - 프로파일링 도구 연동 옵션
        - 테스트 체크리스트 생성
      - Export Options
        - 설정 JSON 내보내기
        - 팀원과 공유 버튼
        - 나중에 설정 수정 옵션
    - [ ] 온보딩 진행 상태 저장 및 복구 로직
      <!-- Best Practice Tree -->
      - State Persistence
        - 각 단계별 저장 (onboardingStep 저장)
        - 사용자 입력 로컬 스토리지 저장
        - 중단 시점 복구
      - Resume Logic
        - 마지막 완료 단계부터 재개
        - 이전 입력값 복원
        - 다시 시작 옵션 제공
  - [ ] ExportTypeToggle 위젯 구현 (스프라이트/폰트)
    <!-- Best Practice Tree -->
    - Toggle UI Component
      - 세그먼티드 버튼 패턴
      - 스프라이트 모드 / 폰트 모드
      - 아이콘 + 한국어 라벨
    - Mode Switching Logic
      - Provider 상태 동기화
      - 모드별 UI 전환 애니메이션
      - 설정 모드별 독립 저장
    - Flame Integration
      - 스프라이트 모드: 기존 아틀라스 JSON 호환
      - 폰트 모드: SpriteFont export (PNG + FNT)
      - 9-slice 보더 정보 포함
    - [ ] lib/widgets/dialogs/texture_settings/export_type_toggle.dart 파일 생성
      <!-- Best Practice Tree -->
      - Widget Design
        - SegmentedButton Flutter 위젯 사용
        - 아이콘 (Icons.layers / Icons.font_download)
        - 한국어 라벨 (스프라이트 / 폰트)
      - Styling
        - 활성/비활성 상태 색상
        - 호버 효과 적용
        - DesignSystem 토큰 사용
    - [ ] 모드 전환 로직 구현
      <!-- Best Practice Tree -->
      - State Sync
        - Provider exportType 업데이트
        - Consumer 패턴 사용
        - 다른 위젯과 상태 동기화
      - Animation
        - AnimatedSwitched/AnimatedCrossFade 사용
        - 부드러운 전환 효과
        - 크기 변화 애니메이션
    - [ ] 스프라이트 모드 UI 레이아웃 구현
      <!-- Best Practice Tree -->
      - Sprite Mode Layout
        - 기존 아틀라스 설정 컨트롤
        - JSON 포맷 옵션
        - 9-slice 보더 정보 편집
      - Flame Integration
        - SpriteComponent 호환 설정
        - 이미지 파일 포맷 (PNG/WebP)
        - 오프셋/앵커 포인트 설정
    - [ ] 폰트 모드 UI 레이아웃 구현
      <!-- Best Practice Tree -->
      - Font Mode Layout
        - 폰트 레이아웃 최적화 설정
        - 문자별 패딩 컨트롤
        - Kerning 정보 옵션
      - Flame SpriteFont
        - FNT 파일 형식 설정
        - PNG 텍스처 옵션
        - 글자 간격/줄 간격 설정
  - [ ] GameTypeSection 위젯 구현 (게임 타입별 전략)
    <!-- Best Practice Tree -->
    - Game Type Presets
      - 2D 캐주얼: ETC2 8bit 기본 + ASTC 6x6
      - 2D 액션: ASTC 6x6 기본 + ETC2 8bit 폴백
      - 3D RPG: ASTC 6x6 메인 + ETC2 8bit 폴백
      - 하이엔드 3D: ASTC 4x4~6x6 전체
    - Selection UI
      - 게임 타입 셀렉트 박스
      - 각 프리셋 설명 툴팁
      - 커스텀 설정 옵션
    - Preset Application
      - 프리셋 선택 시 자동 설정 적용
      - 이후 변경사항 추적
      - 기본값 복원 기능
    - [ ] lib/widgets/dialogs/texture_settings/game_type_section.dart 파일 생성
      <!-- Best Practice Tree -->
      - Section Structure
        - ExpansionTile 또는 Card 위젯 사용
        - 제목: "게임 타입 설정"
        - 프리셋 목록 렌더링
      - UI Components
        - DropdownButton 게임 타입 선택
        - 현재 설정 미리보기 카드
        - 커스텀 설정 토글
    - [ ] 게임 타입 프리셋 데이터 구조 정의
      <!-- Best Practice Tree -->
      - Preset Data Model
        - GameTypePreset 클래스 정의
        - 각 프리셋별 압축 설정
        - 메모리 예산 기본값
      - Preset Registry
        - Map<GameType, GameTypePreset> 형태
        - 프리셋 로드/저장 메서드
        - 커스텀 프리셋 지원
    - [ ] 프리셋 적용 로직 구현
      <!-- Best Practice Tree -->
      - Application Logic
        - applyPreset(GameType) 메서드
        - Provider 상태 업데이트
        - 변경사항 표시
      - Conflict Resolution
        - 커스텀 설정과 프리셋 충돌 시 처리
        - 덮어쓰기/병합 옵션
        - 사용자 확인 다이얼로그
    - [ ] 커스텀 설정 모드 UI 구현
      <!-- Best Practice Tree -->
      - Custom Mode UI
        - 모든 옵션 편집 가능 상태
        - 별도 저장 버튼
        - 프리셋과 비교 표시
      - Validation
        - 커스텀 설정 유효성 검사
        - 호환성 경고
        - 저장 전 확인
  - [ ] CompressionFormatSection 위젯 구현 (플랫폼별 포맷)
    <!-- Best Practice Tree -->
    - Platform Format UI
      - Android 포맷: ETC2 4bit, ETC2 8bit, ASTC 4x4/6x6/8x8
      - iOS 포맷: ASTC 4x4/6x6/8x8
      - 플랫폼별 섹션 분리
    - ASTC Block Size
      - 4x4, 6x6, 8x8, 10x10, 12x12 옵션
      - 블록 크기별 압축률/품질 표시
      - 호환성 경고 메시지
    - Fallback Strategy
      - 기본 포맷 설정
      - 폴백 포맷 선택
      - 오버라이드 옵션
    - [ ] lib/widgets/dialogs/texture_settings/compression_format_section.dart 파일 생성
      <!-- Best Practice Tree -->
      - Section Structure
        - TabBar로 플랫폼 분리 (Android/iOS)
        - 각 플랫폼별 포맷 옵션 렌더링
        - 공통 설정 섹션
      - UI Components
        - DropdownButton 포맷 선택
        - RadioGroup ASTC 블록 크기
        - Toggle 폴백 활성화
    - [ ] Android 포맷 옵션 UI 구현
      <!-- Best Practice Tree -->
      - Format Options
        - ETC2 4bit/8bit 라디오 버튼
        - ASTC 4x4/6x6/8x8 라디오 버튼
        - 각 포맷 설명 툴팁
      - Compatibility Info
        - 최소 API 레벨 표시
        - 지원 기기 비율
        - 품질/크기 비교 차트
    - [ ] iOS 포맷 옵션 UI 구현
      <!-- Best Practice Tree -->
      - Format Options
        - ASTC 4x4/6x6/8x8 라디오 버튼
        - 각 포맷 설명 툴팁
        - 품질/크기 비교
      - iOS Specifics
        - iOS 10+ 호환성
        - Apple Silicon 최적화
        - Metal 텍스처 포맷
    - [ ] 폴백 전략 UI 구현
      <!-- Best Practice Tree -->
      - Fallback Options
        - 폴백 포맷 드롭다운
        - 조건별 폴백 설정 (RAM, API 레벨)
        - 폴백 시 품질 저하 경고
      - Override Controls
        - 플랫폼별 오버라이드 체크박스
        - 세부 폴백 규칙 설정
        - 테스트 시뮬레이션 버튼
  - [ ] MemoryInfoPanel 위젯 구현
    <!-- Best Practice Tree -->
    - Memory Info Display
      - 전체 메모리 예산 표시
      - 텍스처 할당량 계산
      - 현재 사용량/한도 표시
    - Build Size Estimation
      - 예상 빌드 크기 계산
      - 포맷별 크기 차이 표시
      - 압축률 정보 표시
    - Visual Feedback
      - 프로그레스 바로 사용량 시각화
      - 초과 시 경고 색상
      - 툴팁으로 상세 정보 제공
    - [ ] lib/widgets/dialogs/texture_settings/memory_info_panel.dart 파일 생성
      <!-- Best Practice Tree -->
      - Panel Structure
        - Grid 또는 Column 레이아웃
        - 메모리/빌드 섹션 분리
        - 색상 코딩된 인디케이터
      - UI Components
        - LinearProgressIndicator 사용량
        - Text 표시 (MB 단위)
        - Icon 경고 표시
    - [ ] 메모리 계산 로직 구현
      <!-- Best Practice Tree -->
      - Calculation Engine
        - 총 텍스처 크기 계산
        - 포맷별 압축률 적용
        - 실제 VRAM 사용량 추정
      - Display Logic
        - MB/GB 단위 변환
        - 소수점 표시 설정
        - 퍼센트 계산
    - [ ] 빌드 크기 추정 로직 구현
      <!-- Best Practice Tree -->
      - Size Estimation
        - 각 포맷별 예상 크기
        - 압축 전후 비교
        - 빌드 시간 추정
      - Comparison View
        - 포맷별 크기 비교 바
        - 압축률 퍼센트 표시
        - 추천 포맷 하이라이트
    - [ ] 시각적 피드백 구현
      <!-- Best Practice Tree -->
      - Progress Indicators
        - 사용량에 따른 색상 변화 (녹색-노란색-빨간색)
        - 애니메이션 효과
        - 툴팁에 상세 정보
      - Warning System
        - 한도 초과 경고 메시지
        - 아이콘 표시
        - 해결책 제안 툴팁
  - [ ] TexturePackingSettingsDialog 메인 다이얼로그 조립
    <!-- Best Practice Tree -->
    - Dialog Structure
      - OnboardingStepper (최초 실행 시)
      - ExportTypeToggle (스프라이트/폰트 모드)
      - GameTypeSection (게임 타입 프리셋)
      - CompressionFormatSection (플랫폼별 포맷)
      - MemoryInfoPanel (메모리/빌드 정보)
    - Dialog Layout
      - DraggableDialog 패턴 사용
      - 탭별 섹션 구성
      - Save/Cancel 버튼
    - State Integration
      - TexturePackingSettingsProvider 연동
      - 설정 변경 시 실시간 프리뷰
      - 저장 로직 구현
    - [ ] lib/widgets/dialogs/texture_settings/texture_packing_settings_dialog.dart 파일 생성
      <!-- Best Practice Tree -->
      - Dialog Base
        - DraggableDialog 확장
        - 제목: "텍스처 패킹 설정"
        - 크기: 800x600 픽셀
      - Layout Structure
        - 왼쪽: 탭 네비게이션
        - 오른쪽: 콘텐츠 영역
        - 하단: Save/Cancel 버튼
    - [ ] 온보딩 조건부 렌더링 구현
      <!-- Best Practice Tree -->
      - Conditional Logic
        - onboardingCompleted 체크
        - false: OnboardingStepper 표시
        - true: 설정 탭 표시
      - Transition
        - 온보딩 완료 후 부드러운 전환
        - 다이얼로그 크기 조정
        - 탭 활성화
    - [ ] 탭 네비게이션 구현
      <!-- Best Practice Tree -->
      - Tab Structure
        - [일반] ExportTypeToggle + GameTypeSection
        - [압축] CompressionFormatSection
        - [정보] MemoryInfoPanel
        - [고급] 추가 옵션
      - Navigation Logic
        - TabController 사용
        - 탭 아이콘 + 라벨
        - 저장되지 않은 변경사항 경고
    - [ ] Save/Cancel 버튼 로직 구현
      <!-- Best Practice Tree -->
      - Button Actions
        - Save: Provider 상태 저장 + 다이얼로그 닫기
        - Cancel: 변경사항 없이 닫기
        - Apply: 저장 후 열린 상태 유지
      - Validation
        - 저장 전 유효성 검사
        - 필수 설정 확인
        - 경고 다이얼로그
    - [ ] Provider 연동 및 실시간 프리뷰
      <!-- Best Practice Tree -->
      - Provider Integration
        - Consumer 패턴 사용
        - 설정 변경 시 자동 업데이트
        - MemoryInfoPanel 실시간 계산
      - Preview System
        - 설정 변경 즉시 반영
        - 미리보기 영역 업데이트
        - 변경사항 강조 표시
  - [ ] ExportDialog 통합 및 메뉴 연동
    <!-- Best Practice Tree -->
    - Dialog Integration
      - ExportDialog 앞단에서 호출
      - 설정 데이터 전달
      - 결과 반환 처리
    - Menu Connection
      - 메뉴 항목 추가 (Texture Settings)
      - 단축키 연동
      - 아이콘 설정
    - Workflow Integration
      - 내보내기 전 설정 확인
      - 설정 변경 시 재내보내기 지원
      - 설정 저장/로드 로직
    - [ ] ExportDialog에 텍스처 설정 버튼 추가
      <!-- Best Practice Tree -->
      - Button Placement
        - ExportDialog 하단 툴바
        - "텍스처 설정" 버튼
        - 아이콘: Icons.tune
      - Action Handler
        - 버튼 클릭 시 설정 다이얼로그 표시
        - 현재 아틀라스 정보 전달
        - 결과 수신 및 적용
    - [ ] 메뉴 항목 추가 및 라우팅 구현
      <!-- Best Practice Tree -->
      - Menu Structure
        - File → Texture Settings
        - 단축키: Cmd+Shift+T
        - 아이콘: Icons.tune
      - Navigation Logic
        - 메뉴 클릭 시 다이얼로그 표시
        - 현재 컨텍스트 전달
        - go_router 사용 고려
    - [ ] 내보내기 워크플로우 통합
      <!-- Best Practice Tree -->
      - Export Flow
        - ExportDialog 열리기 전 설정 확인
        - 텍스처 설정 → ExportDialog 순서
        - 설정 적용 후 내보내기
      - State Management
        - 설정 변경 플래그
        - 재내보내기 필요 여부 확인
        - 자동 저장/다시 묻기
    - [ ] 설정 저장/로드 로직 구현
      <!-- Best Practice Tree -->
      - Persistence
        - 프로젝트별 설정 저장 (.json 파일)
        - 로드 시 기본값 병합
        - 설정 버전 관리
      - Export/Import
        - 설정 JSON 내보내기
        - 설정 JSON 가져오기
        - 팀원과 공유 기능

## Worker1

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

