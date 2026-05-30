import Foundation
import SwiftData

@Model
final class DoItem {
    var id: UUID
    var name: String
    var note: String
    var createdAt: Date
    var doTypeRaw: String
    var priorityRaw: Int

    // TodayTask fields
    var startTime: Date?
    var deadline: Date?
    var isCompleted: Bool

    // HabitTask fields
    var habitStartDate: Date?
    var habitEndDate: Date?
    var reminderTime: Date?
    var cycleType: String?
    var customDates: [Date]?
    var currentStreak: Int
    var totalCount: Int
    var completionRate: Double

    // PeriodTask fields
    var periodStartDate: Date?
    var periodEndDate: Date?
    var periodIsCompleted: Bool

    @Relationship(deleteRule: .cascade)
    var habitRecords: [HabitRecord]?

    var tags: [Tag]?

    init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        doType: DoType = .today,
        priority: Priority = .medium,
        startTime: Date? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        habitStartDate: Date? = nil,
        habitEndDate: Date? = nil,
        reminderTime: Date? = nil,
        cycleType: String? = nil,
        customDates: [Date]? = nil,
        currentStreak: Int = 0,
        totalCount: Int = 0,
        completionRate: Double = 0,
        periodStartDate: Date? = nil,
        periodEndDate: Date? = nil,
        periodIsCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = Date()
        self.doTypeRaw = doType.rawValue
        self.priorityRaw = priority.rawValue
        self.startTime = startTime
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.habitStartDate = habitStartDate
        self.habitEndDate = habitEndDate
        self.reminderTime = reminderTime
        self.cycleType = cycleType
        self.customDates = customDates
        self.currentStreak = currentStreak
        self.totalCount = totalCount
        self.completionRate = completionRate
        self.periodStartDate = periodStartDate
        self.periodEndDate = periodEndDate
        self.periodIsCompleted = periodIsCompleted
    }

    var doType: DoType {
        DoType(rawValue: doTypeRaw) ?? .today
    }

    var priority: Priority {
        Priority(rawValue: priorityRaw) ?? .medium
    }

    var periodStatus: PeriodStatus {
        guard doType == .period, let start = periodStartDate, let end = periodEndDate else {
            return .none
        }
        let now = Date()
        if periodIsCompleted { return .completed }
        if now > end { return .overdue }
        if Calendar.current.isDateInToday(end) || now >= end { return .dueToday }
        if now >= start { return .active }
        return .upcoming
    }
}

enum PeriodStatus {
    case none, upcoming, active, dueToday, overdue, completed
}
