import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("今日")
                }

            InboxView()
                .tabItem {
                    Image(systemName: "tray")
                    Text("收集箱")
                }

            GoalListView()
                .tabItem {
                    Image(systemName: "scope")
                    Text("目标")
                }

            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我的")
                }
        }
        .tint(.blue)
    }
}

// MARK: - Placeholder views (to be replaced by real implementations)
// GoalListView is implemented in GoodList/Views/Goal/GoalListView.swift
struct InboxView: View { var body: some View { Text("收集箱") } }
struct StatsView: View { var body: some View { Text("统计") } }
struct SettingsView: View { var body: some View { Text("我的") } }
