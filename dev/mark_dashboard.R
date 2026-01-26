# =============================================================================
# Mark's Publication Trends Dashboard
#
# Dataset: ~120 countries, 6 time periods, 5 metrics
# Demonstrates the improved input system with:
#   - Grouped select options (by region)
#   - Slider with custom labels
#   - Switch with explicit toggle_series
#   - Help text for inputs
#   - Size variants
#   - Reset button
#   - Powered by dashboardr branding
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2024)

# =============================================================================
# Generate realistic fake data for ~120 countries
# =============================================================================

# Country list with regions for realistic data generation
countries_data <- tribble(
  ~country, ~region, ~weird_base,
  # North America
  "United States", "North America", 85,
  "Canada", "North America", 80,
  "Mexico", "Latin America", 35,
  # Western Europe
  "United Kingdom", "Western Europe", 82,
  "Germany", "Western Europe", 78,
  "France", "Western Europe", 75,
  "Netherlands", "Western Europe", 80,
  "Belgium", "Western Europe", 72,
  "Switzerland", "Western Europe", 76,
  "Austria", "Western Europe", 70,
  "Italy", "Western Europe", 65,
  "Spain", "Western Europe", 62,
  "Portugal", "Western Europe", 55,
  "Ireland", "Western Europe", 74,
  "Denmark", "Northern Europe", 78,
  "Sweden", "Northern Europe", 80,
  "Norway", "Northern Europe", 79,
  "Finland", "Northern Europe", 77,
  "Iceland", "Northern Europe", 75,
  # Eastern Europe
  "Poland", "Eastern Europe", 45,
  "Czech Republic", "Eastern Europe", 48,
  "Hungary", "Eastern Europe", 44,
  "Romania", "Eastern Europe", 38,
  "Bulgaria", "Eastern Europe", 35,
  "Slovakia", "Eastern Europe", 42,
  "Slovenia", "Eastern Europe", 50,
  "Croatia", "Eastern Europe", 45,
  "Serbia", "Eastern Europe", 40,
  "Ukraine", "Eastern Europe", 35,
  "Russia", "Eastern Europe", 42,
  "Estonia", "Eastern Europe", 52,
  "Latvia", "Eastern Europe", 48,
  "Lithuania", "Eastern Europe", 46,
  # Asia Pacific
  "Japan", "Asia Pacific", 72,
  "South Korea", "Asia Pacific", 65,
  "China", "Asia Pacific", 30,
  "Taiwan", "Asia Pacific", 58,
  "Hong Kong", "Asia Pacific", 62,

  "Singapore", "Asia Pacific", 68,
  "Malaysia", "Asia Pacific", 40,
  "Thailand", "Asia Pacific", 35,
  "Vietnam", "Asia Pacific", 25,
  "Indonesia", "Asia Pacific", 28,
  "Philippines", "Asia Pacific", 32,
  "India", "Asia Pacific", 38,
  "Pakistan", "Asia Pacific", 25,
  "Bangladesh", "Asia Pacific", 22,
  "Sri Lanka", "Asia Pacific", 30,
  "Nepal", "Asia Pacific", 20,
  # Oceania
  "Australia", "Oceania", 82,
  "New Zealand", "Oceania", 80,
  # Middle East
  "Israel", "Middle East", 70,
  "Turkey", "Middle East", 45,
  "Iran", "Middle East", 35,
  "Saudi Arabia", "Middle East", 40,
  "United Arab Emirates", "Middle East", 48,
  "Qatar", "Middle East", 50,
  "Kuwait", "Middle East", 45,
  "Jordan", "Middle East", 38,
  "Lebanon", "Middle East", 42,
  "Egypt", "Middle East", 32,
  # Africa
  "South Africa", "Africa", 55,
  "Nigeria", "Africa", 28,
  "Kenya", "Africa", 30,
  "Ghana", "Africa", 28,
  "Ethiopia", "Africa", 20,
  "Tanzania", "Africa", 22,
  "Uganda", "Africa", 24,
  "Morocco", "Africa", 35,
  "Tunisia", "Africa", 38,
  "Algeria", "Africa", 30,
  "Senegal", "Africa", 25,
  "Cameroon", "Africa", 22,
  "Zimbabwe", "Africa", 28,
  "Zambia", "Africa", 25,
  "Botswana", "Africa", 32,
  # Latin America
  "Brazil", "Latin America", 45,
  "Argentina", "Latin America", 50,
  "Chile", "Latin America", 52,
  "Colombia", "Latin America", 40,
  "Peru", "Latin America", 35,
  "Venezuela", "Latin America", 38,
  "Ecuador", "Latin America", 32,
  "Bolivia", "Latin America", 28,
  "Paraguay", "Latin America", 25,
  "Uruguay", "Latin America", 48,
  "Costa Rica", "Latin America", 42,
  "Panama", "Latin America", 38,
  "Guatemala", "Latin America", 28,
  "Cuba", "Latin America", 35,
  "Dominican Republic", "Latin America", 30,
  "Puerto Rico", "Latin America", 55,
  # Additional countries
  "Greece", "Southern Europe", 58,
  "Cyprus", "Southern Europe", 55,
  "Malta", "Southern Europe", 52,
  "Luxembourg", "Western Europe", 70,
  "Belarus", "Eastern Europe", 38,
  "Moldova", "Eastern Europe", 32,
  "Georgia", "Eastern Europe", 35,
  "Armenia", "Eastern Europe", 33,
  "Azerbaijan", "Eastern Europe", 30,
  "Kazakhstan", "Central Asia", 32,
  "Uzbekistan", "Central Asia", 25,
  "Mongolia", "Asia Pacific", 28,
  "Myanmar", "Asia Pacific", 22,
  "Cambodia", "Asia Pacific", 20
)

# Time periods
decades <- c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")

# Generate publication data
generate_country_data <- function(country_row) {
  country <- country_row$country
  region <- country_row$region
  weird_base <- country_row$weird_base

  # Base publication share (varies by country prominence)
  pub_base <- case_when(
    country %in% c("United States", "China") ~ runif(1, 15, 25),
    country %in% c("United Kingdom", "Germany", "Japan", "France") ~ runif(1, 4, 8),
    country %in% c("Canada", "Australia", "Italy", "Spain", "Netherlands", "India", "Brazil", "South Korea") ~ runif(1, 2, 5),
    TRUE ~ runif(1, 0.1, 2)
  )

  # Female authorship base (higher in Western countries, increasing over time)
  female_base <- case_when(
    region %in% c("Western Europe", "Northern Europe", "North America", "Oceania") ~ runif(1, 20, 30),
    region %in% c("Latin America", "Eastern Europe") ~ runif(1, 18, 28),
    TRUE ~ runif(1, 12, 22)
  )

  # Qualitative base (varies by region/tradition)
  qual_base <- case_when(
    region %in% c("Western Europe", "Northern Europe") ~ runif(1, 18, 28),
    region %in% c("North America", "Oceania") ~ runif(1, 15, 25),
    TRUE ~ runif(1, 10, 20)
  )

  tibble(
    country = country,
    region = region,
    decade = decades
  ) %>%
    mutate(
      decade_num = as.numeric(factor(decade)),
      # Publications: some countries grow, some decline
      pct_publications = pmax(0.01, pub_base * (1 + (decade_num - 3) * runif(1, -0.05, 0.15)) + rnorm(n(), 0, pub_base * 0.1)),
      # Female authorship: generally increasing over time
      pct_female = pmin(55, pmax(5, female_base + (decade_num - 1) * runif(1, 3, 6) + rnorm(n(), 0, 3))),
      # WEIRD: generally decreasing as global south increases
      pct_weird = pmin(95, pmax(10, weird_base - (decade_num - 1) * runif(1, 1, 4) + rnorm(n(), 0, 4))),
      # Qualitative: slight increase over time
      pct_qualitative = pmin(45, pmax(5, qual_base + (decade_num - 1) * runif(1, 0.5, 2) + rnorm(n(), 0, 3))),
      # Quantitative: complement (roughly)
      pct_quantitative = pmin(90, pmax(40, 100 - pct_qualitative - runif(1, 5, 15) + rnorm(n(), 0, 3)))
    ) %>%
    select(-decade_num)
}

# Generate data for all countries
publication_data <- countries_data %>%
  rowwise() %>%
  do(generate_country_data(.)) %>%
  ungroup()

# Add Global Average
global_avg <- publication_data %>%
  group_by(decade) %>%
  summarise(
    pct_publications = mean(pct_publications),
    pct_female = mean(pct_female),
    pct_weird = mean(pct_weird),
    pct_qualitative = mean(pct_qualitative),
    pct_quantitative = mean(pct_quantitative),
    .groups = "drop"
  ) %>%
  mutate(country = "Global Average", region = "Global")

publication_data <- bind_rows(publication_data, global_avg)

# Round values for cleaner display
publication_data <- publication_data %>%
  mutate(
    across(starts_with("pct_"), ~round(., 1))
  )

# =============================================================================
# Reshape to long format for metric switching
# =============================================================================

publication_data_long <- publication_data %>%
  pivot_longer(
    cols = starts_with("pct_"),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    # Clean up metric names for display
    metric = case_when(
      metric == "pct_publications" ~ "Publications",
      metric == "pct_female" ~ "Female Authorship",
      metric == "pct_weird" ~ "WEIRD Studies",
      metric == "pct_qualitative" ~ "Qualitative",
      metric == "pct_quantitative" ~ "Quantitative",
      TRUE ~ metric
    )
  )

cat("Generated data for", n_distinct(publication_data_long$country), "countries\n")
cat("Total rows:", nrow(publication_data_long), "\n")
cat("Metrics:", paste(unique(publication_data_long$metric), collapse = ", "), "\n")

# =============================================================================
# Create GROUPED options by region (new feature!)
# =============================================================================

# Build grouped country options by region
countries_by_region <- publication_data_long %>%
  filter(country != "Global Average") %>%
  distinct(country, region) %>%
  arrange(region, country)

# Create a named list for grouped select
grouped_countries <- split(countries_by_region$country, countries_by_region$region)
# Sort region names alphabetically
grouped_countries <- grouped_countries[sort(names(grouped_countries))]

# Default selection: some major countries
default_countries <- c("United States", "United Kingdom", "Germany", "China", "Brazil")

# Metrics for dropdown
all_metrics <- c("Publications", "Female Authorship", "WEIRD Studies", "Qualitative", "Quantitative")

# =============================================================================
# Create visualization - single chart, metric switched via input
# =============================================================================

viz <- create_viz() %>%
  add_viz(
    type = "timeline",
    time_var = "decade",
    y_var = "value",
    group_var = "country",
    chart_type = "line",
    title = "Publication Trends by Country",
    subtitle = "Select a metric and countries to compare trends over time",
    x_label = "Decade",
    y_label = "Percentage (%)"
  )

# =============================================================================
# Create content with improved filters
# =============================================================================

content <- create_content() %>%
  # add_text(md_text(
  #   "### 📊 Explore Global Publication Trends",
  #   "",
  #   "Use the filters below to compare countries across different metrics and time periods."
  # )) %>%

  # Row 1: Country multi-select (with GROUPED options!) and Metric single-select
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "country_filter",
      label = "🌍 Select Countries",
      filter_var = "country",
      options = grouped_countries,  # Using GROUPED options by region!
      default_selected = default_countries,
      placeholder = "Choose countries to compare...",
      width = "600px",
      mr = "10px",
      help = "Countries are grouped by region. Select multiple to compare."
    ) %>%
  add_input(
    input_id = "show_average",
    label = "Show Global Average",
    type = "switch",
    filter_var = "country",
    # Using explicit toggle_series parameter (new!)
    toggle_series = "Global Average",
    override = TRUE,
    value = TRUE,
    help = "Toggle the global average trendline."
  ) %>%
  end_input_row() %>%

  # Row 2: Slider with CUSTOM LABELS and Switch with explicit toggle_series
  add_input_row(style = "inline", align = "center") %>%
    add_input(
      input_id = "decade_slider",
      label = "📅 Starting Decade",
      type = "slider",
      filter_var = "decade",
      min = 1,
      max = 6,
      step = 1,
      value = 1,
      show_value = TRUE,
      width = "600px",
      mr = "10px",
      # Using CUSTOM LABELS for slider!
      labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s"),
      help = "Filter to show data from this decade onwards."
    ) %>%
  add_input(
    input_id = "metric_select",
    label = "📈 Select Metric",
    type = "select_single",
    filter_var = "metric",
    options = all_metrics,
    default_selected = "Publications",
    width = "250px",
    help = "Choose which publication metric to visualize."
  )  %>%
  end_input_row() %>%

  add_spacer(height = "0.5rem")

# Combine: Viz first, then filter options below
this <- viz + content

# =============================================================================
# Create dashboard with modern styling
# =============================================================================

dashboard <- create_dashboard(
  title = "Global Publication Trends",
  output_dir = "mark_publication_dashboard",
  tabset_theme = "modern",
  author = "Mark's Research Project",
  description = "Interactive dashboard exploring publication trends across 120+ countries from the 1970s to 2020s",
  # Modern navbar styling

  navbar_bg_color = "#1e3a5f",
  navbar_text_color = "#ffffff",
  # Clean fonts
  mainfont = "Inter",
  fontsize = "15px"
) %>%
  add_page(
    name = "Trends",
    data = publication_data_long,
    content = this,
    icon = "ph:chart-line-up",
    is_landing_page = TRUE,
    # Explicit time_var for metric switching
    time_var = "decade"
  ) %>%
  add_page(
    name = "About",
    text = md_text(
      "# About This Dashboard",
      "",
      "This dashboard visualizes publication trends across **120+ countries** from the **1970s to 2020s**.",
      "",
      "## 📊 Available Metrics",
      "",
      "| Metric | Description |",
      "|--------|-------------|",
      "| **Publications** | Country's share of global publications |",
      "| **Female Authorship** | Percentage of publications with female authors |",
      "| **WEIRD Studies** | Studies conducted in Western, Educated, Industrialized, Rich, Democratic countries |",
      "| **Qualitative** | Publications using qualitative research methods |",
      "| **Quantitative** | Publications using quantitative research methods |",
      "",
      "## 🎯 How to Use",
      "",
      "1. **Select Countries** — Use the grouped dropdown to choose countries by region",
      "2. **Select Metric** — Choose which publication metric to display",
      "3. **Filter Decades** — Use the slider to filter the starting decade",
      "4. **Global Average** — Toggle the switch to show/hide the global benchmark",
      "",
      "## 📝 Data Notes",
      "",
      "- Data is **simulated** for demonstration purposes",
      "- Real data would come from bibliometric databases like Web of Science or Scopus",
      "- WEIRD = Western, Educated, Industrialized, Rich, Democratic (Henrich et al., 2010)",
      "",
      "## ✨ Features Demonstrated",
      "",
      "This dashboard showcases the improved `dashboardr` input system:",
      "",
      "- **Grouped select options** — Countries organized by region",
      "- **Slider with custom labels** — Decade labels instead of numbers",
      "- **Toggle series switch** — Show/hide specific series with override",
      "- **Help text** — Contextual guidance for each input",
      "- **Metric switching** — Dynamic data updates based on selection"
    ),
    icon = "ph:info"
  ) %>%
  # Add powered by dashboardr branding
  add_powered_by_dashboardr(size = "large", style = "default")

# Print summary
print(dashboard)

# Generate and render
cat("\n=== Generating Mark's Dashboard ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done! ===\n")
