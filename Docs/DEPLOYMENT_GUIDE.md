# LivePlan 2.0 배포 가이드

**버전**: 2.0.0
**작성일**: 2026-02-02

---

## 목차

1. [사전 준비](#1-사전-준비)
2. [빌드 및 아카이브](#2-빌드-및-아카이브)
3. [TestFlight 배포](#3-testflight-배포)
4. [App Store 제출](#4-app-store-제출)
5. [제출 후 체크리스트](#5-제출-후-체크리스트)

---

## 1. 사전 준비

### 1.1 필수 완료 항목

- [ ] 모든 테스트 통과 (AppCoreTests, AppStorageTests)
- [ ] 수동 QA 완료 (PHASE2_FULL_QA_CHECKLIST.md)
- [ ] 프라이버시/권한 검토 완료 (PRIVACY_REVIEW.md)
- [ ] 스크린샷 7장 촬영 완료
- [ ] App Review Notes 최종 확인

### 1.2 프로젝트 설정 확인

```bash
# XcodeGen으로 프로젝트 재생성
cd /path/to/LivePlan
xcodegen generate
```

### 1.3 버전 확인

| 항목 | 값 |
|------|-----|
| MARKETING_VERSION | 2.0.0 |
| CURRENT_PROJECT_VERSION | 1 (빌드 번호) |
| Bundle ID | com.liveplan.LivePlan |

---

## 2. 빌드 및 아카이브

### 2.1 Release 빌드 설정

```bash
# 프로젝트 열기
open LivePlan.xcodeproj

# 또는 xcodebuild로 아카이브
xcodebuild archive \
  -project LivePlan.xcodeproj \
  -scheme LivePlan \
  -configuration Release \
  -archivePath build/LivePlan.xcarchive
```

### 2.2 Archive 전 체크리스트

- [ ] Scheme을 "LivePlan"으로 선택
- [ ] Configuration을 "Release"로 설정
- [ ] Signing Team 확인
- [ ] Product > Archive 실행

### 2.3 Archive 성공 확인

- [ ] Organizer에서 아카이브 확인
- [ ] 앱 아이콘 정상 표시
- [ ] 버전/빌드 번호 확인

---

## 3. TestFlight 배포

### 3.1 App Store Connect 업로드

1. Organizer에서 아카이브 선택
2. "Distribute App" 클릭
3. "App Store Connect" 선택
4. "Upload" 선택
5. 배포 옵션 확인:
   - [ ] Include bitcode: No (iOS 16+ 권장)
   - [ ] Upload symbols: Yes
6. 업로드 완료 대기

### 3.2 App Store Connect 설정

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. "My Apps" > "LivePlan" 선택
3. "TestFlight" 탭 이동

### 3.3 TestFlight 테스터 설정

#### 내부 테스터 (App Store Connect 사용자)

- [ ] 테스터 그룹 생성/선택
- [ ] 빌드 할당
- [ ] 테스트 안내 문구 입력

#### 외부 테스터 (선택)

- [ ] 베타 앱 심사 제출 필요
- [ ] 테스터 이메일 추가
- [ ] 테스트 안내 문구 입력

### 3.4 TestFlight 릴리즈 노트

```
LivePlan 2.0.0 (빌드 1)

테스트 포인트:
1. 보드 뷰에서 태스크 상태 변경
2. 캘린더 뷰에서 날짜별 태스크 확인
3. 우선순위(P1~P4) 설정 및 표시
4. 필터 생성/저장/적용
5. 잠금화면 위젯 표시 확인
6. 프라이버시 모드 토글

알려진 이슈:
- 위젯은 iOS 정책상 즉시 갱신되지 않습니다

피드백: [피드백 URL]
```

---

## 4. App Store 제출

### 4.1 메타데이터 입력

App Store Connect > "App Store" 탭

#### 버전 정보

| 항목 | 값 |
|------|-----|
| Version | 2.0.0 |
| Copyright | © 2026 [Your Name/Company] |

#### 앱 설명 (KR)

> Docs/AppStoreDescription_KR.md 내용 복사

#### 앱 설명 (EN)

> Docs/AppStoreDescription_EN.md 내용 복사

#### 새로운 기능 (KR)

> Docs/ReleaseNotes_2.0.md의 "App Store 새로운 기능" 섹션 복사

#### 새로운 기능 (EN)

> Docs/ReleaseNotes_2.0.md의 "App Store What's New" 섹션 복사

### 4.2 스크린샷 업로드

> Docs/SCREENSHOT_STORYBOARD.md 참조

- [ ] 6.9" (iPhone 16 Pro Max) - 7장
- [ ] 6.3" (iPhone 16 Pro) - 7장
- [ ] 6.7" (iPhone 15 Plus) - 7장
- [ ] (선택) 6.1" (iPhone 15) - 7장

### 4.3 App Review Notes 입력

> Docs/AppReviewNotes.md 전체 내용 복사

### 4.4 App Privacy 설정

- [ ] "Data Not Collected" 선택
- [ ] 개인정보 처리방침 URL 입력 (필요시)

### 4.5 가격 및 배포

- [ ] 가격: 무료
- [ ] 배포 국가 선택 (한국, 미국 등)
- [ ] 자동 릴리즈 vs 수동 릴리즈 선택

### 4.6 최종 제출

1. 모든 필드 확인
2. "Submit for Review" 클릭
3. 수출 규정 준수 확인:
   - [ ] 암호화 사용: No (또는 해당시 Yes)
   - [ ] IDFA 사용: No
4. 제출 완료

---

## 5. 제출 후 체크리스트

### 5.1 심사 상태 모니터링

- 상태: "Waiting for Review" → "In Review" → "Ready for Sale"
- 예상 심사 기간: 1-3일

### 5.2 리젝 대응 준비

| 일반적인 리젝 사유 | 대응 |
|------------------|------|
| Guideline 2.1 - App Completeness | 재현 단계 상세화 |
| Guideline 4.2 - Minimum Functionality | 기능 설명 보완 |
| Guideline 5.1.1 - Data Collection | Privacy Policy 업데이트 |

### 5.3 릴리즈 후 작업

- [ ] App Store 페이지 확인
- [ ] 첫 리뷰 모니터링
- [ ] 크래시 리포트 확인 (App Store Connect)

---

## 부록: 명령어 요약

### 테스트 실행

```bash
# AppCore 테스트
cd AppCore && swift test

# AppStorage 테스트
cd AppStorage && swift test

# 전체 프로젝트 테스트
xcodebuild test \
  -project LivePlan.xcodeproj \
  -scheme LivePlan \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### 아카이브 및 업로드

```bash
# Archive
xcodebuild archive \
  -project LivePlan.xcodeproj \
  -scheme LivePlan \
  -configuration Release \
  -archivePath build/LivePlan.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/LivePlan.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Upload via altool (deprecated) or transporter
xcrun altool --upload-app \
  -f build/export/LivePlan.ipa \
  -t ios \
  -u "YOUR_APPLE_ID" \
  -p "APP_SPECIFIC_PASSWORD"
```

---

## 문서 링크

- [AppStoreDescription_KR.md](./AppStoreDescription_KR.md)
- [AppStoreDescription_EN.md](./AppStoreDescription_EN.md)
- [ReleaseNotes_2.0.md](./ReleaseNotes_2.0.md)
- [AppReviewNotes.md](./AppReviewNotes.md)
- [SCREENSHOT_STORYBOARD.md](./SCREENSHOT_STORYBOARD.md)
- [QA/PHASE2_FULL_QA_CHECKLIST.md](./QA/PHASE2_FULL_QA_CHECKLIST.md)
- [QA/PRIVACY_REVIEW.md](./QA/PRIVACY_REVIEW.md)

---

*이 문서는 appstore-submission.md 규칙을 따릅니다.*
