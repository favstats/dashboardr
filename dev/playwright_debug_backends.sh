#!/usr/bin/env bash
set -euo pipefail

# Simple Playwright CLI run to open the backends page, capture a snapshot,
# console log, and screenshot for debugging chart rendering.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Prefer the built docs sibling at ../here/docs (where the static HTML lives)
# and fall back to a local ./here/docs directory if that exists instead.
if [ -d "$ROOT/../here/docs" ]; then
  DOCS_DIR="$ROOT/../here/docs"
else
  DOCS_DIR="$ROOT/here/docs"
fi
PORT="${PORT:-8010}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required for the Playwright wrapper; please install Node.js/npm." >&2
  exit 1
fi

if [ ! -x "$PWCLI" ]; then
  echo "Playwright CLI wrapper not found at: $PWCLI" >&2
  exit 1
fi

echo "Starting local static server from $DOCS_DIR on port $PORT..."
python3 -m http.server "$PORT" --directory "$DOCS_DIR" >/tmp/dashboardr_playwright_http.log 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID"' EXIT

PAGE_URL="http://localhost:$PORT/backends___show_when.html"

echo "Opening $PAGE_URL in headed Chrome via Playwright..."
"$PWCLI" open "$PAGE_URL" --headed

echo "Taking fresh snapshot..."
"$PWCLI" snapshot

echo "Capturing screenshot..."
"$PWCLI" screenshot

LATEST_CONSOLE_LOG="$(ls -t "$ROOT"/.playwright-cli/console-*.log | head -n 1)"
LATEST_SCREENSHOT="$(ls -t "$ROOT"/.playwright-cli/page-*.png | head -n 1)"

echo "Latest console log: $LATEST_CONSOLE_LOG"
echo "Latest screenshot : $LATEST_SCREENSHOT"
echo "Done. Server log: /tmp/dashboardr_playwright_http.log"
