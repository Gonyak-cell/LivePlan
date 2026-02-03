---
name: playstore-release
description: Pre-release checklist for Google Play Store submission. Verifies privacy, permissions, versioning, and generates release notes.
tools: [Read, Grep, Glob]
---

## 목적

Google Play Store 제출 전 체크리스트를 검증하고, 릴리즈 노트 및 메타데이터를 생성한다.

## 언제 사용해야 하는가(트리거)

- 내부 테스트 트랙 배포 전
- 프로덕션 릴리즈 전
- 버전 업데이트 전

## 입력

- **$ARGUMENTS**: 버전 번호 또는 릴리즈 유형 (예: "v1.0.0", "bugfix release")

## 출력 포맷

```
## Play Store Release Checklist: [버전]

### Build Verification
- [ ] Debug 빌드 테스트 완료
- [ ] Release 빌드 생성 성공
- [ ] ProGuard/R8 적용 확인
- [ ] APK/AAB 서명 확인

### Version Check
| 항목 | 값 |
|------|-----|
| versionCode | [숫자] |
| versionName | [버전] |
| minSdk | [API 레벨] |
| targetSdk | [API 레벨] |

### Privacy & Permissions
- [ ] 불필요한 권한 없음
- [ ] Data Safety 섹션 정확함
- [ ] 개인정보처리방침 URL 유효

### QA Status
- [ ] 위젯 테스트 완료
- [ ] Quick Settings Tile 테스트 완료
- [ ] 프라이버시 모드 테스트 완료
- [ ] 크래시 없음 확인

### Release Notes (EN)
```
[릴리즈 노트 내용]
```

### Release Notes (KR)
```
[릴리즈 노트 내용]
```

### Metadata Updates Needed
- [ ] 스크린샷 업데이트 필요 여부
- [ ] 설명 업데이트 필요 여부

### Risks/Notes
[잠재적 위험/특이사항]
```

## 체크 항목 상세

### 1. 빌드 검증

```bash
# Release AAB 생성
./gradlew bundleRelease

# APK 서명 확인
jarsigner -verify -verbose -certs app-release.apk
```

### 2. 권한 검사

**허용된 권한**
- `INTERNET` (향후 동기화용, 현재 미사용)
- `RECEIVE_BOOT_COMPLETED` (위젯 갱신)

**금지된 권한**
- `ACCESS_FINE_LOCATION`
- `READ_CONTACTS`
- `CAMERA`

### 3. 릴리즈 노트 템플릿

**초기 릴리즈**
```
Welcome to LivePlan!
• Create projects and tasks
• Home screen widgets for quick access
• Privacy mode for sensitive information
```

**업데이트**
```
What's new in [version]:
• [새 기능]
• [개선 사항]
• [버그 수정]
```

## 관련 rules

- Android/.claude/rules/playstore-submission.md
- Android/.claude/rules/strings-localization.md
