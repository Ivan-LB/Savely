# Firebase

How Savely uses Firebase, what's stored where, and the rules for changing it.

## What we use

| Product | Purpose |
|---|---|
| Firebase Auth | Email/password + Sign in with Apple |
| Firestore | User profile (only) |

We do **not** use Firebase Analytics, Crashlytics, Remote Config, Cloud Functions, Cloud Messaging, or Storage today. Adding any of these is a non-trivial decision — surface as an option, don't pull them in silently.

## Configuration

`GoogleService-Info.plist` lives in `Savely/` and is **gitignored**. Firebase reads it automatically at app launch.

If you ever need to regenerate it: Firebase console → Project settings → Your apps → iOS → download `GoogleService-Info.plist` → drop into `Savely/` (don't commit).

## Auth

`AuthenticationManager.shared` owns auth state. Public surface:

```swift
final class AuthenticationManager {
  static let shared: AuthenticationManager
  var currentUser: AuthDataResultModel? { get }
  var authStateStream: AsyncStream<AuthDataResultModel?> { get }

  func signIn(email: String, password: String) async throws -> AuthDataResultModel
  func signUp(email: String, password: String) async throws -> AuthDataResultModel
  func signInWithApple() async throws -> AuthDataResultModel
  func signOut() throws
  func deleteAccount() async throws
}
```

`AuthDataResultModel` (in `Models/`) wraps `FirebaseAuth.User` — never expose the raw Firebase type to views.

## Firestore: user profile

The single Firestore collection in use today is `users/{uid}`, storing one document per user.

### `users/{uid}` document shape

```
users/{uid}
├── id: String (== uid)
├── email: String
├── name: String?
├── photoURL: String?
├── isPremium: Bool
├── currency: String  (e.g. "MXN", "USD")
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

The Swift mirror is `DBUserModel` in `Models/DBUserModel.swift`. CRUD goes through `UserManager.shared`:

```swift
final class UserManager {
  static let shared: UserManager
  func createUser(_ user: DBUserModel) async throws
  func fetchUser(userId: String) async throws -> DBUserModel
  func updateUser(_ user: DBUserModel) async throws
  func deleteUser(userId: String) async throws
}
```

When the document shape changes:
1. Update `DBUserModel`.
2. Update encode/decode logic in `UserManager` and its extension.
3. Update this file.
4. If the change is backwards-incompatible, write a migration path (read old → write new) in `UserManager`. Test on a real document.

## Offline behavior

Firestore caches by default — reads work offline against the local cache, writes queue and sync on reconnect. **Don't disable persistence.**

Network state is observed by `AppViewModel`. When offline, the UI should surface a banner via `Strings.swift` (currently TBD — open work).

## What's NOT in Firestore (and shouldn't be)

- **Expenses, incomes, goals, tips** — these live in SwiftData locally. There is no cloud sync today.
- **OpenAI API key** — lives in `Config.plist`, not Firestore.
- **App settings** (dark mode, onboarding flag) — UserDefaults.

If you want to add cloud sync for transactions, that's a major architecture change — surface as an option, document the trade-offs (conflict resolution, write costs, offline reconciliation), and get explicit approval.

## Security rules

Firestore security rules live in the Firebase console (not in this repo). The current rule of thumb is:

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

When a new collection or field is added, update the rules in the console **before** the client code ships.

## Common gotchas

- **Timestamps:** Firestore returns `Timestamp`, not `Date`. Convert in the DTO via `dateValue()`.
- **Optional fields:** Firestore omits `nil` fields entirely. When decoding, use `Optional<T>` Swift-side.
- **Document IDs:** the `id` field stored in the document must equal the document's path-level ID (`uid`). They drift when someone forgets, and it's painful to fix.
- **`@DocumentID` property wrapper** is from `FirebaseFirestoreSwift` — we don't use it; we encode manually.
