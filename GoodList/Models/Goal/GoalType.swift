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
