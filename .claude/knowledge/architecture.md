# Architecture

How Savely is organized. Specialists pull this when they need to understand a layer they don't own.

## High-level flow

```
SavelyApp (@main)
  └── AppViewModel  ←  single source of truth: auth state, user profile, dark mode, network
        └── ContentView
              ├── .loading      → splash
              ├── .loggedOut    → LoginView / SignUpView
              ├── .onboarding   → OnboardingView
              └── .main         → MainNavigationView (TabView)
                                      ├── DashboardTab
                                      ├── ExpensesTab
                                      ├── IncomesTab
                                      ├── GoalsTab
                                      └── ProfileTab
```

`AppViewModel` is injected as `@EnvironmentObject` throughout. The `AppState` enum drives top-level routing.

## Layers

| Layer | Path | Role | Owns external I/O? |
|---|---|---|---|
| Views | `Savely/Views/` | Pure SwiftUI, no business logic | No |
| ViewModels | `Savely/ViewModels/` | `@MainActor`, `@Observable`. Compose data, expose state | No (delegates to managers) |
| Models | `Savely/Models/` | `@Model` (SwiftData) + DTOs (Codable, Firestore, OpenAI) | No |
| Managers | `Savely/Managers/` | Singletons that wrap external SDKs | Yes |
| Extensions | `Savely/Extensions/` | `<Manager>Extension.swift` — split impls | Yes |
| Utilities | `Savely/Utilities/` | OpenAI client, OCR, helpers | Yes (only OpenAI client + OCR) |
| Resources | `Savely/Resources/` | Strings, colors, sizing constants | No |

## The View / ViewModel contract

- View binds to a view model via `@State` (owned by the parent that creates it) or `@Bindable` (if the view model is passed down).
- View model is `@MainActor` and `@Observable`.
- View model receives services via initializer (don't reach into `XYZManager.shared` from inside the view).
- View model never imports SwiftUI types beyond `Color`, `Image`, `LocalizedStringKey`. No `View` conformances.

## The ViewModel / Manager contract

- Manager methods are `async throws`.
- Manager errors are typed enums.
- View model wraps manager calls in `Task` and translates errors to user-facing `Strings.swift` keys.

## SwiftData container

Configured in `Savely/SavelyApp.swift`. Models registered: `ExpenseModel`, `IncomeModel`, `GoalModel`, `TipModel`. `DBUserModel` is the Firestore DTO and is **not** a SwiftData `@Model`.

Migrations: when a `@Model` field changes, register a migration plan in `SavelyApp.swift`. Coordinate via `data-model-specialist`.

## Firestore

Authoritative source for the user profile (`DBUserModel`). Local SwiftData is the source of truth for transactions (expenses, incomes, goals) — Firestore is not used for them today. If that changes, document in `firebase.md`.

## Manager / Extension split

Each manager has a small core file and one or more extension files:

```
Managers/AuthenticationManager.swift   ← class declaration, shared state
Extensions/AuthenticationManagerExtension.swift   ← email/password flow, Apple flow, etc.
```

The split keeps each file under ~200 lines. When adding a new method, add it to the extension that matches its concern, or create a new extension if it's a new concern.

## Routing decision tree (for the orchestrator)

```
Touches a .swift file under Views/ or ViewModels/  → swiftui-feature-specialist
Touches a .swift file under Models/                → data-model-specialist
Touches Managers/, Extensions/, OpenAIClient,
  Notifications, OCRUtilities, SignInWithApple    → services-specialist
Touches .github/, project.pbxproj, entitlements,
  schemes, .swiftlint.yml, Package.resolved        → build-ci-specialist
Touches SavelyTests/ or SavelyUITests/             → qa-tester
Touches .gitignore, .github/templates, branches,
  commits, PRs                                     → git-workflow-specialist
Multiple of the above                              → split into multiple PRs
```
