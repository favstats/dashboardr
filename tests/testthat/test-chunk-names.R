# Tests for meaningful R chunk names in generated QMD files
library(testthat)

test_that("chunk names use tabgroup as highest priority", {
  viz <- create_viz(
    type = "timeline",
    time_var = "year",
    response_var = "value"
  ) %>%
    add_viz(
      title = "Trend Over Time",
      tabgroup = "demographics/age/trend"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_tabgroup"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(year = 2020:2023, value = 1:4),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_text <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should have chunk named after tabgroup (sanitized)
  expect_true(grepl("```{r demographics-age-trend}", qmd_text, fixed = TRUE))
  
})

test_that("chunk names extract relevant variables for each viz type", {
  # Test multiple visualization types
  viz <- create_viz() %>%
    # Stackedbar: x_var + stack_var
    add_viz(
      type = "stackedbar",
      x_var = "satisfaction",
      stack_var = "department",
      title = "Satisfaction"
    ) %>%
    # Stackedbars: first question
    add_viz(
      type = "stackedbars",
      questions = c("q1_trust", "q2_safety"),
      title = "Survey"
    ) %>%
    # Timeline: response_var
    add_viz(
      type = "timeline",
      time_var = "year",
      response_var = "metric",
      title = "Timeline"
    ) %>%
    # Histogram: x_var
    add_viz(
      type = "histogram",
      x_var = "score",
      title = "Distribution"
    ) %>%
    # Heatmap: x_var (or y_var/value_var)
    add_viz(
      type = "heatmap",
      x_var = "country",
      y_var = "year",
      value_var = "population",
      title = "Heatmap"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_vartypes"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(
        satisfaction = 1:10,
        department = rep(c("A", "B"), 5),
        q1_trust = 1:10,
        q2_safety = 1:10,
        year = 2020:2029,
        metric = rnorm(10),
        score = rnorm(10),
        country = rep(c("US", "UK"), 5),
        population = rnorm(10, 1e6, 1e5)
      ),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_text <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Check each type uses appropriate variables
  expect_true(grepl("```{r stackedbar-satisfaction-department}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r stackedbars-q1-trust}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r timeline-metric}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r histogram-score}", qmd_text, fixed = TRUE))
  expect_true(grepl("```\\{r heatmap-(country|year|population)", qmd_text))
  
})

test_that("chunk names sanitize special characters", {
  viz <- create_viz(
    type = "timeline",
    time_var = "date",
    response_var = "metric"
  ) %>%
    add_viz(
      title = "Metric Trend",
      tabgroup = "section_A/sub.section/item#1"
    )
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_sanitize"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(date = 1:10, metric = rnorm(10)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_text <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Should sanitize: underscores, dots, hashes → dashes
  expect_true(grepl("```{r section-a-sub-section-item-1}", qmd_text, fixed = TRUE))
  
})

test_that("chunk names are unique and disambiguate duplicates", {
  # Create multiple visualizations with same variables/titles
  viz <- create_viz(
    type = "histogram",
    x_var = "value"
  ) %>%
    add_viz(title = "Chart 1", tabgroup = "analysis/main") %>%
    add_viz(title = "Chart 2", tabgroup = "analysis/main") %>%  # Duplicate tabgroup!
    add_viz(title = "My Chart") %>%
    add_viz(title = "My Chart") %>%  # Duplicate title -> duplicate variable-based label
    add_viz(title = "My Chart")      # Triple duplicate!
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_unique"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(value = rnorm(100)),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_text <- paste(readLines(qmd_file, warn = FALSE), collapse = "\n")
  
  # Duplicate tabgroups should get counters
  expect_true(grepl("```{r analysis-main}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r analysis-main-2}", qmd_text, fixed = TRUE))
  
  # Duplicate histogram-value labels should also get counters
  expect_true(grepl("```{r histogram-value}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r histogram-value-2}", qmd_text, fixed = TRUE))
  expect_true(grepl("```{r histogram-value-3}", qmd_text, fixed = TRUE))
  
})

test_that("chunk names are limited to reasonable length", {
  # Create a very long tabgroup path
  long_path <- paste(rep("verylongsectionname", 10), collapse = "/")
  
  viz <- create_viz(
    type = "timeline",
    time_var = "x",
    response_var = "y"
  ) %>%
    add_viz(title = "Long Path", tabgroup = long_path)
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_long"),
    title = "Test"
  ) %>%
    add_page(
      "Analysis",
      data = data.frame(x = 1:10, y = 1:10),
      visualizations = viz,
      is_landing_page = TRUE
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  qmd_file <- file.path(dashboard$output_dir, "index.qmd")
  qmd_content <- readLines(qmd_file, warn = FALSE)
  
  # Find the chunk label
  chunk_line <- grep("```{r ", qmd_content, fixed = TRUE, value = TRUE)
  chunk_line <- chunk_line[!grepl("setup", chunk_line)]  # Exclude setup chunk
  chunk_label <- gsub("```\\{r ([^}]+)\\}.*", "\\1", chunk_line[1])
  
  # Should be truncated to 50 characters
  expect_true(nchar(chunk_label) <= 50)
  
})

test_that("chunk names work correctly in complex nested dashboards", {
  # Real-world scenario: multiple pages, nested tabs, various viz types
  viz1 <- create_viz(
    type = "stackedbar",
    x_var = "category",
    stack_var = "group"
  ) %>%
    add_viz(title = "Overview", tabgroup = "analysis/overview") %>%
    add_viz(title = "By Age", tabgroup = "analysis/demographics/age") %>%
    add_viz(title = "By Gender", tabgroup = "analysis/demographics/gender")
  
  viz2 <- create_viz(
    type = "timeline",
    time_var = "year",
    response_var = "metric"
  ) %>%
    add_viz(title = "Trends", tabgroup = "trends/overall")
  
  dashboard <- create_dashboard(
    output_dir = tempfile("chunk_complex"),
    title = "Test"
  ) %>%
    add_page(
      "Page1",
      data = data.frame(
        category = rep(c("A", "B"), 5),
        group = rep(c("X", "Y"), 5),
        year = 2020:2029,
        metric = rnorm(10)
      ),
      visualizations = viz1,
      is_landing_page = TRUE
    ) %>%
    add_page(
      "Page2",
      data = data.frame(year = 2020:2023, metric = 1:4),
      visualizations = viz2
    )
  
  generate_dashboard(dashboard, render = FALSE)
  
  # Check page 1
  qmd1 <- paste(readLines(file.path(dashboard$output_dir, "index.qmd"), warn = FALSE), collapse = "\n")
  expect_true(grepl("```{r analysis-overview}", qmd1, fixed = TRUE))
  expect_true(grepl("```{r analysis-demographics-age}", qmd1, fixed = TRUE))
  expect_true(grepl("```{r analysis-demographics-gender}", qmd1, fixed = TRUE))
  
  # Check page 2
  qmd2 <- paste(readLines(file.path(dashboard$output_dir, "page2.qmd"), warn = FALSE), collapse = "\n")
  expect_true(grepl("```{r trends-overall}", qmd2, fixed = TRUE))
  
})
