# LivePlan Android - Play Store 출시 진행 상황

Last Updated: 2026-02-03 15:30:00

## 개요

LivePlan Android 앱의 Google Play Store 출시를 위한 작업 진행 상황을 기록합니다.

---

## 완료된 작업

### 1. Android 앱 빌드 및 실행 ✅
- 에뮬레이터: Medium Phone API 36.1 (Android 16)
- 앱 정상 실행 확인
- 주요 기능 동작 테스트 완료

### 2. 스크린샷 촬영 ✅

**en-US 폴더 (8장)**
| 파일명 | 설명 |
|--------|------|
| 1. 빈 상태.png | 프로젝트 없는 초기 화면 |
| 2. 프로젝트 생성.png | 프로젝트 생성 화면 |
| 3. 프로젝트 목록.png | 프로젝트 목록 |
| 4. 태스크 추가.png | 태스크 추가 화면 |
| 5. 태스크 목록.png | 태스크 목록 |
| 6. 설정화면.png | 설정 화면 |
| 7. 검색 화면.png | 검색 화면 |
| Screenshot_20260203_143922.png | 추가 스크린샷 |

**ko-KR 폴더 (8장)**
- 한국어 버전 스크린샷 8장 촬영 완료
- 파일명 정리 필요 (현재 기본 파일명 상태)

**저장 위치:** `Android/LivePlan-Android/docs/screenshots/`

### 3. 개인정보처리방침 ✅
- **파일:** `Android/LivePlan-Android/docs/privacy-policy.html`
- **호스팅:** GitHub Pages
- **URL:** https://gonyak-cell.github.io/liveplan-privacy/privacy-policy.html
- **내용:** 한국어 + 영어 버전 포함
- **회사명:** teamgray
- **연락처:** dieding88@naver.com

### 4. Google Play 개발자 계정 ✅
- 계정 등록 완료 ($25 결제)
- Play Console 접근 가능

### 5. AAB 릴리즈 빌드 ✅
- **파일:** `Android/LivePlan-Android/app/release/app-release.aab`
- 기존 keystore 사용하여 서명 완료

---

## 진행 중인 작업

### 6. Play Store 앱 등록 🔄
- Play Console에서 앱 만들기 진행 중
- 스토어 등록정보 입력 필요

---

## 남은 작업

### 7. 앱 아이콘 512x512 PNG ⏳
- Play Store 제출용 고해상도 아이콘 필요
- 현재 앱 내 아이콘: webp 형식 (mipmap 폴더)

### 8. Play Store 스토어 등록정보 ⏳
- 앱 설명 (한국어/영어)
- 스크린샷 업로드
- 카테고리 선택
- 앱 아이콘 업로드

### 9. 앱 콘텐츠 설정 ⏳
- 개인정보처리방침 URL 입력
- 광고 포함 여부
- 타겟 연령층
- 콘텐츠 등급 설문

### 10. 앱 번들 업로드 및 심사 제출 ⏳
- AAB 파일 업로드
- 출시 트랙 선택 (내부 테스트 / 비공개 / 프로덕션)
- 심사 제출

---

## 주요 정보 요약

| 항목 | 값 |
|------|-----|
| 앱 이름 | LivePlan |
| 패키지명 | com.liveplan.app |
| 개발사 | teamgray |
| 연락처 | dieding88@naver.com |
| 개인정보처리방침 | https://gonyak-cell.github.io/liveplan-privacy/privacy-policy.html |
| AAB 파일 | app/release/app-release.aab |
| Keystore | liveplan-release.keystore |

---

## 문제 해결 기록

### OneDrive 동기화 충돌
- **문제:** Gradle 빌드 중 파일 삭제 불가
- **해결:** OneDrive 일시 중지 후 빌드 진행

### 에뮬레이터 응답 없음
- **문제:** `am force-stop` 명령 3000초 타임아웃
- **해결:** 에뮬레이터 Cold Boot 후 재시작

---

## 다음 단계

1. Play Console에서 앱 기본 정보 입력
2. 스토어 등록정보 작성
3. 앱 아이콘 512x512 준비 및 업로드
4. AAB 파일 업로드
5. 심사 제출
