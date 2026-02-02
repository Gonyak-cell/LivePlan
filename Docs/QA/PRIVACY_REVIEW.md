# P2-M8-06 프라이버시/권한 최종 검토

**검토일**: 2026-02-02
**검토자**: ____________________

---

## 1. Info.plist 권한 문구 검토

### 1.1 메인 앱 (LivePlan/Info.plist)

| 권한 키 | 현재 상태 | 필요 여부 | 판정 |
|---------|----------|----------|------|
| NSSupportsLiveActivities | `true` | ✅ 필요 | ✅ OK |
| 카메라/마이크/위치 등 | 없음 | 불필요 | ✅ OK |
| 백그라운드 모드 | 없음 | 불필요 | ✅ OK |

**결론**: 앱에서 사용하는 유일한 권한 관련 설정은 Live Activities 지원이며, 별도 권한 요청 문구가 필요하지 않습니다.

### 1.2 위젯 Extension (LivePlanWidgetExtension/Info.plist)

| 항목 | 현재 상태 | 판정 |
|------|----------|------|
| NSExtensionPointIdentifier | com.apple.widgetkit-extension | ✅ OK |
| 추가 권한 | 없음 | ✅ OK |

### 1.3 인텐트 Extension (LivePlanIntents/Info.plist)

| 항목 | 현재 상태 | 판정 |
|------|----------|------|
| NSExtensionPointIdentifier | com.apple.appintents-extension | ✅ OK |
| 추가 권한 | 없음 | ✅ OK |

---

## 2. App Privacy 표기 확인 (App Store Connect)

### 2.1 수집 데이터 분류

| 데이터 유형 | 수집 여부 | 용도 | 판정 |
|------------|----------|------|------|
| 사용자 콘텐츠 (태스크/프로젝트) | ❌ 수집 안 함 | 로컬 저장만 | ✅ |
| 분석/통계 | ❌ 수집 안 함 | - | ✅ |
| 광고 | ❌ 수집 안 함 | - | ✅ |
| 식별자 | ❌ 수집 안 함 | - | ✅ |
| 위치 | ❌ 수집 안 함 | - | ✅ |
| 연락처/이메일 | ❌ 수집 안 함 | - | ✅ |
| 건강/금융 | ❌ 수집 안 함 | - | ✅ |

### 2.2 App Store Connect 표기

**권장 표기**: "Data Not Collected"

모든 데이터는 기기에만 저장되며 서버로 전송되지 않습니다.

---

## 3. 민감정보 로그 제거 확인

### 3.1 확인 항목

| 항목 | 확인 방법 | 상태 |
|------|----------|------|
| 프로젝트/태스크 제목 로깅 | 코드 검색: `print`, `os_log`, `Logger` | ☐ 확인 필요 |
| 완료 로그 내용 로깅 | 코드 검색 | ☐ 확인 필요 |
| 사용자 설정 로깅 | 코드 검색 | ☐ 확인 필요 |

### 3.2 검색 명령어 (Mac에서 실행)

```bash
# 민감정보 로그 검색
grep -r "print(" LivePlan/ --include="*.swift" | grep -v "Test"
grep -r "os_log" LivePlan/ --include="*.swift"
grep -r "Logger" LivePlan/ --include="*.swift"
```

### 3.3 허용되는 로그

- 디버그 빌드에서만 활성화되는 로그
- 태스크 ID, 프로젝트 ID 등 식별자만 포함 (제목 제외)
- 에러 스택 트레이스 (민감정보 미포함 확인 필요)

---

## 4. 프라이버시 기본값 확인

### 4.1 product-decisions.md 준수

| 규칙 | 현재 구현 | 판정 |
|------|----------|------|
| 기본 프라이버시 레벨 Level 1 (Masked) | ☐ 확인 필요 | |
| Level 1/2에서 원문 제목 노출 금지 | ☐ 확인 필요 | |
| 인텐트 메시지에서 원문 노출 금지 (Level 1/2) | ☐ 확인 필요 | |

### 4.2 확인 코드 위치

- `AppSettings.swift`: `privacyMode` 기본값
- `OutstandingComputer.swift`: 마스킹 로직
- 각 Intent 파일: 메시지 생성 로직

---

## 5. App Group 컨테이너 확인

### 5.1 공유 데이터 보호

| 항목 | 설정 | 판정 |
|------|------|------|
| App Group ID | group.com.liveplan.shared | ✅ OK |
| 공유 데이터 암호화 | iOS 기본 보호 (파일 시스템 암호화) | ✅ OK |
| 접근 권한 | 앱 + 확장만 접근 가능 | ✅ OK |

---

## 6. 최종 체크리스트

### 배포 전 필수 확인

- [ ] Info.plist에 불필요한 권한 없음
- [ ] App Store Connect에 "Data Not Collected" 표기 예정
- [ ] 민감정보 로그가 릴리즈 빌드에서 비활성화됨
- [ ] 프라이버시 기본값 Level 1 확인
- [ ] 인텐트 메시지 프라이버시 준수 확인

### 검토 결과

- [ ] **통과** - 모든 항목 확인 완료
- [ ] **조건부 통과** - 일부 수정 필요 (아래 기재)
- [ ] **실패** - 심각한 문제 발견

### 수정 필요 사항

```
[수정 필요 사항을 여기에 기재]
```

---

**검토자 서명**: ____________________
**검토 완료일**: ____________________
