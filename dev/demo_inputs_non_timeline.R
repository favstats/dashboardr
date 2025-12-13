## =============================================================================
## Demo: Inputs with non-timeline visualizations
## Shows grouped selects, custom-label slider, and toggle switch on
## stacked bars, scatter, and heatmap (no timeline viz type used).
## =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2025)

segments <- c("SMB", "Growth", "Enterprise", "Benchmark")
journey_stage_order <- c("Onboarding", "Adoption", "Expansion", "Renewal")
products <- c("Pulse Automation", "Signal Analytics", "Flow Ops")
regions <- c("Americas", "EMEA", "APAC")

n <- 420

customer_health <- tibble(
  account = sprintf("Acct-%03d", 1:n),
  segment = sample(segments, n, replace = TRUE, prob = c(0.34, 0.31, 0.25, 0.1)),
  journey_stage = sample(
    journey_stage_order, n,
    replace = TRUE, prob = c(0.28, 0.32, 0.26, 0.14)
  ),
  product = sample(products, n, replace = TRUE, prob = c(0.4, 0.35, 0.25)),
  region = sample(regions, n, replace = TRUE, prob = c(0.45, 0.35, 0.2)),
  health_score = round(rnorm(n, mean = 78, sd = 8)),
  csat = round(rnorm(n, mean = 4.2, sd = 0.6), 1)
) %>%
  mutate(
    health_score = pmin(pmax(health_score, 55), 98),
    csat = pmin(pmax(csat, 2.4), 5),
    stage_index = match(journey_stage, journey_stage_order),
    success_level = case_when(
      health_score >= 85 ~ "Strong",
      health_score >= 75 ~ "Healthy",
      TRUE ~ "At Risk"
    ),
    escalation_rate = round(pmax(0, 12 - health_score / 9 + rnorm(n, 0, 1.3)), 1)
  )

# Grouped options for the multi-select
grouped_segments <- list(
  "Customer segments" = c("SMB", "Growth", "Enterprise"),
  "Comparisons" = c("Benchmark")
)

# Custom labels shown on the slider (numeric filtering still uses the values)
health_slider_labels <- c("60+", "65+", "70+", "75+", "80+", "85+", "90+", "95+")

viz <- create_viz() %>%
  add_viz(
    type = "stackedbar",
    x_var = "journey_stage",
    stack_var = "segment",
    title = "Stage mix by segment",
    subtitle = "Non-timeline stacked bars with grouped select + switch",
    x_label = "Customer journey",
    y_label = "Share of accounts",
    stack_label = "Segment",
    stacked_type = "percent",
    x_order = journey_stage_order,
    stack_order = c("SMB", "Growth", "Enterprise", "Benchmark"),
    color_palette = c("#4F46E5", "#0EA5E9", "#22C55E", "#F59E0B"),
    text = "Use the inputs below to see how filtering works outside timelines.",
    icon = "ph:stack",
    height = 520
  ) %>%
  add_viz(
    type = "scatter",
    x_var = "health_score",
    y_var = "csat",
    color_var = "segment",
    title = "Health vs. CSAT by segment",
    subtitle = "Slider filters by minimum health score",
    x_label = "Customer health score",
    y_label = "CSAT (1-5)",
    color_palette = c("#4F46E5", "#0EA5E9", "#22C55E", "#F59E0B"),
    height = 500,
    tabgroup = "quality"
  ) %>%
  add_viz(
    type = "heatmap",
    x_var = "segment",   # make x-axis match segment filter for JS filtering
    y_var = "product",
    value_var = "health_score",
    title = "Average health by segment and product",
    subtitle = "Heatmap now responds to segment filter",
    x_label = "Segment",
    y_label = "Product",
    value_label = "Avg health",
    x_order = c("SMB", "Growth", "Enterprise", "Benchmark"),
    y_order = products,
    color_palette = c("#E0F2FE", "#0369A1"),
    tooltip_suffix = "/100",
    icon = "ph:thermometer",
    height = 520,
    tabgroup = "quality"
  )

content <- create_content() %>%
  # add_text(md_text(
  #   "# Inputs on non-timeline charts",
  #   "",
  #   "Stacked bars, scatter, and heatmap using the refreshed inputs."
  # )) %>%
  add_input_row(style = "inline", align = "center") %>%
  add_input(
    input_id = "segment_filter",
    label = "Segments",
    filter_var = "segment",
    options = grouped_segments,
    default_selected = c("SMB", "Growth", "Enterprise"),
    placeholder = "Pick segments",
    width = "380px",
    help = "Grouped options work outside timeline charts."
  ) %>%
  add_input(
    input_id = "benchmark_toggle",
    label = "Show Benchmark",
    type = "switch",
    filter_var = "segment",
    toggle_series = "Benchmark",
    override = TRUE,
    value = TRUE,
    help = "Switch hides/shows the Benchmark stack or series."
  ) %>%
  end_input_row()


content2 <- create_content() %>%
  add_input_row(style = "inline", align = "center") %>%
  add_input(
    input_id = "health_slider",
    label = "Minimum health score",
    type = "slider",
    filter_var = "health_score",
    min = 60,
    max = 95,
    step = 5,
    value = 70,
    show_value = TRUE,
    labels = health_slider_labels,
    width = "400px",
    mr = "12px",
    help = "Custom labels + numeric filtering on scatter."
  ) %>%
  add_input(
    input_id = "stage_select",
    label = "Journey stage",
    type = "select_multiple",
    filter_var = "journey_stage",
    options = journey_stage_order,
    default_selected = journey_stage_order,
    width = "320px",
    help = "Filters stacked bars and heatmap categories."
  ) %>%
  end_input_row() %>%
  add_spacer(height = "0.6rem")

this <- content + viz + content2

dashboard <- create_dashboard(
  title = "Customer Health Inputs Demo",
  output_dir = "demo_inputs_non_timeline",
  tabset_theme = "modern",
  description = "Shows refreshed input system on stacked bars, scatter, and heatmap (no timeline).",
  author = "dashboardr"
) %>%
  add_page(
    name = "Customer Health",
    data = customer_health,
    # visualizations = viz,
    content = this,
    icon = "ph:pulse",
    is_landing_page = TRUE
  ) %>%
  add_powered_by_dashboardr(size = "large", style = "default")

cat("\n=== Generating demo ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")
cat("\n=== Done ===\n")
