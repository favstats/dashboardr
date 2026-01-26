# Build Loading Overlay Demo Dashboard
# Run this script to generate the overlay demo for the docs

library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Prepare data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  filter(happy %in% 1:3, polviews %in% 1:7,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    degree = droplevels(as_factor(degree)),
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews))
  )

# Create pages with different overlay themes
glass_page <- create_page(
  "Glass Theme",
  data = gss,
  type = "bar",
  icon = "ph:sparkle-fill",
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading visualizations...",
  overlay_duration = 2000
) %>%
  add_text("## Glass Overlay Theme", "", 
           "This page uses the **glass** overlay theme - a semi-transparent frosted effect.",
           "Reload the page to see the overlay again.") %>%
  add_viz(x_var = "degree", title = "Education Levels", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race Distribution", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", title = "Happiness Levels", tabgroup = "Attitudes") %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Attitudes")

light_page <- create_page(

  "Light Theme",
  data = gss,
  type = "bar",
  icon = "ph:sun-fill",
  overlay = TRUE,
  overlay_theme = "light",
  overlay_text = "Preparing your dashboard...",
  overlay_duration = 2000
) %>%
  add_text("## Light Overlay Theme", "",
           "This page uses the **light** overlay theme - a clean white background.",
           "Reload the page to see the overlay again.") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

dark_page <- create_page(
  "Dark Theme",
  data = gss,
  type = "bar",
  icon = "ph:moon-fill",
  overlay = TRUE,
  overlay_theme = "dark",
  overlay_text = "Almost ready...",
  overlay_duration = 2000
) %>%
  add_text("## Dark Overlay Theme", "",
           "This page uses the **dark** overlay theme - ideal for dark-themed dashboards.",
           "Reload the page to see the overlay again.") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

accent_page <- create_page(
  "Accent Theme",
  data = gss,
  type = "bar",
  icon = "ph:paint-brush-fill",
  overlay = TRUE,
  overlay_theme = "accent",
  overlay_text = "Loading...",
  overlay_duration = 2000
) %>%
  add_text("## Accent Overlay Theme", "",
           "This page uses the **accent** overlay theme - uses your dashboard's accent color.",
           "Reload the page to see the overlay again.") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

# Create and generate dashboard
# Output to docs/live-demos/overlay within the package
# Note: Run this script from the package root directory
output_dir <- here::here("docs", "live-demos", "overlay")

create_dashboard(
  title = "Loading Overlay Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern"
) %>%
  add_pages(glass_page, light_page, dark_page, accent_page) %>%
  generate_dashboard(render = TRUE)

cat("\n✅ Overlay demo generated at:", output_dir, "\n")
