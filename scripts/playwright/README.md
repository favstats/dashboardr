# Dashboardr Local Playwright Pipeline

This pipeline is a **local visual-integration checker** (separate from `testthat`) for dashboard rendering, filters, tabsets, sidebars, linked inputs, and `show_when` behavior.

It always captures screenshots and produces a run report under:

- `output/playwright/<run_id>/results.json`
- `output/playwright/<run_id>/report.html`
- `output/playwright/<run_id>/screenshots/`
- `output/playwright/<run_id>/console/`
- `output/playwright/<run_id>/logs/`

It also refreshes stable pointers every run:

- `output/playwright/latest/report.html`
- `output/playwright/latest-report.html`
- `output/playwright/latest-results.json`

It also maintains a persistent running status list:

- `output/playwright/running-status.html`
- `output/playwright/running-status.md`
- `output/playwright/running-status.json`

The HTML status page includes screenshot thumbnails, direct links to each scenario's report/results/console/logs, and built-in search/filter controls.

## What it tests

- Existing docs/live-demos scenarios from `scripts/playwright/scenarios.yml`
- Generated backend matrix scenarios from `scripts/playwright/generate_matrix_dashboards.R` (when enabled)
- Interaction plans: `filter`, `linked_inputs`, `tab_click`, `sidebar_toggle`, `show_when_toggle`
- Hard-fail checks:
  - missing required selectors
  - missing/hidden expected backend chart widgets
  - failed interactions
  - expected filter effect not observed
  - forbidden console error patterns

## Prerequisites

- `npx`
- `python3`
- `Rscript`
- Playwright CLI wrapper:
  - `$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh`
- Quarto **only if** `--include-generated true`

## Run

From repo root:

```bash
bash scripts/playwright/run_pipeline.sh
```

Options:

```bash
bash scripts/playwright/run_pipeline.sh \
  --mode smoke|full \
  --headed|--headless \
  --port 9010 \
  --include-generated true|false \
  --include-docs true|false \
  --docs-root /path/to/site/root \
  --scenario-manifest scripts/playwright/scenarios.yml
```

Defaults:

- `--mode smoke`
- `--headless`
- `--include-generated true`
- `--include-docs true`
- `--docs-root <repo>/docs`
- `--scenario-manifest scripts/playwright/scenarios.yml`

## Deep Sweep: `demo_chart_backends.R`

Run a thorough all-layout/all-backend check (echarts4r, plotly, highcharter; 5 layouts each):

```bash
bash scripts/playwright/run_demo_chart_backends.sh --mode full --headless
```

This command:

1. Regenerates `here/`, `here_plotly/`, and `here_hc/` via the selected demo script.
2. Runs Playwright scenarios from the selected scenario manifest.
3. Serves from repo root so URLs like `/here/docs/layout_*.html` resolve.

Profiles:

- `mixed` (default): diverse chart types (`dev/demo_chart_backends.R`) with broad integration checks.
- `strict`: propagation stress checks (`dev/demo_chart_backends_strict.R`) where every input must affect all charts.

Examples:

```bash
# Mixed chart diversity checks (default)
bash scripts/playwright/run_demo_chart_backends.sh --profile mixed --mode full --headless

# Strict all-inputs-all-charts propagation checks
bash scripts/playwright/run_demo_chart_backends.sh --profile strict --mode full --headless
```

To skip regeneration and test existing outputs only:

```bash
bash scripts/playwright/run_demo_chart_backends.sh --skip-regenerate
```

## Sidebar Demo Sweep: `demo_sidebar_dashboard.R`

Run dedicated sidebar + linked-input + `show_when` checks for `echarts4r` and `plotly`:

```bash
bash scripts/playwright/run_demo_sidebar_dashboard.sh --mode full --headless
```

This command:

1. Regenerates `sidebar_gss_demo_echarts/` and `sidebar_gss_demo_plotly/`.
2. Runs Playwright scenarios from `scripts/playwright/scenarios_demo_sidebar_dashboard.yml`.
3. Serves from repo root so sidebar demo URLs resolve under `/<demo_dir>/docs/*.html`.

To skip regeneration and test existing outputs only:

```bash
bash scripts/playwright/run_demo_sidebar_dashboard.sh --skip-regenerate
```

## Input Matrix Demo Sweep: `demo_input_matrix_backends.R`

Run a core+mixed backend input-matrix sweep (echarts4r, plotly, highcharter, plus one mixed page):

```bash
bash scripts/playwright/run_demo_input_matrix.sh --mode full --headless
```

This command:

1. Runs `devtools::install()` (unless skipped).
2. Regenerates `input_matrix_echarts/`, `input_matrix_plotly/`, `input_matrix_hc/`, and `input_matrix_mixed/`.
3. Runs scenarios from `scripts/playwright/scenarios_demo_input_matrix.yml`.
4. Serves from repo root so URLs like `/input_matrix_plotly/docs/p2_stackedbar_palette.html` resolve.

Coverage highlights:

- Inputs: `select_single`, `select_multiple`, `checkbox`, `radio`, `slider`, `switch`, `text`, `number`, `button_group`, `linked_inputs`
- Features: `color_palette` on `bar` and `stackedbar`, complex `show_when`, dynamic text selector checks
- Backends: core single-backend pages plus a dedicated mixed-backend integration page

To skip regeneration and test existing outputs only:

```bash
bash scripts/playwright/run_demo_input_matrix.sh --skip-regenerate
```

## No-Sidebar Complex Inputs Sweep: `demo_inputs_no_sidebar_backends.R`

Run dedicated tests for complex inline/top-of-page inputs without any sidebar (echarts4r, plotly, highcharter):

```bash
bash scripts/playwright/run_demo_inputs_no_sidebar.sh --mode full --headless
```

This command:

1. Runs `devtools::install()` (unless skipped).
2. Regenerates `input_nosidebar_echarts/`, `input_nosidebar_plotly/`, and `input_nosidebar_hc/`.
3. Runs scenarios from `scripts/playwright/scenarios_demo_inputs_no_sidebar.yml`.
4. Serves from repo root so URLs like `/input_nosidebar_plotly/docs/n2_inline_showwhen_modes.html` resolve.

Coverage highlights:

- Inline inputs only (no sidebar): `select_multiple`, `select_single`, `button_group`, `checkbox`, `radio`, `slider`, `switch`, `linked_inputs`
- Complex behavior: `show_when` transitions, dynamic text blocks, dynamic title placeholders
- Multi-chart propagation checks on linked-input pages

To skip regeneration and test existing outputs only:

```bash
bash scripts/playwright/run_demo_inputs_no_sidebar.sh --skip-regenerate
```

## Notes

- `smoke` runs a deterministic minimum scenario set.
- `full` runs docs expansion plus generated mixed/backend variants.
- If Quarto is not installed, run with `--include-generated false` to test docs scenarios only.
