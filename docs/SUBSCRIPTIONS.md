# Subscriptions — plan

The written plan for #27, now with the owner's decisions in. Nothing here is built yet; each step
under **Build order** is its own issue, and each lands on iOS and Android in one pull request.
Product rules 5 and 6 in `docs/HANDOFF.md` §1 still hold: no data leaves the device, and a parent
gate guards anything that costs money.

## The shape in one paragraph

**Hop Tales Plus** is one auto-renewing subscription with a monthly and a yearly plan, and no free
trial. **Every Level 1 story** is free forever, with no account and no clock, and that is the
taste. Every story above Level 1, and every story added later above Level 1, needs Plus. A child
who reaches a locked story, or finishes Level 1, sees an "Ask a grown-up" button with no price and
nothing to buy. Only a grown-up who passes the parent gate ever sees the paywall. Progress and
stars are never taken away.
StoreKit 2 on iOS and Google Play Billing on Android do all of it on the device, with no server of
ours.

## 1. What is free and what is paid

| | Free | Plus |
|---|---|---|
| Every Level 1 story, read and re-read | ✓ | ✓ |
| Every story above Level 1, now and future | | ✓ |
| Speech, help, stars, moods, settings | ✓ | ✓ |
| Friends and wardrobe looks earned by reading | ✓ | ✓ |
| Play on the TV (AirPlay) | ✓ | ✓ |
| iPad | ✓ | ✓ |

- **The free tier is Level 1, not one named story.** The rule is `story.level == 1` in
  `stories.json`, so it covers the four Level 1 stories today (The Meadow Walk, Bob and the Bug,
  The Big Nap, Bob and the Mud) and any Level 1 story added later. Every new reader starts at
  Level 1 with Bob, and onboarding offers no other starting friend.
- **No feature ever sits behind the paywall**, only stories. The reading loop is the same for
  everyone, so a free child never meets a lesser version of the game.
- **The TV isn't paywalled.** It's the feature that sells the app on the living-room floor, and
  it costs us nothing to give away.
- **Cosmetics are never sold.** Friends, wardrobe looks and treats are earned by reading, for free
  and Plus children alike. There is no shop and no in-app currency (`docs/DESIGN-HANDOFF-FRIENDS.md`
  rule 5 still holds).
- **The journey keeps going.** A free child who reads well enough at Level 1 still meets the next
  friend. That friend's stories show the locked card, and the four Level 1 stories stay open.
- **A starting friend above Level 1.** Onboarding no longer offers one: every new reader starts
  with Bob. A reader who was set up on Skip or Oggy before that, or whom a grown-up moves up in
  Settings, keeps the friend; the friend's own stories show the locked card, and Home offers the
  Level 1 stories to read.

### No free trial

- **Neither plan has an introductory offer.** Nobody has the full library until they pay. The four
  Level 1 stories are the taste: a family can read them for as long as they like and decide.
- The yearly plan is the one the paywall leads with, as the better value: "$2.50 a month".
- **No lifetime unlock.** Two plans, nothing else to choose between.

## 2. Products and prices

| Plan | iOS product ID | Android (Play) | Price (USD) |
|---|---|---|---|
| Plus Monthly | `com.hoptales.plus.monthly` | `hop_tales_plus`, base plan `monthly` | $4.99 / month |
| Plus Yearly | `com.hoptales.plus.yearly` | `hop_tales_plus`, base plan `yearly` | $29.99 / year |

- **iOS.** One subscription group, reference name `hop_tales_plus`, holding the two products, so
  a grown-up can switch plans without double-paying.
  - Both products exist in App Store Connect: monthly at $4.99 for 1 month, yearly at $29.99 for
    1 year paid upfront, Family Sharing on, no introductory offer.
  - The yearly product is a plain 1-year subscription, not "Monthly with a 12-Month Commitment".
- **Android.** One subscription product, `hop_tales_plus`, with two auto-renewing base plans,
  `monthly` and `yearly`, and no offers.
- **Why the IDs differ.** Apple has no base plans, so each plan is its own product. Play groups
  the plans under one product, which is the same shape as Apple's subscription group. Both apps
  map their store's IDs onto one shared `PlusPlan` (`monthly`, `yearly`) in the shared logic, and
  nothing else in the app sees a store ID.
- **Base storefront.** The account's primary language is English (Canada). Either Canada or the
  US works as the base price, and both consoles convert the rest. Check the converted prices
  before launch; round them by hand where they land awkwardly.
- **Why these prices.** The big children's reading subscriptions sit at about $10–13 a month
  (from memory, so check before launch). Hop Tales has a smaller library, so it should look like
  an easy yes.
  - Yearly works out at $2.50 a month, half the monthly price, and is the plan the paywall leads
    with.
- **Revenue share.**
  - Apple: enrol in the App Store Small Business Program, which cuts the commission from 30% to
    15%.
  - Google: Play's service fee for subscriptions is 15% from the first day.

### A lapsed subscriber keeps everything they earned

- Stars, per-story progress, finished sentences, friends met and wardrobe looks stay in
  `ProgressStore`, untouched.
- Plus stories go back to the locked card. The card still shows the story's standing ("You read 4
  of 6"), so resubscribing picks up exactly where the child left off.
- Every Level 1 story and all settings keep working.
- Nothing is ever deleted because a subscription ended.

## 3. The paywall and what a child sees

A child must never be able to act on a purchase prompt.

**The locked story card (child-facing).** A Plus story on Home shows a small paper padlock
sticker. Tapping it opens a card with the story's art and title, the story's standing when it has
one ("You read 4 of 6"), "This story is part of Hop Tales Plus", and one button: **Ask a
grown-up**. The card has no price, no plan names and no buy button.

**The parent gate.** Ask a grown-up opens the gate from rule 6:
- It's a times-table question in words ("What is seven times eight?") with a number pad.
- It's never a press-and-hold.
- A wrong answer draws a new question, with no lockout and no failure state for the child.
- The gate is one shared component on each app. The paywall, Restore, Manage subscription, Request
  a refund and any future outside link all go through it.
- Build step 2 (#346) added it on both apps, with the locked story card as its first use. Until the
  paywall lands (#347), passing the gate shows a "Hop Tales Plus is on its way" note.

**The paywall (grown-up-facing, behind the gate).**
- **iOS.** StoreKit's `SubscriptionStoreView` for the `hop_tales_plus` group, styled as a paper
  sheet over the meadow.
  - It shows the two plans, auto-renewal wording, and links to Terms of Use and the Privacy
    Policy, which App Review requires for subscriptions.
  - It includes Restore purchases (`.storeButton(.visible, for: .restorePurchases)`).
  - Using Apple's view instead of a custom one keeps the required disclosures correct as the rules
    change.
- **Android.** A Compose sheet drawn in the same paper style, listing the two base plans from
  `queryProductDetailsAsync`, with the yearly plan first. Buying calls `launchBillingFlow` with the
  base plan's offer token, and Play draws its own purchase sheet over it.
  - The sheet carries the plan prices, "renews automatically until cancelled, cancel any time in
    Google Play", and links to the Terms of Use and the Privacy Policy.
- **Both.** A plain two-plan paywall. The yearly plan leads as the better value, "$2.50 a month",
  with monthly as the flexible option. The content rhythm (section 7) is the line under the
  title: why Plus is worth keeping.

**Where the paywall can be reached:**
1. The locked story card, then the gate.
2. **Grown-ups (settings)**, in a new "Hop Tales Plus" section:
   - The status, in plain words: "Plus, renews 3 March" or "Free: the Level 1 stories".
   - Subscribe, Restore purchases, Manage subscription and Request a refund.
   - What subscribers get: every story above Level 1 and the content rhythm.
   - The rest of Settings still opens without the gate. Only this section's buttons ask first.
3. **The end of onboarding**, once:
   - After the last onboarding step, the paywall opens in its onboarding form: both plans, yearly
     leading, and a clear secondary button, **Try Level 1 free**, which closes it and starts the
     app on the free stories.
   - It goes through the gate first, like every other way to the paywall. Onboarding is filled in
     by a grown-up, so the question goes to the person holding the phone; leaving the gate also
     starts the app on the free stories, with no further prompt.
   - This is the one moment a grown-up is guaranteed to be holding the phone. It's shown once and
     never comes back on its own; resetting onboarding (a grown-up action) shows it again.
4. **"You finished Level 1!"**, once (child-facing, see below), through its Ask a grown-up button
   and the gate.

**"You finished Level 1!" (child-facing).** When a free reader has finished every Level 1 story
at least once, the next step up is the first thing Plus sells, so the app marks it:
- A celebratory paper card in the app's style: paper confetti, the Level 1 rosette and "You
  finished Level 1!".
- It previews what's next: Skip, the Level 2 friend, in colour with "Skip is waiting", and the
  trickier words as Skip's "Words like …" examples from the onboarding trail.
- Buttons: **Ask a grown-up**, which opens the gate and then the paywall, and **Keep reading**,
  which closes the card to Home with the Level 1 stories open to read again.
- No price, no plan names and nothing to buy, like the locked card.
- **Where it sits.** It's a journey moment, produced by the `Journey` feature with the others
  (tally, big story, new friend) and shown on the reading panels at The end. It comes right after
  the tally of the read that finishes the last Level 1 story. Finishing every story at the level
  is also what first lets a Bob reader move up (`docs/DESIGN-HANDOFF-FRIENDS.md` §3a), so:
  - on that read it takes the big-story card's place; the big-story card, which leads to Skip's
    locked story, comes back at the next The end as usual;
  - a new-friend moment earned on the same read (the trail or sustained reading) follows it, and
    Skip's stories then show the locked card.
- **Shown once**, recorded on the reader's progress so it syncs and doesn't come back on another
  device. After that the locked cards are the way in. A reader who had already finished every
  Level 1 story before this ships sees it at the end of their next Level 1 story.
- It never appears for a Plus subscriber, and not while the release switch keeps every story open
  (build step 1), since there'd be nothing to unlock.

**Never:** a paywall mid-story, on launch, after the intro, or anywhere a child can reach it by
tapping. There are no countdowns and no "offer ends soon". A journey moment that would open a
locked story (a new friend's first story) shows the friend and then the locked card, never the
paywall.

## 4. Restore, Family Sharing, refunds and grace periods (iOS)

All of this is StoreKit 2 on the device.

- **Entitlement.**
  - At launch, iterate over `Transaction.currentEntitlements`, which is on-device and cached, so
    it works offline in the car.
  - While the app runs, listen to `Transaction.updates`.
  - Plus is active when a verified transaction for either product ID has no `revocationDate`.
  - The app keeps no entitlement cache of its own. StoreKit's is authoritative and survives
    reinstalls.
- **Restore purchases.** Call `AppStore.sync()` from the Grown-ups section and from the paywall,
  behind the gate. It's rarely needed with StoreKit 2, but App Review expects the button.
- **Manage subscription.** `showManageSubscriptions(in:)`, behind the gate.
- **Family Sharing.** Turn it on for both subscriptions in App Store Connect. One grown-up
  subscribes and every child's device in the family has Plus.
  - Shared transactions arrive with `ownershipType == .familyShared` and count the same.
  - For a family app this is a selling point, so say so on the paywall and the website.
- **Billing grace period.** Turn on the 16-day grace period in App Store Connect.
  - During grace the subscription stays in `currentEntitlements`, so the child notices nothing.
  - The Grown-ups section shows "There's a problem with your payment" and a Manage subscription
    button, from `Product.SubscriptionInfo.Status` (`.inGracePeriod`, `.inBillingRetryPeriod`).
  - After grace, Apple's billing retry runs with no access, and stories lock as for any lapse.
- **Refunds.**
  - Grown-ups can ask for one in the app with `beginRefundRequest`, behind the gate.
  - A refunded transaction arrives on `Transaction.updates` with a `revocationDate`. Entitlement
    drops at once, and stories lock the lapsed way, keeping progress.
- **Verification.** Only trust transactions that pass StoreKit's JWS check (`VerificationResult
  .verified`). An unverified result counts as not entitled, and the app never shows an error to
  the child.
- **Local testing.** A `.storekit` configuration file backs local runs and previews, and
  `StoreKitTest`'s `SKTestSession` covers renew, lapse, refund, grace and family-shared cases.

## 5. Android: Google Play Billing

The same rules on Play, with the official library `com.android.billingclient:billing-ktx` (the
current major version) and no server.

- **Connecting.** One `BillingClient` for the app, built with `enablePendingPurchases` and a
  `PurchasesUpdatedListener`, connected when the app starts and reconnected when the service
  disconnects. Billing lives in the `app` module; the rule for which stories are free lives in
  `core/content`, so it stays pure Kotlin and testable.
- **Entitlement.**
  - On start and on every return to the foreground, call `queryPurchasesAsync` for
    `ProductType.SUBS`. Play caches it on the device, so it works offline.
  - Plus is active when a purchase of `hop_tales_plus` has `purchaseState == PURCHASED`.
  - Purchases also arrive on the `PurchasesUpdatedListener` while the app runs; handle them the
    same way.
  - Like iOS, the app keeps no entitlement cache of its own. Play's is authoritative and survives
    reinstalls on the same Google account.
- **Acknowledgement.** Every new purchase with `isAcknowledged == false` is acknowledged with
  `acknowledgePurchase` as soon as it's seen, on the listener or at the next query. Play refunds a
  subscription that isn't acknowledged within three days, so the next launch retries any that
  failed.
- **Pending purchases.** A purchase in `PENDING` (a cash or slow payment method) is not Plus yet.
  The Grown-ups section says "Waiting for your payment to go through", and stories unlock once it
  turns `PURCHASED`, on the listener or the next query.
- **Verification.** With no server, the app checks the purchase signature against the app's Play
  public key from Play Console and treats anything that fails as not entitled, with no error shown
  to the child.
- **Grace period and account hold.** Turn on a grace period on both base plans in Play Console
  (14 days, the nearest to Apple's 16). During grace the purchase is still returned as
  `PURCHASED`, so the child notices nothing. In account hold it drops out of
  `queryPurchasesAsync`, and stories lock as for any lapse.
- **Restore.** Play has no restore call; a reinstall or a new device on the same Google account
  finds the purchase at the first query. The Grown-ups section still has Restore purchases, which
  runs the query again, so both apps offer the same buttons.
- **Manage subscription.** Open Play's subscription centre,
  `https://play.google.com/store/account/subscriptions?sku=hop_tales_plus&package=com.hoptales.android`,
  behind the gate. It's an outside link, so the gate guards it twice over.
- **Refunds.** Play has no in-app refund call. Request a refund opens Google Play's refund help
  page behind the gate. A refunded or revoked purchase drops out of `queryPurchasesAsync`, and
  stories lock the lapsed way, keeping progress.
- **Family sharing.** Play Family Library doesn't share in-app subscriptions today, so Plus
  belongs to the Google account that bought it. Check Play Console when setting up, and turn it on
  if Play has added it.
- **Families policy.** Hop Tales is in Play's Families programme, which asks for:
  - a parent gate before any purchase, and no purchase prompts aimed at children — the locked card
    has no price and the paywall is only behind the gate;
  - no ads or analytics SDKs (the billing library is Google's own and allowed);
  - Play Billing's in-app messaging (`showInAppMessages`) stays off, since it would draw a payment
    prompt in front of a child.
- **Testing.** License testers in Play Console buy with test cards and accelerated renewals.
  Unit tests use a fake entitlement source, as on iOS.

## 6. What we give up with no server

- **Store server notifications need an endpoint**, so they're out: App Store Server Notifications
  on iOS and Real-time developer notifications on Play. Each app learns about renewals, refunds
  and lapses at launch and while running, which is enough for entitlement.
- **Android can't tell grace from a normal renewal on the device.** The Play Developer API would,
  but it needs a server, so the Android Grown-ups section has no "problem with your payment" line.
  Play tells the purchaser itself, by email and in the Play Store.
- **Server-side receipt checks.** iOS has StoreKit's on-device JWS check; Android has the
  signature check against the Play public key, which is weaker but enough for a $4.99 plan.
- **Business numbers** (new subscriptions, conversion, churn) come from App Store Connect's
  subscription reports and Play Console's subscription dashboards, not from the app. Kids Category
  (guideline 1.3) and Play's Families policy forbid third-party analytics anyway.

## 7. Content rhythm

Plus is a promise of more, so it needs a rhythm parents can see:

- **A new story every month**, above Level 1, so it lands in Plus.
- **Something seasonal each season**: a new friend, a wardrobe set or a meadow mood. Wardrobe looks
  and moods are still earned by reading, never sold.

The rhythm is the reason to subscribe, so it's in three places: the line under the paywall title,
the Grown-ups Plus section ("A new story every month, and something new each season"), and the
store descriptions on both stores. It's also what App Store guideline 3.1.2 means by ongoing value.
Release notes name each month's story.

## 8. Privacy and review

- **Privacy label.** The App Privacy answers stay "Data Not Collected", and Play's Data safety
  form stays "No data collected". The stores handle the purchase, and the app sends nothing
  anywhere.
- **Privacy policy.** `Website/public/privacy.html` says "no purchases" and
  `docs/app-store-privacy.md` says "there are no links or purchases, so there is no gate". Both
  change to: purchases go through Apple or Google, behind a parent gate, and we receive nothing
  about the purchaser.
- **Store descriptions.** Drop "no in-app purchases" from the App Store description, add the free
  Level 1 stories, the two plans and the content rhythm, and write the Play
  description to match.
- **Terms of Use.** A subscription needs Terms of Use (Apple's standard licence agreement is fine
  on iOS; `Website/public/terms.html` covers Play) linked from the paywall and both store
  descriptions.
- **Review notes.** Tell the reviewers where the gate is, give them the times-table answer rule,
  and say that the Level 1 stories are free.

## 9. Strategy

**The library is the product.** There are 34 stories across seven levels, so a grown-up who
subscribes sees a real shelf on day one, and the content rhythm keeps it growing.

**Positioning.**
- "Every Level 1 story free, forever. Plus unlocks every story, with a new one every month, for
  the whole family."
- The promises we can actually keep are the moat: no ads, no data and no account.
- Lead with yearly, and show monthly as the flexible option.

**Levers after launch**, all store-provided and none needing a server:
- **Offer codes** (Apple) and **promo codes** (Play) for schools, reviewers and friends.
- **Win-back offers** for lapsed subscribers, for example the first month at $0.99, on both
  stores.
- **Price tests.** App Store Connect doesn't A/B test prices natively; product-page optimisation
  can test the paywall screenshots and copy instead. Play Console has price experiments.

**Measure** in App Store Connect and Play Console:
- new subscriptions, and the share of downloads that subscribe;
- the yearly-to-monthly split, to check that leading with yearly works;
- month-2 retention;
- the refund rate.
Revisit prices after 90 days of data.

## Build order

Each step is one issue and one pull request that lands on both apps (`Parity: both`). Until step
7 has the products live in both consoles, the gating rule stays switched off in release builds,
so a shipped build never locks a story nobody can buy yet.

1. **Entitlement and the Level 1 rule** — #345
   - Shared logic: `Story.isFree` (`level == 1`) and `isLocked(story, isPlus:)` in Swift
     `Content` and Kotlin `core/content`, with ported tests, plus the `PlusPlan` mapping from
     each store's IDs.
   - iOS: a `PurchasesClient` dependency exposing `isPlus` as a stream (`currentEntitlements`
     plus `updates`), with live, test and preview values.
   - Android: an entitlement source over `BillingClient` (`queryPurchasesAsync`, acknowledgement,
     pending), with a fake for tests and previews.
   - A release switch that keeps every story open until step 7: `Plus.locksStories` in
     `Content/Plus.swift` on iOS, `hoptales.plusLocksStories` in `android/gradle.properties` on
     Android. Both are `false`, and a test on each app fails if either is flipped by accident.
2. **The locked story card and the parent gate** — #346
   - The shared times-table gate on both apps, with snapshot and unit tests.
   - The padlock sticker on Home, and the locked card with the story's standing and Ask a
     grown-up.
   - Amend `docs/HANDOFF.md` rule 6, since the gate now exists.
3. **The paywall** — #347
   - iOS: `SubscriptionStoreView` behind the gate, with a `.storekit` file for local runs.
   - Android: the paper paywall sheet and `launchBillingFlow`.
   - Snapshots in light and dark on both apps.
4. **The Grown-ups Plus section** — #348
   - Status, Subscribe, Restore, Manage and Refund, all behind the gate; the payment-problem line
     on iOS and the pending line on Android; the content rhythm.
5. **The end-of-onboarding offer** — #349
   - The one-time paywall after the last onboarding step, behind the gate: both plans, yearly
     leading, and Try Level 1 free as the secondary.
6. **"You finished Level 1!"** — #355
   - The once-only journey moment at The end, with the Skip and trickier-words preview, Ask a
     grown-up (gate, then the paywall from step 3) and Keep reading; its flag on the reader's
     progress, and ported tests for when it appears.
7. **Store setup and copy** — #350
   - App Store Connect, done: the `hop_tales_plus` group with `com.hoptales.plus.monthly` ($4.99,
     1 month) and `com.hoptales.plus.yearly` ($29.99, 1 year upfront), Family Sharing on, no
     introductory offer.
   - App Store Connect, still to do: the group display name, the 16-day grace period, the Small
     Business Program, review notes, the review screenshot at submission and localised display
     names.
   - Play Console: a payments profile, `hop_tales_plus` with its two base plans and prices and no
     offer, the grace period, the licence key, license testers and the Families declarations.
   - Repo copy: `privacy.html`, `docs/app-store-privacy.md`, the website, and the store
     descriptions without "no in-app purchases". Then turn the release switch on (both
     settings above, and the two `everyStoryStaysOpenUntilTheStoresAreLive` tests), The Play public key is
     committed as the `hoptales.playPublicKey` Gradle property in `android/gradle.properties`; it is
     public, and without it no Play purchase verifies.
