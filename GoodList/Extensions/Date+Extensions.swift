import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isOverdue: Bool {
        self < Date() && !Calendar.current.isDateInToday(self)
    }

    static var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    static var todayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
    }

    func daysFrom(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }
}
