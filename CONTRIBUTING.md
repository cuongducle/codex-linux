# Contributing to Codex Desktop for Linux

Thank you for your interest in contributing! This project packages the upstream
OpenAI Codex Desktop application for Linux.

## Getting Started

1. **Fork** the repository.
2. **Clone** your fork and install dependencies:
   ```bash
   git clone https://github.com/<your-username>/codex-linux.git
   cd codex-linux
   npm install
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b fix/your-fix-description
   ```

## Types of Contributions

- **Bug fixes:** Packaging issues, install scripts, AppArmor profiles, sandbox handling.
- **Platform support:** Patches for new distributions, display servers, or architectures.
- **Documentation:** README improvements, troubleshooting guides, translations.
- **CI/CD:** Workflow improvements, build optimizations.

## Development Workflow

1. Download the upstream DMG (see `scripts/setup.sh` for the URL).
2. Run `bash scripts/setup.sh ./Codex.dmg` to extract and rebuild native modules.
3. Make your changes to the packaging scripts or patches.
4. Test with `npm run build:linux` and verify with `bash scripts/smoke-verify.sh`.

## Commit Messages

Use clear, descriptive commit messages:

```
fix(postinst): handle missing AppArmor on non-Ubuntu distros
feat(ci): add arm64 build matrix
docs(readme): add troubleshooting section
```

## Pull Request Process

1. Ensure your branch is up to date with `main`.
2. Describe what changed and why.
3. Include testing steps you performed.
4. Keep PRs focused — one logical change per PR.

## Code of Conduct

Be respectful and constructive. This project follows the
[GitHub Community Guidelines](https://docs.github.com/en/site-policy/github-terms/github-community-guidelines).
