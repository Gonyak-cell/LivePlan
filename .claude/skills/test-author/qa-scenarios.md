배포 전 수동 QA 체크리스트(Phase 1)

위젯(잠금화면)

위젯 추가(직사각/인라인 중 최소 1)

태스크 완료 후 위젯 카운트/Top N 반영 확인(즉시 반영 보장 X)

pinned 변경 후 스코프 전환 확인

빈 상태 문구 확인

Live Activity

시작/갱신/종료 동작 확인

표시가 “요약 + 1개 핵심”을 넘지 않는지

privacyMode 레벨별 노출 확인

단축어

RefreshLiveActivity 단축어 수동 실행 확인

반복 실행(2~3회)에도 상태 꼬임 없음(멱등성)

프라이버시

privacyMode Level 1(기본)에서 제목 마스킹 확인

Level 0에서 원문 노출 확인(길이 제한 포함)

Level 2에서 카운트 중심 표시 확인