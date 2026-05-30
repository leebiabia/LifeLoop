import Foundation
import SwiftData

@Model
final class GoalItem {
    var id: UUID
    var name: String
    var desc: String
    var createdAt: Date
    var goalTypeRaw: String
    var color: String
    var icon: String
    var totalRecords: Int

    // ProgressGoal / AccumulationGoal fields
    var targetValue: Double?
    var currentValue: Double?
    var unit: String?

    @Relationship(deleteRule: .cascade)
    var records: [GoalRecord]?

    init(
        id: UUID = UUID(),
        name: String,
        desc: String = "",
        createdAt: Date = Date(),
        goalType: GoalType = .progress,
        color: String = "#007AFF",
        icon: String = "target",
        totalRecords: Int = 0,
        targetValue: Double? = nil,
        currentValue: Double? = nil,
        unit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.createdAt = createdAt
        self.goalTypeRaw = goalType.rawValue
        self.color = color
        self.icon = icon
        self.totalRecords = totalRecords
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
    }

    var goalType: GoalType {
        GoalType(rawValue: goalTypeRaw) ?? .progress
    }

    var ringProgress: Double {
        switch goalType {
        case .progress, .accumulation:
            guard let target = targetValue, let current = currentValue, target > 0 else {
                return 0
            }
            return min(current / target, 1.0)
        case .lifetime:
            guard let records = records, !records.isEmpty else { return 0 }
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentDates = Set(records.filter { $0.date >= thirtyDaysAgo }.map {
                Calendar.current.startOfDay(for: $0.date)
            })
            return min(Double(recentDates.count) / 30.0, 1.0)
        }
    }

    var isCompleted: Bool {
        guard let target = targetValue, let current = currentValue, target > 0 else {
            return false
        }
        return current >= target
    }
}
