# Testing

How tests are organized, how to run them, and the migration plan to Swift Testing.

## Today's state

- `SavelyTests/SavelyTests.swift` — XCTest skeleton, no real coverage
- `SavelyUITests/SavelyUITests.swift` — XCTest skeleton
- `SavelyUITests/SavelyUITestsLaunchTests.swift` — XCTest launch test

The test schemes (`SavelyTests`, `SavelyUITests`) are **not shared**. Only `Savely.xcscheme` is shared, and its Test action includes both bundles.

## Running tests

```bash
xcodebuild test \
  -project Savely.xcodeproj \
  -scheme Savely \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -resultBundlePath build/TestResults.xcresult
```

To open the result bundle locally:
```bash
open build/TestResults.xcresult
```

## Swift Testing migration

**New tests use Swift Testing (`@Test`)**, not XCTest. Swift Testing landed in Xcode 16 and is the modern API.

```swift
import Testing
@testable import Savely

@Suite("Goal progress")
struct GoalProgressTests {
  @Test("clamps at 100% when saved exceeds target")
  func clampsAtOneHundred() async throws {
    let goal = GoalModel(target: 100, saved: 150)
    #expect(goal.progress == 1.0)
  }

  @Test("returns 0 when target is 0")
  func zeroTarget() async throws {
    let goal = GoalModel(target: 0, saved: 50)
    #expect(goal.progress == 0)
  }
}
```

Existing XCTest files stay XCTest until they're rewritten — don't mix `@Test` and `XCTestCase` in the same file.

UI tests stay on XCTest for now — Swift Testing's UI-test support is less mature.

## Test data: in-memory SwiftData

Don't mock `ModelContext`. Use an in-memory container:

```swift
@MainActor
@Test func goalCreationPersists() async throws {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try ModelContainer(
    for: GoalModel.self,
    configurations: config
  )
  let context = container.mainContext

  let goal = GoalModel(name: "Test", target: 1000, saved: 0)
  context.insert(goal)
  try context.save()

  let fetched = try context.fetch(FetchDescriptor<GoalModel>())
  #expect(fetched.count == 1)
}
```

## Firebase in tests

Don't hit Firebase in unit tests. Two options:

1. **Inject a protocol** — wrap the manager in a protocol, provide a fake in tests.
2. **Firebase Local Emulator Suite** — for integration tests, run `firebase emulators:start` and point the SDK at it. Mark these tests with a separate `@Suite("Integration")` and skip in CI by default.

Today there are no integration tests. When adding them, document the setup in `firebase.md` and gate them behind an env var so they don't run in regular CI.

## Migration tests (SwiftData)

When a `@Model` schema changes, add a test:

```swift
@Test func migratesGoalsFromV1ToV2() async throws {
  // 1. Create a container at the V1 schema with sample data
  // 2. Run the migration
  // 3. Open at V2 schema and verify the data shape
}
```

Without this, you find out about migration bugs in production when users update.

## What to test (and what not to)

**Always test:**
- Pure functions and computed properties on models (`progress`, `formattedAmount`, etc.)
- View model state transitions (loading → loaded → error)
- Migration paths
- Bug fixes (write the test that reproduces the bug, then fix)

**Don't test:**
- SwiftUI view layout (use Previews instead)
- Trivial getters/setters
- Third-party SDK behavior (Firebase, OpenAI internals)

**UI test the critical paths only:**
- Launch → onboarding → main
- Login → main
- Add expense → see it in dashboard
- Add goal → see it in goals tab

UI testing every screen is brittle and slow. Pick the user journeys that would be embarrassing to break.

## CI and result bundles

When CI fails, the `.xcresult` bundle is uploaded as an artifact. Steps to read it:

1. Open the failed workflow run on GitHub
2. Scroll to "Artifacts" at the bottom
3. Download `TestResults.xcresult.zip`
4. Unzip and `open TestResults.xcresult` in Xcode

The bundle has the full test report, console output, and any screenshots/recordings UI tests captured.
