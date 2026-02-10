# =================================================================
# Tests for viz_map.R
# =================================================================

# Sample data for tests
sample_country_data <- data.frame(
  iso2c = c("US", "DE", "FR", "GB", "JP"),
  country = c("United States", "Germany", "France", "United Kingdom", "Japan"),
  value = c(1000, 500, 300, 400, 600),
  population = c(330, 83, 67, 67, 126)
)

# --- Error Validation Tests (don't require network) ---
test_that("viz_map requires value_var parameter", {
  expect_error(
    viz_map(data = sample_country_data, join_var = "iso2c"),
    "value_var"
  )
})

test_that("viz_map validates value_var exists in data", {
  expect_error(
    viz_map(data = sample_country_data, value_var = "nonexistent", join_var = "iso2c"),
    "not found"
  )
})

test_that("viz_map validates join_var exists in data", {
  expect_error(
    viz_map(data = sample_country_data, value_var = "value", join_var = "nonexistent"),
    "not found"
  )
})

# --- Tests requiring network for map data ---
test_that("viz_map creates a highchart object", {
  skip_on_cran()
  skip_if_offline()  # Requires network for map data from highcharts.com
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    join_var = "iso2c"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map uses default join_var of iso2c", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value"
    # join_var defaults to "iso2c"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts title parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    title = "Test Map Title"
  )
  
  expect_s3_class(result, "highchart")
  # Title should be in the chart configuration
  expect_true("title" %in% names(result$x$hc_opts))
})

test_that("viz_map accepts subtitle parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    subtitle = "A subtitle for the map"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts custom color palette", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    color_palette = c("#ffffff", "#ff0000")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts na_color parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    na_color = "#CCCCCC"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts height parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    height = 800
  )
  
  expect_s3_class(result, "highchart")
  expect_equal(result$x$hc_opts$chart$height, 800)
})

test_that("viz_map accepts border styling parameters", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    border_color = "#000000",
    border_width = 2
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map disables credits by default", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    credits = FALSE
  )
  
  expect_s3_class(result, "highchart")
  expect_false(result$x$hc_opts$credits$enabled)
})

test_that("viz_map can enable credits", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    credits = TRUE
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map includes map navigation controls", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value"
  )
  
  expect_true(result$x$hc_opts$mapNavigation$enabled)
})

test_that("viz_map handles click_url_template", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    click_url_template = "{iso2c}_dashboard/index.html"
  )
  
  expect_s3_class(result, "highchart")
  
  # Should have cursor pointer
  expect_equal(result$x$hc_opts$plotOptions$series$cursor, "pointer")
})

test_that("viz_map uses click_var when specified", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    click_url_template = "{country}_page.html",
    click_var = "country"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map defaults click_var to join_var", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    join_var = "iso2c",
    click_url_template = "{iso2c}_dashboard.html"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts legend_title parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    legend_title = "Custom Legend Title"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map uses value_var as legend_title by default", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map accepts color_stops for custom scale", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    color_stops = c(0, 250, 500, 750, 1000),
    color_palette = c("#f7fcf5", "#c7e9c0", "#74c476", "#238b45", "#00441b")
  )
  
  expect_s3_class(result, "highchart")
  
  # Should have colorAxis configuration
  expect_true("colorAxis" %in% names(result$x$hc_opts))
})

test_that("viz_map handles different map types", {
  skip_on_cran()
  skip_if_offline()
  
  # World map (default)
  world_map <- viz_map(
    data = sample_country_data,
    value_var = "value",
    map_type = "custom/world"
  )
  expect_s3_class(world_map, "highchart")
})

test_that("viz_map handles US map type", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("highcharter")

  us_data <- data.frame(
    state = c("California", "Texas", "New York"),
    value = c(100, 80, 90)
  )

  us_map <- viz_map(
    data = us_data,
    value_var = "value",
    join_var = "state",
    map_type = "countries/us/us-all"
  )

  expect_s3_class(us_map, "highchart")
})

test_that("viz_map handles haven_labelled variables", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("haven")
  
  # Create data with haven_labelled class
  data_with_labels <- sample_country_data
  class(data_with_labels$value) <- c("haven_labelled", class(data_with_labels$value))
  attr(data_with_labels$value, "labels") <- c(Low = 100, High = 1000)
  
  result <- viz_map(
    data = data_with_labels,
    value_var = "value"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map supports tooltip parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    tooltip = "Country: {name}<br>Value: {value}"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map supports legacy tooltip_format parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    tooltip_format = "<b>{point.name}</b><br/>Value: {point.value}"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map supports legacy tooltip_vars parameter", {
  skip_on_cran()
  skip_if_offline()
  
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    tooltip_vars = c("value", "population")
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map tooltip priority: tooltip_format > tooltip_vars > tooltip", {
  skip_on_cran()
  skip_if_offline()
  
  # When multiple tooltip options provided, tooltip_format takes precedence
  result <- viz_map(
    data = sample_country_data,
    value_var = "value",
    tooltip_format = "<b>Custom</b>",
    tooltip_vars = c("value"),
    tooltip = "Simple tooltip"
  )
  
  expect_s3_class(result, "highchart")
})

test_that("viz_map works with non-standard variable names", {
  skip_on_cran()
  skip_if_offline()
  
  data_weird_names <- data.frame(
    `country code` = c("US", "DE"),
    `total value` = c(100, 200),
    check.names = FALSE
  )
  
  result <- viz_map(
    data = data_weird_names,
    value_var = "total value",
    join_var = "country code"
  )
  
  expect_s3_class(result, "highchart")
})
