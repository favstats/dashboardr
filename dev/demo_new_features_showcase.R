# =============================================================================
# Showcase: All New dashboardr Features (v0.3)
#
# This demo uses synthetic data to demonstrate every new visualization type,
# chart export, show_when comparison operators, annotations & reference lines,
# all woven into a multi-page sidebar dashboard.
#
# New viz types: pie, donut, lollipop, dumbbell, gauge, funnel, pyramid,
#                sankey, waffle
# New features: chart_export, reference_lines, annotations,
#               show_when with >, <, >=, <=
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2025)

# =============================================================================
# SYNTHETIC DATA
# =============================================================================

# --- Employee satisfaction survey data ---
n <- 600
departments <- c("Engineering", "Marketing", "Sales", "HR", "Finance")
regions     <- c("North America", "Europe", "Asia Pacific", "Latin America")

employees <- tibble(
  id         = 1:n,
  year       = sample(2019:2024, n, replace = TRUE),
  department = sample(departments, n, replace = TRUE,
                      prob = c(0.30, 0.20, 0.25, 0.10, 0.15)),
  region     = sample(regions, n, replace = TRUE,
                      prob = c(0.35, 0.30, 0.20, 0.15)),
  satisfaction = sample(c("Very Satisfied", "Satisfied", "Neutral",
                           "Dissatisfied", "Very Dissatisfied"), n,
                        replace = TRUE,
                        prob = c(0.20, 0.35, 0.25, 0.12, 0.08)),
  engagement_score = round(rnorm(n, mean = 72, sd = 12)),
  tenure_years = round(rexp(n, rate = 0.2) + 1, 1),
  salary_band = sample(c("< $60K", "$60K-$90K", "$90K-$120K", "> $120K"),
                        n, replace = TRUE,
                        prob = c(0.20, 0.35, 0.30, 0.15)),
  remote_pct  = sample(c(0, 25, 50, 75, 100), n, replace = TRUE,
                        prob = c(0.10, 0.15, 0.25, 0.30, 0.20))
) %>%
  mutate(
    engagement_score = pmax(20, pmin(100, engagement_score)),
    tenure_years     = pmin(25, tenure_years)
  )

# --- Recruitment funnel data ---
funnel_data <- tibble(
  stage = c("Applications", "Phone Screen", "Technical Interview",
            "On-site Interview", "Offer Extended", "Hired"),
  count = c(5000, 2200, 900, 450, 180, 120)
)

# --- Budget flow data (for Sankey) ---
budget_flow <- tibble(
  from  = c("Revenue", "Revenue", "Revenue",
            "OpEx", "OpEx", "OpEx",
            "CapEx", "CapEx",
            "R&D", "R&D"),
  to    = c("OpEx", "CapEx", "R&D",
            "Salaries", "Marketing Spend", "Operations",
            "Equipment", "Real Estate",
            "Product Dev", "Innovation Lab"),
  value = c(45, 20, 35,
            25, 10, 10,
            12, 8,
            22, 13)
)

# --- Dumbbell: before/after data ---
engagement_change <- tibble(
  department  = departments,
  score_2021  = c(65, 58, 62, 70, 60),
  score_2024  = c(78, 72, 68, 82, 75)
)

# --- Pre-aggregated department counts for waffle ---
dept_counts <- employees %>%
  count(department, name = "n")

# --- Timeline aggregation for trend charts ---
yearly_engagement <- employees %>%
  group_by(year, department) %>%
  summarise(
    avg_engagement = round(mean(engagement_score), 1),
    .groups = "drop"
  )

# --- Satisfaction by salary band for lollipop ---
salary_satisfaction <- employees %>%
  group_by(salary_band) %>%
  summarise(
    avg_score = round(mean(engagement_score), 1),
    .groups = "drop"
  ) %>%
  mutate(salary_band = factor(salary_band,
    levels = c("< $60K", "$60K-$90K", "$90K-$120K", "> $120K")))

# =============================================================================
# PAGE 1: Pie Chart (sidebar — single chart)
# =============================================================================

pie_content <- create_content(data = employees) %>%
  add_sidebar(title = "Filters", width = "280px") %>%
    add_input(
      input_id  = "region_filter",
      label     = "Region",
      type      = "checkbox",
      filter_var = "region",
      options   = regions,
      default_selected = regions,
      stacked   = TRUE
    ) %>%
  end_sidebar() %>%
  add_viz(
    type    = "pie",
    x_var   = "department",
    title   = "Employees by Department",
    subtitle = "Use the sidebar to filter by region",
    color_palette = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F"),
    sort_by_value = TRUE,
    height  = 500,
    export  = TRUE
  )

# =============================================================================
# PAGE 2: Donut Chart (sidebar — single chart)
# =============================================================================

donut_content <- create_content(data = employees) %>%
  add_sidebar(title = "Filters", width = "280px") %>%
    add_input(
      input_id  = "dept_filter",
      label     = "Department",
      type      = "select_multiple",
      filter_var = "department",
      options   = departments,
      default_selected = departments
    ) %>%
  end_sidebar() %>%
  add_viz(
    type       = "donut",
    x_var      = "region",
    title      = "Employees by Region",
    subtitle   = "Donut chart (auto 50% inner cut-out)",
    color_palette = c("#EDC948", "#B07AA1", "#FF9DA7", "#9C755F"),
    height     = 500,
    export     = TRUE
  )

# =============================================================================
# PAGE 3: Comparisons — no sidebar (lollipop, dumbbell, waffle)
# =============================================================================

comparison_content <- create_content() %>%
  add_text(md_text(
    "## Engagement by Salary Band",
    "",
    "Lollipop charts offer a cleaner alternative to bar charts for ranked data."
  )) %>%
  add_spacer(height = "0.5rem") %>%
  add_viz(
    type    = "lollipop",
    data    = salary_satisfaction,
    x_var   = "salary_band",
    y_var   = "avg_score",
    title   = "Average Engagement Score by Salary Band",
    x_label = "Salary Band",
    y_label = "Engagement Score",
    horizontal    = TRUE,
    sort_by_value = TRUE,
    color_palette = c("#4E79A7"),
    export  = TRUE
  ) %>%
  add_spacer(height = "1.5rem") %>%
  add_text(md_text(
    "## Engagement Change: 2021 vs 2024",
    "",
    "Dumbbell charts highlight the gap between two time points per category."
  )) %>%
  add_viz(
    type      = "dumbbell",
    data      = engagement_change,
    x_var     = "department",
    low_var   = "score_2021",
    high_var  = "score_2024",
    title     = "Department Engagement: Before & After Initiative",
    low_label  = "2021",
    high_label = "2024",
    low_color  = "#E15759",
    high_color = "#59A14F",
    sort_by_gap = TRUE,
    horizontal  = TRUE,
    export  = TRUE
  ) %>%
  add_spacer(height = "1.5rem") %>%
  add_text(md_text(
    "## Department Composition (Waffle)",
    "",
    "Waffle charts use a grid of squares for an intuitive part-to-whole view."
  )) %>%
  add_viz(
    type    = "waffle",
    data    = dept_counts,
    x_var   = "department",
    y_var   = "n",
    title   = "Workforce Distribution (Waffle Grid)",
    total   = 100,
    rows    = 10,
    color_palette = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F"),
    export  = TRUE
  )

# =============================================================================
# PAGE 4: Flows & Funnels — no sidebar (funnel, pyramid, sankey)
# =============================================================================

flow_content <- create_content() %>%
  add_text(md_text(
    "## Recruitment Pipeline",
    "",
    "Funnel charts visualise drop-off through sequential stages."
  )) %>%
  add_viz(
    type    = "funnel",
    data    = funnel_data,
    x_var   = "stage",
    y_var   = "count",
    title   = "Hiring Funnel: Applications to Hires",
    color_palette = c("#264653", "#2A9D8F", "#E9C46A",
                      "#F4A261", "#E76F51", "#E15759"),
    show_conversion = TRUE,
    export  = TRUE
  ) %>%
  add_spacer(height = "1.5rem") %>%
  add_text(md_text(
    "## Pyramid View",
    "",
    "The same data reversed into a pyramid shape."
  )) %>%
  add_viz(
    type     = "pyramid",
    data     = funnel_data,
    x_var    = "stage",
    y_var    = "count",
    title    = "Hiring Pyramid (Reversed Funnel)",
    color_palette = c("#E15759", "#E76F51", "#F4A261",
                      "#E9C46A", "#2A9D8F", "#264653"),
    export   = TRUE
  ) %>%
  add_spacer(height = "1.5rem") %>%
  add_text(md_text(
    "## Budget Allocation (Sankey Diagram)",
    "",
    "Sankey diagrams trace flows from source to destination nodes."
  )) %>%
  add_viz(
    type      = "sankey",
    data      = budget_flow,
    from_var  = "from",
    to_var    = "to",
    value_var = "value",
    title     = "Annual Budget Flow ($M)",
    subtitle  = "Revenue allocation through departments",
    color_palette = c(
      "Revenue"         = "#264653",
      "OpEx"            = "#2A9D8F",
      "CapEx"           = "#E9C46A",
      "R&D"             = "#F4A261",
      "Salaries"        = "#76B7B2",
      "Marketing Spend" = "#F28E2B",
      "Operations"      = "#BAB0AC",
      "Equipment"       = "#9C755F",
      "Real Estate"     = "#FF9DA7",
      "Product Dev"     = "#E15759",
      "Innovation Lab"  = "#B07AA1"
    ),
    node_width   = 25,
    node_padding = 12,
    height       = 500,
    export       = TRUE
  )

# =============================================================================
# PAGE 5: Trends (sidebar — single timeline with ref lines + annotations)
# =============================================================================

trends_content <- create_content(data = employees) %>%
  add_sidebar(title = "Trend Controls", width = "260px") %>%
    add_input(
      input_id  = "dept_trend",
      label     = "Department",
      type      = "checkbox",
      filter_var = "department",
      options   = departments,
      default_selected = departments,
      stacked   = TRUE
    ) %>%
  end_sidebar() %>%
  add_viz(
    type      = "timeline",
    data      = yearly_engagement,
    time_var  = "year",
    y_var     = "avg_engagement",
    group_var = "department",
    agg       = "none",
    title     = "Engagement Score by Department Over Time",
    subtitle  = "With target reference line and event annotations",
    x_label   = "Year",
    y_label   = "Avg Engagement Score",
    color_palette = c(
      "Engineering" = "#4E79A7",
      "Marketing"   = "#F28E2B",
      "Sales"       = "#E15759",
      "HR"          = "#76B7B2",
      "Finance"     = "#59A14F"
    ),
    reference_lines = list(
      list(y = 75, label = "Target", color = "#2ca02c", dash = "dash")
    ),
    annotations = list(
      list(x = 2020, label = "COVID Impact", color = "#E15759"),
      list(x = 2023, label = "New Initiative", color = "#4E79A7")
    ),
    height = 550,
    export = TRUE
  )

# =============================================================================
# PAGE 6: KPI Gauges — no sidebar (static gauges)
# =============================================================================

gauges_content <- create_content() %>%
  add_text(md_text(
    "## Performance Gauges",
    "",
    "Gauge charts display KPIs with color bands for quick status assessment."
  )) %>%
  add_spacer(height = "0.5rem") %>%
  add_viz(
    type    = "gauge",
    value   = 73,
    title   = "Overall Engagement",
    data_labels_format = "{y}%",
    color   = "#4E79A7",
    bands   = list(
      list(from = 0,  to = 40, color = "#E15759"),
      list(from = 40, to = 70, color = "#F28E2B"),
      list(from = 70, to = 100, color = "#59A14F")
    ),
    target       = 80,
    target_color = "#333",
    export  = TRUE
  ) %>%
  add_spacer(height = "1rem") %>%
  add_viz(
    type    = "gauge",
    value   = 88,
    title   = "Employee Retention Rate",
    data_labels_format = "{y}%",
    color   = "#59A14F",
    min     = 0,
    max     = 100,
    export  = TRUE
  ) %>%
  add_spacer(height = "1rem") %>%
  add_viz(
    type    = "gauge",
    value   = 4.2,
    title   = "Avg Rating (out of 5)",
    data_labels_format = "{y}",
    min     = 0,
    max     = 5,
    color   = "#F28E2B",
    export  = TRUE
  )

# =============================================================================
# PAGE 7: About (text page explaining features)
# =============================================================================

about_text <- md_text(
  "# New Features Showcase",
  "",
  "This dashboard demonstrates every new feature added in dashboardr v0.3.",
  "",
  "## New Visualization Types",
  "",
  "| Type | Function | Description |",
  "|------|----------|-------------|",
  "| Pie | `viz_pie()` | Classic pie chart with labels and tooltips |",
  "| Donut | `viz_pie()` via `type = \"donut\"` | Pie with inner cut-out (auto 50%) |",
  "| Lollipop | `viz_lollipop()` | Stem + dot, a clean bar chart alternative |",
  "| Dumbbell | `viz_dumbbell()` | Two-point comparison per category |",
  "| Gauge | `viz_gauge()` | KPI speedometer with color bands |",
  "| Funnel | `viz_funnel()` | Sequential stage drop-off |",
  "| Pyramid | `viz_funnel()` via `type = \"pyramid\"` | Reversed funnel |",
  "| Sankey | `viz_sankey()` | Flow diagram between nodes |",
  "| Waffle | `viz_waffle()` | Grid-of-squares proportional chart |",
  "",
  "## Chart Export",
  "",
  "Every chart on this dashboard has an export button (top-right hamburger menu).",
  "Supported formats: PNG, SVG, PDF, CSV, XLS, and fullscreen mode.",
  "",
  "Set per-chart with `export = TRUE` or dashboard-wide with `chart_export = TRUE`.",
  "",
  "## Reference Lines & Annotations",
  "",
  "Timeline charts now support:",
  "",
  "- `reference_lines`: horizontal/vertical guidelines (e.g. targets, thresholds)",
  "- `annotations`: labeled markers for notable events",
  "",
  "## show_when Comparison Operators",
  "",
  "The conditional visibility system now supports:",
  "",
  "- `~ score > 50` (greater than)",
  "- `~ score < 100` (less than)",
  "- `~ year >= 2020` (greater than or equal)",
  "- `~ score <= 75` (less than or equal)",
  "- `~ !active` (negation)",
  "",
  "Combined with the existing `==`, `!=`, `%in%`, `&`, and `|` operators,",
  "this makes `show_when` a complete conditional logic system.",
  "",
  "## Built With",
  "",
  "- [dashboardr](https://github.com/favstats/dashboardr) - Static HTML dashboards in R",
  "- [Highcharts](https://www.highcharts.com/) via highcharter - Interactive charts",
  "- [Quarto](https://quarto.org/) - Document rendering engine"
)

# =============================================================================
# ASSEMBLE DASHBOARD
# =============================================================================

dashboard <- create_dashboard(
  output_dir    = "dev/demo_showcase_output",
  title         = "dashboardr v0.3: Feature Showcase",
  author        = "dashboardr Team",
  theme         = "litera",
  chart_export  = TRUE,
  search        = TRUE,
  back_to_top   = TRUE,
  page_navigation = TRUE,
  tabset_theme  = "modern",
  page_footer   = paste0("Built with dashboardr | ", Sys.Date()),
  navbar_brand  = "dashboardr Showcase",
  navbar_style  = "dark"
) %>%
  # Page 1: Pie (sidebar with region filter)
  add_page(
    name    = "Pie Chart",
    icon    = "ph:chart-pie",
    data    = employees,
    content = pie_content
  ) %>%
  # Page 2: Donut (sidebar with department filter)
  add_page(
    name    = "Donut Chart",
    icon    = "ph:chart-donut",
    data    = employees,
    content = donut_content
  ) %>%
  # Page 3: Comparisons (no sidebar — lollipop, dumbbell, waffle)
  add_page(
    name    = "Comparisons",
    icon    = "ph:arrows-out-line-horizontal",
    content = comparison_content
  ) %>%
  # Page 4: Flows & Funnels (no sidebar — funnel, pyramid, sankey)
  add_page(
    name    = "Flows & Funnels",
    icon    = "ph:funnel",
    content = flow_content
  ) %>%
  # Page 5: Trends (sidebar with department filter — single timeline)
  add_page(
    name    = "Trends",
    icon    = "ph:trend-up",
    data    = employees,
    content = trends_content
  ) %>%
  # Page 6: KPI Gauges (no sidebar — static gauges)
  add_page(
    name    = "KPIs",
    icon    = "ph:gauge",
    content = gauges_content
  ) %>%
  # Page 7: About
  add_page(
    name = "About",
    icon = "ph:info",
    text = about_text
  )

# =============================================================================
# GENERATE & RENDER
# =============================================================================

generate_dashboard(dashboard, render = TRUE, open = "browser")
