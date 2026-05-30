# LifeLoop 设计规格说明

> 日期：2026-05-31
> 状态：已确认，待实现计划
> 基于：PRD V1.0 + 头脑风暴迭代

---

## 一、已确认决策

| # | 决策点 | 选择 | 理由 |
|---|--------|------|------|
| 1 | 视觉方向 | 浅色模式为主（深色自动适配） | Apple Reminders + Fitness 融合，白色卡片 + 细微阴影 |
| 2 | 实现顺序 | 核心先行：数据模型 → 业务逻辑 → UI | 底层稳固，UI只是展示层 |
| 3 | iCloud同步 | 本地优先，iCloud可选开启 | 离线可用，同步是增量功能 |
| 4 | 圆环交互 | V1: 页面进入动画 + Canvas 绘制 + 粒子效果/触觉反馈留到V2 | V1先做完整功能，视觉增强迭代加入 |
| 5 | Do-Goal关系 | 完全独立，两条平行轨道 | 逻辑清晰，无隐式副作用 |
| 6 | 技术栈 | SwiftUI + SwiftData + @Observable MVVM | Apple原生幸福路径，开发效率最高 |
| 7 | 圆环结构 | 单环（V1），双环留到V2 | 先做出来再优化 |

---

## 二、架构设计

### 2.1 分层架构

```
Views (SwiftUI)          ← UI渲染、用户交互、动画
    ↓
ViewModels (@Observable) ← 状态管理、业务逻辑协调
    ↓
Services                 ← 可复用业务能力（通知、同步、计算）
    ↓
Repositories             ← 数据访问抽象、查询封装
    ↓
SwiftData Models         ← 持久化、可选CloudKit同步
```

### 2.2 项目目录

```
LifeLoop/
├── App/                    ← @main 入口、AppDelegate、TabView壳
├── Models/
│   ├── Do/                 ← DoItem, TodayTask, HabitTask, PeriodTask, HabitRecord
│   ├── Goal/               ← GoalItem, ProgressGoal, AccumulationGoal, LifetimeGoal, GoalRecord
│   └── Common/             ← Priority, Tag
├── ViewModels/             ← TodayVM, InboxVM, GoalVM, StatsVM, SettingsVM
├── Views/                  ← 按Tab组织：Today/, Inbox/, Goal/, Stats/, Settings/
├── Components/
│   ├── Rings/              ← RingBorderView（单环Canvas组件）
│   ├── Cards/              ← DoCard, GoalCard, StatCard
│   └── Common/             ← EmptyStateView, BadgeView
├── Services/               ← NotificationService, SyncService, StreakCalculator, ExportService
├── Repositories/           ← DoRepository, GoalRepository
└── Extensions/             ← Date+, Color+Theme
```

---

## 三、数据模型

### 3.1 DoList 模型（单表继承，doType 区分）

```
DoItem (基类)
├── id, name, note, createdAt, doType, priority, tags
├── TodayTask: 使用 startTime, deadline, isCompleted
├── HabitTask: 使用 startDate, endDate, reminderTime, cycleType,
│              customDates, currentStreak, totalCount, completionRate
│              → @Relationship HabitRecord[]
└── PeriodTask: 使用 startDate, endDate, isCompleted
                → 规则：未到startDate→Period页面，到达startDate→Today，
                  到达endDate→Due Today，超过→Overdue
```

### 3.2 Goal 模型（单表继承，goalType 区分）

```
GoalItem (基类)
├── id, name, desc, createdAt, goalType, color, icon, totalRecords
│   → @Relationship GoalRecord[]
├── ProgressGoal: targetValue, currentValue, unit
│   → 环 = currentValue / targetValue
├── AccumulationGoal: targetValue, currentValue, unit
│   → 环 = currentValue / targetValue（每次记录增加值）
└── LifetimeGoal: (无额外字段)
    → 环 = 近30天活跃天数 / 30
```

### 3.3 环计算公式（V1 单环）

| Goal类型 | 环填充% | 数据来源 |
|----------|---------|---------|
| ProgressGoal | `currentValue / targetValue × 100` | currentValue, targetValue |
| AccumulationGoal | `currentValue / targetValue × 100` | currentValue, targetValue |
| LifetimeGoal | `近30天有记录天数 / 30 × 100` | GoalRecord.date 去重计数 |
| 已完成 | `100%`（闭环） | currentValue >= targetValue |

---

## 四、UI设计规范

### 4.1 设计语言
- 调色板：系统蓝(#007AFF)、系统绿(#34C759)、系统橙(#FF9500)、紫色(#AF52DE/#5856D6)
- 背景：浅色 #F2F2F7，卡片 #FFFFFF
- 字体：SF Pro Display（标题）/ SF Pro Text（正文）
- 字体层级：32px/28px 标题 → 17px 卡片标题 → 15px 正文 → 11px 辅助
- 字体颜色：#1D1D1F 主 / #8E8E93 辅
- 圆角：卡片 18-24px，按钮全圆角，Tag 8px
- 阴影：极淡，`0 1px 2px rgba(0,0,0,0.03)`
- TabBar：毛玻璃 `backdrop-blur(24px)`
- 图标：SF Symbols 风格线框，1.8px 描边，round cap/join

### 4.2 边框环设计
- 环 = 卡片外围 conic-gradient 描边（6px宽）
- 从-90°（顶部中央）顺时针填充
- 环与卡片间距 4px
- 外层 border-radius 26px → 卡片 border-radius 20px
- SwiftUI 实现：`RoundedRectangle.trim + .stroke(AngularGradient) + animation`

### 4.3 分区标题
- 色点（6px圆形）替代 emoji：蓝点=任务、绿点=习惯、橙点=时期

### 4.4 卡片布局
- Hero Card：今日进度摘要，氛围光晕右上角
- Do Card：圆形勾选框 + 任务名 + 截止时间Tag
- Habit Card：图标 + 名称 + 打卡按钮
- Period Alert：橙色脉冲圆点 + 文字提示
- Goal Card：图标 + 标题 + 统计数字 + 进度环边框

---

## 五、Tab 结构

| Tab | 名称 | 核心内容 |
|-----|------|---------|
| 1 | 今日 | Hero圆环摘要 + 今日任务列表 + 打卡列表 + 时期任务到期提醒 |
| 2 | 收集箱 | 快速新建 → 选择Do/Goal类型 → 配置详情 |
| 3 | 目标 | 所有Goal卡片（单环边框 + 统计数字） |
| 4 | 统计 | 任务统计/打卡统计/目标统计（V1基础图表） |
| 5 | 我的 | 提醒设置、iCloud开关、数据导出、深色模式 |

---

## 六、MVP 范围

### V1 必须完成
- [x] Today 任务 CRUD
- [x] Habit 打卡 + 周期管理
- [x] Period 任务 + 自动转入Today
- [x] Goal 系统（3种类型 + 单环进度）
- [x] Inbox 收集箱
- [x] 本地通知
- [x] 统计模块（基础版）
- [x] SwiftData 存储
- [x] iCloud 同步（可选）

### V1 不开发
- AI 助手、社区、团队协作、Apple Watch、Widget、成就系统
- 双环、粒子效果、触觉反馈（V2迭代）
