import SwiftUI
import AppCore

/// 캘린더 뷰 - dueDate 기준 월별 캘린더
/// - product-decisions.md 1.2: Calendar 뷰 (dueAt 기준)
/// - 읽기 전용
struct ProjectCalendarView: View {
    let tasks: [Task]
    let isTaskCompleted: (Task) -> Bool
    let onToggleComplete: (Task) -> Void

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // 월 네비게이션
            monthHeader

            // 요일 헤더
            weekdayHeader

            // 캘린더 그리드
            calendarGrid

            Divider()

            // 선택된 날짜의 태스크 목록
            selectedDateTaskList
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString(displayedMonth))
                .font(.headline)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

        return HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        taskCount: tasksForDate(date).count,
                        hasOverdue: hasOverdueTask(on: date)
                    ) {
                        selectedDate = date
                    }
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Selected Date Task List

    private var selectedDateTaskList: some View {
        let dateTasks = tasksForDate(selectedDate)
        let unscheduledTasks = tasksWithoutDueDate

        return List {
            // 선택된 날짜의 태스크
            Section(header: Text(selectedDateHeader)) {
                if dateTasks.isEmpty {
                    Text("마감일이 이 날짜인 할 일이 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(dateTasks) { task in
                        TaskRowView(
                            task: task,
                            isCompleted: isTaskCompleted(task),
                            onToggle: { onToggleComplete(task) }
                        )
                    }
                }
            }

            // 마감일 없는 태스크 (미정)
            if !unscheduledTasks.isEmpty {
                Section("미정") {
                    ForEach(unscheduledTasks) { task in
                        TaskRowView(
                            task: task,
                            isCompleted: isTaskCompleted(task),
                            onToggle: { onToggleComplete(task) }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    private var selectedDateHeader: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: selectedDate)
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }

    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // 6주 (42일) 그리드
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: displayedMonth, toGranularity: .month) {
                days.append(currentDate)
            } else if days.isEmpty || days.count < 35 {
                days.append(nil) // 이전/다음 달 빈칸
            }

            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            }
        }

        // 불필요한 후행 nil 제거
        while days.last == nil && days.count > 35 {
            days.removeLast()
        }

        return days
    }

    private func tasksForDate(_ date: Date) -> [Task] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }

    private var tasksWithoutDueDate: [Task] {
        tasks.filter { $0.dueDate == nil }
    }

    private func hasOverdueTask(on date: Date) -> Bool {
        tasksForDate(date).contains { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !isTaskCompleted(task)
        }
    }
}

// MARK: - CalendarDayCell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let taskCount: Int
    let hasOverdue: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(textColor)

                // 태스크 dot 표시
                if taskCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(hasOverdue ? Color.red : Color.blue)
                                .frame(width: 4, height: 4)
                        }
                        if taskCount > 3 {
                            Text("+")
                                .font(.system(size: 6))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        }
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { // 일요일
            return .red
        } else if weekday == 7 { // 토요일
            return .blue
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return Color.blue.opacity(0.1)
        }
        return .clear
    }
}

// MARK: - Preview

#Preview("Calendar View") {
    let today = Date()
    let calendar = Calendar.current

    let sampleTasks = [
        Task(projectId: "p1", title: "오늘 마감", dueDate: today),
        Task(projectId: "p1", title: "내일 마감", dueDate: calendar.date(byAdding: .day, value: 1, to: today)),
        Task(projectId: "p1", title: "내일 마감 2", dueDate: calendar.date(byAdding: .day, value: 1, to: today)),
        Task(projectId: "p1", title: "다음주 마감", dueDate: calendar.date(byAdding: .day, value: 7, to: today)),
        Task(projectId: "p1", title: "마감 없음"),
        Task(projectId: "p1", title: "지연된 일", dueDate: calendar.date(byAdding: .day, value: -2, to: today)),
    ]

    return ProjectCalendarView(
        tasks: sampleTasks,
        isTaskCompleted: { _ in false },
        onToggleComplete: { _ in }
    )
}

#Preview("Empty Calendar") {
    ProjectCalendarView(
        tasks: [],
        isTaskCompleted: { _ in false },
        onToggleComplete: { _ in }
    )
}
