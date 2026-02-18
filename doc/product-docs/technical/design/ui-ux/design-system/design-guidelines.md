---
id: PD-UIX-001
type: Product Documentation
category: UI/UX Design
version: 1.0
created: 2025-01-18
updated: 2025-01-18
status: Living Document
description: Foundational design system guidelines for Breakout Buddies Flutter application
---

# Breakout Buddies - Design System Guidelines

> **📋 Document Status**: Living Document - Evolves as design patterns emerge
> **🎯 Purpose**: Foundational reference for all UI/UX Design work
> **⚠️ CRITICAL**: This document MUST be consulted during every UI Design task

## Table of Contents

- [1. Design Principles](#1-design-principles)
- [2. Visual Foundation](#2-visual-foundation)
  - [2.1 Colors](#21-colors)
  - [2.2 Typography](#22-typography)
  - [2.3 Spacing & Layout](#23-spacing--layout)
  - [2.4 Iconography](#24-iconography)
- [3. Component Library](#3-component-library)
- [4. Accessibility Standards](#4-accessibility-standards)
- [5. Platform-Specific Guidelines](#5-platform-specific-guidelines)
- [6. Responsive Design Patterns](#6-responsive-design-patterns)
- [7. Animation & Motion](#7-animation--motion)
- [8. Design Patterns](#8-design-patterns)
- [9. Do's and Don'ts](#9-dos-and-donts)
- [10. Evolution Process](#10-evolution-process)

---

## 1. Design Principles

### 1.1 Core Principles

**1. User-First Design**

- Prioritize user needs over aesthetic preferences
- Design for the 80% use case, accommodate the 20%
- Minimize cognitive load at every interaction point

**2. Consistency Across Platforms**

- Maintain brand identity while respecting platform conventions
- Use platform-native patterns where users expect them
- Create a cohesive experience across iOS, Android, and Web

**3. Accessibility by Default**

- Meet WCAG 2.1 Level AA minimum for all features
- Design for diverse abilities from the start, not as an afterthought
- Test with assistive technologies regularly

**4. Performance-Conscious Design**

- Optimize for mid-range devices (3-4 year old smartphones)
- Minimize asset sizes and animation complexity
- Design for offline-first experiences where appropriate

**5. Progressive Disclosure**

- Show essential information first, details on demand
- Avoid overwhelming users with too many options
- Guide users through complex flows with clear steps

### 1.2 Brand Personality

**Breakout Buddies Personality Traits**:

- **Adventurous**: Encourages exploration and discovery
- **Social**: Facilitates connection and shared experiences
- **Reliable**: Provides confidence through clear, predictable interactions
- **Playful**: Injects fun without compromising usability

**Tone of Voice**:

- Friendly and encouraging, never condescending
- Clear and direct, avoiding jargon
- Enthusiastic about escape rooms without being pushy

---

## 2. Visual Foundation

### 2.1 Colors

> **Note**: This section defines the foundational color system. Specific color values will be refined based on brand guidelines and accessibility audits.

#### Primary Palette

**Primary Brand Color**: `#6200EE` (Purple)

- **Usage**: Primary actions, key UI elements, brand moments
- **Contrast Ratio**: 4.5:1 on white, 7:1 on light backgrounds
- **Shades**:
  - Light: `#7F39FB` (Hover states)
  - Dark: `#3700B3` (Pressed states)

**Secondary Brand Color**: `#03DAC6` (Teal)

- **Usage**: Secondary actions, highlights, accents
- **Contrast Ratio**: 3.5:1 on white
- **Shades**:
  - Light: `#66FFF9` (Hover states)
  - Dark: `#00A896` (Pressed states)

#### Semantic Colors

**Success**: `#4CAF50` (Green)

- ✅ Success messages
- Confirmation states
- Positive indicators

**Warning**: `#FF9800` (Orange)

- ⚠️ Warning messages
- Caution states
- Non-critical alerts

**Error**: `#F44336` (Red)

- ❌ Error messages
- Failed actions
- Critical alerts

**Info**: `#2196F3` (Blue)

- ℹ️ Informational messages
- Neutral notifications
- System messages

#### Neutral Colors

**Backgrounds**:

- Surface: `#FFFFFF` (White)
- Background: `#F5F5F5` (Off-white)
- Surface Variant: `#E0E0E0` (Light gray)

**Text**:

- Primary: `#212121` (Near black) - Body text
- Secondary: `#757575` (Gray) - Helper text
- Disabled: `#BDBDBD` (Light gray) - Disabled states

**Borders & Dividers**:

- Default: `#E0E0E0`
- Subtle: `#F5F5F5`
- Prominent: `#BDBDBD`

#### Dark Mode

> **Status**: To be defined based on product roadmap

- [ ] Dark mode color palette defined
- [ ] Contrast ratios validated
- [ ] Component adaptations documented

### 2.2 Typography

#### Font Family

**Primary Font**: **Roboto** (Android/Web default)

- Modern, highly legible sans-serif
- Excellent screen readability
- Wide character support

**iOS Alternative**: **San Francisco** (iOS system font)

- Native iOS font for platform consistency
- Optimized for Apple devices

#### Type Scale

| Style          | Size | Weight          | Line Height | Usage                      |
| -------------- | ---- | --------------- | ----------- | -------------------------- |
| **H1**         | 32px | Bold (700)      | 40px        | Page titles                |
| **H2**         | 24px | Bold (700)      | 32px        | Section headers            |
| **H3**         | 20px | Semi-Bold (600) | 28px        | Subsection headers         |
| **H4**         | 18px | Semi-Bold (600) | 24px        | Card titles                |
| **Body Large** | 16px | Regular (400)   | 24px        | Prominent body text        |
| **Body**       | 14px | Regular (400)   | 20px        | Standard body text         |
| **Caption**    | 12px | Regular (400)   | 16px        | Helper text, labels        |
| **Button**     | 14px | Medium (500)    | 16px        | Button labels              |
| **Overline**   | 10px | Medium (500)    | 16px        | Section labels (uppercase) |

#### Typography Guidelines

**Line Length**:

- Optimal: 50-75 characters per line
- Maximum: 90 characters per line

**Paragraph Spacing**:

- Between paragraphs: 16px
- After headings: 8px

**Text Alignment**:

- Body text: Left-aligned (LTR), Right-aligned (RTL)
- Centered: Only for short, standalone elements (hero text, empty states)

### 2.3 Spacing & Layout

#### Spacing Scale

**Base Unit**: 8px (all spacing is a multiple of 8px for consistency)

**Spacing Tokens**:

- `spacing-xs`: 4px (Tight spacing within components)
- `spacing-sm`: 8px (Close-related elements)
- `spacing-md`: 16px (Default spacing)
- `spacing-lg`: 24px (Section spacing)
- `spacing-xl`: 32px (Large gaps)
- `spacing-2xl`: 48px (Major sections)
- `spacing-3xl`: 64px (Page-level spacing)

#### Layout Grid

**Mobile (< 600px)**:

- Columns: 4
- Gutters: 16px
- Margins: 16px

**Tablet (600px - 1024px)**:

- Columns: 8
- Gutters: 24px
- Margins: 24px

**Desktop (> 1024px)**:

- Columns: 12
- Gutters: 32px
- Margins: 32px
- Max content width: 1440px (centered)

#### Component Spacing

**Cards**:

- Padding: 16px
- Margin between cards: 16px
- Border radius: 8px

**Buttons**:

- Horizontal padding: 16px
- Vertical padding: 12px
- Margin between buttons: 8px (horizontal), 16px (vertical)

**Form Fields**:

- Padding: 12px 16px
- Margin between fields: 16px
- Label-to-input spacing: 8px

### 2.4 Iconography

#### Icon Library

**Primary Source**: Material Icons (Material Symbols)

- **Style**: Rounded (friendly, approachable)
- **Weight**: 400 (Regular)
- **Optical Size**: 24px (default)

**iOS Alternative**: SF Symbols

- Use on iOS for platform-consistent feel
- Match weight and style to Material Icons

#### Icon Sizes

- **Extra Small**: 16px (Inline text icons)
- **Small**: 20px (Compact UI elements)
- **Medium**: 24px (Standard UI icons - DEFAULT)
- **Large**: 32px (Feature icons, prominent actions)
- **Extra Large**: 48px (Hero icons, empty states)

#### Icon Usage Guidelines

**Do**:

- Use icons to reinforce text labels
- Maintain consistent icon sizes within a context
- Use filled icons sparingly (for active/selected states)
- Ensure icon meaning is culturally appropriate

**Don't**:

- Use icons without labels for critical actions (unless universally understood)
- Mix icon styles (outlined + filled) inconsistently
- Scale icons disproportionately
- Use overly complex custom icons

---

## 3. Component Library

> **Note**: Breakout Buddies uses Flutter's built-in Material and Cupertino components as the foundation. This section documents which components to use and how to customize them.

### 3.1 Flutter Material Components

**Buttons**:

- **ElevatedButton**: Primary actions (Submit, Confirm, Save)
- **OutlinedButton**: Secondary actions (Cancel, Back, Skip)
- **TextButton**: Tertiary actions (Learn More, Help, Dismiss)
- **FloatingActionButton**: Primary screen action (Create, Add)

**Inputs**:

- **TextField**: Text input with Material styling
- **DropdownButton**: Single selection from list
- **Checkbox**: Multiple selections
- **Radio**: Single selection from group
- **Switch**: Toggle between two states
- **Slider**: Select value from range

**Display**:

- **Card**: Content container with elevation
- **Chip**: Compact element (filters, tags)
- **ListTile**: Standard list item with leading/trailing widgets
- **DataTable**: Structured data display

**Feedback**:

- **SnackBar**: Brief messages at bottom of screen
- **Dialog**: Modal dialogs (AlertDialog, SimpleDialog)
- **ProgressIndicator**: Loading states (Circular, Linear)

### 3.2 Flutter Cupertino Components (iOS)

**When to Use**:

- iOS-specific screens where native feel is critical
- Navigation patterns (CupertinoNavigationBar, CupertinoTabBar)
- Action sheets (CupertinoActionSheet)
- Pickers (CupertinoDatePicker, CupertinoPicker)

### 3.3 Custom Components

**To Be Developed**:

- [ ] Room Card (for displaying escape room listings)
- [ ] Booking Summary Card
- [ ] Rating Display
- [ ] Provider Badge
- [ ] Social Connection Indicator

> As custom components are developed, they will be documented in `doc/product-docs/technical/design/ui-ux/design-system/components/`

---

## 4. Accessibility Standards

### 4.1 WCAG 2.1 Level AA Compliance

**Required Compliance Level**: WCAG 2.1 Level AA (Minimum)

All features must meet the following:

#### Perceivable

1. **Text Alternatives** (1.1):

   - All images have alt text
   - Decorative images marked as decorative
   - Icon-only buttons have semantic labels

2. **Color Contrast** (1.4.3, 1.4.6):

   - Normal text: 4.5:1 minimum
   - Large text (18pt+): 3:1 minimum
   - UI components: 3:1 minimum
   - Target: Level AAA (7:1 for normal text) where feasible

3. **Resize Text** (1.4.4):

   - UI scales properly at 200% zoom
   - No horizontal scrolling at 320px width
   - Text containers expand to fit content

4. **Reflow** (1.4.10):
   - Content reflows without loss of information at 320px viewport
   - No two-dimensional scrolling required

#### Operable

5. **Keyboard Access** (2.1):

   - All functionality available via keyboard
   - Logical tab order
   - No keyboard traps
   - Focus visible on all interactive elements

6. **Touch Targets** (2.5.5):

   - Minimum touch target: 44x44 points (iOS), 48x48 dp (Android)
   - Adequate spacing between targets (8px minimum)

7. **Motion** (2.3):
   - No flashing content (< 3 flashes per second)
   - Users can pause, stop, or hide moving content
   - Animation respects `prefers-reduced-motion`

#### Understandable

8. **Language** (3.1):

   - Page language identified
   - Clear, simple language used
   - Abbreviations explained

9. **Predictable** (3.2):

   - Consistent navigation
   - Consistent identification
   - No unexpected context changes

10. **Input Assistance** (3.3):
    - Clear error messages
    - Form labels visible and descriptive
    - Help text provided where needed
    - Error prevention for critical actions

#### Robust

11. **Compatible** (4.1):
    - Semantic HTML (Web)
    - Proper accessibility traits (iOS/Android)
    - Screen reader tested

### 4.2 Screen Reader Support

**Required**:

- All interactive elements have semantic labels
- Logical navigation order
- State changes announced
- Error messages read aloud
- Loading states communicated

**Testing Tools**:

- **iOS**: VoiceOver
- **Android**: TalkBack
- **Web**: NVDA, JAWS, VoiceOver (macOS)

### 4.3 Assistive Technology Compatibility

- [ ] Screen readers (VoiceOver, TalkBack)
- [ ] Screen magnification
- [ ] Voice control
- [ ] Switch control
- [ ] High contrast modes

---

## 5. Platform-Specific Guidelines

### 5.1 iOS Design

**Follow iOS Human Interface Guidelines**:

- Use iOS-native navigation patterns (Tab Bar, Navigation Bar)
- Respect iOS typography (SF Pro)
- Use iOS-native components where expected (Pickers, Action Sheets)
- Follow iOS gesture conventions (swipe back, pull to refresh)

**iOS-Specific Patterns**:

- **Navigation**: Use `CupertinoNavigationBar` for native feel
- **Tab Bar**: Bottom tab bar for primary navigation
- **Modal Presentation**: Sheet-style modals
- **Haptic Feedback**: Use for confirmation actions

**Resources**:

- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### 5.2 Android Design

**Follow Material Design Guidelines**:

- Use Material Design 3 components
- Respect Material motion principles
- Use Material color system
- Follow Material elevation system

**Android-Specific Patterns**:

- **Navigation**: Use `AppBar` with Material styling
- **Navigation Drawer**: For secondary navigation
- **Bottom Navigation**: For primary navigation (3-5 items)
- **Floating Action Button**: Primary screen action

**Resources**:

- [Material Design 3](https://m3.material.io/)

### 5.3 Web Design

**Web-Specific Considerations**:

- Responsive design down to 320px
- Keyboard navigation with visible focus indicators
- Hover states for desktop interactions
- Progressive enhancement approach

**Web-Specific Patterns**:

- **Navigation**: Top navigation bar (desktop), bottom/hamburger (mobile)
- **Forms**: Use HTML5 input types for better UX
- **Links**: Clearly distinguishable from body text

---

## 6. Responsive Design Patterns

### 6.1 Breakpoints

**Mobile First Approach**: Design for mobile, enhance for larger screens

| Breakpoint             | Range           | Layout Strategy                           |
| ---------------------- | --------------- | ----------------------------------------- |
| **XS (Mobile)**        | 320px - 599px   | Single column, stacked content            |
| **SM (Large Mobile)**  | 600px - 899px   | Single column, larger touch targets       |
| **MD (Tablet)**        | 900px - 1199px  | 2-column layouts, side-by-side content    |
| **LG (Desktop)**       | 1200px - 1439px | 2-3 column layouts, persistent navigation |
| **XL (Large Desktop)** | 1440px+         | Max-width 1440px, centered content        |

### 6.2 Adaptive Patterns

**Navigation**:

- **Mobile**: Bottom tab bar or hamburger menu
- **Tablet**: Bottom tab bar or side navigation
- **Desktop**: Top navigation bar + sidebar

**Content Layout**:

- **Mobile**: Single column, card-based
- **Tablet**: 2-column grid
- **Desktop**: 3-column grid or sidebar + main content

**Forms**:

- **Mobile**: Full-width inputs, vertical labels
- **Tablet/Desktop**: Horizontal labels, multi-column forms

---

## 7. Animation & Motion

### 7.1 Motion Principles

**Purpose**: Motion should be purposeful, not decorative

1. **Feedback**: Confirm user actions
2. **Guidance**: Direct attention to important elements
3. **Continuity**: Connect related UI states
4. **Expression**: Reinforce brand personality

### 7.2 Timing & Easing

**Duration Guidelines**:

- **Micro-interactions**: 100-200ms (button presses, toggles)
- **Transitions**: 200-300ms (screen changes, modal appearance)
- **Complex animations**: 300-500ms (multi-step transitions)

**Easing Functions**:

- **Ease-out**: Use for entering elements (fast start, slow finish)
- **Ease-in**: Use for exiting elements (slow start, fast finish)
- **Ease-in-out**: Use for transitions between states

### 7.3 Performance

**Requirements**:

- Target 60 FPS on all animations
- Use GPU-accelerated properties (transform, opacity)
- Avoid animating layout properties (width, height, top, left)
- Respect `prefers-reduced-motion` user preference

**Flutter Animation Best Practices**:

- Use `AnimatedWidget` or `AnimatedBuilder` for custom animations
- Leverage implicit animations (AnimatedContainer, AnimatedOpacity)
- Dispose animation controllers properly

---

## 8. Design Patterns

### 8.1 Common UI Patterns

**Empty States**:

- Clear illustration or icon
- Descriptive message explaining why content is missing
- Primary action to populate content

**Loading States**:

- Shimmer effect for content placeholders (preferred)
- Circular progress indicator for indeterminate waits
- Linear progress indicator for determinate progress

**Error States**:

- Clear error message in plain language
- Actionable guidance ("Check your internet connection")
- Retry action when appropriate

**Success Confirmation**:

- Brief success message (SnackBar)
- Visual feedback (checkmark animation)
- Optional auto-dismiss (3-5 seconds)

### 8.2 Navigation Patterns

**Bottom Navigation** (Mobile):

- 3-5 primary destinations
- Icons + labels
- Active state clearly indicated

**Tab Bar** (iOS):

- Same as bottom navigation
- Follows iOS HIG styling

**Drawer Navigation**:

- Secondary navigation
- Profile/settings access
- Rarely-accessed features

**Hierarchical Navigation**:

- Back button in app bar
- Breadcrumbs (web/tablet)
- Clear page titles

### 8.3 Data Display Patterns

**Lists**:

- Use `ListView.builder` for efficient rendering
- Include pull-to-refresh
- Infinite scroll for large datasets
- Empty state when no results

**Cards**:

- Group related information
- Include primary action (tap to view details)
- Optional secondary actions (overflow menu)

**Forms**:

- Group related fields
- Clear labels above or within inputs
- Inline validation with helpful error messages
- Disabled submit until valid

---

## 9. Do's and Don'ts

### 9.1 Visual Design

**Do**:

- ✅ Use consistent spacing (8px base unit)
- ✅ Maintain color contrast ratios (4.5:1 minimum)
- ✅ Align elements to a grid
- ✅ Use white space generously
- ✅ Test designs on actual devices

**Don't**:

- ❌ Use too many colors (stick to palette)
- ❌ Center-align body text
- ❌ Use tiny font sizes (< 12px)
- ❌ Rely solely on color to convey information
- ❌ Overcrowd the interface

### 9.2 Interaction Design

**Do**:

- ✅ Provide immediate feedback for user actions
- ✅ Use standard gestures (tap, swipe, pinch)
- ✅ Keep touch targets ≥ 44x44 points
- ✅ Confirm destructive actions
- ✅ Save user progress automatically

**Don't**:

- ❌ Use unfamiliar gestures
- ❌ Hide important actions in menus
- ❌ Require excessive scrolling
- ❌ Create dead ends (no way forward or back)
- ❌ Use modals for non-critical interruptions

### 9.3 Content & Messaging

**Do**:

- ✅ Write in plain, conversational language
- ✅ Use active voice
- ✅ Keep error messages friendly and actionable
- ✅ Provide context for actions
- ✅ Use consistent terminology

**Don't**:

- ❌ Use technical jargon
- ❌ Write vague error messages ("Error occurred")
- ❌ Blame the user ("You entered invalid data")
- ❌ Use all caps (feels like shouting)
- ❌ Overwhelm with long paragraphs

---

## 10. Evolution Process

### 10.1 How This Document Evolves

**Living Document Philosophy**:

- This document starts with foundational guidelines
- As feature designs are created, reusable patterns are identified
- Patterns that appear across multiple features are added to this guideline
- Continuous refinement based on user feedback and testing

### 10.2 Proposing New Patterns

**Process**:

1. **Identify Need**: Encounter a design challenge not covered by existing guidelines
2. **Design Solution**: Create a solution in the feature UI Design document
3. **Evaluate Reusability**: After 2-3 features use similar pattern, propose for design system
4. **Document Pattern**: Add to this guideline with:
   - Problem it solves
   - When to use it
   - Example implementation
   - Accessibility considerations
5. **Update Related Docs**: Update component library or pattern library

**Criteria for Inclusion**:

- Used in 3+ features OR high-value single-use pattern
- Solves a clear, recurring problem
- Maintains consistency with existing guidelines
- Accessible by default
- Performant and implementable in Flutter

### 10.3 Requesting Changes

**Change Request Process**:

1. Identify issue or improvement opportunity
2. Document proposed change with rationale
3. Assess impact (which features affected?)
4. Discuss with team/stakeholders
5. Implement change with version update
6. Update affected feature designs

**Version History**:

| Version | Date       | Changes                          | Author                   |
| ------- | ---------- | -------------------------------- | ------------------------ |
| 1.0     | 2025-01-18 | Initial design system guidelines | AI Agent & Human Partner |

---

## Appendix

### A. Design Tools

**Recommended Tools**:

- **Design**: Figma (collaborative design, prototyping)
- **Icons**: Material Icons library
- **Color**: [Coolors](https://coolors.co/), [Contrast Checker](https://webaim.org/resources/contrastchecker/)
- **Accessibility**: [WAVE](https://wave.webaim.org/), Axe DevTools

### B. Reference Resources

**Platform Guidelines**:

- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design 3](https://m3.material.io/)
- [Flutter Design](https://docs.flutter.dev/ui)

**Accessibility**:

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)

**Typography & Color**:

- [Type Scale](https://typescale.com/)
- [Material Color Tool](https://m2.material.io/design/color/the-color-system.html#tools-for-picking-colors)

### C. Contact & Contributions

**Questions or Suggestions**:

- Review this guideline before every UI Design task
- Propose patterns through the evolution process
- Request clarifications through project communication channels

---

**🎨 Remember**: These guidelines are a living foundation. Start here, build upon it, and help it evolve as Breakout Buddies grows.
