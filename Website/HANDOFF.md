# Hop Tales marketing site: build handoff

> **Visual update:** the site is now in the collage storybook style. Match `reference/collage-desktop-1440.jpg` and `reference/collage-mobile-390.jpg`, and use the tokens and fonts in `docs/DESIGN-HANDOFF-V3.md` §1 and §7 (these override §2 here). Structure, links, privacy/terms and the PR plan below are unchanged.

A one-page marketing site for hoptales.com, plus Privacy and Terms pages. Issue #44 tracks the privacy policy URL, which App Store submission needs.

- **Design:** the "Marketing site" page of the Hop Tales design canvas. It has two artboards, Desktop 1440 and Mobile 390.
- **Pixel reference:** `reference/desktop-1440.jpg` and `reference/mobile-390.jpg` are full-page renders.
- **Markup reference:** `reference/desktop.html` and `reference/mobile.html` are the generated artboards. Open them in a browser: fonts and assets resolve from `public/assets/`. Every element in them is absolutely positioned, so **don't copy the layout**. Lift the SVG markup (wordmark, ribbon, ball, word pills, mic pill, feature icons) and the exact colours from them.
- **Art direction:** `docs/ART-DIRECTION.md` covers the Ink & Ember rules, and they apply here too.

## Kick-off prompt for Claude Code

> Read `Website/HANDOFF.md` and look at `Website/reference/desktop-1440.jpg` and `mobile-390.jpg`. Build the site in `Website/public/` as static HTML + CSS (no framework, no build step, no JS unless the spec asks for it). Work through the PR plan at the bottom in order, and stop after each PR for review. Match the reference renders at 1440 and 390, and make every width in between work.

## 1. Stack and structure

```
Website/
  HANDOFF.md
  reference/               design renders + generated markup (not deployed)
  public/                  the deployable site root
    index.html
    privacy.html
    terms.html
    styles.css
    assets/
      fonts/               LilitaOne, Fredoka 500/600, Andika 700 (TTF; ship WOFF2 subsets)
      world/               sky/far/mid/near × day/dusk SVGs, 2340 × 844 each
      sprites/             fox.svg, fox-trot-0.svg, dragon.svg
      shots/               app screenshots, 2x (phones 780 × 1688, TV 3840 × 2160)
      icon.png             1254² app icon → favicon, apple-touch-icon, OG
```

- Plain HTML and one stylesheet. Page structure uses semantic landmarks (`header`, `main`, `section`, `footer`).
- Host it on any static host pointed at `Website/public`. GitHub Pages or Cloudflare Pages both work; the choice is open.
- The site uses Vercel Web Analytics (`/_vercel/insights/script.js`, enabled per project in Vercel): cookie-free, first-party page-view counts. There are no cookies, ads or other third-party scripts. The Privacy Policy and Terms cover the app only, not the website.
- Self-host the fonts. Don't use Google Fonts, because that would send visitor IPs to a third party.

## 2. Tokens

```css
:root {
  --ink: #1D1A2C;
  --parch: #FFF6E2;        /* cards, cream text on dark */
  --parch-lip: #EBD5A6;    /* bevel inner lip, dashed divider */
  --card-2: #FFFBF1;       /* feature cards */
  --page: #F7E9C8;         /* page background */
  --deep: #0E3D46;         /* stories band */
  --night: #1B1738;        /* CTA band fallback */
  --body: #3A3548;         /* long-form body text on parchment */
  --muted: #6E6780;
  --on-deep: #A9D6D4;      /* body text on --deep */
  --on-night: #E6DEF5;     /* body text in CTA */
  --footer-meta: #B9B2C8;
  --red: #DB2A2E;  --red-d: #A3141D;  --red-h: #FF6A55;
  --gold: #F6BB3E; --gold-d: #C7861A; --gold-h: #FFE39A;
  --teal: #1E8C8C;
  --art-panel: #CFE8EE;    /* step-card illustration panel */
}
```

**Type**

| Role | Face | Desktop | Mobile |
|---|---|---|---|
| H1 hero | Lilita One, cream, 11 px ink stroke | 72 / 1.02 | 46, 8 px stroke |
| H2 section | Lilita One | 56 (How, Stories) · 52 (TV, Grown-ups) | 36–38 |
| H2 CTA | Lilita One, cream, 10 px ink stroke | 68 | 42, 8 px stroke |
| Card title | Lilita One | 28 (steps) · 24 (features) | same |
| Body lead | Fredoka 500 | 20 / 1.5 | 17 |
| Body | Fredoka 500 | 16–19 / 1.5 | 16–17 |
| Nav links | Fredoka 600 | 18 | — |
| Reading words in art | Andika 700 | — | — |

Letter-spacing on Lilita is 0.01em. For outlined headings, use `-webkit-text-stroke: Npx var(--ink); paint-order: stroke fill;`. With paint-order set, the stroke sits behind the fill, so the visible outline is half the stroke value. Check it in Safari and Firefox.

**Bevel**, the one surface recipe used for every card and button:

```css
.bevel {
  background: var(--parch);
  border: 3px solid var(--ink);            /* 4px on large cards */
  border-radius: 30px;
  box-shadow:
    inset 0 calc(-1 * (var(--drop) + 2px)) 0 var(--parch-lip),
    inset 0 3px 0 rgba(255,255,255,.85),
    0 var(--drop) 0 var(--ink);
  --drop: 6px;                             /* 5px on feature cards */
}
```

**Phone frame:** screenshot `<img>` inside an ink border of `max(6px, width/42)`, radius `14%` of width, `box-shadow: 0 (border+4px) 0 var(--ink), 0 40px 60px rgba(12,10,30,.35)`, rotated per section.

## 3. Sections (desktop 1440; content inset 64 px nav / 100 px sections)

**Nav** (over the hero, top 26): wordmark SVG 198 × 51 on the left. On the right: How it works (`#how`), For parents (`#parents`), Privacy (`privacy.html`), Terms (`terms.html`), and the App Store badge at 50 px tall. Gap 30.

**Hero** (880 tall, bottom border 5 px ink)
- Background: `sky-day`, `far-day`, `mid-day` and `near-day` stacked at 1.04 scale, all anchored top-left (2434 × 878). The ground line sits at y ≈ 466. Past 2434 px wide, extend with the sky's top colour and the grass colour.
- Pip (`fox.svg`) stands on the path at x ≈ 560, feet on the ground line.
- Left column (x 64, top 124, width 720): red ribbon "A READ-ALOUD ADVENTURE" (300 × 44, Lilita 16). 22 px gap, then the H1 "Read a word.<br>Watch the world grow." (two lines at 72).
- Intro card (x 64, top 548, width 560): bevel with radius 30, border 4, drop 6, padding 26/30/30.
  - Copy: "Hop Tales listens while your child reads aloud. Every word they say bounces the ball forward — and carries Pip the fox from a sunny meadow to a dragon's hill."
  - Below it, a row: the App Store badge (64 tall) and two lines in muted 15: "iPhone & iPad / Plays on your TV with AirPlay".
- Phones: `inkheard` 320 wide, rotated −4°, at (840, 120), in front. `inkdragon` 290 wide, rotated 7°, at (1052, 150), behind.

**How it works** (`#how`, `--page`, 700 tall)
- H2 centred, with the sub "Three beats, over and over, until the story is done." in muted 20.
- Three cards, 400 wide, spread across 1240. Each card: bevel, padding 26/28/30, gap 14. Card contents, top to bottom:
  - A 120-tall art panel: `--art-panel`, 3 px ink border, radius 20, art bottom-aligned.
  - A gold number disc (40, border 3, drop `0 3px 0 ink`, Lilita 22) next to the title.
  - Body text, 17 `--body`.
- Card copy:
  1. **Say the word.** "A big word sits on the card. Your child reads it out loud and Hop Tales listens, right on the device." Art: the mic pill ("Say the word", teal mic disc, level bars).
  2. **The ball hops.** "Heard it! The ball bounces to the next word, and the last one tucks into a gold pill." Art: a gold "cat" pill, the orange ball raised 46 px, then "sat" in Andika 52.
  3. **The world grows.** "Every word walks Pip the fox a little further, from a sunny meadow to the castle road to dragon's hill." Art: `fox-trot-0.svg` at 190 × 135, bleeding off the bottom edge.

**Stories** (`--deep`, 980 tall)
- H2 "Three stories. One big adventure." in cream, with no stroke.
- Sub in `--on-deep` 20: "The world changes as they read — morning sun, golden hour, then torches and a dragon at dusk."
- Three phones, 270 wide, rotated −3 / 0 / 3, across 1060. Each has a caption: Lilita 28 cream title, then 16 `--on-deep`.
  - `inkmeadow`: "Meadow Morning / Short words to start"
  - `inkcastle`: "The Castle Road / Meet Sir Pennant"
  - `inkdragon`: "Dragon's Hill / Longer words, bigger world"

**Big screen** (`--page`, 640 tall)
- Text column (x 100, width 440): H2 "Play it on the big screen" and body 19. Copy: "AirPlay Hop Tales to your Apple TV. The phone stays in your child's hands and does the listening, while the TV shows the whole world — castle, knight and dragon in one wide view."
- TV: `inktv.jpg` at 720 × 405 inside a 10 px ink border with radius 26 and `box-shadow: 0 14px 0 ink, 0 40px 60px rgba(12,10,30,.3)`. Below it an ink stand: an 80 × 28 neck and a 200 × 12 rounded base.

**For grown-ups** (`#parents`, `--page`, 3 px dashed `--parch-lip` top border)
- H2 centred. A 2 × 2 grid, 1120 wide, gap 24.
- Feature card: `--card-2` bevel with radius 26, drop 5, padding 24. It holds an icon tile (58², radius 18, border 3, drop `0 3px 0 ink`) and a text block (Lilita 24 title, body 16).

| Icon tile bg | Title | Copy |
|---|---|---|
| `--teal`, lock | Private by design | Speech is recognised on the device. No audio is recorded or stored, and nothing is sent anywhere. |
| `--gold-h`, "ag" in Andika | Made for new readers | Words are set in Andika, a typeface built for literacy, with the same a and g shapes kids learn to write. |
| `#FFD2C8`, heart | Never a wrong answer | Listening is forgiving. If a word gets stuck, Hop Tales reads it aloud — no buzzers, no timers. |
| `#E4DCF6`, no-sign | No ads, no sign-ups | Nothing to click away to and no account to make. Open it, pick a story, start reading. |

**CTA** (560 tall, clipped, `--night` fallback)
- Background: dusk layers at 1.0 scale, shifted up 190 px. Horizontal offsets: sky 0, far −240, mid −480, near −800. This puts the castle on the left, the old keep in the middle, and torches at x ≈ 1200 and ≈ 1450.
- Overlay: `linear-gradient(90deg, rgba(14,12,42,.72) 0%, rgba(14,12,42,.35) 45%, transparent 70%)`.
- Ember (`dragon.svg`, 420 × 368) at (960, 170), `filter: brightness(.92)`.
- Text (x 100, top 150, width 640): H2 "Ready for the dragon?", then `--on-night` 20 "Download Hop Tales and read the first story together tonight.", then the App Store badge at 70 tall.

**Footer** (`--ink`, 150 tall, padding 0 100)
- Wordmark at 30 on the left.
- On the right: Privacy Policy, Terms of Service, and Download (App Store link), in Fredoka 600 17 cream, underlined with a 4 px offset. Then "© 2026 Hop Tales" in 15 `--footer-meta`.

## 4. Responsive

Match the reference at 1440 and 390, and make the layout fluid everywhere between.

| Width | Behaviour |
|---|---|
| ≥ 1100 | Desktop layout as above, content max-width 1240 centred. The hero art scales from the left edge; the phones stay right-aligned. |
| 700–1099 | Hero: the text column and intro card go full width, and the two phones sit below them at 60 % size. How-it-works and grown-ups cards go to 1 column at 640 max, or 2 up where they fit. The TV section stacks. |
| < 700 | The mobile artboard, padding 20. |

Mobile artboard specifics:
- **Nav:** wordmark 28, plus a small ink "Get it" pill linking to the App Store. There are no text links in the mobile nav; the footer carries Privacy and Terms.
- **Hero:** 760 tall. `day` scene at 0.9 scale, shifted up 27. Layer x offsets: far −49, mid −97, near −162. Ribbon 250 × 40, H1 46. Two phones overlap at 200 wide (−4°) and 170 wide (6°).
- **Intro card:** overlaps the hero bottom by 60 px and contains a full-width App Store badge.
- **How it works:** one column of cards.
- **Stories:** three phones fanned (150 / 160 / 150 wide, −8° / 0 / 8°) with the castle one in front. The caption line reads "Meadow · Castle Road · Dragon's Hill / Morning sun to torches at dusk."
- **TV section and features:** stacked.
- **CTA:** 520 tall, dusk scene at 0.9 scale, shifted up 120. Layer x offsets: far −502, mid −1004, near −1674. The dragon is 300 wide, bottom-centre, with the heading and badge above.
- **Footer:** stacked, with links wrapping.

## 5. App Store badge and links

- Use **Apple's official "Download on the App Store" badge** (black SVG) from Apple's marketing guidelines, at the heights above. The custom ink button in the design is only a stand-in, because Apple's guidelines don't allow a custom version of the badge.
- `APP_STORE_URL = https://apps.apple.com/app/id<APP_ID>`. Keep it in one place, since it's used in the nav, hero, CTA, footer and mobile "Get it" pill.
- Add a Smart App Banner: `<meta name="apple-itunes-app" content="app-id=<APP_ID>">`.
- The `<APP_ID>` comes from App Store Connect. Leave a single obvious TODO until then.

## 6. Privacy and Terms pages

Both pages share the site's nav, footer and `--page` background. The body is a single parchment bevel card, 760 max width, with Fredoka 18 / 1.6 body and Lilita headings.

**privacy.html.** Source of truth is `docs/app-store-privacy.md`. Cover:
- The app collects no data. Speech recognition runs on the device with `requiresOnDeviceRecognition`. Audio is never stored or sent.
- The child's name, settings and progress stay on the device, and deleting the app deletes them.
- There are no accounts, analytics, advertising, tracking or third-party SDKs.
- Microphone and speech-recognition permissions, and why the app asks for them.
- Children's privacy: Kids Category, Ages 6–8. Say plainly that no personal information is collected from children.
- A contact email, and a "Last updated" date.

**terms.html.** Short and plain:
- Licence to use the app.
- The content (stories and art) belongs to Hop Tales.
- No warranty, and limitation of liability.
- Apple's standard EULA applies to App Store purchases. Link it.
- Governing law is British Columbia, Canada.
- Contact email and "Last updated" date.

Both pages are drafts for the owner to review. They are not legal advice. Put a visible `TODO: review` comment at the top of each until it's signed off.

## 7. Meta, accessibility, performance

- **Head:**
  - `<title>`: "Hop Tales — a read-aloud adventure for new readers".
  - Meta description: the hero intro line.
  - `theme-color` `#1D1A2C`.
  - Favicon and apple-touch-icon made from `icon.png`.
  - OG/Twitter image: a 1200 × 630 crop of the hero (make it from the reference render or a headless screenshot), saved as `assets/og.jpg`.
- **Accessibility:**
  - One `h1`, then an `h2` per section.
  - Decorative art gets `alt=""`. Screenshots get short alts ("Hop Tales reading screen: the word 'sat' just heard").
  - The wordmark SVG gets `role="img" aria-label="Hop Tales"`.
  - Focus rings: 3 px gold outline with a 3 px offset.
  - Cream-on-sky headings rely on the ink stroke for contrast, so never remove it.
  - Tap targets are at least 44 px.
- **Motion** (optional, last): a gentle parallax on the hero layers on scroll (far 0.3, mid 0.6, near 1.0, like the game), and a 2-second ball bob in step 2. Everything sits behind `prefers-reduced-motion: no-preference`. Make it CSS-only if possible.
- **Performance:**
  - Convert the screenshots to AVIF/WebP with 1x/2x `srcset`, and keep JPEG as a fallback. Lazy-load everything below the hero.
  - Fonts: subset to Latin and convert to WOFF2. Preload Lilita One and Fredoka 500. Use `font-display: swap`.
  - SVG world layers total ≈ 200 KB for day. Inline nothing; let them cache.
  - Target: Lighthouse ≥ 95 on all four categories, with no layout shift from fonts or images (set width/height on every `img`).

## 8. PR plan

1. **Scaffold:** folder structure, `styles.css` tokens and bevel utility, `@font-face`, and the favicon/meta skeleton. Plus an empty `index.html` with the nav and footer.
2. **Hero:** layered world background, Pip, headline, intro card, phones, and the official badge.
3. **How it works + Stories**
4. **Big screen + For grown-ups + CTA**
5. **Responsive pass:** tablet and mobile per §4, checked at 390, 768, 1024, 1440 and 1920.
6. **Privacy + Terms** pages (drafts, flagged for review).
7. **Polish:** OG image, image formats and srcset, reduced-motion-safe parallax, and a Lighthouse pass.
8. **Deploy:** static host pointed at `Website/public`, with the custom domain `hoptales.com`. Add the privacy URL to App Store Connect and close #44.

## 9. Open items

- The App Store ID. The page ships with a TODO until it exists.
- The contact email for the privacy and terms pages.
- Whether to show pricing on the page, if the app will be paid.
- Hosting provider and DNS for hoptales.com.
