# Spellings iOS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a universal native SwiftUI iOS app that replicates the current spelling tester behavior using bundled JSON data and persisted session state.

**Architecture:** Create a new Xcode SwiftUI app target inside this repository, move the spelling dataset into a bundled JSON file, and implement a small observable session store that handles filtering, shuffling, navigation, and persistence. Keep the first UI to a single practice screen so the codebase stays small and easy to extend later.

**Tech Stack:** SwiftUI, Foundation, XCTest, UserDefaults, Xcode project generated from the command line

---

### Task 1: Scaffold the iOS app project

**Files:**
- Create: `spellings-ios/Spellings.xcodeproj`
- Create: `spellings-ios/Spellings/SpellingsApp.swift`
- Create: `spellings-ios/Spellings/ContentView.swift`
- Create: `spellings-ios/Spellings/Assets.xcassets`
- Create: `spellings-ios/Spellings/Preview Content`

**Step 1: Generate the base project**

Run: create a new SwiftUI iOS app project named `Spellings` under `spellings-ios/`

**Step 2: Verify project structure exists**

Run: `find spellings-ios -maxdepth 3 | sort`
Expected: project file and default SwiftUI app files exist

**Step 3: Commit**

```bash
git add spellings-ios
git commit -m "feat: scaffold spellings ios app"
```

### Task 2: Add the bundled spelling dataset

**Files:**
- Create: `spellings-ios/Spellings/words.json`

**Step 1: Copy the embedded data into JSON**

Move the JSON array from `index.html` into `spellings-ios/Spellings/words.json`

**Step 2: Verify the JSON parses**

Run: `plutil -lint spellings-ios/Spellings/words.json`
Expected: `OK`

**Step 3: Add the file to the Xcode project target**

Update the Xcode project so `words.json` is copied into the app bundle

**Step 4: Commit**

```bash
git add spellings-ios/Spellings/words.json spellings-ios/Spellings.xcodeproj
git commit -m "feat: bundle spelling data in ios app"
```

### Task 3: Build the data model and filters with TDD

**Files:**
- Create: `spellings-ios/Spellings/Models/WordEntry.swift`
- Create: `spellings-ios/Spellings/Models/WordFilter.swift`
- Create: `spellings-ios/SpellingsTests/WordFilterTests.swift`

**Step 1: Write the failing tests**

Cover:
- decoding one `WordEntry`
- `all` returns all words
- `learned` and `notLearned` split words by the same field rules as the web app
- term filters include only words with values for that key

**Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpellingsTests/WordFilterTests`
Expected: FAIL because models and filter logic do not exist yet

**Step 3: Write the minimal implementation**

Implement `Codable` models and filter matching logic

**Step 4: Run the tests to verify they pass**

Run the same `xcodebuild test` command
Expected: PASS

**Step 5: Commit**

```bash
git add spellings-ios/Spellings spellings-ios/SpellingsTests
git commit -m "feat: add spelling models and filters"
```

### Task 4: Add session state and persistence with TDD

**Files:**
- Create: `spellings-ios/Spellings/Models/SessionState.swift`
- Create: `spellings-ios/Spellings/Stores/SpellingSessionStore.swift`
- Create: `spellings-ios/SpellingsTests/SpellingSessionStoreTests.swift`

**Step 1: Write the failing tests**

Cover:
- fresh session shuffles filtered words and starts at index 0
- previous and next stop at bounds
- restart creates a new valid order and resets index
- saved state restores only when filter and order are valid

**Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpellingsTests/SpellingSessionStoreTests`
Expected: FAIL because the store does not exist yet

**Step 3: Write the minimal implementation**

Implement observable state, order generation, persistence, and restore validation

**Step 4: Run the tests to verify they pass**

Run the same `xcodebuild test` command
Expected: PASS

**Step 5: Commit**

```bash
git add spellings-ios/Spellings spellings-ios/SpellingsTests
git commit -m "feat: add spelling session state"
```

### Task 5: Build the SwiftUI practice screen

**Files:**
- Modify: `spellings-ios/Spellings/ContentView.swift`
- Modify: `spellings-ios/Spellings/SpellingsApp.swift`

**Step 1: Write a narrow UI smoke test if practical**

If the generated project includes a test target that can host simple view smoke coverage, add a minimal assertion around app launch state. If not, proceed with focused manual verification and keep logic tested at the unit level.

**Step 2: Implement the main screen**

Include:
- filter picker
- progress text
- large centered current word
- previous button
- next button
- restart button

**Step 3: Bind the view to `SpellingSessionStore`**

Load bundled data on app launch and update persisted state through the store

**Step 4: Build the app**

Run: `xcodebuild -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add spellings-ios/Spellings
git commit -m "feat: build spellings practice screen"
```

### Task 6: Verify end-to-end behavior

**Files:**
- Modify as needed: files touched above

**Step 1: Run the full test suite**

Run: `xcodebuild test -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: PASS

**Step 2: Run a release-style build**

Run: `xcodebuild -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`

**Step 3: Fix any failures**

Make the smallest changes needed and rerun the failing command

**Step 4: Commit**

```bash
git add spellings-ios
git commit -m "feat: finish initial spellings ios port"
```
