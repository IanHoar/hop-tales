Replace the paper word card and the reading chrome with **words printed along the meadow path**. The hare sits on the path and hops from word to word. While a page is being read, the only control on screen is a small back chip.

**Design:** board A, "Words on the path · minimal interface", on the *Hop Tales — collage storybook* canvas.

**Reference renders** (untracked in the working tree; commit them with the PR):

- `Design/collage/reference/reading-path-minimal.jpg`: the chosen direction (A), an optional listening dot (B), and the end of a page (C).
- `Design/collage/reference/reading-path-explorations.jpg`: the first pass with the old chrome still on. It's useful for the word treatment and the dusk tint.

## Remove (phone and iPad)

- `ReadingTopBar`: the title label and the star chip. A back chip replaces it.
- The paper card: `WordCard` / `SentenceStrip`'s card background.
- `MicPill` ("Say the word").
- The progress dots.
- The per-word `StarChip` pop-ups. Keep counting stars in state; they're shown only at the end.
- Keep `DebugControls` and debug tap-to-advance.

## Words on the path

**Font and colours**

- Young Serif. The current word is 46 pt; all other words are scaled to 0.7.
- Current word: ink `#2E2018`.
- Read words: ink `#3B2A20`, with the gold wash below.
- Upcoming words: `rgba(59,42,32,0.42)`.
- Words use a multiply blend so the paper grain shows through.

**Lying on the ground**

- Apply `rotation3DEffect(.degrees(24), axis: (1, 0, 0), anchor: UnitPoint(x: 0.5, y: 0.6), perspective: ~0.5)`.
- Centre each word on the path line, nudged up by 58 % of its height.

**Read wash**

- A radial gradient: `#F7D774` at 95 % opacity, going to 70 % at 52 % of the radius and to 0 at 72 %.
- It overhangs the word by 14 pt on each side and uses multiply.
- It fades in over 0.35 s after a 0.25 s delay.

**Spacing:** centre to centre = half of word A's width + 64 pt + half of word B's width, with widths measured at 46 pt.

**Rendering:**

- The text stays in SwiftUI, per CLAUDE.md.
- The word layer must pan **1:1 with the near land layer**, so both need to be driven from one camera offset. For example, the SwiftUI layer publishes `cameraX` and `MeadowBackdrop`/`WorldView` takes it, instead of deriving the scroll from `worldProgress` on its own.

## Camera and land scale (reading only)

The reading screen uses a closer land scale than the intro, so the painted path is wide enough to carry words.

**Scales on the 390×844 reference phone:**

- Near: **0.74** (the intro uses 0.42).
- Mid: 0.5.
- Far: 0.42.
- Scale everything through `ReadingGeometry`.

**Layout on the reference phone:**

- Path centre: y 640. The path band is about 120 px of the 834 px near layer, so about 89 pt tall.
- Near top = path centre − 440 × 0.74 (≈ 314).
- Mid top = near top + 8.
- Far top = near top − 52.
- The sky gradient fills everything above the far layer.

**The camera follows the hare:**

- The hare's feet are at x 96, y path + 30.
- The current word's centre sits at x 236.

**When a word is heard:**

- The camera pans by the distance to the next word over 0.62 s, with `cubic-bezier(0.45, 0, 0.3, 1)`.
- Near and words move at 1×, mid at 0.6× and far at 0.3×.
- Meanwhile the hare plays the hop sheet in place (8 frames, 14 fps) with a 30 pt arc.
- Hare sizes: about 124 pt tall sitting and 116 pt hopping.

**After the last word:** the camera overshoots 200 pt past it, so the hare lands beyond it next to the end sign.

**Reduce Motion:** replace the pan and the hop with a 0.2 s crossfade to the next position.

## Signposts

- Asset: `Design/collage/soft/prop-signpost.png` (borderless). Draw it 172 pt tall, standing in the grass just behind the path, with its feet at path − 40.
- **Start sign:** at the first word + 80 pt.
  - It shows the story title in Fraunces 700 at 17 pt, ink, multiply, rotated −1.5°, with at most two lines.
  - Text box inside the sign: x 7, y 23, width w − 30, height 53.
  - This replaces the title label. It scrolls away with the first hop.
- **End sign:** at the last word + 270 pt. It says "The end" in Fraunces 700 at 21 pt.
- **Multi-sentence stories:** my suggestion is one continuous path, with a longer gap (about 140 pt) between sentences. The existing clear jump (#109) becomes a longer bound across that gap. Challenge this if paging per sentence reads better.

## Controls

- **Back chip:**
  - A 38 pt circle, paper `#FBF4E4` at 72 % opacity, with a 3 pt white rim and a soft shadow.
  - Position: top-left, 18 pt in, just below the safe area.
  - Contents: a 16 pt chevron.
  - It sends `backTapped`.
  - A press-and-hold grown-up lock is optional and could be a follow-up.
- **No mic button.** Listening runs whenever the page is visible.
- **Tapping the current word** reads it aloud (`currentWordTapped`, unchanged). Keep the hit target at least 44 pt.
- Keep the VoiceOver label and hint on the current word.

## End of story

- The hare passes the last word and reaches the end sign.
- Then two stickers appear at the bottom centre (y 752 on the reference phone):
  - **Read it again**, with a ↻ icon, in Fraunces 18.
  - The star total as **"★ +N"**, rotated 4°.
- This restyles `StoryFinished` and keeps its actions. "Back to stories" moves to the back chip.

## Not in this issue

- Board B's listening dot: a 42 pt sage mic dot with a gold ring that fills with progress. Only add it if testing shows kids need a listening cue.
- `TVReadingScreen`: the same treatment, with words about 2× size. Do it as a follow-up.

## Also update

- The CLAUDE.md ground rule "The word card, ball, mic pill and progress rail never move between stages". The words now live on the path; text still lives in SwiftUI.
- The Reading row in `docs/DESIGN-HANDOFF-V3.md` §2.
- Snapshots: replace `WordCardSnapshotTests` with path snapshots at the start, mid-page and end.

## Acceptance

- [ ] No top bar, card, mic pill, dots or star pop-ups while reading. The back chip is the only control.
- [ ] Words stay locked to the painted path through every hop, with no drift against the near layer.
- [ ] The hare hops in place while the ground slides one word; the far and mid layers parallax.
- [ ] The title shows on the start signpost and "The end" on the end signpost.
- [ ] The end of a story shows Read it again and the star total.
- [ ] Reduce Motion, VoiceOver and the iPad layout all work.
- [ ] `WordMatcherTests` stay green and the snapshots are updated.
