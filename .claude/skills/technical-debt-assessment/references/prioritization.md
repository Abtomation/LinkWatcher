# Debt Prioritization: Impact/Effort Frameworks

Systematic prioritization of identified debt via an impact/effort matrix, so remediation maximizes
business value within realistic capacity. Always weigh current business priorities and team
capacity — a high-priority item unaddressable for months can be worth less than a medium-priority
item fixable now.

## Contents

1. [Impact Scoring](#impact-scoring)
2. [Effort Scoring](#effort-scoring)
3. [Matrix Application](#matrix-application)
4. [Worked Scoring Example](#worked-scoring-example)
5. [Troubleshooting](#troubleshooting)

## Impact Scoring

Score four dimensions 1 (Low) / 2 (Medium) / 3 (High):

| Dimension | High (3) | Medium (2) | Low (1) |
|---|---|---|---|
| **User experience** | User-facing errors/crashes; > 2 s delays; blocks critical workflows; data integrity/security exposure | Minor inconvenience; 0.5–2 s delays; non-critical features affected | No direct user impact; cosmetic; internal tooling only |
| **Development velocity** | Blocks feature work; workarounds slow all development; changes risky | Slows specific work; occasional workarounds; +20–50% dev time | Minor inconvenience; < +20% dev time; easy to work around |
| **Maintenance cost** | Frequent production issues; ongoing manual intervention; cascading failures | Occasional issues; periodic manual fixes; extra monitoring | Minimal upkeep; self-contained; rare production impact |
| **Risk & security** | Vulnerabilities; data-integrity or compliance exposure; stability risk | Potential concerns; minor compliance issues; moderate risks | None; theoretical/future risks only |

**Overall impact**: High if any dimension is High or ≥ 3 dimensions are Medium; Medium if 1–2
dimensions are Medium; Low otherwise.

## Effort Scoring

Score four dimensions the same way:

| Dimension | High (3) | Medium (2) | Low (1) |
|---|---|---|---|
| **Scope of change** | Architectural change; multiple modules/services; schema or multi-client API changes | One module, several components; refactoring; config/deployment changes; shared utilities | One component; simple changes; no external dependencies |
| **Team & skills** | Multiple people; missing expertise; cross-team coordination | 2–3 people; some specialized knowledge; in-team coordination | Single developer; existing expertise |
| **Risk & testing** | High regression risk; extensive testing; careful rollout | Moderate side-effect risk; standard suite | Low risk; minimal testing |
| **Timeline** | > 2 weeks | 3–10 days | < 3 days |

**Overall effort**: same aggregation rule as impact.

## Matrix Application

1. Score every item (impact, effort); priority score = impact ÷ effort.
2. Place on the matrix; quadrants: **Critical** (high impact, low effort — quick wins, do now),
   **High** (high impact, high effort — plan deliberately), **Medium** (low impact, low effort —
   fill-ins), **Low** (low impact, high effort — consider deferring).
3. **Apply business context** before finalizing: sprint/release priorities, capacity, dependencies
   between items, stakeholder requirements, external deadlines. Context can legitimately promote
   or defer items across quadrants — record why.
4. Phase the roadmap: Critical → current cycle; High → next 1–2 cycles with dedicated time;
   Medium/Low → capacity fill-ins.

## Worked Scoring Example

*Hardcoded API keys in source*: UX Low (1), velocity Medium (2), maintenance Medium (2),
risk/security **High (3)** → overall impact High (3). Scope Low (1), skills Low (1), testing
Medium (2), timeline Low (1) → overall effort Low (1). Score 3.0 → **Critical (quick win)**.

*Outdated auth library*: impact Medium (2) ÷ effort High (3) = 0.67 → **Low priority** — defer
unless business context (e.g. a security-review deadline) promotes it.

## Troubleshooting

- **Assessors disagree on impact** — resolve with data (metrics, user feedback) and stakeholder
  input; document the assumptions behind the chosen score.
- **Everything scores high** — apply criteria strictly, compare items relatively, force-rank
  within each quadrant.
- **Effort estimates consistently wrong** — decompose large items, buffer for unknowns, track
  actual-vs-estimate to calibrate the next cycle.
- **Priorities churn between cycles** — move changes to a regular review cadence with explicit
  change criteria; keep a record of changes and reasons.
