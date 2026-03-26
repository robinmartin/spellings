# Spellings iOS Design

## Goal

Convert the current single-page spelling tester into a universal native iOS app built with SwiftUI while preserving the existing behavior and leaving room for richer practice features later.

## Current Behavior to Preserve

- Load a bundled spelling list containing `word`, `master`, and seasonal grouping fields.
- Show a single word at a time.
- Support filters for `all`, `learned`, `not-learned`, and the existing term buckets.
- Shuffle the filtered words into a session order.
- Allow previous and next navigation through the shuffled session.
- Allow restarting with a fresh shuffled order.
- Persist the current filter, shuffled order, and current index across app launches.

## Recommended Architecture

The iOS app should be a small native SwiftUI app with bundled JSON data and an observable session store.

### Layers

1. `WordEntry`
Defines the decoded spelling data model from bundled JSON.

2. `WordFilter`
Encodes the supported filter modes and display names.

3. `SpellingSessionStore`
Owns decoded data, active filter, shuffled session order, current index, persistence, and navigation methods.

4. `ContentView`
Renders the main practice screen with a filter picker, progress label, current word, and session controls.

## Data Strategy

The spelling list should move out of `index.html` and into a bundled `words.json` file in the Xcode target. This keeps the data editable without touching view code and is a better base for future features like stats, answer entry, and per-word metadata.

## Persistence

Session state should be stored in `UserDefaults` as a compact codable value containing:

- selected filter
- shuffled order as an array of words
- current index

On launch, the app should restore state only if the saved order is still valid for the current dataset and filter. Otherwise it should generate a fresh shuffled session.

## UI Direction

The first iOS pass should stay close to the existing app:

- one-screen flow
- large centered word
- filter picker at the top
- progress text in the header
- restart button
- previous and next navigation buttons

The layout should adapt cleanly to both iPhone and iPad using standard SwiftUI sizing rather than trying to reproduce the exact HTML styling.

## Future-Proofing

The session store should expose clear actions so later features can be added without rewriting the app structure:

- reveal or hide word states
- correct or incorrect marking
- score tracking
- practice modes
- session summaries

## Testing

The first implementation should focus on unit tests for the non-UI behavior:

- filter behavior
- session reset and shuffle shape
- navigation bounds
- persistence restore validation

UI testing can wait until the app has more interaction complexity.
