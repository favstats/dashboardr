#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$ROOT/scripts/playwright"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"

MODE="smoke"
HEADLESS="true"
BASE_PORT=""
INCLUDE_GENERATED="true"
INCLUDE_DOCS="true"
DOCS_ROOT=""
SCENARIO_MANIFEST=""

log() {
  printf '[playwright] %s\n' "$*"
}

die() {
  printf '[playwright] ERROR: %s\n' "$*" >&2
  exit 1
}

normalize_bool() {
  case "${1:-}" in
    true|TRUE|1|yes|YES|y|Y) printf 'true' ;;
    false|FALSE|0|no|NO|n|N) printf 'false' ;;
    *) die "Invalid boolean: $1 (expected true/false)" ;;
  esac
}

pick_port() {
  python3 - <<'PY'
import socket
s = socket.socket()
s.bind(('127.0.0.1', 0))
print(s.getsockname()[1])
s.close()
PY
}

usage() {
  cat <<'USAGE'
Usage: bash scripts/playwright/run_pipeline.sh [options]

Options:
  --mode smoke|full
  --headed
  --headless
  --port <n>
  --include-generated true|false
  --include-docs true|false
  --docs-root <path>
  --scenario-manifest <path>
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --headed)
      HEADLESS="false"
      shift
      ;;
    --headless)
      HEADLESS="true"
      shift
      ;;
    --port)
      BASE_PORT="$2"
      shift 2
      ;;
    --include-generated)
      INCLUDE_GENERATED="$2"
      shift 2
      ;;
    --include-docs)
      INCLUDE_DOCS="$2"
      shift 2
      ;;
    --docs-root)
      DOCS_ROOT="$2"
      shift 2
      ;;
    --scenario-manifest)
      SCENARIO_MANIFEST="$2"
      shift 2
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

INCLUDE_GENERATED="$(normalize_bool "$INCLUDE_GENERATED")"
INCLUDE_DOCS="$(normalize_bool "$INCLUDE_DOCS")"
DOCS_ROOT="${DOCS_ROOT:-$ROOT/docs}"
SCENARIO_MANIFEST="${SCENARIO_MANIFEST:-$SCRIPT_DIR/scenarios.yml}"

if [[ ! -d "$DOCS_ROOT" ]]; then
  die "--docs-root does not exist or is not a directory: $DOCS_ROOT"
fi
if [[ ! -f "$SCENARIO_MANIFEST" ]]; then
  die "--scenario-manifest does not exist: $SCENARIO_MANIFEST"
fi

if [[ "$INCLUDE_GENERATED" != "true" && "$INCLUDE_DOCS" != "true" ]]; then
  die "At least one of --include-generated or --include-docs must be true"
fi

for cmd in npx python3 Rscript jq; do
  command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
done

[[ -x "$PWCLI" ]] || die "Playwright wrapper not found/executable at: $PWCLI"
"$PWCLI" --help >/dev/null 2>&1 || die "Playwright CLI wrapper did not start"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$ROOT/output/playwright/$RUN_ID"
mkdir -p "$RUN_DIR"/{screenshots,console,logs}

STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Run ID: $RUN_ID"
log "Mode: $MODE"
log "Run directory: $RUN_DIR"

if [[ "$INCLUDE_GENERATED" == "true" ]]; then
  log "Generating matrix dashboards..."
  Rscript "$SCRIPT_DIR/generate_matrix_dashboards.R" \
    --output_dir "$RUN_DIR/generated_site" \
    --mode "$MODE" \
    --manifest_out "$RUN_DIR/generated_scenarios.json"
else
  printf '{"generated_at":null,"mode":"%s","scenarios":[],"skipped":[]}\n' "$MODE" > "$RUN_DIR/generated_scenarios.json"
fi

DOCS_PORT=""
GENERATED_PORT=""
if [[ -n "$BASE_PORT" ]]; then
  DOCS_PORT="$BASE_PORT"
  GENERATED_PORT="$((BASE_PORT + 1))"
else
  DOCS_PORT="$(pick_port)"
  GENERATED_PORT="$(pick_port)"
fi

SERVER_PIDS=()
cleanup() {
  if [[ "${#SERVER_PIDS[@]}" -gt 0 ]]; then
    for pid in "${SERVER_PIDS[@]}"; do
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    done
  fi
  if [[ -n "${SESSION:-}" ]]; then
    "$PWCLI" --session "$SESSION" close >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

DOCS_BASE_URL=""
GENERATED_BASE_URL=""
if [[ "$INCLUDE_DOCS" == "true" ]]; then
  DOCS_BASE_URL="http://127.0.0.1:$DOCS_PORT"
  python3 -m http.server "$DOCS_PORT" --directory "$DOCS_ROOT" >"$RUN_DIR/logs/http-docs.log" 2>&1 &
  SERVER_PIDS+=("$!")
  log "Docs server: $DOCS_BASE_URL (root: $DOCS_ROOT)"
fi

if [[ "$INCLUDE_GENERATED" == "true" ]]; then
  GENERATED_BASE_URL="http://127.0.0.1:$GENERATED_PORT"
  python3 -m http.server "$GENERATED_PORT" --directory "$RUN_DIR/generated_site" >"$RUN_DIR/logs/http-generated.log" 2>&1 &
  SERVER_PIDS+=("$!")
  log "Generated server: $GENERATED_BASE_URL"
fi

sleep 1

RESOLVED="$RUN_DIR/scenarios.resolved.json"
Rscript - "$SCENARIO_MANIFEST" "$RUN_DIR/generated_scenarios.json" "$RESOLVED" "$MODE" "$INCLUDE_DOCS" "$INCLUDE_GENERATED" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
manifest_path <- args[[1]]
generated_path <- args[[2]]
out_path <- args[[3]]
mode <- args[[4]]
include_docs <- identical(args[[5]], "true")
include_generated <- identical(args[[6]], "true")

`%||%` <- function(x, y) if (is.null(x)) y else x

if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required for Playwright scenarios.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required for Playwright scenarios.", call. = FALSE)
}

manifest <- yaml::read_yaml(manifest_path)
defaults <- manifest$defaults %||% list(forbidden_console_patterns = character(0))
scenarios <- manifest$scenarios %||% list()

apply_defaults <- function(s, defaults) {
  for (nm in names(defaults)) {
    if (is.null(s[[nm]])) {
      s[[nm]] <- defaults[[nm]]
    }
  }
  s
}

keep_mode <- function(s) {
  m <- s$modes %||% c("smoke", "full")
  mode %in% unlist(m, use.names = FALSE)
}

scenarios <- Filter(keep_mode, scenarios)
scenarios <- lapply(scenarios, apply_defaults, defaults = defaults)

if (!include_docs) {
  scenarios <- Filter(function(s) !identical(s$source_type, "docs"), scenarios)
}
if (!include_generated) {
  scenarios <- Filter(function(s) !identical(s$source_type, "generated"), scenarios)
}

if (include_generated && file.exists(generated_path)) {
  generated <- jsonlite::fromJSON(generated_path, simplifyVector = FALSE)$scenarios %||% list()
  generated <- Filter(keep_mode, generated)
  generated <- lapply(generated, apply_defaults, defaults = defaults)
  scenarios <- c(scenarios, generated)
}

out <- list(defaults = defaults, scenarios = scenarios)
jsonlite::write_json(out, out_path, auto_unbox = TRUE, pretty = TRUE)
RS

SCENARIO_COUNT="$(jq '.scenarios | length' "$RESOLVED")"
if [[ "$SCENARIO_COUNT" -le 0 ]]; then
  die "No scenarios resolved for mode=$MODE include_docs=$INCLUDE_DOCS include_generated=$INCLUDE_GENERATED"
fi

log "Resolved scenarios: $SCENARIO_COUNT"

SESSION_PREFIX="pw-${RUN_ID: -5}"

: > "$RUN_DIR/results.ndjson"

for ((i = 0; i < SCENARIO_COUNT; i++)); do
  SESSION="${SESSION_PREFIX}-${i}"
  scenario_json="$(jq -c ".scenarios[$i]" "$RESOLVED")"
  scenario_id_raw="$(jq -r '.id' <<<"$scenario_json")"
  scenario_id="$(printf '%s' "$scenario_id_raw" | tr -cs 'A-Za-z0-9._-' '_')"
  source_type="$(jq -r '.source_type' <<<"$scenario_json")"
  url_path="$(jq -r '.url_path' <<<"$scenario_json")"

  if [[ "$source_type" == "docs" ]]; then
    [[ -n "$DOCS_BASE_URL" ]] || die "Scenario '$scenario_id_raw' requires docs server, but docs are disabled"
    scenario_url="$DOCS_BASE_URL$url_path"
    local_path="${DOCS_ROOT%/}${url_path}"
  else
    [[ -n "$GENERATED_BASE_URL" ]] || die "Scenario '$scenario_id_raw' requires generated server, but generated are disabled"
    scenario_url="$GENERATED_BASE_URL$url_path"
    local_path="${RUN_DIR}/generated_site${url_path}"
  fi

  local_file_url="file://$local_path"
  runtime_json="$(jq -c \
    --arg url "$scenario_url" \
    --arg local_file_url "$local_file_url" \
    --arg local_file_path "$local_path" \
    '. + {url: $url, local_file_url: $local_file_url, local_file_path: $local_file_path}' <<<"$scenario_json")"

  scenario_js_escaped="$({
    SCENARIO_JSON="$runtime_json" python3 - <<'PY'
import os
s = os.environ['SCENARIO_JSON']
s = s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
print(s)
PY
  })"

  check_code="$({
    SCENARIO_ESCAPED="$scenario_js_escaped" CHECK_TEMPLATE="$SCRIPT_DIR/check_page.js" python3 - <<'PY'
import os
template_path = os.environ["CHECK_TEMPLATE"]
scenario_escaped = os.environ["SCENARIO_ESCAPED"]
with open(template_path, "r", encoding="utf-8") as f:
    template = f.read()
print(template.replace("__SCENARIO_JSON__", scenario_escaped))
PY
  })"

  log "[$((i + 1))/$SCENARIO_COUNT] $scenario_id_raw"

  OPEN_ARGS=(--session "$SESSION" open about:blank)
  if [[ "$HEADLESS" == "false" ]]; then
    OPEN_ARGS+=(--headed)
  fi
  "$PWCLI" "${OPEN_ARGS[@]}" >/dev/null

  run_log="$RUN_DIR/logs/${scenario_id}.run-code.log"
  run_exit=0
  if ! run_output="$("$PWCLI" --session "$SESSION" run-code "$check_code" 2>&1)"; then
    run_exit=$?
  fi
  printf '%s\n' "$run_output" > "$run_log"

  result_line="$(awk '/^### Result$/ {getline; print; exit}' <<<"$run_output" || true)"

  if [[ -z "$result_line" ]] || ! jq -e . >/dev/null 2>&1 <<<"$result_line"; then
    result_json="$(jq -n \
      --arg id "$scenario_id_raw" \
      --arg backend "$(jq -r '.backend // ""' <<<"$scenario_json")" \
      --arg source "$source_type" \
      --arg url "$scenario_url" \
      --arg local_file_url "$local_file_url" \
      --arg local_file_path "$local_path" \
      --arg msg "Playwright run-code did not return valid JSON result" \
      '{id:$id, backend:$backend, source_type:$source, url:$url, local_file_url:$local_file_url, local_file_path:$local_file_path, failures:[$msg], status:"fail"}')"
  else
    result_json="$result_line"
  fi

  if [[ "$run_exit" -ne 0 ]]; then
    result_json="$(jq --arg msg "run-code exited with status $run_exit" \
      '.failures = ((.failures // []) + [$msg]) | .status = "fail"' <<<"$result_json")"
  fi

  screenshot_rel=""
  ss_output="$("$PWCLI" --session "$SESSION" screenshot 2>&1 || true)"
  printf '%s\n' "$ss_output" > "$RUN_DIR/logs/${scenario_id}.screenshot.log"
  ss_src_rel="$(printf '%s\n' "$ss_output" | grep -oE '\.playwright-cli/page-[^)]+\.png' | tail -n 1 || true)"
  if [[ -n "$ss_src_rel" && -f "$ROOT/$ss_src_rel" ]]; then
    screenshot_rel="screenshots/${scenario_id}.png"
    cp "$ROOT/$ss_src_rel" "$RUN_DIR/$screenshot_rel"
  else
    result_json="$(jq --arg msg "Screenshot capture failed" '.failures = ((.failures // []) + [$msg]) | .status = "fail"' <<<"$result_json")"
  fi

  console_rel=""
  con_output="$("$PWCLI" --session "$SESSION" console 2>&1 || true)"
  printf '%s\n' "$con_output" > "$RUN_DIR/logs/${scenario_id}.console.log"
  con_src_rel="$(printf '%s\n' "$con_output" | grep -oE '\.playwright-cli/console-[^)]+\.log' | tail -n 1 || true)"
  if [[ -n "$con_src_rel" && -f "$ROOT/$con_src_rel" ]]; then
    console_rel="console/${scenario_id}.log"
    cp "$ROOT/$con_src_rel" "$RUN_DIR/$console_rel"
  fi

  forbid_patterns=()
  while IFS= read -r pat; do
    [[ -n "$pat" ]] || continue
    forbid_patterns+=("$pat")
  done < <(jq -r ".defaults.forbidden_console_patterns[]?, .scenarios[$i].forbidden_console_patterns[]?" "$RESOLVED" | awk 'NF' | sort -u)
  if [[ -n "$console_rel" && -f "$RUN_DIR/$console_rel" ]]; then
    for pat in "${forbid_patterns[@]}"; do
      if [[ -n "$pat" ]] && grep -Fqi -- "$pat" "$RUN_DIR/$console_rel"; then
        result_json="$(jq --arg msg "Forbidden console pattern matched: $pat" \
          '.failures = ((.failures // []) + [$msg]) | .status = "fail"' <<<"$result_json")"
      fi
    done
  fi

  result_json="$(jq \
    --arg screenshot "$screenshot_rel" \
    --arg console "$console_rel" \
    --arg run_log "logs/${scenario_id}.run-code.log" \
    '.screenshot = $screenshot
     | .console_log = $console
     | .run_log = $run_log
     | .failures = (.failures // [])
     | .status = (if ((.failures | length) > 0) then "fail" else (.status // "pass") end)' <<<"$result_json")"

  printf '%s\n' "$result_json" >> "$RUN_DIR/results.ndjson"
  "$PWCLI" --session "$SESSION" close >/dev/null 2>&1 || true
done

FINISHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
jq -s \
  --arg run_id "$RUN_ID" \
  --arg mode "$MODE" \
  --arg started_at "$STARTED_AT" \
  --arg finished_at "$FINISHED_AT" \
  --argjson include_docs "$INCLUDE_DOCS" \
  --argjson include_generated "$INCLUDE_GENERATED" \
  '{
    run_id: $run_id,
    mode: $mode,
    started_at: $started_at,
    finished_at: $finished_at,
    include_docs: $include_docs,
    include_generated: $include_generated,
    results: .
  }' "$RUN_DIR/results.ndjson" > "$RUN_DIR/results.json"

Rscript "$SCRIPT_DIR/render_report.R" \
  --results "$RUN_DIR/results.json" \
  --output "$RUN_DIR/report.html" \
  --run_id "$RUN_ID"

RUNNING_STATUS_JSON="$ROOT/output/playwright/running-status.json"
RUNNING_STATUS_MD="$ROOT/output/playwright/running-status.md"
RUNNING_STATUS_HTML="$ROOT/output/playwright/running-status.html"

Rscript "$SCRIPT_DIR/update_running_status.R" \
  --results "$RUN_DIR/results.json" \
  --status_json "$RUNNING_STATUS_JSON" \
  --status_md "$RUNNING_STATUS_MD" \
  --status_html "$RUNNING_STATUS_HTML"

LATEST_DIR="$ROOT/output/playwright"
LATEST_LINK="$LATEST_DIR/latest"
LATEST_REPORT="$LATEST_DIR/latest-report.html"
LATEST_RESULTS="$LATEST_DIR/latest-results.json"

ln -sfn "$RUN_DIR" "$LATEST_LINK"
cp "$RUN_DIR/report.html" "$LATEST_REPORT"
cp "$RUN_DIR/results.json" "$LATEST_RESULTS"

FAIL_COUNT="$(jq '[.results[] | select(.status != "pass")] | length' "$RUN_DIR/results.json")"
PASS_COUNT="$(jq '[.results[] | select(.status == "pass")] | length' "$RUN_DIR/results.json")"

log "Pass: $PASS_COUNT"
log "Fail: $FAIL_COUNT"
log "Results: $RUN_DIR/results.json"
log "Report:  $RUN_DIR/report.html"
log "Latest:  $LATEST_LINK/report.html"
log "Status:  $RUNNING_STATUS_HTML"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
