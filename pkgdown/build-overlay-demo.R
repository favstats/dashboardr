# Build Loading Overlay Demo Dashboard
# Run from package root: source("pkgdown/build-overlay-demo.R")

library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

cat("📊 Building Overlay Demo Dashboard...\n\n")

# Prepare data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  filter(happy %in% 1:3, polviews %in% 1:7,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(
    # Convert ALL haven_labelled variables to factors or plain types
    year = as.integer(year),
    age = as.integer(age),
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

# ============================================================
# Find package root and set output directory
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
output_dir <- file.path(pkg_root, "docs", "live-demos", "overlay")

cat("   Package root:", pkg_root, "\n")
cat("   Output dir:", output_dir, "\n")

# Clean up old files
if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

about_page <- create_page(
  "About",
  icon = "ph:info",
  navbar_align = "right"
) %>%
  add_text(
    "## About This Demo",
    "",
    "This dashboard demonstrates the four loading overlay themes available in dashboardr.",
    "Each page shows a different theme — reload the page to see the overlay animation again.",
    "",
    "### Overlay Themes",
    "",
    "| Theme | Description |",
    "|-------|-------------|",
    "| `glass` | Semi-transparent frosted effect |",
    "| `light` | Clean white background |",
    "| `dark` | Dark background, ideal for dark themes |",
    "| `accent` | Uses your dashboard's accent color |",
    "",
    "### Usage",
    "",
    "```r",
    "create_page(",
    "  \"My Page\",",
    "  overlay = TRUE,",
    "  overlay_theme = \"glass\",",
    "  overlay_text = \"Loading...\",",
    "  overlay_duration = 2000",
    ")",
    "```",
    "",
    "### Source Code",
    "",
    "The full R code that generates this dashboard is available on GitHub:",
    "",
    "- [View Source Code](https://github.com/favstats/dashboardr/blob/main/pkgdown/build-overlay-demo.R)",
    "",
    "### Learn More",
    "",
    "- [dashboardr Documentation](https://favstats.github.io/dashboardr/)",
    "- [Community Gallery](https://favstats.github.io/dashboardr/gallery/)"
  )

dashboard <- create_dashboard(
  title = "Loading Overlay Demo",
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "modern",
  allow_inside_pkg = TRUE  # Required for pkgdown demos
) %>%
  add_pages(glass_page, light_page, dark_page, accent_page, about_page)

# Generate
result <- tryCatch(
  generate_dashboard(dashboard, render = TRUE, open = FALSE),
  error = function(e) {
    cat("   ⚠️  generate_dashboard error:", e$message, "\n")
    NULL
  }
)

# Check for HTML and move if in docs/ subdirectory
html_locations <- c(
  file.path(output_dir, "index.html"),
  file.path(output_dir, "docs", "index.html")
)

html_found <- FALSE
for (loc in html_locations) {
  if (file.exists(loc)) {
    cat("   ✅ Overlay demo HTML found at:", loc, "\n")
    html_found <- TRUE
    
    if (grepl("/docs/index.html$", loc)) {
      docs_dir <- dirname(loc)
      files_to_move <- list.files(docs_dir, full.names = TRUE)
      for (f in files_to_move) {
        file.copy(f, output_dir, recursive = TRUE, overwrite = TRUE)
      }
      unlink(docs_dir, recursive = TRUE)
      cat("   📁 Moved HTML files to root of output_dir\n")
    }
    break
  }
}

if (!html_found) {
  cat("   ⚠️  QMD files created but HTML not rendered\n")
  cat("   📁 To render manually: cd", output_dir, "&& quarto render .\n")
}
