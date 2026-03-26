import Foundation

struct WordEntry: Codable, Equatable {
    let word: String
    let master: Int?
    let au1: Int?
    let au2: Int?
    let sp1: Int?
    let sp2: Int?
    let su1: Int?
    let su2: Int?
    let ex1: Int?
    let ex2: Int?
    let ex3: Int?

    func value(for bucket: WordFilter.Bucket) -> Int? {
        switch bucket {
        case .au1:
            au1
        case .au2:
            au2
        case .sp1:
            sp1
        case .sp2:
            sp2
        case .su1:
            su1
        case .su2:
            su2
        case .ex1:
            ex1
        case .ex2:
            ex2
        }
    }

    var isLearned: Bool {
        [au1, au2, sp1, sp2, su1, su2].contains { $0 != nil }
    }
}
