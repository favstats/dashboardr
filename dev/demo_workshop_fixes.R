#!/usr/bin/env Rscript
# =============================================================================
# Demo: Workshop Follow-up Fixes
# =============================================================================
# This script demonstrates fixes for issues raised after the workshop:
#
# 1. Zero counts in grouped bar charts (complete_groups parameter)
# 2. Pre-aggregated data support (y_var parameter)
# 3. Custom grid maps using add_hc()
#
# Run this script to see all features in action!
# =============================================================================

devtools::load_all(".")

cat("\n")
cat("=============================================================================\n")
cat("                    DASHBOARDR FIXES DEMO\n")
cat("=============================================================================\n\n")

# =============================================================================
# DATA PREPARATION
# =============================================================================

# Data for zero counts demo - Treatment B has no observations for "High"
set.seed(42)
zero_counts_data <- data.frame(
  outcome = factor(c("Low", "Low", "Medium", "Medium", "High",
                     "Low", "Medium", "Medium", "High", "High"),
                   levels = c("Low", "Medium", "High")),
  treatment = factor(c("A", "A", "A", "A", "A",
                       "B", "B", "B", "A", "A"),
                     levels = c("A", "B"))
)

cat("Zero Counts Data Summary:\n")
print(table(zero_counts_data$outcome, zero_counts_data$treatment))
cat("Note: Treatment B has 0 observations for 'High'\n\n")

# Pre-aggregated data - combine into one dataframe for the page
pre_agg_data <- data.frame(
  gruppe = c("Altersgruppe 18-30", "Altersgruppe 31-50", "Altersgruppe 51+",
             "Ja", "Nein", "Keine Angabe"),
  anteil = c(25, 45, 30, 450, 380, 70),
  type = c("Alter", "Alter", "Alter", "Umfrage", "Umfrage", "Umfrage")
)

cat("Pre-aggregated Data:\n")
print(pre_agg_data)
cat("\n")

# Constituency grid map data
wahlkreis_data <- data.frame(
  name = c("Berlin-Mitte", "Hamburg-Nord", "Munich-Ost", "Cologne-West"),
  x = c(0, 1, 0, 1),
  y = c(0, 0, 1, 1),
  value = c(45, 62, 38, 55),
  stringsAsFactors = FALSE
)

# =============================================================================
# PAGE 1: Zero Counts Fix (Pure dashboardr with add_viz)
# =============================================================================

cat("Creating Page 1: Zero Counts Fix...\n")

page1_content <- create_content(data = zero_counts_data) %>%
  add_text("## The Problem") %>%
  add_text("When a group has 0 counts for a category, bars would 'shift' and become misaligned.
In the data below, Treatment B has no observations for 'High':") %>%
  add_text("```
        A  B
  Low   2  1
  Medium 2  2
  High   3  0
```") %>%

  add_text("## The Solution: `complete_groups` Parameter") %>%
  add_text("New parameter `complete_groups` (default TRUE) fills missing combinations with 0.") %>%

  add_viz(
    type = "bar",
    x_var = "outcome",
    group_var = "treatment",
    title = "complete_groups = TRUE (Default)",
    subtitle = "All x/group combinations present - bars align correctly",
    complete_groups = TRUE,
    tabgroup = "Demo/Fixed (Default)"
  ) %>%

  add_viz(
    type = "bar",
    x_var = "outcome",
    group_var = "treatment",
    title = "complete_groups = FALSE (Opt-out)",
    subtitle = "Only observed combinations shown - may cause misalignment",
    complete_groups = FALSE,
    tabgroup = "Demo/Sparse (Opt-out)"
  ) %>%

  add_text("## Usage") %>%
  add_code(
    code = '# Default behavior - fills missing combinations with 0
viz_bar(data, x_var = "outcome", group_var = "treatment")

# Opt out - show only observed combinations
viz_bar(data, x_var = "outcome", group_var = "treatment",
        complete_groups = FALSE)',
    language = "r"
  )

# =============================================================================
# PAGE 2: Pre-aggregated Data (Pure dashboardr with add_viz)
# =============================================================================

cat("Creating Page 2: Pre-aggregated Data...\n")

# Filter data for each example
alter_data <- pre_agg_data[pre_agg_data$type == "Alter", ]
umfrage_data <- pre_agg_data[pre_agg_data$type == "Umfrage", ]

page2_content <- create_content(data = alter_data) %>%
  add_text("## The Problem") %>%
  add_text("Users with already-aggregated data (e.g., from SQL, Excel, or external sources)
could not use `viz_bar()` directly - it would re-count the rows instead of using the values.") %>%

  add_text("## The Solution: `y_var` Parameter") %>%
  add_text("New parameter `y_var` uses pre-computed values directly, skipping aggregation.") %>%

  add_viz(
    type = "bar",
    x_var = "gruppe",
    y_var = "anteil",
    title = "Pre-aggregated Proportions",
    subtitle = "Using y_var to pass values directly",
    y_label = "Anteil (%)",
    horizontal = TRUE,
    tabgroup = "Examples/Proportions"
  )

# Add second example with different data using add_hc (different data source)
chart_counts <- viz_bar(
  data = umfrage_data,
  x_var = "gruppe",
  y_var = "anteil",
  bar_type = "percent",
  title = "Counts to Percentages",
  subtitle = "y_var + bar_type='percent' converts counts automatically"
)

page2_content <- page2_content %>%
  add_text("### Counts to Percentages") %>%
  add_hc(chart_counts) %>%

  add_text("## Usage") %>%
  add_code(
    code = '# Data with pre-computed values
my_data <- data.frame(
  gruppe = c("18-30", "31-50", "51+"),
  anteil = c(25, 45, 30)  # Already computed!
)

# Use y_var to skip aggregation
viz_bar(my_data, x_var = "gruppe", y_var = "anteil")

# Also works with bar_type = "percent" to convert counts
viz_bar(count_data, x_var = "category", y_var = "n",
        bar_type = "percent")',
    language = "r"
  )

# =============================================================================
# PAGE 3: Real Map with Bubbles (requires add_hc)
# =============================================================================

cat("Creating Page 3: Real Map with Bubbles...\n")

# German cities with coordinates and vote share values
cities_data <- data.frame(
  name = c("Berlin", "Hamburg", "München", "Köln", "Frankfurt",
           "Stuttgart", "Düsseldorf", "Leipzig", "Dresden", "Hannover"),
  lat = c(52.52, 53.55, 48.14, 50.94, 50.11,
          48.78, 51.23, 51.34, 51.05, 52.37),
  lon = c(13.40, 9.99, 11.58, 6.96, 8.68,
          9.18, 6.78, 12.37, 13.74, 9.74),
  value = c(65, 58, 52, 48, 55, 45, 42, 38, 35, 40),
  stringsAsFactors = FALSE
)

# Create a real map of Germany with bubble overlay using hcmap
custom_map_chart <- highcharter::hcmap(
  map = "countries/de/de-all",
  showInLegend = FALSE,
  nullColor = "#E8E8E8",
  borderColor = "#A0A0A0"
) %>%
  highcharter::hc_add_series(
    data = lapply(1:nrow(cities_data), function(i) {
      list(
        name = cities_data$name[i],
        lat = cities_data$lat[i],
        lon = cities_data$lon[i],
        z = cities_data$value[i]
      )
    }),
    type = "mapbubble",
    name = "Stimmenanteil (%)",
    minSize = "3%",
    maxSize = "12%",
    color = highcharter::hex_to_rgba("#3498db", 0.7)
  ) %>%
  highcharter::hc_title(text = "Wahlergebnis nach Stadt") %>%
  highcharter::hc_subtitle(text = "Interaktive Karte mit Bubble-Overlay - Pan & Zoom!") %>%
  highcharter::hc_tooltip(
    useHTML = TRUE,
    headerFormat = "",
    pointFormat = "<b>{point.name}</b><br/>Stimmenanteil: <b>{point.z}%</b>"
  ) %>%
  highcharter::hc_mapNavigation(
    enabled = TRUE,
    buttonOptions = list(verticalAlign = "bottom")
  ) %>%
  highcharter::hc_legend(enabled = FALSE)

page3_content <- create_content() %>%
  add_text("## Real Maps with Bubbles using `add_hc()`") %>%
  add_callout(
    text = "For geographic maps with custom overlays (bubbles, markers, etc.),
use `add_hc()` with Highcharts Maps. Supports pan, zoom, and full interactivity!",
    type = "tip",
    title = "Custom Map Visualizations"
  ) %>%
  add_hc(custom_map_chart) %>%
  add_text("## How It Works") %>%
  add_text("1. Create a map using `highchart(type = 'map')` and `hc_add_series_map()`") %>%
  add_text("2. Add bubble overlay with `hc_add_series(type = 'mapbubble')`") %>%
  add_text("3. Each bubble needs `lat`, `lon`, and `z` (size) values") %>%
  add_text("4. Add to dashboard with `add_hc(my_map)`") %>%
  add_code(
    code = '# Create a real map with bubble overlay
library(highcharter)

# City data with geographic coordinates
cities <- data.frame(
  name = c("Berlin", "Hamburg", "München", "Köln"),
  lat = c(52.52, 53.55, 48.14, 50.94),
  lon = c(13.40, 9.99, 11.58, 6.96),
  value = c(65, 58, 52, 48)
)

# Create the map using hcmap (downloads map data automatically)
map_chart <- hcmap(
  map = "countries/de/de-all",  # Germany map
  showInLegend = FALSE,
  nullColor = "#E8E8E8"
) %>%
  # Add bubble layer on top
  hc_add_series(
    data = lapply(1:nrow(cities), function(i) {
      list(name = cities$name[i],
           lat = cities$lat[i],
           lon = cities$lon[i],
           z = cities$value[i])
    }),
    type = "mapbubble",
    name = "Vote Share (%)",
    minSize = "3%",
    maxSize = "12%"
  ) %>%
  hc_title(text = "City Results") %>%
  hc_mapNavigation(enabled = TRUE)  # Enable pan/zoom

# Add to dashboard
create_content() %>%
  add_hc(map_chart)',
    language = "r",
    caption = "Example: Geographic map with bubble overlay"
  )

# =============================================================================
# CREATE DASHBOARD
# =============================================================================

cat("\nBuilding dashboard...\n")

# Output to a temp directory for the demo
output_dir <- file.path("fixes_demo")

dashboard <- create_dashboard(
  output_dir = output_dir,
  title = "Fixes Demo",
  theme = "flatly"
) %>%
  add_page(
    "Zero Counts",
    data = zero_counts_data,
    content = page1_content,
    is_landing_page = TRUE
  ) %>%
  add_page(
    "Pre-aggregated",
    data = alter_data,
    content = page2_content
  ) %>%
  add_page(
    "Custom Maps",
    content = page3_content
  )

# Generate and render
cat("\nGenerating dashboard...\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")

