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
