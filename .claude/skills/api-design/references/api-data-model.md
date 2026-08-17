# API Data Model Craft

Customization decisions for an API Data Model document (created by the task via
`process-framework/scripts/file-creation/02-design/New-APIDataModel.ps1`). The template lists the
*sections*; this is how to decide *what goes in them*.

## Data structure complexity — flat vs. nested

- **Flat** for basic CRUD payloads.
- **Nested** for domain objects with real sub-structure or relationships.
- Trade-off: nesting raises validation and serialization cost and complicates client
  implementation — don't nest for cosmetic grouping.

## Field requirement strategy — required vs. optional

- Drive `required` from business / data-integrity needs, not convenience.
- Bias toward **optional** for fields added after v1: promoting a field to required is a breaking
  change for existing clients.

## Validation granularity — type-only vs. business-rule

- Type/format checks (string length, numeric range, date format, array size) belong in the **Data
  Constraints** table for every model.
- Add business-rule validation only where data quality genuinely depends on it — each rule is
  documentation *and* implementation surface.

## Versioning strategy — model evolution

- State the API version the model targets, and whether a given change is breaking.
- Reach for additive optional fields (non-breaking growth) before a new model version; document
  migration when a break is unavoidable.

## Worked example

`Authentication Request` (`-RelatedEndpoints "/auth/login,/auth/refresh"`):

- **Structure**: email/username, password, optional `rememberMe`, optional device info.
- **Required vs. optional**: credentials required; `rememberMe` / device optional (added-later
  candidates).
- **Validation**: email format + password strength in Data Constraints; note sensitive-field
  handling under the optional **Security Notes** section.
- **Versioning**: leave room for future auth methods (OAuth, 2FA) as additive optional fields
  rather than a v2 model.
