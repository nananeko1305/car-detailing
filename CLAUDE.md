# Car Detailing: architecture map

Android-only Flutter app for a detailing crew: a calendar of jobs built from a
price list, a shared wallet and the earnings history. Accounts exist only if
the admin creates them.

The README below is imported and holds the product rules, the data model, the
push design and the release process. This file adds what the README does not:
how the code fits together, and what breaks if you forget it.

@README.md

The global guidelines about Go layout and Neutrino libraries do not apply here:
there is no Go in this repository.

**Keep this true:** a change that alters anything below updates this file in the
same commit. No version numbers, line counts or lists of every file; they go
stale. The repository is **public**, so nothing secret goes here.

## System

```
                     ┌─ Firebase Auth      email/password, no self sign-up
 Android app ────────┼─ Firestore          direct from the app, offline cache on
 (Flutter)           ├─ Push worker        POST /announce
                     ├─ GitHub Pages       version.json, the update check
                     └─ FCM                receives pushes

 Push worker ────────┬─ Firestore REST     service account, bypasses the rules
 (Cloudflare, cron)  └─ FCM v1             per-phone job pushes, 21:00 reminder

 GitHub Actions ─────┬─ GitHub Release     the APK
 (push to main)      ├─ GitHub Pages       download page + version.json
                     └─ FCM topic          `releases`, every install
```

There is no backend of our own, so **`firestore.rules` is the security
boundary** for everything the app does. The worker's service account skips the
rules, so **its own checks in `push_worker/src/` are the only boundary on that
path**: it verifies the Firebase ID token and re-checks the account and the
author itself.

## Code map

Start-up: `main.dart` → `StartGate` (welcome: language, once per phone) →
`AuthGate` (signed in?) → `ProfileGate` (profile, switched off, or the one-time
admin claim) → `HomeScreen`. `AuthGate` keys `ProfileGate` by uid, so switching
accounts resets all state below it.

| Path | Holds |
|---|---|
| `lib/models/` | Immutable classes and the pure logic: `pricing.dart` (`quote`), `earnings.dart` (`Earnings`: pay by helper, category shares), `WalletMovement` |
| `lib/money/` | Parsing and formatting of dinars |
| `lib/services/` | Singleton repositories (`XRepository.instance`), `LiveData`, push, announcer, auth, updates |
| `lib/screens/` | Full screens; `HomeScreen` is the shell with three tabs and the drawer |
| `lib/widgets/` | Reusable pieces, sheets and dialogs |
| `lib/l10n/` | `app_en.arb` (template) and `app_sr.arb`; the generated Dart is committed |
| `lib/theme/` | `kCeramic` and `context.colors`; use these, not hard-coded colors |
| `push_worker/src/` | `index.js` routes, `announce.js`, `cron.js`, `crew.js` recipients, `message.js` texts, `google.js` Firestore and FCM |
| `android/app/src/main/` | `MainActivity.kt` creates notification channels; `res/values*/strings.xml` holds push titles |

## How the app works

- **Reads go through `LiveData`.** `HomeScreen` owns one per session and passes
  it down as `data`. It listens to whole collections and resubscribes with
  backoff, because a Firestore listener that errors never recovers. Filtering
  happens on the client, which is why `firestore.indexes.json` is empty.
- **Writes go through `saveInBackground`; do not await a Firestore write in
  UI.** The future does not complete offline. The exceptions are the admin
  claim and adding a worker, whose screens wait for the result.
- **Every job write goes through `JobRepository._write`**: `rev` by
  `increment(1)`, `updatedBy`, `updatedAt` as server time. The rules require
  all three, and the worker announces by comparing `rev` with `pushRev`.
- **Never `set()` an existing job.** It would drop the worker's `pushRev` and
  `pushStatus`, which the rules refuse. Edits use `update()`.
- **Money is an `int` in para, dinars only.** Category shares are split in
  whole dinars so they always add up.
- **The profit is the admin's.** A job's `helpers` carry their own pay;
  `Job.netMinor` (charged − helpers) is what the wallet takes in and what the
  admin keeps. Old jobs without `helpers` fall back to `workers` in
  `Job.fromMap`; keep writing `workers` for v1.0.x apps.
- **Fields kept only for the rules and older apps:** `end` is always written
  as '' (the rules require it); `equipmentMinor` from v1.1.0 is still allowed
  by the rules but never read or written. Equipment is wallet spending.
- **Balances and earnings are computed, never stored.**
- **User-visible text goes through `AppLocalizations`**, in both `.arb` files,
  then `flutter gen-l10n`. Serbian is `sr-Latn` (`kSerbianLatin`); plain `sr`
  gives Cyrillic dates.
- **`SnackBar` with an action needs `persist: false`** (Flutter 3.47), or it
  stays until closed.

## Who may do what

| Records | Create | Change | Delete |
|---|---|---|---|
| jobs | any active user, as author | any active user | author or admin |
| walletEntries | any active user | author or admin | author or admin |
| priceCategories, priceItems, meta/pricing | admin | admin | nobody (archive) |
| users | admin (workers), plus the one-time admin claim | self (name, phone); admin (others' name, phone, `disabled`) | nobody |

Not in the rules, so a new client path must repeat it: spending cannot take
the wallet below zero (`WalletMovement.overdraws`).

## What a change has to touch

**New Firestore collection:** the rules and `rules_test`, a model, a
repository, a `_watch` in `LiveData`, the README data model table. Deploy the
rules first.

**New field:** old documents and old APKs both exist. `fromDoc` tolerates its
absence; the rules' key lists must allow it, and an old APK must still pass.

**New push type:** `push_worker/src/message.js`; the title in
`res/values/strings.xml`, `values-sr` and `values-b+sr+Latn`; `res/raw/keep.xml`
(or resource shrinking drops it and the notification arrives empty); the key
list in the CI step "Verify notification strings"; `PushKind` and
`jobPushTitle` for the foreground snack bar. A new channel also goes in
`MainActivity.kt`.

## Testing

```sh
flutter analyze && flutter test       # the same gate CI runs before a release
cd push_worker && npm test            # node --test, with a fake fetch
cd rules_test && npm test             # the rules on the emulator
```

There is no fake Firestore, and repositories bind `FirebaseFirestore.instance`
when created, so tests cannot construct them; screens must not touch a
repository while building. `LiveData(listen: false)` with its fields set is the
fake for screens (`test/support.dart`).
