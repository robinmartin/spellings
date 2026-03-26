import Foundation

struct SessionState: Codable, Equatable {
    let filter: WordFilter
    let order: [String]
    let index: Int
}
