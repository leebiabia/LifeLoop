import Foundation
import SwiftData
import Observation

@Observable
final class DoRepository {
    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTodayTasks() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.today.rawValue && !$0.isCompleted }
        )
        return try context.fetch(descriptor)
    }

    func fetchCompletedTodayTasks() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.today.rawValue && $0.isCompleted }
        )
        return try context.fetch(descriptor)
    }

    func fetchHabits() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.habit.rawValue }
        )
        return try context.fetch(descriptor)
    }

    func fetchActivePeriodTasks() throws -> [DoItem] {
        let now = Date()
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate {
                $0.doTypeRaw == DoType.period.rawValue &&
                $0.periodStartDate != nil &&
                $0.periodStartDate! <= now &&
                !$0.periodIsCompleted
            }
        )
        return try context.fetch(descriptor)
    }

    func fetchUpcomingPeriodTasks() throws -> [DoItem] {
        let now = Date()
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate {
                $0.doTypeRaw == DoType.period.rawValue &&
                $0.periodStartDate != nil &&
                $0.periodStartDate! > now
            }
        )
        return try context.fetch(descriptor)
    }

    func fetchAllDoItems() throws -> [DoItem] {
        return try context.fetch(FetchDescriptor<DoItem>())
    }

    func createTodayTask(name: String, note: String = "", priority: Priority = .medium,
                         startTime: Date? = nil, deadline: Date? = nil, tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .today, priority: priority,
                          startTime: startTime, deadline: deadline, isCompleted: false)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func createHabit(name: String, note: String = "", cycleType: CycleType = .daily,
                     reminderTime: Date? = nil, startDate: Date = Date(),
                     endDate: Date? = nil, tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .habit,
                          habitStartDate: startDate, habitEndDate: endDate,
                          reminderTime: reminderTime, cycleType: cycleType)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func createPeriodTask(name: String, note: String = "", startDate: Date, endDate: Date,
                          tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .period,
                          periodStartDate: startDate, periodEndDate: endDate)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func toggleComplete(_ item: DoItem) {
        item.isCompleted.toggle()
        try? context.save()
    }

    func recordHabit(_ habit: DoItem, note: String = "") {
        guard habit.doType == .habit else { return }
        let record = HabitRecord(date: Date(), note: note)
        if habit.habitRecords == nil {
            habit.habitRecords = []
        }
        habit.habitRecords?.append(record)
        habit.totalCount += 1

        let today = Calendar.current.startOfDay(for: Date())
        var streak = 1
        var checkDate = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        while true {
            let hasRecord = habit.habitRecords?.contains { record in
                Calendar.current.isDate(record.date, inSameDayAs: checkDate)
            } ?? false
            if hasRecord {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        habit.currentStreak = streak
        habit.completionRate = habit.totalCount > 0 ? 1.0 : 0.0
        try? context.save()
    }

    func completePeriodTask(_ item: DoItem) {
        guard item.doType == .period else { return }
        item.periodIsCompleted = true
        try? context.save()
    }

    func delete(_ item: DoItem) {
        context.delete(item)
        try? context.save()
    }
}
