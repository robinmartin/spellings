import Foundation

@MainActor
final class SpellingSessionStore: ObservableObject {
    @Published private(set) var entries: [WordEntry] = []
    @Published var selectedFilter: WordFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            resetSession()
        }
    }
    @Published private(set) var order: [String] = []
    @Published private(set) var index = 0

    private let userDefaults: UserDefaults
    private let storageKey = "spellingTesterState"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var availableFilters: [WordFilter] {
        [.all, .learned, .notLearned, .au1, .au2, .sp1, .sp2, .su1, .su2, .ex1, .ex2]
    }

    var currentWord: String? {
        guard order.indices.contains(index) else { return nil }
        return order[index]
    }

    var progressText: String {
        let total = order.count
        guard total > 0 else { return "0 / 0" }
        return "\(min(total, max(1, index + 1))) / \(total)"
    }

    var canGoPrevious: Bool {
        index > 0
    }

    var canGoNext: Bool {
        index < order.count - 1
    }

    func loadWords() throws {
        let url = Bundle.main.url(forResource: "words", withExtension: "json")
        guard let url else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        entries = try JSONDecoder().decode([WordEntry].self, from: data)

        let savedState = loadState()
        if let savedState {
            selectedFilter = savedState.filter
            restore(savedState)
            return
        }

        if availableFilters.contains(.su1) {
            selectedFilter = .su1
        } else {
            selectedFilter = .all
        }
        startSession()
    }

    func goPrevious() {
        guard canGoPrevious else { return }
        index -= 1
        saveState()
    }

    func goNext() {
        guard canGoNext else { return }
        index += 1
        saveState()
    }

    func startNewSession() {
        clearState()
        startSession()
    }

    func resetSession() {
        startSession()
    }

    private func startSession() {
        let words = selectedFilter.filteredWords(from: entries)
        guard !words.isEmpty else {
            order = []
            index = 0
            return
        }

        order = words.shuffled()
        index = 0
        saveState()
    }

    private func restore(_ state: SessionState) {
        let validWords = Set(selectedFilter.filteredWords(from: entries))
        let isValidOrder = !state.order.isEmpty && state.order.allSatisfy { validWords.contains($0) }

        guard isValidOrder, state.index >= 0, state.index < state.order.count else {
            startSession()
            return
        }

        order = state.order
        index = state.index
        saveState()
    }

    private func saveState() {
        let state = SessionState(filter: selectedFilter, order: order, index: index)
        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func loadState() -> SessionState? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(SessionState.self, from: data)
    }

    private func clearState() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
