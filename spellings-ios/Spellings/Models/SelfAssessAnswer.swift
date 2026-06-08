import Foundation

struct SelfAssessAnswer: Codable, Equatable {
    let word: String
    let response: String
    let correctSpelling: String

    var isCorrect: Bool {
        response == correctSpelling
    }
}
