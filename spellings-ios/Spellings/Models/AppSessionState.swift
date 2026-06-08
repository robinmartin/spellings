import Foundation

struct AppSessionState: Codable, Equatable {
    let selectedMode: PracticeMode
    let twoPersonSession: SessionState?
    let selfAssessSession: SelfAssessSession.State?
}
