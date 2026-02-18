# Tests for page_generation.R internal functions — lightweight, covr-safe
# These test code-generation helpers that produce strings (no HTML rendering)
library(testthat)

# Access internal functions
.generate_data_load_code <- dashboardr:::.generate_data_load_code
.make_rds_bundle_ref <- dashboardr:::.make_rds_bundle_ref

# --- .generate_data_load_code ---

test_that(".generate_data_load_code local RDS", {
  code <- .generate_data_load_code("data/survey.rds")
  expect_true(grepl("readRDS", code))
  expect_true(grepl("survey.rds", code))
})
  
test_that(".generate_data_load_code local parquet", {
  code <- .generate_data_load_code("data/survey.parquet")
  expect_true(grepl("arrow::read_parquet", code))
  expect_true(grepl("survey.parquet", code))
})

test_that(".generate_data_load_code remote RDS (URL)", {
  code <- .generate_data_load_code("https://example.com/data.rds")
  expect_true(grepl("readRDS", code))
  expect_true(grepl("gzcon", code))
  expect_true(grepl("url", code))
})

test_that(".generate_data_load_code remote parquet (URL)", {
  code <- .generate_data_load_code("https://example.com/data.parquet")
  expect_true(grepl("arrow::read_parquet", code))
  expect_true(grepl("https://example.com", code))
})

test_that(".generate_data_load_code custom var_name", {
  code <- .generate_data_load_code("data/survey.rds", var_name = "my_data")
  expect_true(grepl("my_data <-", code))
})

test_that(".generate_data_load_code case insensitive parquet", {
  code <- .generate_data_load_code("data/survey.PARQUET")
  expect_true(grepl("arrow::read_parquet", code))
})

test_that(".generate_data_load_code bundled RDS reference", {
  bundle_ref <- .make_rds_bundle_ref(
    bundle_file = "dashboard_data_bundle.rds",
    bundle_key = "dataset_small_10obs.rds"
  )
  code <- .generate_data_load_code(bundle_ref, var_name = "survey_data")
  expect_true(any(grepl("\\.dashboardr_bundle_cache", code)))
  expect_true(any(grepl("dashboard_data_bundle\\.rds", code)))
  expect_true(any(grepl("dataset_small_10obs\\.rds", code)))
  expect_true(any(grepl("survey_data <-", code)))
})

test_that(".generate_global_setup_chunk loads externalized table filter data", {
  .generate_global_setup_chunk <- dashboardr:::.generate_global_setup_chunk

  page <- list(
    data_path = "dataset_small_10obs.rds",
    visualizations = NULL,
    content_blocks = list(
      structure(list(
        type = "reactable",
        table_file = "table_obj_1.rds",
        table_var = "table_obj_1",
        table_filter_data_file = "table_filter_data_1.rds",
        table_filter_data_var = "table_filter_data_1"
      ), class = "content_block")
    ),
    needs_show_when = FALSE
  )

  setup_lines <- .generate_global_setup_chunk(page)
  setup_text <- paste(setup_lines, collapse = "\n")

  expect_true(grepl("table_obj_1 <- readRDS\\('table_obj_1\\.rds'\\)", setup_text))
  expect_true(grepl("table_filter_data_1 <- readRDS\\('table_filter_data_1\\.rds'\\)", setup_text))
})

test_that("DT/reactable generators reference filter data variable when present", {
  .generate_DT_block <- dashboardr:::.generate_DT_block
  .generate_reactable_block <- dashboardr:::.generate_reactable_block

  dt_lines <- .generate_DT_block(list(
    type = "DT",
    table_var = "table_obj_2",
    filter_vars = c("region"),
    table_filter_data_var = "table_filter_data_2"
  ))
  dt_text <- paste(dt_lines, collapse = "\n")
  expect_true(grepl("data = table_filter_data_2", dt_text, fixed = TRUE))
  expect_false(grepl("as\\.data\\.frame\\(list\\(", dt_text))

  react_lines <- .generate_reactable_block(list(
    type = "reactable",
    table_var = "table_obj_3",
    filter_vars = c("region"),
    table_filter_data_var = "table_filter_data_3"
  ))
  react_text <- paste(react_lines, collapse = "\n")
  expect_true(grepl("data = table_filter_data_3", react_text, fixed = TRUE))
  expect_false(grepl("as\\.data\\.frame\\(list\\(", react_text))
})
