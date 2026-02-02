목적

본 문서는 “Lock-screen-first 프로젝트/태스크 앱”의 아키텍처 경계와 의존성 규칙을 고정하는 단일 기준(규칙) 문서입니다.

구현자는(Claude Code 포함) 본 문서의 MUST/MUST NOT 규칙을 우선 준수합니다. 세부 데이터 규칙은 data-model.md, 잠금화면 표면 정책은 lockscreen.md, 인텐트 규칙은 intents.md를 따릅니다.

적용 범위

App(메인 앱 타깃), AppExtensions(Widget/Live Activity/Controls 타깃), AppIntents(인텐트 타깃), AppCore(도메인 모듈), AppStorage(영속화 모듈) 전반.

특히 “확장 타깃(Extensions)”과 “인텐트 타깃(Intents)”은 메인 앱과 다른 실행 컨텍스트이므로, 아래 규칙을 엄격히 적용합니다.

핵심 원칙(요약)

MUST: 도메인 로직은 AppCore에만 둔다.

MUST NOT: AppCore는 SwiftUI/WidgetKit/ActivityKit/AppIntents 등 UI·플랫폼 표현 프레임워크를 import 하지 않는다.

MUST: Extensions/Intents는 AppCore에만 의존한다(역의존 금지).

MUST: 저장소(영속화) 구현은 AppStorage에만 둔다(AppCore에는 프로토콜만 둔다).

MUST: 확장 타깃에서는 “표현 + 최소 호출”만 수행하고, 무거운 연산·대량 IO·폴링을 금지한다.

비목표(Non-goals)

Phase 1에서는 아래를 구현하거나 설계를 확정하지 않는다(추가 요구가 있더라도 기본적으로 보류).

협업(공유 프로젝트/팀/권한/멘션)

서버/계정 시스템(로그인/백엔드 동기화)

칸반 보드, 복잡한 프로젝트 템플릿/워크플로 엔진

대규모 첨부(파일/이미지 다량 업로드, 클라우드 스토리지 연동)

리치 텍스트/블록 기반 문서 편집(Notion 스타일)

위 비목표를 건드리는 변경은 “새 Phase 제안서(Plan 문서)”가 먼저 필요합니다.

용어 정의(최소)

AppCore: 프로젝트/태스크/반복/완료 로그 및 잠금화면 표시 후보 선정 로직(순수 도메인).

AppStorage: 로컬 저장(예: Codable JSON/파일) 및 마이그레이션, App Group 컨테이너 접근.

App(UI): SwiftUI 기반 사용자 UI(목록/생성/완료/설정).

Extensions: WidgetKit(잠금화면 위젯), ActivityKit(Live Activity), Controls(iOS 18+).

Intents: App Intents 및 Shortcuts/Controls에서 호출되는 액션 인터페이스.

Shared Container(App Group): 앱과 확장 타깃이 동일 데이터를 읽기 위해 사용하는 컨테이너.

결정 필요(Open decisions)

iOS 최소 지원 버전(iOS 17.x 고정 vs iOS 18+ 중심으로 Controls 적극 사용).

동기화 범위(Phase 2에서 iCloud/CloudKit 도입 여부).

프라이버시 기본값(잠금화면 마스킹 ON 고정 여부 및 레벨).

저장 포맷(단순 JSON 파일 vs CoreData 도입 여부 — 기본은 JSON 권장, CoreData는 Phase 2+에서만 검토).

변경 시 파급효과(필수 동반 수정)

AppCore의 엔티티/불변식 변경 → data-model.md 및 AppCoreTests 업데이트 필수.

잠금화면 표시 후보 선정 규칙 변경 → lockscreen.md 및 관련 테스트(선정 알고리즘 테스트) 업데이트 필수.

인텐트 추가/변경 → intents.md 및 단축어/컨트롤 사용 시나리오 문서 업데이트 필수.

저장 스키마 변경 → AppStorage 마이그레이션 및 저장-로드 회귀 테스트 업데이트 필수.

────────────────────────────────────────
A. 제품/기능 스코프 경계
────────────────────────────────────────

A1. Phase 1(현재) — 반드시 포함되는 기능

프로젝트(Project)

시작일(startDate) 필수, 마감일(dueDate)은 선택.

활성/보관/종료 등 상태는 최소 집합으로 운영(복잡한 워크플로 금지).

태스크(Task)

일반(one-off) + 매일 반복(daily recurring).

체크(완료) 동작:

일반: 완료되면 미완료 목록에서 영구 제거(완료 기록은 남김 가능).

매일 반복: “오늘분만” 완료 처리, 다음 날에는 자동으로 다시 미완료로 간주(표시 기준).

잠금화면 요약

Lock Screen 위젯: “요약 + Top N + 카운트” 중심.

Live Activity: “현재/핵심 1개 카드” 또는 “핀 프로젝트 요약” 중 하나로 제한.

프라이버시 기본값: 민감정보를 최소화(마스킹/카운트 중심).

단축어/인텐트

Live Activity 갱신용 Refresh 인텐트 제공(사용자가 자동화로 8시간 갱신 운영).

완료/빠른 추가 등 최소 액션만 제공.

A2. Phase 2+ 확장 후보(후속 단계에서만)

미루기(Snooze), “오늘만 숨김”, 지연(Overdue) 관리 강화

반복 규칙 확장(평일/주간/월간), day boundary 사용자 설정(예: 새벽 4시)

통계/리포트(연속 달성, 실패 로그 등)

iCloud/CloudKit 동기화(다기기)

검색(단, 인덱싱/서버는 금지. 로컬 경량 검색만)

A3. 금지/보류 기능(Phase 1에서는 하지 않음)

협업/공유/팀(권한 포함)

서버/계정/푸시 기반 작업 동기화(필요 시 Phase 3+에서 재검토)

칸반 보드/복잡한 워크플로(Asana급 기능)

대규모 첨부(파일 시스템/클라우드 스토리지 연동)

리치 텍스트/문서 편집(Notion 스타일)

과도한 SDK/분석 도구(앱 무게 증가 요인)

스코프 가드(강행 규칙)

새 기능 제안 시 반드시 “사용자 가치 1문장 + 유지보수 비용 + 잠금화면과의 관계”를 Plan에 포함.

“기능 하나 추가”가 아니라 “슬라이스 하나 추가(1커밋)”로만 진행.

────────────────────────────────────────
B. 타깃/모듈 구조(레이어드 아키텍처)
────────────────────────────────────────

B1. 모듈/타깃 구성(권장)

AppCore (도메인)

AppStorage (영속화 구현)

App (메인 UI 타깃)

AppExtensions

Widget Extension(잠금화면 위젯)

Live Activity Extension(잠금화면 카드)

Controls Extension(iOS 18+)

AppIntents (인텐트 타깃)

B2. 의존 방향 규칙(절대 규칙)

AppCore MUST NOT import:

SwiftUI, UIKit, WidgetKit, ActivityKit, AppIntents, UserNotifications 등 “표현/플랫폼 기능” 프레임워크.

AppStorage MAY import:

Foundation, OSLog 등 기본 프레임워크

파일 접근/컨테이너 접근을 위한 최소 API

App/UI, Extensions, Intents MAY import:

SwiftUI/WidgetKit/ActivityKit/AppIntents 등 필요 프레임워크

단, 도메인 판단은 AppCore 호출을 통해 수행

B3. 경계 분리 기준(무엇이 AppCore인가?)

AppCore에 둬야 하는 것(예시)

“오늘(dateKey) 기준 미완료 계산”

“매일 반복 완료 여부 판단”

“잠금화면 표시 후보 선정(우선순위/Top N)”

“완료 처리의 의미(일반 vs 반복)”

AppCore에 두면 안 되는 것(금지 예시)

위젯/라이브액티비티 UI 컴포넌트

단축어/컨트롤 등록 코드

권한 요청/알림 스케줄링

파일/DB 구현 상세(저장 경로, JSON 구조 등)

B4. “얇은” UI 원칙

UI는 상태를 “표현”하고, 사용자의 의도를 “명령(use-case 호출)”으로 변환한다.

UI는 도메인 규칙을 복제하지 않는다(동일 로직을 UI에 재구현 금지).

────────────────────────────────────────
C. 데이터 흐름(Data flow)
────────────────────────────────────────

C1. Write Path(쓰기 경로) — 표준 흐름(강제)

트리거(입력)

App(UI)에서 사용자 입력(프로젝트/태스크 생성, 완료 체크, 설정 변경)

Intents/Controls/Shortcuts에서 액션 호출(완료, 빠른 추가, 라이브액티비티 갱신)

처리

UI/Intents는 AppCore의 use-case를 호출한다.

AppCore는 변경된 도메인 상태를 계산한다(불변식 검증 포함).

AppCore는 AppStorage의 Repository 프로토콜을 통해 commit(저장)을 요청한다.

저장 성공 후, 필요 시 “표면 갱신 트리거”를 호출한다.

위젯: 시스템 제약이 있어 즉시 반영을 보장하지 않음(요약 중심 설계).

Live Activity: 갱신 인텐트 또는 앱 내부 트리거로 상태 업데이트.

C2. Read Path(읽기 경로) — 확장 타깃 기준

데이터 소스는 “Shared Container(App Group)”를 단일 진실원천으로 삼는다.

이유: 위젯/라이브액티비티/인텐트는 메인 앱과 별도 프로세스로 실행될 수 있음.

Extensions/Intents는 직접 도메인 판단을 하지 않고,

AppCore의 “순수 계산 함수”에 입력을 넣어 표시용 DTO(요약)를 얻는다.

읽기 실패/데이터 없음의 폴백

크래시 금지.

“빈 상태(미완료 0)” 또는 “앱 열기 유도” 같은 안전한 디폴트를 사용.

C3. 상태 동기화 전략(Phase 1 기준)

Phase 1에서는 로컬+App Group 공유만 확정.

iCloud/CloudKit은 Phase 2+에서 별도 설계 문서로 추가(본 문서에 섞지 않음).

────────────────────────────────────────
D. 저장소 경계(Repository/Service)
────────────────────────────────────────

D1. AppCore의 저장소 인터페이스(프로토콜) 원칙

AppCore는 아래만 알고 있어야 한다:

load/save API의 “의미” (예: loadAll(), save(snapshot))

저장 실패 시 도메인 레벨에서 어떻게 처리할지(에러 타입/재시도 여부)

AppCore는 아래를 몰라야 한다:

파일 경로/확장자/JSON 구조/마이그레이션 구현 상세

App Group 컨테이너 접근 코드

동시성/락/원자적 쓰기 구현

D2. AppStorage의 책임(구현체 전용)

저장 포맷, 파일 IO, 원자적 쓰기(atomic write), 오류 복구 정책

schemaVersion 관리 및 마이그레이션 함수

App Group 컨테이너 접근 및 확장 타깃과의 공유 규칙

D3. 동기화 정책(로컬 only vs iCloud)

Phase 1: 로컬 only(Shared Container 포함).

Phase 2+: iCloud를 도입하려면,

도메인 불변식에 미치는 영향(충돌 해결/병합 규칙)을 먼저 문서화하고 테스트로 잠금.

저장 포맷/마이그레이션/충돌 해결 전략을 별도 문서로 추가.

────────────────────────────────────────
E. 확장 타깃(Widget/Activity/Controls) 운영 원칙
────────────────────────────────────────

E1. “표현(View) + 최소 호출” 원칙(강행)

Extensions는 표시용 데이터(요약 DTO)를 읽고 렌더링만 한다.

Extensions 내부에 “복잡한 선정 알고리즘/반복 리셋 로직”을 직접 구현하지 않는다.

Controls는 “명령(완료/추가 등)”만 수행하고, 결과는 다음 갱신에 반영되는 것으로 설계한다.

E2. 무거운 연산/IO 금지

확장 타깃에서 금지되는 대표 행위

대용량 JSON 반복 디코딩/인덱싱

이미지/링크 프리뷰 생성(네트워크/무거운 처리) 상시 수행

타이머 기반 폴링

허용되는 행위

작은 상태 파일 1회 읽기 + 요약 계산(경량) + 렌더링

캐시된 요약 데이터 읽기

E3. 캐시/프리컴퓨트 정책(권장)

표시용 요약 데이터는 AppStorage 또는 App(UI)에서 “미리 계산된 스냅샷”으로 저장 가능.

단, “스냅샷은 파생 데이터”이므로, 원천(AppCore 상태)과 불일치 시 재생성 규칙을 둔다.

E4. 프라이버시/표시 최소화(기본값)

확장 타깃의 기본 표시값은 “마스킹/카운트 중심”.

사용자가 명시적으로 해제하지 않는 한, 프로젝트명/태스크명의 원문 노출을 최소화한다.

세부 규칙은 lockscreen.md를 우선 적용.

────────────────────────────────────────
F. 코딩 표준(최소)
────────────────────────────────────────

F1. 네이밍 규칙(권장)

AppCore 엔티티: Project, Task, RecurrenceRule, CompletionLog 등 명사형

Use-case: CompleteTaskUseCase, AddTaskUseCase, ComputeOutstandingUseCase 등 동사+명사

Repository 프로토콜: TaskRepository, ProjectRepository 등

DTO: LockScreenSummary, ProjectDigest 등 “표시 목적”이 명확한 이름

F2. 에러 처리 원칙

도메인 에러(AppCore)

불변식 위반, 입력 검증 실패, 논리적으로 불가능한 상태 등을 명확한 타입으로 정의

인프라 에러(AppStorage)

파일 IO 실패, 디코딩 실패, 마이그레이션 실패 등

UI 에러(App/UI, Extensions)

사용자 메시지로 변환 가능한 형태로만 취급

금지

UI에서 인프라 예외를 그대로 노출

AppCore에서 “사용자 문구”를 생성(표현 계층 침범)

F3. 로깅/진단(디버그 한정)

개발(디버그) 빌드에서만 verbose 로그 허용

릴리즈 빌드에서는 최소 로그(필요 시 OSLog의 레벨/카테고리 관리)

민감정보(프로젝트/태스크 제목 등)는 로그에 남기지 않는 것을 원칙으로 한다.

────────────────────────────────────────
G. 위험 변경(보호 파일) 정책
────────────────────────────────────────

G1. 보호 파일 목록(예시)

*.entitlements

Info.plist

project.pbxproj

Signing/Capabilities 관련 설정 파일

App Group/Extension 관련 설정이 포함된 Xcode 프로젝트 설정

G2. 변경 원칙(강행)

보호 파일 변경은 반드시 “별도 커밋 1개”로 분리한다.

커밋 메시지에 아래를 반드시 포함한다:

변경 사유(왜 필요한가)

영향 범위(어떤 타깃/권한/확장에 영향이 있는가)

복구 방법(되돌리기 지점, 주의사항)

보호 파일 변경을 동반하는 기능 구현 커밋과 섞지 않는다(리뷰/회귀 추적 불가).

G3. Claude Code 운영(훅 권장)

PreToolUse 훅으로 보호 파일 편집을 기본 차단하고, 명시 승인 시에만 허용하는 정책을 적용한다.

구체 설정은 .claude/settings.json 및 hooks 스크립트에서 관리한다(이 문서에서는 정책만 고정).

끝.