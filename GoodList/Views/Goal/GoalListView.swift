import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: GoalViewModel?
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let vm = viewModel {
                    VStack(spacing: 16) {
                        ForEach(vm.goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal, viewModel: vm)) {
                                goalCard(goal)
                            }
                            .buttonStyle(.plain)
                        }

                        if !vm.completedGoals.isEmpty {
                            HStack {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("已完成").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Spacer()
                            }
                            ForEach(vm.completedGoals) { goal in
                                goalCard(goal)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("目标")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                Button { showCreateSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateGoalSheet(viewModel: viewModel!)
            }
            .onAppear {
                let goalRepo = GoalRepository(context: modelContext)
                viewModel = GoalViewModel(goalRepo: goalRepo)
                viewModel?.loadData()
            }
        }
    }

    @ViewBuilder
    func goalCard(_ goal: GoalItem) -> some View {
        RingBorderView(progress: goal.ringProgress, color: Color(hex: goal.color), ringWidth: 6) {
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: goal.color).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name).font(.subheadline).fontWeight(.semibold)
                    Text(goal.desc).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.ringProgress * 100))%")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(Color(hex: goal.color))
                    if let current = goal.currentValue, let target = goal.targetValue {
                        Text("\(String(format: "%.0f", current))/\(String(format: "%.0f", target))\(goal.unit ?? "")")
                            .font(.caption2).foregroundColor(.secondary)
                    } else {
                        Text("\(goal.totalRecords) 次")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

struct CreateGoalSheet: View {
    let viewModel: GoalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var desc = ""
    @State private var selectedType: GoalType = .progress
    @State private var targetValue: Double = 100
    @State private var unit = ""
    @State private var selectedColor = "#007AFF"

    private let colors = ["#007AFF", "#34C759", "#FF9500", "#AF52DE", "#5856D6", "#FF3B30"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("目标名称", text: $name)
                TextField("描述（可选）", text: $desc)
                Picker("类型", selection: $selectedType) {
                    ForEach(GoalType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                if selectedType != .lifetime {
                    HStack {
                        Text("目标值")
                        TextField("100", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    TextField("单位（如：本、kg、万）", text: $unit)
                }
                HStack {
                    Text("颜色")
                    Spacer()
                    ForEach(colors, id: \.self) { color in
                        Circle().fill(Color(hex: color)).frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0))
                            .onTapGesture { selectedColor = color }
                    }
                }
            }
            .navigationTitle("新建目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        switch selectedType {
                        case .progress:
                            viewModel.createProgressGoal(name: name, desc: desc, target: targetValue, unit: unit, color: selectedColor)
                        case .accumulation:
                            viewModel.createAccumulationGoal(name: name, desc: desc, target: targetValue, unit: unit, color: selectedColor)
                        case .lifetime:
                            viewModel.createLifetimeGoal(name: name, desc: desc, color: selectedColor)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
