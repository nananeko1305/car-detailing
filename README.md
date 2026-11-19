# Car Detailing

Android app (Flutter + Firebase) for a crew that does deep cleaning of
furniture and car interiors and detailing: a shared calendar of bookings, a
shared cash wallet and the earnings history, built on a price list. Serbian
(Latin) and English. One look, "Keramika": graphite with a pearl sheen.

Firebase project: `car-detailing-261115` (Firestore in `eur3`), on the Google
account petarcocic1411@gmail.com, next to Car Expenses. The push worker runs on
the Cloudflare account of the same address.

## Accounts

There is no public registration.

1. The first account is made in the Firebase console (Authentication → Users →
   Add user). It signs in, enters its name and taps **Postani admin**. This
   works exactly once: `meta/admin` then locks the role.
2. The admin adds workers (menu → Radnici: name, phone, email, starting
   password) and can switch them off and back on. A switched-off worker
   cannot sign in; their jobs keep their name. Accounts are never deleted.

Everyone sees everything: calendar, wallet and earnings.

## Jobs

A job is one visit to a client, and it is both the booking and the earning:
there is no second record of the money.

- Date, **start time only** (a job takes as long as it takes), client, phone
  (tap to call), address (tap for the map), the **price-list items with
  quantities**, notes (such as which car).
- **"Radim sam | Imam pomoć"**: with help, any number of workers, each with
  **what they are paid** for the job. The form shows what that leaves the
  admin. The **profit always goes to the admin**; workers are helpers. Jobs
  from before v1.1.0 have no helpers: anyone listed in `workers` other than
  whoever booked it reads as a helper with no pay recorded.
- **Equipment** (chemicals, cloths…) is not part of a job: it is spending
  entered in the wallet by hand. v1.1.0 had a per-job equipment field; what
  it wrote (`equipmentMinor`) is ignored.
- The price is worked out from the items and the terms: the biggest discount
  whose threshold the order is **strictly above** ("iznad 6.000"), rounded to
  whole dinars, plus the travel fee below the free-travel amount when one is
  set. On top of that, a **"Konačan popust"** in whole percent comes off the
  whole (items, discount and travel), rounded to whole dinars; typing it
  sets the agreed price again. Anyone can type over the price; "Vrati cenu
  po cenovniku" brings it back.
- **booked → done or cancelled.** "Završi posao" asks what was charged
  (the agreed price unless it changed on the spot), whether it goes into the
  wallet (on by default), and the helpers' pay, filled in from the booking.
- A booked job whose day has passed shows on top of the calendar as **"Nije
  završeno"** until someone finishes or cancels it.
- A client who came without booking: a new job with **"Već završeno"**.
- Cancelled jobs stay in the history, struck through, out of the earnings.
  "Vrati u zakazano" undoes done or cancelled. Delete is for mistakes, by the
  author or the admin, and tells nobody.
- Anyone may add, edit, finish or cancel any job.

## Price list

Categories, each with items and a note (what is included, which cars count as
small, medium, large or SUV), plus the terms in `meta/pricing`. Everyone reads
it; only the admin edits it. Items and categories are put away (archived),
never deleted. A job copies the items it was booked with, so a later price
change never rewrites an old job. On a fresh database the admin loads the
crew's paper list (`assets/price_list.json`, 2026-11-15) with one tap.

## Wallet and earnings

- **Wallet:** one balance in dinars. A finished job with "U novčanik" comes
  in by itself as one line: what was charged, less the helpers' pay, which
  leaves the wallet with it. Anyone puts money in or records spending, such
  as equipment (what for, date, who). The month card shows the admin
  *Moja zarada*, *Dato radnicima* and *Troškovi*; a worker sees what they
  were paid. Spending can never take the wallet below zero: the app checks it, not
  the rules, so two people spending at the same moment could still both get
  through. Entries are changed or deleted by their author or the admin.
- **Earnings:** a month or a year: charged, jobs, average per job, given to
  helpers, costs (wallet spending), the admin's earnings
  (charged − helpers − costs), money put in by hand,
  cancelled jobs, by price-list category, paid to each helper, month by month
  for a year, and the finished jobs. A worker also sees what they got.
  Computed every time, never stored.

Everything is in dinars, stored as integers in para.

## Data model

| Collection | Fields |
|---|---|
| `users/{uid}` | `email`, `firstName`, `lastName`, `phone`, `role` (`admin`/`worker`), `disabled`, `createdAt` |
| `jobs/{id}` | `ownerId`, `date` (yyyy-MM-dd), `start` (HH:mm), `end` (always '' since v1.1.1; the rules still require it), `clientName`, `clientPhone`, `address`, `items` (`{itemId, categoryId, name, priceMinor, qty}`), `subtotalMinor`, `discountPercent`, `travelMinor`, `priceMinor`, `finalDiscountPercent` (0–100, since v1.1.2), `helpers` (`{uid, payMinor}`), `workers` (the helpers' uids, for v1.0.x apps), `notes`, `status` (`booked`/`done`/`cancelled`), `paidMinor`, `toWallet`, `doneBy`, `doneAt`, `rev`, `updatedBy`, `createdAt`, `updatedAt`; v1.1.0 only, ignored: `equipmentMinor`; worker only: `pushRev`, `pushStatus` |
| `walletEntries/{id}` | `type` (`deposit`/`withdrawal`), `amountMinor`, `description`, `date`, `userId` (who), `createdBy` (author), `updatedAt` |
| `priceCategories/{id}` | `name`, `note`, `order`, `archived` |
| `priceItems/{id}` | `categoryId`, `name`, `priceMinor`, `order`, `archived` |
| `pushTokens/{token}` | `uid`; read only by the worker |
| `meta/admin` | `uid` of the admin (one-time claim) |
| `meta/pricing` | `discounts` (`{overMinor, percent}`), `freeTravelFromMinor`, `travelMinor` |
| `meta/reminder` | `day` of the last evening reminder (worker only) |

All access rules are in [firestore.rules](firestore.rules), tested in
[rules_test](rules_test).

## Pushes

Job pushes name clients, addresses and money, so they never go to a topic:
the [push worker](push_worker) sends them to the phones of active accounts one
by one, and holds the service-account key the APK cannot carry.

| Push | When | Channel |
|---|---|---|
| New / changed / cancelled booking | on save; not to whoever saved it; not for past days | jobs |
| Tomorrow's bookings | 21:00 Belgrade, one push listing them | reminders |
| New version | after every release (CI, topic `releases`) | updates |

Finishing a job sends nothing. Every app write bumps `rev`; the phone that made
it asks `POST /announce {kind: 'job', id}` once the server has the change, and
asks again on every start until the worker has caught up (`pushRev`). The
worker checks the ID token and that the caller is active and made the change,
marks the job only if it has not changed since it was read, and only then
sends: a repeated call sends nothing. Titles are string resources, so each
phone shows its own language.

## Release

- Work happens on `dev`; a PR from `dev` to `main` ships. **Every merge into
  `main` builds a signed APK, publishes a GitHub Release and the download page
  with `version.json`, and notifies every install.** A change to
  `.github/pages/**` alone redeploys only the page.
- The commit type sets the version: `feat` bumps the minor, anything else the
  patch, a breaking change the major. `pubspec.yaml` is only a floor.
- Download page: https://nananeko1305.github.io/car-detailing/ — the APK is
  named after its version (`car-detailing-1.0.0.apk`).

| Piece | Deployed by | When |
|---|---|---|
| App | CI, on a push to `main` | merging is the release |
| `firestore.rules` | `firebase deploy --only firestore:rules` | **before** the merge that needs them |
| Push worker | `npm run deploy` in `push_worker/` | **before** the merge that needs it |

GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `FCM_SERVICE_ACCOUNT`.
Cloudflare secret: `GOOGLE_SERVICE_ACCOUNT`. The originals are kept outside
this repository, with a list of what each one is.

## Testing

```sh
flutter analyze && flutter test            # the same gate CI runs
cd push_worker && npm ci && npm test       # the worker, with fakes
cd rules_test && npm install && npm test   # the rules, on the Firestore emulator
```

## Fonts

Space Grotesk and Inter, bundled under `assets/fonts/` with their SIL Open
Font Licenses.
