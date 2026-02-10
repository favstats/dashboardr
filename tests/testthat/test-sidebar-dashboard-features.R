# =============================================================================
# Tests for Sidebar Dashboard Features (v0.2.1)
# =============================================================================
#
# Tests for:
# 1. color_palette named vector support (viz_timeline, viz_stackedbar)
# 2. group_order parameter (viz_timeline)
# 3. title_map parameter (viz_timeline, viz_stackedbar)
# 4. show_when conditional visibility
# 5. .serialize_arg() named vector handling
# 6. Demo dashboard generation
# =============================================================================

library(testthat)
library(dashboardr)

# Skip entire file under covr CI to prevent OOM (exit code 143)
if (identical(Sys.getenv("DASHBOARDR_COVR_CI"), "true") || !identical(Sys.getenv("NOT_CRAN"), "true")) {
  # skipped on CRAN/covr CI
} else {

# =============================================================================
# SECTION 1: color_palette — Named Vector Support
# =============================================================================

describe("color_palette with named vectors", {

  # Simple test data
  make_data <- function() {
    data.frame(
      year = rep(2020:2022, each = 3),
      group = rep(c("A", "B", "C"), 3),
      value = runif(9, 10, 90),
      stringsAsFactors = FALSE
    )
  }

  it("viz_timeline accepts named color_palette without error", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      color_palette = c("A" = "#E15759", "B" = "#4E79A7", "C" = "#F28E2B")
    )
    expect_s3_class(hc, "highchart")
  })

  it("viz_timeline accepts unnamed color_palette (backwards compat)", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      color_palette = c("#E15759", "#4E79A7", "#F28E2B")
    )
    expect_s3_class(hc, "highchart")
  })

  it("named color_palette assigns correct colors to series in timeline", {
    d <- make_data()
    colors <- c("A" = "#E15759", "B" = "#4E79A7", "C" = "#F28E2B")
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      color_palette = colors
    )
    # Check that series have the correct colors assigned
    series_list <- hc$x$hc_opts$series
    series_names <- vapply(series_list, function(s) s$name, character(1))
    series_colors <- vapply(series_list, function(s) s$color %||% NA_character_, character(1))
    for (nm in names(colors)) {
      idx <- which(series_names == nm)
      if (length(idx) > 0) {
        expect_equal(series_colors[idx[1]], unname(colors[nm]),
                     info = paste("Color for series", nm))
      }
    }
  })

  it("viz_stackedbar accepts named color_palette without error", {
    d <- data.frame(
      x = rep(c("Q1", "Q2"), each = 3),
      stack = rep(c("A", "B", "C"), 2),
      n = c(10, 20, 30, 15, 25, 35),
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data = d,
      x_var = "x",
      stack_var = "stack",
      y_var = "n",
      color_palette = c("A" = "#E15759", "B" = "#4E79A7", "C" = "#F28E2B")
    )
    expect_s3_class(hc, "highchart")
  })
})

# =============================================================================
# SECTION 2: group_order parameter
# =============================================================================

describe("group_order in viz_timeline", {

  make_data <- function() {
    data.frame(
      year = rep(2020:2022, each = 3),
      group = rep(c("C", "A", "B"), 3),
      value = c(10, 20, 30, 15, 25, 35, 12, 22, 32),
      stringsAsFactors = FALSE
    )
  }

  it("respects group_order for series ordering", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      group_order = c("A", "B", "C")
    )
    series_names <- vapply(hc$x$hc_opts$series, function(s) s$name, character(1))
    expect_equal(series_names, c("A", "B", "C"))
  })

  it("without group_order uses data order", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none"
    )
    series_names <- vapply(hc$x$hc_opts$series, function(s) s$name, character(1))
    # Default order is based on unique() of the data — C, A, B
    expect_equal(series_names, c("C", "A", "B"))
  })

  it("group_order filters to existing groups only", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      group_order = c("Z", "B", "A", "X")  # Z and X don't exist
    )
    series_names <- vapply(hc$x$hc_opts$series, function(s) s$name, character(1))
    expect_equal(series_names, c("B", "A"))
  })
})

# =============================================================================
# SECTION 3: title_map parameter
# =============================================================================

describe("title_map in viz_timeline", {

  make_data <- function() {
    data.frame(
      year = rep(2020:2022, each = 2),
      group = rep(c("Male", "Female"), 3),
      value = runif(6, 30, 80),
      question = "Marijuana Legalization",
      stringsAsFactors = FALSE
    )
  }

  it("accepts title_map with named vector (simple format)", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      title = "% {key_response} by group",
      title_map = list(
        key_response = c("Marijuana Legalization" = "Legal", "Death Penalty" = "Favor")
      ),
      cross_tab_filter_vars = c("question")
    )
    expect_s3_class(hc, "highchart")
    # Check that titleLookups is embedded in config
    config <- attr(hc, "cross_tab_config")
    expect_true(!is.null(config$titleLookups))
    expect_true("key_response" %in% names(config$titleLookups))
    expect_equal(config$titleLookups$key_response$values[["Marijuana Legalization"]], "Legal")
    # Should NOT have inputVar (auto-detect on JS side)
    expect_null(config$titleLookups$key_response$inputVar)
  })

  it("embeds titleTemplate when title has placeholders", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      title = "{question}: % {key_response}",
      cross_tab_filter_vars = c("question")
    )
    config <- attr(hc, "cross_tab_config")
    expect_equal(config$titleTemplate, "{question}: % {key_response}")
  })
})

describe("title_map in viz_stackedbar", {

  it("accepts title_map with named vector", {
    d <- data.frame(
      x = rep(c("Q1", "Q2"), each = 2),
      stack = rep(c("A", "B"), 2),
      n = c(10, 20, 15, 25),
      question = "Test",
      stringsAsFactors = FALSE
    )
    hc <- viz_stackedbar(
      data = d,
      x_var = "x",
      stack_var = "stack",
      y_var = "n",
      title = "% {key_response}",
      title_map = list(key_response = c("Test" = "Yes")),
      cross_tab_filter_vars = c("question")
    )
    expect_s3_class(hc, "highchart")
    config <- attr(hc, "cross_tab_config")
    expect_true(!is.null(config$titleLookups))
  })
})

# =============================================================================
# SECTION 4: .serialize_arg() named vector handling
# =============================================================================

describe(".serialize_arg named vectors", {

  serialize <- dashboardr:::.serialize_arg

  it("serializes named character vectors with correct syntax", {
    result <- serialize(c("A" = "X", "B" = "Y"))
    # Should produce: c("A" = "X", "B" = "Y")
    expect_match(result, '"A"\\s*=\\s*"X"')
    expect_match(result, '"B"\\s*=\\s*"Y"')
    # Should be valid R
    expect_silent(parse(text = result))
  })

  it("serializes unnamed character vectors without names", {
    result <- serialize(c("X", "Y"))
    # Should produce: c("X", "Y")
    expect_false(grepl("=", result))
    expect_silent(parse(text = result))
  })

  it("serializes list with named vector values", {
    result <- serialize(list(key = c("A" = "X", "B" = "Y")))
    expect_match(result, "list")
    expect_match(result, "key")
    expect_silent(parse(text = result))
  })
})

# =============================================================================
# SECTION 5: cross-tab config embedding
# =============================================================================

describe("cross-tab config includes color and group info", {

  make_data <- function() {
    data.frame(
      year = rep(2020:2022, each = 3),
      group = rep(c("A", "B", "C"), 3),
      value = runif(9, 10, 90),
      dim = "Test",
      stringsAsFactors = FALSE
    )
  }

  it("groupOrder is embedded in timeline config", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      group_order = c("C", "B", "A"),
      cross_tab_filter_vars = c("dim")
    )
    config <- attr(hc, "cross_tab_config")
    expect_equal(unlist(config$groupOrder), c("C", "B", "A"))
  })

  it("colorMap is embedded in timeline config when named palette used", {
    d <- make_data()
    colors <- c("A" = "#111", "B" = "#222", "C" = "#333")
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      color_palette = colors,
      cross_tab_filter_vars = c("dim")
    )
    config <- attr(hc, "cross_tab_config")
    expect_equal(config$colorMap$A, "#111")
    expect_equal(config$colorMap$B, "#222")
  })

  it("colorMap is NULL in config when unnamed palette used", {
    d <- make_data()
    hc <- viz_timeline(
      data = d,
      time_var = "year",
      y_var = "value",
      group_var = "group",
      agg = "none",
      color_palette = c("#111", "#222", "#333"),
      cross_tab_filter_vars = c("dim")
    )
    config <- attr(hc, "cross_tab_config")
    expect_null(config$colorMap)
  })
})

# =============================================================================
# SECTION 6: Demo dashboard generation
# =============================================================================

describe("sidebar demo dashboard generation", {

  it("demo script generates without errors", {
    skip_if_not_installed("gssr")
    skip_on_cran()

    # Find the demo script relative to the package root
    demo_script <- file.path(testthat::test_path(), "..", "..", "dev", "demo_sidebar_dashboard.R")
    skip_if(!file.exists(demo_script), "demo_sidebar_dashboard.R not found")

    # Normalize to absolute path before changing working directory
    demo_script <- normalizePath(demo_script)

    # Use a temp working directory so the hardcoded "11111" output_dir
    # from create_dashboard() lands inside it
    temp_dir <- tempfile("demo_test")
    dir.create(temp_dir, recursive = TRUE)
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    old_wd <- setwd(temp_dir)
    on.exit(setwd(old_wd), add = TRUE)

    # Read the demo script and strip devtools::load_all() — package is already
    # loaded during testing, and the temp dir has no DESCRIPTION file
    script_lines <- readLines(demo_script)
    script_lines <- script_lines[!grepl("^devtools::load_all", script_lines)]
    script_text <- paste(script_lines, collapse = "\n")

    env <- new.env(parent = globalenv())
    capture.output(
      suppressWarnings(eval(parse(text = script_text), envir = env)),
      type = "message"
    )

    # The demo creates dashboard in "11111/" sub-directory
    output_subdir <- file.path(temp_dir, "11111")
    qmd_files <- if (dir.exists(output_subdir)) {
      list.files(output_subdir, pattern = "\\.qmd$")
    } else {
      # Fallback: check all subdirectories
      list.files(temp_dir, pattern = "\\.qmd$", recursive = TRUE)
    }
    expect_true(length(qmd_files) > 0)
  })
})

} # end covr CI skip
