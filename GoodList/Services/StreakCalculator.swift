import Foundation

enum StreakCalculator {
    static func calculateStreak(for habit: DoItem) -> Int {
        guard habit.doType == .habit, let records = habit.habitRecords, !records.isEmpty else {
            return 0
        }
        let today = Calendar.current.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        while true {
            let hasRecord = records.contains { record in
                Calendar.current.isDate(record.date, inSameDayAs: checkDate)
            }
            if hasRecord {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                if checkDate == today {
                    checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                    continue
                }
                break
            }
        }
        return streak
    }

    static func calculateCompletionRate(for habit: DoItem) -> Double {
        guard habit.doType == .habit, let startDate = habit.habitStartDate,
              let records = habit.habitRecords, !records.isEmpty else {
            return 0
        }
        let totalDays = max(Date().daysFrom(startDate) + 1, 1)
        let recordedDays = Set(records.map { $0.date.startOfDay }).count
        return min(Double(recordedDays) / Double(totalDays), 1.0)
    }

    static func recentActivityDays(for goal: GoalItem) -> Int {
        guard let records = goal.records, !records.isEmpty else { return 0 }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentDates = records.filter { $0.date >= thirtyDaysAgo }.map { $0.date.startOfDay }
        return Set(recentDates).count
    }
}
