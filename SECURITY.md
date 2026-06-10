# Security Policy

## Supported Versions

Only the latest release is actively monitored for security issues.

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
responsibly:

1. **Do not** open a public issue.
2. Send a report to [codex-linux-maintainers@users.noreply.github.com](mailto:codex-linux-maintainers@users.noreply.github.com)
   with a description of the vulnerability, steps to reproduce, and potential impact.
3. You will receive an acknowledgment within 48 hours.

## Scope

This repository contains **packaging scripts only** — no Codex source code is
redistributed. Security concerns specific to the Codex Desktop application
itself should be directed to [OpenAI](https://openai.com/security/).

## Known Considerations

- The APT repository currently uses `trusted=yes` (unsigned). Users should verify
  package integrity via checksums published in GitHub Releases.
- The install script (`install.sh`) is fetched over HTTPS but piped directly to
  `sudo bash`. Users concerned about supply-chain risk should download and review
  the script before execution.
