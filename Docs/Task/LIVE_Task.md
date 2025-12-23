# LIVE Tasks

> This file syncs bidirectionally with the Archon Kanban board.

---

## Backlog

<!-- 모든 태스크가 Worker들에게 분배됨 -->

## Worker1

<!-- Worker1: Core Quality (버그 수정, 성능 최적화) - core/, services/ 영역 -->
<!-- 작업순서: Phase 1 - 안정화 (최우선) -->

- [ ] 버그 수정 및 안정화 #bugfix !high
  - [ ] 사용자 피드백 기반 버그 트래킹 시스템 구축
    - [ ] GitHub Issues에 버그 리포트 템플릿 생성 (.github/ISSUE_TEMPLATE/bug_report.md)
    - [ ] 버그 심각도 라벨 정의 (Critical/High/Medium/Low)
    - [ ] 버그 상태 라벨 정의 (Open/InProgress/Fixed/Verified)
    - [ ] 릴리즈 노트 자동 생성 스크립트 작성
    <!-- Best Practice Tree -->
    <!-- Bug Tracking: Collection(GitHub Issues, 템플릿) → Triage(심각도 분류, 재현 단계) → Tracking(상태 관리, 릴리즈 연동) -->
  - [ ] 크래시 리포팅 메커니즘 구현
    - [ ] ErrorHandler 클래스 생성 (lib/core/error/error_handler.dart)
    - [ ] FlutterError.onError 핸들러 등록 (main.dart)
    - [ ] PlatformDispatcher.onError 핸들러 등록 (비동기 에러)
    - [ ] 스택 트레이스 포맷팅 유틸리티 구현
    - [ ] 로컬 로그 파일 저장 로직 구현 (logs/ 디렉토리)
    - [ ] 크래시 로그 뷰어 다이얼로그 UI 구현
    - [ ] 민감 정보 필터링 로직 추가 (파일 경로, 사용자명)
    <!-- Best Practice Tree -->
    <!-- Crash Reporting: Collection(FlutterError.onError, 스택트레이스) → Storage(로컬 로그, 원격 전송) → Privacy(민감정보 제외, 동의) -->
  - [ ] 메모리 누수 모니터링 및 수정
    - [ ] ImageCache 사이즈 제한 설정 (maximumSize, maximumSizeBytes)
    - [ ] 모든 StatefulWidget에 dispose() 패턴 검토 및 수정
    - [ ] StreamSubscription 해제 누락 검사 및 수정
    - [ ] AnimationController dispose 검사 및 수정
    - [ ] FocusNode dispose 검사 및 수정
    - [ ] ScrollController dispose 검사 및 수정
    - [ ] LRU 캐시 적용으로 무한 캐시 증가 방지
    - [ ] 메모리 프로파일링 테스트 수행 및 문서화
    <!-- Best Practice Tree -->
    <!-- Memory Leak: Detection(DevTools Memory, 프로파일링) → Common Issues(이미지 dispose, 리스너 해제, 캐시 증가) → Prevention(dispose 패턴, WeakReference) -->

- [ ] 성능 최적화 #performance !high
  - [ ] 대용량 이미지 처리 최적화
    - [ ] Isolate 기반 이미지 디코딩 구현 (compute 함수 활용)
    - [ ] 이미지 로딩 프로그레스 표시 UI 추가
    - [ ] 프리뷰용 다운샘플링 로직 구현 (썸네일 생성)
    - [ ] 청크 단위 이미지 처리 구현 (대용량 파일 분할)
    - [ ] LRU 이미지 캐시 매니저 구현 (캐시 크기 제한)
    - [ ] 메모리 임계값 모니터링 및 자동 캐시 정리
    <!-- Best Practice Tree -->
    <!-- Large Image: Loading(Isolate 비동기, 프로그레시브) → Memory(다운샘플링, 청크 처리) → Caching(LRU, 메모리 임계값) -->
  - [ ] 빈 패킹 알고리즘 성능 개선
    - [ ] 현재 패킹 알고리즘 벤치마크 측정 (100/500/1000 스프라이트)
    - [ ] 병목 지점 프로파일링 및 분석
    - [ ] 공간 복잡도 최적화 (불필요한 데이터 구조 제거)
    - [ ] 휴리스틱 개선 (MaxRects, Guillotine 비교)
    - [ ] 중간 결과 캐싱 구현 (변경된 스프라이트만 재계산)
    - [ ] 캐시 무효화 로직 구현 (스프라이트 변경 감지)
    - [ ] 개선 후 벤치마크 비교 문서화
    <!-- Best Practice Tree -->
    <!-- Packing: Algorithm(공간 복잡도, 휴리스틱) → Caching(중간 결과, 변경분만 재계산) → Profiling(병목 식별, 벤치마크) -->
  - [ ] UI 렌더링 성능 프로파일링 및 개선
    - [ ] DevTools Performance 탭으로 프레임 드롭 분석
    - [ ] 리빌드 과다 위젯 식별 (flutter inspector)
    - [ ] RepaintBoundary 적용 (Canvas, 스프라이트 리스트)
    - [ ] const 생성자 활용 최적화 (정적 위젯)
    - [ ] 불필요한 setState 호출 제거
    - [ ] Selector/Consumer 세분화로 Provider 최적화
    - [ ] Canvas 레이어 최적화 (saveLayer 최소화)
    - [ ] 클리핑 영역 활용으로 렌더링 범위 제한
    <!-- Best Practice Tree -->
    <!-- UI Performance: Profiling(DevTools, 프레임 드롭) → Optimization(RepaintBoundary, const, 리빌드 제거) → Rendering(Canvas 레이어, 클리핑) -->

## Worker2

<!-- Worker2: UX & i18n (접근성, 국제화, 문서화) - widgets/, l10n/ 영역 -->
<!-- 작업순서: Phase 2 - 사용성 개선 -->

- [ ] 접근성 개선 #accessibility !medium
  - [ ] 키보드 네비게이션 완성
    - [ ] 전체 앱 포커스 순서 맵 작성 (문서화)
    - [ ] FocusNode 누락된 인터랙티브 위젯에 추가
    - [ ] FocusTraversalGroup으로 논리적 그룹화
    - [ ] Tab/Shift+Tab 순서 테스트 및 조정
    - [ ] 포커스 표시 스타일 정의 (하이라이트 색상, 두께)
    - [ ] 모든 기능 키보드만으로 접근 가능 확인
    - [ ] 단축키 목록 문서화 (Docs/Shortcuts.md)
    <!-- Best Practice Tree -->
    <!-- Keyboard Nav: Focus Management(FocusNode, 순서 정의) → Actions(키보드 접근, 단축키 문서화) → Visual(포커스 표시, 하이라이트) -->
  - [ ] 스크린 리더 지원 (Semantics)
    - [ ] 모든 이미지에 Semantics.label 추가
    - [ ] 버튼/아이콘에 의미있는 label 추가
    - [ ] Semantics.sortKey로 읽기 순서 정의
    - [ ] SemanticsBoundary로 랜드마크 정의
    - [ ] ExcludeSemantics로 장식용 요소 제외
    - [ ] macOS VoiceOver 테스트 수행 및 문서화
    - [ ] Windows NVDA 테스트 수행 및 문서화
    <!-- Best Practice Tree -->
    <!-- Screen Reader: Semantics(위젯 적용, 의미있는 라벨) → Navigation(논리적 순서, 랜드마크) → Testing(VoiceOver, NVDA) -->
  - [ ] 고대비 모드 지원
    - [ ] MediaQuery.highContrastOf 감지 로직 추가
    - [ ] 고대비 색상 팔레트 정의 (ColorScheme)
    - [ ] 경계선 강조 스타일 정의 (2px 이상)
    - [ ] ThemeData에 고대비 테마 추가
    - [ ] 테마 전환 로직 구현
    - [ ] macOS 고대비 설정 테스트
    - [ ] Windows 고대비 설정 테스트
    - [ ] 가독성 검증 체크리스트 작성
    <!-- Best Practice Tree -->
    <!-- High Contrast: Detection(MediaQuery.highContrast, 시스템 설정) → Theme(고대비 팔레트, 경계선 강조) → Testing(설정 조합, 가독성) -->

- [ ] 국제화 (i18n) 지원 #i18n !medium
  - [ ] 다국어 지원 인프라 구축
    - [ ] flutter_localizations 패키지 추가 (pubspec.yaml)
    - [ ] intl 패키지 추가 및 설정
    - [ ] l10n.yaml 설정 파일 생성
    - [ ] lib/l10n/ 폴더 구조 생성
    - [ ] app_en.arb 기본 파일 생성
    - [ ] app_ko.arb 한국어 파일 생성
    - [ ] MaterialApp에 localizationsDelegates 설정
    - [ ] 언어 전환 설정 UI 구현 (Settings)
    - [ ] 선택된 언어 저장 로직 구현 (SharedPreferences)
    <!-- Best Practice Tree -->
    <!-- i18n Infrastructure: Package(flutter_localizations, intl) → Structure(arb 파일, 언어별 폴더) → Integration(localizationsDelegates, 언어 전환) -->
  - [ ] 한국어/영어 번역 완성
    - [ ] 모든 UI 문자열 추출 및 키 정의
    - [ ] 메뉴 항목 번역 (File, Edit, View, Help)
    - [ ] 버튼 텍스트 번역
    - [ ] 다이얼로그 메시지 번역
    - [ ] 에러 메시지 번역
    - [ ] 툴팁 텍스트 번역
    - [ ] 상태 메시지 번역
    - [ ] 누락 문자열 감지 스크립트 작성
    - [ ] 번역 리뷰 체크리스트 작성
    <!-- Best Practice Tree -->
    <!-- Translation: Coverage(모든 UI 문자열, 에러 메시지) → Quality(네이티브 검토, 컨텍스트 맞춤) → Maintenance(키 관리, 누락 감지) -->
  - [ ] 날짜/숫자 포맷 로케일 지원
    - [ ] DateFormat 래퍼 유틸리티 생성
    - [ ] NumberFormat 래퍼 유틸리티 생성
    - [ ] 파일 크기 포맷 유틸리티 (KB, MB, GB)
    - [ ] 좌표/픽셀 값 포맷 유틸리티
    - [ ] 한국어 날짜 포맷 테스트 (yyyy년 MM월 dd일)
    - [ ] 영어 날짜 포맷 테스트 (MMM dd, yyyy)
    - [ ] 천단위 구분자 테스트 (1,234 vs 1.234)
    <!-- Best Practice Tree -->
    <!-- Locale Formatting: Date(DateFormat, 로케일별) → Numbers(NumberFormat, 천단위 구분) → Currency(통화 기호, 위치 규칙) -->

- [ ] 문서화 및 도움말 #docs !medium
  - [ ] 사용자 가이드 문서 작성
    - [ ] 빠른 시작 가이드 작성 (5분 튜토리얼)
    - [ ] 스프라이트 추가 방법 설명
    - [ ] 아틀라스 패킹 방법 설명
    - [ ] 내보내기 옵션 설명
    - [ ] 설정 옵션 설명
    - [ ] 스크린샷 캡처 및 추가
    - [ ] 웹 문서 호스팅 설정 (GitHub Pages)
    <!-- Best Practice Tree -->
    <!-- User Guide: Content(빠른 시작, 기능별 설명) → Format(마크다운/웹, 스크린샷) → Accessibility(앱 내 접근, 검색) -->
  - [ ] 앱 내 도움말 시스템
    - [ ] 주요 UI 요소에 Tooltip 추가
    - [ ] 메뉴 > Help 항목 추가
    - [ ] 단축키 목록 다이얼로그 구현
    - [ ] "What's This?" 컨텍스트 도움말 모드 구현
    - [ ] 온라인 문서 링크 연결
    - [ ] 버전 정보 다이얼로그 구현
    <!-- Best Practice Tree -->
    <!-- In-App Help: Tooltip(UI 요소 설명, 호버) → Help Menu(메뉴 항목, 단축키 목록) → Context Help(도움말 버튼, 문서 링크) -->
  - [ ] 단축키 치트시트
    - [ ] 모든 단축키 목록 수집
    - [ ] 카테고리별 분류 (파일, 편집, 뷰, 도구)
    - [ ] ShortcutCheatsheet 위젯 구현
    - [ ] Cmd+? (macOS) / F1 (Windows) 단축키 연결
    - [ ] 오버레이 표시 애니메이션 구현
    - [ ] macOS/Windows 키 표기 분기 (Cmd vs Ctrl)
    - [ ] 인쇄 가능 PDF 버전 생성
    <!-- Best Practice Tree -->
    <!-- Shortcut Reference: Content(모든 단축키, 카테고리 분류) → Access(Cmd+?/Help 메뉴, 오버레이) → Platform(macOS/Windows 분기, Cmd vs Ctrl) -->

## Worker3

<!-- Worker3: Infra & Deploy (업데이트, 배포, 피드백) - 빌드/배포 파이프라인 -->
<!-- 작업순서: Phase 3~4 - 배포 준비 및 운영 기능 -->

- [ ] 배포 파이프라인 구축 #deploy !medium
  - [ ] macOS 앱 서명 및 공증
    - [ ] Apple Developer 계정 Developer ID 인증서 생성
    - [ ] 프로비저닝 프로파일 생성 및 설정
    - [ ] macos/Runner.xcodeproj 서명 설정
    - [ ] Entitlements 파일 검토 및 필요 권한 정의
    - [ ] Hardened Runtime 활성화
    - [ ] codesign으로 앱 서명
    - [ ] xcrun notarytool로 Apple 공증 제출
    - [ ] xcrun stapler로 공증 티켓 첨부
    - [ ] 공증 후 앱 실행 테스트
    <!-- Best Practice Tree -->
    <!-- macOS Signing: Certificates(Developer ID, 프로비저닝) → Notarization(Apple 공증, stapler) → Entitlements(권한 정의, Sandbox) -->
  - [ ] Windows 빌드 및 인스톨러
    - [ ] flutter build windows --release 빌드 확인
    - [ ] MSIX 패키징 설정 (msix 패키지 추가)
    - [ ] msix_config 섹션 pubspec.yaml에 추가
    - [ ] 앱 아이콘 및 메타데이터 설정
    - [ ] MSIX 인스톨러 생성 테스트
    - [ ] Inno Setup 대체 exe 인스톨러 (선택적)
    - [ ] Windows SmartScreen 테스트
    <!-- Best Practice Tree -->
    <!-- Windows Build: Build(flutter build windows, MSIX/exe) → Signing(코드 서명, SmartScreen) → Distribution(GitHub Releases, MS Store) -->
  - [ ] Linux 빌드 및 패키징
    - [ ] flutter build linux --release 빌드 확인
    - [ ] 필요 의존성 목록 작성 (libgtk-3, etc.)
    - [ ] AppImage 패키징 스크립트 작성
    - [ ] appimagetool로 AppImage 생성
    - [ ] 다른 Linux 배포판에서 실행 테스트 (Ubuntu, Fedora)
    - [ ] .desktop 파일 생성 및 아이콘 설정
    <!-- Best Practice Tree -->
    <!-- Linux Build: Build(flutter build linux, 의존성 번들링) → Packaging(AppImage, deb/rpm) → Distribution(GitHub Releases, Flatpak) -->
  - [ ] GitHub Releases 자동 배포
    - [ ] .github/workflows/release.yml 생성
    - [ ] 태그 푸시 트리거 설정 (on: push: tags: 'v*')
    - [ ] macOS 빌드 job 구성
    - [ ] Windows 빌드 job 구성
    - [ ] Linux 빌드 job 구성
    - [ ] 아티팩트 업로드 단계 추가
    - [ ] 자동 릴리즈 노트 생성 설정
    - [ ] 릴리즈 에셋 첨부 자동화
    - [ ] 전체 워크플로우 테스트 (테스트 태그)
    <!-- Best Practice Tree -->
    <!-- CI/CD: Workflow(GitHub Actions, 태그 트리거) → Build Matrix(macOS/Windows/Linux 병렬) → Release(자동 노트, 에셋 첨부) -->

- [ ] 업데이트 시스템 #update !low
  - [ ] 버전 체크 메커니즘
    - [ ] UpdateService 클래스 생성 (lib/services/update_service.dart)
    - [ ] GitHub Releases API 호출 로직 구현
    - [ ] 현재 버전과 최신 버전 비교 로직
    - [ ] 시맨틱 버전 파싱 유틸리티 구현
    - [ ] 앱 시작 시 버전 체크 (선택적 활성화)
    - [ ] 마지막 체크 시간 저장 (24시간 간격)
    - [ ] 네트워크 오류 시 graceful 처리
    <!-- Best Practice Tree -->
    <!-- Version Check: API(GitHub Releases API, 버전 비교) → Timing(앱 시작 시, 주기적 백그라운드) → Storage(현재 버전, 마지막 체크) -->
  - [ ] 업데이트 알림 UI
    - [ ] UpdateBanner 위젯 구현 (비침습적 배너)
    - [ ] 버전 정보 및 변경 사항 표시
    - [ ] "지금 다운로드" 버튼 (브라우저로 이동)
    - [ ] "나중에 알림" 버튼 (24시간 후 다시 표시)
    - [ ] "이 버전 건너뛰기" 버튼 (해당 버전 무시)
    - [ ] 알림 설정 저장 로직 (SharedPreferences)
    - [ ] 강제 업데이트 지원 (중요 보안 업데이트)
    <!-- Best Practice Tree -->
    <!-- Update Notification: Display(비침습적 배너/다이얼로그, 버전 정보) → Actions(지금 다운로드, 나중에, 건너뛰기) → Persistence(설정 저장, 강제 업데이트) -->
  - [ ] 자동 업데이트 (선택적)
    - [ ] 백그라운드 다운로드 로직 구현
    - [ ] 다운로드 진행률 UI 표시
    - [ ] 다운로드 완료 알림
    - [ ] 앱 종료 후 설치 스크립트 (macOS/Windows)
    - [ ] 롤백 메커니즘 구현 (이전 버전 백업)
    - [ ] macOS: Sparkle 프레임워크 통합 검토
    - [ ] Windows: Squirrel.Windows 통합 검토
    <!-- Best Practice Tree -->
    <!-- Auto Update: Download(백그라운드, 진행률) → Installation(앱 종료 후 설치, 롤백) → Platform(macOS Sparkle, Windows Squirrel) -->

- [ ] 사용자 피드백 수집 #feedback !low
  - [ ] 피드백 전송 기능
    - [ ] Help > Send Feedback 메뉴 항목 추가
    - [ ] FeedbackDialog 위젯 구현
    - [ ] 피드백 카테고리 선택 (버그/제안/질문/기타)
    - [ ] 제목 및 설명 입력 필드
    - [ ] 시스템 정보 첨부 체크박스 (동의)
    - [ ] GitHub Issue 생성 API 연동 (또는 이메일)
    - [ ] 전송 성공/실패 피드백 표시
    <!-- Best Practice Tree -->
    <!-- Feedback Submission: UI(Help > Send Feedback, 간단한 폼) → Content(제목/설명, 카테고리) → Delivery(이메일/GitHub Issue, 시스템 정보) -->
  - [ ] 버그 리포트 템플릿
    - [ ] 버그 리포트 다이얼로그 구현
    - [ ] 재현 단계 입력 가이드 UI
    - [ ] 예상 동작 vs 실제 동작 입력 필드
    - [ ] OS 버전 자동 수집
    - [ ] 앱 버전 자동 수집
    - [ ] 시스템 정보 자동 수집 (메모리, 해상도)
    - [ ] 스크린샷 첨부 옵션 구현
    - [ ] 로그 파일 첨부 옵션 (동의 시)
    <!-- Best Practice Tree -->
    <!-- Bug Report: Fields(재현 단계, 예상 vs 실제, 환경) → Auto-fill(OS/앱 버전, 시스템 정보) → Attachment(스크린샷, 로그 파일) -->
  - [ ] 기능 요청 수집 채널
    - [ ] GitHub Discussions 활성화 및 설정
    - [ ] Feature Request 카테고리 생성
    - [ ] 앱 내 "기능 요청" 링크 추가
    - [ ] 투표 시스템 안내 (반응 이모지)
    - [ ] 요청 상태 라벨 정의 (Planned/InProgress/Done)
    - [ ] 구현 시 알림 프로세스 정의
    <!-- Best Practice Tree -->
    <!-- Feature Requests: Channel(GitHub Discussions, 포럼) → Voting(반응 이모지, 우선순위) → Communication(상태 업데이트, 구현 알림) -->

## Review

## Done
