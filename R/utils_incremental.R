# =================================================================
# Incremental Build Utilities
# =================================================================
#
# dashboardr can skip re-rendering pages whose content hasn't changed
# since the last build. This file provides the hashing and manifest
# persistence layer that makes incremental builds possible.
#
# How it works:
#   1. Before rendering, each page's configuration is hashed (xxhash64).
#   2. Hashes are compared against a manifest (.dashboardr_manifest.rds)
#      saved in the output directory from the previous build.
#   3. Pages whose hash matches the manifest are skipped; only changed
#      or new pages are re-rendered by Quarto.
#   4. After a successful build the manifest is updated with new hashes.
#
# The manifest is a simple list:
#   list(pages = list(page_name = list(hash = "...")))
#
# Called from: dashboard_generation.R during the build pipeline.
# =================================================================

#' Compute a fast hash of an arbitrary R object
#'
#' Uses xxhash64 for speed — suitable for change-detection, not
#' cryptographic purposes.
#'
#' @param obj Any R object (typically a page configuration list).
#' @return Character string hash.
#' @keywords internal
.compute_hash <- function(obj) {
  digest::digest(obj, algo = "xxhash64")
}

#' Save the build manifest to disk
#'
#' Writes the manifest (a list of page hashes) as an RDS file inside
#' the output directory so it persists across builds.
#'
#' @param manifest List with a `pages` element mapping page names to hashes.
#' @param output_dir Path to the dashboard output directory.
#' @keywords internal
.save_manifest <- function(manifest, output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  saveRDS(manifest, manifest_file)
}

#' Load a previously saved build manifest
#'
#' Returns NULL if no manifest exists (i.e. first build).
#'
#' @param output_dir Path to the dashboard output directory.
#' @return The manifest list, or NULL.
#' @keywords internal
.load_manifest <- function(output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  if (file.exists(manifest_file)) {
    return(readRDS(manifest_file))
  }
  NULL
}

#' Check whether a page needs to be rebuilt
#'
#' Compares the current page configuration hash against the stored
#' manifest hash. Returns TRUE when:
#'   - No manifest exists (first build)
#'   - The page is new (not in the manifest)
#'   - The page's hash has changed
#'
#' @param page_name Character scalar — the page identifier.
#' @param page_config The page configuration list to hash.
#' @param manifest The manifest list from `.load_manifest()`, or NULL.
#' @return Logical: TRUE if the page should be re-rendered.
#' @keywords internal
.needs_rebuild <- function(page_name, page_config, manifest) {
  if (is.null(manifest) || is.null(manifest$pages)) {
    return(TRUE)  # First build — everything must render
  }

  if (!page_name %in% names(manifest$pages)) {
    return(TRUE)  # New page not seen before
  }

  old_hash <- manifest$pages[[page_name]]$hash
  new_hash <- .compute_hash(page_config)

  return(old_hash != new_hash)
}
