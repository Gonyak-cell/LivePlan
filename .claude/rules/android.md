# android.md

Last Updated: 2026-02-03 09:18:35

## 목적

LivePlan Android 전환 작업의 파일 구조 및 작업 규칙을 고정한다.

iOS 코드베이스와의 분리를 명확히 하고, Android 관련 모든 산출물이 단일 디렉터리에서 관리되도록 한다.

## 적용 범위

- Android 앱 소스 코드
- Android 관련 설계/문서
- Android 빌드 설정 및 리소스
- Android 테스트 코드
- Android 전용 Claude 설정(agents/rules/skills)

## 핵심 원칙(강행)

### 1. 파일 위치 규칙

**Android 전환 작업과 관련된 모든 파일은 `Android/` 폴더 이하에 저장해야 한다.**

허용되는 위치:
- `Android/LivePlan-Android/` - Android 앱 프로젝트
- `Android/.claude/` - Android 전용 Claude 설정

금지되는 위치:
- 프로젝트 루트에 Android 관련 파일 직접 생성
- `AppCore/`, `AppStorage/` 등 iOS 모듈에 Android 코드 혼합
- 루트 `.claude/rules/`에는 공통 규칙만 (android.md는 예외)

### 2. 디렉터리 구조(현재)

```
Android/
├── .claude/                       # Android 전용 Claude 설정
│   ├── agents/
│   ├── rules/
│   └── skills/                    # Android 개발 관련 스킬
│
└── LivePlan-Android/              # Android 앱 프로젝트 루트
    ├── app/                       # 메인 앱 모듈 (UI/DI/진입점)
    ├── core/                      # 코어 모듈 (iOS AppCore 대응)
    ├── data/                      # 데이터 모듈 (iOS AppStorage 대응)
    ├── widget/                    # 위젯 모듈 (iOS Widget Extension 대응)
    ├── shortcuts/                 # 단축어 모듈 (iOS AppIntents 대응)
    ├── config/                    # 빌드 설정 (detekt 등)
    ├── docs/                      # Android 관련 문서/스크린샷
    │   └── screenshots/
    │       ├── en-US/
    │       └── ko-KR/
    └── build.gradle.kts
```

### 3. 모듈 대응 관계

| iOS 모듈 | Android 모듈 | 역할 |
|---------|-------------|------|
| AppCore | core | 도메인 로직/엔티티/유즈케이스 |
| AppStorage | data | 저장소/Repository 구현 |
| App (UI) | app | 메인 앱/UI/DI |
| Widget Extension | widget | 홈 화면 위젯 |
| AppIntents | shortcuts | 단축어/인텐트 |

### 4. iOS 규칙과의 관계

- `architecture.md`, `data-model.md` 등 도메인 규칙은 Android에도 동일하게 적용
- UI/플랫폼 관련 규칙(`lockscreen.md`, `intents.md`)은 Android 플랫폼에 맞게 해석
- Android 고유 규칙이 필요하면 `Android/.claude/rules/`에 추가

### 5. 네이밍 규칙

- 패키지명: `com.liveplan.*`
  - `com.liveplan.app` - 메인 앱
  - `com.liveplan.core` - 코어/도메인
  - `com.liveplan.data` - 데이터/저장소
  - `com.liveplan.widget` - 위젯
  - `com.liveplan.shortcuts` - 단축어

## 비목표

- iOS 코드와 Android 코드의 공유 모듈 생성 (KMM 등은 Phase 2+)
- iOS 규칙 파일 내에 Android 관련 내용 추가

## 변경 시 파급효과

- 디렉터리 구조 변경 시 본 문서 업데이트 필수
- 새로운 Android 모듈 추가 시 본 문서에 구조 반영

끝.
