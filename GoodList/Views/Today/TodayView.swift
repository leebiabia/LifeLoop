import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let vm = viewModel {
                    VStack(spacing: 16) {
                        heroSection(vm: vm)
                        taskSection(vm: vm)
                        habitSection(vm: vm)
                        periodSection(vm: vm)
                    }
                    .padding(.horizontal, 20)
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("今天")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                let doRepo = DoRepository(context: modelContext)
                viewModel = TodayViewModel(doRepo: doRepo)
                viewModel?.loadData()
            }
        }
    }

    @ViewBuilder
    func heroSection(vm: TodayViewModel) -> some View {
        RingBorderView(progress: vm.completionPercentage, color: .blue, ringWidth: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日完成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(vm.completedTodayTasks.count)/\(vm.todayTasks.count + vm.completedTodayTasks.count)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                Text("\(Int(vm.completionPercentage * 100))%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    func taskSection(vm: TodayViewModel) -> some View {
        if !vm.todayTasks.isEmpty || !vm.completedTodayTasks.isEmpty {
            sectionHeader("今日任务", color: .blue, count: "剩余 \(vm.todayTasks.count) 项")
            ForEach(vm.todayTasks) { task in taskRow(task, vm: vm) }
            ForEach(vm.completedTodayTasks) { task in taskRow(task, vm: vm) }
        }
    }

    @ViewBuilder
    func habitSection(vm: TodayViewModel) -> some View {
        if !vm.habits.isEmpty {
            sectionHeader("习惯打卡", color: .green, count: "\(vm.habits.count) 项")
            ForEach(vm.habits) { habit in habitRow(habit, vm: vm) }
        }
    }

    @ViewBuilder
    func periodSection(vm: TodayViewModel) -> some View {
        if !vm.dueTodayPeriodTasks.isEmpty || !vm.overduePeriodTasks.isEmpty {
            sectionHeader("时期任务", color: .orange, count: "")
            ForEach(vm.dueTodayPeriodTasks) { task in periodRow(task, status: "今日截止", color: .orange) }
            ForEach(vm.overduePeriodTasks) { task in periodRow(task, status: "已逾期", color: .red) }
        }
    }

    func sectionHeader(_ title: String, color: Color, count: String) -> some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            Spacer()
            if !count.isEmpty { Text(count).font(.caption2).foregroundColor(.secondary) }
        }
    }

    func taskRow(_ task: DoItem, vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Button { vm.toggleTask(task) } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .blue : .gray.opacity(0.4))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name).font(.subheadline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                if !task.note.isEmpty {
                    Text(task.note).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            if let deadline = task.deadline {
                Text(deadline.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).fontWeight(.medium)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(deadline.isOverdue ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundColor(deadline.isOverdue ? .red : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
    }

    func habitRow(_ habit: DoItem, vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.subheadline).fontWeight(.medium)
                Text("连续 \(habit.currentStreak) 天 · 累计 \(habit.totalCount) 次")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Button { vm.recordHabit(habit) } label: {
                Text("打卡").font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Color.green).foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
    }

    func periodRow(_ task: DoItem, status: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8)
                .overlay(Circle().stroke(color.opacity(0.2), lineWidth: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name).font(.subheadline).fontWeight(.medium)
                Text(status).font(.caption2).foregroundColor(color)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
