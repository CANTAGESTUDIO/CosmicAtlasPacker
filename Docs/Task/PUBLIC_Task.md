---
created: 2025-12-23T15:10
updated: 2025-12-25T12:00
---
# PUBLIC Tasks

> 이 파일은 Archon 칸반보드와 양방향 동기화됩니다.
> Available Tags: #feature, #bugfix, #refactor, #test, #docs, #ui, #api, #db, #config, #chore
> Priority: !high, !medium, !low
> Deadline: Deadline(yyyy:MM:dd)
> Subtask: 2-space indent

## Backlog

## Worker1

## Worker2

## Worker3

## Review
- [ ] ExportDialog 프리뷰 패널에 원본 이미지 대신 패킹된 스프라이트들 표시 #bugfix #export !high
  - [x] _generatePreview()에서 multiSpriteProvider 스프라이트 로드 확인
  - [x] sprite.hasImageData 및 imageBytes null 여부 디버그 로그 추가
  - [x] _generateAtlasPreviewImage() sourceImages 맵 구성 로직 점검
  - [x] generateMultiSourceAtlasImage()에서 sprite.imageBytes 복사 로직 검증
  - [x] 원본 이미지 대신 추출된 스프라이트 이미지 우선 사용하도록 분기 수정
  - [x] atlasImage 캔버스에 스프라이트 픽셀 복사 좌표 정확성 확인
  - [x] _convertImgToUiImage() 변환 결과 ui.Image 유효성 검증
  - [x] CustomPaint 렌더링 시 이미지 표시 여부 테스트
    > **BP** · Provider: ref.watch() 상태감지, null-safe 리스트 · imageBytes: hasImageData 선검증, RGBA 4채널 길이확인 · CustomPaint: shouldRepaint() 최적화, dispose() 메모리해제 · 비동기: Completer 패턴, mounted 체크, 5초 타임아웃 · 성능: 디바운스 300ms, RepaintBoundary 격리
- [ ] ExportDialog 최초 오픈 시 파일명 입력 필드 비워두기 #ui #export !low
  - [x] initState() 내 defaultName 변수 생성 로직 위치 확인
  - [x] projectTitle 및 sourceImage.fileName 기반 이름 생성 코드 제거
  - [x] _nameController를 빈 문자열('')로 초기화
  - [x] _performExport()에서 빈 파일명 체크 로직 확인
  - [x] canExport 조건에서 _nameController.text.isNotEmpty 유지 확인
  - [x] 파일명 TextField에 placeholder hint 텍스트 적절성 검토
    > **BP** · initState: 빈문자열 직접초기화, dispose() 해제 · 검증: text.isEmpty 체크, trim() 공백제거 · 버튼활성화: 다중조건 &&, canSubmit getter 분리 · UX: hintText 명확히, 비활성화 시각피드백
- [ ] 텍스처 압축 포맷 드롭다운에서 ETC2 옵션 선택 불가 버그 수정 #bugfix #ui !medium
  - [x] EditorDropdown의 MenuAnchor 메뉴 열기/닫기 동작 확인
  - [x] TextureCompressionFormat.values에 etc2_4bit, etc2_8bit 포함 확인
  - [x] _buildTextureCompressionSection()에서 items 파라미터 전달값 검증
  - [x] MenuItemButton onPressed 콜백 내 onChanged(item) 호출 확인
  - [x] ETC2 선택 시 notifier.updateIOSFormat() 정상 호출 여부 로그 추가
  - [x] TextureCompressionFormat에서 supportsIOS=false인 ETC2 필터링 여부 확인
  - [x] iosFormat 필드에 ETC2 할당 시 Provider 상태 업데이트 검증
  - [x] 드롭다운 메뉴 닫힘 후 선택값 반영 UI 갱신 확인
    > **BP** · MenuAnchor: controller.open()/close() 명시호출, onPressed null체크 · enum필터링: .where() 조건필터, supportsIOS 플래그확인, 빈리스트 폴백 · Provider: ref.read() for mutations, 상태변경 후 자동리빌드 · 디버깅: debugPrint 콜백확인, 선택값==현재값 비교로그
- [ ] 포맷 타입 변경 시 최종 결과물 미리보기 갱신되지 않는 버그 수정 #bugfix #export !medium
  - [x] _buildTextureCompressionSection() onChanged 콜백 로직 분석
  - [x] notifier.updateIOSFormat() 호출 시 Provider 상태 변경 확인
  - [x] build() 메서드 내 ref.watch(texturePackingSettingsProvider) 감지 확인
  - [x] 포맷 변경 onChanged에서 setState() 또는 _updatePreview() 호출 추가
  - [x] _updatePreview() 디바운스 타이머 300ms 정상 작동 확인
  - [x] _generatePreview()에서 새 포맷 설정값 반영 여부 검증
  - [x] 프리뷰 이미지 재생성 후 setState()로 UI 갱신 트리거
  - [x] 포맷 변경 → 프리뷰 갱신 전체 플로우 테스트
    > **BP** · ref.watch: build() 내 자동리빌드, select() 특정필드만 감시 · onChanged: setState() 또는 _updatePreview() 호출, async 에러핸들링 · 디바운스: Timer 300ms, 이전타이머 cancel() 필수, dispose() 정리 · 프리뷰재생성: 이전이미지 dispose(), mounted 체크, 로딩표시 · 테스트: 연속변경시 마지막값만 반영, race condition 방지
- [ ] 텍스처 패커 모드 / 애니메이션 모드 전환 기능 구현 #feature !high
  - [x] EditorMode enum 생성 및 editorModeProvider 추가
  - [x] EditorToolbar에 모드 전환 토글 버튼(세그먼티드 버튼) 추가
  - [x] EditorScreen에서 _buildMainContent() 메서드 모드별 분기 구현
  - [x] _buildTexturePackerLayout() 메서드로 기존 레이아웃 분리
  - [x] _buildAnimationLayout() 메서드로 애니메이션 모드 레이아웃 구현
  - [ ] AnimationSettingsPanel 독립 컴포넌트로 분리 생성 (향후 구현)
  - [ ] 모드 전환 시 상태 유지 및 드래그 앤 드롭 지원 구현 (향후 구현)
- [ ] 텍스처 패킹 세팅 다이얼로그 구현 #feature #ui #settings !high
  - [x] TextureCompressionSettings 모델 생성 (freezed)
  - [ ] lib/data/models/texture_compression_settings.dart 파일 생성
  - [ ] TextureCompressionFormat enum 정의
  - [ ] ASTCBlockSize enum 정의
  - [ ] GameType enum 정의
  - [ ] TextureCompressionSettings 클래스 필드 정의
  - [ ] freezed 어노테이션 및 copyWith 메서드 추가
  - [ ] JSON 직렬화 코드 생성 및 검증
  - [ ] 기본 설정 팩토리 메서드 생성
  - [ ] TexturePackingSettingsProvider 생성
  - [ ] lib/providers/texture_packing_settings_provider.dart 파일 생성
  - [ ] LocalStorageService 생성 및 연동
  - [ ] TexturePackingSettingsState 및 Events 정의
  - [ ] 프리셋 적용 로직 구현
  - [ ] Provider 앱 레벨 등록
  - [ ] OnboardingStepper 위젯 구현 (6단계 온보딩)
  - [ ] lib/widgets/dialogs/texture_settings/onboarding_stepper.dart 파일 생성
  - [ ] Step 1: 타겟 기기 정의 UI 구현
  - [ ] Step 2: 그래픽 품질 수준 UI 구현
  - [ ] Step 3: 메모리 예산 설정 UI 구현
  - [ ] Step 4: 압축 전략 UI 구현
  - [ ] Step 5: 빌드 시간 및 CI/CD 영향 UI 구현
  - [ ] Step 6: QA 테스트 계획 UI 구현
  - [ ] 온보딩 진행 상태 저장 및 복구 로직
  - [ ] ExportTypeToggle 위젯 구현 (스프라이트/폰트)
  - [ ] lib/widgets/dialogs/texture_settings/export_type_toggle.dart 파일 생성
  - [ ] 모드 전환 로직 구현
  - [ ] 스프라이트 모드 UI 레이아웃 구현
  - [ ] 폰트 모드 UI 레이아웃 구현
  - [ ] GameTypeSection 위젯 구현 (게임 타입별 전략)
  - [ ] lib/widgets/dialogs/texture_settings/game_type_section.dart 파일 생성
  - [ ] 게임 타입 프리셋 데이터 구조 정의
  - [ ] 프리셋 적용 로직 구현
  - [ ] 커스텀 설정 모드 UI 구현
  - [ ] CompressionFormatSection 위젯 구현 (플랫폼별 포맷)
  - [ ] lib/widgets/dialogs/texture_settings/compression_format_section.dart 파일 생성
  - [ ] Android 포맷 옵션 UI 구현
  - [ ] iOS 포맷 옵션 UI 구현
  - [ ] 폴백 전략 UI 구현
  - [ ] MemoryInfoPanel 위젯 구현
  - [ ] lib/widgets/dialogs/texture_settings/memory_info_panel.dart 파일 생성
  - [ ] 메모리 계산 로직 구현
  - [ ] 빌드 크기 추정 로직 구현
  - [ ] 시각적 피드백 구현
  - [ ] TexturePackingSettingsDialog 메인 다이얼로그 조립
  - [ ] lib/widgets/dialogs/texture_settings/texture_packing_settings_dialog.dart 파일 생성
  - [ ] 온보딩 조건부 렌더링 구현
  - [ ] 탭 네비게이션 구현
  - [ ] Save/Cancel 버튼 로직 구현
  - [ ] Provider 연동 및 실시간 프리뷰
  - [ ] ExportDialog 통합 및 메뉴 연동
  - [ ] ExportDialog에 텍스처 설정 버튼 추가
  - [ ] 메뉴 항목 추가 및 라우팅 구현
  - [ ] 내보내기 워크플로우 통합
  - [ ] 설정 저장/로드 로직 구현
- [ ] Export 기능 구현 (애니메이션/폰트/9-Slice 데이터 처리) #feature #export !high
  - [x] animationProvider에서 AnimationSequence 목록 읽기
  - [x] AnimationSequence → AnimationInfo 변환 로직 구현
  - [x] generateMetadata()에 animations 파라미터 추가
  - [x] _exportAnimationInfo 플래그 조건부 포함 처리
  - [x] SpriteModel에서 NineSliceBorder 데이터 추출
  - [x] NineSliceBorder → NineSliceInfo 변환 구현
  - [x] generateMetadata()에 nineSlice 필드 채우기
  - [x] 9-Slice isEnabled 유효성 체크 로직
  - [x] BMFont .fnt 파일 포맷 스펙 정의
  - [x] ExportService.generateFontData() 메서드 추가
  - [x] 스프라이트별 character metrics 계산
  - [x] .fnt 파일 저장 로직 구현
  - [x] _performExport()에서 애니메이션 데이터 전달
  - [x] _performExport()에서 폰트 내보내기 분기 처리
  - [x] 미리보기에 애니메이션 시퀀스 개수 표시
  - [x] 미리보기에 9-Slice 적용 스프라이트 개수 표시
  - [x] 폰트 모드 시 글자 수 표시
- [ ] Export 프리뷰 패널 실제 이미지 렌더링 #feature #export !medium
  - [x] img.Image에서 RGBA 픽셀 데이터 추출
  - [x] ui.decodeImageFromPixels로 ui.Image 생성
  - [x] 비동기 변환 완료 대기 처리
  - [x] CustomPaint 위젯으로 이미지 렌더링
  - [x] 패널 크기에 맞춰 스케일 조정
  - [x] 이미지 생성 중 로딩 인디케이터 표시
  - [x] 설정 변경 디바운스 처리 (300ms)
  - [x] 변경 감지 시 프리뷰 재생성
  - [x] 이전 ui.Image 메모리 해제
- [ ] 텍스처 압축 포맷 설정 기능 구현 #feature #export !medium
  - [x] ImageOutputFormat enum 생성 (PNG, JPEG)
  - [x] 각 포맷별 품질 파라미터 정의
  - [x] ExportService.encodeImage() 포맷별 인코딩 메서드 추가
  - [x] ExportDialog에 포맷 선택 DropdownButton 추가
  - [x] 품질 슬라이더 UI 구현
  - [x] 포맷별 예상 파일 크기 표시
  - [x] PNG 인코딩 (압축 레벨 0-9)
  - [x] JPEG 인코딩 (알파 채널 흰색 배경 처리)
- [ ] 배경색 제거 설정 다이얼로그 UI 개선 #ui !medium
  - [x] 현재 배경색 제거 다이얼로그 구조 분석
  - [x] 배경색 선택 컨트롤 개선 (ColorPicker 통합)
  - [x] 허용 오차(Tolerance) 슬라이더 UI 구현
  - [x] 배경색 제거 옵션 UI 추가 (부드러운 가장자리 등)
  - [x] 배경색 제거 프리뷰 패널 구현
  - [x] 다이얼로그 버튼 레이아웃 및 상호작용 개선
- [ ] 오토슬라이스 설정 다이얼로그 UI 개선 #ui !medium
  - [x] 현재 오토슬라이스 다이얼로그 구조 분석
  - [x] 오토슬라이스 파라미터별 시각적 컨트롤 디자인
  - [x] 설정 프리셋 UI 컴포넌트 구현
  - [x] 오토슬라이스 결과 프리뷰 패널 추가
  - [x] 다이얼로그 버튼 레이아웃 및 상호작용 개선
  - [x] 배경색 제거 설정 UI 오토슬라이스 다이얼로그 내 통합
- [ ] 그리드 슬라이스 설정 다이얼로그 UI 개선 #ui !medium
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

