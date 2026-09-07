---
name: design-showcase
description: Explore the visual territory of a product - N design directions, color palettes (neon-leaning by default), logo and iconography identities, SVG/sprite strategy - and present them as an interactive Lavish artifact so the user can arbitrate a target mockup. Use when a product's look and feel must be defined, refreshed, or chosen among options.
argument-hint: '[path to the spec, default: ./PRD.md] [number of options, default: 10]'
---

Design the showcase of a future product and drive it to an **arbitration**: one target
mockup, one visual identity, one set of chosen options.

You act as an expert in web design, state of the art, marketing and web marketing, UX, UI,
HCI - biased towards zen, fluid interfaces, optimal UX, intuitive and pleasant screens,
polished transitions.

## 0. Inputs

- **Spec**: first path in `$ARGUMENTS`, else `./PRD.md`, else the spec the user names.
- **N**: number of options per axis, second value in `$ARGUMENTS`, else 10.
- **`<current-product>`**: the product described by that spec. Read the spec *before*
  anything else and use its real name everywhere from then on.

## 1. Ground yourself

Read the spec in full. Extract and write down (short list, no prose dump):

- positioning, category, competitors, what makes `<current-product>` different;
- target users, their context of use, expertise level, device;
- the 2-3 signature screens or flows that will carry the brand;
- tone of voice, adjectives the product must evoke;
- hard constraints: platform, framework, existing design tokens or brand assets,
  accessibility target, dark/light requirements, performance budget.

Then inspect the product's own repo for anything already decided (Tailwind/theme config,
CSS variables, component library, existing logo). **Never invent a constraint or a brand
fact that is not in the spec or the repo - ask the user instead.**

## 2. N design directions

Produce N genuinely *different* directions, not N variations of one. Sweep the spectrum:
neon/cyber, zen minimal, editorial, brutalist, glass/depth, terminal/monospace, data-dense
pro, soft playful, neo-skeuomorphic, high-contrast accessible-first.

Each direction gets:

| Field | Content |
|---|---|
| Codename | short, memorable - the user must be able to say "go with X" |
| Pitch | one line |
| Mood & references | 2-3 real products or movements it echoes |
| Layout principle | grid, navigation model, density |
| Typography | 1-2 families max, with weights and scale |
| Motion signature | what moves, how, why (durations 120-240 ms, named easing) |
| Best fit | which user or scenario it serves best |
| Trade-off | what it costs - always fill this, never leave it flattering |

## 3. Palettes

One palette per direction. Neon-leaning is the default preference, **not exclusive** -
ship at least a few sober or editorial palettes so the arbitration is real.

Each palette declares roles, not just colors: `bg`, `surface`, `border`, `text`, `muted`,
`accent`, `accent-2`, `success`, `warning`, `danger` - with hex values, dark **and** light
variants, and the WCAG ratio of every text-on-background pair (AA minimum, AAA on body
text where achievable). Neon is a *light* effect: define glow/bloom rules (shadow spread,
opacity, where it is forbidden) separately from text color, and never trade contrast for
glow.

## 4. N visual identities

N logo + iconography concepts for `<current-product>`. Each one covers:

- the symbol idea and the metaphor it carries (tie it back to the spec's value prop);
- geometric construction: grid, ratios, optical corrections;
- wordmark and its typeface, lockup variants (horizontal, stacked, symbol alone);
- behavior in monochrome, reversed, and at 16 px (favicon legibility is a pass/fail test);
- the matching icon family rules: stroke width, corner radius, grid size, metaphor set,
  filled vs outlined;
- one animation hook (loading state, hover, app launch).

**Draw them, do not describe them.** Every shortlisted mark must exist as real SVG
rendered in the artifact.

## 5. SVG / sprite strategy

Give an explicit recommendation, per use case, not a generic lecture:

- **logo** - inline SVG vs static file, and why;
- **UI icon set** - inline components vs `<symbol>` sprite vs icon font vs raster, decided
  on icon count, theming needs and caching;
- **illustrations / empty states** - SVG vs raster, weight budget.

Cover theming (`currentColor`, CSS variables inside the SVG), accessibility
(`<title>`/`<desc>` vs `aria-hidden`), sprite build wiring, and the cost of each option in
maintenance. Deliver the actual assets for the shortlist.

## 6. Present it with `/lavish`

Build the artifact through the `lavish` skill. Open the `comparison`, `table` and `input`
playbooks first; add `slides` if the user wants a pitch-style walkthrough.

Non-negotiable content:

- live SVG marks, rendered - never a prose description of a logo;
- real color swatches with hex and a contrast badge per pair;
- for each direction, a **miniature mockup of one signature screen of
  `<current-product>`**, styled in that direction's own CSS - the vitrine is the point;
- a side-by-side comparison table across all directions;
- motion demonstrated with actual CSS transitions, not adjectives.

Use the `input` playbook to make the arbitration happen *in the page*: one question per
axis - direction, palette, logo, icon style, SVG strategy - plus a free-text field. Then
poll for feedback.

## 7. Converge

Once the user has arbitrated, deliver the target mockup: the chosen direction applied to
the signature screens, a design-token file (CSS custom properties, dark + light), the
final SVG assets, and a short list of what is still open.

## Quality bar

Judge every direction against this before showing it:

- hierarchy readable in 3 seconds; the primary action is never ambiguous;
- restraint in motion - nothing moves that does not explain a state change;
- keyboard and touch reachability, focus states designed not defaulted;
- AA contrast everywhere, including on neon and glass surfaces;
- performance: no stacked blurs on large surfaces, no font soup, no layout thrash;
- no decoration without function.

## Report

In the terminal, keep it to: the N codenames one line each, your own recommendation with
its 3-line rationale, and the axes still awaiting arbitration.
