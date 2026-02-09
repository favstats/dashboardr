# dashboardr Architecture (Maintainer Notes)

This document captures the current internal structure used to keep `dashboardr`
maintainable without changing public APIs.

## Local-only AI tooling

Any AI governance/adapter files are treated as local-only contributor tooling.
They are not part of required repository checks or package build artifacts.

## High-level flow

1. Collection builders
- `create_content()` / `create_viz()` build content/viz specs.
- `create_page()` builds page specs.
- `create_dashboard()` builds project specs.

2. Spec processing
- `R/viz_processing.R` turns flat specs into grouped/tabbed render structures.
- Cross-tab filter metadata is attached here.

3. File generation
- `R/page_generation.R` produces page-level QMD content.
- `R/quarto_yml.R` produces `_quarto.yml`.
- `R/dashboard_generation.R` writes project files and optional render step.

4. Rendering
- Quarto renders generated QMD to HTML when enabled.

## Internal maintainability modules

- `R/block_registry.R`
  - Central block type registry (`.content_block_types()`)
  - Shared block validation for generation (`.validate_content_block_for_generation()`)

- `R/nse_helpers.R`
  - Shared NSE default capture (`.capture_nse_defaults()`)
  - Shared variable parameter sets for collection/page defaults

- `R/content_validation.R`
  - Shared validation helpers for `show_when` and `filter_vars`

## Asset policy

Canonical runtime assets live in:
- `inst/assets/`

Managed mirrors are synced via:
- `scripts/sync_assets.R`

Check drift:
- `Rscript scripts/sync_assets.R --check`

## Artifact policy

Canonical publish output tracked in git:
- `docs/`

Non-canonical generated outputs (dev/scratch) are guarded by:
- `.gitignore` rules
- `scripts/check_artifacts.R`
- CI workflow step "Enforce artifact policy"

## Feature matrix testing architecture

Machine-readable matrix:
- `tests/testthat/fixtures/feature_matrix.yml`

Scenario and generation helpers:
- `tests/testthat/helper-feature-matrix.R`

Goldens:
- `tests/testthat/golden/feature_matrix/`

Two-tier execution:
- PR tier (`DASHBOARDR_MATRIX_LEVEL=pr`): deterministic pairwise subset.
- Nightly tier (`DASHBOARDR_MATRIX_LEVEL=nightly`): expanded matrix.
