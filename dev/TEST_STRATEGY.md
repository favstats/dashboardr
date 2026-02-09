# Dashboardr Test Strategy

## Goals

- Preserve strict public API compatibility.
- Catch cross-feature regressions across content types, layouts, backends, inputs, and conditional visibility.
- Keep PR feedback fast while still running broad sweeps regularly.

## Capability-matrix philosophy

The matrix is the source of truth for interaction coverage:
- `tests/testthat/fixtures/feature_matrix.yml`

It defines:
- content block types and feature support flags
- supported backend set
- explicit unsupported combinations and expected error patterns

All registered content types from `dashboardr:::.content_block_types()` must appear in the matrix.

## Pairwise vs exhaustive

PR tier (`DASHBOARDR_MATRIX_LEVEL=pr`):
- deterministic pairwise-selected subset + full base coverage by content type
- optimized for speed and stable CI feedback

Nightly tier (`DASHBOARDR_MATRIX_LEVEL=nightly`):
- expanded deterministic pairwise-selected matrix set
- deeper interaction coverage across backends and feature toggles

This balances signal quality and CI throughput.

## Golden policy

Interaction-sensitive structure checks use fragment goldens:
- `tests/testthat/golden/feature_matrix/`

Golden scope includes:
- `_quarto.yml` structural fragments
- QMD fragments for rows/columns, show_when wrappers, filter_vars propagation, backend injection

Goldens should remain stable; only update them when behavior changes are intentional and reviewed.

## Adding new content types or features

When adding a new block type or major feature:

1. Update canonical registry (for block types).
2. Update `tests/testthat/fixtures/feature_matrix.yml` with support flags.
3. Add or update scenario generation logic in `tests/testthat/helper-feature-matrix.R`.
4. Add explicit unsupported-combination expectations if applicable.
5. Add/update matrix tests and golden fragments.
6. Run PR-tier matrix tests locally.

## Minimum checks before merge

- `tests/testthat/test-api-contract.R`
- matrix tests (PR tier)
- generation structure golden matrix test
- artifact policy check
- asset drift check
