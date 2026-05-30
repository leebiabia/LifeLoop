import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var allDoItems: [DoItem]
    @Query private var allGoals: [GoalItem]

    var completedTasks: Int {
        allDoItems.filter { $0.doType == .today && $0.isCompleted }.count
    }
    var totalTasks: Int {
        allDoItems.filter { $0.doType == .today }.count
    }
    var habitTotalCount: Int {
        allDoItems.filter { $0.doType == .habit }.reduce(0) { $0 + $1.totalCount }
    }
    var maxStreak: Int {
        allDoItems.filter { $0.doType == .habit }.map { $0.currentStreak }.max() ?? 0
    }
    var completedGoals: Int {
        allGoals.filter { $0.isCompleted && $0.goalType != .lifetime }.count
    }
    var totalRecords: Int {
        allGoals.reduce(0) { $0 + $1.totalRecords }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statSection("任务统计", color: .blue) {
                        StatRow(title: "完成任务", value: "\(completedTasks)")
                        StatRow(title: "总任务", value: "\(totalTasks)")
                        StatRow(title: "完成率", value: totalTasks > 0 ? "\(Int(Double(completedTasks)/Double(totalTasks)*100))%" : "-")
                    }

                    statSection("打卡统计", color: .green) {
                        StatRow(title: "累计打卡", value: "\(habitTotalCount)")
                        StatRow(title: "最长连续", value: "\(maxStreak) 天")
                        StatRow(title: "活跃习惯", value: "\(allDoItems.filter { $0.doType == .habit }.count)")
                    }

                    statSection("目标统计", color: .purple) {
                        StatRow(title: "进行中", value: "\(allGoals.count - completedGoals)")
                        StatRow(title: "已完成", value: "\(completedGoals)")
                        StatRow(title: "累计记录", value: "\(totalRecords)")
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
        }
    }

    @ViewBuilder
    func statSection(_ title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(title).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            }
            VStack(spacing: 0) { content() }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value).font(.headline).fontWeight(.bold)
        }
        .padding(14)
    }
}
