# Security Policy

## Supported Scope

This repository contains documentation and skill definitions, not production services.
Security-sensitive issues are primarily:

- Accidental inclusion of secrets/tokens/private keys
- Unsafe operational guidance in examples
- Malicious or misleading automation instructions

## Reporting

If you discover a security issue, open a private security advisory on GitHub (preferred).
If private advisories are unavailable, do not open a public issue. Contact the maintainer privately
through the repository owner's GitHub profile contact options:
`https://github.com/Jahrome907`

### Response Targets

- Initial triage response: within 7 days
- Status update after confirmation: within 14 days
- Public disclosure only after a fix or agreed mitigation is available

## Secret Handling

- Do not commit credentials to this repository.
- Use placeholders in examples (`<token>`, `CHANGE_THIS`, etc.).
- Rotate any credential immediately if it was exposed in history.
