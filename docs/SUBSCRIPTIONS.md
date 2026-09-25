# Subscriptions — plan

The written plan for #27. Nothing here is built yet; each section under **Build order** becomes its
own issue. Product rules 5 and 6 in `docs/HANDOFF.md` §1 still hold: no data leaves the device, and a
parent gate guards anything that costs money.

## The shape in one paragraph

**Hop Tales Plus** is one auto-renewing subscription group with a monthly and a yearly plan. The
yearly plan has a 7-day free trial. **The Meadow Walk** is free forever, with no account and no
trial clock. Every other story, and every story added later, needs Plus. A child who reaches a
locked story sees an "ask a grown-up" card with no price and nothing to buy. Only a grown-up who
passes the parent gate ever sees the paywall. Progress and stars are never taken away. StoreKit 2
does all of it on the device, with no server of ours.

## 1. What is free and what is paid

| | Free | Plus |
|---|---|---|
| The Meadow Walk, read and re-read | ✓ | ✓ |
| Every other story, now and future | | ✓ |
| Speech, help, stars, moods, settings | ✓ | ✓ |
| Play on the TV (AirPlay) | ✓ | ✓ |
| iPad | ✓ | ✓ |

- **One free story, fixed as The Meadow Walk.** A free story that depends on the reading level
  picked in onboarding is the friendlier idea. But resetting onboarding would then hand out a
  different free story each time, and with four stories that is the whole library.
- **The TV isn't paywalled.** It's the feature that sells the app on the living-room floor, and
  it costs us nothing to give away.
- **No feature ever sits behind the paywall**, only stories. The reading loop is the same for
  everyone, so a free child never meets a lesser version of the game.

### Introductory offer

- A **7-day free trial on the yearly plan only**, introductory offer type *free trial*. A week
  covers a few bedtimes, which is enough to find out whether the child likes it.
- The monthly plan has no trial, so the paywall has an obvious default.
- StoreKit decides who is eligible (`Product.SubscriptionInfo.isEligibleForIntroOffer`), and the
  paywall only mentions the trial when the grown-up is eligible.

## 2. Products and prices

One subscription group, `hop_tales_plus`, so a grown-up can switch plans without double-paying.

| Reference name | Product ID | Type | Price (USD tier) | Trial |
|---|---|---|---|---|
| Plus Monthly | `com.hoptales.plus.monthly` | Auto-renewable, 1 month | $4.99 | — |
| Plus Yearly | `com.hoptales.plus.yearly` | Auto-renewable, 1 year | $29.99 | 7 days free |

- **Base storefront.** The account's primary language is English (Canada). Either Canada or the
  US works as the base price, and App Store Connect equalises the rest.
- **Why these prices.** The big children's reading subscriptions sit at about $10–13 a month (from
  memory, so check before launch). Hop Tales has a far smaller library, so it should look like
  an easy yes.
  - Yearly works out at $2.50 a month, half the monthly price, and is the plan the paywall leads
    with.
- **Revenue share.** Enrol in the App Store Small Business Program, which cuts Apple's commission
  from 30% to 15%. A subscription also drops to 15% after a subscriber's first year.
- **Maybe later: a lifetime unlock.** A non-consumable at about $59.99 suits parents who dislike
  subscriptions. Leave it out of v1 so there are only two choices. If it's added, it lives outside
  the subscription group, and entitlement is "any active Plus plan *or* lifetime".

### A lapsed subscriber keeps everything they earned

- Stars, per-story progress and finished sentences stay in `ProgressStore`, untouched.
- Plus stories go back to the locked card. The card still shows the story's standing ("You read 4
  of 6"), so resubscribing picks up exactly where the child left off.
- The Meadow Walk and all settings keep working.
- Nothing is ever deleted because a subscription ended.

## 3. The paywall and what a child sees

A child must never be able to act on a purchase prompt.

**The locked story card (child-facing).** A Plus story on Home shows a small paper padlock
sticker. Tapping it opens a card with the story's art and title, "This story is part of Hop Tales
Plus", and one button: **Ask a grown-up**. The card has no price, no trial wording and no buy
button.

**The parent gate.** Ask a grown-up opens the gate from rule 6:
- It's a times-table question in words ("What is seven times eight?") with a number pad.
- It's never a press-and-hold.
- A wrong answer draws a new question, with no lockout and no failure state for the child.
- The gate is one shared component. The paywall, Restore, Manage subscription and any future
  outside link all go through it.

**The paywall (grown-up-facing, behind the gate).** Use StoreKit's `SubscriptionStoreView` for the
`hop_tales_plus` group, styled as a paper sheet over the meadow:
- It shows the plans, the trial terms, auto-renewal wording, and links to Terms of Use and the
  Privacy Policy, which App Review requires for subscriptions.
- It includes Restore purchases (`.storeButton(.visible, for: .restorePurchases)`).
- Using Apple's view instead of a custom one keeps the required disclosures correct as the rules
  change.

**Where the paywall can be reached:**
1. The locked story card, then the gate.
2. **Grown-ups (settings)**, in a new "Hop Tales Plus" section:
   - The status, in plain words: "Plus, renews 3 March" or "Free".
   - Subscribe, Restore purchases, Manage subscription (`showManageSubscriptions`) and Request a
     refund (`beginRefundRequest`).
   - The rest of Settings still opens without the gate. Only this section's buttons ask first.
3. **The end of onboarding**, a soft offer:
   - After the microphone step, a card says "Start with The Meadow Walk", with a secondary "See
     Hop Tales Plus" that goes through the gate.
   - The free path is the big button.
   - Onboarding is filled in by a grown-up, so this is the one moment they're guaranteed to be
     holding the phone.

**Never:** a paywall mid-story, on launch, after the intro, or anywhere a child can reach it by
tapping. There are no countdowns and no "offer ends soon".

## 4. Restore, Family Sharing, refunds and grace periods

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
- **Family Sharing.** Turn it on for both subscriptions in App Store Connect. One grown-up
  subscribes and every child's device in the family has Plus.
  - Shared transactions arrive with `ownershipType == .familyShared` and count the same.
  - For a family app this is a selling point, so say so on the paywall and the website.
- **Billing grace period.** Turn on the 16-day grace period in App Store Connect.
  - During grace the subscription stays in `currentEntitlements`, so the child notices nothing.
  - The Grown-ups section shows "There's a problem with your payment" and a Manage subscription
    button.
  - After grace, Apple's billing retry runs with no access, and stories lock as for any lapse.
- **Refunds.**
  - Grown-ups can ask for one in the app with `beginRefundRequest`, behind the gate.
  - A refunded transaction arrives on `Transaction.updates` with a `revocationDate`. Entitlement
    drops at once, and stories lock the lapsed way, keeping progress.
- **Verification.** Only trust transactions that pass StoreKit's JWS check (`VerificationResult
  .verified`). An unverified result counts as not entitled, and the app never shows an error to
  the child.

### What we give up with no server

- **App Store Server Notifications need an endpoint**, so they're out. The app learns about
  renewals, refunds and lapses at launch and through `Transaction.updates`, which is enough for
  entitlement.
- **Business numbers** (trials started, conversion, churn) come from App Store Connect's
  subscription reports and App Analytics, not from the app. Kids Category rules (guideline 1.3)
  forbid third-party analytics anyway.

## 5. Privacy and review

- **Privacy label.** The App Privacy answers stay "Data Not Collected". Apple handles the
  purchase, and the app sends nothing anywhere.
- **Privacy policy.** Update `privacy.html` and `docs/app-store-privacy.md`: today both say "no
  purchases". Say that purchases go through Apple, behind a parent gate, and that we receive
  nothing about the purchaser.
- **Terms of Use.** A subscription needs Terms of Use (Apple's standard licence agreement is
  fine) linked from the paywall and the App Store description.
- **Guideline 3.1.2.** An auto-renewing subscription must give ongoing value. That means a steady
  supply of new stories; see Strategy below.
- **Review notes.** Tell the reviewer where the gate is, give them the times-table answer rule,
  and say that The Meadow Walk is the free story.

## 6. Strategy

**The library is the product.**
- With four stories, a monthly subscription is a hard sell, and App Review may ask what the
  ongoing value is. So a public content cadence has to come first: for example, **two new stories
  a month**, announced on the paywall ("New stories every month") and in the app's release notes.
- Aim for at least **12 stories at launch**. At the current six sentences each, that's about three
  weeks of reading, and the yearly plan's trial then shows off a real shelf.
- The build can be ready before then. Hold the paywall behind a build-time flag
  until the library is ready.

**Positioning.**
- "One story free, forever. Plus unlocks every story, and new ones every month, for the whole
  family."
- The promises we can actually keep are the moat: no ads, no data and no account.
- Lead with yearly, and show monthly as the flexible option.

**Levers after launch**, all Apple-provided and none needing a server:
- **Offer codes** for schools, reviewers and friends.
- **Win-back offers** (iOS 18) for lapsed subscribers, for example the first month at $0.99.
- A **promotional offer** in Grown-ups for a family who cancelled in a billing-retry window.
- **Price tests.** App Store Connect doesn't A/B test prices natively; product-page optimisation
  can test the paywall screenshots and copy instead.
- A lifetime unlock if reviews complain about the subscription.

**Measure** in App Store Connect:
- trial starts;
- trial-to-paid conversion, aiming for 35–50% for a family app with a real trial;
- month-2 retention;
- the refund rate.
Revisit prices after 90 days of data.

## Build order (future issues)

1. **Parent gate component.** A shared times-table gate in `DesignSystem`/`GrownUps`, with
   snapshot and unit tests. Useful on its own, since Settings links out eventually.
2. **Entitlement client.** A `Purchases` module with a `PurchasesClient` dependency:
   - It exposes `isPlus` as a stream from `currentEntitlements` plus `updates`, along with
     `products`, `purchase`, `restore`, `manage` and `refund`.
   - It has live, test and preview values.
   - A `.storekit` configuration file backs local runs, and `StoreKitTest`'s `SKTestSession`
     covers renew, lapse, refund, grace and family-shared cases.
3. **Locked stories.** `Story.isFree`, true only for The Meadow Walk. Home shows the padlock
   sticker, and the locked card appears with Ask a grown-up. Progress is untouched on lapse.
4. **The paywall.** `SubscriptionStoreView` behind the gate, the paper styling, and snapshots in
   light and dark.
5. **Grown-ups section.** Status, Subscribe, Restore, Manage and Refund, with the billing-problem
   state.
6. **Onboarding soft offer.** A last card with the free path first.
7. **App Store Connect setup (manual).**
   - The subscription group and products.
   - Family Sharing, the 16-day grace period and the yearly trial.
   - Enrol in the Small Business Program.
   - Terms of Use, review notes and localised display names.
8. **Privacy and site copy.** `privacy.html`, `docs/app-store-privacy.md`, and the website's
   pricing line.
9. **Launch switch.** A build-time flag that shows the paywall once the library reaches its
   launch size.

## Decisions for Ian

- Prices: $4.99 monthly and $29.99 yearly, or a different anchor?
- Trial: 7 days on yearly only, or on both plans, or 14 days?
- Is The Meadow Walk the free story, or should it be a story written to be the free one?
- The launch library size and content cadence: are 12 stories and two a month realistic?
- Lifetime unlock in v1 or later?
