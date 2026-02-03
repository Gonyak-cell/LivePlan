# playstore-submission.md

Last Updated: 2026-02-02 15:00:00

## 목적

LivePlan을 Google Play Store에 제출할 때 필요한 메타데이터, 스크린샷, 개인정보처리방침을 고정하여 심사 지연/리젝 리스크를 낮춘다.

## 적용 범위

- Play Console 메타데이터 (앱 설명/스크린샷/카테고리)
- 개인정보처리방침 (Privacy Policy)
- 데이터 보안 섹션 (Data Safety)
- 릴리즈 노트

────────────────────────────────────────
## A. 앱 정보 기본
────────────────────────────────────────

### A1. 기본 정보

| 항목 | 값 |
|------|-----|
| 앱 이름 | LivePlan |
| 패키지명 | com.liveplan |
| 카테고리 | 생산성 (Productivity) |
| 타겟 연령 | 전체 이용가 |
| 콘텐츠 등급 | Everyone |

### A2. 짧은 설명 (80자 이내)

**EN**: Simple task manager with home screen widgets. Stay on top of your daily tasks.

**KR**: 홈 화면 위젯으로 오늘의 할 일을 확인하세요. 간단한 태스크 관리 앱.

### A3. 전체 설명 (4000자 이내)

**EN**:
```
LivePlan is a simple yet powerful task management app designed to help you stay focused on what matters most.

KEY FEATURES:
• Home Screen Widgets: See your top tasks at a glance without opening the app
• Projects & Tasks: Organize your work with projects and sections
• Recurring Tasks: Set up daily habits with automatic reset
• Priority Levels: Focus on what's important with P1-P4 priorities
• Privacy Mode: Mask task titles on your home screen
• Quick Add: Capture tasks quickly from widgets or shortcuts
• Board View: Visualize your workflow with Kanban-style boards
• Calendar View: See your schedule at a glance

PRIVACY FIRST:
• All data stored locally on your device
• No account required
• No ads, no tracking
• Privacy mode hides sensitive information on widgets

Perfect for:
• Daily task management
• Building productive habits
• Staying organized with minimal effort

Start your productive journey with LivePlan today!
```

**KR**:
```
LivePlan은 가장 중요한 일에 집중할 수 있도록 도와주는 간단하면서도 강력한 태스크 관리 앱입니다.

주요 기능:
• 홈 화면 위젯: 앱을 열지 않고도 주요 할 일을 한눈에 확인
• 프로젝트 & 태스크: 프로젝트와 섹션으로 업무 정리
• 반복 태스크: 자동 리셋으로 매일 습관 설정
• 우선순위: P1-P4 우선순위로 중요한 일에 집중
• 프라이버시 모드: 홈 화면에서 태스크 제목 마스킹
• 빠른 추가: 위젯이나 단축키로 빠르게 태스크 추가
• 보드 뷰: 칸반 스타일 보드로 워크플로 시각화
• 캘린더 뷰: 일정을 한눈에 확인

프라이버시 우선:
• 모든 데이터는 기기에만 저장
• 계정 불필요
• 광고 없음, 추적 없음
• 프라이버시 모드로 위젯에서 민감 정보 숨김

이런 분께 추천:
• 일일 태스크 관리
• 생산적인 습관 만들기
• 최소한의 노력으로 정리 유지

LivePlan과 함께 생산적인 하루를 시작하세요!
```

────────────────────────────────────────
## B. 스크린샷 가이드
────────────────────────────────────────

### B1. 필수 스크린샷 (5~8장)

| # | 화면 | 내용 |
|---|------|------|
| 1 | 프로젝트 목록 | 메인 화면, 프로젝트 카드 |
| 2 | 태스크 리스트 | 태스크 목록 + 완료 체크 |
| 3 | 홈 화면 위젯 | Medium 위젯 (Top 3 + 카운트) |
| 4 | 보드 뷰 | 칸반 스타일 레이아웃 |
| 5 | 태스크 생성 | 새 태스크 입력 화면 |
| 6 | 프라이버시 모드 | 마스킹된 위젯 표시 |
| 7 | 설정 화면 | 프라이버시/대표 프로젝트 설정 |

### B2. 스크린샷 요구사항

- 해상도: 1080 x 1920 (또는 2160 x 3840)
- 형식: PNG 또는 JPEG
- 실제 기기 또는 에뮬레이터 캡처
- 민감 정보 없는 샘플 데이터 사용

────────────────────────────────────────
## C. 데이터 보안 (Data Safety)
────────────────────────────────────────

### C1. 데이터 수집 여부

| 질문 | 답변 |
|------|------|
| 앱이 사용자 데이터를 수집하나요? | 아니오 |
| 앱이 사용자 데이터를 공유하나요? | 아니오 |
| 앱이 데이터를 암호화하나요? | 해당 없음 (로컬 저장) |
| 사용자가 데이터 삭제를 요청할 수 있나요? | 예 (앱 삭제 시 자동 삭제) |

### C2. 데이터 유형

| 데이터 유형 | 수집 | 공유 | 용도 |
|------------|------|------|------|
| 개인 정보 | ❌ | ❌ | - |
| 위치 | ❌ | ❌ | - |
| 금융 정보 | ❌ | ❌ | - |
| 사용자 콘텐츠 (태스크) | 로컬만 | ❌ | 앱 기능 |
| 기기 ID | ❌ | ❌ | - |

### C3. 데이터 보안 선언문

```
LivePlan stores all your data locally on your device.
We do not collect, transmit, or share any personal information.
No account or login required.
Uninstalling the app will delete all stored data.
```

────────────────────────────────────────
## D. 개인정보처리방침
────────────────────────────────────────

### D1. 필수 항목

```
Privacy Policy for LivePlan

Last updated: [Date]

1. Information We Don't Collect
LivePlan does not collect, store, or transmit any personal information
to external servers. All your task data is stored locally on your device.

2. Local Data Storage
- Your projects, tasks, and settings are stored only on your device
- This data is not accessible to us or any third parties
- Uninstalling the app will permanently delete all your data

3. No Account Required
LivePlan works entirely offline without requiring any account,
login, or registration.

4. No Third-Party Services
We do not integrate any analytics, advertising, or tracking services.

5. Data Security
Your data remains on your device and is protected by your device's
built-in security features.

6. Children's Privacy
LivePlan does not knowingly collect any data from children under 13.

7. Changes to This Policy
We may update this privacy policy from time to time.
Any changes will be posted on this page.

8. Contact
If you have questions about this privacy policy,
please contact: [contact email]
```

────────────────────────────────────────
## E. 릴리즈 노트 템플릿
────────────────────────────────────────

### E1. 초기 릴리즈 (v1.0.0)

**EN**:
```
Welcome to LivePlan!

• Create projects and tasks to organize your day
• Add home screen widgets for quick access
• Set up recurring tasks for daily habits
• Use privacy mode to hide sensitive information
• View tasks in list, board, or calendar view

Thank you for choosing LivePlan!
```

**KR**:
```
LivePlan에 오신 것을 환영합니다!

• 프로젝트와 태스크로 하루를 정리하세요
• 홈 화면 위젯으로 빠르게 확인
• 매일 반복 태스크로 습관 만들기
• 프라이버시 모드로 민감 정보 숨기기
• 리스트, 보드, 캘린더 뷰 지원

LivePlan을 선택해 주셔서 감사합니다!
```

### E2. 업데이트 템플릿

```
[Version X.Y.Z]

NEW:
• [새 기능 1]
• [새 기능 2]

IMPROVED:
• [개선 사항 1]

FIXED:
• [버그 수정 1]
```

────────────────────────────────────────
## F. 제출 전 체크리스트
────────────────────────────────────────

- [ ] 앱이 크래시 없이 정상 동작하는가
- [ ] 모든 권한이 필요한 기능에만 사용되는가
- [ ] 개인정보처리방침 URL이 유효한가
- [ ] Data Safety 섹션이 정확하게 작성되었는가
- [ ] 스크린샷이 실제 앱과 일치하는가
- [ ] 릴리즈 노트가 명확하게 작성되었는가
- [ ] 타겟 API 레벨이 Play Store 요구사항을 충족하는가
- [ ] ProGuard/R8 설정이 적용되었는가
- [ ] 서명이 올바르게 되었는가

끝.
