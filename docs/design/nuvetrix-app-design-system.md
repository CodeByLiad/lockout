# Nuvetrix App Design System

Version 1.1, October 6, 2026. Reference app: **WishPlay**.

Every Nuvetrix Android app follows this file. It defines the look, feel, components and copy rules that make our apps feel like one family, while each app keeps its own accent color and icon. When this file and an app's own design notes disagree, this file wins unless the app's notes say why.

For AI coding agents: read this file before building or changing any UI. Use the tokens and components here instead of inventing new ones. If something you need is missing, add it here first, then use it.

---

## 1. Principles

1. **Works for the user, not on them.** No dark patterns, no nagging, no fake urgency. Upgrades are offered, never forced. Nothing tracks the user.
2. **Expressive, not noisy.** We use Material 3 Expressive: bold type, playful shapes, springy motion. Each screen gets one bold moment (a hero card, a big number). Everything around it stays calm.
3. **Honest states.** Missing data says so plainly ("To be announced", "Will be shared later"). Never show fake numbers or placeholder text to users.
4. **Offline first.** Screens render from local data instantly. Loading states are for the network, not for the app's own data.
5. **One job per screen.** If a screen needs a paragraph to explain itself, split it.

---

## 2. Foundation

- **Framework:** Jetpack Compose with Material 3 Expressive components (`androidx.compose.material3`, expressive APIs where available).
- **Dynamic color:** off. Our apps use their own brand colors so they stay recognizable. Do not use `dynamicLightColorScheme` / `dynamicDarkColorScheme`.
- **Themes:** Light, Dark, and System (default: System). Every screen must work in both.
- **Edge-to-edge:** always. Handle system bar insets with `WindowInsets`; never hard-code status bar heights.
- **Minimum Android:** 8.0 (API 26), target the latest API level.

---

## 3. Color

Every app shares the same neutral palette (ink and cool lavender surfaces). Each app picks **one accent color**, which fills the `primaryContainer` role and becomes `primary` in dark mode.

### 3.1 Shared neutrals and roles: light theme

| Role | Hex | Used for |
| --- | --- | --- |
| `surface` | `#FBF9FF` | Screen background |
| `surfaceContainer` | `#F1EEF8` | List items, cards, nav bar, sheets |
| `surfaceContainerHigh` | `#E8E4F2` | Pressed list items, search field, inactive segments |
| `surfaceContainerHighest` | `#DDD8EC` | Deepest containers |
| `onSurface` | `#16132E` | Main text and icons (Nuvetrix ink) |
| `onSurfaceVariant` | `#4A4663` | Secondary text |
| `outline` | `#77728F` | Field borders, switch outline |
| `outlineVariant` | `#CAC5DA` | Dividers, chip borders, dashed "TBA" borders |
| `primary` | `#2E2766` | Filled buttons, selected segments, active switches |
| `onPrimary` | `#FFFFFF` | Text on `primary` |
| `primaryContainer` | **App accent** | Hero cards, FAB, Pro badges, "soon" badges |
| `onPrimaryContainer` | **App accent ink** | Text on the accent |
| `secondaryContainer` | `#E4DFFF` | Tonal buttons, selected chips, nav indicator |
| `onSecondaryContainer` | `#231A5C` | Text on `secondaryContainer` |
| `tertiary` | `#5B3FE0` | Focus rings, "changed" tags |
| `tertiaryContainer` | `#E6DEFF` | Info tags (e.g. "Moved to Dec 3", "Custom") |
| `onTertiaryContainer` | `#21105E` | Text on `tertiaryContainer` |
| `error` | `#B3261E` | Destructive actions, error text |
| `errorContainer` / `onErrorContainer` | `#F9DEDC` / `#410E0B` | Error banners |
| `success` (custom) | `#1E6E47` | "Out now", "Approved" text |
| `successContainer` (custom) | `#CDEFD9` | Success badges |
| `scrim` | `#16132E` at 48% | Behind sheets and menus |

### 3.2 Shared neutrals and roles: dark theme

| Role | Hex |
| --- | --- |
| `surface` | `#131124` |
| `surfaceContainer` | `#1C1A33` |
| `surfaceContainerHigh` | `#25223F` |
| `surfaceContainerHighest` | `#302D4C` |
| `onSurface` | `#EDEAF7` |
| `onSurfaceVariant` | `#C3BED7` |
| `outline` | `#938EAB` |
| `outlineVariant` | `#46425F` |
| `primary` | **App accent** (same as light `primaryContainer`) |
| `onPrimary` | **App accent ink** |
| `primaryContainer` / `onPrimaryContainer` | **App accent** / **App accent ink** |
| `secondaryContainer` / `onSecondaryContainer` | `#342D6B` / `#E4DFFF` |
| `tertiary` | `#B9A8FF` |
| `tertiaryContainer` / `onTertiaryContainer` | `#3C2C8F` / `#E6DEFF` |
| `error` | `#F2B8B5` |
| `errorContainer` / `onErrorContainer` | `#601410` / `#F9DEDC` |
| `success` / `successContainer` | `#7ED3A4` / `#0F3D27` |
| `scrim` | `#000000` at 60% |

### 3.3 App accents

| App | Accent | Accent ink |
| --- | --- | --- |
| WishPlay | `#FFB938` Star gold | `#2B1C00` |
| Lockout | `#C2EE7B` Rep lime | `#1F2E00` |
| *(next app)* | *pick using the rules below* | |

**Rules for choosing a new app's accent**

- Bright and light enough that dark ink text on it passes 4.5:1 contrast (aim for lightness around 75–85%).
- Clearly different in hue from every existing Nuvetrix app accent, so icons don't blur together on a home screen.
- Not Google Play green, and not the Nuvetrix company ultramarine `#2E2BDB` (reserved for the company brand).
- The accent ink is a very dark shade of the accent's own hue, not pure black.

### 3.4 Optional Pro accent themes

Apps with a Pro tier may offer extra accents. They replace only the accent pair; neutrals stay the same.

| Name | Accent | Accent ink |
| --- | --- | --- |
| Violet | `#B9A8FF` | `#21105E` |
| Teal | `#6ED6C4` | `#00382F` |
| Coral | `#FF9E8A` | `#4A0E00` |

### 3.5 Color rules

- The accent is for emphasis. Use it on at most two or three elements per screen (for example the hero card, the FAB and one badge).
- Never put white text on the accent.
- Never use gradients or glow effects. Flat fills only.
- Game covers, user images and the app icon are the only places other colors appear.
- Colors that must be told apart also differ in lightness, not only hue.

---

## 4. Typography

Two families, bundled in the APK under `res/font` (not downloaded at runtime, so they work offline and need no Google Play services):

- **Bricolage Grotesque** (display): screen titles, headlines, big numbers, the wordmark. Weights 500, 700, 800.
- **Figtree** (body): everything else. Weights 400, 500, 600, 700.

Both are free under the SIL Open Font License.

Apps that show numbers in columns — tables of sets, reps, weights, prices or scores — may bundle a
third family for those columns only:

- **JetBrains Mono** (numeric, optional): weights 400 and 700. Use it only where figures must line
  up vertically. Everything else, including single numbers and the `countdown` style, stays Figtree
  or Bricolage. Also free under the SIL Open Font License.

Proportional figures drift out of alignment as digit widths change, which makes a column of weights
hard to compare at a glance. A monospaced face fixes the column without affecting any other text.

### 4.1 Type scale

| Style | Font | Weight | Size / line height (sp) | Letter spacing | Used for |
| --- | --- | --- | --- | --- | --- |
| `displayLarge` | Bricolage | 800 | 44 / 46 | -0.03em | Welcome headline |
| `displayMedium` | Bricolage | 800 | 36 / 38 | -0.03em | Tab titles ("My wishlist") |
| `headlineLarge` | Bricolage | 800 | 28 / 31 | -0.025em | Details page title, sheet titles |
| `headlineMedium` | Bricolage | 700 | 22 / 26 | -0.02em | Card titles |
| `titleLarge` | Bricolage | 700 | 19 / 23 | -0.01em | Section headings |
| `titleMedium` | Figtree | 700 | 16 / 22 | 0 | List item titles |
| `titleSmall` | Figtree | 600 | 14 / 20 | 0 | Field labels |
| `bodyLarge` | Figtree | 400 | 17 / 25 | 0 | Intro paragraphs |
| `bodyMedium` | Figtree | 400 | 15 / 22 | 0 | Default body text |
| `bodySmall` | Figtree | 400 | 13 / 18 | 0 | Supporting text in lists |
| `labelLarge` | Figtree | 600 | 15 / 20 | 0 | Buttons |
| `labelMedium` | Figtree | 700 | 13 / 18 | 0 | Chips, badges |
| `labelSmall` | Figtree | 600 | 12 / 16 | 0 | Nav bar labels |
| `countdown` (custom) | Bricolage | 800 | 88 / 72 | -0.05em | The one big number on a hero card |
| `numericTable` (custom, optional) | JetBrains Mono | 500 | 15 / 22 | 0 | Numerals in columns (sets, reps, weights) |

### 4.2 Type rules

- Sentence case everywhere. No all-caps labels.
- Don't highlight a single word in a headline with a different color or weight.
- The wordmark splits weights: app name's first word in 800, second in 500 (e.g. **Wish**Play).
- Support system font scaling up to 200%. Text wraps; it never gets cut off.
- Line length for paragraphs: under about 40 characters per line on phones is fine; don't force full-width walls of text on tablets (cap width at 640 dp).

---

## 5. Shape

Material 3 Expressive uses shape as a signal. Corners change when something is pressed or selected.

### 5.1 Corner scale

| Token | Radius | Used for |
| --- | --- | --- |
| `extraSmall` | 8 dp | Inner corners of grouped list items, small tags |
| `small` | 12 dp | Chips (unselected), badges, pressed buttons |
| `medium` | 16 dp | Text fields, icon tiles, add buttons |
| `large` | 24–28 dp | Cards, empty states, outer list corners |
| `extraLarge` | 32–36 dp | Hero cards, bottom sheets (top corners), dialogs |
| `full` | 50% | Buttons, selected chips, nav indicator, avatars |

### 5.2 Shape behaviors

- **Press morph:** buttons are pill-shaped at rest and morph to 12 dp corners (16 dp for large buttons) while pressed, with a slight scale to 97%.
- **Selection morph:** chips go from 12 dp corners to a full pill when selected. Segmented buttons: inner segments 8 dp, outer ends 22 dp, the selected segment becomes a full pill.
- **Grouped lists:** items sit 3 dp apart in one group. First item has 26 dp top corners, last item 26 dp bottom corners, everything else 8 dp. A pressed item rounds to 20 dp.
- **Hero cards** use asymmetric corners: 36 dp on three corners, 12 dp on the bottom-left. This is the signature Nuvetrix card shape.

### 5.3 Expressive shapes

Use the Material 3 Expressive shape library (`MaterialShapes`, built on `androidx.graphics.shapes`) for decorative and identity elements only:

| Shape | Used for |
| --- | --- |
| 9-sided cookie | User avatars, Pro badge, play button on trailers |
| 12-sided cookie | Profile avatar (large) |
| 4-sided cookie, 6-sided cookie, circle, rounded square | Placeholder logos for items without an image, rotating through the set |

Never clip real content (covers, screenshots, text containers) into cookie shapes.

---

## 6. Motion

Motion answers the user's action. Nothing moves on its own except the wavy progress indicator.

| Kind | Spec | Used for |
| --- | --- | --- |
| Spatial, fast | `spring(dampingRatio = 0.6f, stiffness = 800f)` | Press morphs, switch thumb, chip selection |
| Spatial, default | `spring(dampingRatio = 0.7f, stiffness = Spring.StiffnessMediumLow)` | Screen transitions, sheets, FAB menu, card expand |
| Effects | `tween(200)`, no bounce | Color, opacity, fades |

- **Screen transitions:** forward slides in 28 dp from the right with a fade; back slides from the left.
- **Bottom sheets** rise 40 dp with the default spring.
- **FAB menu** items rise and scale in with a 50 ms stagger; the FAB's plus icon rotates 45° into an ×.
- **Wavy progress:** the only ambient motion; the wave drifts slowly.
- **Reduced motion:** when the system "Remove animations" setting is on, replace springs with instant changes and stop the wave.

---

## 7. Layout and spacing

- 4 dp base grid; most spacing is a multiple of 8.
- Screen side margins: 20 dp for text and headings, 16 dp for grouped lists and cards.
- Space between sections: 28 dp. Between a heading and its content: 12 dp.
- Touch targets: at least 48 × 48 dp.
- Content width on tablets and foldables: max 640 dp, centered.
- Scrollable screens leave 128 dp of bottom padding when a nav bar and FAB are present, so the last item is never hidden.

### 7.1 App structure

- **Bottom navigation bar**, 3 to 4 tabs max, each with an icon and a label. Active tab: `secondaryContainer` pill indicator (64 × 32 dp).
- **Tab screens** start with a large title (`displayMedium`) instead of a top app bar.
- **Pushed screens** (details, forms, Pro) use a simple top bar: back button left, optional title, optional actions right.
- **One FAB** at most, only on the main tab, bottom-right above the nav bar. If it offers more than one action, it opens a FAB menu.

---

## 8. Components

Build these once in a shared `designsystem` module and reuse them. Names below are the Compose component names to use.

### Buttons

| Component | Height | Style | Use |
| --- | --- | --- | --- |
| `NvButton.Filled` | 48 dp | `primary` fill | Main action on a screen |
| `NvButton.Accent` | 48 or 60 dp | Accent fill | The hero action (Save, Get Pro, Add to wishlist) |
| `NvButton.Tonal` | 48 dp | `secondaryContainer` | Secondary actions |
| `NvButton.Outlined` | 48 dp | 1 dp `outline` border | Neutral alternatives (Reject, Cancel) |
| `NvButton.Text` | 48 dp | No fill, `primary` text | Low-emphasis (Not now, Redeem a code) |
| `NvButton.Danger` | 48 dp | `outlineVariant` border, `error` text | Remove, Delete |
| `NvIconButton` | 48 dp | Pill; pressed 14 dp corners | Back, bell, clear |

Rules: one filled or accent button per screen. Icons sit left of the label at 20 dp. Button labels are verbs that say exactly what happens.

### Chips and selection

- **Filter chips:** 38 dp tall, 1 dp `outlineVariant` border. Selected: `secondaryContainer` fill, check icon, full pill. Horizontal rows scroll; no wrapping in filter bars.
- **Segmented button group:** for 2–4 mutually exclusive options (Minimum / Recommended, Light / Dark / System). See 5.2.

### Lists

- **Grouped list item:** min 72–76 dp tall, `surfaceContainer` fill, 16 dp padding, leading image (52 dp) or icon tile (40 dp, 14 dp corners), title (`titleMedium`), supporting text (`bodySmall`), optional trailing badge or control.
- **Status badges** on the right of list items:
  - Soon (within 14 days): accent fill.
  - Released / done: `successContainer`.
  - Unknown / TBA: transparent with a 1.5 dp dashed `outline` border.
  - Default: `surfaceContainerHigh`.

### Cards

- **Hero card:** accent fill, signature asymmetric corners (5.2), 22 dp padding, contains the one big number (`countdown` style) with a unit label, a title, and optionally a wavy progress indicator. At most one per screen.
- **Info card:** `surfaceContainer`, 28 dp corners, 20 dp padding.
- **TBA card:** transparent with a 2 dp dashed `outlineVariant` border. Used whenever data isn't available yet.

### Inputs

- **Text field:** outlined, 56 dp tall, 16 dp corners, label above the field (not floating inside), 2 dp `primary` border when focused, error text below in `error`.
- **Search field:** 58 dp tall pill, `surfaceContainerHigh` fill, leading search icon, trailing clear button.
- **Switch:** standard M3 switch; thumb grows when on.

### Overlays

- **Bottom sheet:** `surfaceContainer`, 32 dp top corners, drag handle, 24 dp side padding. Preferred over dialogs for choices, confirmations and short forms.
- **Dialog:** only for destructive confirmations. 32 dp corners.
- **Snackbar:** `onSurface` background with `surface` text, 16 dp corners, above the nav bar, auto-dismiss after 3 seconds. The message repeats the action's name ("Added to your wishlist" after "Add").

### Progress

- **Wavy linear progress** for countdowns and long-running work.
- **Loading indicator** (M3 Expressive shape-morphing indicator) for unknown waits.
- Never show a spinner for local data.

### Empty states

A `surfaceContainer` block with 32 dp corners: a short headline (`headlineMedium`), one sentence explaining what to do, and one button that does it. Empty is an invitation to act, not a sad face.

---

## 9. Icons

- **UI icons:** Material Symbols Rounded, 24 dp, weight 400, grade 0. Filled variant for the active nav tab only.
- Icon-only buttons always have a content description.
- **No emoji** in the UI.

### 9.1 App icon system

Every Nuvetrix app icon follows the WishPlay pattern:

- Rounded-square tile filled with the **app accent**, one simple **ink (`#16132E`) symbol** in the middle, with small accent-colored details cut into it.
- The symbol must read at 32 px. No text, no gradients, no thin lines.
- Deliver the same set of files every time, named `<app>-<variant>.svg`:

| File | Purpose |
| --- | --- |
| `<app>-app-icon.svg` | Main rounded icon |
| `<app>-app-icon-square.svg` | Full-bleed square |
| `<app>-app-icon-circle.svg` | Round version for avatars |
| `<app>-adaptive-foreground.svg` | Symbol only, inside the 66 dp safe zone of a 108 dp canvas |
| `<app>-adaptive-background.svg` | Solid accent layer |
| `<app>-adaptive-monochrome.svg` | Themed icon for Android 13+ |
| `<app>-notification-icon.svg` | White silhouette on transparent, details cut out |
| `<app>-mark.svg` / `<app>-mark-on-dark.svg` | Symbol without background |
| `<app>-wordmark.svg` / `<app>-wordmark-on-dark.svg` | Name in Bricolage Grotesque, outlined |
| `<app>-logo-horizontal.svg` / `...-on-dark.svg` | Icon plus wordmark |

---

## 10. Writing

- **Voice:** plain, friendly, direct. Short sentences. Talk to the user as "you".
- **Sentence case** for everything: titles, buttons, tabs.
- **Buttons say what happens:** "Save to wishlist", not "Submit". The same action keeps the same name everywhere, and the snackbar uses it too.
- **Missing data:** "To be announced", "Will be shared later", "Will be shared closer to launch". Never "N/A", never blank.
- **Errors** say what went wrong and how to fix it. They don't apologize and aren't vague: "Add a name to save this game."
- **Numbers:** "In 2 days", "Tomorrow", "Today", then dates like "Oct 9". Full dates with year only on details pages.
- **No hype words** ("amazing", "revolutionary"), no exclamation marks in UI text, no emoji.

---

## 11. Accessibility

- Text contrast at least 4.5:1 (3:1 for text 24 sp and larger). Check both themes.
- Every interactive element is at least 48 × 48 dp and has a TalkBack label.
- Switches and toggles announce their state; selected chips and segments announce "selected".
- Font scaling to 200% without clipping.
- Never convey meaning with color alone; pair it with text or an icon.
- Respect reduced motion (section 6).

---

## 12. Standard screens every app ships

1. **Welcome:** app symbol in a 9-sided cookie on `secondaryContainer`, `displayLarge` headline stating the benefit, one sentence, "Continue with Google" (filled) and "Continue as guest" (tonal), plus a line explaining guest data stays on the phone.
2. **Profile / settings,** in this order:
   1. Header: large cookie avatar, name, email, Pro badge if Pro.
   2. Sign-in card (guests only).
   3. Pro card (free users only), hero-card style.
   4. Look and feel: theme segmented control (Light / Dark / System), accent swatches (Pro).
   5. App-specific settings.
   6. Account list: Synced status, Redeem a code, Admin panel (admin only), Check for updates, About, Sign out.
3. **About:** "Made by Nuvetrix" with the version number, links to the privacy policy and terms on the Nuvetrix website.
4. **Get Pro** (if the app has Pro): large cookie shape with the Pro symbol, what Pro includes as a grouped list, the price with "once", Pay with card, Pay with bKash, Redeem a code, and one line on secure checkout.
5. **Update prompt:** a bottom sheet when a newer APK exists; full-screen only for forced updates.

### Pro and upgrade rules

- A locked feature shows a small accent "Pro" chip with a lock icon. Tapping it opens Get Pro.
- At most one upgrade prompt per screen. Never interrupt a task with an upgrade dialog.
- Free features are never degraded to push upgrades.

---

## 13. Company brand vs app brand

The Nuvetrix company brand (website, store listings, social posts) is separate from app UI:

| | Company (nuvetrix website) | Apps |
| --- | --- | --- |
| Main color | Ultramarine `#2E2BDB` | Each app's accent |
| Second color | Tangerine `#FF7A3D` | Shared ink `#16132E` |
| Display font | Unbounded | Bricolage Grotesque |
| Body font | Instrument Sans | Figtree |
| Mark | "N" tile with tangerine dot | App icon (section 9.1) |

Apps mention Nuvetrix only on the Welcome screen footer (optional), the About screen and the Get Pro checkout line. Don't use company colors inside app UI.

---

## 14. Compose starter code

Put these in the shared `designsystem` module. Apps only change `AppAccent`.

```kotlin
// Color.kt
object Ink { val Main = Color(0xFF16132E) }

data class AppAccent(val accent: Color, val onAccent: Color)
val WishPlayAccent = AppAccent(Color(0xFFFFB938), Color(0xFF2B1C00))
val LockoutAccent = AppAccent(Color(0xFFC2EE7B), Color(0xFF1F2E00))

val SuccessLight = Color(0xFF1E6E47); val SuccessContainerLight = Color(0xFFCDEFD9)
val SuccessDark = Color(0xFF7ED3A4);  val SuccessContainerDark = Color(0xFF0F3D27)

fun nvLightColors(a: AppAccent) = lightColorScheme(
    primary = Color(0xFF2E2766), onPrimary = Color.White,
    primaryContainer = a.accent, onPrimaryContainer = a.onAccent,
    secondaryContainer = Color(0xFFE4DFFF), onSecondaryContainer = Color(0xFF231A5C),
    tertiary = Color(0xFF5B3FE0),
    tertiaryContainer = Color(0xFFE6DEFF), onTertiaryContainer = Color(0xFF21105E),
    error = Color(0xFFB3261E), errorContainer = Color(0xFFF9DEDC), onErrorContainer = Color(0xFF410E0B),
    background = Color(0xFFFBF9FF), surface = Color(0xFFFBF9FF),
    onBackground = Ink.Main, onSurface = Ink.Main, onSurfaceVariant = Color(0xFF4A4663),
    surfaceContainer = Color(0xFFF1EEF8), surfaceContainerHigh = Color(0xFFE8E4F2),
    surfaceContainerHighest = Color(0xFFDDD8EC),
    outline = Color(0xFF77728F), outlineVariant = Color(0xFFCAC5DA),
)

fun nvDarkColors(a: AppAccent) = darkColorScheme(
    primary = a.accent, onPrimary = a.onAccent,
    primaryContainer = a.accent, onPrimaryContainer = a.onAccent,
    secondaryContainer = Color(0xFF342D6B), onSecondaryContainer = Color(0xFFE4DFFF),
    tertiary = Color(0xFFB9A8FF),
    tertiaryContainer = Color(0xFF3C2C8F), onTertiaryContainer = Color(0xFFE6DEFF),
    error = Color(0xFFF2B8B5), errorContainer = Color(0xFF601410), onErrorContainer = Color(0xFFF9DEDC),
    background = Color(0xFF131124), surface = Color(0xFF131124),
    onBackground = Color(0xFFEDEAF7), onSurface = Color(0xFFEDEAF7), onSurfaceVariant = Color(0xFFC3BED7),
    surfaceContainer = Color(0xFF1C1A33), surfaceContainerHigh = Color(0xFF25223F),
    surfaceContainerHighest = Color(0xFF302D4C),
    outline = Color(0xFF938EAB), outlineVariant = Color(0xFF46425F),
)
```

```kotlin
// Type.kt  (fonts bundled in res/font)
val Bricolage = FontFamily(
    Font(R.font.bricolage_grotesque_medium, FontWeight.Medium),
    Font(R.font.bricolage_grotesque_bold, FontWeight.Bold),
    Font(R.font.bricolage_grotesque_extrabold, FontWeight.ExtraBold),
)
val Figtree = FontFamily(
    Font(R.font.figtree_regular, FontWeight.Normal),
    Font(R.font.figtree_medium, FontWeight.Medium),
    Font(R.font.figtree_semibold, FontWeight.SemiBold),
    Font(R.font.figtree_bold, FontWeight.Bold),
)

private fun display(w: FontWeight, size: Int, line: Int, ls: Double) =
    TextStyle(fontFamily = Bricolage, fontWeight = w, fontSize = size.sp, lineHeight = line.sp, letterSpacing = ls.em)
private fun body(w: FontWeight, size: Int, line: Int) =
    TextStyle(fontFamily = Figtree, fontWeight = w, fontSize = size.sp, lineHeight = line.sp)

val NvTypography = Typography(
    displayLarge = display(FontWeight.ExtraBold, 44, 46, -0.03),
    displayMedium = display(FontWeight.ExtraBold, 36, 38, -0.03),
    headlineLarge = display(FontWeight.ExtraBold, 28, 31, -0.025),
    headlineMedium = display(FontWeight.Bold, 22, 26, -0.02),
    titleLarge = display(FontWeight.Bold, 19, 23, -0.01),
    titleMedium = body(FontWeight.Bold, 16, 22),
    titleSmall = body(FontWeight.SemiBold, 14, 20),
    bodyLarge = body(FontWeight.Normal, 17, 25),
    bodyMedium = body(FontWeight.Normal, 15, 22),
    bodySmall = body(FontWeight.Normal, 13, 18),
    labelLarge = body(FontWeight.SemiBold, 15, 20),
    labelMedium = body(FontWeight.Bold, 13, 18),
    labelSmall = body(FontWeight.SemiBold, 12, 16),
)
val CountdownStyle = display(FontWeight.ExtraBold, 88, 72, -0.05)
```

```kotlin
// Shape.kt
val NvShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(28.dp),
    extraLarge = RoundedCornerShape(36.dp),
)
// Signature hero card: 36 dp corners, 12 dp bottom-left
val HeroCardShape = RoundedCornerShape(topStart = 36.dp, topEnd = 36.dp, bottomEnd = 36.dp, bottomStart = 12.dp)

// Motion
val SpringFast = spring<Float>(dampingRatio = 0.6f, stiffness = 800f)
val SpringDefault = spring<Float>(dampingRatio = 0.7f, stiffness = Spring.StiffnessMediumLow)
```

```kotlin
// Theme.kt
enum class ThemeMode { Light, Dark, System }

@Composable
fun NvTheme(accent: AppAccent, mode: ThemeMode = ThemeMode.System, content: @Composable () -> Unit) {
    val dark = when (mode) { ThemeMode.Light -> false; ThemeMode.Dark -> true; ThemeMode.System -> isSystemInDarkTheme() }
    MaterialTheme(   // use MaterialExpressiveTheme where your material3 version provides it
        colorScheme = if (dark) nvDarkColors(accent) else nvLightColors(accent),
        typography = NvTypography,
        shapes = NvShapes,
        content = content,
    )
}
```

---

## 15. Do and don't

| Do | Don't |
| --- | --- |
| One hero card with one big number per screen | Several accent-filled cards competing |
| Grouped lists with 3 dp gaps and rounded ends | Separate floating cards with drop shadows |
| Dashed "To be announced" states | Blank fields, "N/A", fake placeholder data |
| Bottom sheets for choices and confirmations | Stacked dialogs |
| Shape morph on press | Ripple as the only feedback on big buttons |
| Flat color | Gradients, glows, heavy shadows |
| "Pro" chip on the locked feature | Upgrade pop-ups in the middle of a task |
| Bundled fonts | Downloading fonts at runtime |

---

## 16. New app checklist

- [ ] Accent chosen and checked against section 3.3 rules; added to the accents table.
- [ ] Full icon set delivered with the names in 9.1; notification icon is white on transparent.
- [ ] `NvTheme` used with the app's `AppAccent`; dynamic color off.
- [ ] Light, dark and system themes checked on every screen.
- [ ] Welcome, Profile, About (and Get Pro if needed) follow section 12.
- [ ] All copy follows section 10; every missing-data state has its text.
- [ ] Contrast, 48 dp targets, TalkBack labels and 200% font scale checked.
- [ ] Reduced motion respected.
- [ ] Any new component added to this file before it's used.
