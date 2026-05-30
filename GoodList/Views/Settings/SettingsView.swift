import SwiftUI

struct SettingsView: View {
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = false

    var body: some View {
        NavigationStack {
            List {
                Section("提醒设置") {
                    Toggle("每日晚间提醒 (20:00)", isOn: .constant(true))
                    Toggle("任务截止提醒", isOn: .constant(true))
                }

                Section("同步") {
                    Toggle("iCloud 同步", isOn: $icloudSyncEnabled)
                }

                Section("外观") {
                    NavigationLink("深色模式") {
                        Text("深色模式设置（后续完善）")
                    }
                }

                Section("数据") {
                    Button("导出数据 (CSV)") { }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}
