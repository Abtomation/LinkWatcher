---
variant_group: validation-dimension-paths
description: "Accessibility / UX Compliance dimension path for Dimension Validation — analysis steps and criteria for accessibility standards, UX compliance, keyboard navigation, and inclusive design patterns"
---

# Accessibility / UX Compliance — Validation Dimension Path

> **Parent task**: [Dimension Validation](dimension-validation-task.md) (PF-TSK-092). Execute the shared process there; this path file supplies the dimension-specific content that plugs into the parent's steps 2, 3, 5, 7, 8, and 12, plus the tokens for steps 6 and 13.
>
> | `-ValidationType` (step 6) | `Dims` (step 13) |
> |---|---|
> | `AccessibilityUX` | `UX` |

## AI Agent Role (parent: AI Agent Role)

**Role**: Accessibility Specialist
**Mindset**: Inclusive-design-focused, standards-compliant, user-empathy-driven
**Focus Areas**: WCAG compliance, keyboard navigation, screen reader compatibility, color contrast, focus management, semantic markup, touch target sizing
**Communication Style**: Identify accessibility barriers with specific WCAG criteria references, recommend inclusive alternatives, ask about target accessibility level (A, AA, AAA) and platform-specific requirements

## Dimension Context (parent step 2)

- **UI Design Documents** - UI/UX design specifications and style guides
- **Design System** - component library documentation and accessibility patterns
- **Platform Guidelines** - platform-specific accessibility guidelines (Material Design, Apple HIG, Web Content Accessibility Guidelines)

## Dimension Criteria (parent step 3)

Review the target WCAG level, platform guidelines, and project-specific accessibility requirements.

## Execution Analysis Steps (parent step 5)

5a. **Semantic Structure Analysis**: Verify that UI elements use proper semantic markup/widgets — headings hierarchy, landmark regions, list structures, and form labels
5b. **Keyboard Navigation Review**: Test that all interactive elements are reachable and operable via keyboard — tab order, focus indicators, keyboard shortcuts, and focus trapping in modals
5c. **Screen Reader Compatibility**: Assess that content is properly announced by assistive technology — alt text for images, ARIA labels for interactive elements, live region announcements for dynamic content
5d. **Color & Contrast Assessment**: Verify that text, icons, and interactive elements meet minimum contrast ratios (4.5:1 for normal text, 3:1 for large text per WCAG AA)
5e. **Touch Target & Interaction Review**: Ensure interactive elements meet minimum size requirements (44x44 dp/px) and have sufficient spacing to prevent accidental activation
5f. **Motion & Animation Review**: Check that animations respect user preferences (prefers-reduced-motion), and that no content flashes more than 3 times per second

## Scoring & Findings (parent steps 7–8)

- Apply the 4-point scoring system (0–3) to each accessibility criterion.
- Record specific accessibility barriers **with WCAG success criteria references** and remediation recommendations.

## Remediation Prioritization (parent step 12)

Create action items for accessibility improvements — prioritize by impact on users with disabilities.

## Dimension Outputs (parent: Outputs)

- **Accessibility / UX Compliance Validation Report** - created in `doc/validation/reports/accessibility-ux-compliance/PD-VAL-XXX-accessibility-ux-compliance-features-[feature-range].md`
- **Accessibility Remediation Recommendations** - improvements (with WCAG criteria references) for features scoring below the quality threshold
