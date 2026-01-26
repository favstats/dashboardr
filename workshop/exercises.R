# =============================================================================
# dashboardr Workshop - Comprehensive Exercises
# =============================================================================
# 
# This file contains hands-on exercises for the dashboardr workshop.
# Work through each exercise in order. Solutions are at the bottom of each
# section (scroll down after you try first!)
#
# =============================================================================

# Load packages
library(dashboardr)
library(dplyr)

# =============================================================================
# SAMPLE DATA
# =============================================================================
# We'll use this sample data throughout the exercises

set.seed(42)
survey_data <- data.frame(
  id = 1:500,
  age = sample(18:80, 500, replace = TRUE),
  income = rnorm(500, mean = 50000, sd = 15000),
  department = sample(c("Sales", "Engineering", "Marketing", "HR"), 500, replace = TRUE),
  satisfaction = sample(1:5, 500, replace = TRUE),
  year = sample(2020:2024, 500, replace = TRUE),
  wave = sample(1:2, 500, replace = TRUE),
  gender = sample(c("Male", "Female", "Other"), 500, replace = TRUE, prob = c(0.48, 0.48, 0.04)),
  region = sample(c("North", "South", "East", "West"), 500, replace = TRUE),
  q1_trust = sample(1:5, 500, replace = TRUE),
  q2_value = sample(1:5, 500, replace = TRUE),
  q3_recommend = sample(1:5, 500, replace = TRUE),
  survey_weight = runif(500, 0.5, 1.5)
)

# =============================================================================
# EXERCISE 1: Your First Visualization Collection
# =============================================================================
# 
# Goal: Create a visualization collection with 3 histograms
# 
# Requirements:
#   - Create histograms for: age, income, and satisfaction
#   - Put age and income in "demographics" tabgroup
#   - Put satisfaction in "feedback" tabgroup
#   - Use a blue color palette: c("#3498DB")
#   - Set bins to 15 for all histograms
#   - Print the result to see the structure!

# YOUR CODE HERE:
# viz <- create_viz(
#   type = "histogram",
#   ...
# ) %>%
#   add_viz(...) %>%
#   ...

# Print to see structure:
# print(viz)


# -- SOLUTION (scroll down after trying) --
#
#
#
#
#
#
#
#
#
#
# viz1 <- create_viz(
#   type = "histogram",
#   color_palette = c("#3498DB"),
#   bins = 15
# ) %>%
#   add_viz(x_var = "age", title = "Age Distribution", tabgroup = "demographics") %>%
#   add_viz(x_var = "income", title = "Income Distribution", tabgroup = "demographics") %>%
#   add_viz(x_var = "satisfaction", title = "Satisfaction Scores", tabgroup = "feedback")
# 
# print(viz1)

# =============================================================================
# EXERCISE 2: Create Your First Complete Dashboard
# =============================================================================
#
# Goal: Build a complete dashboard with multiple pages
#
# Requirements:
#   - Title: "Survey Analysis Dashboard"
#   - Output directory: "survey_dashboard"
#   - Landing page "Home" with welcome text (use md_text())
#   - Analysis page with the visualizations from Exercise 1
#   - About page aligned to the right
#   - Add icons to each page
#   - Generate with render = FALSE first to test

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "histogram", color_palette = c("#3498DB"), bins = 15) %>%
#   add_viz(x_var = "age", title = "Age Distribution", tabgroup = "demographics") %>%
#   add_viz(x_var = "income", title = "Income Distribution", tabgroup = "demographics") %>%
#   add_viz(x_var = "satisfaction", title = "Satisfaction", tabgroup = "feedback")
# 
# dashboard <- create_dashboard(
#   title = "Survey Analysis Dashboard",
#   output_dir = "survey_dashboard"
# ) %>%
#   add_page(
#     "Home",
#     icon = "ph:house-fill",
#     is_landing_page = TRUE,
#     text = md_text(
#       "# Welcome to the Survey Dashboard!",
#       "",
#       "This dashboard presents our **employee survey** results.",
#       "",
#       "## Quick Facts",
#       "",
#       "- 500 respondents",
#       "- 4 departments",
#       "- 2020-2024 data"
#     )
#   ) %>%
#   add_page(
#     "Analysis",
#     icon = "ph:chart-bar-fill",
#     data = survey_data,
#     visualizations = viz
#   ) %>%
#   add_page(
#     "About",
#     icon = "ph:info-fill",
#     navbar_align = "right",
#     text = md_text(
#       "## About",
#       "",
#       "Created with dashboardr"
#     )
#   )
# 
# print(dashboard)
# generate_dashboard(dashboard, render = FALSE)

# =============================================================================
# EXERCISE 3: Multiple Visualization Types
# =============================================================================
#
# Goal: Create a dashboard using different chart types
#
# Requirements:
#   1. A histogram of age distribution
#   2. A bar chart of department distribution (horizontal, percent)
#   3. A stacked bar of satisfaction by department
#   
# Each should be in its own tabgroup.
# Combine them using the + operator!

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# histogram_viz <- create_viz(type = "histogram", color_palette = c("#3498DB"), bins = 15) %>%
#   add_viz(x_var = "age", title = "Age Distribution", tabgroup = "demographics")
# 
# bar_viz <- create_viz(type = "bar", color_palette = c("#E74C3C")) %>%
#   add_viz(
#     x_var = "department",
#     title = "Department Distribution",
#     tabgroup = "departments",
#     horizontal = TRUE,
#     bar_type = "percent"
#   )
# 
# stacked_viz <- create_viz(type = "stackedbar") %>%
#   add_viz(
#     x_var = "department",
#     stack_var = "satisfaction",
#     title = "Satisfaction by Department",
#     tabgroup = "satisfaction",
#     stacked_type = "percent",
#     horizontal = TRUE,
#     stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
#     stack_bin_labels = c("1", "2", "3", "4", "5"),
#     color_palette = c("#E74C3C", "#E67E22", "#F1C40F", "#2ECC71", "#27AE60")
#   )
# 
# combined <- histogram_viz + bar_viz + stacked_viz
# print(combined)

# =============================================================================
# EXERCISE 4: Using Filters and title_tabset
# =============================================================================
#
# Goal: Create the same visualization for different subsets of data
#
# Requirements:
#   - Create 3 bar charts of department distribution
#   - One for each year: 2022, 2023, 2024
#   - Use filter to subset the data
#   - Use title_tabset to label each tab
#   - All should be in the same tabgroup "yearly_comparison"

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "bar", color_palette = c("#9B59B6"), horizontal = TRUE) %>%
#   add_viz(
#     x_var = "department",
#     title = "Department Distribution",
#     filter = ~ year == 2022,
#     title_tabset = "2022",
#     tabgroup = "yearly_comparison"
#   ) %>%
#   add_viz(
#     x_var = "department",
#     title = "Department Distribution",
#     filter = ~ year == 2023,
#     title_tabset = "2023",
#     tabgroup = "yearly_comparison"
#   ) %>%
#   add_viz(
#     x_var = "department",
#     title = "Department Distribution",
#     filter = ~ year == 2024,
#     title_tabset = "2024",
#     tabgroup = "yearly_comparison"
#   )
# 
# print(viz)

# =============================================================================
# EXERCISE 5: Nested Tabgroups
# =============================================================================
#
# Goal: Create a hierarchical tab structure
#
# Requirements:
#   Create visualizations with this structure:
#   - analysis/
#     - demographics/
#       - age (histogram)
#       - income (histogram)
#     - satisfaction/
#       - overview (bar chart of satisfaction)
#       - by_department (stacked bar)

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# nested_viz <- create_viz(type = "histogram", color_palette = c("#3498DB"), bins = 15) %>%
#   add_viz(
#     x_var = "age",
#     title = "Age Distribution",
#     tabgroup = "analysis/demographics/age"
#   ) %>%
#   add_viz(
#     x_var = "income",
#     title = "Income Distribution",
#     tabgroup = "analysis/demographics/income"
#   ) %>%
#   add_viz(
#     type = "bar",
#     x_var = "satisfaction",
#     title = "Overall Satisfaction",
#     tabgroup = "analysis/satisfaction/overview",
#     bar_type = "percent"
#   ) %>%
#   add_viz(
#     type = "stackedbar",
#     x_var = "department",
#     stack_var = "satisfaction",
#     title = "Satisfaction by Department",
#     tabgroup = "analysis/satisfaction/by_department",
#     stacked_type = "percent",
#     horizontal = TRUE,
#     stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
#     stack_bin_labels = c("1", "2", "3", "4", "5")
#   )
# 
# print(nested_viz)

# =============================================================================
# EXERCISE 6: Custom Bin Breaks and Labels
# =============================================================================
#
# Goal: Create meaningful age groups using custom binning
#
# Requirements:
#   - Create a histogram of age
#   - Use custom breaks: 18, 30, 45, 60, 75, Inf
#   - Use custom labels: "18-29", "30-44", "45-59", "60-74", "75+"
#   - Add appropriate axis labels

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "histogram", color_palette = c("#2ECC71")) %>%
#   add_viz(
#     x_var = "age",
#     title = "Age Groups",
#     bin_breaks = c(18, 30, 45, 60, 75, Inf),
#     bin_labels = c("18-29", "30-44", "45-59", "60-74", "75+"),
#     x_label = "Age Group",
#     y_label = "Number of Respondents"
#   )
# 
# # Preview (if you have data attached)
# # create_histogram(
# #   data = survey_data,
# #   x_var = "age",
# #   bin_breaks = c(18, 30, 45, 60, 75, Inf),
# #   bin_labels = c("18-29", "30-44", "45-59", "60-74", "75+")
# # )

# =============================================================================
# EXERCISE 7: Multiple Stacked Bars (Likert Questions)
# =============================================================================
#
# Goal: Create a stacked bar chart for multiple Likert-type questions
#
# Requirements:
#   - Use the q1_trust, q2_value, q3_recommend columns
#   - Create meaningful question labels
#   - Use a diverging color palette (red to green)
#   - Show as horizontal percent bars

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# questions <- c("q1_trust", "q2_value", "q3_recommend")
# labels <- c(
#   "I trust the company",
#   "I feel valued",
#   "I would recommend this company"
# )
# 
# viz <- create_viz(type = "stackedbars") %>%
#   add_viz(
#     x_vars = questions,
#     x_var_labels = labels,
#     title = "Employee Sentiment",
#     stacked_type = "percent",
#     horizontal = TRUE,
#     stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
#     stack_bin_labels = c("Strongly Disagree", "Disagree", "Neutral", "Agree", "Strongly Agree"),
#     color_palette = c("#E74C3C", "#E67E22", "#F1C40F", "#2ECC71", "#27AE60")
#   )
# 
# print(viz)

# =============================================================================
# EXERCISE 8: Apply Themes and Icons
# =============================================================================
#
# Goal: Create a professionally styled dashboard
#
# Requirements:
#   - Use theme_modern() with purple style
#   - Add icons to each page
#   - Add custom tabgroup labels with icons
#   - Enable search and back_to_top

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "histogram", color_palette = c("#9B59B6"), bins = 15) %>%
#   add_viz(x_var = "age", title = "Age", tabgroup = "demographics") %>%
#   add_viz(x_var = "satisfaction", title = "Satisfaction", tabgroup = "feedback") %>%
#   set_tabgroup_labels(list(
#     demographics = "{{< iconify ph:users-fill >}} Demographics",
#     feedback = "{{< iconify ph:heart-fill >}} Feedback"
#   ))
# 
# dashboard <- create_dashboard(
#   title = "Styled Survey Dashboard",
#   output_dir = "styled_dashboard",
#   search = TRUE,
#   back_to_top = TRUE
# ) %>%
#   apply_theme(theme_modern("purple")) %>%
#   add_page(
#     "Home",
#     icon = "ph:house-fill",
#     is_landing_page = TRUE,
#     text = md_text(
#       "# Welcome! {{< iconify ph:sparkle-fill >}}",
#       "",
#       "This is a **professionally styled** dashboard.",
#       "",
#       "- {{< iconify ph:check-circle-fill >}} Modern theme",
#       "- {{< iconify ph:check-circle-fill >}} Custom icons",
#       "- {{< iconify ph:check-circle-fill >}} Search enabled"
#     )
#   ) %>%
#   add_page(
#     "Analysis",
#     icon = "ph:chart-bar-fill",
#     data = survey_data,
#     visualizations = viz
#   ) %>%
#   add_page(
#     "About",
#     icon = "ph:info-fill",
#     navbar_align = "right",
#     text = md_text("## About", "", "Built with dashboardr")
#   )
# 
# print(dashboard)
# generate_dashboard(dashboard, render = FALSE)

# =============================================================================
# EXERCISE 9: Content System - Mixed Content
# =============================================================================
#
# Goal: Create a content collection with multiple content types
#
# Requirements:
#   - Add a heading with add_text()
#   - Add a callout with important info (type = "note")
#   - Add a histogram visualization
#   - Add an accordion with methodology details
#   - Add a spacer
#   - Add another visualization

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# content <- create_content() %>%
#   add_text("# Survey Analysis", "", "This section presents our key findings.") %>%
#   add_callout(
#     text = "Data collected from 500 respondents across 4 departments.",
#     type = "note",
#     title = "Sample Information"
#   ) %>%
#   add_viz(
#     type = "histogram",
#     x_var = "age",
#     title = "Age Distribution",
#     color_palette = c("#3498DB"),
#     bins = 15
#   ) %>%
#   add_accordion(
#     title = "Methodology",
#     text = md_text(
#       "## Data Collection",
#       "",
#       "- Survey conducted online",
#       "- Random sampling method",
#       "- 85% response rate"
#     ),
#     open = FALSE
#   ) %>%
#   add_spacer(height = "2rem") %>%
#   add_viz(
#     type = "bar",
#     x_var = "department",
#     title = "Department Distribution",
#     horizontal = TRUE,
#     bar_type = "percent"
#   )
# 
# print(content)

# =============================================================================
# EXERCISE 10: Value Boxes
# =============================================================================
#
# Goal: Create a row of value boxes showing key metrics
#
# Requirements:
#   - Create 3 value boxes in a row
#   - Show: Total Responses, Average Satisfaction, Response Rate
#   - Use different background colors for each
#   - Include emoji or text as logo

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# content <- create_content() %>%
#   add_text("# Dashboard Overview") %>%
#   add_value_box_row() %>%
#     add_value_box(
#       title = "Total Responses",
#       value = "500",
#       logo_text = "📊",
#       bg_color = "#3498DB"
#     ) %>%
#     add_value_box(
#       title = "Avg Satisfaction",
#       value = "3.8 / 5",
#       logo_text = "⭐",
#       bg_color = "#27AE60"
#     ) %>%
#     add_value_box(
#       title = "Response Rate",
#       value = "85%",
#       logo_text = "📈",
#       bg_color = "#9B59B6"
#     ) %>%
#   end_value_box_row()
# 
# print(content)

# =============================================================================
# EXERCISE 11: Interactive Inputs
# =============================================================================
#
# Goal: Add interactive filtering to a visualization
#
# Requirements:
#   - Create an input row with:
#     - Multi-select for regions
#     - Button group for metrics (use a fake metric column)
#   - Add a timeline visualization that uses group_var = "region"

# First, prepare data with a metric column
input_data <- survey_data %>%
  group_by(year, region) %>%
  summarise(
    satisfaction = mean(satisfaction),
    count = n(),
    .groups = "drop"
  ) %>%
  tidyr::pivot_longer(
    cols = c(satisfaction, count),
    names_to = "metric",
    values_to = "value"
  )

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# content <- create_content() %>%
#   add_text("## Regional Performance") %>%
#   add_input_row(style = "boxed", align = "center") %>%
#     add_input(
#       input_id = "region_filter",
#       label = "Select Regions",
#       type = "select_multiple",
#       filter_var = "region",
#       options = c("North", "South", "East", "West"),
#       default_selected = c("North", "South", "East", "West"),
#       width = "300px",
#       mr = "20px"
#     ) %>%
#     add_input(
#       input_id = "metric_select",
#       label = "Metric",
#       type = "button_group",
#       filter_var = "metric",
#       options = c("satisfaction", "count"),
#       default_selected = "satisfaction"
#     ) %>%
#   end_input_row() %>%
#   add_spacer(height = "1rem") %>%
#   add_viz(
#     type = "timeline",
#     time_var = "year",
#     response_var = "value",
#     group_var = "region",
#     chart_type = "line",
#     title = "Trend Over Time"
#   )
# 
# print(content)

# =============================================================================
# EXERCISE 12: Vectorized Creation
# =============================================================================
#
# Goal: Create multiple visualizations efficiently with add_vizzes()
#
# Requirements:
#   - Create bar charts for all 3 question columns (q1_trust, q2_value, q3_recommend)
#   - Use meaningful titles
#   - Use .tabgroup_template to organize into tabs

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "bar", horizontal = TRUE, bar_type = "percent") %>%
#   add_vizzes(
#     x_var = c("q1_trust", "q2_value", "q3_recommend"),
#     title = c("Trust in Company", "Feeling Valued", "Would Recommend"),
#     .tabgroup_template = "questions/{title}"
#   )
# 
# print(viz)

# =============================================================================
# EXERCISE 13: Using Weights
# =============================================================================
#
# Goal: Create weighted visualizations
#
# Requirements:
#   - Create two histograms of age: one unweighted, one weighted
#   - Use the survey_weight column for weighting
#   - Put them in tabs to compare

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# viz <- create_viz(type = "histogram", color_palette = c("#3498DB"), bins = 15) %>%
#   add_viz(
#     x_var = "age",
#     title = "Age Distribution (Unweighted)",
#     title_tabset = "Unweighted",
#     tabgroup = "weight_comparison"
#   ) %>%
#   add_viz(
#     x_var = "age",
#     title = "Age Distribution (Weighted)",
#     weight_var = "survey_weight",
#     title_tabset = "Weighted",
#     tabgroup = "weight_comparison"
#   )
# 
# print(viz)

# =============================================================================
# EXERCISE 14: Combining Collections with Pagination
# =============================================================================
#
# Goal: Create sections with page breaks between them
#
# Requirements:
#   - Create 3 visualization collections (demographics, satisfaction, questions)
#   - Combine them with pagination between sections
#   - Print to verify structure

# YOUR CODE HERE:


# -- SOLUTION --
#
#
#
#
#
#
#
#
#
#
# demographics <- create_viz(type = "histogram", color_palette = c("#3498DB")) %>%
#   add_viz(x_var = "age", title = "Age", tabgroup = "demographics")
# 
# satisfaction <- create_viz(type = "stackedbar") %>%
#   add_viz(
#     x_var = "department",
#     stack_var = "satisfaction",
#     title = "Satisfaction by Dept",
#     tabgroup = "satisfaction",
#     stacked_type = "percent",
#     horizontal = TRUE,
#     stack_breaks = c(0.5, 1.5, 2.5, 3.5, 4.5, 5.5),
#     stack_bin_labels = c("1", "2", "3", "4", "5")
#   )
# 
# questions <- create_viz(type = "bar", horizontal = TRUE) %>%
#   add_viz(x_var = "q1_trust", title = "Trust", tabgroup = "questions")
# 
# combined <- demographics %>%
#   combine_viz(satisfaction) %>%
#   add_pagination() %>%
#   combine_viz(questions)
# 
# print(combined)

# =============================================================================
# EXERCISE 15: Final Challenge - Complete Dashboard
# =============================================================================
#
# Goal: Create a complete, publication-ready dashboard
#
# Requirements:
#   - A descriptive title
#   - Landing page with:
#     - Value boxes showing key metrics
#     - Welcome text with icons
#   - Analysis page with:
#     - At least 3 visualization types
#     - Nested tabgroups
#     - Custom tabgroup labels with icons
#     - At least one input for filtering
#   - About page
#   - Apply a theme with custom colors
#   - Enable lazy loading for the analysis page
#   - Add a loading overlay
#
# This is your masterpiece! Take 20-30 minutes.

# YOUR CODE HERE:


# =============================================================================
# BONUS EXERCISES
# =============================================================================

# =============================================================================
# BONUS 1: Timeline with Response Filtering
# =============================================================================
#
# Goal: Show only "highly satisfied" (4-5) respondents over time
#
# Requirements:
#   - Create a timeline of satisfaction over years
#   - Filter to only show responses 4 and 5
#   - Combine into a single line with custom label

# First prepare appropriate data
timeline_data <- survey_data %>%
  group_by(year) %>%
  summarise(
    satisfaction = list(satisfaction),
    .groups = "drop"
  ) %>%
  tidyr::unnest(cols = c(satisfaction))

# YOUR CODE HERE:


# =============================================================================
# BONUS 2: Grouped Bar Chart
# =============================================================================
#
# Goal: Compare department distribution by gender
#
# Requirements:
#   - Create a grouped bar chart
#   - X-axis: department
#   - Group by: gender
#   - Horizontal, percent

# YOUR CODE HERE:


# =============================================================================
# BONUS 3: Theme Customization
# =============================================================================
#
# Goal: Create a dashboard with heavily customized theme
#
# Requirements:
#   - Start with theme_academic()
#   - Override: 
#     - Font to "Georgia"
#     - Font size to 18px
#     - Navbar color to dark red (#8B0000)
#     - Max width to 1400px

# YOUR CODE HERE:


# =============================================================================
# Congratulations! 🎉
# =============================================================================
#
# You've completed the dashboardr workshop exercises!
#
# Key takeaways:
# 1. Use create_viz() to set defaults, add_viz() for individual charts
# 2. Tabgroups organize content with "/" for nesting
# 3. Always print() your objects to see structure
# 4. Combine visualizations with + operator
# 5. Use filter = ~ condition for data subsets
# 6. Apply themes with apply_theme(theme_function())
# 7. Icons use the format "set:icon-name" (e.g., "ph:house-fill")
# 8. Content system allows mixing text, charts, callouts, etc.
# 9. Interactive inputs can filter your visualizations
# 10. Vectorized creation with add_vizzes() for efficiency
#
# Next steps:
# - Explore vignettes: vignette(package = "dashboardr")
# - Check documentation: ?create_viz, ?add_viz, ?create_dashboard
# - Publish your dashboard: publish_dashboard()
#
# Happy dashboarding! 📊
# =============================================================================
