기능×테스트 매트릭스(Phase 1)

데이터 모델/완료

oneOff 완료 → AppCore 단위 테스트(B1)

dailyRecurring 오늘 완료 → AppCore 단위 테스트(B2)

dailyRecurring 다음날 리셋 → AppCore 단위 테스트(B3/B4)

dateKey

자정 경계 → DateKeyTests(B4)

타임존 변경 최소 방어 → DateKeyTests(B5)

잠금화면 선정

pinnedFirst 폴백 → SelectionTests(B6)

Top N/카운트 → SelectionTests(계약)

privacyMode 출력 → PrivacyMaskingTests(B7)

저장/마이그레이션

Round-trip → StorageRoundTripTests

schemaVersion n→n+1 → StorageMigrationTests

손상/로드 실패 폴백 → StorageFailSafeTests

인텐트

Refresh: 멱등성/폴백 → IntentContractTests

CompleteNextTask: displayList[0] 정합성 → IntentContractTests

QuickAdd: 기본 프로젝트 정책 → IntentContractTests