#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$ROOT/scripts/playwright"

MODE="full"
HEADLESS_FLAG="--headless"
PORT=""
REGENERATE="true"
INSTALL_FIRST="true"
SCENARIO_MANIFEST="$SCRIPT_DIR/scenarios_demo_sidebar_single_graph.yml"

log() {
  printf '[playwright-sidebar-single] %s\n' "$*"
}

die() {
  printf '[playwright-sidebar-single] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: bash scripts/playwright/run_demo_sidebar_single_graph.sh [options]

Options:
  --mode smoke|full        (default: full)
  --headed                 Run browser headed.
  --headless               Run browser headless (default).
  --port <n>               Base port for docs server.
  --skip-regenerate        Skip rerunning dev/demo_sidebar_single_graph.R.
  --skip-install           Skip running devtools::install() before regeneration.
USAGE
}

find_local_quarto() {
  local base="$HOME/.local/quarto"
  if [[ ! -d "$base" ]]; then
    return 1
  fi
  find "$base" -type f -path "*/bin/quarto" 2>/dev/null | sort -V | tail -n 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --headed)
      HEADLESS_FLAG="--headed"
      shift
      ;;
    --headless)
      HEADLESS_FLAG="--headless"
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --skip-regenerate)
      REGENERATE="false"
      shift
      ;;
    --skip-install)
      INSTALL_FIRST="false"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

if [[ "$MODE" != "smoke" && "$MODE" != "full" ]]; then
  die "--mode must be smoke or full"
fi

if [[ "$REGENERATE" == "true" ]]; then
  command -v Rscript >/dev/null 2>&1 || die "Missing required command: Rscript"

  if [[ "$INSTALL_FIRST" == "true" ]]; then
    log "Installing package with devtools::install() before regeneration..."
    Rscript -e "devtools::install('${ROOT}', upgrade = 'never', dependencies = FALSE, build_vignettes = FALSE, quiet = TRUE)"
  fi

  if ! command -v quarto >/dev/null 2>&1; then
    local_quarto="$(find_local_quarto || true)"
    if [[ -n "${local_quarto:-}" ]]; then
      export PATH="$(dirname "$local_quarto"):$PATH"
      log "Using local Quarto: $local_quarto"
    fi
  fi
  command -v quarto >/dev/null 2>&1 || die "Quarto is required to regenerate sidebar single-graph demo outputs"

  log "Regenerating sidebar single-graph demos..."
  DASHBOARDR_DEMO_OPEN=false Rscript "$ROOT/dev/demo_sidebar_single_graph.R"
fi

cmd=(
  bash "$SCRIPT_DIR/run_pipeline.sh"
  --mode "$MODE"
  "$HEADLESS_FLAG"
  --include-generated false
  --include-docs true
  --docs-root "$ROOT"
  --scenario-manifest "$SCENARIO_MANIFEST"
)

if [[ -n "$PORT" ]]; then
  cmd+=(--port "$PORT")
fi

log "Running sidebar single-graph Playwright sweep..."
"${cmd[@]}"
