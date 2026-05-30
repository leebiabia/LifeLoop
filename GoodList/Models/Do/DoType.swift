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
