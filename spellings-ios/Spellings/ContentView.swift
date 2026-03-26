import SwiftUI

struct ContentView: View {
    @ObservedObject var store: SpellingSessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Picker("Filter", selection: $store.selectedFilter) {
                        ForEach(store.availableFilters) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    Text(store.progressText)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Button {
                        store.startNewSession()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Start New")
                }

                Spacer()

                Text(store.currentWord ?? "No words available")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                Spacer()

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
            .padding()
            .navigationTitle("Spellings")
        }
    }
}

#Preview {
    ContentView(store: SpellingSessionStore())
}
