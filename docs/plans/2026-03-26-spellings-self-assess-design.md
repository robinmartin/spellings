# Spellings Self Assess Design

## Goal

Add a second practice mode called `Self Assess` while preserving the current mode as `2-Person`.

## Existing Mode

The current app behavior should remain available under a renamed `2-Person` mode:

- pick a filter
- show one shuffled word at a time
- navigate previous and next
- restart the session
- persist progress

## New Self Assess Mode

`Self Assess` is a solo spelling test flow:

1. Choose the filter list to work from.
2. Start a shuffled session from that list.
3. Show a play button that speaks the current word aloud.
4. Let the user type the answer with autocorrect, predictive text, and spelling assistance disabled.
5. Submit the answer without revealing whether it is correct.
6. Continue until all words have answers.
7. Tap `Complete Test` to reveal results.
8. Show a final score and only the incorrect answers, including both the typed answer and the correct spelling.

## Recommended Architecture

Keep shared data and filter logic in the existing store layer, but separate mode-specific session behavior.

### Shared

- bundled spelling data
- filter selection
- shuffled order generation
- progress calculation

### 2-Person Session

Keep the current navigation-based session behavior with only minor renaming and layout changes.

### Self Assess Session

Add a dedicated session model that tracks:

- active shuffled order
- current answer draft
- submitted answers by word
- completion state
- deferred scoring

This keeps the original mode stable and avoids overloading one store with conflicting state models.

## Speech

Use Apple text-to-speech for `Self Assess`, most likely `AVSpeechSynthesizer`. The play button should replay the current word on demand.

## Input Rules

The answer field should be configured to minimize hints:

- no autocorrect
- no text suggestions if available through SwiftUI/UIKit bridges
- no automatic capitalization
- plain text entry

The app should not mark correctness until the end screen.

## Results Screen

The summary should show:

- score such as `18 / 24`
- percentage
- a list of only incorrect responses
- for each incorrect response: spoken target word, typed answer, correct spelling

## Persistence

The current persisted session format should be expanded so app relaunch restores the selected mode and that mode's in-progress state. The stored shape should stay explicit rather than loosely keyed so future modes can be added safely.

## Testing

Focus the first automated coverage on logic rather than UI:

- mode persistence
- self assess answer submission and completion
- deferred scoring
- incorrect answer reporting
- existing 2-person filtering behavior remains intact
