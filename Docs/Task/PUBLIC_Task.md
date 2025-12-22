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

