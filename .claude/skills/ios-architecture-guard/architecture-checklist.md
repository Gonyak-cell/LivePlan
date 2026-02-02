체크리스트: iOS 아키텍처/경량화 가드

레이어 의존 방향(architecture.md)

AppCore가 SwiftUI/WidgetKit/ActivityKit/AppIntents/UIKit를 import 했는가? (하면 BLOCKER)

Extensions/Intents가 AppCore가 아닌 다른 레이어(예: App/UI, AppStorage 구현체)에 직접 의존하는가? (하면 MAJOR)

도메인 규칙(반복/선정)이 UI/확장에 중복 구현되었는가? (하면 MAJOR)

데이터 모델/저장(data-model.md)

schemaVersion 증가가 필요한 변경인가?

CompletionLog 유니크 제약(taskId+dateKey)이 깨질 가능성이 있는가?

스냅샷/캐시 도입 시 정합성 테스트가 추가되는가?

잠금화면 표면(lockscreen.md)

Top N/카운트 정의가 바뀌었는가? (선정/인텐트 대상과 동기화 필수)

privacyMode 기본값/마스킹 레벨이 깨지는 노출이 있는가? (민감정보 원문 노출은 MAJOR 이상)

확장 타깃 성능(performance.md)

확장에서 무거운 IO/연산/로그 장기 스캔이 있는가? (MAJOR)

네트워크 호출이 있는가? (Phase 1에서는 BLOCKER)

폴링/타이머가 있는가? (BLOCKER)

JSON decode/encode가 반복되는가? (WARN~MAJOR; 캐시/스냅샷 고려)

보호 파일(architecture.md)

entitlements/Info.plist/project.pbxproj 수정이 필요한가?

별도 커밋 분리 여부

사유/영향/복구방법 기록 여부

외부 의존성(performance.md)

신규 패키지/SDK 추가인가?

대안 비교가 있는가?

용량/성능/유지보수 영향이 평가되었는가?

제거 플랜이 있는가?

테스트(testing.md)

반복/리셋 최소 회귀 세트(B1~B7)가 유지되는가?

lockscreen 선정 알고리즘 계약 테스트가 업데이트되는가?

인텐트(CompleteNextTask) 대상 일치성이 테스트되는가?