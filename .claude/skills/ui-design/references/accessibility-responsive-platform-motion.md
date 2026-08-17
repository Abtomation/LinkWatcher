# Accessibility, Responsive, Platform, Motion & Design-System Integration (sections 7–11)

- [Section 7 — Accessibility Requirements](#section-7--accessibility-requirements)
- [Section 8 — Responsive Design](#section-8--responsive-design)
- [Section 9 — Platform-Specific Adaptations](#section-9--platform-specific-adaptations)
- [Section 10 — Animation & Transitions](#section-10--animation--transitions)
- [Section 11 — Design System Integration](#section-11--design-system-integration)

## Section 7 — Accessibility Requirements

Target **WCAG 2.1 Level AA**. Make every requirement **testable** (a specific value or behavior, not
"should be accessible"). Cover the four principles (Perceivable, Operable, Understandable, Robust);
the load-bearing concretes:

- Text contrast ≥ 4.5:1 (≥ 3:1 large text) · touch targets ≥ 44×44 pt · fully keyboard-operable ·
  screen-reader tested.
- **Semantic labels** for every interactive element, plus focus order and the announcements for
  state changes:

```markdown
- Email input: label "Email address" + hint "Enter your email"
- Continue button: "Continue to password"
- Error: "Error: Invalid email format. Please check and try again."
```

## Section 8 — Responsive Design

Per breakpoint (mobile / tablet / desktop), specify the layout adjustments, component-size changes,
and what is hidden/shown — and the content priority on small screens.

```markdown
**Mobile (320–599px)**: single column · full-width inputs · stacked buttons · bottom nav
**Tablet (900px+)**: 2-column form · side-by-side buttons · persistent side nav
```

## Section 9 — Platform-Specific Adaptations

Only when the target spans platforms. Per platform (iOS / Android / Web / Desktop): native components
used, platform-specific behaviors (mobile: gestures; desktop: keyboard shortcuts, hover, context menu,
window resize), and compliance with the platform's guidelines (iOS HIG, Material Design, the target
OS's desktop conventions). If designs are ≥ 90% identical across platforms, document once and note the
differences rather than duplicating whole sections.

```markdown
### iOS
- HIG: bottom-sheet modal flow; swipe-down to dismiss (with confirm); floating-label text fields
- Components: native nav bar, text field, button
- Behaviors: light-impact haptic on press; pull-to-refresh
```

## Section 10 — Animation & Transitions

State the motion **principle** (fluid / snappy / subtle) and **purpose** (feedback / guidance /
continuity), then specify each animation in a table. Keep most at 100–300ms with easeOut/easeInOut.

| Element | Animation | Duration | Easing | Trigger |
|---------|-----------|----------|--------|---------|
| Button  | scale 0.95 | 150ms | easeOut | on press |
| Modal   | fade + slide-up | 300ms | easeInOut | on open |
| Error   | shake + color | 400ms | easeOut | on validation fail |

Performance: GPU-accelerated properties only (transform, opacity); honor `prefers-reduced-motion`;
target 60 FPS. Mark the whole section "not applicable" explicitly when the feature has no motion.

## Section 11 — Design System Integration

- **Patterns applied** — list the PD-UIX-001 patterns this feature reuses (e.g. empty-state,
  form-validation).
- **New patterns introduced** — for anything genuinely new, describe it, assess reusability
  (High/Medium/Low), and recommend adding High-reusability ones to the Design Guidelines via its
  evolution process. A new reusable pattern is a candidate Design-Guidelines update, not a one-off.

```markdown
**Candidate pattern**: real-time email validation (green check as a valid email is typed)
- Reusability: High → recommend adding to Design Guidelines as "Real-time Input Validation"
```
