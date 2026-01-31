# Build Interactive Inputs Demo Dashboard
# Showcases all input types with working examples
# Run from package root: source("pkgdown/build-inputs-demo.R")

library(dashboardr)
library(dplyr)
library(tidyr)

cat("📊 Building Inputs Demo Dashboard...\n\n")

# =============================================================================
# Generate synthetic publication trend data (similar to Mark's example)
# =============================================================================

set.seed(2024)

countries <- c(
  "United States", "United Kingdom", "Germany", "France",
  "Japan", "China", "Brazil", "Australia", "Global Average"
)

decades <- c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")

segments <- c("Research", "Industry", "Government")

# Generate trend data
publication_data <- expand.grid(
  country = countries,
  decade = decades,
  stringsAsFactors = FALSE
) %>%
  mutate(
    decade_num = as.numeric(factor(decade)),
    # Female authorship: increasing over time
    pct_female = case_when(
      country == "Global Average" ~ 15 + decade_num * 5,
      country %in% c("United States", "United Kingdom", "Germany") ~ 12 + decade_num * 6 + rnorm(n(), 0, 3),
      country %in% c("Japan", "China") ~ 8 + decade_num * 4 + rnorm(n(), 0, 3),
      TRUE ~ 10 + decade_num * 5 + rnorm(n(), 0, 4)
    ),
    # Open access: increasing especially in recent decades
    pct_open_access = case_when(
      country == "Global Average" ~ pmax(5, (decade_num - 2) * 12),
      TRUE ~ pmax(2, (decade_num - 2) * 12 + rnorm(n(), 0, 5))
    ),
    pct_female = pmin(pmax(pct_female, 5), 55),
    pct_open_access = pmin(pmax(pct_open_access, 0), 70)
  ) %>%
  select(country, decade, pct_female, pct_open_access)

# Generate segment data for stacked bar
segment_data <- expand.grid(
  decade = decades,
  segment = segments,
  stringsAsFactors = FALSE
) %>%
  mutate(
    publications = case_when(
      segment == "Research" ~ 500 + as.numeric(factor(decade)) * 80 + round(rnorm(n(), 0, 50)),
      segment == "Industry" ~ 200 + as.numeric(factor(decade)) * 60 + round(rnorm(n(), 0, 30)),
      segment == "Government" ~ 100 + as.numeric(factor(decade)) * 20 + round(rnorm(n(), 0, 20))
    ),
    publications = pmax(publications, 50)
  )

# Grouped country options by region
countries_by_region <- list(
  "Americas" = c("United States", "Brazil"),
  "Europe" = c("United Kingdom", "Germany", "France"),
  "Asia-Pacific" = c("Japan", "China", "Australia"),
  "Benchmarks" = c("Global Average")
)

# Default selections
default_countries <- c("United States", "United Kingdom", "Germany", "Global Average")

# =============================================================================
# Find package root
# =============================================================================

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

# =============================================================================
# PAGE 1: Select Dropdown (Multi-select with grouped options)
# =============================================================================

select_viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_female",
    group_var = "country",
    chart_type = "line",
    title = "Female Authorship Trends",
    subtitle = "Percentage of publications with female first authors",
    x_label = "Decade",
    y_label = "% Female Authors",
    height = 450
  )

select_content <- create_content() %>%
  add_text(md_text(
    "## Select Dropdown Input",
    "",
    "The **select** input creates a searchable dropdown. Use `select_multiple` for multi-select or `select_single` for single selection.",
    "",
    "This example uses **grouped options** to organize countries by region:"
  )) %>%
  add_code(
'add_input(
  input_id = "country_filter",
  label = "Select Countries",
  type = "select_multiple",
  filter_var = "country",
  options = list(
    "Americas" = c("United States", "Brazil"),
    "Europe" = c("United Kingdom", "Germany", "France"),
    "Asia-Pacific" = c("Japan", "China", "Australia"),
    "Benchmarks" = c("Global Average")
  ),
  default_selected = c("United States", "Germany"),
  placeholder = "Choose countries to compare...",
  width = "500px"
)', language = "r") %>%
  add_spacer(height = "1rem") %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries",
      type = "select_multiple",
      filter_var = "country",
      options = countries_by_region,
      default_selected = default_countries,
      placeholder = "Choose countries to compare...",
      width = "500px",
      help = "Countries are grouped by region. Select multiple to compare."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

select_page_content <- select_content + select_viz

# =============================================================================
# PAGE 2: Slider with Custom Labels
# =============================================================================

slider_viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_open_access",
    group_var = "country",
    chart_type = "line",
    title = "Open Access Adoption",
    subtitle = "Percentage of publications available as open access",
    x_label = "Decade",
    y_label = "% Open Access",
    height = 450
  )

slider_content <- create_content() %>%
  add_text(md_text(
    "## Slider Input",
    "",
    "The **slider** input filters data by a numeric range. Use `labels` to display custom text instead of numbers."
  )) %>%
  add_code(
'add_input(
  input_id = "decade_slider",
  label = "Starting Decade",
  type = "slider",
  filter_var = "decade",
  min = 1,
  max = 6,
  step = 1,
  value = 1,
  show_value = TRUE,
  labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s"),
  width = "500px"
)', language = "r") %>%
  add_spacer(height = "1rem") %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "decade_slider",
      label = "Starting Decade",
      type = "slider",
      filter_var = "decade",
      min = 1,
      max = 6,
      step = 1,
      value = 1,
      show_value = TRUE,
      labels = decades,
      width = "500px",
      help = "Drag to filter data from a specific decade onwards."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

slider_page_content <- slider_content + slider_viz

# =============================================================================
# PAGE 3: Switch Toggle (Show/Hide Series)
# =============================================================================

switch_viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_female",
    group_var = "country",
    chart_type = "line",
    title = "Female Authorship with Benchmark",
    subtitle = "Toggle the global average to compare against individual countries",
    x_label = "Decade",
    y_label = "% Female Authors",
    height = 450
  )

switch_content <- create_content() %>%
  add_text(md_text(
    "## Switch Toggle",
    "",
    "The **switch** input toggles a specific series on/off. Use `toggle_series` to specify which series to control."
  )) %>%
  add_code(
'add_input(
  input_id = "show_average",
  label = "Show Global Average",
  type = "switch",
  filter_var = "country",
  toggle_series = "Global Average",
  override = TRUE,
  value = TRUE
)', language = "r") %>%
  add_spacer(height = "1rem") %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_select",
      label = "Select Countries",
      type = "select_multiple",
      filter_var = "country",
      options = c("United States", "United Kingdom", "Germany", "France", "Japan", "China", "Brazil", "Australia"),
      default_selected = c("United States", "Germany", "Japan"),
      width = "400px"
    ) %>%
    add_input(
      input_id = "show_average",
      label = "Show Global Average",
      type = "switch",
      filter_var = "country",
      toggle_series = "Global Average",
      override = TRUE,
      value = TRUE,
      help = "Toggle benchmark line on/off."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

switch_page_content <- switch_content + switch_viz

# =============================================================================
# PAGE 4: Checkbox Input (Stacked Bar)
# =============================================================================

checkbox_viz <- create_viz() %>%
  add_viz(
    type = "stackedbar",
    x_var = "decade",
    stack_var = "segment",
    y_var = "publications",
    title = "Publications by Sector",
    subtitle = "Toggle sectors to see their contribution",
    x_label = "Decade",
    y_label = "Number of Publications",
    stack_label = "Sector",
    stacked_type = "counts",
    stack_order = segments,
    color_palette = c("#4F46E5", "#0EA5E9", "#22C55E"),
    height = 450
  )

checkbox_content <- create_content() %>%
  add_text(md_text(
    "## Checkbox Input",
    "",
    "The **checkbox** input allows multiple selections with all options visible. Great for 3-6 options."
  )) %>%
  add_code(
'add_input(
  input_id = "segment_filter",
  label = "Show Sectors",
  type = "checkbox",
  filter_var = "segment",
  options = c("Research", "Industry", "Government"),
  default_selected = c("Research", "Industry", "Government"),
  inline = TRUE
)', language = "r") %>%
  add_spacer(height = "1rem") %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "segment_filter",
      label = "Show Sectors",
      type = "checkbox",
      filter_var = "segment",
      options = segments,
      default_selected = segments,
      inline = TRUE,
      help = "Check/uncheck to show/hide sectors in the chart."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

checkbox_page_content <- checkbox_content + checkbox_viz

# =============================================================================
# PAGE 5: Combined Example (Select + Switch)
# =============================================================================

combined_viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "pct_female",
    group_var = "country",
    chart_type = "line",
    title = "Global Publication Trends",
    subtitle = "Compare countries against the global benchmark",
    x_label = "Decade",
    y_label = "% Female Authors",
    height = 500
  )

combined_content <- create_content() %>%
  add_text(md_text(
    "## Combined Inputs",
    "",
    "Multiple inputs can work together. Here, a **select dropdown** filters countries while a **switch** toggles the benchmark."
  )) %>%
  add_code(
'content <- create_content() %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_filter",
      label = "Select Countries",
      filter_var = "country",
      options = countries_by_region,
      default_selected = c("United States", "Germany"),
      width = "450px"
    ) %>%
    add_input(
      input_id = "show_average",
      label = "Show Benchmark",
      type = "switch",
      filter_var = "country",
      toggle_series = "Global Average",
      override = TRUE,
      value = TRUE
    ) %>%
  end_input_row()', language = "r") %>%
  add_spacer(height = "1rem") %>%
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "combined_country_filter",
      label = "Select Countries",
      type = "select_multiple",
      filter_var = "country",
      options = countries_by_region,
      default_selected = c("United States", "United Kingdom", "Germany"),
      placeholder = "Choose countries...",
      width = "450px",
      help = "Select countries to compare."
    ) %>%
    add_input(
      input_id = "combined_show_average",
      label = "Show Benchmark",
      type = "switch",
      filter_var = "country",
      toggle_series = "Global Average",
      override = TRUE,
      value = TRUE,
      help = "Toggle global average line."
    ) %>%
  end_input_row() %>%
  add_spacer(height = "0.5rem")

combined_page_content <- combined_content + combined_viz

# =============================================================================
# CREATE DASHBOARD
# =============================================================================

dashboard <- create_dashboard(
  title = "Interactive Inputs Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern",
  allow_inside_pkg = TRUE,
  author = "dashboardr",
  description = "Showcase of all interactive input types with working examples"
) %>%
  add_page(
    name = "Select",
    data = publication_data,
    content = select_page_content,
    icon = "ph:list-magnifying-glass",
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Slider",
    data = publication_data,
    content = slider_page_content,
    icon = "ph:sliders-horizontal"
  ) %>%
  add_page(
    name = "Switch",
    data = publication_data,
    content = switch_page_content,
    icon = "ph:toggle-right"
  ) %>%
  add_page(
    name = "Checkbox",
    data = segment_data,
    content = checkbox_page_content,
    icon = "ph:check-square"
  ) %>%
  add_page(
    name = "Combined",
    data = publication_data,
    content = combined_page_content,
    icon = "ph:faders"
  ) %>%
  add_page(
    name = "About",
    icon = "ph:info",
    navbar_align = "right",
    text = md_text(
      "## About This Demo",
      "",
      "This dashboard demonstrates all interactive input types in dashboardr.",
      "",
      "### Input Types",
      "",
      "| Type | Best For | Selection |",
      "|------|----------|-----------|",
      "| `select_multiple` | Many categories (10+) | Multiple |",
      "| `select_single` | Many categories, pick one | Single |",
      "| `checkbox` | Few categories (3-6) | Multiple |",
      "| `radio` | Mutually exclusive choices | Single |",
      "| `slider` | Numeric ranges | Range |",
      "| `switch` | Toggle series on/off | Boolean |",
      "",
      "### Key Concept: filter_var",
      "",
      "The `filter_var` parameter must match the grouping variable in your visualization:",
      "",
      "```r",
      "# Visualization groups by country",
      "add_viz(type = \"timeline\", group_var = \"country\", ...)",
      "",
      "# Input filters by country - must match!",
      "add_input(filter_var = \"country\", ...)",
      "```",
      "",
      "### Learn More",
      "",
      "- [dashboardr Documentation](https://favstats.github.io/dashboardr/)",
      "- [Advanced Features Guide](https://favstats.github.io/dashboardr/articles/advanced-features.html)"
    )
  ) %>%
  add_powered_by_dashboardr(size = "large", style = "default")

# Print summary
print(dashboard)

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

cat("\n✅ Inputs demo generation complete!\n")
