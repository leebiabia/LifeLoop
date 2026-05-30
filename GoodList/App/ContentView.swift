import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("今日")
                .tabItem { Label("今日", systemImage: "calendar") }
            Text("收集箱")
                .tabItem { Label("收集箱", systemImage: "tray") }
            Text("目标")
                .tabItem { Label("目标", systemImage: "scope") }
            Text("统计")
                .tabItem { Label("统计", systemImage: "chart.bar") }
            Text("我的")
                .tabItem { Label("我的", systemImage: "person.circle") }
        }
    }
}
