# History - 2025-12-25

> AI 작업 로그 - Task/SubTask 완료 기록

---

| 시간 | 태스크 제목 | 회고 |
|------|------------|------|
| 18:59 | Export 기능 구현 (애니메이션/폰트/9-Slice 데이터 처리) | AnimationSequence→JSON 변환, 9-Slice 메타데이터 포함, BMFont .fnt 생성, 미리보기 통계 표시 구현 완료 |
| 19:45 | 텍스처 압축 포맷 설정 기능 구현 | PNG/JPEG 포맷 선택, 품질 슬라이더, 예상 파일 크기 표시, JPEG 알파 채널 처리 구현 완료 |
| 20:15 | Export 프리뷰 패널 실제 이미지 렌더링 | img.Image→ui.Image 변환, CustomPaint 렌더링, 디바운스 300ms, 체커보드 배경, 로딩 인디케이터 구현 완료 |
| 21:30 | Export 다이얼로그 4개 버그 수정 | (1) sourceId null fallback 처리 (2) 파일명 초기값 빈 문자열 (3) ETC2 포맷 iOS 호환 필터링 (4) 포맷 변경 시 프리뷰 갱신 추가 |
