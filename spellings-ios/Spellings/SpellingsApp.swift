import SwiftUI

@main
struct SpellingsApp: App {
    @StateObject private var store = SpellingSessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task {
                    try? store.loadWords()
                }
        }
    }
}
