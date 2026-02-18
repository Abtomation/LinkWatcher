---
id: PF-ASS-002
type: Process Framework
category: Tier Assessment
version: 1.0
created: 2023-06-15
updated: 2025-05-29
---

# Documentation Examples

This directory contains example documentation for different documentation tiers to serve as references when creating new documentation.

## Purpose

These examples demonstrate how to apply the tiered documentation approach to features of varying complexity. They provide concrete examples of what documentation should look like at each tier.

## Documentation Tier Examples

- [Tier 1 Task Breakdown Example](tier1-task-breakdown-example.md) - Example of a task breakdown for a simple feature (Remember Me Login Option)
- <!-- [Tier 2 Technical Design Document Example](../../../../process-framework/methodologies/loading-state-informational-content.md) - Template/example link commented out --> - Example of a lightweight TDD for a moderate feature
- <!-- [Tier 3 Technical Design Document Example](../../../../process-framework/methodologies/user-authentication-flow.md) - Template/example link commented out --> - Example of a full TDD for a complex feature

## Documentation Tier Adjustment Examples

These examples demonstrate how documentation tiers can change during implementation as the actual complexity of a feature becomes apparent:

### Tier Upgrades (Increased Complexity)

| Feature ID | Feature Name | Initial Tier | Final Tier | Key Factors | Example |
|------------|--------------|--------------|------------|-------------|---------|
| 2.3.1 | Game Settings | Tier 1 🔵 | Tier 3 🔴 | Cross-device sync, advanced customization, accessibility | [View Example](2.3.1-game-settings-tier-adjustment-example.md) |

### Tier Downgrades (Decreased Complexity)

| Feature ID | Feature Name | Initial Tier | Final Tier | Key Factors | Example |
|------------|--------------|--------------|------------|-------------|---------|
| 3.2.4 | Global Leaderboard | Tier 3 🔴 | Tier 2 🟠 | Third-party service, simplified requirements | [View Example](3.2.4-leaderboard-tier-adjustment-example.md) |

## How to Use These Examples

### For Initial Documentation

1. Determine the appropriate documentation tier for your feature using the [Documentation Tiers](../../../../process-framework/methodologies/documentation-tiers/README.md) guide
2. Refer to the corresponding example as a template for your documentation
3. Adapt the template to your specific feature, adding or removing sections as needed

### For Documentation Tier Adjustments

1. Review the tier adjustment examples to understand how complexity can change during implementation
2. Use the [Documentation Tier Assessment Guide](../../../guides/guides/assessment-guide.md) when you notice significant changes in feature complexity
3. Reference the appropriate example based on whether your feature is increasing or decreasing in complexity
4. Follow the format shown in the examples to document your tier adjustment rationale

## Documentation Templates

For official templates (rather than examples), refer to:

- <!-- [Task Breakdown Template](../../../../process-framework/task-breakdown-template.md) - Template/example link commented out --> - For all features, with additional sections for Tier 1 features
- [Lightweight Technical Design Document Template](../../../templates/templates/tdd-t2-template.md) - For Tier 2 features
- [Full Technical Design Document Template](../../../templates/templates/tdd-t3-template.md) - For Tier 3 features
