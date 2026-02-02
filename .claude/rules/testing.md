목적

본 문서는 “Lock-screen-first 프로젝트/태스크 앱”의 테스트 전략(계층/필수 케이스/수동 QA/회귀 방지 규칙)을 고정하는 단일 기준(규칙) 문서입니다.

구현자는(Claude Code 포함) 본 문서의 MUST/MUST NOT 규칙을 우선 준수합니다. 데이터 모델/불변식은 data-model.md, 잠금화면 표시/우선순위 규칙은 lockscreen.md, 인텐트 계약은 intents.md, 모듈 경계는 architecture.md를 따릅니다.

적용 범위

AppCore 단위 테스트(최우선)

AppStorage 저장/마이그레이션 테스트

잠금화면 선정 알고리즘 테스트(순수 함수 기반)

App Intents 계약 테스트(가능 범위)

배포 전 수동 QA(위젯/Live Activity/단축어/프라이버시)

핵심 원칙(요약)

AppCore 규칙이 “정답”이며, 반드시 단위 테스트로 잠근다.

반복/리셋(dateKey)은 가장 높은 회귀 위험이므로, 테스트 케이스를 최소 세트로 고정한다.

잠금화면 표시 대상 선정은 “순수 함수”로 설계하여 테스트 가능해야 한다(로직이 UI/확장에 흩어지면 실패).

Storage는 round-trip + schemaVersion 마이그레이션을 테스트로 고정한다.

버그 수정은 재현 테스트부터(테스트 없이 버그 수정 금지).

비목표(Non-goals)

Phase 1에서는 UI 스냅샷 테스트를 필수로 강제하지 않는다(유지보수 비용이 큼).

Phase 1에서는 네트워크/서버 테스트가 없다(서버 기능 자체가 비목표).

Phase 1에서는 모든 확장(위젯/Live Activity)의 UI 픽셀 단위 검증을 하지 않는다(대신 “표시 데이터 계약”을 테스트한다).

용어 정의(최소)

Unit Test: AppCore의 순수 로직 검증

Contract Test: “입력 → 출력 DTO/문구/카운트”가 규칙을 만족하는지 검증

dateKey: 사용자 타임존 기준 YYYY-MM-DD(정의는 data-model.md)

Outstanding: “오늘 기준 잠금화면에 떠야 하는 미완료 후보” 계산 결과

DoD: Definition of Done(기능 완료 기준)

결정 필요(Open decisions)

iOS 최소 지원 버전(iOS 17 포함 vs iOS 18+ 중심)

dueSoon/overdue 기준(시간 기반 vs 날짜 기반)에 따른 테스트 케이스 범위

privacyMode 레벨 수(2 vs 3)에 따른 출력 테스트 범위

Storage 포맷(JSON 파일 vs CoreData) 선택(Phase 1 권장: JSON)

변경 시 파급효과(필수 동반 수정)

dateKey 규칙 변경 → B 섹션(반복/리셋) 테스트 전면 업데이트 필수

잠금화면 우선순위 변경 → 선정 알고리즘 테스트 + 인텐트 CompleteNextTask 테스트 동시 업데이트

저장 스키마 변경(schemaVersion 증가) → 마이그레이션 테스트 추가/수정 필수

────────────────────────────────────────
A. 테스트 계층(무엇을 어디까지 테스트할지)
────────────────────────────────────────

A1. AppCore 단위 테스트(필수, 최우선)
목표

데이터 모델 불변식과 핵심 규칙(완료/반복/리셋/선정)을 테스트로 잠근다.

확장(위젯/인텐트)이 늘어나도 AppCore가 흔들리지 않게 한다.

범위(필수 포함)

Project/Task/CompletionLog의 의미적 규칙

oneOff 완료 처리(영구 완료)

dailyRecurring 완료 처리(당일만 완료)

dateKey 계산 및 리셋(표시 기준)

outstanding 계산(잠금화면 후보 선정 결과: displayList/counters)

금지

UI 프레임워크 import(테스트 대상이 AppCore인 경우)

테스트에서 파일 IO/실제 App Group 컨테이너 접근(가능하면 인메모리 저장소로 대체)

권장 구조

AppCoreTests

DateKeyTests

CompletionRulesTests

RecurrenceRulesTests

OutstandingSelectionTests

PrivacyMaskingTests

A2. Storage 테스트(라운드트립/마이그레이션)
목표

저장-로드가 데이터 손실 없이 왕복되는지 확인하고, 스키마 버전 변경 시 마이그레이션이 안전한지 검증한다.

필수 테스트

Round-trip

주어진 Snapshot(Projects/Tasks/Logs/Settings)을 저장 후 다시 로드하여 동일성을 확인

최소 케이스: 빈 상태, 단일 프로젝트+태스크, 반복 태스크+로그 포함

손상/읽기 실패 안전성

디코딩 실패/파일 없음 시 크래시 금지

안전 폴백(빈 상태 또는 “앱에서 복구 안내”)로 동작하는지

마이그레이션

schemaVersion n의 샘플 데이터를 로드하면 n+1로 변환되는지

변환 후 불변식(중복 로그 없음 등)이 유지되는지

권장 방식

저장 테스트는 실제 파일 시스템 대신 “테스트용 임시 디렉터리” 또는 “인메모리 파일 추상화”를 사용한다.

App Group 컨테이너 경로는 테스트에서 직접 사용하지 않는다(환경 의존성 제거).

A3. Lock screen selection 알고리즘 테스트(순수 함수 기반)
목표

lockscreen.md의 우선순위 정책이 코드에 정확히 반영되었는지 계약 테스트로 검증한다.

전제(강행)

선정 알고리즘은 “순수 함수”로 설계되어야 테스트가 가능하다(architecture.md).

입력: dateKey, pinnedProjectId, privacyMode, selectionPolicy, projects/tasks/logs

출력: displayList(Top N), counters, metadata

필수 검증 포인트

Top N 정책이 준수되는지(예: 3개 + remaining 카운트)

우선순위 순서가 고정대로 동작하는지(핀 우선, 임박/지연, 반복 등)

privacyMode에 따라 출력 문자열이 마스킹 규칙을 따르는지

A4. Intents 테스트(가능 범위 내 계약 테스트)
목표

인텐트가 AppCore 규칙을 위반하지 않고, 멱등성/폴백 정책을 지키는지 검증한다.

권장 접근

“인텐트 자체의 런타임 실행”이 환경에 따라 복잡할 수 있으므로, Phase 1에서는 다음을 우선한다.

인텐트가 호출하는 use-case의 결과를 테스트(AppCore 테스트로 흡수)

인텐트 어댑터 로직(파라미터 해석/폴백/메시지)을 얇게 만들고, 해당 부분을 별도 테스트로 검증(가능하면)

필수 검증 포인트

RefreshLiveActivity: 데이터 변경 없이 표시 상태 갱신, 멱등성 유지

CompleteNextTask: lockscreen.md의 displayList 1순위를 완료 대상으로 삼는지

QuickAddTask: 기본 프로젝트 정책(인박스 vs pinned)을 일관되게 적용하는지

실패 메시지: 짧고 안전한 문구, 크래시 금지

────────────────────────────────────────
B. “반복/리셋” 필수 테스트 케이스(체크리스트)
────────────────────────────────────────

본 섹션의 테스트는 “삭제/축소 금지”의 최소 회귀 세트다.
(수정은 가능하나, 동등 이상의 보호를 제공해야 한다.)

B1. oneOff 완료 처리(영구 제거)

Given: oneOff 태스크 1개(미완료)

When: 완료 처리(CompletionLog 생성)

Then:

outstanding 목록에서 해당 태스크가 제거된다

counters(outstandingTotal)가 1 감소한다

중복 완료 호출 시에도 상태가 깨지지 않는다(멱등성)

B2. dailyRecurring 완료 처리(당일만 완료)

Given: dailyRecurring 태스크 1개, dateKey=오늘, 완료 로그 없음

When: 오늘 dateKey로 완료 처리(CompletionLog 생성)

Then:

오늘 outstanding에서 제거된다

recurringDone 증가, recurringTotal 유지

같은 dateKey로 중복 완료 호출 시 로그가 중복 생성되지 않는다(유니크)

B3. dailyRecurring 미완료로 날짜 변경 시 “표시에만 리셋”

Given: dailyRecurring 태스크 1개, 전날 dateKey에 완료 로그 없음

When: dateKey를 “다음 날”로 변경하여 outstanding 계산

Then:

전날 미완료가 누적되어 남지 않는다(전날 인스턴스 개념 없음)

다음 날에는 “당일 미완료”로 다시 등장한다(계산상)

추가: 전날에 완료 로그가 있었더라도, 다음 날에는 다시 미완료로 등장한다

B4. 자정 경계(23:59 / 00:01)

Given: 동일한 절대 시간 흐름에서 로컬 타임존 기준으로

23:59의 dateKey와 00:01의 dateKey가 다르게 계산되는지

Then:

dateKey 전환이 정확히 발생한다

전환 이후 dailyRecurring의 완료 여부 판단이 “새 dateKey”로 수행된다

B5. 타임존 변경 시 dateKey 정책(최소 방어)

Given: 동일한 절대 시각에서 TimeZone A와 B로 dateKey를 계산

Then:

정책대로 dateKey가 달라질 수 있음을 허용(단, 크래시/중복 로그 생성 금지)

(taskId, dateKey) 유니크 제약이 깨지지 않는다

최소 목표: 타임존 변경이 있어도 “오늘 완료 여부” 계산이 안정적으로 동작(예외/충돌 없이)

B6. pinned project 유무 케이스

Given: pinnedProjectId가 있는 경우/없는 경우

Then:

pinned가 있으면 pinned 스코프 우선(정책이 pinnedFirst일 때)

pinned가 없으면 todayOverview로 폴백

pinned가 archived/completed면 today로 폴백(폴백 사유 확인 가능)

B7. privacyMode에 따른 출력 문자열/표시 정책

Given: 동일한 도메인 상태에서 privacyMode Level 0/1/2

Then:

Level 0: 제목 원문(길이 제한/말줄임은 적용)

Level 1: 프로젝트명 숨김 + 태스크명 축약/익명화

Level 2: 제목 미노출, 카운트/진척률만

특히 “CompleteNextTask의 반환 메시지”도 privacyMode 규칙을 준수해야 한다.

────────────────────────────────────────
C. 수동 QA 시나리오(배포 전 필수)
────────────────────────────────────────

목적

시스템 표면(위젯/Live Activity/단축어/프라이버시)은 자동 테스트로 완전 대체가 어렵다.

따라서 배포 전에는 아래 수동 시나리오를 “항상 수행”한다.

C1. 위젯 표시/갱신
준비

프로젝트 1개(핀 설정), 태스크 5개(1~2개는 dueDate 포함), 반복 태스크 2개
절차

잠금화면에 위젯 추가(직사각/인라인 중 최소 1개)

앱에서 태스크 1개 완료 처리

위젯이 즉시 갱신되지 않더라도, 일정 시간/재진입 후 갱신되는지 확인

pinnedProjectId를 변경하고 위젯 표시 스코프가 바뀌는지 확인
체크

Top N/카운트 표시가 lockscreen.md 정책과 일치

빈 상태/프로젝트 없음 상태에서도 크래시 없음

C2. Live Activity 시작/갱신/종료
절차

Live Activity 시작(앱 내부 버튼 또는 인텐트/단축어로)

RefreshLiveActivity 인텐트 실행(수동)

표시 모드(pinnedSummary/todaySummary 등)가 의도대로 반영되는지 확인

Live Activity 종료 후 폴백(위젯 요약)만으로 핵심 가치 유지되는지 확인
체크

표시 내용이 “요약 + 1개 핵심”을 넘지 않음

프라이버시 모드에서 제목 원문 노출이 제한됨

C3. 단축어(RefreshLiveActivity) 실행
절차

단축어 앱에서 RefreshLiveActivity를 호출하는 단축어 생성

수동 실행으로 정상 동작 확인

(선택) 자동화 설정(8시간 주기 등) 적용 가능성 확인(사용자 안내 문구 필요 여부 판단)
체크

반복 실행해도 상태 꼬임 없음(멱등성)

데이터가 없을 때도 안전 메시지 반환

C4. 프라이버시 모드 토글 후 잠금화면 노출 확인
절차

privacyMode Level 1(기본)에서 잠금화면 표시 확인

Level 0으로 변경 후 제목 원문 노출 확인

Level 2로 변경 후 카운트 중심 표시 확인
체크

모든 표면(위젯/Live Activity/인텐트 메시지)이 동일한 프라이버시 규칙 준수

토글 후 “갱신 요청”은 수행하되, 위젯 즉시 반영을 약속하지 않음

────────────────────────────────────────
D. 회귀 방지 규칙
────────────────────────────────────────

D1. 규칙 변경 시 반드시 테스트 업데이트(강행)

data-model.md 또는 lockscreen.md의 규칙이 변경되면, 해당 규칙을 커버하는 테스트를 반드시 함께 수정/추가한다.

규칙 변경 커밋에는 최소 1개의 테스트 변경이 포함되어야 한다(예외 없음).

D2. bugfix는 “재현 테스트 먼저 작성”(강행)

버그가 보고/발견되면, 다음 순서를 고정한다.

재현 테스트 작성(현재는 실패해야 함)

수정 구현

테스트 통과 확인

“테스트 없이 버그만 수정” 금지.

D3. 슬라이스 단위 커밋(권장)

한 커밋은 하나의 기능 슬라이스만 포함한다.

테스트/코드/문서(해당 규칙 파일) 변경은 동일 슬라이스 커밋에 포함한다.

D4. 최소 회귀 세트 유지(강행)

B 섹션의 최소 회귀 세트는 삭제/무력화 금지.

테스트가 취약해진 경우(불안정/플레이키)는 “테스트를 안정화”하는 별도 슬라이스를 만든다.

끝.