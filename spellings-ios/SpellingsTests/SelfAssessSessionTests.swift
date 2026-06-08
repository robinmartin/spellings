import XCTest
@testable import Spellings

@MainActor
final class SelfAssessSessionTests: XCTestCase {
    func testUpdatingDraftSavesAnswerForCurrentWord() {
        let session = SelfAssessSession(filter: .sp1, order: ["apple", "banana"])

        session.updateDraft("appl")

        XCTAssertEqual(session.answers["apple"]?.response, "appl")
        XCTAssertFalse(session.isComplete)
        XCTAssertNil(session.result)
    }

    func testNextAndPreviousNavigateWithoutClearingSavedAnswers() {
        let session = SelfAssessSession(filter: .sp1, order: ["apple", "banana"])

        session.updateDraft("appl")
        session.goNext()
        session.updateDraft("bananna")
        session.goPrevious()

        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertEqual(session.currentWord, "apple")
        XCTAssertEqual(session.draft, "appl")
        XCTAssertEqual(session.answers["banana"]?.response, "bananna")
    }

    func testCompletingSessionReturnsOnlyWrongAnswers() {
        let session = SelfAssessSession(filter: .sp1, order: ["apple", "banana"])

        session.updateDraft("apple")
        session.goNext()
        session.updateDraft("bananna")

        let result = session.completeTest()

        XCTAssertEqual(result.score, 1)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.incorrectAnswers.count, 1)
        XCTAssertEqual(result.incorrectAnswers[0].word, "banana")
        XCTAssertEqual(result.incorrectAnswers[0].response, "bananna")
        XCTAssertEqual(result.incorrectAnswers[0].correctSpelling, "banana")
    }

    func testStatePersistsFilterAndAllowsFinishedIndex() {
        let session = SelfAssessSession(filter: .su1, order: ["apple"])

        session.updateDraft("apple")
        session.goNext()

        XCTAssertEqual(session.state.filter, .su1)
        XCTAssertEqual(session.state.currentIndex, 1)
    }

    func testUnansweredCountIgnoresWordsWithNonWhitespaceAnswers() {
        let session = SelfAssessSession(filter: .su1, order: ["apple", "banana", "cherry"])

        session.updateDraft("apple")
        session.goNext()
        session.updateDraft("   ")
        session.goNext()

        XCTAssertEqual(session.unansweredCount, 2)
    }
}
