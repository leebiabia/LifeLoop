import Foundation
import SwiftData
import Observation

@Observable
final class GoalRepository {
    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [GoalItem] {
        return try context.fetch(FetchDescriptor<GoalItem>())
    }

    func fetchActive() throws -> [GoalItem] {
        var all = try context.fetch(FetchDescriptor<GoalItem>())
        return all.filter { !$0.isCompleted || $0.goalType == .lifetime }
    }

    func fetchCompleted() throws -> [GoalItem] {
        var all = try context.fetch(FetchDescriptor<GoalItem>())
        return all.filter { $0.isCompleted && $0.goalType != .lifetime }
    }

    func createProgressGoal(name: String, desc: String = "", targetValue: Double,
                            unit: String = "", color: String = "#007AFF", icon: String = "target") {
        let goal = GoalItem(name: name, desc: desc, goalType: .progress,
                            color: color, icon: icon, targetValue: targetValue,
                            currentValue: 0, unit: unit)
        context.insert(goal)
        try? context.save()
    }

    func createAccumulationGoal(name: String, desc: String = "", targetValue: Double,
                                unit: String = "", color: String = "#5856D6", icon: String = "target") {
        let goal = GoalItem(name: name, desc: desc, goalType: .accumulation,
                            color: color, icon: icon, targetValue: targetValue,
                            currentValue: 0, unit: unit)
        context.insert(goal)
        try? context.save()
    }

    func createLifetimeGoal(name: String, desc: String = "", color: String = "#FF9500",
                            icon: String = "infinity") {
        let goal = GoalItem(name: name, desc: desc, goalType: .lifetime, color: color, icon: icon)
        context.insert(goal)
        try? context.save()
    }

    func addRecord(to goal: GoalItem, value: Double = 1, note: String = "") {
        let record = GoalRecord(date: Date(), value: value, note: note)
        if goal.records == nil {
            goal.records = []
        }
        goal.records?.append(record)
        goal.totalRecords += 1

        if goal.goalType == .accumulation || goal.goalType == .progress {
            goal.currentValue = (goal.currentValue ?? 0) + value
        }
        try? context.save()
    }

    func updateProgress(goal: GoalItem, currentValue: Double) {
        goal.currentValue = currentValue
        try? context.save()
    }

    func delete(_ goal: GoalItem) {
        context.delete(goal)
        try? context.save()
    }
}
