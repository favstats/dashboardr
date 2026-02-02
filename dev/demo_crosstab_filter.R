# =============================================================================
# Demo: Intuitive Cross-Tab Filtering
# =============================================================================

library(dashboardr)
library(dplyr)

# Load and prepare data
library(gssr)
data(gss_panel20)

gss_clean <- gss_panel20 %>%
  select(sex_1a, degree_1a, region_1a, happy_1a) %>%
  filter(if_any(everything(), ~ !is.na(.))) %>%
  mutate(
    sex = as.character(haven::as_factor(sex_1a)),
    degree = as.character(haven::as_factor(degree_1a)),
    region = as.character(haven::as_factor(region_1a)),
    happy = as.character(haven::as_factor(happy_1a))
  ) %>%
  filter(!is.na(sex), !is.na(degree), !is.na(happy)) %>%
  select(sex, degree, region, happy)

cat("Data prepared:", nrow(gss_clean), "rows\n\n")

# =============================================================================
# PAGE 1: SIMPLE API with add_filter()
# =============================================================================

simple_content <- create_content(data = gss_clean) %>%
  add_sidebar(width = "280px", title = "Filter Data", position = "left") %>%
    add_filter(
      filter_var = "degree",
      type = "radio",
      stacked = TRUE,  # dots centered above labels
      group_align = "center",  # center the whole group
      ncol = 3,  # 3 columns like facet_wrap(ncol = 3)
      add_all = TRUE,
      add_all_label = "Alle"
    ) %>%
    add_filter(filter_var = "sex") %>%
  end_sidebar() %>%
  add_viz(
    type = "stackedbar",
    x_var = "region",
    stack_var = "happy",
    title = "Happiness by Region",
    subtitle = "Toggle filters to recalculate percentages",
    stacked_type = "percent",
    stack_order = c("very happy", "pretty happy", "not too happy"),
    color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
    height = 500
  )

# =============================================================================
# PAGE 2: FULL API with add_input()
# =============================================================================

degree_values <- sort(unique(gss_clean$degree))
sex_values <- sort(unique(gss_clean$sex))

full_api_content <- create_content(data = gss_clean) %>%
  add_sidebar(width = "280px", title = "Filter Data", position = "left") %>%
    add_input(
      input_id = "education_filter",
      label = "Education Level:",
      type = "radio",
      filter_var = "degree",
      options = degree_values,
      default_selected = degree_values[1],
      inline = TRUE,  # horizontal layout
      stacked = TRUE,
      add_all = TRUE,
      add_all_label = "All"
    ) %>%
    add_input(
      input_id = "gender_filter",
      label = "Gender:",
      type = "checkbox",
      filter_var = "sex",
      stacked = TRUE,
      options = sex_values,
      default_selected = sex_values
    ) %>%
  end_sidebar() %>%
  add_viz(
    type = "stackedbar",
    x_var = "region",
    stack_var = "happy",
    title = "Happiness by Region",
    subtitle = "Same chart, different API",
    stacked_type = "percent",
    stack_order = c("very happy", "pretty happy", "not too happy"),
    color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
    height = 500
  )

# =============================================================================
# CREATE DASHBOARD
# =============================================================================

dashboard <- create_dashboard(
  output_dir = "demo_crosstab_output",
  title = "Filter Demo",
  theme = "flatly",
  allow_inside_pkg = TRUE
) %>%
  add_page(
    name = "Simple API",
    data = gss_clean,
    content = simple_content,
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Full API",
    data = gss_clean,
    content = full_api_content
  ) %>%
  generate_dashboard()

cat("\n")
cat("=============================================\n")
cat("Dashboard generated in: demo_crosstab_output/\n")
cat("=============================================\n")
cat("\n")
cat("To view: quarto preview demo_crosstab_output\n")
