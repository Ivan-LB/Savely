# Localization

The hard rule: **no hardcoded user-facing strings in views.** Everything goes through `Resources/Strings.swift` and is registered in `Localizable.xcstrings`.

## How it works

`Strings.swift` exposes typed constants that wrap `NSLocalizedString` (or `String(localized:)` on iOS 15+):

```swift
enum L10n {
  enum Goals {
    static let title = String(localized: "goals.title", defaultValue: "Goals")
    static let addGoal = String(localized: "goals.addGoal", defaultValue: "Add Goal")
    static func progress(_ percent: Int) -> String {
      String(localized: "goals.progress", defaultValue: "\(percent)% complete")
    }
  }
}
```

`Localizable.xcstrings` is Xcode's string catalog format (Xcode 15+). It auto-discovers keys when you reference them via `String(localized:)`.

## Adding a new string

1. Pick a dotted key: `<feature>.<element>` or `<feature>.<element>.<state>`. Examples: `expenses.empty.title`, `auth.login.error.invalidCredentials`.
2. Add a constant in the appropriate `L10n.<Feature>` enum in `Strings.swift`.
3. Use it in the view: `Text(L10n.Expenses.title)`.
4. Open `Localizable.xcstrings` in Xcode — the new key appears under the default language. Add translations for other locales.

## Pluralization

Use `String(localized:)` with a stringsdict-style entry in the catalog:

```swift
static func itemCount(_ n: Int) -> String {
  String(localized: "items.count",
         defaultValue: "\(n) items")
}
```

Then in the catalog, set the variation by `%lld` count → singular `1 item` / plural `%lld items`.

## Don't

- ❌ `Text("Goals")` — hardcoded literal
- ❌ `Text("\(count) items")` — manual pluralization
- ❌ String concatenation: `Text("Hello, " + name)` — use `Text("Hello, \(name)")` and localize the whole template
- ❌ Capitalize/lowercase the result of a localized string — different languages have different casing rules

## Date and number formatting

Don't use `Strings.swift` for these — use `Date.FormatStyle` and `Decimal.FormatStyle`:

```swift
expense.date.formatted(date: .abbreviated, time: .omitted)
amount.formatted(.currency(code: "MXN"))
```

These respect the user's locale automatically.

## Accessibility labels

Accessibility labels are also user-facing strings. Same rule — go through `L10n`:

```swift
Image(systemName: "trash")
  .accessibilityLabel(L10n.Common.delete)
```

## Catalog hygiene

- Keep keys grouped by feature in `Strings.swift` so they're easy to find.
- When you delete a feature, delete its keys from both `Strings.swift` and the catalog.
- Don't ship strings with `defaultValue` only — make sure every supported locale has a translation before merging a release.
