 

# Open Source Checklist - Orion-LD API Gateway

## About

This checklist ensures the Orion-LD API Gateway project follows best practices for health, development, and security. It serves as a living document to track our progress and maintain high standards for our open source community.

Use this checklist as a discussion starter for the team and a foundation for continuous improvement.

## Project Status

Current compliance status for Orion-LD API Gateway:

- ✅ Documentation complete (README, Architecture, Usage)
- ✅ Docker-based deployment ready
- ✅ Security features implemented (JWT, IP whitelisting)
- ✅ GitHub Actions CI/CD configured
- ✅ MkDocs documentation site
- 🔄 OpenSSF Scorecard monitoring enabled
- 🔄 Container security scanning active

## Archiving and Deprecating a Project

- Should use the platform's "Archival" function. This way, it becomes read-only, including the issues board, and is flagged as inactive.
- Should state in the README that the project is no longer maintained.
- Should be archived if there are no maintainers.

## Documentation

### Community Health Files ✅

The project includes all standard Community Health Files:

- ✅ [README.md](https://github.com/CTU-SematX/Orion-Nginx#readme) - Comprehensive project documentation
- ✅ [CONTRIBUTING.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CONTRIBUTING.md) - Contribution guidelines
- ✅ [CODE_OF_CONDUCT.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CODE_OF_CONDUCT.md) - Community standards
- ✅ [SECURITY.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/SECURITY.md) - Security policy
- ✅ [CHANGELOG.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CHANGELOG.md) - Version history
- ✅ [GOVERNANCE.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/GOVERNANCE.md) - Project governance

### Technical Documentation ✅

- ✅ Installation and Requirements - Docker setup guide
- ✅ Quick Start Instructions - 3-step deployment process
- ✅ Usage Examples - Both trusted and non-trusted client scenarios
- ✅ Architecture Diagram - Visual component flow
- ✅ Security Model - Two-tier access control explanation
- ✅ Configuration Guide - Environment variables and customization
- ✅ Troubleshooting - Common issues and solutions
- ✅ Development Guide - For contributors
- ✅ [MkDocs Site](https://ctu-sematx.github.io/Orion-Nginx/) - Published documentation

## Legal and Licensing

### License Compliance ✅

- ✅ Project licensed under [CC-BY-4.0](https://github.com/CTU-SematX/Orion-Nginx/blob/main/LICENSES/CC-BY-4.0.txt)
- ✅ No conflicts with third-party licenses (OpenResty, Orion-LD, MongoDB)
- ✅ License declarations follow [REUSE specification](https://reuse.software/)
- ✅ All materials have clear copyright information

### Third-Party Dependencies

- OpenResty (BSD License) - Compatible ✅
- lua-resty-jwt (Apache 2.0) - Compatible ✅
- lua-resty-hmac (MIT) - Compatible ✅
- FIWARE Orion-LD (AGPL-3.0) - Separate container, compatible ✅
- MongoDB (SSPL) - Separate container, compatible ✅

### Naming and Trademarks Check

- Should ensure that the project name does not conflict with an existing project or infringe on trademarks.
  - Conduct a general search engine check for the proposed project name.
  - Perform a [Trademark Search](https://www.prv.se/en/ip-professional/trademarks/trademark-databases/).

> **Note**: It might be perfectly acceptable to use a name reminiscent of an existing trademark - if the existing trademark is used for other services/areas and is not recognized as a well-known trademark.

## People & Maintenance

### Maintainer Responsibilities ✅

- ✅ Maintainers listed in README
- ✅ Security contact designated in SECURITY.md
- ✅ Pull request workflow defined in CONTRIBUTING.md
- ✅ Community engagement guidelines in place
- ✅ Code review process via GitHub Actions

### Release Management 🔄

- ✅ GitHub Actions workflows for releases configured
- ✅ Semantic versioning ready (v*.*.* tags)
- ✅ Docker image publishing to ghcr.io
- ✅ SLSA provenance attestation enabled
- ✅ SBOM generation configured
- 🔄 Need to establish regular release cadence
- 🔄 Consider CODEOWNERS file for component ownership

## Project Quality

### Code Quality ✅

- ✅ Initial code review completed
- ✅ MegaLinter integration in CI pipeline
- ✅ Docker build testing on pull requests
- ✅ YAML, Markdown, and Shell script linting

### Ease of Use ✅

- ✅ Docker Compose setup for easy deployment
- ✅ Simple `start.sh` script for quick start
- ✅ Comprehensive documentation with examples
- ✅ Pre-built container images via GitHub Actions
- ✅ cURL examples for common operations
- ✅ JWT generation examples in Python and Node.js

### Testing Goals 🔄

Current state:

- ✅ Docker build tests
- ✅ Docker Compose validation
- 🔄 Need integration tests for JWT verification
- 🔄 Need end-to-end API tests
- 🔄 Consider load testing for production readiness

## Release and Versioning

### Version Strategy ✅

- ✅ [Semantic Versioning 2.0.0](https://semver.org/) implemented
- ✅ Git tags for releases (v*.*.*)
- ✅ Support for pre-release versions (alpha, beta, rc)
- ✅ Automated release workflow via GitHub Actions
- ✅ Draft releases for review before publishing
- ✅ Container images tagged with version numbers

### Release Process

Automated via `.github/workflows/release-workflow.yml`:

1. Push version tag (e.g., `v1.0.0`)
2. GitHub Actions builds container
3. Generates SBOM and SLSA provenance
4. Publishes to GitHub Container Registry
5. Creates draft GitHub release with changelog

## Security

*Based on the [OpenSSF guide for secure open source development](https://github.com/ossf/wg-best-practices-os-developers/blob/main/docs/Concise-Guide-for-Developing-More-Secure-Software.md) (2023-06-14) and [social engineering takeover alerts](https://openssf.org/blog/2024/04/15/open-source-security-openssf-and-openjs-foundations-issue-alert-for-social-engineering-takeovers-of-open-source-projects/).*

### General Security 🔄

**Repository Protection:**

- 🔄 Enable 2FA/MFA for all maintainers
- 🔄 Limit merge and push rights to main branch
- 🔄 Enable branch protection rules
- 🔄 Require signed commits
- ✅ OpenSSF Scorecard monitoring enabled

**Maintainer Review:**

- 🔄 Establish periodic review of committers and maintainers
- ✅ Automated testing in CI pipeline
- 🔄 Need test coverage reporting
- 🔄 Add negative case testing

### Contribution Security ✅

- ✅ Code review process defined in CONTRIBUTING.md
- ✅ Pull request template with checklist
- ✅ MegaLinter runs on all PRs
- ✅ Docker build testing before merge
- ✅ Clear contribution guidelines
- ✅ No binary files in repository (container-based deployment)

### Dependencies and Vulnerability Detection

**Implemented ✅:**

- ✅ Container vulnerability scanning in CI pipeline
- ✅ MegaLinter for code quality and security
- ✅ YAML, Shell, and Dockerfile linting
- ✅ Automated dependency tracking via Dependabot (GitHub)
- ✅ Package managers used (Alpine APK, OpenResty OPM)

**Dependencies Monitored:**

- ✅ OpenResty base image (Alpine-based)
- ✅ lua-resty-jwt library
- ✅ lua-resty-hmac library
- ✅ Orion-LD container (FIWARE official)
- ✅ MongoDB container (official)

**TODO 🔄:**

- 🔄 Enable GitHub secret scanning
- 🔄 Add SAST tools (e.g., Trivy, Grype)
- 🔄 Implement automated security updates
- 🔄 Add dependency health evaluation process

### Publishing and Distribution ✅

**SBOM and Attestation:**

- ✅ SBOM generation enabled in release workflow
- ✅ SLSA provenance attestation configured
- ✅ Container image scanning before publish
- ✅ Multi-platform builds (AMD64, ARM64)

**Access Control:**

- ✅ Publishing limited to GitHub Actions workflows
- ✅ Requires repository permissions for releases
- ✅ Published to GitHub Container Registry (ghcr.io)

**User Experience:**

- ✅ Semantic versioning for clear upgrade paths
- ✅ Container tags: `latest`, `v1.0.0`, `v1.0`, `v1`
- ✅ Comprehensive upgrade documentation
- ✅ Environment variable based configuration (easy updates)
- 🔄 Consider signing releases with GPG/sigstore

### Security Policy ✅

- ✅ [SECURITY.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/SECURITY.md) in place
- ✅ Vulnerability reporting process documented
- ✅ Security contact information provided
- ✅ Response timeline commitments
- ✅ Responsible disclosure guidelines

---

## Security Resources

Secure software practices and tooling from OpenSSF and OWASP:

### Tooling

- [OpenSSF guide to security tools](https://github.com/ossf/wg-security-tooling/blob/main/guide.md#readme).
- [OWASP Application Security Tools](https://owasp.org/www-community/Free_for_Open_Source_Application_Security_Tools)
- [OpenSSF Scorecards for repository security](https://github.com/ossf/scorecard)

### Guides

- [OpenSSF's Concise Guide for Evaluating Open Source Software](https://best.openssf.org/Concise-Guide-for-Evaluating-Open-Source-Software)
- [CNCF Security TAG Software Supply Chain Best Practices guide](https://github.com/cncf/tag-security/blob/main/supply-chain-security/supply-chain-security-paper/CNCF_SSCP_v1.pdf).
- [OWASP Cheatsheets](https://cheatsheetseries.owasp.org/index.html).
- [OWASP Software Developer Guide](https://owasp.org/www-project-developer-guide/release/).
- [Signing artifacts in the supply chain - OpenSSF sigstore project](https://www.sigstore.dev/).
- [OWASP Application Security Verification Standard - ASVS](https://owasp.org/www-project-application-security-verification-standard/).
- [Supply-chain Levels for Software Artifacts - (SLSA)](https://slsa.dev/).

## GitHub Workflows ✅

### Automated CI/CD Pipelines

**Pull Request Workflow:**

- ✅ MegaLinter for code quality
- ✅ Docker build testing
- ✅ Container security scanning
- ✅ Automatic on every PR

**Release Workflow:**

- ✅ Triggered by version tags (v*.*.*)
- ✅ Builds multi-platform containers
- ✅ Generates SBOM and SLSA provenance
- ✅ Publishes to GitHub Container Registry
- ✅ Creates draft release with changelog

**MkDocs Deployment:**

- ✅ Automatic documentation deployment
- ✅ Deploys to GitHub Pages
- ✅ Triggered on docs changes

**OpenSSF Scorecard:**

- ✅ Bi-weekly security analysis
- ✅ Results published to GitHub Security tab

See [CONTRIBUTING](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CONTRIBUTING.md) for detailed workflow information.

## Specifications and Standards to Follow

The following will help your Open Source Project to be collaborative, reusable, accessible, and up-to-date.

- [REUSE License specification](https://reuse.software/)
  - Ensures clear and standardized license compliance across the project.

- [Conventional Commits format](https://www.conventionalcommits.org/en/v1.1.0/)
  - Provides a clear and structured project history through standardized commit messages.

- [Keep-A-Changelog format](https://keepachangelog.com/en/1.1.0/)
  - Maintains a clear and user-friendly release history.

- [Semantic Versioning 2.0.0](https://semver.org/)
  - Provides consistent version numbering for releases.

- [Contributor Covenant guidelines](https://www.contributor-covenant.org/)
  - Establishes a social contract for respectful and inclusive collaboration.

- [OpenSSF Scorecard](https://scorecard.dev/)
  - Helps assess and improve the security health of our project.

- [PublicCode.yml](https://yml.publiccode.tools/index.html)
  - Facilitates easy metadata indexing for better discoverability of our project.

- [Standard for Public Code](https://standard.publiccode.net/)
  - Ensures the project meets criteria for public code quality and sustainability.
