import Foundation

struct SelfAssessResult: Equatable {
    let score: Int
    let total: Int
    let incorrectAnswers: [SelfAssessAnswer]

    var percentage: Double {
        guard total > 0 else { return 0 }
        return (Double(score) / Double(total)) * 100
    }
}
