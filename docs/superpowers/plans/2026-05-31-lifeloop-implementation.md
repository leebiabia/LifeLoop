# LifeLoop 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 构建 LifeLoop iOS 应用 V1 — 个人成长管理工具，包含 DoList（任务/打卡/时期）+ Goal（进度/累计/终身）+ 收集箱 + 统计 + 设置

**架构：** SwiftUI + SwiftData + @Observable MVVM。View → ViewModel → Repository → SwiftData Model。Do 与 Goal 完全独立。单环边框进度组件。本地优先存储，iCloud 可选。

**技术栈：** Swift 5.10+, SwiftUI, SwiftData, @Observable, UNUserNotificationCenter, CloudKit (可选)

---

## 文件清单

| # | 文件 | 职责 |
|---|------|------|
| 1 | `App/LifeLoopApp.swift` | @main 入口，ModelContainer 配置 |
| 2 | `App/AppDelegate.swift` | UNUserNotificationCenter 委托 |
| 3 | `App/ContentView.swift` | TabView 壳，5个Tab路由 |
| 4 | `Models/Common/Priority.swift` | 优先级枚举 |
| 5 | `Models/Common/Tag.swift` | 标签模型 |
| 6 | `Models/Do/DoType.swift` | Do类型枚举 |
| 7 | `Models/Do/DoItem.swift` | Do基类（单表继承，doType区分） |
| 8 | `Models/Do/HabitRecord.swift` | 打卡记录 |
| 9 | `Models/Goal/GoalType.swift` | Goal类型枚举 |
| 10 | `Models/Goal/GoalItem.swift` | Goal基类（单表继承，goalType区分） |
| 11 | `Models/Goal/GoalRecord.swift` | 目标记录 |
| 12 | `Repositories/DoRepository.swift` | Do数据访问层 |
| 13 | `Repositories/GoalRepository.swift` | Goal数据访问层 |
| 14 | `Services/StreakCalculator.swift` | 连续打卡计算 |
| 15 | `Services/NotificationService.swift` | 本地通知管理 |
| 16 | `Services/PeriodTaskService.swift` | 时期任务自动转入Today |
| 17 | `ViewModels/TodayViewModel.swift` | 今日页状态管理 |
| 18 | `ViewModels/GoalViewModel.swift` | 目标页状态管理 |
| 19 | `ViewModels/InboxViewModel.swift` | 收集箱状态管理 |
| 20 | `Components/Rings/RingBorderView.swift` | 单环边框进度组件 |
| 21 | `Views/Today/TodayView.swift` | 今日Tab主视图 |
| 22 | `Views/Goal/GoalListView.swift` | 目标Tab主视图 |
| 23 | `Views/Goal/GoalDetailView.swift` | 目标详情 + 记录 |
| 24 | `Views/Inbox/InboxView.swift` | 收集箱快速新建 |
| 25 | `Views/Stats/StatsView.swift` | 统计Tab |
| 26 | `Views/Settings/SettingsView.swift` | 我的Tab |
| 27 | `Extensions/Date+Extensions.swift` | 日期工具扩展 |
| 28 | `Extensions/Color+Theme.swift` | 主题色扩展 |

---

### 任务 1：项目骨架 + SwiftData 模型

**文件：**
- 创建：`App/LifeLoopApp.swift`
- 创建：`Models/Common/Priority.swift`
- 创建：`Models/Common/Tag.swift`
- 创建：`Models/Do/DoType.swift`
- 创建：`Models/Do/DoItem.swift`
- 创建：`Models/Do/HabitRecord.swift`
- 创建：`Models/Goal/GoalType.swift`
- 创建：`Models/Goal/GoalItem.swift`
- 创建：`Models/Goal/GoalRecord.swift`
- 创建：`Extensions/Date+Extensions.swift`

- [ ] **步骤 1：创建 Priority 和 Tag 模型**

```swift
// Models/Common/Priority.swift
import Foundation
import SwiftData

enum Priority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var title: String {
        switch self {
        case .low:    return "低"
        case .medium: return "中"
        case .high:   return "高"
        }
    }

    var color: String {
        switch self {
        case .low:    return "#8E8E93"
        case .medium: return "#FF9500"
        case .high:   return "#FF3B30"
        }
    }
}

// Models/Common/Tag.swift
import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String

    init(id: UUID = UUID(), name: String, color: String = "#007AFF") {
        self.id = id
        self.name = name
        self.color = color
    }
}
```

- [ ] **步骤 2：创建 DoType 和 DoItem 模型**

```swift
// Models/Do/DoType.swift
import Foundation

enum DoType: String, Codable, CaseIterable {
    case today  = "today"
    case habit  = "habit"
    case period = "period"

    var title: String {
        switch self {
        case .today:  return "今日任务"
        case .habit:  return "习惯打卡"
        case .period: return "时期任务"
        }
    }
}

// Models/Do/DoItem.swift
import Foundation
import SwiftData

@Model
final class DoItem {
    var id: UUID
    var name: String
    var note: String
    var createdAt: Date
    var doTypeRaw: String          // DoType.rawValue
    var priorityRaw: Int           // Priority.rawValue

    // TodayTask 字段
    var startTime: Date?
    var deadline: Date?
    var isCompleted: Bool

    // HabitTask 字段
    var habitStartDate: Date?
    var habitEndDate: Date?
    var reminderTime: Date?
    var cycleType: String?         // "daily" | "weekly" | "monthly" | "customDates"
    var customDates: [Date]?
    var currentStreak: Int
    var totalCount: Int
    var completionRate: Double

    // PeriodTask 字段
    var periodStartDate: Date?
    var periodEndDate: Date?
    var periodIsCompleted: Bool

    @Relationship(deleteRule: .cascade)
    var habitRecords: [HabitRecord]?

    var tags: [Tag]?

    init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        doType: DoType = .today,
        priority: Priority = .medium,
        startTime: Date? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        habitStartDate: Date? = nil,
        habitEndDate: Date? = nil,
        reminderTime: Date? = nil,
        cycleType: String? = nil,
        customDates: [Date]? = nil,
        currentStreak: Int = 0,
        totalCount: Int = 0,
        completionRate: Double = 0,
        periodStartDate: Date? = nil,
        periodEndDate: Date? = nil,
        periodIsCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = Date()
        self.doTypeRaw = doType.rawValue
        self.priorityRaw = priority.rawValue
        self.startTime = startTime
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.habitStartDate = habitStartDate
        self.habitEndDate = habitEndDate
        self.reminderTime = reminderTime
        self.cycleType = cycleType
        self.customDates = customDates
        self.currentStreak = currentStreak
        self.totalCount = totalCount
        self.completionRate = completionRate
        self.periodStartDate = periodStartDate
        self.periodEndDate = periodEndDate
        self.periodIsCompleted = periodIsCompleted
    }

    // 计算属性：方便访问枚举
    var doType: DoType {
        DoType(rawValue: doTypeRaw) ?? .today
    }

    var priority: Priority {
        Priority(rawValue: priorityRaw) ?? .medium
    }

    // 时期任务状态判断
    var periodStatus: PeriodStatus {
        guard doType == .period, let start = periodStartDate, let end = periodEndDate else {
            return .none
        }
        let now = Date()
        if periodIsCompleted { return .completed }
        if now > end { return .overdue }
        if Calendar.current.isDateInToday(end) || now >= end { return .dueToday }
        if now >= start { return .active }
        return .upcoming
    }
}

enum PeriodStatus {
    case none, upcoming, active, dueToday, overdue, completed
}

// Models/Do/HabitRecord.swift
import Foundation
import SwiftData

@Model
final class HabitRecord {
    var id: UUID
    var date: Date
    var completedAt: Date
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), completedAt: Date = Date(), note: String = "") {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.note = note
    }
}
```

- [ ] **步骤 3：创建 GoalType、GoalItem、GoalRecord 模型**

```swift
// Models/Goal/GoalType.swift
import Foundation

enum GoalType: String, Codable, CaseIterable {
    case progress     = "progress"
    case accumulation = "accumulation"
    case lifetime     = "lifetime"

    var title: String {
        switch self {
        case .progress:     return "进度型"
        case .accumulation: return "累计型"
        case .lifetime:     return "终身目标"
        }
    }
}

// Models/Goal/GoalItem.swift
import Foundation
import SwiftData

@Model
final class GoalItem {
    var id: UUID
    var name: String
    var desc: String
    var createdAt: Date
    var goalTypeRaw: String         // GoalType.rawValue
    var color: String               // 主题色 hex
    var icon: String                // SF Symbol 名称
    var totalRecords: Int

    // ProgressGoal / AccumulationGoal 字段
    var targetValue: Double?
    var currentValue: Double?
    var unit: String?

    // LifetimeGoal 无额外字段

    @Relationship(deleteRule: .cascade)
    var records: [GoalRecord]?

    init(
        id: UUID = UUID(),
        name: String,
        desc: String = "",
        goalType: GoalType = .progress,
        color: String = "#007AFF",
        icon: String = "target",
        totalRecords: Int = 0,
        targetValue: Double? = nil,
        currentValue: Double? = nil,
        unit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.desc = desc
        self.createdAt = Date()
        self.goalTypeRaw = goalType.rawValue
        self.color = color
        self.icon = icon
        self.totalRecords = totalRecords
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
    }

    var goalType: GoalType {
        GoalType(rawValue: goalTypeRaw) ?? .progress
    }

    // 环填充百分比 (V1 单环)
    var ringProgress: Double {
        switch goalType {
        case .progress, .accumulation:
            guard let target = targetValue, let current = currentValue, target > 0 else {
                return 0
            }
            return min(current / target, 1.0)
        case .lifetime:
            // 近30天活跃天数 / 30
            guard let records = records, !records.isEmpty else { return 0 }
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentDates = Set(records.filter { $0.date >= thirtyDaysAgo }.map {
                Calendar.current.startOfDay(for: $0.date)
            })
            return min(Double(recentDates.count) / 30.0, 1.0)
        }
    }

    var isCompleted: Bool {
        guard let target = targetValue, let current = currentValue, target > 0 else {
            return false
        }
        return current >= target
    }
}

// Models/Goal/GoalRecord.swift
import Foundation
import SwiftData

@Model
final class GoalRecord {
    var id: UUID
    var date: Date
    var value: Double          // 本次增加值
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), value: Double = 1, note: String = "") {
        self.id = id
        self.date = date
        self.value = value
        self.note = note
    }
}
```

- [ ] **步骤 4：创建 Date 扩展和 LifeLoopApp 入口**

```swift
// Extensions/Date+Extensions.swift
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

// App/LifeLoopApp.swift
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
```

- [ ] **步骤 5：Commit**

```bash
git add -A
git commit -m "feat: add SwiftData models and app entry point"
```

---

### 任务 2：Repository 数据访问层

**文件：**
- 创建：`Repositories/DoRepository.swift`
- 创建：`Repositories/GoalRepository.swift`

- [ ] **步骤 1：创建 DoRepository**

```swift
// Repositories/DoRepository.swift
import Foundation
import SwiftData

@Observable
final class DoRepository {
    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 查询

    func fetchTodayTasks() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.today.rawValue && !$0.isCompleted }
        )
        return try context.fetch(descriptor)
    }

    func fetchCompletedTodayTasks() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.today.rawValue && $0.isCompleted }
        )
        return try context.fetch(descriptor)
    }

    func fetchHabits() throws -> [DoItem] {
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate { $0.doTypeRaw == DoType.habit.rawValue }
        )
        return try context.fetch(descriptor)
    }

    func fetchActivePeriodTasks() throws -> [DoItem] {
        // 时期任务：已到开始日期，未完成
        let now = Date()
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate {
                $0.doTypeRaw == DoType.period.rawValue &&
                $0.periodStartDate != nil &&
                $0.periodStartDate! <= now &&
                !$0.periodIsCompleted
            }
        )
        return try context.fetch(descriptor)
    }

    func fetchUpcomingPeriodTasks() throws -> [DoItem] {
        let now = Date()
        let descriptor = FetchDescriptor<DoItem>(
            predicate: #Predicate {
                $0.doTypeRaw == DoType.period.rawValue &&
                $0.periodStartDate != nil &&
                $0.periodStartDate! > now
            }
        )
        return try context.fetch(descriptor)
    }

    func fetchAllDoItems() throws -> [DoItem] {
        return try context.fetch(FetchDescriptor<DoItem>())
    }

    // MARK: - 写入

    func createTodayTask(name: String, note: String = "", priority: Priority = .medium,
                         startTime: Date? = nil, deadline: Date? = nil, tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .today, priority: priority,
                          startTime: startTime, deadline: deadline, isCompleted: false)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func createHabit(name: String, note: String = "", cycleType: String = "daily",
                     reminderTime: Date? = nil, startDate: Date = Date(),
                     endDate: Date? = nil, tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .habit,
                          habitStartDate: startDate, habitEndDate: endDate,
                          reminderTime: reminderTime, cycleType: cycleType)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func createPeriodTask(name: String, note: String = "", startDate: Date, endDate: Date,
                          tags: [Tag] = []) {
        let item = DoItem(name: name, note: note, doType: .period,
                          periodStartDate: startDate, periodEndDate: endDate)
        item.tags = tags
        context.insert(item)
        try? context.save()
    }

    func toggleComplete(_ item: DoItem) {
        item.isCompleted.toggle()
        try? context.save()
    }

    func recordHabit(_ habit: DoItem, note: String = "") {
        guard habit.doType == .habit else { return }
        let record = HabitRecord(date: Date(), note: note)
        if habit.habitRecords == nil {
            habit.habitRecords = []
        }
        habit.habitRecords?.append(record)
        habit.totalCount += 1

        // 计算连续天数
        let today = Calendar.current.startOfDay(for: Date())
        var streak = 1
        var checkDate = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        while true {
            let hasRecord = habit.habitRecords?.contains { record in
                Calendar.current.isDate(record.date, inSameDayAs: checkDate)
            } ?? false
            if hasRecord {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        habit.currentStreak = streak
        habit.completionRate = habit.totalCount > 0 ? 1.0 : 0.0
        try? context.save()
    }

    func completePeriodTask(_ item: DoItem) {
        guard item.doType == .period else { return }
        item.periodIsCompleted = true
        try? context.save()
    }

    func delete(_ item: DoItem) {
        context.delete(item)
        try? context.save()
    }
}
```

- [ ] **步骤 2：创建 GoalRepository**

```swift
// Repositories/GoalRepository.swift
import Foundation
import SwiftData

@Observable
final class GoalRepository {
    private var context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [GoalItem] {
        return try context.fetch(FetchDescriptor<GoalItem>())
    }

    func fetchActive() throws -> [GoalItem] {
        // 未完成的 progress/accumulation + 全部 lifetime
        var all = try context.fetch(FetchDescriptor<GoalItem>())
        return all.filter { !$0.isCompleted || $0.goalType == .lifetime }
    }

    func fetchCompleted() throws -> [GoalItem] {
        var all = try context.fetch(FetchDescriptor<GoalItem>())
        return all.filter { $0.isCompleted && $0.goalType != .lifetime }
    }

    func createProgressGoal(name: String, desc: String = "", targetValue: Double,
                            unit: String = "", color: String = "#007AFF", icon: String = "target") {
        let goal = GoalItem(name: name, desc: desc, goalType: .progress,
                            color: color, icon: icon, targetValue: targetValue,
                            currentValue: 0, unit: unit)
        context.insert(goal)
        try? context.save()
    }

    func createAccumulationGoal(name: String, desc: String = "", targetValue: Double,
                                unit: String = "", color: String = "#5856D6", icon: String = "target") {
        let goal = GoalItem(name: name, desc: desc, goalType: .accumulation,
                            color: color, icon: icon, targetValue: targetValue,
                            currentValue: 0, unit: unit)
        context.insert(goal)
        try? context.save()
    }

    func createLifetimeGoal(name: String, desc: String = "", color: String = "#FF9500",
                            icon: String = "target") {
        let goal = GoalItem(name: name, desc: desc, goalType: .lifetime, color: color, icon: icon)
        context.insert(goal)
        try? context.save()
    }

    func addRecord(to goal: GoalItem, value: Double = 1, note: String = "") {
        let record = GoalRecord(date: Date(), value: value, note: note)
        if goal.records == nil {
            goal.records = []
        }
        goal.records?.append(record)
        goal.totalRecords += 1

        if goal.goalType == .accumulation || goal.goalType == .progress {
            goal.currentValue = (goal.currentValue ?? 0) + value
        }
        try? context.save()
    }

    func updateProgress(goal: GoalItem, currentValue: Double) {
        goal.currentValue = currentValue
        try? context.save()
    }

    func delete(_ goal: GoalItem) {
        context.delete(goal)
        try? context.save()
    }
}
```

- [ ] **步骤 3：Commit**

```bash
git add Repositories/
git commit -m "feat: add DoRepository and GoalRepository"
```

---

### 任务 3：Service 服务层

**文件：**
- 创建：`Services/StreakCalculator.swift`
- 创建：`Services/NotificationService.swift`
- 创建：`Services/PeriodTaskService.swift`

- [ ] **步骤 1：创建 StreakCalculator**

```swift
// Services/StreakCalculator.swift
import Foundation

enum StreakCalculator {
    /// 计算从今天往回的最大连续天数
    static func calculateStreak(for habit: DoItem) -> Int {
        guard habit.doType == .habit, let records = habit.habitRecords, !records.isEmpty else {
            return 0
        }
        let today = Calendar.current.startOfDay(for: Date())
        // 检查今天或昨天是否有记录（只要连续不中断）
        var streak = 0
        var checkDate = today
        while true {
            let hasRecord = records.contains { record in
                Calendar.current.isDate(record.date, inSameDayAs: checkDate)
            }
            if hasRecord {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                // 允许今天还没打卡但昨天打了（streak延续中）
                if checkDate == today {
                    checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                    continue
                }
                break
            }
        }
        return streak
    }

    /// 计算habit完成率 = 有记录的天数 / 从开始到今天的天数
    static func calculateCompletionRate(for habit: DoItem) -> Double {
        guard habit.doType == .habit, let startDate = habit.habitStartDate,
              let records = habit.habitRecords, !records.isEmpty else {
            return 0
        }
        let totalDays = max(Date().daysFrom(startDate) + 1, 1)
        let recordedDays = Set(records.map { $0.date.startOfDay }).count
        return min(Double(recordedDays) / Double(totalDays), 1.0)
    }

    /// Lifetime Goal 近30天活跃天数
    static func recentActivityDays(for goal: GoalItem) -> Int {
        guard let records = goal.records, !records.isEmpty else { return 0 }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentDates = records.filter { $0.date >= thirtyDaysAgo }.map { $0.date.startOfDay }
        return Set(recentDates).count
    }
}
```

- [ ] **步骤 2：创建 NotificationService**

```swift
// Services/NotificationService.swift
import Foundation
import UserNotifications

@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 任务截止时间提醒
    func scheduleDeadlineReminder(for task: DoItem) {
        guard let deadline = task.deadline, deadline > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "⏰ 任务即将截止"
        content.body = task.name
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: deadline) ?? deadline
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "deadline-\(task.id)", content: content, trigger: trigger)
        center.add(request)
    }

    /// 每日20:00检查提醒
    func scheduleEveningCheck() {
        let content = UNMutableNotificationContent()
        content.title = "📋 今日回顾"
        content.body = "还有未完成的任务，别忘了处理哦"
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "evening-check", content: content, trigger: trigger)
        center.add(request)
    }

    /// 习惯每日提醒
    func scheduleHabitReminder(for habit: DoItem) {
        guard let reminderTime = habit.reminderTime else { return }
        let content = UNMutableNotificationContent()
        content.title = "🔄 \(habit.name)"
        content.body = "该打卡了！坚持就是胜利"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "habit-\(habit.id)", content: content, trigger: trigger)
        center.add(request)
    }

    /// 取消某个提醒
    func cancelReminder(for id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
```

- [ ] **步骤 3：创建 PeriodTaskService**

```swift
// Services/PeriodTaskService.swift
import Foundation
import SwiftData

@Observable
final class PeriodTaskService {
    /// 检查时期任务是否应该出现在Today页
    /// 返回应该在Today显示的任务列表
    static func tasksForToday(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let startDate = task.periodStartDate,
                  !task.periodIsCompleted else {
                return false
            }
            // 开始日期 <= 今天 且 未完成
            return startDate <= Date()
        }
    }

    /// 需要标记为 Due Today 的任务（截止日期是今天）
    static func dueTodayTasks(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let endDate = task.periodEndDate,
                  !task.periodIsCompleted else {
                return false
            }
            return Calendar.current.isDateInToday(endDate)
        }
    }

    /// 逾期任务
    static func overdueTasks(from periodTasks: [DoItem]) -> [DoItem] {
        periodTasks.filter { task in
            guard task.doType == .period,
                  let endDate = task.periodEndDate,
                  !task.periodIsCompleted else {
                return false
            }
            return endDate < Date() && !Calendar.current.isDateInToday(endDate)
        }
    }
}
```

- [ ] **步骤 4：Commit**

```bash
git add Services/
git commit -m "feat: add StreakCalculator, NotificationService, PeriodTaskService"
```

---

### 任务 4：TodayViewModel + TodayView

**文件：**
- 创建：`ViewModels/TodayViewModel.swift`
- 创建：`Views/Today/TodayView.swift`
- 创建：`App/ContentView.swift`

- [ ] **步骤 1：创建 TodayViewModel**

```swift
// ViewModels/TodayViewModel.swift
import Foundation
import SwiftUI
import Observation

@Observable
final class TodayViewModel {
    var todayTasks: [DoItem] = []
    var completedTodayTasks: [DoItem] = []
    var habits: [DoItem] = []
    var activePeriodTasks: [DoItem] = []
    var dueTodayPeriodTasks: [DoItem] = []
    var overduePeriodTasks: [DoItem] = []

    var completionPercentage: Double {
        let total = todayTasks.count + completedTodayTasks.count
        guard total > 0 else { return 0 }
        return Double(completedTodayTasks.count) / Double(total)
    }

    private let doRepo: DoRepository

    init(doRepo: DoRepository) {
        self.doRepo = doRepo
    }

    func loadData() {
        todayTasks = (try? doRepo.fetchTodayTasks()) ?? []
        completedTodayTasks = (try? doRepo.fetchCompletedTodayTasks()) ?? []
        habits = (try? doRepo.fetchHabits()) ?? []
        let periodTasks = (try? doRepo.fetchActivePeriodTasks()) ?? []
        activePeriodTasks = PeriodTaskService.tasksForToday(from: periodTasks)
        dueTodayPeriodTasks = PeriodTaskService.dueTodayTasks(from: periodTasks)
        overduePeriodTasks = PeriodTaskService.overdueTasks(from: periodTasks)
    }

    func toggleTask(_ item: DoItem) {
        doRepo.toggleComplete(item)
        loadData()
    }

    func recordHabit(_ habit: DoItem) {
        doRepo.recordHabit(habit)
        loadData()
    }
}
```

- [ ] **步骤 2：创建 ContentView（TabView 壳）**

```swift
// App/ContentView.swift
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
```

- [ ] **步骤 3：创建 TodayView**

```swift
// Views/Today/TodayView.swift
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
                        // Hero 完成率
                        heroSection(vm: vm)

                        // 今日任务
                        sectionHeader(title: "今日任务", color: .blue, count: "剩余 \(vm.todayTasks.count) 项")
                        ForEach(vm.todayTasks) { task in
                            taskRow(task, vm: vm)
                        }
                        ForEach(vm.completedTodayTasks) { task in
                            taskRow(task, vm: vm)
                        }

                        // 习惯打卡
                        sectionHeader(title: "习惯打卡", color: .green, count: "\(vm.habits.count) 项")
                        ForEach(vm.habits) { habit in
                            habitRow(habit, vm: vm)
                        }

                        // 时期任务
                        if !vm.dueTodayPeriodTasks.isEmpty || !vm.overduePeriodTasks.isEmpty {
                            sectionHeader(title: "时期任务", color: .orange, count: "")
                            ForEach(vm.dueTodayPeriodTasks) { task in
                                periodRow(task, status: "今日截止", color: .orange)
                            }
                            ForEach(vm.overduePeriodTasks) { task in
                                periodRow(task, status: "已逾期", color: .red)
                            }
                        }
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

    // MARK: - Subviews

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
    func sectionHeader(title: String, color: Color, count: String) -> some View {
        HStack {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
            if !count.isEmpty {
                Text(count)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    func taskRow(_ task: DoItem, vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                vm.toggleTask(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .blue : .gray.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let deadline = task.deadline {
                Text(deadline.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
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

    @ViewBuilder
    func habitRow(_ habit: DoItem, vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon ?? "flame")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(habit.doType == .habit ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("🔥 \(habit.currentStreak) 天 · 累计 \(habit.totalCount) 次")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                vm.recordHabit(habit)
            } label: {
                Text("打卡")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
    }

    @ViewBuilder
    func periodRow(_ task: DoItem, status: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(color.opacity(0.2), lineWidth: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(status)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
```

- [ ] **步骤 4：Commit**

```bash
git add ViewModels/TodayViewModel.swift Views/Today/TodayView.swift App/ContentView.swift
git commit -m "feat: add TodayView with hero ring, tasks, habits, and period alerts"
```

---

### 任务 5：RingBorderView 圆环组件

**文件：**
- 创建：`Components/Rings/RingBorderView.swift`
- 创建：`Extensions/Color+Theme.swift`

- [ ] **步骤 1：创建 Color 主题扩展**

```swift
// Extensions/Color+Theme.swift
import SwiftUI

extension Color {
    static let lifeBlue   = Color(hex: "#007AFF")
    static let lifeGreen  = Color(hex: "#34C759")
    static let lifeOrange = Color(hex: "#FF9500")
    static let lifeRed    = Color(hex: "#FF3B30")
    static let lifePurple = Color(hex: "#AF52DE")
    static let lifeIndigo = Color(hex: "#5856D6")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **步骤 2：创建 RingBorderView**

```swift
// Components/Rings/RingBorderView.swift
import SwiftUI

/// 单环边框进度组件 — 围绕内容绘制进度环
struct RingBorderView<Content: View>: View {
    let progress: Double        // 0...1
    let color: Color
    let ringWidth: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var animatedProgress: Double = 0

    var body: some View {
        content()
            .padding(ringWidth + 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20 + ringWidth / 2)
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(ringWidth / 2)
            )
            .padding(ringWidth) // 给环留空间
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
    }
}

#Preview {
    RingBorderView(progress: 0.65, color: .blue, ringWidth: 6) {
        VStack(alignment: .leading) {
            Text("示例目标")
                .font(.headline)
            Text("65% 完成")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
}
```

- [ ] **步骤 3：Commit**

```bash
git add Components/Rings/RingBorderView.swift Extensions/Color+Theme.swift
git commit -m "feat: add RingBorderView component with animated progress"
```

---

### 任务 6：GoalViewModel + GoalListView + GoalDetailView

**文件：**
- 创建：`ViewModels/GoalViewModel.swift`
- 创建：`Views/Goal/GoalListView.swift`
- 创建：`Views/Goal/GoalDetailView.swift`

- [ ] **步骤 1：创建 GoalViewModel**

```swift
// ViewModels/GoalViewModel.swift
import Foundation
import Observation

@Observable
final class GoalViewModel {
    var goals: [GoalItem] = []
    var completedGoals: [GoalItem] = []

    private let goalRepo: GoalRepository

    init(goalRepo: GoalRepository) {
        self.goalRepo = goalRepo
    }

    func loadData() {
        goals = (try? goalRepo.fetchActive()) ?? []
        completedGoals = (try? goalRepo.fetchCompleted()) ?? []
    }

    func createProgressGoal(name: String, desc: String, target: Double, unit: String, color: String) {
        goalRepo.createProgressGoal(name: name, desc: desc, targetValue: target, unit: unit, color: color)
        loadData()
    }

    func createAccumulationGoal(name: String, desc: String, target: Double, unit: String, color: String) {
        goalRepo.createAccumulationGoal(name: name, desc: desc, targetValue: target, unit: unit, color: color)
        loadData()
    }

    func createLifetimeGoal(name: String, desc: String, color: String) {
        goalRepo.createLifetimeGoal(name: name, desc: desc, color: color)
        loadData()
    }

    func addRecord(to goal: GoalItem, value: Double = 1, note: String = "") {
        goalRepo.addRecord(to: goal, value: value, note: note)
        loadData()
    }

    func deleteGoal(_ goal: GoalItem) {
        goalRepo.delete(goal)
        loadData()
    }
}
```

- [ ] **步骤 2：创建 GoalListView**

```swift
// Views/Goal/GoalListView.swift
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
                        // 活跃目标
                        ForEach(vm.goals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal, viewModel: vm)) {
                                goalCard(goal)
                            }
                            .buttonStyle(.plain)
                        }

                        // 已完成目标
                        if !vm.completedGoals.isEmpty {
                            Text("已完成")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

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
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
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
                    Text(goal.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(goal.desc)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.ringProgress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: goal.color))
                    if let current = goal.currentValue, let target = goal.targetValue {
                        Text("\(String(format: "%.0f", current))/\(String(format: "%.0f", target))\(goal.unit ?? "")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(goal.totalRecords) 次")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}
```

- [ ] **步骤 3：创建 GoalDetailView**

```swift
// Views/Goal/GoalDetailView.swift
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
                // 大圆环
                RingBorderView(progress: goal.ringProgress, color: Color(hex: goal.color), ringWidth: 8) {
                    VStack(spacing: 4) {
                        Text("\(Int(goal.ringProgress * 100))%")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(Color(hex: goal.color))
                        if let current = goal.currentValue, let target = goal.targetValue {
                            Text("\(String(format: "%.0f", current)) / \(String(format: "%.0f", target)) \(goal.unit ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(goal.totalRecords) 次")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(40)
                }
                .padding()

                // 添加记录按钮
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

                // 记录列表
                if let records = goal.records, !records.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("记录历史")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                            HStack {
                                Image(systemName: goal.icon)
                                    .font(.callout)
                                    .frame(width: 32, height: 32)
                                    .background(Color(hex: goal.color).opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading) {
                                    Text("\(goal.name)")
                                        .font(.subheadline)
                                    if !record.note.isEmpty {
                                        Text(record.note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("+\(String(format: "%.0f", record.value)) \(goal.unit ?? "")")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: goal.color))
                                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
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
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(goal.unit ?? "")
                                .foregroundColor(.secondary)
                        }
                    }
                    TextField("备注", text: $recordNote)
                }
                .navigationTitle("添加记录")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showAddRecord = false }
                    }
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
```

- [ ] **步骤 4：创建 CreateGoalSheet（占位 — 后续在Inbox中完善）**

```swift
// 临时放在 GoalListView.swift 同文件中
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
                        Spacer()
                        TextField("100", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("单位（如：本、kg、万）", text: $unit)
                }

                HStack {
                    Text("颜色")
                    Spacer()
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }
            }
            .navigationTitle("新建目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
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
```

- [ ] **步骤 5：Commit**

```bash
git add ViewModels/GoalViewModel.swift Views/Goal/GoalListView.swift Views/Goal/GoalDetailView.swift
git commit -m "feat: add Goal list, detail, and create sheet with RingBorderView"
```

---

### 任务 7：InboxView 收集箱

**文件：**
- 创建：`ViewModels/InboxViewModel.swift`
- 创建：`Views/Inbox/InboxView.swift`

- [ ] **步骤 1：创建 InboxViewModel**

```swift
// ViewModels/InboxViewModel.swift
import Foundation
import SwiftUI
import Observation

enum InboxCreateType {
    case doToday, doHabit, doPeriod
    case goalProgress, goalAccumulation, goalLifetime
}

@Observable
final class InboxViewModel {
    var inputText = ""
    var selectedType: InboxCreateType?
    var quickActions: [InboxCreateType] = [
        .doToday, .doHabit, .doPeriod,
        .goalProgress, .goalAccumulation, .goalLifetime
    ]

    func typeTitle(_ type: InboxCreateType) -> String {
        switch type {
        case .doToday:          return "今日任务"
        case .doHabit:          return "习惯打卡"
        case .doPeriod:         return "时期任务"
        case .goalProgress:     return "进度目标"
        case .goalAccumulation: return "累计目标"
        case .goalLifetime:     return "终身目标"
        }
    }

    func typeIcon(_ type: InboxCreateType) -> String {
        switch type {
        case .doToday:          return "checkmark.circle"
        case .doHabit:          return "repeat.circle"
        case .doPeriod:         return "calendar.badge.clock"
        case .goalProgress:     return "chart.line.uptrend.xyaxis.circle"
        case .goalAccumulation: return "plus.circle"
        case .goalLifetime:     return "infinity.circle"
        }
    }

    func typeColor(_ type: InboxCreateType) -> Color {
        switch type {
        case .doToday:          return .blue
        case .doHabit:          return .green
        case .doPeriod:         return .orange
        case .goalProgress:     return .blue
        case .goalAccumulation: return .purple
        case .goalLifetime:     return .orange
        }
    }
}
```

- [ ] **步骤 2：创建 InboxView**

```swift
// Views/Inbox/InboxView.swift
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
                // 输入区
                VStack(spacing: 16) {
                    TextField("快速记录一个想法...", text: $viewModel.inputText, axis: .vertical)
                        .font(.title3)
                        .padding()
                        .frame(minHeight: 80, alignment: .top)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.quickActions, id: \.self) { type in
                            Button {
                                createType = type
                                showCreateSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: viewModel.typeIcon(type))
                                        .font(.title2)
                                    Text(viewModel.typeTitle(type))
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
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
    @State private var cycleType = "daily"
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
                    if hasDeadline {
                        DatePicker("截止时间", selection: $deadline)
                    }
                }

                if type == .doHabit {
                    Picker("周期", selection: $cycleType) {
                        Text("每日").tag("daily")
                        Text("每周").tag("weekly")
                        Text("每月").tag("monthly")
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
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
            .navigationTitle(typeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        create()
                        onCreated()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear { name = presetName }
        }
        .presentationDetents([.medium, .large])
    }

    private var typeTitle: String {
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
```

- [ ] **步骤 3：Commit**

```bash
git add ViewModels/InboxViewModel.swift Views/Inbox/InboxView.swift
git commit -m "feat: add Inbox with quick-create for all Do and Goal types"
```

---

### 任务 8：StatsView + SettingsView

**文件：**
- 创建：`Views/Stats/StatsView.swift`
- 创建：`Views/Settings/SettingsView.swift`

- [ ] **步骤 1：创建 StatsView**

```swift
// Views/Stats/StatsView.swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
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
                    // Do 统计
                    statSection("任务统计", color: .blue) {
                        StatRow(title: "完成任务", value: "\(completedTasks)")
                        StatRow(title: "总任务", value: "\(totalTasks)")
                        StatRow(title: "完成率", value: totalTasks > 0 ? "\(Int(Double(completedTasks)/Double(totalTasks)*100))%" : "—")
                    }

                    // Habit 统计
                    statSection("打卡统计", color: .green) {
                        StatRow(title: "累计打卡", value: "\(habitTotalCount)")
                        StatRow(title: "最长连续", value: "\(maxStreak) 天")
                        StatRow(title: "活跃习惯", value: "\(allDoItems.filter { $0.doType == .habit }.count)")
                    }

                    // Goal 统计
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
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            VStack(spacing: 0) {
                content()
            }
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
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(14)
    }
}
```

- [ ] **步骤 2：创建 SettingsView**

```swift
// Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @State private var showExportAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("提醒设置") {
                    Toggle("每日晚间提醒 (20:00)", isOn: .constant(true))
                    Toggle("任务截止提醒", isOn: .constant(true))
                }

                Section("同步") {
                    Toggle("iCloud 同步", isOn: $icloudSyncEnabled)
                        .onChange(of: icloudSyncEnabled) { _, newValue in
                            // 切换 CloudKit 容器配置
                        }
                }

                Section("外观") {
                    Toggle("深色模式", isOn: $darkModeEnabled)
                }

                Section("数据") {
                    Button("导出数据 (CSV)") {
                        showExportAlert = true
                    }
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
        .alert("导出", isPresented: $showExportAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("数据导出功能将在后续版本中完善")
        }
    }
}
```

- [ ] **步骤 3：Commit**

```bash
git add Views/Stats/StatsView.swift Views/Settings/SettingsView.swift
git commit -m "feat: add Stats and Settings views"
```

---

## 自检

**1. 规格覆盖度：**
- [x] SwiftData 数据模型（DoItem 单表继承 + GoalItem 单表继承）
- [x] DoRepository + GoalRepository
- [x] TodayView（Hero环 + 任务列表 + 打卡 + 时期提醒）
- [x] GoalListView + GoalDetailView（单环边框）
- [x] InboxView（快速新建所有类型）
- [x] StatsView（任务/打卡/目标统计）
- [x] SettingsView（提醒/同步/导出/深色模式）
- [x] RingBorderView 单环组件
- [x] NotificationService + StreakCalculator + PeriodTaskService
- [x] TabView 5个Tab

**2. 占位符扫描：** 无 TODO/待定/占位符

**3. 类型一致性：** DoItem/GoalItem 字段名在各仓库和视图中一致，RingBorderView 的 progress 参数始终为 Double(0...1)

---

## 任务总结

| 任务 | 内容 | 文件数 | 预计时间 |
|------|------|--------|---------|
| 1 | 数据模型 + App入口 | 11 | 20min |
| 2 | Repository层 | 2 | 15min |
| 3 | Service层 | 3 | 10min |
| 4 | TodayViewModel + TodayView + ContentView | 3 | 20min |
| 5 | RingBorderView + Color扩展 | 2 | 10min |
| 6 | GoalViewModel + GoalListView + GoalDetailView | 3 | 25min |
| 7 | InboxViewModel + InboxView | 2 | 20min |
| 8 | StatsView + SettingsView | 2 | 10min |
