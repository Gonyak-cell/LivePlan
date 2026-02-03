# Keystore 생성 가이드

> ⚠️ **중요**: keystore 분실 시 앱 업데이트 불가!

## 1. PowerShell에서 keystore 생성

```powershell
cd "c:\Users\diedi\OneDrive\Documents\App\LivePlan\Android\LivePlan-Android"

& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore liveplan-release.keystore -alias liveplan -keyalg RSA -keysize 2048 -validity 10000
```

### 입력할 정보:
| 항목 | 입력값 |
|------|--------|
| Keystore password | **6자 이상, 안전한 비밀번호** |
| Re-enter password | (동일하게) |
| 이름(CN) | `LivePlan Developer` |
| 조직(OU) | `.` (또는 원하는 값) |
| 조직명(O) | `LivePlan` |
| 도시(L) | `.` (또는 원하는 값) |
| 시/도(ST) | `.` (또는 원하는 값) |
| 국가(C) | `KR` |
| 확인 | `yes` |

## 2. Base64 인코딩

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("liveplan-release.keystore")) | Out-File -Encoding ASCII keystore_base64.txt
```

## 3. GitHub Secrets 등록

GitHub Repository → Settings → Secrets and variables → Actions → New repository secret

| Secret 이름 | 값 |
|------------|-----|
| `ANDROID_KEYSTORE_BASE64` | `keystore_base64.txt` 내용 전체 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_KEY_ALIAS` | `liveplan` |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 (보통 keystore와 동일) |

## 4. 백업 (필수!)

아래 파일들을 **안전한 위치**에 백업:
- `liveplan-release.keystore`
- `keystore_base64.txt`
- 비밀번호 기록 (암호화 보관)

## 5. .gitignore 확인

keystore 파일이 git에 커밋되지 않도록 확인:
```
*.keystore
keystore_base64.txt
```
