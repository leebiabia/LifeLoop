import Foundation
import SwiftData

@Model
final class HabitRecord {
    var id: UUID
    var date: Date
    var completedAt: Date
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), completedAt: Date = Date(), note: String = "") {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.note = note
    }
}
