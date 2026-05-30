import Foundation
import SwiftData

@Model
final class GoalRecord {
    var id: UUID
    var date: Date
    var value: Double
    var note: String

    @Relationship(inverse: \GoalItem.records) var goal: GoalItem?

    init(id: UUID = UUID(), date: Date = Date(), value: Double = 1, note: String = "") {
        self.id = id
        self.date = date
        self.value = value
        self.note = note
    }
}
