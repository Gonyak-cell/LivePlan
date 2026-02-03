# LivePlan Android - QA 트래킹

> Last Updated: 2026-02-03 09:40:00

---

## 📱 수동 QA 체크리스트

### 1. 프로젝트 CRUD
- [ ] 프로젝트 생성 (시작일 필수)
- [ ] 프로젝트 수정
- [ ] 프로젝트 삭제
- [ ] 프로젝트 보관(archive)

### 2. 태스크 CRUD
- [ ] 일반 태스크 생성
- [ ] 반복 태스크 생성
- [ ] 태스크 완료/미완료 토글
- [ ] 태스크 수정
- [ ] 태스크 삭제

### 3. 반복 태스크 동작
- [ ] 오늘 완료 → 목록에서 제거
- [ ] 다음 날(시뮬레이션) → 다시 미완료

### 4. 뷰 전환
- [ ] 리스트 뷰 정상
- [ ] 보드 뷰 정상
- [ ] 드래그 앤 드롭 상태 변경

### 5. 위젯 QA
- [ ] 위젯 추가 성공 (2x2, 4x2)
- [ ] Top N + 카운트 표시
- [ ] 앱 변경 → 위젯 갱신
- [ ] 기기 재시작 후 위젯 유지
- [ ] 빈 상태 표시

### 6. Quick Settings Tile QA
- [ ] 타일 추가 성공
- [ ] "다음 할 일 완료" 동작
- [ ] 완료할 항목 없을 때 피드백

### 7. App Shortcuts QA
- [ ] 바로가기 메뉴 표시
- [ ] "빠른 추가" 동작
- [ ] 바로가기 → 앱 열기

### 8. 프라이버시 모드 QA
- [ ] ON → 위젯 제목 마스킹
- [ ] OFF → 위젯 제목 표시
- [ ] 설정 변경 → 위젯 갱신

### 9. 엣지 케이스
- [ ] 데이터 없음 상태
- [ ] 앱 강제 종료 → 재실행 (데이터 유지)
- [ ] 저장소 부족 (크래시 없음)

### 10. 디바이스 호환성
- [ ] Android 8.0+ 테스트
- [ ] Android 14+ 테스트
- [ ] 다크모드 테스트

---

## 📸 스크린샷 체크리스트

| # | 파일명 | 완료 |
|---|--------|------|
| 1 | `01_create_project_task.png` | ⬜ |
| 2 | `02_home_widget.png` | ⬜ |
| 3 | `03_recurring_concept.png` | ⬜ |
| 4 | `04_privacy_mode.png` | ⬜ |
| 5 | `05_board_view.png` | ⬜ |
| 6 | `06_quick_settings_tile.png` | ⬜ |
| 7 | `07_app_shortcuts.png` | ⬜ |

### 저장 위치
```
docs/screenshots/
├── ko-KR/   ← 한국어 스크린샷 7장
└── en-US/   ← 영어 스크린샷 7장
```

---

## 🔐 GitHub Secrets 체크리스트

| Secret | 등록됨 |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | ⬜ |
| `ANDROID_KEYSTORE_PASSWORD` | ⬜ |
| `ANDROID_KEY_ALIAS` | ⬜ |
| `ANDROID_KEY_PASSWORD` | ⬜ |

---

## 📊 완료 현황

| 구분 | 완료 | 전체 | 비율 |
|------|------|------|------|
| 수동 QA | 0 | 28 | 0% |
| 스크린샷 | 0 | 7 | 0% |
| GitHub Secrets | 0 | 4 | 0% |

---

## 다음 단계

1. ✅ 폴더 구조 생성 완료
2. ⬜ **Keystore 생성** → [KEYSTORE_SETUP.md](../KEYSTORE_SETUP.md) 참조
3. ⬜ **스크린샷 촬영** → [screenshots-guide.md](./screenshots-guide.md) 참조
4. ⬜ **수동 QA 실행** → 위 체크리스트 따라 진행
5. ⬜ **Internal 배포** → GitHub tag 생성
