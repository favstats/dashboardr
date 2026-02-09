#!/usr/bin/env Rscript

run_git <- function(args) {
  out <- tryCatch(
    system2("git", args = args, stdout = TRUE, stderr = TRUE),
    error = function(e) character(0)
  )
  if (length(out) == 1 && identical(out, "")) character(0) else out
}

normalize_paths <- function(x) {
  x <- trimws(x)
  x <- x[nzchar(x)]
  gsub("\\\\", "/", x)
}

forbidden_patterns <- c(
  "^(22222|here|here_hc|here_plotly)/",
  "^dev/.*/docs/",
  "^dev/.*/site_libs/",
  "^dev/.*/\\.quarto/"
)

is_forbidden <- function(path) {
  any(vapply(forbidden_patterns, function(pat) grepl(pat, path, perl = TRUE), logical(1)))
}

detect_base_ref <- function() {
  event_name <- Sys.getenv("GITHUB_EVENT_NAME", unset = "")
  base_ref <- Sys.getenv("GITHUB_BASE_REF", unset = "")

  if (nzchar(base_ref) && identical(event_name, "pull_request")) {
    # Best-effort fetch so origin/<base_ref> exists in shallow CI clones.
    invisible(run_git(c("fetch", "--depth=1", "origin", base_ref)))
    return(sprintf("origin/%s", base_ref))
  }

  has_head_parent <- tryCatch(system2("git", c("rev-parse", "--verify", "HEAD~1"), stdout = FALSE, stderr = FALSE) == 0,
                              error = function(e) FALSE)
  if (isTRUE(has_head_parent)) "HEAD~1" else "HEAD"
}

base_ref <- detect_base_ref()
range_expr <- if (identical(base_ref, "HEAD")) "HEAD" else sprintf("%s...HEAD", base_ref)

changed <- normalize_paths(run_git(c("diff", "--name-only", "--diff-filter=ACMRD", range_expr)))
include_untracked <- identical(tolower(Sys.getenv("CI", unset = "false")), "true") ||
  identical(tolower(Sys.getenv("CHECK_ARTIFACTS_INCLUDE_UNTRACKED", unset = "false")), "true")
untracked <- if (include_untracked) {
  normalize_paths(run_git(c("ls-files", "--others", "--exclude-standard")))
} else {
  character(0)
}

candidates <- unique(c(changed, untracked))
blocked <- sort(candidates[vapply(candidates, is_forbidden, logical(1))])

if (length(blocked) > 0) {
  cat("Artifact policy violation: non-canonical generated paths detected.\n\n")
  cat("Blocked files:\n")
  cat(paste0(" - ", blocked), sep = "\n")
  cat("\n\nAllowed canonical output is root docs/ only.\n")
  quit(status = 1)
}

cat("Artifact policy check passed.\n")
