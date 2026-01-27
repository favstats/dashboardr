# Build Interactive Inputs Demo Dashboard
# Run from package root: source("pkgdown/build-inputs-demo.R")

library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

cat("📊 Building Inputs Demo Dashboard...\n\n")

# Prepare data with multiple years for richer filtering
data(gss_all)
gss_inputs <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, region) %>%
  filter(year >= 2010 & year <= 2022,
         happy %in% 1:3, 
         polviews %in% 1:7,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(
    # Convert ALL haven_labelled variables to factors or plain types
    year = as.integer(year),
    age = as.integer(age),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    degree = droplevels(as_factor(degree)),
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews)),
    region = droplevels(as_factor(region))
  )

# Page 1: Select and Checkbox inputs
select_page <- create_page(
  "Select & Checkbox",
  data = gss_inputs,
  type = "bar",
  icon = "ph:list-checks-fill"
) %>%
  add_text(
    "## Select & Checkbox Inputs",
    "",
    "Use the dropdown and checkboxes below to filter the data.",
    "The charts update automatically based on your selections."
  ) %>%
  add_callout(
    "**Try it:** Select different education levels and check/uncheck races to see how the charts change.",
    type = "tip"
  ) %>%
  add_input_row() %>%
  add_input(
    input_id = "edu_select",
    label = "Education Level",
    type = "select_multiple",
    filter_var = "degree",
    options_from = "degree"
  ) %>%
  add_input(
    input_id = "race_check",
    label = "Race",
    type = "checkbox",
    filter_var = "race",
    options_from = "race",
    inline = TRUE
  ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Gender", tabgroup = "Results") %>%
  add_viz(x_var = "polviews", title = "Political Views Distribution", tabgroup = "Results")

# Page 2: Slider and Radio inputs
slider_page <- create_page(
  "Slider & Radio",
  data = gss_inputs,
  type = "bar",
  icon = "ph:sliders-fill"
) %>%
  add_text(
    "## Slider & Radio Button Inputs",
    "",
    "Filter by age range using the slider, or select a specific gender."
  ) %>%
  add_input_row() %>%
  add_input(
    input_id = "age_slider",
    label = "Age Range",
    type = "slider",
    filter_var = "age",
    min = 18,
    max = 89,
    value = c(25, 65)
  ) %>%
  add_input(
    input_id = "sex_radio",
    label = "Gender",
    type = "radio",
    filter_var = "sex",
    options_from = "sex",
    inline = TRUE
  ) %>%
  end_input_row() %>%
  add_viz(x_var = "degree", title = "Education Distribution") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

# Page 3: Combined example
combined_page <- create_page(
  "Full Example",
  data = gss_inputs,
  type = "bar",
  icon = "ph:funnel-fill"
) %>%
  add_text(
    "## Complete Filtering Example",
    "",
    "This page combines multiple input types for comprehensive data exploration."
  ) %>%
  add_input_row() %>%
  add_input(
    input_id = "year_select",
    label = "Survey Year",
    type = "select_single",
    filter_var = "year",
    options_from = "year"
  ) %>%
  add_input(
    input_id = "edu_full",
    label = "Education",
    type = "select_multiple",
    filter_var = "degree",
    options_from = "degree"
  ) %>%
  end_input_row() %>%
  add_input_row() %>%
  add_input(
    input_id = "race_full",
    label = "Race",
    type = "checkbox",
    filter_var = "race",
    options_from = "race",
    inline = TRUE
  ) %>%
  add_input(
    input_id = "sex_full",
    label = "Gender",
    type = "radio",
    filter_var = "sex",
    options_from = "sex",
    inline = TRUE
  ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Gender", tabgroup = "Analysis") %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Analysis") %>%
  add_viz(x_var = "degree", title = "Education Breakdown", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race Distribution", tabgroup = "Demographics")

# ============================================================
# Find package root and set output directory
# ============================================================
find_pkg_root <- function() {
  dir <- getwd()
  for (i in 1:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  stop("Could not find package root. Run from package directory.")
}

pkg_root <- find_pkg_root()
output_dir <- file.path(pkg_root, "docs", "live-demos", "inputs")

cat("   Package root:", pkg_root, "\n")
cat("   Output dir:", output_dir, "\n")

# Clean up old files
if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dashboard <- create_dashboard(
  title = "Interactive Inputs Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern",
  allow_inside_pkg = TRUE  # Required for pkgdown demos
) %>%
  add_pages(select_page, slider_page, combined_page)

# Generate
result <- tryCatch(
  generate_dashboard(dashboard, render = TRUE, open = FALSE),
  error = function(e) {
    cat("   ⚠️  generate_dashboard error:", e$message, "\n")
    NULL
  }
)

# Check for HTML and move if in docs/ subdirectory
html_locations <- c(
  file.path(output_dir, "index.html"),
  file.path(output_dir, "docs", "index.html")
)

html_found <- FALSE
for (loc in html_locations) {
  if (file.exists(loc)) {
    cat("   ✅ Inputs demo HTML found at:", loc, "\n")
    html_found <- TRUE
    
    if (grepl("/docs/index.html$", loc)) {
      docs_dir <- dirname(loc)
      files_to_move <- list.files(docs_dir, full.names = TRUE)
      for (f in files_to_move) {
        file.copy(f, output_dir, recursive = TRUE, overwrite = TRUE)
      }
      unlink(docs_dir, recursive = TRUE)
      cat("   📁 Moved HTML files to root of output_dir\n")
    }
    break
  }
}

if (!html_found) {
  cat("   ⚠️  QMD files created but HTML not rendered\n")
  cat("   📁 To render manually: cd", output_dir, "&& quarto render .\n")
}
