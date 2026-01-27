# Build Features Demo Dashboard
# Showcases tabset styling, interactive inputs, and loading overlays
# Run from package root: source("pkgdown/build-features-demo.R")

library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

cat("📊 Building Features Demo Dashboard...\n\n")

# Prepare data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, region) %>%
  filter(year >= 2018,
         happy %in% 1:3, 
         polviews %in% 1:7,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(
    # Convert ALL haven_labelled variables to factors or plain types
    year = as.integer(year),
    age = as.integer(age),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    degree = droplevels(as_factor(degree)),
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews)),
    region = droplevels(as_factor(region))
  )

# ============================================================
# PAGE 1: Tab Styling - Pills Theme
# ============================================================
pills_page <- create_page(
  "Pills Theme",
  data = gss,
  type = "bar",
  icon = "ph:circles-four-fill",
  tabset_theme = "pills"
) %>%
  add_text(
    "## Pills Tab Theme",
    "",
    "This page uses `tabset_theme = \"pills\"` which creates rounded pill-shaped tab buttons.",
    "Navigate between the tabs below to see how they look."
  ) %>%
  add_code(
'create_page(
  "Pills Theme",
  data = gss,
  type = "bar",
  tabset_theme = "pills"
) %>%
  add_viz(x_var = "degree", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", tabgroup = "Attitudes")',
    language = "r"
  ) %>%
  add_viz(x_var = "degree", title = "Education Levels", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race Distribution", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", title = "Happiness Levels", tabgroup = "Attitudes") %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Attitudes")

# ============================================================
# PAGE 2: Tab Styling - Modern Theme
# ============================================================
modern_page <- create_page(
  "Modern Theme",
  data = gss,
  type = "bar",
  icon = "ph:squares-four-fill",
  tabset_theme = "modern"
) %>%
  add_text(
    "## Modern Tab Theme",
    "",
    "This page uses `tabset_theme = \"modern\"` for a clean, contemporary look.",
    "Compare this with the Pills theme on the previous page."
  ) %>%
  add_code(
'create_page(
  "Modern Theme",
  data = gss,
  type = "bar",
  tabset_theme = "modern"
) %>%
  add_viz(x_var = "degree", tabgroup = "Section A") %>%
  add_viz(x_var = "happy", tabgroup = "Section B")',
    language = "r"
  ) %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Section A") %>%
  add_viz(x_var = "sex", title = "Gender", tabgroup = "Section A") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Section B") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "Section B")

# ============================================================
# PAGE 3: Interactive Inputs - All Types
# ============================================================
inputs_page <- create_page(
  "Interactive Inputs",
  data = gss,
  type = "bar",
  icon = "ph:sliders-horizontal-fill"
) %>%
  add_text(
    "## Interactive Input Widgets",
    "",
    "Use the controls below to filter the data. All four input types are shown:",
    "",
    "- **Select dropdown** - Choose one or multiple education levels",
    "- **Checkboxes** - Toggle race categories on/off", 
    "- **Slider** - Filter by age range",
    "- **Radio buttons** - Select one gender"
  ) %>%
  add_code(
'create_page("Inputs Demo", data = gss, type = "bar") %>%
  add_input_row() %>%
    add_input(
      input_id = "edu", label = "Education",
      type = "select_multiple", filter_var = "degree"
    ) %>%
    add_input(
      input_id = "race", label = "Race", 
      type = "checkbox", filter_var = "race", inline = TRUE
    ) %>%
  end_input_row() %>%
  add_input_row() %>%
    add_input(
      input_id = "age", label = "Age Range",
      type = "slider", filter_var = "age", min = 18, max = 89
    ) %>%
    add_input(
      input_id = "sex", label = "Gender",
      type = "radio", filter_var = "sex", inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", title = "Happiness")',
    language = "r"
  ) %>%
  add_text("", "---", "") %>%
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
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Gender") %>%
  add_viz(x_var = "polviews", title = "Political Views Distribution")

# ============================================================
# PAGE 4: Loading Overlay - Glass Theme
# ============================================================
overlay_page <- create_page(
  "Loading Overlay",
  data = gss,
  type = "bar",
  icon = "ph:spinner-gap-fill",
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading visualizations...",
  overlay_duration = 2000
) %>%
  add_text(
    "## Loading Overlay Demo",
    "",
    "This page uses the **glass** overlay theme. When you reload this page,",
    "you'll see a frosted glass effect while the charts render.",
    "",
    "**Reload this page** to see the overlay effect!"
  ) %>%
  add_code(
'create_page(
  "Loading Overlay",
  data = gss,
  type = "bar",
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading visualizations...",
  overlay_duration = 2000
) %>%
  add_viz(x_var = "degree", title = "Education")',
    language = "r"
  ) %>%
  add_text(
    "",
    "### Available Overlay Themes",
    "",
    "| Theme | Description |",
    "|-------|-------------|",
    "| `glass` | Semi-transparent frosted glass effect |",
    "| `light` | Clean white background |",
    "| `dark` | Dark background for dark themes |",
    "| `accent` | Uses your dashboard's accent color |"
  ) %>%
  add_viz(x_var = "degree", title = "Education Levels", tabgroup = "Charts") %>%
  add_viz(x_var = "race", title = "Race Distribution", tabgroup = "Charts") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Charts")

# ============================================================
# PAGE 5: About This Demo
# ============================================================
about_page <- create_page(
  "About",
  icon = "ph:info-fill",
  navbar_align = "right"
) %>%
  add_text(
    "## About This Demo",
    "",
    "This dashboard showcases key **dashboardr** features. Each page demonstrates",
    "a different capability with the actual code that generates it.",
    "",
    "### Features Demonstrated",
    "",
    "| Page | Feature | Key Parameters |",
    "|------|---------|----------------|",
    "| Pills Theme | Tab styling | `tabset_theme = \"pills\"` |",
    "| Modern Theme | Tab styling | `tabset_theme = \"modern\"` |",
    "| Interactive Inputs | Filtering widgets | `add_input()`, `add_input_row()` |",
    "| Loading Overlay | Loading animation | `overlay = TRUE`, `overlay_theme` |",
    "",
    "### Learn More",
    "",
    "- [dashboardr Documentation](https://favstats.github.io/dashboardr/)",
    "- [Getting Started Guide](https://favstats.github.io/dashboardr/articles/getting-started.html)",
    "- [Advanced Features](https://favstats.github.io/dashboardr/articles/advanced-features.html)"
  )

# ============================================================
# CREATE AND GENERATE DASHBOARD
# ============================================================
find_pkg_root <- function() {
  dir <- getwd()
  for (i in 1:10) {
    if (file.exists(file.path(dir, "DESCRIPTION"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  stop("Could not find package root. Run from package directory.")
}

pkg_root <- find_pkg_root()
output_dir <- file.path(pkg_root, "docs", "live-demos", "features")

cat("   Package root:", pkg_root, "\n")
cat("   Output dir:", output_dir, "\n")

# Clean up old files if they exist
if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dashboard <- create_dashboard(
  title = "dashboardr Features Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern",
  allow_inside_pkg = TRUE
) %>%
  add_pages(
    pills_page,
    modern_page,
    inputs_page,
    overlay_page,
    about_page
  )

# Generate
result <- tryCatch(
  generate_dashboard(dashboard, render = TRUE, open = FALSE),
  error = function(e) {
    cat("   ⚠️  generate_dashboard error:", e$message, "\n")
    NULL
  }
)

# Check for HTML output
html_locations <- c(
  file.path(output_dir, "index.html"),
  file.path(output_dir, "docs", "index.html")
)

html_found <- FALSE
for (loc in html_locations) {
  if (file.exists(loc)) {
    cat("   ✅ Features demo HTML found at:", loc, "\n")
    html_found <- TRUE
    break
  }
}

if (!html_found) {
  cat("   ⚠️  QMD files created but HTML not rendered (Quarto may not be installed)\n")
  cat("   📁 To render manually: cd", output_dir, "&& quarto render .\n")
}
