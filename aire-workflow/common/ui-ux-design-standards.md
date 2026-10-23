# UI/UX Design Standards

The accessibility, responsiveness and design rules every AIRE-generated mockup follows. Loaded by
`extensions/design/ui-ux/ui-ux-mockups.md` at Step 2. It is not an extension of its own and is never loaded
at workflow start. The Step 4 self-check runs the checklist in Section 7 before the user
sees anything.

**Precedence**: an explicit user answer (Section 1), then the existing product's design system
(brownfield), then the NFR targets in `spec/plans/nfr.md`, then the defaults in this file. 

---

## 1. Design questions

Write `spec/spec-generation/ui-ux-design-questions.md` in the standard format
(`common/question-format-guide.md`), with **only** the questions the requirements, the design
documents and the existing interface do not already answer.
- **Brownfield**: questions 1 and 4 to 8 are usually answered by the existing interface. Read it first
  and ask only what it does not settle.
- **Everything already determinable**: skip the file, and state the derived answers in
  `ui-ux-design.md`.

```markdown
## Question 1: Visual basis
Which visual basis should the mockups follow?

A) The existing application's styling

B) Brand guidelines provided in spec/context-project/new-references/

C) Material Design

D) The default scales of the project's CSS framework (for example Tailwind)

E) A neutral custom style

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 2: Supported screen sizes
Which screen sizes must the interface support?

A) Desktop only

B) Desktop and tablet

C) Desktop, tablet and mobile

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 3: Accessibility level
Which accessibility level applies? WCAG 2.2 AA is the minimum.

A) WCAG 2.2 AA

B) WCAG 2.2 AAA where achievable

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 4: Information density
How much information should each screen carry?

A) Compact, for frequent expert use

B) Balanced

C) Spacious, for occasional or first-time use

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 5: Primary navigation
Which navigation pattern should the application use?

A) Fixed side navigation

B) Collapsible side navigation

C) Top navigation bar

D) Tabs

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 6: Feedback style
How should errors and confirmations be shown?

A) Inline next to the field or element, with a summary for forms

B) Banner at the top of the page

C) Toast notifications

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 7: Loading states
How should loading be represented?

A) Skeleton placeholders

B) Spinners

C) Progress bars for long operations, skeletons elsewhere

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 8: Brand colour and tone
Enter the primary brand colour (hex value or name), any colours to avoid, and the tone the interface
should convey (for example professional, efficient, approachable). Enter "none" to use a neutral
palette.

[Answer]: 
```

Follow up on any vague answer per `common/overconfidence-prevention.md`. Record the final answers in
the **Design system** section of `spec/plans/ui-ux-design.md`.

---

## 2. Design tokens

Define tokens once, in a `:root` CSS custom-property block, and use the same block in every screen
file. No colour, size or spacing value is written outside it.

| Token group | Contents | Default |
|---|---|---|
| Colour roles | primary, secondary, surface, background, text, muted text, border, focus, success, warning, error, info | Neutral palette, or derived from Question 8 |
| Spacing | base unit and scale | 4px base: 4, 8, 12, 16, 24, 32, 48, 64 |
| Typography | font stack, base size, scale, weights, line height | System font stack; 16px base; scale 12, 14, 16, 20, 24, 32; weights 400, 500, 600, 700; line height 1.5 for body text |
| Radius | small, medium, large | 4px, 8px, 12px |
| Elevation | shadow levels | 0, 1, 2, 3 |
| Motion | durations and easing | 150ms and 250ms, ease-out |
| Icons | one icon set, one style | Inline SVG matching the stack's icon set (for example Lucide, Heroicons or Material Symbols). Never emoji. |

- **Brownfield**: copy the token values from the existing theme or CSS variables. Do not create a
  parallel palette.
- **Stack-aligned**: when the frontend uses a CSS framework or component library, use that system's
  scales (for example Tailwind spacing, Material tokens), so the mockup translates directly into
  code.

---

## 3. Accessibility (WCAG 2.2 AA minimum)

| Area | Requirement | WCAG |
|---|---|---|
| Text contrast | 4.5:1 for normal text; 3:1 for large text (24px regular or 18.66px bold and above). AAA: 7:1 and 4.5:1 | 1.4.3, 1.4.6 |
| Non-text contrast | 3:1 for input borders, focus indicators, icons that carry meaning, and chart elements | 1.4.11 |
| Colour alone | Never the only way to convey state. Errors, status and required fields also use text or an icon | 1.4.1 |
| Semantic structure | One `h1` per screen, headings in order, landmarks (`header`, `nav`, `main`, `footer`), lists as lists, tables with `th` and `scope` | 1.3.1, 2.4.6 |
| Page basics | `lang` on `html`, a descriptive `title`, and a skip link to `main` when navigation precedes content | 3.1.1, 2.4.2, 2.4.1 |
| Forms | A visible `label` for every input (never placeholder-only), required fields marked in text, instructions before the field, and errors linked to the field with `aria-describedby` | 1.3.1, 3.3.1, 3.3.2 |
| Keyboard | Every control reachable and operable by keyboard, in a logical tab order, with no keyboard trap. Use native `button`, `a`, `input` and `select` before ARIA roles | 2.1.1, 2.1.2, 2.4.3 |
| Focus | A visible focus indicator on every interactive element (at least a 2px outline at 3:1 contrast), never hidden behind sticky headers or footers | 2.4.7, 2.4.11 |
| Names | Icon-only buttons have `aria-label`. Meaningful images have `alt`; decorative images use `alt=""` | 4.1.2, 1.1.1 |
| Target size | At least 24 by 24 CSS px everywhere, and 44 by 44 on touch layouts. AAA: 44 by 44 everywhere | 2.5.8, 2.5.5 |
| Status messages | Toasts, inline results and loading completion are announced with `role="status"`, or `role="alert"` for errors | 4.1.3 |
| Motion | No flashing above 3 per second. Animation respects `prefers-reduced-motion`, and moving content longer than 5 seconds can be paused | 2.3.1, 2.2.2 |
| Authentication | No cognitive test to sign in. Allow paste and password managers | 3.3.8 |
| Redundant entry | Information already entered in the same flow is not asked for again | 3.3.7 |

---

## 4. Responsive design

- **Mobile first.** Base styles target the smallest supported size; `min-width` media queries add
  layout for larger screens. For a desktop-only target (Question 2), design for 1024px and wider and
  omit the smaller breakpoints.
- **Breakpoints**: sm 640px, md 768px, lg 1024px, xl 1280px. On brownfield, use the existing
  product's breakpoints.
- **Reflow**: content works at 320 CSS px wide with no horizontal scrolling, except data tables and
  maps (1.4.10). Text resized to 200% loses no content or function (1.4.4).
- **Units**: `rem` for type and spacing, `%`, `fr` and `minmax()` for layout, and `max-width: 100%`
  on media. No fixed pixel widths on containers.
- **Viewport**: `<meta name="viewport" content="width=device-width, initial-scale=1">`. Never disable
  zoom.
- **Grid**: 12 columns at lg and above, 8 at md, 4 at sm. Readable line length is 45 to 75 characters,
  using a centred max-width container on large screens and full width on small ones.
- **Mobile inputs**: a font size of at least 16px, so mobile browsers do not zoom on focus.

| Component | lg and above | sm |
|---|---|---|
| Navigation | As chosen in Question 5 | Collapses to a menu button with an accessible label and `aria-expanded` |
| Data tables | Standard table | Stacked cards with field labels, or horizontal scroll inside the table container only |
| Forms | Up to two columns for related short fields | Single column |
| Modals | Centred dialog | Full-screen sheet |
| Charts | Full interactive chart | Simplified chart with the key figures also shown as text |
| Primary actions | Right-aligned or inline, as the design system defines | Full width, within thumb reach |

---

## 5. UX patterns (defaults when no answer applies)

| Pattern | Default |
|---|---|
| Validation | On submit, then inline as the user corrects each field. A form error summary links to each field |
| Error messages | State what went wrong and how to fix it, in plain language, next to the field |
| Success feedback | Inline confirmation or `role="status"` toast; the result is visible without a page reload |
| Loading | Skeletons for content areas; a spinner only for actions under about 2 seconds; progress for longer ones |
| Empty states | Explain why it is empty and offer the next action |
| Destructive actions | Confirmation that names the item and the consequence, with the safe option as the default focus |
| Primary actions | One primary action per screen or section, in a consistent position |
| Data density | Per Question 4: compact uses smaller spacing tokens and row heights, but never below the Section 3 target size |

---

## 6. Brownfield consistency

- Reuse the existing components, layout shell, navigation and terminology. A new screen should look
  like it already belongs to the product.
- Where the existing interface falls below Section 3, the new screens meet Section 3 anyway. List the
  existing gap under **Design decisions** in `ui-ux-design.md`; do not change existing screens that
  are out of scope.

---

## 7. Self-check before presenting (ui-ux-mockups.md Step 4)

Check every screen file against this list. Fix every failure before the review message is shown, and
record the result in `ui-ux-design.md` under **Standards check**.

- [ ] Every colour, size and spacing value comes from the `:root` token block
- [ ] Text and non-text contrast meet Section 3 for the chosen level (calculate the ratio for each
      foreground and background token pair)
- [ ] One `h1`, ordered headings, landmarks, `lang`, `title`, skip link where needed
- [ ] Every input has a visible label; errors are linked with `aria-describedby`; state is never
      shown by colour alone
- [ ] Native interactive elements, a logical tab order, a visible focus style on every one
- [ ] Icon-only controls have accessible names; images have correct `alt`
- [ ] Targets are at least 24 by 24 px, and 44 by 44 on touch layouts
- [ ] Status and error messages use `role="status"` or `role="alert"`
- [ ] Viewport meta present, zoom not disabled, layout reflows at 320px with no horizontal scroll
- [ ] Each component follows the Section 4 responsive rules for every supported size
- [ ] Animation respects `prefers-reduced-motion`
- [ ] Default, empty, loading, error and success states are present where the ACs imply them
- [ ] No emoji used as icons or decoration
