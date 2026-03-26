import Foundation

enum WordFilter: String, CaseIterable, Codable, Identifiable {
    case all
    case learned
    case notLearned
    case au1
    case au2
    case sp1
    case sp2
    case su1
    case su2
    case ex1
    case ex2

    var id: String { rawValue }

    enum Bucket: String, CaseIterable, Codable {
        case au1
        case au2
        case sp1
        case sp2
        case su1
        case su2
        case ex1
        case ex2
    }

    var title: String {
        switch self {
        case .all:
            "All Words"
        case .learned:
            "Covered"
        case .notLearned:
            "Not Covered"
        case .au1:
            "Autumn 1"
        case .au2:
            "Autumn 2"
        case .sp1:
            "Spring 1"
        case .sp2:
            "Spring 2"
        case .su1:
            "Summer 1"
        case .su2:
            "Summer 2"
        case .ex1:
            "Extra 1"
        case .ex2:
            "Extra 2"
        }
    }

    var bucket: Bucket? {
        Bucket(rawValue: rawValue)
    }

    func filteredWords(from entries: [WordEntry]) -> [String] {
        switch self {
        case .all:
            return entries.map(\.word)
        case .learned:
            return entries.filter(\.isLearned).map(\.word)
        case .notLearned:
            return entries.filter { !$0.isLearned }.map(\.word)
        case .au1, .au2, .sp1, .sp2, .su1, .su2, .ex1, .ex2:
            guard let bucket else { return [] }
            return entries.filter { $0.value(for: bucket) != nil }.map(\.word)
        }
    }
}
