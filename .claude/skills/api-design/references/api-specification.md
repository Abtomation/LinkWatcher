# API Specification Craft

Customization decisions for an API Specification document (created by the task via
`process-framework/scripts/file-creation/02-design/New-APISpecification.ps1`). The template carries
its own section structure; these are the decisions the template can't make. The **API-type /
template-variant decision** — the load-bearing one — is in the skill's SKILL.md.

## Authentication strategy

JWT (stateless, scalable) · API Key (simple service-to-service) · OAuth (third-party / delegated) ·
Session (traditional web). The choice drives client integration complexity and scalability.

## Error handling granularity

Bare HTTP status codes for simple APIs; structured error objects when clients need specific error
conditions to recover or debug. Reference the project's Response Status Catalog in the Status Codes
section (the task's define-API-contract step) and use its canonical status codes for consistency.

## Documentation detail level

Minimal for internal APIs with known usage; comprehensive for public APIs or complex integrations
where developer onboarding matters.

## Service-Interface worked example

`PD-API-001 Invoice Generation External Integrations`
(`doc/technical/api/specifications/api-1.1.3-invoice-generation-external-integrations.md` in the
origin project) documents three integrations — wkhtmltopdf subprocess, Outlook COM, HTML/DOCX
templates — using the Service-Interface variant's section vocabulary (Purpose, Invocation contract,
Inputs, Outputs, Error model, Concurrency, Versioning per integration). Use it as the model when
the REST endpoint/auth/status-code shape is structurally wrong for the boundary.
