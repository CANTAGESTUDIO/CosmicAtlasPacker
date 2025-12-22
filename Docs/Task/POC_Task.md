# POC Tasks

> This file syncs bidirectionally with the Archon Kanban board.

---

## Backlog

## Worker1

## Worker2

## Worker3

## Review

## Done

- [x] BatchRenderer 호환성 테스트 #test !high
  - [x] 출력된 JSON이 BatchRenderer에서 파싱 가능한지 검증
    <!-- Best Practice Tree -->
    - JSON Parsing Test
      - Validation
        - JSON 구문 오류 검사
        - 필수 필드 존재 확인
      - Type Check
        - 숫자 필드 타입 검증
        - 문자열 필드 검증
      - Edge Cases
        - 빈 스프라이트 목록
        - 특수 문자 ID
  - [x] 실제 게임 엔진(Unity/Godot)에서 텍스처 로드 테스트
    <!-- Best Practice Tree -->
    - Engine Integration Test
      - Unity
        - SpriteAtlas import 테스트
        - 스프라이트 렌더링 확인
      - Godot (선택)
        - AtlasTexture 로드
        - 좌표 정확도 검증
      - Documentation
        - 테스트 결과 기록
        - 호환성 이슈 문서화
  - [x] 테스트 결과 문서화
    <!-- Best Practice Tree -->
    - Test Documentation
      - Format
        - 테스트 케이스 목록
        - 결과 (Pass/Fail)
      - Issues
        - 발견된 문제점
        - 해결 방안
      - Deliverable
        - Docs/Test 폴더에 저장
        - 버전별 결과 기록

- [x] PNG 내보내기 구현 #export !high
  - [x] image 패키지로 아틀라스 이미지 생성
    <!-- Best Practice Tree -->
    - Atlas Image Generation
      - Creation
        - 계산된 크기로 Image 생성
        - RGBA 포맷
      - Compositing
        - 각 스프라이트 복사
        - 투명 배경 유지
      - Quality
        - 원본 픽셀 정확도 유지
        - 안티앨리어싱 없음
  - [x] PNG 포맷으로 인코딩 및 파일 저장
    <!-- Best Practice Tree -->
    - PNG Export
      - Encoding
        - encodePng 함수 활용
        - 압축 레벨 설정
      - File I/O
        - 저장 경로 선택 다이얼로그
        - 비동기 파일 쓰기
      - Error Handling
        - 디스크 공간 확인
        - 쓰기 권한 검증
  - [x] 저장 경로 선택 다이얼로그
    <!-- Best Practice Tree -->
    - Save Dialog
      - Configuration
        - FilePicker.platform.saveFile
        - 기본 파일명 제안
      - Path Handling
        - 확장자 자동 추가
        - 경로 유효성 검증
      - UX
        - 저장 성공/실패 알림
        - 진행률 표시

- [x] 아틀라스 프리뷰 패널 구현 #preview !medium
  - [x] 패킹 결과를 실시간으로 렌더링하는 위젯
    <!-- Best Practice Tree -->
    - Realtime Preview
      - Rendering
        - CustomPainter 활용
        - 스프라이트 영역 시각화
      - Performance
        - 디바운싱 (입력 변경 시)
        - 캐시된 이미지 재사용
      - Layout
        - 아틀라스 크기에 맞는 스케일
        - 줌/팬 지원
  - [x] 스프라이트별 바운딩 박스 및 ID 표시
    <!-- Best Practice Tree -->
    - Sprite Visualization
      - Bounding Box
        - 스프라이트 영역 테두리
        - 색상 구분 (선택 상태)
      - ID Label
        - 축소 시 자동 숨김
        - 충돌 방지 위치 조정
      - Interaction
        - 호버 시 상세 정보
        - 클릭 시 선택
  - [x] 아틀라스 크기 자동 계산 및 표시
    <!-- Best Practice Tree -->
    - Atlas Size
      - Calculation
        - 패킹 결과 기반 최소 크기
        - Power of Two 옵션
      - Display
        - 크기 텍스트 표시
        - 사용률 퍼센트
      - Options
        - 최대 크기 제한
        - 패딩 설정 적용

- [x] JSON 메타데이터 내보내기 구현 #export !high
  - [x] PRD 섹션 7.1 형식의 JSON 스키마 구현
    <!-- Best Practice Tree -->
    - JSON Schema
      - Structure
        - frames 객체 (스프라이트별)
        - meta 객체 (아틀라스 정보)
      - Fields
        - frame: x, y, w, h
        - sourceSize, spriteSourceSize
      - Validation
        - 스키마 규격 준수
        - 필수 필드 검증
  - [x] 스프라이트별 frame, sourceSize 데이터 생성
    <!-- Best Practice Tree -->
    - Sprite Data
      - frame
        - 아틀라스 내 위치 (x, y, w, h)
        - 픽셀 단위 정수
      - sourceSize
        - 원본 스프라이트 크기
        - trimmed 정보 (미구현)
      - pivot (기본값)
        - 기본 center (0.5, 0.5)
        - MVP에서 확장
  - [x] meta 객체 생성 (image, size, format)
    <!-- Best Practice Tree -->
    - Meta Object
      - Required Fields
        - image: 아틀라스 파일명
        - size: w, h
        - format: "RGBA8888"
      - Optional Fields
        - app, version 정보
        - scale: 1
      - Encoding
        - UTF-8 JSON
        - pretty print 옵션
  - [x] JSON 파일 저장 (PNG와 동일 경로)
    <!-- Best Practice Tree -->
    - JSON Export
      - Path
        - PNG와 동일 디렉토리
        - 동일 파일명 + .json 확장자
      - Encoding
        - jsonEncode 활용
        - indent 포맷팅
      - Synchronization
        - PNG 저장 후 JSON 저장
        - 원자적 저장 고려

- [x] 그리드 슬라이싱 구현 #slicing !medium
  - [x] Cell Size 기반 자동 분할 로직 구현
    <!-- Best Practice Tree -->
    - Cell Size Slicing
      - Input
        - 너비/높이 픽셀 입력
        - 최소/최대 값 검증
      - Algorithm
        - 이미지 크기 ÷ 셀 크기
        - 나머지 영역 처리 정책
      - Output
        - 균일한 크기의 사각형 배열
        - 자동 ID 부여
  - [x] Cell Count 기반 자동 분할 로직 구현
    <!-- Best Practice Tree -->
    - Cell Count Slicing
      - Input
        - 행/열 개수 입력
        - 정수 검증
      - Algorithm
        - 이미지 크기 ÷ 셀 개수
        - 픽셀 단위 반올림 처리
      - Output
        - 균일한 크기의 사각형 배열
        - row_col 형식 ID 부여
  - [x] 그리드 슬라이싱 설정 UI (간단한 다이얼로그)
    <!-- Best Practice Tree -->
    - Grid Dialog UI
      - Layout
        - 텍스트 필드 (Cell Size/Count)
        - 라디오 버튼 (모드 선택)
      - Validation
        - 실시간 입력 검증
        - 에러 메시지 표시
      - Preview
        - 예상 결과 미리보기
        - Apply/Cancel 버튼

- [x] 빈 패킹 알고리즘 구현 #packing !high
  - [x] MaxRects 데이터 구조 설계 (빈 사각형 리스트)
    <!-- Best Practice Tree -->
    - MaxRects Data Structure
      - Model
        - Rectangle (x, y, width, height)
        - FreeRect 리스트
      - Operations
        - 삽입, 분할, 병합
        - 효율적인 탐색
      - Memory
        - 불필요한 사각형 정리
        - 최적화된 자료구조
  - [x] Best Short Side Fit 휴리스틱 구현
    <!-- Best Practice Tree -->
    - BSSF Heuristic
      - Algorithm
        - 남는 짧은 변 최소화
        - 모든 빈 사각형 탐색
      - Scoring
        - shortSide = min(freeW - spriteW, freeH - spriteH)
        - 최소 점수 사각형 선택
      - Edge Cases
        - 동점 시 처리 정책
        - 회전 옵션 (미구현)
  - [x] Guillotine Split으로 빈 영역 분할
    <!-- Best Practice Tree -->
    - Guillotine Split
      - Split Types
        - Horizontal split (위/아래)
        - Vertical split (좌/우)
      - Optimization
        - 더 큰 영역 남기는 방향 선택
        - Min Area split rule
      - Merge
        - 인접한 빈 영역 병합
        - 조각화 방지
  - [x] 스프라이트 면적 기준 내림차순 정렬 후 패킹
    <!-- Best Practice Tree -->
    - Sort and Pack
      - Sorting
        - 면적 (w × h) 내림차순
        - 안정 정렬 유지
      - Packing Loop
        - 큰 스프라이트 먼저 배치
        - 배치 실패 시 처리
      - Result
        - 최종 위치 좌표 저장
        - 패킹 효율 계산

- [x] 수동 슬라이싱 구현 #slicing !high
  - [x] GestureDetector로 마우스 드래그 영역 선택 구현
    <!-- Best Practice Tree -->
    - Mouse Drag Selection
      - Gesture
        - onPanStart/Update/End 활용
        - 로컬 좌표 → 이미지 좌표 변환
      - Visual Feedback
        - 실시간 선택 영역 표시
        - 점선 또는 반투명 사각형
      - Validation
        - 최소 선택 크기 검증
        - 이미지 경계 내 제한
  - [x] 선택된 사각형 영역을 스프라이트로 등록
    <!-- Best Practice Tree -->
    - Sprite Registration
      - Data
        - 고유 ID 자동 생성 (sprite_0, sprite_1)
        - sourceRect 정확한 좌표 저장
      - Validation
        - 중복 영역 경고
        - 빈 영역 필터링
      - State
        - Provider로 스프라이트 목록 관리
        - 불변 상태 패턴
  - [x] 선택 영역 시각적 피드백 (오버레이 표시)
    <!-- Best Practice Tree -->
    - Selection Overlay
      - Styling
        - 선택된 영역 하이라이트
        - 드래그 중 영역 표시
      - Layering
        - 이미지 위 오버레이 레이어
        - Z-index 관리
      - Interaction
        - 호버 상태 표시
        - 선택/해제 시각적 구분

- [x] 소스 캔버스 위젯 구현 #canvas !high
  - [x] InteractiveViewer를 활용한 줌/팬 기능 구현
    <!-- Best Practice Tree -->
    - Interactive Canvas
      - Zoom
        - minScale/maxScale 적절히 설정
        - 휠 줌 감도 조절
        - 줌 중심점 유지
      - Pan
        - boundaryMargin 설정
        - constrained 경계 처리
      - Performance
        - clipBehavior 최적화
        - 불필요한 렌더링 방지
  - [x] CustomPainter로 이미지 렌더링 (TransformationController 연동)
    <!-- Best Practice Tree -->
    - Custom Painter
      - Rendering
        - shouldRepaint 최적화
        - Canvas transform 적용
      - Layering
        - 이미지 레이어
        - 오버레이 레이어 분리
      - Performance
        - isComplex, willChange 힌트
        - 필요 영역만 페인트
  - [x] 그리드 오버레이 표시 (토글 가능)
    <!-- Best Practice Tree -->
    - Grid Overlay
      - Rendering
        - 뷰포트 영역만 렌더링
        - 줌 레벨에 따른 간격 조정
      - Styling
        - 반투명 색상
        - 눈에 띄지만 방해되지 않는 스타일
      - Toggle
        - 상태 관리로 토글
        - 키보드 단축키 연동

- [x] 에디터 메인 화면 레이아웃 구현 #ui !medium
  - [x] 2패널 레이아웃 (Source Panel, Atlas Preview Panel)
    <!-- Best Practice Tree -->
    - Two Panel Layout
      - Structure
        - Row/Column 기반 분할
        - 비율 기반 크기 조절
      - Responsiveness
        - 윈도우 리사이즈 대응
        - 최소 크기 제한
      - Divider
        - 드래그로 크기 조절
        - 더블클릭 리셋
  - [x] 기본 메뉴바 (File 메뉴 - Open, Export)
    <!-- Best Practice Tree -->
    - Menu Bar
      - Platform
        - PlatformMenuBar 사용
        - macOS 네이티브 메뉴
      - Items
        - File > Open Image
        - File > Export Atlas
      - Shortcuts
        - Cmd+O, Cmd+E
        - 플랫폼별 분기
  - [x] 간단한 툴바 (슬라이싱 모드 선택)
    <!-- Best Practice Tree -->
    - Toolbar
      - Layout
        - 가로 버튼 배열
        - 아이콘 + 텍스트
      - Mode Selection
        - Select, Rect Slice, Grid Slice
        - 라디오 버튼 스타일
      - State
        - Provider로 현재 모드 관리
        - 시각적 선택 상태

- [x] 이미지 로드 기능 구현 #image !high
  - [x] file_picker를 통한 PNG 파일 선택 다이얼로그 구현
    <!-- Best Practice Tree -->
    - File Picker
      - Configuration
        - FileType.custom + allowedExtensions: ['png']
        - macOS entitlements 파일 접근 권한
      - Error Handling
        - 사용자 취소 처리 (null result)
        - 파일 접근 권한 거부 처리
      - UX
        - 로딩 인디케이터 표시
        - 최근 경로 기억 (선택적)
  - [x] image 패키지로 PNG 이미지 로드 및 메모리 관리
    <!-- Best Practice Tree -->
    - Image Loading
      - Performance
        - 비동기 로드 (compute/isolate)
        - 메모리 모니터링
        - 대용량 이미지 청크 로딩
      - Validation
        - 파일 존재 여부 확인
        - PNG 포맷 검증
        - 이미지 크기 제한 검사
      - Memory
        - 이전 이미지 dispose 처리
        - 메모리 누수 방지
  - [x] 로드된 이미지를 RawImage로 변환하여 Flutter 위젯에 표시
    <!-- Best Practice Tree -->
    - Image Display
      - Conversion
        - image.Image → ui.Image 변환
        - decodeImageFromPixels 사용
      - Performance
        - RepaintBoundary 활용
        - 불필요한 리빌드 방지
      - Error States
        - 로드 실패 시 placeholder
        - 에러 메시지 표시

- [x] Flutter Desktop 프로젝트 설정 #setup !high
  - [x] Flutter Desktop 프로젝트 생성 및 macOS 타겟 설정
    <!-- Best Practice Tree -->
    - Flutter Desktop Setup
      - Configuration
        - flutter create --platforms=macos,windows,linux
        - pubspec.yaml environment SDK 3.5+
        - macOS deployment target 10.14+
      - Dependencies
        - flutter_riverpod 상태관리
        - file_picker 파일 선택
        - image 패키지 이미지 처리
      - Structure
        - Clean Architecture 폴더 구조
        - lib/core, models, services, providers, widgets
  - [x] pubspec.yaml 의존성 설정 (riverpod, file_picker, image, path)
    <!-- Best Practice Tree -->
    - Dependency Setup
      - Version Pinning
        - 메이저 버전 고정 (^x.y.z)
        - 호환성 테스트 후 업데이트
      - Dev Dependencies
        - build_runner 코드 생성
        - flutter_lints 코드 품질
      - Platform Specific
        - macOS entitlements 파일 권한
        - Sandbox 설정 확인
  - [x] Clean Architecture 폴더 구조 생성 (core, models, services, providers, widgets)
    <!-- Best Practice Tree -->
    - Folder Structure
      - Layers
        - lib/core/utils (공통 유틸리티)
        - lib/models (데이터 모델)
        - lib/services (비즈니스 로직)
        - lib/providers (상태 관리)
        - lib/widgets (UI 컴포넌트)
      - Naming
        - 파일명 snake_case
        - 클래스명 PascalCase
      - Exports
        - barrel 파일로 export 관리

