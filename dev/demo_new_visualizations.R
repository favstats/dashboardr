# This demo showcases the newest visualization types in dashboardr
# Uses synthetic data to ensure all visualizations work reliably.

library(tidyverse)
devtools::load_all()

set.seed(42)

# =============================================================================
# Generate Clean Synthetic Data
# =============================================================================

n <- 500

# Survey-like data
survey_data <- tibble(
  id = 1:n,
  year = sample(2018:2024, n, replace = TRUE),
  age = round(rnorm(n, mean = 45, sd = 15)),
  gender = sample(c("Male", "Female"), n, replace = TRUE),
  region = sample(c("Northeast", "South", "Midwest", "West"), n, replace = TRUE,
                  prob = c(0.2, 0.35, 0.25, 0.2)),
  education = sample(c("High School", "Some College", "Bachelor's", "Graduate"), n,
                     replace = TRUE, prob = c(0.3, 0.25, 0.3, 0.15)),
  happiness = sample(c("Very Happy", "Pretty Happy", "Not Too Happy"), n,
                     replace = TRUE, prob = c(0.3, 0.5, 0.2)),
  trust = sample(c("Can Trust", "Can't Be Too Careful", "Depends"), n,
                 replace = TRUE, prob = c(0.35, 0.45, 0.2)),
  political_views = round(rnorm(n, mean = 4, sd = 1.5)),  # 1-7 scale
  income = round(rnorm(n, mean = 60000, sd = 25000))
) %>%
  # Ensure age and political_views are within reasonable bounds

  mutate(
    age = pmax(18, pmin(85, age)),
    political_views = pmax(1, pmin(7, political_views)),
    income = pmax(15000, income)
  )

# Map data for choropleth
map_data <- tibble(
  iso2c = c("US", "CA", "MX", "GB", "DE", "FR", "IT", "ES", "JP", "CN",
            "AU", "BR", "IN", "RU", "ZA"),
  country = c("United States", "Canada", "Mexico", "United Kingdom", "Germany",
              "France", "Italy", "Spain", "Japan", "China", "Australia",
              "Brazil", "India", "Russia", "South Africa"),
  value = c(85, 78, 45, 72, 80, 68, 55, 62, 88, 70, 75, 42, 38, 50, 35),
  category = sample(c("High", "Medium", "Low"), 15, replace = TRUE)
)

# =============================================================================
# Create Visualizations
# =============================================================================

viz_collection <- create_viz() %>%
  # --- Timeline Section ---
  add_viz(type = "timeline",
          time_var = "year",
          y_var = "happiness",
          chart_type = "stacked_area",
          title = "Happiness Trends Over Time",
          subtitle = "Stacked area chart showing distribution of happiness levels",
          y_levels = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          height = 800,  # Custom height
          tabgroup = "Trends/Happiness",
          data = "survey") %>%
  add_viz(type = "timeline",
          time_var = "year",
          y_var = "trust",
          group_var = "gender",
          chart_type = "line",
          y_filter = "Can Trust",
          title = "Social Trust by Gender",
          subtitle = "Line chart showing percentage who say 'Can Trust'",
          height = 400,  # Custom height
          tabgroup = "Trends/Trust",
          data = "survey") %>%
  # --- Hierarchical Section ---
  add_viz(type = "treemap",
          group_var = "region",
          subgroup_var = "education",
          value_var = "income",
          title = "Income by Region & Education",
          subtitle = "Treemap showing total income distribution",
          height = 600,  # Custom height (native support)
          tabgroup = "Hierarchical/Treemap",
          data = "survey") %>%
  # --- Relational Section ---
  add_viz(type = "scatter",
          x_var = "age",
          y_var = "political_views",
          color_var = "gender",
          show_trend = TRUE,
          trend_method = "loess",
          title = "Age vs Political Views",
          subtitle = "Scatter plot with LOESS trend lines by gender",
          height = 550,  # Custom height
          tabgroup = "Relational/Scatter",
          data = "survey") %>%
  # --- Geospatial Section ---
  add_viz(type = "map",
          value_var = "value",
          join_var = "iso2c",
          title = "Global Indicator Example",
          subtitle = "Interactive choropleth map with custom data",
          color_palette = c("#f7fbff", "#08519c"),
          height = 500,  # Custom height (native support)
          tabgroup = "Geospatial/World Map",
          data = "map_data") %>%
  # --- Distribution Section ---
  add_viz(type = "histogram",
          x_var = "age",
          bins = 15,
          title = "Age Distribution (Tall)",
          subtitle = "Standard histogram of respondent ages - 600px height",
          color_palette = "#2E86AB",
          height = 600,  # Custom height - should be tall
          tabgroup = "Distributions/Age",
          data = "survey") %>%
  add_viz(type = "histogram",
          x_var = "income",
          bins = 20,
          title = "Income Distribution (Short)",
          subtitle = "Histogram of annual income - 300px height",
          color_palette = "#28a745",
          height = 300,  # Custom height - should be short
          tabgroup = "Distributions/Income",
          data = "survey")

# =============================================================================
# Create Dashboard
# =============================================================================

dashboard <- create_dashboard(
  output_dir = "dev/demo_new_viz",
  title = "Dashboardr: New Viz Showcase",
  author = "Dashboardr Team",
  theme = "flatly",
  value_boxes = TRUE,
  code_folding = "show"
) %>%
  add_page(
    name = "New Visualizations",
    icon = "ph:magic-wand",
    data = list(survey = survey_data, map_data = map_data),
    visualizations = viz_collection
  ) %>%
  add_page(
    name = "About this Demo",
    icon = "ph:info",
    text = md_text(
      "# New Visualization Types",
      "",
      "This dashboard demonstrates the latest visualization types added to the `dashboardr` package:",
      "",
      "- **Timeline**: `type = \"timeline\"` for time-series data (line or stacked area).",
      "- **Treemap**: `type = \"treemap\"` for hierarchical part-to-whole relationships.",
      "- **Scatter**: `type = \"scatter\"` for relational analysis with trend lines.",
      "- **Map**: `type = \"map\"` for geospatial choropleth maps.",
      "- **Histogram**: `type = \"histogram\"` for univariate distributions.",
      "",
      "All these visualizations are built on top of `highcharter` for high interactivity.",
      "",
      "## Data",
      "",
      "This demo uses **synthetic data** (500 observations) to ensure reliable visualization rendering."
    )
  )

# =============================================================================
# Generate and Render
# =============================================================================

generate_dashboard(dashboard, render = TRUE, open = "browser")
