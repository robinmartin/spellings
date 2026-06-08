import Foundation

@MainActor
final class SpellingSessionStore: ObservableObject {
    @Published private(set) var entries: [WordEntry] = []
    @Published var selectedMode: PracticeMode = .twoPerson {
        didSet {
            guard selectedMode != oldValue, hasLoadedWords, !isRestoringState else { return }
            ensureSessionForCurrentMode()
            saveState()
        }
    }
    @Published var twoPersonFilter: WordFilter = .all {
        didSet {
            guard twoPersonFilter != oldValue, hasLoadedWords, !isRestoringState else { return }
            startTwoPersonSession()
        }
    }
    @Published var selfAssessFilter: WordFilter = .all {
        didSet {
            guard selfAssessFilter != oldValue, hasLoadedWords, !isRestoringState else { return }
            startSelfAssessSession()
        }
    }
    @Published private(set) var twoPersonOrder: [String] = []
    @Published private(set) var twoPersonIndex = 0
    @Published private(set) var selfAssessSession: SelfAssessSession?

    private let userDefaults: UserDefaults
    private let storageKey = "spellingTesterState"
    private var hasLoadedWords = false
    private var isRestoringState = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var availableFilters: [WordFilter] {
        [.all, .learned, .notLearned, .au1, .au2, .sp1, .sp2, .su1, .su2, .ex1, .ex2]
    }

    var twoPersonCurrentWord: String? {
        guard twoPersonOrder.indices.contains(twoPersonIndex) else { return nil }
        return twoPersonOrder[twoPersonIndex]
    }

    var twoPersonProgressText: String {
        let total = twoPersonOrder.count
        guard total > 0 else { return "0 / 0" }
        return "\(min(total, max(1, twoPersonIndex + 1))) / \(total)"
    }

    var canGoPrevious: Bool {
        twoPersonIndex > 0
    }

    var canGoNext: Bool {
        twoPersonIndex < twoPersonOrder.count - 1
    }

    func loadWords() throws {
        let url = Bundle.main.url(forResource: "words", withExtension: "json")
        guard let url else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        entries = try JSONDecoder().decode([WordEntry].self, from: data)
        hasLoadedWords = true

        let defaultFilter = preferredDefaultFilter()
        isRestoringState = true
        twoPersonFilter = defaultFilter
        selfAssessFilter = defaultFilter
        isRestoringState = false

        if let savedState = loadState() {
            restore(savedState)
        } else {
            startTwoPersonSession()
        }
    }

    func goPrevious() {
        guard canGoPrevious else { return }
        twoPersonIndex -= 1
        saveState()
    }

    func goNext() {
        guard canGoNext else { return }
        twoPersonIndex += 1
        saveState()
    }

    func startNewTwoPersonSession() {
        startTwoPersonSession()
    }

    func startNewSelfAssessSession() {
        startSelfAssessSession()
    }

    func updateSelfAssessDraft(_ text: String) {
        selfAssessSession?.updateDraft(text)
        saveState()
    }

    func goToPreviousSelfAssessWord() {
        selfAssessSession?.goPrevious()
        saveState()
    }

    func goToNextSelfAssessWord() {
        selfAssessSession?.goNext()
        saveState()
    }

    @discardableResult
    func completeSelfAssessTest() -> SelfAssessResult? {
        let result = selfAssessSession?.completeTest()
        saveState()
        return result
    }

    private func preferredDefaultFilter() -> WordFilter {
        availableFilters.contains(.su1) ? .su1 : .all
    }

    private func ensureSessionForCurrentMode() {
        switch selectedMode {
        case .twoPerson:
            if twoPersonOrder.isEmpty {
                startTwoPersonSession()
            }
        case .selfAssess:
            if selfAssessSession == nil {
                startSelfAssessSession()
            }
        }
    }

    private func startTwoPersonSession() {
        let words = twoPersonFilter.filteredWords(from: entries)
        twoPersonOrder = words.shuffled()
        twoPersonIndex = 0
        saveState()
    }

    private func startSelfAssessSession() {
        let words = selfAssessFilter.filteredWords(from: entries)
        selfAssessSession = SelfAssessSession(
            filter: selfAssessFilter,
            order: words.shuffled()
        )
        saveState()
    }

    private func restore(_ appState: AppSessionState) {
        isRestoringState = true
        selectedMode = appState.selectedMode
        isRestoringState = false

        restoreTwoPerson(appState.twoPersonSession)
        restoreSelfAssess(appState.selfAssessSession)
        ensureSessionForCurrentMode()
        saveState()
    }

    private func restoreTwoPerson(_ state: SessionState?) {
        guard let state else {
            twoPersonFilter = preferredDefaultFilter()
            twoPersonOrder = []
            twoPersonIndex = 0
            return
        }

        let validWords = Set(state.filter.filteredWords(from: entries))
        let isValidOrder = state.order.allSatisfy { validWords.contains($0) }
        let isValidIndex = state.index >= 0 && state.index < max(state.order.count, 1)

        guard isValidOrder, isValidIndex else {
            twoPersonFilter = state.filter
            twoPersonOrder = []
            twoPersonIndex = 0
            return
        }

        twoPersonFilter = state.filter
        twoPersonOrder = state.order
        twoPersonIndex = state.index
    }

    private func restoreSelfAssess(_ state: SelfAssessSession.State?) {
        guard let state else {
            selfAssessFilter = preferredDefaultFilter()
            selfAssessSession = nil
            return
        }

        let validWords = Set(state.filter.filteredWords(from: entries))
        let isValidOrder = state.order.allSatisfy { validWords.contains($0) }
        let isValidIndex = state.currentIndex >= 0 && state.currentIndex <= state.order.count
        let isValidAnswers = Set(state.answers.keys).isSubset(of: Set(state.order))

        guard isValidOrder, isValidIndex, isValidAnswers else {
            selfAssessFilter = state.filter
            selfAssessSession = nil
            return
        }

        selfAssessFilter = state.filter
        let answers = state.answers.mapValues { response in
            SelfAssessAnswer(word: "", response: response, correctSpelling: "")
        }
        let rebuiltAnswers = Dictionary(uniqueKeysWithValues: answers.map { key, value in
            (key, SelfAssessAnswer(word: key, response: value.response, correctSpelling: key))
        })
        let session = SelfAssessSession(
            filter: state.filter,
            order: state.order,
            currentIndex: state.currentIndex,
            answers: rebuiltAnswers,
            draft: state.draft,
            isComplete: state.isComplete
        )
        if state.isComplete {
            _ = session.completeTest()
        }
        selfAssessSession = session
    }

    private func saveState() {
        guard hasLoadedWords else { return }
        let state = AppSessionState(
            selectedMode: selectedMode,
            twoPersonSession: SessionState(filter: twoPersonFilter, order: twoPersonOrder, index: twoPersonIndex),
            selfAssessSession: selfAssessSession?.state
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func loadState() -> AppSessionState? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AppSessionState.self, from: data)
    }
}
