import SwiftUI

struct GoalDetailView: View {
    let goal: GoalItem
    let viewModel: GoalViewModel
    @State private var recordValue: Double = 1
    @State private var recordNote: String = ""
    @State private var showAddRecord = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RingBorderView(progress: goal.ringProgress, color: Color(hex: goal.color), ringWidth: 8) {
                    VStack(spacing: 4) {
                        Text("\(Int(goal.ringProgress * 100))%")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(Color(hex: goal.color))
                        if let current = goal.currentValue, let target = goal.targetValue {
                            Text("\(String(format: "%.0f", current)) / \(String(format: "%.0f", target)) \(goal.unit ?? "")")
                                .font(.subheadline).foregroundColor(.secondary)
                        } else {
                            Text("\(goal.totalRecords) 次")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    .padding(40)
                }
                .padding()

                Button {
                    showAddRecord = true
                } label: {
                    Label("记录进度", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: goal.color))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                if let records = goal.records, !records.isEmpty {
                    Text("记录历史").font(.caption).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        HStack {
                            Image(systemName: goal.icon).font(.callout)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: goal.color).opacity(0.1))
                                .clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text(goal.name).font(.subheadline)
                                if !record.note.isEmpty {
                                    Text(record.note).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("+\(String(format: "%.0f", record.value)) \(goal.unit ?? "")")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundColor(Color(hex: goal.color))
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddRecord) {
            NavigationStack {
                Form {
                    if goal.goalType == .accumulation || goal.goalType == .progress {
                        HStack {
                            Text("数值")
                            Spacer()
                            TextField("0", value: $recordValue, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            Text(goal.unit ?? "").foregroundColor(.secondary)
                        }
                    }
                    TextField("备注", text: $recordNote)
                }
                .navigationTitle("添加记录")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { showAddRecord = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            viewModel.addRecord(to: goal, value: recordValue, note: recordNote)
                            showAddRecord = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
