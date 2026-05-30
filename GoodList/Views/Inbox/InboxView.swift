import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InboxViewModel()
    @State private var showCreateSheet = false
    @State private var createType: InboxCreateType?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("快速记录一个想法...", text: $viewModel.inputText, axis: .vertical)
                    .font(.title3)
                    .padding()
                    .frame(minHeight: 80, alignment: .top)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.quickActions, id: \.self) { type in
                        Button {
                            createType = type
                            showCreateSheet = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: type.icon).font(.title2)
                                Text(type.title).font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("收集箱")
            .sheet(isPresented: $showCreateSheet) {
                if let type = createType {
                    InboxCreateSheet(type: type, presetName: viewModel.inputText) {
                        viewModel.inputText = ""
                    }
                }
            }
        }
    }
}

// MARK: - Create Sheet

struct InboxCreateSheet: View {
    let type: InboxCreateType
    let presetName: String
    let onCreated: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var note = ""
    @State private var deadline = Date().addingTimeInterval(3600)
    @State private var hasDeadline = false
    @State private var cycleType: CycleType = .daily
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var targetValue: Double = 100
    @State private var unit = ""
    @State private var selectedColor = "#007AFF"

    private let colors = ["#007AFF", "#34C759", "#FF9500", "#AF52DE", "#5856D6", "#FF3B30"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $name)

                if type == .doToday {
                    Toggle("设置截止时间", isOn: $hasDeadline)
                    if hasDeadline { DatePicker("截止时间", selection: $deadline) }
                }

                if type == .doHabit {
                    Picker("周期", selection: $cycleType) {
                        ForEach(CycleType.allCases, id: \.self) { c in Text(c.title).tag(c) }
                    }
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                }

                if type == .doPeriod {
                    DatePicker("开始", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束", selection: $endDate, displayedComponents: .date)
                }

                if type == .goalProgress || type == .goalAccumulation {
                    HStack {
                        Text("目标值")
                        TextField("100", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    TextField("单位", text: $unit)
                }

                if type == .goalProgress || type == .goalAccumulation || type == .goalLifetime {
                    HStack {
                        Text("颜色")
                        ForEach(colors, id: \.self) { c in
                            Circle().fill(Color(hex: c)).frame(width: 20)
                                .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == c ? 3 : 0))
                                .onTapGesture { selectedColor = c }
                        }
                    }
                }

                TextField("备注（可选）", text: $note)
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") { create(); onCreated(); dismiss() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { name = presetName }
        }
        .presentationDetents([.medium, .large])
    }

    private var sheetTitle: String {
        switch type {
        case .doToday: return "新建任务"
        case .doHabit: return "新建打卡"
        case .doPeriod: return "新建时期任务"
        case .goalProgress: return "新建进度目标"
        case .goalAccumulation: return "新建累计目标"
        case .goalLifetime: return "新建终身目标"
        }
    }

    private func create() {
        let doRepo = DoRepository(context: modelContext)
        let goalRepo = GoalRepository(context: modelContext)

        switch type {
        case .doToday:
            doRepo.createTodayTask(name: name, note: note, deadline: hasDeadline ? deadline : nil)
        case .doHabit:
            doRepo.createHabit(name: name, note: note, cycleType: cycleType, startDate: startDate)
        case .doPeriod:
            doRepo.createPeriodTask(name: name, note: note, startDate: startDate, endDate: endDate)
        case .goalProgress:
            goalRepo.createProgressGoal(name: name, desc: note, targetValue: targetValue, unit: unit, color: selectedColor)
        case .goalAccumulation:
            goalRepo.createAccumulationGoal(name: name, desc: note, targetValue: targetValue, unit: unit, color: selectedColor)
        case .goalLifetime:
            goalRepo.createLifetimeGoal(name: name, desc: note, color: selectedColor)
        }
    }
}
