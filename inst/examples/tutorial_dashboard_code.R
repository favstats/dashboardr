# =============================================================================
# Tutorial Dashboard - Complete Example Code
# =============================================================================
#
# This script demonstrates how to create a complete dashboard with dashboardr.
# It uses the General Social Survey (GSS) data to create visualizations
# showing education levels, happiness trends, and text content examples.
#
# To run this script, you need to install the following packages:
#   install.packages(c("dashboardr", "gssr", "dplyr", "haven"))
#
# =============================================================================

library(dashboardr)
library(gssr)

# =============================================================================
# DATA PREPARATION
# =============================================================================

# Cross-sectional data (for bar/stackedbar charts)
# Using 2020 GSS Panel data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  dplyr::mutate(
    degree = as.character(haven::as_factor(degree_1a)),
    happy = as.character(haven::as_factor(happy_1a))
  ) %>%
  dplyr::filter(!is.na(degree), !is.na(happy))

# Time series data (for timeline chart)
# Using cumulative GSS data from 1972-2024
data(gss_all, package = "gssr")
gss_time <- gss_all %>%
  dplyr::mutate(happy = as.character(haven::as_factor(happy))) %>%
  dplyr::filter(!is.na(happy), !is.na(year),
                happy %in% c("very happy", "pretty happy", "not too happy"))

# =============================================================================
# CHARTS PAGE
# =============================================================================

# Create visualizations for the Charts page
chart_vizzes <- create_content() %>%
  # Bar chart - simple counts by education level
  add_viz(type = "bar",
          x_var = "degree",
          title = "Education Level Distribution",
          subtitle = "Count of respondents by highest degree attained",
          x_label = "Education",
          y_label = "Count",
          x_order = c("less than high school", "high school",
                      "associate/junior college", "bachelor's", "graduate"),
          color_palette = c("#3498db", "#2ecc71", "#9b59b6", "#e74c3c", "#f39c12"),
          height = 400) %>%
  # Stacked bar chart - happiness by education
  add_viz(type = "stackedbar",
          x_var = "degree",
          stack_var = "happy",
          title = "Happiness by Education Level",
          subtitle = "Self-reported happiness across education groups",
          x_label = "Education",
          y_label = "Percentage",
          stack_label = "Happiness",
          stacked_type = "percent",
          x_order = c("less than high school", "high school",
                      "associate/junior college", "bachelor's", "graduate"),
          stack_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450)

# Create the Charts page and add visualizations
charts_page <- create_page(name = "Charts", data = gss_clean, icon = "ph:chart-bar") %>%
  add_content(chart_vizzes)

# =============================================================================
# TIMELINE PAGE
# =============================================================================

# Create visualization for the Timeline page
timeline_viz <- create_content() %>%
  add_viz(type = "timeline",
          time_var = "year",
          y_var = "happy",
          title = "Happiness Trends Over Time (1972-2024)",
          subtitle = "How has happiness changed across 50+ years?",
          x_label = "Year",
          y_label = "Percentage",
          y_levels = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450)

# Create the Timeline page and add visualization
timeline_page <- create_page(name = "Timeline", data = gss_time, icon = "ph:chart-line") %>%
  add_content(timeline_viz)

# =============================================================================
# TEXT & CONTENT PAGE
# =============================================================================

# Create content demonstrating text and accordion features
text_content <- create_content() %>%
  # Markdown text with formatting examples
  add_text(md_text(
    "This page demonstrates text formatting and content blocks.",
    "",
    "You can use **bold text**, *italics*, and `inline code`.",
    "",
    "Lists work too:",
    "",
    "- First item with **bold**",
    "- Second item with *italics*",
    "- Third item with `code`"
  )) %>%
  # Accordion example
  add_accordion(
    title = "What is an accordion?",
    text = "A collapsible content block. Great for FAQs or code examples."
  )

# Create the Text & Content page
text_page <- create_page(name = "Text & Content", icon = "ph:chalkboard-simple-bold") %>%
  add_content(text_content)

# =============================================================================
# CREATE AND GENERATE DASHBOARD
# =============================================================================

# Create the dashboard with all pages
dashboard <- create_dashboard(
  output_dir = "tutorial_dashboard",
  title = "Tutorial Dashboard",
  logo = "gss_logo.png",
  theme = "flatly"
) %>%
  add_pages(charts_page, timeline_page, text_page)

# Generate the dashboard (renders all Quarto files to HTML)
generate_dashboard(dashboard)

# =============================================================================
# WHAT'S NEXT?
# =============================================================================
#
# After running this script, you'll have a fully rendered dashboard in the
# "tutorial_dashboard" folder. Open "tutorial_dashboard/index.html" in your
# browser to view it.
#
# To customize:
# - Change the theme: try "cosmo", "lumen", "minty", "sandstone", etc.
# - Add more visualizations: histogram, scatter, heatmap, treemap, boxplot, map
# - Add interactive filters with add_input()
# - Add modals with add_modal()
#
# Learn more at: https://favstats.github.io/dashboardr/
# =============================================================================
