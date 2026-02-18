#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
check_mode <- "--check" %in% args

canonical_dir <- file.path("inst", "assets")

managed_mirrors <- list(
  "dev/showwhen/assets" = c(
    "choices.min.css", "choices.min.js", "filter_hook.js", "input_filter.css",
    "input_filter.js", "linked_inputs.js", "modal.css", "modal.js",
    "pagination.css", "show_when.js", "sidebar.css", "tab-scroll-fix.js"
  ),
  "inst/tutorial_dashboard/assets" = c(
    "modal.css", "modal.js", "pagination.css"
  )
)

hash_file <- function(path) {
  unname(tools::md5sum(path))
}

changes <- list()

for (mirror in names(managed_mirrors)) {
  files <- managed_mirrors[[mirror]]
  dir.create(mirror, recursive = TRUE, showWarnings = FALSE)

  for (fname in files) {
    src <- file.path(canonical_dir, fname)
    dst <- file.path(mirror, fname)

    if (!file.exists(src)) {
      stop(sprintf("Canonical asset missing: %s", src), call. = FALSE)
    }

    needs_update <- !file.exists(dst) || !identical(hash_file(src), hash_file(dst))
    if (needs_update) {
      changes[[length(changes) + 1]] <- c(src = src, dst = dst)
      if (!check_mode) {
        ok <- file.copy(src, dst, overwrite = TRUE)
        if (!ok) {
          stop(sprintf("Failed to copy %s -> %s", src, dst), call. = FALSE)
        }
      }
    }
  }
}

if (length(changes) == 0) {
  cat("Asset sync: already up to date.\n")
  quit(status = 0)
}

if (check_mode) {
  cat("Asset sync check failed: drift detected in managed mirrors.\n")
  for (chg in changes) {
    cat(sprintf(" - %s -> %s\n", chg[["src"]], chg[["dst"]]))
  }
  cat("Run: Rscript scripts/sync_assets.R\n")
  quit(status = 1)
}

cat(sprintf("Asset sync complete: updated %d file(s).\n", length(changes)))
for (chg in changes) {
  cat(sprintf(" - %s -> %s\n", chg[["src"]], chg[["dst"]]))
}
