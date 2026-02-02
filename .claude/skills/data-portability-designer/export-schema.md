Export JSON 스키마(권장)

exportVersion: Int

appName: "LivePlan"

exportedAt: ISO8601

schemaVersion: Int (원 데이터 스키마)

payload:

settings

projects[]

tasks[]

completionLogs[] (선택)

원칙

exportVersion과 schemaVersion을 분리(내보내기 포맷 vs 내부 스키마)

개인 정보 최소, 암호화는 Phase 2에서 검토
