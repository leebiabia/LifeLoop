import Foundation
import SwiftUI
import Observation

enum InboxCreateType: CaseIterable {
    case doToday, doHabit, doPeriod
    case goalProgress, goalAccumulation, goalLifetime

    var title: String {
        switch self {
        case .doToday:          return "今日任务"
        case .doHabit:          return "习惯打卡"
        case .doPeriod:         return "时期任务"
        case .goalProgress:     return "进度目标"
        case .goalAccumulation: return "累计目标"
        case .goalLifetime:     return "终身目标"
        }
    }

    var icon: String {
        switch self {
        case .doToday:          return "checkmark.circle"
        case .doHabit:          return "repeat.circle"
        case .doPeriod:         return "calendar.badge.clock"
        case .goalProgress:     return "chart.line.uptrend.xyaxis.circle"
        case .goalAccumulation: return "plus.circle"
        case .goalLifetime:     return "infinity.circle"
        }
    }

    var color: Color {
        switch self {
        case .doToday:          return .blue
        case .doHabit:          return .green
        case .doPeriod:         return .orange
        case .goalProgress:     return .blue
        case .goalAccumulation: return .purple
        case .goalLifetime:     return .orange
        }
    }
}

@Observable
final class InboxViewModel {
    var inputText = ""
    let quickActions: [InboxCreateType] = InboxCreateType.allCases
}
