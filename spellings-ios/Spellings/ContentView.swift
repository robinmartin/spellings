import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var store: SpellingSessionStore
    @StateObject private var speaker = SpeechCoordinator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Mode", selection: $store.selectedMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch store.selectedMode {
                    case .twoPerson:
                        twoPersonView
                    case .selfAssess:
                        selfAssessView
                    }
                }
                .padding()
            }
            .navigationTitle("Spellings")
        }
    }

    private var twoPersonView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                filterPicker(selection: $store.twoPersonFilter)

                Spacer()

                Text(store.twoPersonProgressText)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    store.startNewTwoPersonSession()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Start New")
            }

            Text(store.twoPersonCurrentWord ?? "No words available")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 320)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button {
                    store.goPrevious()
                } label: {
                    Label("Previous", systemImage: "arrow.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!store.canGoPrevious)

                Button {
                    store.goNext()
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.canGoNext)
            }
        }
    }

    private var selfAssessView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                filterPicker(selection: $store.selfAssessFilter)

                Spacer()

                Button {
                    store.startNewSelfAssessSession()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .buttonStyle(.bordered)
            }

            if let session = store.selfAssessSession {
                if session.isComplete, let result = session.result {
                    selfAssessResultsView(result: result)
                } else {
                    SelfAssessActiveView(session: session, store: store, speaker: speaker)
                }
            } else {
                ContentUnavailableView(
                    "No words available",
                    systemImage: "text.badge.xmark",
                    description: Text("Choose a different list to start a self-assessment.")
                )
            }
        }
    }

    private func selfAssessResultsView(result: SelfAssessResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Self Assess Complete")
                .font(.title.weight(.bold))

            Text("\(result.score) / \(result.total)")
                .font(.system(size: 44, weight: .bold, design: .rounded))

            if result.incorrectAnswers.isEmpty {
                Text("All words were correct.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Incorrect words")
                    .font(.headline)

                ForEach(result.incorrectAnswers, id: \.word) { answer in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(answer.word)
                            .font(.headline)
                        Text("Your answer: \(answer.response)")
                            .foregroundStyle(.secondary)
                        Text("Correct spelling: \(answer.correctSpelling)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    Divider()
                }
            }

            Button {
                store.startNewSelfAssessSession()
            } label: {
                Label("Start Another Test", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func progressText(for session: SelfAssessSession) -> String {
        let total = session.order.count
        guard total > 0 else { return "0 / 0" }
        let completed = min(total, session.currentIndex + (session.currentWord == nil ? 0 : 1))
        return "\(completed) / \(total)"
    }

    private func filterPicker(selection: Binding<WordFilter>) -> some View {
        Picker("Filter", selection: selection) {
            ForEach(store.availableFilters) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.menu)
    }
}

@MainActor
final class SpeechCoordinator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ word: String) {
        guard !isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: word)
        utterance.rate = 0.42
        utterance.voice = preferredVoice()
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredLanguages = ["en-GB", "en-US", "en"]

        for language in preferredLanguages {
            if let voice = voices.first(where: { $0.language == language && $0.quality == .enhanced }) {
                return voice
            }
        }

        for language in preferredLanguages {
            if let voice = voices.first(where: { $0.language.hasPrefix(language) }) {
                return voice
            }
        }

        return AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

private struct SelfAssessActiveView: View {
    @ObservedObject var session: SelfAssessSession
    @ObservedObject var store: SpellingSessionStore
    @ObservedObject var speaker: SpeechCoordinator
    @FocusState private var isFocused: Bool
    @State private var showFinishConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(progressText)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let word = session.currentWord {
                    Button {
                        speaker.speak(word)
                    } label: {
                        Label("Play Word", systemImage: speaker.isSpeaking ? "speaker.wave.2.fill" : "play.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(speaker.isSpeaking)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(session.currentWord == nil ? "Review complete" : "Type the word you hear.")
                    .font(.title3.weight(.semibold))

                SelfAssessTextField(
                    text: Binding(
                        get: { session.draft },
                        set: store.updateSelfAssessDraft
                    ),
                    onSubmit: goToNextWord
                )
                .frame(minHeight: 50)
                .focused($isFocused)
                .disabled(session.currentWord == nil)
            }

            HStack(spacing: 12) {
                Button {
                    store.goToPreviousSelfAssessWord()
                    isFocused = true
                } label: {
                    Label("Previous", systemImage: "arrow.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(session.currentIndex == 0)

                Button(action: goToNextWord) {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(session.currentIndex >= session.order.count)
            }

            Button {
                finishAndMark()
            } label: {
                Label("Finish and Mark", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .confirmationDialog(
            "\(session.unansweredCount) unanswered \(session.unansweredCount == 1 ? "word" : "words")",
            isPresented: $showFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mark Anyway", role: .destructive) {
                store.completeSelfAssessTest()
            }
            Button("Go Back", role: .cancel) { }
        } message: {
            Text("You still have unanswered words. You can go back and finish them, or mark the test now.")
        }
    }

    private var progressText: String {
        let total = session.order.count
        guard total > 0 else { return "0 / 0" }
        let completed = min(total, session.currentIndex + (session.currentWord == nil ? 0 : 1))
        return "\(completed) / \(total)"
    }

    private func goToNextWord() {
        guard session.currentIndex < session.order.count else { return }
        store.goToNextSelfAssessWord()
        if let word = session.currentWord {
            speaker.speak(word)
        }
        isFocused = true
    }

    private func finishAndMark() {
        if session.unansweredCount > 0 {
            showFinishConfirmation = true
            return
        }
        store.completeSelfAssessTest()
    }
}

private struct SelfAssessTextField: UIViewRepresentable {
    @Binding var text: String
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.borderStyle = .roundedRect
        field.font = UIFont.monospacedSystemFont(ofSize: 28, weight: .regular)
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartInsertDeleteType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.autocapitalizationType = .none
        field.keyboardType = .asciiCapable
        field.returnKeyType = .done
        field.enablesReturnKeyAutomatically = true
        field.clearButtonMode = .never
        field.placeholder = "Enter spelling"
        field.delegate = context.coordinator
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []

        if #available(iOS 16.0, *) {
            field.inlinePredictionType = .no
        }

        if #available(iOS 17.0, *) {
            field.allowsEditingTextAttributes = false
        }

        context.coordinator.connect(field)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        private let onSubmit: () -> Void
        private weak var textField: UITextField?

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
        }

        func connect(_ textField: UITextField) {
            self.textField = textField
            textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        }

        @objc
        private func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
}

#Preview {
    ContentView(store: SpellingSessionStore())
}
