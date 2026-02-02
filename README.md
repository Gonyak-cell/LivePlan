# LivePlan

Lock-screen-first 프로젝트/태스크 관리 iOS 앱

## 소개

LivePlan은 잠금화면에서 바로 할 일을 확인하고 관리할 수 있는 iOS 앱입니다. 위젯, Live Activity, App Intents를 활용하여 앱을 열지 않고도 핵심 기능을 사용할 수 있습니다.

### 주요 기능

- **잠금화면 위젯**: Top 3 미완료 항목 + 카운터 표시
- **Live Activity**: 현재 작업 중인 태스크 표시
- **단축어 지원**: RefreshLiveActivity, CompleteNextTask, QuickAddTask
- **iOS 18 Controls**: 잠금화면에서 바로 완료/추가
- **프라이버시 모드**: 잠금화면 노출 최소화 (마스킹 기본)
- **반복 태스크**: 매일/주간/월간 반복 지원
- **우선순위 & 태그**: P1~P4 우선순위, 다중 태그 분류

## 요구사항

- iOS 17.0+
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## 설치 및 빌드

### 1. XcodeGen 설치

```bash
brew install xcodegen
```

### 2. 프로젝트 생성

```bash
git clone https://github.com/YOUR_USERNAME/LivePlan.git
cd LivePlan
xcodegen generate
```

### 3. Xcode에서 열기

```bash
open LivePlan.xcodeproj
```

### 4. 개발 팀 설정

Xcode에서 각 타깃의 Signing & Capabilities에서 개발 팀을 선택하세요.

## 프로젝트 구조

```
LivePlan/
├── AppCore/                 # 도메인 로직 (Swift Package)
│   ├── Models/              # 엔티티 (Project, Task, Tag 등)
│   ├── UseCases/            # 비즈니스 로직
│   └── Parsing/             # QuickAdd 파서
├── AppStorage/              # 저장소 구현 (Swift Package)
├── LivePlan/                # 메인 앱 UI
├── LivePlanWidgetExtension/ # 위젯
├── LivePlanIntents/         # App Intents
├── Docs/                    # 문서
└── project.yml              # XcodeGen 설정
```

## 문서

- [Phase 2 로드맵](Docs/PHASE2_ROADMAP.md)
- [배포 가이드](Docs/DEPLOYMENT_GUIDE.md)
- [릴리즈 노트](Docs/ReleaseNotes_2.0.md)

## 라이선스

Private - All rights reserved
