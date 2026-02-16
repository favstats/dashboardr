# =============================================================================
# Showcase: dashboardr v0.5 New Features
#
# Demonstrates:
# 1. Date & date-range inputs (type = "date" / "daterange")
# 2. URL deep linking & parameterized dashboards (url_params = TRUE)
# 3. Accessibility: alt_text on viz, aria_label on value boxes/metrics,
#    skip-to-content link, focus trapping in modals, keyboard tab navigation
#
# Run:
#   source("dev/demo_v05_features.R")
# =============================================================================

library(tidyverse)
devtools::load_all()

set.seed(2026)

# =============================================================================
# SYNTHETIC DATA: Conference attendance tracker
# =============================================================================

dates <- seq.Date(as.Date("2023-01-01"), as.Date("2025-12-31"), by = "day")
n <- length(dates)

events <- tibble(
  date = dates,
  year = format(dates, "%Y"),
  quarter = paste0(format(dates, "%Y"), "-Q", ceiling(as.numeric(format(dates, "%m")) / 3)),
  month = format(dates, "%b %Y"),
  region = sample(c("North America", "Europe", "Asia Pacific", "Latin America"),
                  n, replace = TRUE, prob = c(0.35, 0.30, 0.20, 0.15)),
  event_type = sample(c("Workshop", "Conference", "Webinar", "Meetup"),
                      n, replace = TRUE, prob = c(0.20, 0.30, 0.35, 0.15)),
  satisfaction = sample(c("Very Satisfied", "Satisfied", "Neutral", "Dissatisfied"),
                        n, replace = TRUE, prob = c(0.30, 0.40, 0.20, 0.10)),
  attendance = rpois(n, lambda = 120),
  rating = round(runif(n, 3.0, 5.0), 1)
)

# Aggregated monthly data for timeline
monthly_data <- events %>%
  group_by(month, region) %>%
  summarise(
    total_attendance = sum(attendance),
    avg_rating = round(mean(rating), 2),
    .groups = "drop"
  )

# Quarterly summary
quarterly_data <- events %>%
  group_by(quarter, event_type) %>%
  summarise(
    total_attendance = sum(attendance),
    event_count = n(),
    .groups = "drop"
  )

# Summary metrics
total_events <- nrow(events)
total_attendees <- sum(events$attendance)
avg_rating_all <- round(mean(events$rating), 1)
top_region <- events %>% count(region, sort = TRUE) %>% slice(1) %>% pull(region)

# =============================================================================
# PAGE 1: Date Filtering (sidebar with date inputs)
# =============================================================================

# Viz collections with their own data
date_viz <- create_content(data = events) %>%
  add_viz(
    type = "timeline",
    time_var = "quarter",
    y_var = "attendance",
    agg = "sum",
    group_var = "event_type",
    title = "Quarterly Attendance by Event Type",
    y_label = "Total Attendance",
    alt_text = "Timeline chart showing quarterly event attendance from 2023 to 2025, grouped by event type (Workshop, Conference, Webinar, Meetup)",
    height = 450
  )

bar_viz <- create_content(data = events) %>%
  add_viz(
    type = "bar",
    x_var = "event_type",
    title = "Events by Type",
    alt_text = "Bar chart showing the count of events by type",
    height = 350
  )

date_page <- create_page("Date Filtering", data = events, icon = "ph:calendar") %>%
  add_sidebar(title = "Date Filters", width = "300px") %>%
    add_input(
      input_id = "date_range",
      label = "Date Range",
      type = "daterange",
      filter_var = "date",
      value = c("2024-01-01", "2025-06-30"),
      min = "2023-01-01",
      max = "2025-12-31",
      help = "Filter events by date range"
    ) %>%
    add_input(
      input_id = "region_filter",
      label = "Region",
      type = "checkbox",
      filter_var = "region",
      options = c("North America", "Europe", "Asia Pacific", "Latin America"),
      default_selected = c("North America", "Europe", "Asia Pacific", "Latin America"),
      stacked = TRUE
    ) %>%
  end_sidebar() %>%
  add_content(date_viz) %>%
  add_content(bar_viz)

# =============================================================================
# PAGE 2: URL Deep Linking (tabbed, with inputs)
# =============================================================================

url_viz <- create_content(data = events) %>%
  add_viz(
    type = "bar",
    x_var = "event_type",
    title = "By Event Type",
    tabgroup = "By Event Type",
    alt_text = "Bar chart of events by type, filtered by selected regions",
    height = 400
  ) %>%
  add_viz(
    type = "bar",
    x_var = "satisfaction",
    title = "By Satisfaction",
    tabgroup = "By Satisfaction",
    alt_text = "Bar chart of events by satisfaction level, filtered by selected regions",
    height = 400
  ) %>%
  add_viz(
    type = "stackedbar",
    x_var = "region",
    stack_var = "event_type",
    title = "Region vs Event Type",
    tabgroup = "Stacked View",
    alt_text = "Stacked bar chart showing the distribution of event types within each region",
    height = 400
  )

url_page <- create_page("URL Deep Linking", data = events, icon = "ph:link") %>%
  add_text(md_text(
    "### URL Deep Linking Demo",
    "",
    "Change filters below, then **copy the URL** from your browser.",
    "Open it in a new tab to see the filter state restored automatically.",
    "Click different tabs and notice the URL hash changes too."
  )) %>%
  add_spacer(height = "0.5rem") %>%
  add_input_row(style = "boxed") %>%
    add_input(
      input_id = "url_region",
      label = "Region",
      type = "select_multiple",
      filter_var = "region",
      options = c("North America", "Europe", "Asia Pacific", "Latin America"),
      default_selected = c("North America", "Europe", "Asia Pacific", "Latin America")
    ) %>%
  end_input_row() %>%
  add_content(url_viz)

# =============================================================================
# PAGE 3: Accessibility (value boxes, metrics, modal, alt_text)
# =============================================================================

a11y_viz <- create_content(data = events) %>%
  add_viz(
    type = "pie",
    x_var = "satisfaction",
    title = "Satisfaction Distribution",
    alt_text = "Pie chart showing event satisfaction: 30% Very Satisfied, 40% Satisfied, 20% Neutral, 10% Dissatisfied",
    height = 400
  )

a11y_page <- create_page("Accessibility", data = events, icon = "ph:wheelchair") %>%
  add_text(md_text(
    "### Accessibility Features",
    "",
    "This page demonstrates dashboardr's accessibility improvements:",
    "",
    "- **Skip-to-content link**: Press `Tab` on page load to reveal it",
    "- **Keyboard tab navigation**: Use `Arrow` keys to move between tabs",
    "- **Modal focus trapping**: Open the modal below, then `Tab` stays within it",
    "- **ARIA live region**: Screen readers announce filter changes",
    "- **Alt text on charts**: Charts below have descriptive `alt_text` for screen readers",
    "- **`aria_label` on metrics/value boxes**: Below cards are labeled for assistive tech"
  )) %>%
  add_spacer(height = "1rem") %>%
  add_value_box_row() %>%
    add_value_box(
      title = "Total Events",
      value = format(total_events, big.mark = ","),
      bg_color = "#2563eb",
      logo_text = "CAL",
      aria_label = paste("Total events:", format(total_events, big.mark = ","))
    ) %>%
    add_value_box(
      title = "Total Attendees",
      value = format(total_attendees, big.mark = ","),
      bg_color = "#059669",
      logo_text = "PPL",
      aria_label = paste("Total attendees:", format(total_attendees, big.mark = ","))
    ) %>%
    add_value_box(
      title = "Avg Rating",
      value = avg_rating_all,
      bg_color = "#d97706",
      logo_text = "STAR",
      aria_label = paste("Average rating:", avg_rating_all, "out of 5")
    ) %>%
  end_value_box_row() %>%
  add_spacer(height = "1rem") %>%
  add_metric(
    value = top_region,
    title = "Top Region",
    icon = "ph:globe",
    color = "#6366f1",
    subtitle = "By number of events",
    aria_label = paste("Top region by events:", top_region)
  ) %>%
  add_spacer(height = "1rem") %>%
  add_text("[Open Focus Trap Demo Modal](#a11y-demo-modal){.modal-link}") %>%
  add_modal(
    modal_id = "a11y-demo-modal",
    title = "Focus Trap Demo",
    modal_content = md_text(
      "### Modal Focus Trapping",
      "",
      "Press **Tab** and **Shift+Tab** to cycle through focusable elements.",
      "Focus stays within this modal. Press **Escape** to close.",
      "",
      "This button does nothing, but it's here for Tab testing:",
      "",
      "<button style='padding: 8px 16px; border-radius: 4px; border: 1px solid #ccc; cursor: pointer;'>Test Button</button>"
    )
  ) %>%
  add_spacer(height = "1rem") %>%
  add_content(a11y_viz)

# =============================================================================
# BUILD DASHBOARD
# =============================================================================

dash <- create_dashboard(
  output_dir = "demo_v05",
  title = "dashboardr v0.5 Features",
  url_params = TRUE,
  chart_export = TRUE,
  theme = "cosmo"
) %>%
  add_page(date_page) %>%
  add_page(url_page) %>%
  add_page(a11y_page)

generate_dashboard(dash, render = TRUE, open = "browser")
