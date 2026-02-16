# dashboardr LLM Guide (Generated)

This guide is generated from canonical policy under `ai/`.
Edit `ai/*` and run `Rscript scripts/sync_ai_adapters.R`.

## Canonical Governance
- `ai/PHILOSOPHY.md`
- `ai/RULES.md`

## Canonical Skills
- `dashboardr-doc-sync`: Keep multi-agent docs in sync from canonical ai/ sources and prevent adapter drift.
- `dashboardr-maintainer`: Maintain dashboardr with strict API compatibility, deterministic generation, and low-risk internal refactors.
- `dashboardr-mcp`: Build and maintain the dashboardr MCP server for LLM-assisted dashboard coding.
- `dashboardr-release-safety`: Apply release-grade safety checks for compatibility, deterministic output, and governance drift.
- `dashboardr-testing`: Build and maintain deterministic feature-matrix and golden tests across content types, backends, layouts, and inputs.

## Required Safety Commands
- `Rscript scripts/check_ai_adapters.R`
- `Rscript scripts/check_artifacts.R`
- `Rscript scripts/sync_assets.R --check`

## Feature Matrix Test Levels
- PR tier: `DASHBOARDR_MATRIX_LEVEL=pr`
- Nightly tier: `DASHBOARDR_MATRIX_LEVEL=nightly`

## Philosophy
# Dashboardr Engineering Philosophy

## 1) Compatibility First
Public API compatibility is non-negotiable.

- Never remove or rename exported functions.
- Never remove arguments or silently change defaults of exported functions.
- Behavior changes are allowed only as targeted bug fixes with tests.
- Internal refactors must preserve externally observable dashboard structure unless a bug is being fixed.

## 2) Single Source of Truth
Avoid duplicate mutable definitions.

- `inst/assets/` is the canonical runtime asset source.
- `R/block_registry.R` is the canonical content-block registry.
- `ai/` is the canonical source for LLM rules and skills.
- Generated adapters (`AGENTS.md`, `CLAUDE.md`, `.cursor/*`, `docs/llms.txt`) are derived artifacts.

## 3) Deterministic Generation and Testing
Outputs and test oracles must be reproducible.

- Prefer stable golden fixtures for `_quarto.yml` and representative QMD fragments.
- Use deterministic scenario generation for feature-matrix tests.
- Keep PR-tier tests fast and deterministic; run broader sweeps nightly.

## 4) Error Quality
Errors must be actionable and contextual.

- Include page/block identifiers when available.
- Prefer explicit validation failures over implicit runtime breakage.
- Keep messages specific enough to guide a fix.

## 5) Documentation Minimalism
Write only what maintainers and contributors need.

- Keep architecture and workflow docs concise and current.
- Avoid stale duplicate docs; document once and link.
- Prefer short examples that are runnable.

## 6) Risk Ladder for Changes
Choose test scope by risk.

- Low risk: comments/docs/internal extraction without behavioral changes.
- Medium risk: generation-path refactors and validation changes.
- High risk: anything affecting page structure, tabgroups, inputs, filtering, or backend rendering.

Higher risk requires stronger evidence (matrix tests + goldens + targeted regression tests).

## Rules
# Dashboardr Operational Rules

## MUST Rules

### 1) Edit Canonical Sources
- Edit canonical policy/skills only under `ai/`.
- Edit adapter targets only via `scripts/sync_ai_adapters.R`.

### 2) Preserve Public API Contracts
- Do not remove/rename exported functions.
- Do not remove arguments or change defaults on exported functions.
- Keep compatibility wrappers when refactors touch behavior-sensitive paths.

### 3) Run Required Checks by Change Type
- Any code change: run relevant `testthat` files and contract tests.
- Generation-path changes: run golden/matrix tests.
- Asset changes: run `Rscript scripts/sync_assets.R --check`.
- Governance/skill changes: run `Rscript scripts/check_ai_adapters.R`.
- Artifact-policy-sensitive changes: run `Rscript scripts/check_artifacts.R`.

### 4) Keep Generated Artifacts in Policy
- Root `docs/` is the only canonical tracked publish output.
- Non-canonical generated outputs must not be introduced.

### 5) Release Gate
Before merge/release, all of the following must pass:
- API contract tests
- Matrix/golden tests (PR or nightly tier as appropriate)
- Asset drift check
- Artifact policy check
- AI adapter drift check

## SHOULD Rules

### 1) Prefer Centralization
- Reuse shared validators/helpers over duplicated logic.
- Keep registries and feature maps in single canonical files.

### 2) Prefer Deterministic Tests
- Use fixed seeds/fixtures.
- Avoid flaky timing-based assertions.

### 3) Keep Docs Short and Linked
- Update `CONTRIBUTING.md`, `dev/ARCHITECTURE.md`, and `dev/TEST_STRATEGY.md` when workflow changes.

## Shortcut Commands
When the user says **"rebuild"**, run `Rscript dev/rebuild.R` from the package root.
Flags: `--skip-demos`, `--skip-pkgdown`. Pass them if the user specifies (e.g. "rebuild skip demos").

## If Uncertain
- Bias toward no behavior change.
- Add explicit tests before refactoring risky logic.
- Choose the strictest compatibility-preserving option and document assumptions.

