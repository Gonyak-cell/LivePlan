결정론적 tie-breaker 카탈로그(Phase 1)

TB1: dueDate 오름차순(가장 이른 마감이 먼저)
TB2: createdAt 오름차순(먼저 만든 항목이 먼저)
TB3: stableKey 오름차순(id 기반 안정 정렬; createdAt이 없을 때)
TB4: type 우선순위(oneOff 먼저 또는 dailyRecurring 먼저) — 필요 시에만

권장 기본

dueDate 있는 항목: TB1

dueDate 없는 항목: TB2, 없으면 TB3

타입은 별도 우선순위 그룹으로 이미 처리하므로, tie-breaker에서 타입을 다시 쓰지 않는 것을 권장
