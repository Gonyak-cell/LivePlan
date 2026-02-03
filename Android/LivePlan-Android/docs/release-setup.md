# LivePlan Android - 릴리즈 설정 가이드

> GitHub Actions를 통한 Play Store 배포 설정

---

## 필요한 GitHub Secrets

다음 시크릿을 GitHub Repository Settings > Secrets > Actions에 등록해야 합니다.

### 1. Android Keystore 관련

| Secret 이름 | 설명 | 생성 방법 |
|------------|------|----------|
| `ANDROID_KEYSTORE_BASE64` | Base64 인코딩된 keystore 파일 | 아래 참조 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore 비밀번호 | keystore 생성 시 설정한 값 |
| `ANDROID_KEY_ALIAS` | Key alias 이름 | keystore 생성 시 설정한 값 |
| `ANDROID_KEY_PASSWORD` | Key 비밀번호 | keystore 생성 시 설정한 값 |

### 2. Play Store 관련

| Secret 이름 | 설명 | 생성 방법 |
|------------|------|----------|
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play Console 서비스 계정 JSON | 아래 참조 |

---

## Keystore 생성 및 설정

### 1. Keystore 생성 (최초 1회)

```bash
keytool -genkey -v -keystore liveplan-release.keystore \
  -alias liveplan \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

프롬프트에 따라 정보 입력:
- Keystore password: (안전한 비밀번호)
- Key password: (안전한 비밀번호)
- 이름, 조직 등 정보

### 2. Base64 인코딩

```bash
# macOS/Linux
base64 -i liveplan-release.keystore -o keystore.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("liveplan-release.keystore")) | Out-File keystore.txt
```

`keystore.txt` 내용을 `ANDROID_KEYSTORE_BASE64` 시크릿에 등록

### 3. Keystore 백업

**중요**: Keystore 파일과 비밀번호를 안전한 곳에 백업하세요.
- 분실 시 앱 업데이트 불가
- Play Console에서 "앱 서명 키" 등록 권장

---

## Play Store 서비스 계정 설정

### 1. Google Cloud Console에서 서비스 계정 생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 또는 생성
3. APIs & Services > Credentials
4. Create Credentials > Service Account
5. 서비스 계정 이름 입력 (예: `liveplan-play-deploy`)
6. 역할: 없음 (Play Console에서 설정)
7. 완료 후 서비스 계정 클릭 > Keys > Add Key > JSON
8. 다운로드된 JSON 파일 내용을 `PLAY_STORE_SERVICE_ACCOUNT_JSON`에 등록

### 2. Play Console에서 권한 부여

1. [Play Console](https://play.google.com/console/) 접속
2. Settings > Developer account > API access
3. "Link" 버튼으로 Google Cloud 프로젝트 연결
4. Service Accounts에서 생성한 계정 찾기
5. "Grant access" 클릭
6. App permissions에서 LivePlan 앱 선택
7. 권한 설정:
   - Release to production, exclude devices, and use Play App Signing: ✅
   - Manage testing tracks and edit tester lists: ✅

---

## GitHub Environment 설정 (권장)

Production 배포를 위한 보호 설정:

1. Repository Settings > Environments
2. "New environment" > `play-store`
3. 보호 규칙 설정:
   - Required reviewers: 1명 이상 승인 필요
   - Wait timer: 배포 전 대기 시간 (옵션)

---

## 배포 방법

### 방법 1: Tag 기반 자동 배포

```bash
# Internal 트랙 배포
git tag android-v1.0.0
git push origin android-v1.0.0
```

### 방법 2: 수동 배포 (GitHub Actions)

1. Actions 탭 > "Android Release" 워크플로우
2. "Run workflow" 클릭
3. Track 선택 (internal/alpha/beta/production)
4. "Run workflow" 실행

---

## 버전 관리

### versionCode 규칙

`app/build.gradle.kts`에서 관리:

```kotlin
defaultConfig {
    versionCode = 1        // 매 릴리즈마다 +1 증가
    versionName = "1.0.0"  // Semantic versioning
}
```

### 버전 증가 체크리스트

- [ ] `versionCode` 증가 (필수, 고유해야 함)
- [ ] `versionName` 업데이트
- [ ] CHANGELOG 업데이트
- [ ] 커밋 & 태그 생성

---

## 트랙 설명

| 트랙 | 용도 | 접근 |
|-----|------|-----|
| `internal` | 내부 테스트 | 이메일로 초대된 테스터만 |
| `alpha` | 비공개 테스트 | Alpha 테스터 그룹 |
| `beta` | 공개 베타 | 누구나 참여 가능 |
| `production` | 정식 출시 | 모든 사용자 |

### 권장 출시 순서

1. **internal** → 개발팀 테스트 (1-2일)
2. **beta** → 베타 테스터 피드백 (1주)
3. **production** → 정식 출시 (단계적 출시 권장)

---

## 문제 해결

### Keystore 관련 오류

```
> Could not read key from keystore
```
→ `ANDROID_KEYSTORE_PASSWORD` 또는 `ANDROID_KEY_PASSWORD` 확인

### Play Store 업로드 오류

```
> The package name is invalid
```
→ `applicationId`가 Play Console에 등록된 것과 일치하는지 확인

```
> Version code already exists
```
→ `versionCode`를 증가시켜야 함

### 서비스 계정 권한 오류

```
> 403 Forbidden
```
→ Play Console에서 서비스 계정 권한 재확인

---

## 체크리스트

### 최초 설정

- [ ] Keystore 생성 완료
- [ ] Keystore 안전하게 백업
- [ ] GitHub Secrets 등록 완료
- [ ] Play Console 서비스 계정 연결
- [ ] 권한 설정 완료
- [ ] 테스트 배포 성공

### 매 릴리즈

- [ ] versionCode 증가
- [ ] versionName 업데이트
- [ ] 릴리즈 노트 작성
- [ ] 태그 생성 또는 수동 배포
- [ ] 배포 결과 확인
