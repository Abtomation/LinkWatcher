# Test File Customization

The file-mechanics half of the `test-authoring` skill — how to create and customize an actual
test file. Consulted by any task that creates test files, at the point where the
[Test Authoring Guide](../../../../process-framework/guides/03-testing/test-authoring-guide.md#phase-1-before-writing)
decides the test's home is a new file (Phase 1).

## Always create via the script

`process-framework/scripts/file-creation/03-testing/New-TestFile.ps1` creates a structured test
file (imports, setup/teardown, tracking markers and TODO comments — deliberately no test bodies,
so a fresh scaffold collects zero tests) in the correct test
directory with a tracked id — never hand-author test files; the script keeps ID assignment,
directory placement, and tracking registration consistent.

```powershell
pwsh.exe -ExecutionPolicy Bypass -File process-framework/scripts/file-creation/03-testing/New-TestFile.ps1 `
  -TestName "AuthenticationService" -TestType "Unit" -ComponentName "AuthenticationService" -Priority "Critical" -FeatureId "0.1.1"
```

Run `Get-Help New-TestFile.ps1 -Parameter *` for the full parameter set.

## Parameter selection craft

- **`-TestType`** — names the test subdirectory the file lands in, so the accepted values are
  *this project's own* subdirectories under its configured test directory, never a fixed
  framework vocabulary; list them with `Run-Tests.ps1 -ListCategories`. Names in common use and
  what they conventionally hold: `unit` (logic in isolation) · `integration` (component
  interactions) · `performance` (benchmarks). Take the choice from the source Test
  Specification's category mapping, not by feel. A type whose directory does not exist yet is
  rejected — scaffold it first (declare it in `project-config.json` `testing.quickCategories`,
  then run `New-TestInfrastructure.ps1`).
- **`-Priority`** (default `Standard`) — `Critical` (foundation features / core parsers — must
  pass before any release) · `Standard` (normal coverage) · `Extended` (benchmarks / stress / edge
  cases — not release-blocking). Agnostic home of the vocabulary:
  [Test Infrastructure Guide — Test Priority](../../../../process-framework/guides/03-testing/test-infrastructure-guide.md#test-priority).

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
- **After creating or modifying test files**, close out per the
  [Test Authoring Guide — Phase 4](../../../../process-framework/guides/03-testing/test-authoring-guide.md#phase-4-close)
  (the scoped tracking sync, then the documentation-completeness procedure).
