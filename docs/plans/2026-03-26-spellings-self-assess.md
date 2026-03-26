# Spellings Self Assess Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a new `Self Assess` mode to the iOS app while preserving the existing session flow as `2-Person`.

**Architecture:** Keep the word dataset and filter logic shared, add an app-level mode selection model, and introduce a dedicated self-assess session state that records typed answers without revealing correctness until the final summary. Preserve the current 2-person flow as a separate branch of the UI rather than forcing both modes through one state shape.

**Tech Stack:** SwiftUI, Foundation, AVFoundation, XCTest, XcodeGen

---

### Task 1: Preserve project configuration and add shared mode types

**Files:**
- Modify: `spellings-ios/project.yml`
- Create: `spellings-ios/Spellings/Models/PracticeMode.swift`
- Create: `spellings-ios/Spellings/Models/AppSessionState.swift`

**Step 1: Write the failing test**

Add a unit test that expects app-level persisted state to encode and decode the selected practice mode.

**Step 2: Run test to verify it fails**

Run a focused test/build command for the new test target or, if test execution remains unreliable, capture the compile failure that proves the new types do not exist.

**Step 3: Write minimal implementation**

Add:
- `PracticeMode` with `twoPerson` and `selfAssess`
- app-level persisted state wrapper
- explicit `DEVELOPMENT_TEAM` in `project.yml` to preserve the locally selected team through regeneration

**Step 4: Run verification**

Regenerate the project and run a build to confirm it compiles.

**Step 5: Commit**

```bash
git add spellings-ios/project.yml spellings-ios/Spellings/Models
git commit -m "feat: add practice mode model"
```

### Task 2: Add self assess session logic with TDD

**Files:**
- Create: `spellings-ios/Spellings/Models/SelfAssessAnswer.swift`
- Create: `spellings-ios/Spellings/Models/SelfAssessResult.swift`
- Create: `spellings-ios/Spellings/Stores/SelfAssessSession.swift`
- Create: `spellings-ios/SpellingsTests/SelfAssessSessionTests.swift`

**Step 1: Write the failing tests**

Cover:
- session starts from the selected filter and shuffled order
- submitting an answer advances without scoring immediately
- completing the test returns total score and only wrong answers
- wrong answer entries include typed and correct spelling

**Step 2: Run test to verify it fails**

Run a focused verification command and confirm failure because the self-assess session types do not exist yet.

**Step 3: Write minimal implementation**

Implement the self-assess state model and deferred result calculation.

**Step 4: Run test/build verification**

Run the same focused command and confirm the new logic compiles and passes where possible.

**Step 5: Commit**

```bash
git add spellings-ios/Spellings spellings-ios/SpellingsTests
git commit -m "feat: add self assess session logic"
```

### Task 3: Refactor the app store for mode-aware persistence

**Files:**
- Modify: `spellings-ios/Spellings/Models/SessionState.swift`
- Modify: `spellings-ios/Spellings/Stores/SpellingSessionStore.swift`

**Step 1: Write the failing test**

Add coverage that persisted app state restores:
- selected practice mode
- current filter
- in-progress 2-person or self-assess session state

**Step 2: Run test to verify it fails**

Run the targeted verification command and confirm the current store cannot support the richer state shape.

**Step 3: Write minimal implementation**

Split responsibilities so the store owns:
- loaded entries
- selected filter
- selected mode
- 2-person session state
- self-assess session state
- persistence and restore

**Step 4: Run verification**

Run the targeted build/test command and confirm success.

**Step 5: Commit**

```bash
git add spellings-ios/Spellings spellings-ios/SpellingsTests
git commit -m "feat: persist mode aware sessions"
```

### Task 4: Build the mode-switching UI and self assess flow

**Files:**
- Modify: `spellings-ios/Spellings/ContentView.swift`
- Create or modify: mode-specific view files under `spellings-ios/Spellings/`

**Step 1: Implement the app shell**

Add a mode picker or segmented control for:
- `2-Person`
- `Self Assess`

**Step 2: Keep the current 2-person UI intact**

Rename the mode in the interface, but preserve behavior.

**Step 3: Implement the self assess UI**

Include:
- filter selection
- play button
- plain text answer field
- submit action
- progress display
- complete-test action
- final results summary showing score and wrong answers only

**Step 4: Disable input help**

Configure the text input to disable:
- autocorrection
- automatic capitalization
- assistive spelling suggestions where available

**Step 5: Run build verification**

Run:
- `xcodebuild -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'generic/platform=iOS' build`
- `xcodebuild -project spellings-ios/Spellings.xcodeproj -scheme Spellings -destination 'platform=iOS Simulator,OS=17.0,name=iPhone 15' build`

Use `CODE_SIGNING_ALLOWED=NO` only where needed for command-line verification.

**Step 6: Commit**

```bash
git add spellings-ios/Spellings spellings-ios/Spellings.xcodeproj spellings-ios/project.yml
git commit -m "feat: add self assess mode ui"
```

### Task 5: Add speech playback and final verification

**Files:**
- Modify: relevant SwiftUI and store files under `spellings-ios/Spellings/`

**Step 1: Add speech playback**

Use Apple TTS so the play button speaks the current self-assess word.

**Step 2: Verify end-to-end behavior**

Build both destinations again and launch in the simulator.

**Step 3: Clean generated noise**

Remove `xcuserdata` and any unrelated local artifacts before final status.

**Step 4: Commit**

```bash
git add spellings-ios
git commit -m "feat: finish self assess mode"
```
