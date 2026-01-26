# Build Interactive Inputs Demo Dashboard
# Run this script to generate the inputs demo for the docs

library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Prepare data with multiple years for richer filtering
data(gss_all)
gss_inputs <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, region) %>%
  filter(year >= 2010 & year <= 2022,
         happy %in% 1:3, 
         polviews %in% 1:7,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    degree = droplevels(as_factor(degree)),
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews)),
    region = droplevels(as_factor(region))
  )

# Page 1: Select and Checkbox inputs
select_page <- create_page(
  "Select & Checkbox",
  data = gss_inputs,
  type = "bar",
  icon = "ph:list-checks-fill"
) %>%
  add_text(
    "## Select & Checkbox Inputs",
    "",
    "Use the dropdown and checkboxes below to filter the data.",
    "The charts update automatically based on your selections."
  ) %>%
  add_callout(
    "**Try it:** Select different education levels and check/uncheck races to see how the charts change.",
    type = "tip"
  ) %>%
  add_input_row() %>%
    add_input(
      input_id = "edu_select",
      label = "Education Level",
      type = "select_multiple",
      filter_var = "degree",
      options_from = "degree"
    ) %>%
    add_input(
      input_id = "race_check",
      label = "Race",
      type = "checkbox",
      filter_var = "race",
      options_from = "race",
      inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Gender", tabgroup = "Results") %>%
  add_viz(x_var = "polviews", title = "Political Views Distribution", tabgroup = "Results")

# Page 2: Slider and Radio inputs
slider_page <- create_page(
  "Slider & Radio",
  data = gss_inputs,
  type = "bar",
  icon = "ph:sliders-fill"
) %>%
  add_text(
    "## Slider & Radio Button Inputs",
    "",
    "Filter by age range using the slider, or select a specific gender."
  ) %>%
  add_input_row() %>%
    add_input(
      input_id = "age_slider",
      label = "Age Range",
      type = "slider",
      filter_var = "age",
      min = 18,
      max = 89,
      value = c(25, 65)
    ) %>%
    add_input(
      input_id = "sex_radio",
      label = "Gender",
      type = "radio",
      filter_var = "sex",
      options_from = "sex",
      inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "degree", title = "Education Distribution") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

# Page 3: Combined example
combined_page <- create_page(
  "Full Example",
  data = gss_inputs,
  type = "bar",
  icon = "ph:funnel-fill"
) %>%
  add_text(
    "## Complete Filtering Example",
    "",
    "This page combines multiple input types for comprehensive data exploration."
  ) %>%
  add_input_row() %>%
    add_input(
      input_id = "year_select",
      label = "Survey Year",
      type = "select_single",
      filter_var = "year",
      options_from = "year"
    ) %>%
    add_input(
      input_id = "edu_full",
      label = "Education",
      type = "select_multiple",
      filter_var = "degree",
      options_from = "degree"
    ) %>%
  end_input_row() %>%
  add_input_row() %>%
    add_input(
      input_id = "race_full",
      label = "Race",
      type = "checkbox",
      filter_var = "race",
      options_from = "race",
      inline = TRUE
    ) %>%
    add_input(
      input_id = "sex_full",
      label = "Gender",
      type = "radio",
      filter_var = "sex",
      options_from = "sex",
      inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Gender", tabgroup = "Analysis") %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Analysis") %>%
  add_viz(x_var = "degree", title = "Education Breakdown", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race Distribution", tabgroup = "Demographics")

# Create and generate dashboard
# Output to docs/live-demos/inputs within the package
# Note: Run this script from the package root directory
output_dir <- here::here("docs", "live-demos", "inputs")

create_dashboard(
  title = "Interactive Inputs Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern"
) %>%
  add_pages(select_page, slider_page, combined_page) %>%
  generate_dashboard(render = TRUE)

cat("\n✅ Inputs demo generated at:", output_dir, "\n")
