# Contributing

## Core policy

- Public API compatibility is strict: do not remove or rename exported functions,
  and do not remove existing arguments/defaults.
- Keep behavioral changes limited to bug fixes and robustness improvements.

## Local-only AI files

AI governance/adapter files are intentionally local-only in this repo setup.
They are ignored by git and excluded from package build inputs.

## Generated artifacts

Only root `docs/` is canonical publish output.

Do not commit generated outputs from scratch/dev dashboards such as:
- `here/`, `here_hc/`, `here_plotly/`, `22222/`
- `dev/**/docs/`, `dev/**/site_libs/`, `dev/**/.quarto/`

CI enforces this with:
- `Rscript scripts/check_artifacts.R`

## Assets

Canonical source:
- `inst/assets/`

Sync managed mirrors:
- `Rscript scripts/sync_assets.R`

Verify no drift:
- `Rscript scripts/sync_assets.R --check`

## Tests

Feature matrix levels:
- PR tier: `DASHBOARDR_MATRIX_LEVEL=pr` (default)
- Nightly tier: `DASHBOARDR_MATRIX_LEVEL=nightly`

Run the package test suite from package context:
- `devtools::test()`
- or `testthat::test_check("dashboardr")`

Avoid using ad-hoc `testthat::test_dir()` as the primary signal for package-level
correctness.

Run targeted matrix/golden tests when generation behavior changes:
- `testthat::test_file("tests/testthat/test-content-feature-matrix.R")`
- `testthat::test_file("tests/testthat/test-feature-matrix-scenarios.R")`
- `testthat::test_file("tests/testthat/test-viz-feature-matrix.R")`
- `testthat::test_file("tests/testthat/test-backend-feature-matrix.R")`
- `testthat::test_file("tests/testthat/test-layout-sidebar-feature-matrix.R")`
- `testthat::test_file("tests/testthat/test-input-showwhen-filter-integration.R")`
- `testthat::test_file("tests/testthat/test-generation-structure-golden-matrix.R")`

Release-safe minimum checks:
- `Rscript scripts/check_artifacts.R`
- `Rscript scripts/sync_assets.R --check`

## Documentation

Keep maintainer-oriented docs concise and current:
- `dev/ARCHITECTURE.md`
- `CONTRIBUTING.md`
- `dev/TEST_STRATEGY.md`
