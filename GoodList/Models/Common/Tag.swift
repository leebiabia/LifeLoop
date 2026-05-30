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
