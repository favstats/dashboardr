# =================================================================
# utils_incremental
# =================================================================

.compute_hash <- function(obj) {
  digest::digest(obj, algo = "xxhash64")
}

.save_manifest <- function(manifest, output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  saveRDS(manifest, manifest_file)
}

.load_manifest <- function(output_dir) {
  manifest_file <- file.path(output_dir, ".dashboardr_manifest.rds")
  if (file.exists(manifest_file)) {
    return(readRDS(manifest_file))
  }
  NULL
}

.needs_rebuild <- function(page_name, page_config, manifest) {
  if (is.null(manifest) || is.null(manifest$pages)) {
    return(TRUE)  # First build
  }
  
  if (!page_name %in% names(manifest$pages)) {
    return(TRUE)  # New page
  }
  
  old_hash <- manifest$pages[[page_name]]$hash
  new_hash <- .compute_hash(page_config)
  
  return(old_hash != new_hash)
}

