import AVFoundation
import XCTest
@testable import Spellings

@MainActor
final class SpeechCoordinatorTests: XCTestCase {
    func testSpeakMarksCoordinatorBusyUntilSpeechFinishes() {
        let coordinator = SpeechCoordinator()

        coordinator.speak("banana")

        XCTAssertTrue(coordinator.isSpeaking)

        coordinator.speechSynthesizer(
            AVSpeechSynthesizer(),
            didFinish: AVSpeechUtterance(string: "banana")
        )

        XCTAssertFalse(coordinator.isSpeaking)
    }

    func testSpeakIsIgnoredWhileSpeechIsAlreadyActive() {
        let coordinator = SpeechCoordinator()

        coordinator.speak("banana")
        coordinator.speak("apple")

        XCTAssertTrue(coordinator.isSpeaking)
    }
}
