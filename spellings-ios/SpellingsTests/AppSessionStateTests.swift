import XCTest
@testable import Spellings

final class AppSessionStateTests: XCTestCase {
    func testAppSessionStateRoundTripsSelectedMode() throws {
        let state = AppSessionState(
            selectedMode: .selfAssess,
            twoPersonSession: SessionState(filter: .sp1, order: ["alpha", "bravo"], index: 1),
            selfAssessSession: nil
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(AppSessionState.self, from: data)

        XCTAssertEqual(decoded.selectedMode, .selfAssess)
        XCTAssertEqual(decoded.twoPersonSession?.filter, .sp1)
        XCTAssertEqual(decoded.twoPersonSession?.order, ["alpha", "bravo"])
        XCTAssertEqual(decoded.twoPersonSession?.index, 1)
    }
}
