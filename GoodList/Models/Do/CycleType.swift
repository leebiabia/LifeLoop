import Foundation

enum CycleType: String, Codable, CaseIterable {
    case daily   = "daily"
    case weekly  = "weekly"
    case monthly = "monthly"
    case custom  = "customDates"

    var title: String {
        switch self {
        case .daily:   return "每日"
        case .weekly:  return "每周"
        case .monthly: return "每月"
        case .custom:  return "自定义"
        }
    }
}
