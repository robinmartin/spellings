import Foundation

enum PracticeMode: String, Codable, CaseIterable, Identifiable {
    case twoPerson
    case selfAssess

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twoPerson:
            "Practise"
        case .selfAssess:
            "Test"
        }
    }
}
