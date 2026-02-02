현재 확정 스펙(Phase 1 기준선)

모델

dailyRecurring은 “템플릿+로그 방식”을 사용한다.

템플릿: Task(type=dailyRecurring)

로그: CompletionLog(taskId, dateKey, completedAt)

매일 인스턴스 생성(날짜별 Task 복제)은 Phase 1에서 금지.

완료 의미

oneOff: CompletionLog 1회 존재하면 영구 완료(미완료에서 제거).

dailyRecurring: “오늘(dateKey)”에 CompletionLog가 있으면 오늘만 완료. 다음 날에는 자동 미완료(계산).

dateKey

dateKey = 사용자(기기) 타임존 기준 YYYY-MM-DD.

Phase 1의 day boundary는 자정(00:00) 고정.

타임존 변경/DST는 “현재 타임존 기준” 계산으로 처리(크래시/중복 로그 금지).

전날 미체크 처리

전날 미체크가 다음 날로 누적되지 않는다(표시 관점 리셋).

실패 로그(미체크 기록)는 Phase 1에서 저장하지 않는다(Phase 2 후보).

정합성

lockscreen 선정(displayList)과 CompleteNextTask 대상은 동일한 선정 로직을 사용한다.

[파일: .claude/skills/recurrence-engine/recurrence-testcases.md]

필수 회귀 테스트(Phase 1 최소 세트; testing.md B1~B7과 동일 의미)

R1 oneOff 완료(영구 제거)

완료 후 outstanding에서 제거, 카운트 감소, 중복 완료에도 안전

R2 dailyRecurring 완료(당일만 완료)

오늘 완료 후 오늘 outstanding에서 제거, (taskId, dateKey) 중복 로그 금지

R3 dailyRecurring 날짜 변경 리셋

전날 미완료가 누적되지 않음

다음 날에는 다시 미완료로 등장(계산상)

R4 자정 경계

23:59와 00:01에서 dateKey가 전환

전환 후 완료 여부 판단이 새 dateKey로 수행

R5 타임존 변경 최소 방어

타임존 변경해도 크래시/중복 로그/불변식 파괴 없음

R6 pinned 유무 폴백

pinned 없거나 archived면 todayOverview로 폴백

R7 privacyMode 출력 규칙

Level 0/1/2에 따른 제목/카운트 출력이 규칙과 동일