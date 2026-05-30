import SwiftUI
import SwiftData

@main
struct LifeLoopApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            DoItem.self,
            HabitRecord.self,
            GoalItem.self,
            GoalRecord.self,
            Tag.self
        ])
    }
}
