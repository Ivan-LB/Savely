# Dead API records still in the project

> Found 2026-08-20 while grounding atelierbelli.com/savely/support in what the
> app actually does. Companion to `drop-bundled-config-plist.md`, which covers
> the third record (the bundled OpenAI plist) on its own.
> Status: **§1 and the on-disk half of §2 DONE in 1.1 (branch
> `chore/release-hygiene`)** — ATS block removed, GoogleService-Info.plist
> deleted locally. **Still open, owner-only:** the Firebase project
> `savely-5160e` (§2, "How much this actually matters") — confirm it is dormant
> and delete it in the Firebase console.

Savely 1.0 talks to nothing. The OpenAI tips feature is unreachable
(`FeatureFlags.tipsEnabled = false`, `Savely/Utilities/FeatureFlags.swift:22`)
and the Firebase auth stack was removed in 2026-08. What is left is paperwork
that still describes integrations the app no longer has.

## 1. ATS exception for openai.com

`Savely/Info.plist:10-26` still declares an `NSAppTransportSecurity`
exception-domain block for `openai.com`. It grants nothing dangerous
(`NSExceptionAllowsInsecureHTTPLoads` is `false`), but it is statically visible
to App Review and it advertises a network integration in an app whose support
page and App Privacy answers both say nothing leaves the phone.

**Chore:** delete the whole `NSAppTransportSecurity` dict. Keep
`ITSAppUsesNonExemptEncryption` — that one is load-bearing for upload.
Restore the exception only if the tips feature is ever re-enabled.

## 2. GoogleService-Info.plist

Two separate facts, and only the second one matters:

- **On disk:** `Savely/GoogleService-Info.plist` still exists but is inert. It
  is not referenced by `project.pbxproj` and not imported by any `.swift` file
  (verified by grep), so it does **not** ship in the binary. It is leftover
  weight from the removed auth stack. Safe to delete whenever.
- **In git history:** it was committed in `80cf033` ("Implementation of
  Firebase to the Project") and the blob is still reachable
  (`git cat-file -p 311b1042689098ca3a8e97e432f3a1c560cabb18`). `.gitignore`
  only stopped future tracking. **`github.com/Ivan-LB/Savely` is a public
  repo**, so the contents are publicly readable today.

### How much this actually matters

Less than it looks, but not zero, and **this key was never revoked** — it is
not the OpenAI key Iván killed on 2026-08-19, it is a separate Firebase
credential for project `savely-5160e`.

A Firebase iOS `API_KEY` is not a secret in the classic sense: Google documents
it as a project identifier, not an authorization token. Real protection comes
from Firebase Security Rules, API-key restrictions, and App Check, not from
hiding the string. So the exposure is closer to "project identifiers are
public" than "credentials leaked".

What still deserves a look, in rough priority order:

1. **Confirm the Firebase project is actually dormant.** If `savely-5160e` has
   no active Auth users, no Firestore/Storage data, and no billing, the
   exposure is academic and deleting the whole project is the cleanest fix.
2. **If the project stays alive**, add an API-key restriction (bundle-id
   allowlist) in Google Cloud Console → APIs & Services → Credentials, and
   confirm Security Rules are not left in test mode.
3. **Only then consider a history rewrite.** `git filter-repo` plus a
   force-push would purge the blob, but it rewrites every commit hash, breaks
   existing clones, and touches a repo wired to Xcode Cloud. Given the key is a
   project identifier and the project is likely dormant, deleting the Firebase
   project outright is a better fix than rewriting history.

**Do not** treat "the key was revoked" as covering this one. It was not.

## 3. Bundled Config.plist

See `drop-bundled-config-plist.md`. Key revoked 2026-08-19; the build-phase
entry is the remaining bug.
