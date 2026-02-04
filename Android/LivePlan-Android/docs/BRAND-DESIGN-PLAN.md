# LivePlan Android 브랜드 디자인 적용 계획

Last Updated: 2026-02-04 12:00:00

## 목적

`files/` 폴더의 TaskCheck 브랜드 디자인 가이드라인을 LivePlan Android 앱 UI에 적용하기 위한 세부 계획 및 티켓 정의.

---

## 📊 현재 상태 분석

### 브랜드 가이드라인 (TaskCheck Design Tokens)

| 요소 | 값 | 설명 |
|------|-----|------|
| **Primary 500** | `#1E9CD7` | 메인 브랜드 컬러 (파랑) |
| **Gradient** | `#6DD3F7 → #1E9CD7` | 브랜드 그라데이션 |
| **Success** | `#10B981` | 완료/성공 |
| **Warning** | `#F59E0B` | 경고 |
| **Error** | `#EF4444` | 오류 |
| **Typography** | Pretendard, Noto Sans KR | 한글 폰트 |
| **Spacing** | 4px 기반 (4, 8, 12, 16, 24...) | 스페이싱 시스템 |
| **Border Radius** | sm(4), md(8), lg(12), xl(16) | 라운딩 |

### 현재 앱 상태

| 파일 | 문제점 |
|------|--------|
| `app/.../ui/theme/Color.kt` | Android 기본 Purple/Pink 템플릿 사용 중 |
| `app/.../ui/theme/Type.kt` | bodyLarge만 정의, 나머지 주석 처리 |
| `app/.../ui/theme/Theme.kt` | Dynamic Color 우선, 브랜드 스킴 미정의 |
| `widget/.../ui/WidgetTheme.kt` | 별도 색상 정의 (#6200EE 등) |
| `app/.../ui/common/PriorityBadge.kt` | 하드코딩된 색상값 |
| `app/.../res/values/colors.xml` | 기본 purple/teal 색상 |

---

## 🎯 적용 전략

### 원칙

1. **SSOT (Single Source of Truth)**: 브랜드 색상을 한 곳(Color.kt)에서 정의
2. **점진적 적용**: 테마 기반 → 컴포넌트 → 위젯 순으로 진행
3. **하위 호환성**: Dynamic Color 폴백 유지
4. **테스트**: 각 단계별 UI 테스트 수행

---

## 📋 구현 티켓

### **Ticket #1: 브랜드 색상 시스템 정의**

**Priority**: P1 (최우선)
**Estimate**: 2시간
**Dependencies**: 없음

**작업 내용**:

1. `app/src/main/java/com/liveplan/ui/theme/Color.kt` 완전 재작성
   - Primary 색상 팔레트 (50~900)
   - Secondary 색상 팔레트
   - Neutral 색상 팔레트
   - Semantic 색상 (Success, Warning, Error, Info)
   - Background 색상

2. 브랜드 그라데이션 정의
   ```kotlin
   val BrandGradient = Brush.verticalGradient(
       colors = listOf(Primary300, Primary500)
   )
   ```

**산출물**:
```kotlin
// Primary Colors
val Primary50 = Color(0xFFE8F7FC)
val Primary100 = Color(0xFFC5ECF8)
val Primary200 = Color(0xFFA8E5F7)
val Primary300 = Color(0xFF6DD3F7)
val Primary400 = Color(0xFF3BB5E8)
val Primary500 = Color(0xFF1E9CD7)  // Main
val Primary600 = Color(0xFF1A86B8)
val Primary700 = Color(0xFF156F99)
val Primary800 = Color(0xFF11597A)
val Primary900 = Color(0xFF0D435B)

// Semantic Colors
val Success = Color(0xFF10B981)
val Warning = Color(0xFFF59E0B)
val Error = Color(0xFFEF4444)
```

---

### **Ticket #2: Material3 Color Scheme 구성**

**Priority**: P1
**Estimate**: 2시간
**Dependencies**: Ticket #1

**작업 내용**:

1. `app/src/main/java/com/liveplan/ui/theme/Theme.kt` 수정
   - LightColorScheme 브랜드 색상으로 구성
   - DarkColorScheme 다크모드 색상 구성
   - Dynamic Color를 기본값 false로 변경 (브랜드 일관성)

2. Color Scheme 매핑:

   | Material Role | Light Mode | Dark Mode |
   |---------------|------------|-----------|
   | primary | Primary500 | Primary300 |
   | onPrimary | White | Primary900 |
   | primaryContainer | Primary100 | Primary800 |
   | secondary | Primary400 | Primary200 |
   | background | Neutral50 | Neutral900 |
   | surface | White | Neutral800 |
   | error | Error | Error |

**산출물**:
- 브랜드 Light/Dark Color Scheme
- Dynamic Color 폴백 유지

---

### **Ticket #3: Typography 시스템 정의**

**Priority**: P2
**Estimate**: 1.5시간
**Dependencies**: 없음

**작업 내용**:

1. `app/src/main/java/com/liveplan/ui/theme/Type.kt` 완전 재작성

2. 브랜드 Typography 스케일 적용:

   | Style | Size | Weight | Line Height |
   |-------|------|--------|-------------|
   | displayLarge | 36sp | Bold | 1.2 |
   | headlineLarge | 28sp | Bold | 1.3 |
   | headlineMedium | 24sp | SemiBold | 1.4 |
   | headlineSmall | 20sp | SemiBold | 1.4 |
   | titleLarge | 18sp | SemiBold | 1.5 |
   | titleMedium | 16sp | Medium | 1.5 |
   | bodyLarge | 16sp | Normal | 1.6 |
   | bodyMedium | 14sp | Normal | 1.5 |
   | labelLarge | 14sp | Medium | 1.4 |
   | labelSmall | 12sp | Normal | 1.4 |

3. FontFamily 정의 (시스템 폰트 사용, 커스텀 폰트는 Phase 2)

---

### **Ticket #4: Spacing & Shape 시스템 정의**

**Priority**: P2
**Estimate**: 1시간
**Dependencies**: 없음

**작업 내용**:

1. 새 파일 생성: `app/src/main/java/com/liveplan/ui/theme/Dimensions.kt`
   ```kotlin
   object Spacing {
       val xs = 4.dp
       val sm = 8.dp
       val md = 12.dp
       val lg = 16.dp
       val xl = 24.dp
       val xxl = 32.dp
   }

   object Radius {
       val sm = 4.dp
       val md = 8.dp
       val lg = 12.dp
       val xl = 16.dp
       val xxl = 24.dp
   }
   ```

2. `Theme.kt`에 Shapes 정의:
   ```kotlin
   val LivePlanShapes = Shapes(
       small = RoundedCornerShape(4.dp),
       medium = RoundedCornerShape(8.dp),
       large = RoundedCornerShape(12.dp)
   )
   ```

---

### **Ticket #5: 공통 컴포넌트 색상 통합**

**Priority**: P2
**Estimate**: 3시간
**Dependencies**: Ticket #1, #2

**작업 내용**:

1. `app/src/main/java/com/liveplan/ui/common/PriorityBadge.kt` 수정
   - 하드코딩된 색상 → 테마 기반으로 변경
   - P1(Error), P2(Warning), P3(Primary), P4(Neutral)로 매핑

2. `app/src/main/java/com/liveplan/ui/common/TaskRow.kt` 수정
   - getPriorityColor() 함수를 테마 색상 사용하도록 수정

3. `app/src/main/java/com/liveplan/ui/common/ProjectCard.kt` 검토
   - MaterialTheme 사용 확인 (이미 테마 기반)

4. 기타 공통 컴포넌트 검토 및 수정
   - `EmptyState.kt`
   - `ErrorState.kt`
   - `LoadingState.kt`

---

### **Ticket #6: 위젯 테마 브랜드 통합**

**Priority**: P2
**Estimate**: 2시간
**Dependencies**: Ticket #1

**작업 내용**:

1. `widget/src/main/kotlin/com/liveplan/widget/ui/WidgetTheme.kt` 수정
   - RawColors를 브랜드 색상으로 교체
   - Primary: `#6200EE` → `#1E9CD7`

2. `widget/src/main/res/values/colors.xml` 수정
   - widget_primary: `#6200EE` → `#1E9CD7`
   - 브랜드 색상 팔레트 추가

3. 위젯 UI 파일 검토
   - `MediumWidget.kt`
   - `SmallWidget.kt`

---

### **Ticket #7: XML 리소스 브랜드 색상 적용**

**Priority**: P3
**Estimate**: 1시간
**Dependencies**: Ticket #1

**작업 내용**:

1. `app/src/main/res/values/colors.xml` 수정
   - 브랜드 Primary 색상 추가
   - Legacy purple/teal 유지 (호환성)

2. `app/src/main/res/values/themes.xml` 수정
   - colorPrimary, colorPrimaryVariant, colorSecondary 설정
   - Splash screen 색상 설정 (필요시)

3. `values-night/colors.xml` 생성 (다크모드 지원)

---

### **Ticket #8: 화면별 UI 일관성 검토**

**Priority**: P3
**Estimate**: 2시간
**Dependencies**: Ticket #5

**작업 내용**:

1. 각 화면에서 하드코딩된 색상 검색 및 수정:
   - `ProjectListScreen.kt`
   - `ProjectDetailScreen.kt`
   - `TaskCreateScreen.kt`
   - `TaskDetailScreen.kt`
   - `KanbanBoardScreen.kt`
   - `CalendarScreen.kt`
   - `SettingsScreen.kt`
   - `SearchScreen.kt`
   - `FilterListScreen.kt`
   - `FilterBuilderScreen.kt`

2. Grep으로 `Color(0x` 패턴 검색하여 하드코딩 색상 제거

---

### **Ticket #9: 그라데이션 & 그림자 적용**

**Priority**: P4
**Estimate**: 1.5시간
**Dependencies**: Ticket #1

**작업 내용**:

1. 브랜드 그라데이션 Brush 정의

2. 브랜드 그림자 (Shadow) 정의
   ```kotlin
   object Elevation {
       val sm = 2.dp   // shadow-sm
       val md = 6.dp   // shadow-md
       val lg = 15.dp  // shadow-lg
   }
   ```

3. 주요 컴포넌트에 그라데이션 적용 검토 (버튼, 헤더 등)

---

### **Ticket #10: UI 테스트 업데이트**

**Priority**: P3
**Estimate**: 1.5시간
**Dependencies**: Ticket #5, #6, #8

**작업 내용**:

1. 기존 UI 테스트 실행 확인
   - `EmptyStateTest.kt`
   - `ErrorStateTest.kt`
   - `LoadingStateTest.kt`
   - 기타 Screen 테스트들

2. 필요시 Preview 업데이트

---

## 📅 구현 순서 (의존성 기반)

```
Phase 1: 기반 작업 (병렬 가능)
├── Ticket #1: 브랜드 색상 시스템 정의 ⭐
├── Ticket #3: Typography 시스템 정의
└── Ticket #4: Spacing & Shape 시스템 정의

Phase 2: 테마 통합
└── Ticket #2: Material3 Color Scheme 구성 (depends: #1)

Phase 3: 컴포넌트 적용 (병렬 가능)
├── Ticket #5: 공통 컴포넌트 색상 통합 (depends: #1, #2)
├── Ticket #6: 위젯 테마 브랜드 통합 (depends: #1)
└── Ticket #7: XML 리소스 브랜드 색상 적용 (depends: #1)

Phase 4: 화면 적용 & 마무리
├── Ticket #8: 화면별 UI 일관성 검토 (depends: #5)
├── Ticket #9: 그라데이션 & 그림자 적용 (depends: #1)
└── Ticket #10: UI 테스트 업데이트 (depends: #5, #6, #8)
```

---

## ⚠️ 주의사항

1. **performance.md 준수**: 커스텀 폰트 도입 금지 (Phase 1)
2. **ui-style.md 준수**: 외부 UI 프레임워크 금지
3. **기존 기능 유지**: 색상 변경으로 인한 기능 손상 없어야 함
4. **Dynamic Color 폴백**: Android 12+ 사용자에게 선택권 유지 (설정에서 토글 가능하도록 고려)

---

## 🧪 검증 체크리스트

- [ ] 모든 화면에서 브랜드 Primary 색상 (#1E9CD7) 적용 확인
- [ ] Light/Dark 모드 전환 시 색상 일관성 확인
- [ ] 위젯에서 브랜드 색상 적용 확인
- [ ] Priority Badge P1~P4 색상 구분 명확
- [ ] 오류/경고/성공 상태 색상 (Semantic) 동작 확인
- [ ] 기존 UI 테스트 통과 확인
- [ ] 접근성: 색상 대비 충분한지 확인 (WCAG 2.1 AA)

---

## 참조 파일

- 브랜드 토큰: `Android/files/tokens.json`
- CSS 변수: `Android/files/variables.css`
- 가이드라인: `Android/files/CLAUDE.md`, `Android/files/README.md`

끝.
