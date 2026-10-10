# Chalk & Glass design system

Source of truth in code: `lib/core/theme/` and `lib/core/widgets/`. Live catalogue in the app: Settings → About → long-press the version row.

## Idea

A chalkboard classroom in daylight (and at night). Paper cards on a chalk-coloured page, subject "pigments" for colour, one warm accent (marigold) for the single most important action on a screen. **Glass is only for things that float over content.**

## Tokens

- Colours (`AppColors`, via `context.app`): `chalk` page, `paper`/`paper2` surfaces, `ink`/`ink2`/`ink3` text, `line`/`line2` rules, `mari` accent (`mariInk` on top of it), `ok`/`bad`/`late` states with `*Soft` fills, `scrim`, and `glassTint`, `glassTintStrong`, `glassShadow`, `glassRim`. Themes: Chalk (light), Blackboard (dark), AMOLED. Subject colours: `AppColors.subjects[id]`; houses: `AppColors.houses`.
- Type (`context.type`, `AppTypography`): `h1` page titles, `t` titles, `cap` captions, `dl` display numerals, `anek(size, weight, …)` for one-off styles, uppercase tracked `Overline` for labels.
- Shape and motion (`tokens.dart`): radii `card 24`, `field 18`, `sheet 34`; durations `fast 180`, `medium 280`, `slow 400`, `rise 420`; tablet breakpoint 840.
- On tablets `PageFrame` centres a ~720 px reading column.

## Building blocks (`core/widgets/ui.dart` barrel)

`labels` (Overline, Stamp, Dot, PulseDot, Chip2), `cover` (notebook Cover), `surfaces` (EduCard, Hr, DashedLine, Hatch, Grab, Gutter), `controls` (Pressable, Btn, Field), `avatar` (Avatar), `motion` (Rise). Pages: `PageFrame` (title row, scrolling body, bottom bar, status-bar scrim), `Dock`, `SheetBody`, `Toast`. States: `ViewStateView`, `EmptyState`, `EmptyArt`, `SkeletonList`, `ErrorState`.

## Glass

- Use for: dock, top icon buttons, pills and segmented controls, switches and sliders, sheets, toasts, bottom action bars.
- Never for: page headers, cards, greetings, ribbons, or any block behind text.
- `Glass(onPigment: true)` when the backdrop is coloured art (clear lens); the default frosted tint when it sits on text and cards. "Reduce transparency" in Settings swaps glass for solid fills; keep both looks readable.
- On Impeller the shader receives the **whole window** as its texture (`uTexSize == uScreen`), and `FlutterFragCoord()` is then a **window coordinate**: the shader samples it as is and subtracts the glass origin (`uOrigin`) for the shape. A crop around the glass (other backends) is sampled at the fragment and arrives y-flipped on GLES (`gFlip`). This was verified with a colour-coded debug pass; a plain page hides mapping bugs, so always check glass over colourful art (the stripes card on the design-system screen) on a device or emulator. Headless tests only exercise the blur fallback. "Show refraction maps" draws the displacement field; the screen also prints the live glass-layer count.
- Keep the number of glass layers on a screen small.

## Empty and loading states

Every collection screen defines: an `EmptyArt` illustration, a title that states the fact ("No homework yet"), a body that says what will appear and when, an optional `emptyHint` chip (reassurance), and `emptyActions` that lead somewhere useful (message the teacher, ask the office). Home has a welcome card with three first steps for a brand-new school. Loading uses skeletons, not a spinner on a blank page.

## Copy

Short, concrete, friendly, no jargon. Sentence case. Numbers carry units. No raw keys: add `en` keys first; `hi`/`mr` fall back.

## Accessibility

Text scale (Settings), 44 px minimum tap targets, "Reduce motion" replaces springs with crossfades, contrast checked in all three themes, icon-only buttons carry a `label`.
