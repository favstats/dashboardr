# Tests for page_generation.R internal functions — lightweight, covr-safe
# These test code-generation helpers that produce strings (no HTML rendering)
library(testthat)

# Access internal functions
.generate_data_load_code <- dashboardr:::.generate_data_load_code

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
