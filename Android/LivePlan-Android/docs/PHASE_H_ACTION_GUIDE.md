# Phase H - 릴리즈 준비 액션 가이드

> Last Updated: 2026-02-03 12:00:00
>
> **목표**: Internal 트랙 배포까지 완료

---

## 현재 상태 요약

| 항목 | 상태 | 비고 |
|------|------|------|
| ProGuard/R8 최적화 | ✅ 완료 | 150줄 proguard-rules.pro |
| Play Store 메타데이터 | ✅ 완료 | KR/EN 작성됨 |
| CI/CD 워크플로우 | ✅ 완료 | android.yml + android-release.yml |
| 통합 테스트 | ✅ 완료 | 8개 Instrumented 테스트 |
| **GitHub Secrets** | ❌ 미완료 | **Critical** |
| **스크린샷 7장** | ❌ 미완료 | **Critical** |
| **수동 QA** | ❌ 미완료 | **Critical** |

---

## 🔴 CRITICAL - 1. GitHub Secrets 등록 (예상: 30분)

### 1.1 Keystore 생성 (Windows PowerShell)

```powershell
# JDK bin 폴더에서 실행 또는 PATH에 keytool이 있어야 함
keytool -genkey -v -keystore liveplan-release.keystore `
  -alias liveplan `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

입력할 정보:
- Keystore password: `[안전한 비밀번호 - 기록해둘 것]`
- Key password: `[동일하게 설정 권장]`
- 이름(CN): `LivePlan Developer`
- 조직(O): `LivePlan`
- 국가(C): `KR`

### 1.2 Base64 인코딩 (PowerShell)

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("liveplan-release.keystore")) | Out-File -Encoding ASCII keystore_base64.txt
```

### 1.3 GitHub Secrets 등록

Repository → Settings → Secrets and variables → Actions → New repository secret

| Secret 이름 | 값 |
|------------|-----|
| `ANDROID_KEYSTORE_BASE64` | keystore_base64.txt 내용 전체 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_KEY_ALIAS` | `liveplan` |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 |

### 1.4 Keystore 백업 (중요!)

```
📁 안전한 위치에 백업:
├── liveplan-release.keystore (원본)
├── keystore_base64.txt (Base64 인코딩)
└── passwords.txt (비밀번호 - 암호화 보관)
```

⚠️ **주의**: Keystore 분실 시 앱 업데이트 불가!

### 1.5 Play Store 서비스 계정 (배포 시 필요)

> 이 단계는 Internal 배포 전 완료 필요

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성: `liveplan-android`
3. APIs & Services → Credentials → Create Service Account
4. JSON 키 다운로드
5. GitHub Secret 등록: `PLAY_STORE_SERVICE_ACCOUNT_JSON`

6. [Play Console](https://play.google.com/console/) 접속
7. Settings → Developer account → API access → Link Google Cloud project
8. Service account에 권한 부여

---

## 🔴 CRITICAL - 2. 스크린샷 7장 촬영 (예상: 1시간)

### 사전 준비

1. **샘플 데이터 생성**
   ```
   프로젝트: "업무 프로젝트"
   태스크:
   - ✅ 회의 준비 (완료)
   - ⬜ 운동하기 (반복, 미완료)
   - ⬜ 영어 공부 (반복, 미완료)
   - ⬜ 프레젠테이션 마감 (내일 마감)
   - ⬜ 보고서 작성 (어제 마감 - 지연)
   ```

2. **기기 설정**
   - 시간: 오전 10:00
   - 배터리: 80% 이상
   - 알림 표시줄: 깨끗하게
   - 다크모드: OFF (라이트 모드)

3. **위젯/타일 미리 추가**
   - 홈 화면 위젯 (2x2 또는 4x2)
   - Quick Settings 타일

### 촬영 체크리스트

| # | 파일명 | 화면 | 완료 |
|---|--------|------|------|
| 1 | `01_create_project_task.png` | 태스크 생성 화면 (날짜/반복 옵션 보이게) | ⬜ |
| 2 | `02_home_widget.png` | 홈 화면 위젯 (Top3 + 카운트) | ⬜ |
| 3 | `03_recurring_concept.png` | 반복 태스크 목록 (반복 아이콘 강조) | ⬜ |
| 4 | `04_privacy_mode.png` | 프라이버시 ON (제목 마스킹) | ⬜ |
| 5 | `05_board_view.png` | 보드 뷰 (Todo/Doing/Done 컬럼) | ⬜ |
| 6 | `06_quick_settings_tile.png` | 빠른 설정 패널 (타일 표시) | ⬜ |
| 7 | `07_app_shortcuts.png` | 앱 아이콘 길게 누름 (바로가기 메뉴) | ⬜ |

### 저장 위치

```
docs/screenshots/
├── ko-KR/
│   ├── 01_create_project_task.png
│   ├── 02_home_widget.png
│   ├── ...
└── en-US/
    └── (동일 - 캡션만 영어로)
```

---

## 🔴 CRITICAL - 3. 수동 QA 체크리스트 (예상: 2시간)

### 3.1 Release APK 생성 및 설치

```bash
cd Android/LivePlan-Android
./gradlew assembleRelease

# APK 위치
# app/build/outputs/apk/release/app-release.apk
```

### 3.2 핵심 기능 QA

#### 프로젝트 CRUD
- [ ] 프로젝트 생성 (시작일 필수)
- [ ] 프로젝트 수정
- [ ] 프로젝트 삭제
- [ ] 프로젝트 보관(archive)

#### 태스크 CRUD
- [ ] 일반 태스크 생성
- [ ] 반복 태스크 생성
- [ ] 태스크 완료/미완료 토글
- [ ] 태스크 수정
- [ ] 태스크 삭제

#### 반복 태스크 동작
- [ ] 오늘 완료 → 목록에서 제거
- [ ] 다음 날(시뮬레이션) → 다시 미완료

#### 뷰 전환
- [ ] 리스트 뷰 정상
- [ ] 보드 뷰 정상
- [ ] 드래그 앤 드롭 상태 변경

### 3.3 위젯 QA
- [ ] 위젯 추가 성공 (2x2, 4x2)
- [ ] Top N + 카운트 표시
- [ ] 앱 변경 → 위젯 갱신
- [ ] 기기 재시작 후 위젯 유지
- [ ] 빈 상태 표시

### 3.4 Quick Settings Tile QA
- [ ] 타일 추가 성공
- [ ] "다음 할 일 완료" 동작
- [ ] 완료할 항목 없을 때 피드백

### 3.5 App Shortcuts QA
- [ ] 바로가기 메뉴 표시
- [ ] "빠른 추가" 동작
- [ ] 바로가기 → 앱 열기

### 3.6 프라이버시 모드 QA
- [ ] ON → 위젯 제목 마스킹
- [ ] OFF → 위젯 제목 표시
- [ ] 설정 변경 → 위젯 갱신

### 3.7 엣지 케이스
- [ ] 데이터 없음 상태
- [ ] 앱 강제 종료 → 재실행 (데이터 유지)
- [ ] 저장소 부족 (크래시 없음)

### 3.8 디바이스 호환성 (가능한 범위)
- [ ] Android 8.0+ 테스트 (최소)
- [ ] Android 14+ 테스트 (최신)
- [ ] 다크모드 테스트

---

## 배포 순서

### Phase H-1: 준비 완료 확인
```
1. GitHub Secrets 등록 완료
2. 스크린샷 7장 촬영 완료
3. 수동 QA 통과
```

### Phase H-2: Internal 배포
```bash
# 방법 1: Tag 기반
git tag android-v1.0.0
git push origin android-v1.0.0

# 방법 2: 수동 (GitHub Actions)
# Actions → "Android Release" → Run workflow → Track: internal
```

### Phase H-3: Play Console 메타데이터 업로드
1. 앱 아이콘 (512x512)
2. 그래픽 이미지 (1024x500)
3. 스크린샷 7장 (ko-KR, en-US)
4. 앱 설명 (playstore-metadata.md 참조)
5. 개인정보 처리방침 URL

### Phase H-4: 심사 제출
1. Data Safety 설문 완료
2. 콘텐츠 등급 설문 완료
3. 심사관 메모 입력 (production-checklist.md 참조)
4. 심사 제출

---

## 체크리스트 요약

### 오늘 완료해야 할 것
- [ ] Keystore 생성 및 GitHub Secrets 등록
- [ ] Release APK 빌드 테스트
- [ ] 스크린샷 7장 촬영

### 내일 완료해야 할 것
- [ ] 수동 QA 전체 실행
- [ ] Play Console 앱 등록
- [ ] Internal 트랙 배포

### 이번 주 완료해야 할 것
- [ ] Beta 테스터 피드백
- [ ] Production 심사 제출

---

## 관련 문서

- [release-setup.md](./release-setup.md) - GitHub Secrets 상세 가이드
- [production-checklist.md](./production-checklist.md) - 전체 QA 체크리스트
- [screenshots-guide.md](./screenshots-guide.md) - 스크린샷 스토리보드
- [playstore-metadata.md](./playstore-metadata.md) - Play Store 메타데이터

---

## 긴급 연락처

- **GitHub Actions 실패**: Actions 탭 → 로그 확인
- **Play Console 문제**: [Play Console 지원](https://support.google.com/googleplay/android-developer/)
- **Keystore 분실**: ⚠️ 복구 불가 - 백업 확인

---

**Phase H 목표**: LivePlan Android 1.0.0 Internal 트랙 배포 완료
