# LifeLoop

个人成长管理应用 — 结合 ToDo 任务、Habit 习惯打卡、Goal 目标追踪。

## 技术栈

- SwiftUI + SwiftData + @Observable MVVM
- iOS 18+
- XcodeGen (生成 .xcodeproj)
- GitHub Actions (CI 自动构建)

## 项目结构

```
GoodList/
├── App/                    # 入口 + TabView
├── Models/                 # SwiftData 数据模型
│   ├── Common/             # Priority, Tag
│   ├── Do/                 # DoItem, HabitRecord
│   └── Goal/               # GoalItem, GoalRecord
├── ViewModels/             # @Observable 状态管理
├── Views/                  # 5 个 Tab 页面
├── Components/             # RingBorderView 圆环组件
├── Services/               # 通知、计算、时期任务
├── Repositories/           # 数据访问层
└── Extensions/             # Date+, Color+
```

## 在 Windows 上开发

本项目在 Windows 上用 Claude Code 编写，通过 GitHub Actions 在 macOS 上自动构建。

### 工作流

1. 在 Windows 上编辑 `.swift` 文件
2. `git push` 到 GitHub
3. GitHub Actions 自动编译验证
4. 如需真机测试，下载 CI 产物到 Mac/iPhone

### 首次设置

```bash
# 1. 在 GitHub 创建仓库
# https://github.com/new

# 2. 推送代码
git remote add origin https://github.com/YOUR_USERNAME/LifeLoop.git
git branch -M main
git push -u origin main

# 3. GitHub Actions 自动触发首次构建
```

## 本地构建（Mac）

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 构建
xcodebuild build \
  -project LifeLoop.xcodeproj \
  -scheme LifeLoop \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
