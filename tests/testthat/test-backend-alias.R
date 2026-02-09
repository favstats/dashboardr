library(testthat)

test_that("normalize backend accepts echarts alias silently by default", {
  expect_no_warning({
    normalized <- dashboardr:::.normalize_backend("echarts")
    expect_identical(normalized, "echarts4r")
  })
})

test_that("normalize backend can still warn on alias when requested", {
  expect_warning(
    dashboardr:::.normalize_backend("echarts", warn_alias = TRUE),
    "alias for 'echarts4r'"
  )
})

test_that("create_dashboard accepts backend = 'echarts' alias", {
  d <- expect_no_warning(
    create_dashboard(
      output_dir = tempfile("dash_backend_alias_"),
      backend = "echarts"
    )
  )

  expect_identical(d$backend, "echarts4r")
})
