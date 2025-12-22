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
    <!-- Best Practice Tree -->
    - Bug Tracking
      - Collection
        - GitHub Issues 활용
        - 버그 리포트 템플릿
      - Triage
        - 심각도 분류 (Critical/High/Medium/Low)
        - 재현 단계 문서화
      - Tracking
        - 상태 관리 (Open/InProgress/Fixed)
        - 릴리즈 노트 연동
  - [ ] 크래시 리포팅 메커니즘 구현
    <!-- Best Practice Tree -->
    - Crash Reporting
      - Collection
        - FlutterError.onError 핸들러
        - 스택 트레이스 수집
      - Storage
        - 로컬 로그 파일 저장
        - 옵션: 원격 서버 전송
      - Privacy
        - 민감 정보 제외
        - 사용자 동의 필요
  - [ ] 메모리 누수 모니터링 및 수정
    <!-- Best Practice Tree -->
    - Memory Leak Fix
      - Detection
        - DevTools Memory 탭 활용
        - 주기적 프로파일링
      - Common Issues
        - 이미지 dispose 누락
        - 리스너 해제 누락
        - 캐시 무한 증가
      - Prevention
        - dispose 패턴 적용
        - WeakReference 활용

- [ ] 성능 최적화 #performance !high
  - [ ] 대용량 이미지 처리 최적화
    <!-- Best Practice Tree -->
    - Large Image Optimization
      - Loading
        - Isolate 활용 비동기 처리
        - 프로그레시브 로딩
      - Memory
        - 이미지 다운샘플링 (프리뷰용)
        - 청크 단위 처리
      - Caching
        - LRU 캐시 적용
        - 메모리 임계값 관리
  - [ ] 빈 패킹 알고리즘 성능 개선
    <!-- Best Practice Tree -->
    - Packing Optimization
      - Algorithm
        - 공간 복잡도 최적화
        - 휴리스틱 개선
      - Caching
        - 중간 결과 캐싱
        - 변경된 스프라이트만 재계산
      - Profiling
        - 병목 지점 식별
        - 벤치마크 테스트
  - [ ] UI 렌더링 성능 프로파일링 및 개선
    <!-- Best Practice Tree -->
    - UI Performance
      - Profiling
        - DevTools Performance 탭
        - 프레임 드롭 분석
      - Optimization
        - RepaintBoundary 적용
        - const 위젯 활용
        - 불필요한 리빌드 제거
      - Rendering
        - Canvas 레이어 최적화
        - 클리핑 영역 활용

## Worker2

<!-- Worker2: UX & i18n (접근성, 국제화, 문서화) - widgets/, l10n/ 영역 -->
<!-- 작업순서: Phase 2 - 사용성 개선 -->

- [ ] 접근성 개선 #accessibility !medium
  - [ ] 키보드 네비게이션 완성
    <!-- Best Practice Tree -->
    - Keyboard Navigation
      - Focus Management
        - FocusNode 적절한 배치
        - 포커스 순서 정의
      - Actions
        - 모든 기능 키보드 접근 가능
        - 단축키 문서화
      - Visual
        - 포커스 표시 명확히
        - 하이라이트 스타일
  - [ ] 스크린 리더 지원 (Semantics)
    <!-- Best Practice Tree -->
    - Screen Reader
      - Semantics
        - Semantics 위젯 적용
        - 의미있는 라벨
      - Navigation
        - 논리적 순서
        - 랜드마크 정의
      - Testing
        - VoiceOver (macOS) 테스트
        - NVDA (Windows) 테스트
  - [ ] 고대비 모드 지원
    <!-- Best Practice Tree -->
    - High Contrast
      - Detection
        - MediaQuery.highContrast
        - 시스템 설정 감지
      - Theme
        - 고대비 색상 팔레트
        - 경계선 강조
      - Testing
        - 다양한 설정 조합 테스트
        - 가독성 검증

- [ ] 국제화 (i18n) 지원 #i18n !medium
  - [ ] 다국어 지원 인프라 구축
    <!-- Best Practice Tree -->
    - i18n Infrastructure
      - Package
        - flutter_localizations
        - intl 패키지
      - Structure
        - arb 파일 관리
        - 언어별 폴더 구조
      - Integration
        - MaterialApp localizationsDelegates
        - 언어 전환 로직
  - [ ] 한국어/영어 번역 완성
    <!-- Best Practice Tree -->
    - Translation
      - Coverage
        - 모든 UI 문자열
        - 에러 메시지
      - Quality
        - 네이티브 스피커 검토
        - 컨텍스트에 맞는 번역
      - Maintenance
        - 번역 키 관리
        - 누락 문자열 감지
  - [ ] 날짜/숫자 포맷 로케일 지원
    <!-- Best Practice Tree -->
    - Locale Formatting
      - Date
        - intl DateFormat 활용
        - 로케일별 포맷
      - Numbers
        - NumberFormat 활용
        - 소수점, 천단위 구분
      - Currency (필요시)
        - 통화 기호
        - 위치 규칙

- [ ] 문서화 및 도움말 #docs !medium
  - [ ] 사용자 가이드 문서 작성
    <!-- Best Practice Tree -->
    - User Guide
      - Content
        - 빠른 시작 가이드
        - 기능별 상세 설명
      - Format
        - 마크다운 또는 웹 문서
        - 스크린샷 포함
      - Accessibility
        - 앱 내 접근 또는 웹 링크
        - 검색 가능
  - [ ] 앱 내 도움말 시스템
    <!-- Best Practice Tree -->
    - In-App Help
      - Tooltip
        - 주요 UI 요소 설명
        - 호버 시 표시
      - Help Menu
        - 메뉴 > Help 항목
        - 단축키 목록
      - Context Help
        - 다이얼로그 도움말 버튼
        - 관련 문서 링크
  - [ ] 단축키 치트시트
    <!-- Best Practice Tree -->
    - Shortcut Reference
      - Content
        - 모든 단축키 목록
        - 카테고리별 분류
      - Access
        - Cmd+? 또는 Help 메뉴
        - 오버레이 표시
      - Platform
        - macOS/Windows 분기
        - Cmd vs Ctrl 표시

## Worker3

<!-- Worker3: Infra & Deploy (업데이트, 배포, 피드백) - 빌드/배포 파이프라인 -->
<!-- 작업순서: Phase 3~4 - 배포 준비 및 운영 기능 -->

- [ ] 배포 파이프라인 구축 #deploy !medium
  - [ ] macOS 앱 서명 및 공증
    <!-- Best Practice Tree -->
    - macOS Signing
      - Certificates
        - Developer ID 인증서
        - 프로비저닝 프로파일
      - Notarization
        - Apple 공증 프로세스
        - stapler 적용
      - Entitlements
        - 필요 권한 정의
        - Sandbox 설정
  - [ ] Windows 빌드 및 인스톨러
    <!-- Best Practice Tree -->
    - Windows Build
      - Build
        - flutter build windows --release
        - MSIX 또는 exe 인스톨러
      - Signing
        - 코드 서명 인증서 (선택적)
        - SmartScreen 경고 방지
      - Distribution
        - GitHub Releases
        - Microsoft Store (선택적)
  - [ ] Linux 빌드 및 패키징
    <!-- Best Practice Tree -->
    - Linux Build
      - Build
        - flutter build linux --release
        - 의존성 번들링
      - Packaging
        - AppImage (권장)
        - deb/rpm (선택적)
      - Distribution
        - GitHub Releases
        - Flatpak/Snap (선택적)
  - [ ] GitHub Releases 자동 배포
    <!-- Best Practice Tree -->
    - CI/CD
      - Workflow
        - GitHub Actions 활용
        - 태그 기반 트리거
      - Build Matrix
        - macOS, Windows, Linux 병렬 빌드
        - 아티팩트 업로드
      - Release
        - 자동 릴리즈 노트 생성
        - 에셋 첨부

- [ ] 업데이트 시스템 #update !low
  - [ ] 버전 체크 메커니즘
    <!-- Best Practice Tree -->
    - Version Check
      - API
        - GitHub Releases API 활용
        - 버전 비교 로직
      - Timing
        - 앱 시작 시 체크
        - 주기적 백그라운드 체크
      - Storage
        - 현재 버전 정보
        - 마지막 체크 시간
  - [ ] 업데이트 알림 UI
    <!-- Best Practice Tree -->
    - Update Notification
      - Display
        - 비침습적 배너 또는 다이얼로그
        - 버전 정보 및 변경 사항
      - Actions
        - 지금 다운로드
        - 나중에 알림
        - 이 버전 건너뛰기
      - Persistence
        - 알림 무시 설정 저장
        - 강제 업데이트 지원 (필요시)
  - [ ] 자동 업데이트 (선택적)
    <!-- Best Practice Tree -->
    - Auto Update
      - Download
        - 백그라운드 다운로드
        - 진행률 표시
      - Installation
        - 앱 종료 후 설치
        - 롤백 메커니즘
      - Platform
        - macOS: Sparkle 프레임워크 고려
        - Windows: 자체 구현 또는 Squirrel

- [ ] 사용자 피드백 수집 #feedback !low
  - [ ] 피드백 전송 기능
    <!-- Best Practice Tree -->
    - Feedback Submission
      - UI
        - Help > Send Feedback 메뉴
        - 간단한 폼
      - Content
        - 제목, 설명
        - 카테고리 (버그/제안/기타)
      - Delivery
        - 이메일 또는 GitHub Issue
        - 시스템 정보 첨부 (동의 시)
  - [ ] 버그 리포트 템플릿
    <!-- Best Practice Tree -->
    - Bug Report Template
      - Fields
        - 재현 단계
        - 예상 동작 vs 실제 동작
        - 환경 정보
      - Auto-fill
        - OS 버전
        - 앱 버전
        - 시스템 정보
      - Attachment
        - 스크린샷 첨부 옵션
        - 로그 파일 첨부 (동의 시)
  - [ ] 기능 요청 수집 채널
    <!-- Best Practice Tree -->
    - Feature Requests
      - Channel
        - GitHub Discussions
        - 커뮤니티 포럼
      - Voting
        - 반응 이모지 투표
        - 우선순위 참고
      - Communication
        - 요청 상태 업데이트
        - 구현 시 알림

## Review

## Done
