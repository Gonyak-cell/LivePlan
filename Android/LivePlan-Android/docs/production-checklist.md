# LivePlan Android - 프로덕션 출시 체크리스트

> Play Store 심사 통과 및 정식 출시를 위한 완전한 체크리스트

---

## 1. 코드/빌드 검증

### 1.1 빌드 검증
- [ ] Release 빌드 성공 (`./gradlew assembleRelease`)
- [ ] AAB 생성 성공 (`./gradlew bundleRelease`)
- [ ] ProGuard/R8 난독화 적용 확인
- [ ] 모든 단위 테스트 통과 (`./gradlew testReleaseUnitTest`)
- [ ] Lint 경고 없음 (`./gradlew lint`)

### 1.2 버전 확인
- [ ] `versionCode` 이전 버전보다 증가
- [ ] `versionName` 업데이트됨
- [ ] `compileSdk` / `targetSdk` 최신 정책 준수 (현재 targetSdk 36)

### 1.3 서명 검증
- [ ] Release keystore로 서명됨
- [ ] keystore 파일 안전하게 백업됨
- [ ] Play App Signing 등록 완료 (권장)

---

## 2. 기능/품질 검증

### 2.1 핵심 기능 수동 QA
- [ ] **프로젝트 CRUD**
  - [ ] 프로젝트 생성 (시작일 필수)
  - [ ] 프로젝트 수정
  - [ ] 프로젝트 삭제
  - [ ] 프로젝트 보관(archive)

- [ ] **태스크 CRUD**
  - [ ] 일반 태스크 생성
  - [ ] 반복 태스크 생성
  - [ ] 태스크 완료/미완료 토글
  - [ ] 태스크 수정
  - [ ] 태스크 삭제

- [ ] **반복 태스크 동작**
  - [ ] 오늘 완료 → 오늘 목록에서 제거
  - [ ] 다음 날 → 다시 미완료로 표시

- [ ] **뷰 전환**
  - [ ] 리스트 뷰 정상 동작
  - [ ] 보드 뷰 정상 동작
  - [ ] 드래그 앤 드롭 상태 변경

### 2.2 위젯 QA
- [ ] 위젯 추가 성공 (2x2, 4x2)
- [ ] 위젯에 Top N + 카운트 표시
- [ ] 앱에서 변경 → 위젯 갱신 확인
- [ ] 기기 재시작 후 위젯 유지
- [ ] 빈 상태 표시 정상

### 2.3 Quick Settings Tile QA
- [ ] 타일 추가 성공
- [ ] "다음 할 일 완료" 동작 확인
- [ ] 완료할 항목 없을 때 토스트/피드백

### 2.4 App Shortcuts QA
- [ ] 앱 아이콘 길게 눌러 바로가기 표시
- [ ] "빠른 추가" 동작 확인
- [ ] 바로가기에서 앱 열기 정상

### 2.5 프라이버시 모드 QA
- [ ] 프라이버시 모드 ON → 위젯에서 제목 마스킹
- [ ] 프라이버시 모드 OFF → 위젯에서 제목 표시
- [ ] 설정 변경 → 위젯 갱신

### 2.6 엣지 케이스
- [ ] 데이터 없음 (프로젝트/태스크 0) 상태 정상
- [ ] 앱 강제 종료 후 재실행 → 데이터 유지
- [ ] 저장소 부족 상황 대응 (크래시 없음)
- [ ] 네트워크 없는 환경에서 정상 동작

---

## 3. 디바이스 호환성

### 3.1 최소 지원 버전
- [ ] Android 8.0 (API 26) 테스트
- [ ] Android 12 (API 31) 테스트 - Material You
- [ ] Android 13 (API 33) 테스트
- [ ] Android 14+ 최신 버전 테스트

### 3.2 화면 크기
- [ ] 작은 화면 (5인치 미만)
- [ ] 일반 화면 (5~6인치)
- [ ] 태블릿 (10인치)

### 3.3 다크모드
- [ ] 라이트 모드 정상
- [ ] 다크 모드 정상
- [ ] 시스템 설정 따라가기 정상

---

## 4. Play Store 메타데이터

### 4.1 스토어 등록정보
- [ ] 앱 이름 (KR/EN)
- [ ] 짧은 설명 (80자 이내)
- [ ] 상세 설명 (4000자 이내)
- [ ] 카테고리: 생산성

### 4.2 그래픽 자산
- [ ] 앱 아이콘 (512x512 PNG)
- [ ] 그래픽 이미지 (1024x500 PNG)
- [ ] 스크린샷 7장 (각 언어)
  - [ ] 01: 프로젝트/할 일 생성
  - [ ] 02: 홈 화면 위젯
  - [ ] 03: 반복 항목 개념
  - [ ] 04: 프라이버시 모드
  - [ ] 05: Board 뷰
  - [ ] 06: Quick Settings Tile
  - [ ] 07: App Shortcuts

### 4.3 연락처/정책
- [ ] 개발자 이메일 등록
- [ ] 개인정보 처리방침 URL 등록
- [ ] (선택) 고객지원 URL

---

## 5. 데이터 안전 (Data Safety)

### 5.1 설문 응답
- [ ] 데이터 수집: 아니요
- [ ] 데이터 공유: 아니요
- [ ] 데이터 암호화: 해당 없음 (로컬 저장)
- [ ] 데이터 삭제: 앱 삭제 시 모든 데이터 삭제

### 5.2 권한 검토
- [ ] 사용 중인 권한 목록 확인
  - `RECEIVE_BOOT_COMPLETED` (위젯 복원)
- [ ] 불필요한 권한 없음 확인
- [ ] 위험 권한(카메라, 위치 등) 없음 확인

---

## 6. 콘텐츠 등급

### 6.1 설문 응답
- [ ] 콘텐츠 등급 설문 완료
- [ ] 예상 등급: 전체 이용가 (PEGI 3 / ESRB Everyone)

---

## 7. 심사관 메모 (Review Notes)

### 7.1 필수 포함 내용
```
LivePlan is a task management app focused on home screen widgets.

Core Features:
1. Widget: Shows top 3 tasks + count summary
2. Quick Settings Tile: "Complete Next Task" action
3. App Shortcuts: Quick add task from launcher

Privacy Default:
- Privacy mode ON by default
- Task titles masked on widget
- All data stored locally only

Testing Steps:
1. Create a project (tap + button on home)
2. Add 3+ tasks (mix one-off and daily recurring)
3. Add widget to home screen (long press → widgets → LivePlan)
4. Verify widget shows task count
5. Complete a task and verify widget updates
6. Toggle privacy mode in Settings

No login required.
No internet permission.
No analytics SDK.
```

---

## 8. 최종 배포

### 8.1 Internal 테스트 (1-2일)
- [ ] Internal 트랙 배포
- [ ] 개발팀 테스트 완료
- [ ] 크래시 리포트 확인

### 8.2 Beta 테스트 (권장, 1주)
- [ ] Beta 트랙 배포
- [ ] 베타 테스터 피드백 수집
- [ ] 치명적 버그 없음 확인

### 8.3 Production 출시
- [ ] Production 트랙 배포
- [ ] 단계적 출시 설정 (권장: 10% → 50% → 100%)
- [ ] 출시 후 24시간 모니터링
- [ ] 크래시/ANR 비율 확인

---

## 9. 출시 후

### 9.1 모니터링
- [ ] Play Console 대시보드 확인
- [ ] 크래시율 < 1% 유지
- [ ] ANR율 < 0.5% 유지
- [ ] 사용자 리뷰 모니터링

### 9.2 문서 업데이트
- [ ] CHANGELOG 업데이트
- [ ] README 버전 정보 업데이트
- [ ] GitHub Release 생성

---

## 빠른 참조: 배포 명령어

### Tag 기반 배포
```bash
# 버전 업데이트 후
git add .
git commit -m "chore: bump version to 1.0.0"
git tag android-v1.0.0
git push origin main --tags
```

### 수동 배포
1. GitHub Actions → "Android Release"
2. "Run workflow"
3. Track 선택: `internal` → `beta` → `production`

---

## 연락처

- **긴급 이슈**: (담당자 연락처)
- **Play Console**: https://play.google.com/console/
- **GitHub Actions**: (repository URL)/actions
