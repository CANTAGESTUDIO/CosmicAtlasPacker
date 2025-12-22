# MVP Tasks

> This file syncs bidirectionally with the Archon Kanban board.

---

## Backlog

## Worker1

## Worker2

## Worker3

## Review

## Done

- [x] 아틀라스 설정 옵션 구현 #settings !medium
  - [x] AtlasSettings 모델 생성 (freezed + json_serializable)
    <!-- Best Practice Tree
    - AtlasSettings Model
      - Properties
        - maxWidth, maxHeight (int, default: 2048)
        - padding (int, default: 2)
        - extrude (int, default: 1)
        - trimTransparent (bool, default: true)
        - powerOfTwo (bool, default: true)
      - Serialization
        - @freezed annotation
        - toJson/fromJson factory
      - Validation
        - 최소/최대 값 검증
        - 유효성 검사 메서드
    -->
  - [x] AtlasSettingsProvider 생성
    <!-- Best Practice Tree
    - Settings Provider
      - State
        - StateNotifier<AtlasSettings>
        - 기본값 초기화
      - Methods
        - updateMaxWidth/updateMaxHeight
        - updatePadding/updateExtrude
        - togglePowerOfTwo/toggleTrimTransparent
        - reset to defaults
      - Persistence
        - 프로젝트 저장/로드 연동
    -->
  - [x] 아틀라스 설정 다이얼로그 UI 구현
    <!-- Best Practice Tree
    - Settings Dialog
      - Layout
        - AlertDialog + Column
        - LabeledNumberInput 위젯 재사용
      - Inputs
        - maxWidth/maxHeight 숫자 입력
        - padding/extrude 슬라이더 또는 숫자 입력
        - powerOfTwo/trimTransparent 스위치
      - Actions
        - Apply/Cancel 버튼
        - Reset to Defaults 버튼
      - Validation
        - 실시간 입력 검증
        - 에러 메시지 표시
    -->
  - [x] 툴바에 설정 버튼 추가
    <!-- Best Practice Tree
    - Toolbar Integration
      - Button
        - Settings 아이콘 버튼
        - 툴팁 표시
      - Menu
        - Tools 메뉴에 Settings 항목 추가
        - 단축키 할당 (Cmd+,)
    -->
  - [x] PackingService에 설정 적용
    <!-- Best Practice Tree
    - Packing Integration
      - MaxRects Algorithm
        - maxWidth/maxHeight로 bin 크기 제한
        - padding 적용
      - Extrude
        - 스프라이트 엣지 복제
        - bleeding 방지
      - PowerOfTwo
        - 최종 크기 2의 제곱으로 조정
      - TrimTransparent
        - 투명 영역 제거 후 패킹
    -->

- [x] 프로젝트 저장/로드 구현 #project !high
  - [x] AtlasProject 모델 확장 (freezed + json_serializable)
  - [x] ProjectService 생성 (저장/로드 로직)
  - [x] .atlas 파일 저장 다이얼로그
  - [x] .atlas 파일 로드 다이얼로그
  - [x] 소스 이미지 상대 경로 저장/복원

- [x] 4패널 레이아웃 완성 #ui !medium
  - [x] multi_split_view로 패널 분할
  - [x] Source Panel 배치
  - [x] Atlas Preview Panel 배치
  - [x] Properties Panel 배치
  - [x] Sprite List Panel 배치

- [x] 스프라이트 목록 패널 구현 #ui !high
  - [x] 스프라이트 썸네일 위젯
  - [x] 스프라이트 리스트 (스크롤 가능)
  - [x] 다중 선택 지원 (Cmd/Ctrl + 클릭)
  - [x] 선택 시 Properties 패널 연동

- [x] 스프라이트 ID 관리 시스템 구현 #validation !high
  - [x] ID 편집 UI (텍스트 필드)
  - [x] ID 중복 검증 서비스
  - [x] 중복 ID 경고 UI

- [x] 투명도 기반 자동 슬라이싱 구현 #slicing !high
  - [x] Flood Fill (Connected Components) 알고리즘 구현
  - [x] 알파 채널 추출 및 임계값 기반 이진화
  - [x] 바운딩 박스 계산 및 최소 크기 필터링
  - [x] 자동 슬라이싱 설정 UI (임계값, 최소 크기 입력)

- [x] 피봇 시스템 구현 #pivot !high
  - [x] PivotPoint 모델 설계 (freezed)
  - [x] PivotPreset 열거형 (9개 프리셋)
  - [x] 3x3 피봇 선택 위젯 구현
  - [x] 커스텀 피봇 좌표 입력 UI
  - [x] 캔버스에서 피봇 핸들 드래그 구현

- [x] 속성 패널 구현 #ui !medium
  - [x] 선택된 스프라이트 정보 표시
  - [x] 위치/크기 수치 표시
  - [x] 피봇 설정 UI 통합
  - [x] 다중 선택 시 공통 속성 편집
