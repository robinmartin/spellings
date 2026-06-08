import Foundation

@MainActor
final class SelfAssessSession: ObservableObject {
    struct State: Codable, Equatable {
        let filter: WordFilter
        let order: [String]
        let currentIndex: Int
        let draft: String
        let answers: [String: String]
        let isComplete: Bool
    }

    @Published private(set) var order: [String]
    @Published private(set) var currentIndex: Int
    @Published private(set) var answers: [String: SelfAssessAnswer]
    @Published private(set) var draft: String
    @Published private(set) var isComplete: Bool
    @Published private(set) var result: SelfAssessResult?
    let filter: WordFilter

    init(
        filter: WordFilter,
        order: [String],
        currentIndex: Int = 0,
        answers: [String: SelfAssessAnswer] = [:],
        draft: String = "",
        isComplete: Bool = false,
        result: SelfAssessResult? = nil
    ) {
        self.filter = filter
        self.order = order
        self.currentIndex = currentIndex
        self.answers = answers
        self.draft = draft
        self.isComplete = isComplete
        self.result = result
    }

    var currentWord: String? {
        guard order.indices.contains(currentIndex) else { return nil }
        return order[currentIndex]
    }

    var unansweredCount: Int {
        order.reduce(into: 0) { count, word in
            let response = answers[word]?.response.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if response.isEmpty {
                count += 1
            }
        }
    }

    func updateDraft(_ text: String) {
        draft = text
        guard let currentWord else { return }
        answers[currentWord] = SelfAssessAnswer(
            word: currentWord,
            response: text,
            correctSpelling: currentWord
        )
    }

    func goNext() {
        guard currentIndex < order.count else { return }
        currentIndex += 1
        draft = currentWord.flatMap { answers[$0]?.response } ?? ""
    }

    func goPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        draft = currentWord.flatMap { answers[$0]?.response } ?? ""
    }

    func goToIndex(_ index: Int) {
        guard index >= 0, index <= order.count else { return }
        currentIndex = index
        draft = currentWord.flatMap { answers[$0]?.response } ?? ""
    }

    func markIncomplete() {
        isComplete = false
        result = nil
    }

    func submitCurrentAnswer() {
        if currentIndex < order.count {
            currentIndex += 1
            draft = currentWord.flatMap { answers[$0]?.response } ?? ""
        }
    }

    @discardableResult
    func completeTest() -> SelfAssessResult {
        let incorrectAnswers: [SelfAssessAnswer] = order.compactMap { word in
            guard let answer = answers[word], !answer.isCorrect else { return nil }
            return answer
        }

        let result = SelfAssessResult(
            score: order.count - incorrectAnswers.count,
            total: order.count,
            incorrectAnswers: incorrectAnswers
        )
        self.result = result
        isComplete = true
        return result
    }

    var state: State {
        State(
            filter: filter,
            order: order,
            currentIndex: currentIndex,
            draft: draft,
            answers: answers.mapValues(\.response),
            isComplete: isComplete
        )
    }
}
