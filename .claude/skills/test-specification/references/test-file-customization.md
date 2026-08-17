# Test File Customization

Craft for creating and customizing actual test files — consulted by any task that implements tests
(Integration and Testing, Core Logic Implementation, Bug Fixing, Code Refactoring, Feature
Enhancement), not only Test Specification Creation.

## Always create via the script

`process-framework/scripts/file-creation/03-testing/New-TestFile.ps1` creates a structured test
file (imports, setup/teardown, Arrange-Act-Assert scaffolding, TODO markers) in the correct test
directory with a tracked id — never hand-author test files; the script keeps ID assignment,
directory placement, and tracking registration consistent.

```powershell
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 `
  -TestName "AuthenticationService" -TestType "Unit" -ComponentName "AuthenticationService" -Priority "Critical" -FeatureId "0.1.1"
```

Run `Get-Help New-TestFile.ps1 -Parameter *` for the full parameter set.

## Parameter selection craft

- **`-TestType`** — determines directory and scope: `Unit` (logic in isolation) · `Integration`
  (component interactions) · `Component` (higher-level than unit) · `E2E` (full workflows) ·
  `Performance`. Take it from the source Test Specification's category mapping, not by feel.
- **`-Priority`** (default `Standard`) — `Critical` (foundation features / core parsers — must
  pass before any release) · `Standard` (normal coverage) · `Extended` (benchmarks / stress / edge
  cases — not release-blocking).

## Customizing the generated file

Work through the TODO markers against the source Test Specification:

- **Imports** — the component under test plus test utilities; follow the existing suite's import
  patterns.
- **Mock strategy** — mock external services and complex dependencies; use real value objects.
  Take expected mock behaviors from the spec's Mock Requirements section.
- **Test cases** — implement the spec's Arrange / Act / Assert scenarios; describe *what behavior*
  each test validates, not just the method name.

## Cross-cutting rules (agnostic homes)

- **Paths inside test content** use the `alpha-project/` synthetic namespace — never real project
  paths. Full rules, mapping convention, and the worked pattern:
  [Test Infrastructure Guide — Test Isolation Rules](../../../../process-framework/guides/03-testing/test-infrastructure-guide.md#test-isolation-rules).
- **After creating or modifying test files**, run the documentation-completeness procedure (update
  the feature's spec, `Validate-TestTracking.ps1`, escalate-vs-inline decision):
  [Test Infrastructure Guide — Test Documentation Completeness](../../../../process-framework/guides/03-testing/test-infrastructure-guide.md#test-documentation-completeness).
