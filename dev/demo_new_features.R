################################################################################
# DEMO: New Features in dashboardr
#
# This script demonstrates all the latest features:
# 1. HTML format options (fonts, colors, margins, etc.)
# 2. Navbar color customization
# 3. Pipeable theme system (theme_ascor, theme_academic, theme_modern, etc.)
# 4. apply_theme() function
# 5. ASCoR/UvA branded dashboard
################################################################################

# Load the development version with new features
devtools::load_all()
library(dplyr)

# Prepare sample data
data(mtcars)
cars_data <- mtcars %>%
  mutate(
    cyl_label = paste(cyl, "cylinders"),
    am_label = ifelse(am == 0, "Automatic", "Manual"),
    vs_label = ifelse(vs == 0, "V-shaped", "Straight")
  )

# Create visualizations
car_viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "Miles Per Gallon Distribution",
    subtitle = "Fuel efficiency across all vehicles",
    bins = 15,
    height = 400,
    tabgroup = "efficiency"
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "hp",
    title = "Horsepower Distribution",
    subtitle = "Engine power across vehicle types",
    bins = 12,
    height = 400,
    tabgroup = "efficiency"
  ) %>%
  set_tabgroup_labels(list(
    efficiency = "Fuel Efficiency",
    performance = "Performance Metrics"
  ))


################################################################################
# DEMO 1: New HTML Format Options & Navbar Color
################################################################################

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  🎨 DEMO 1: HTML Format Options & Navbar Color                   ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

demo1_dashboard <- create_dashboard(
  output_dir = "demo1_format_options",
  title = "Demo: HTML Format Options",
  github = "https://github.com/favstats/dashboardr",
  twitter = "https://twitter.com/username",
  linkedin = "https://linkedin.com/in/username",
  email = "user@example.com",
  website = "https://example.com",

  # NEW: Navbar color customization
  navbar_bg_color = "black",  # Deep blue

  # NEW: Typography options
  mainfont = "Inter",
  fontsize = "17px",
  fontcolor = "black",
  linkcolor = "#2563eb",
  monofont = "Fira Code",
  monobackgroundcolor = "#f8fafc",
  navbar_text_color = "red",
  # NEW: Layout options
  linestretch = 1.7,
  backgroundcolor = "#ffffff",
  max_width = "1200px",
  margin_left = "2rem",
  margin_right = "2rem",
  margin_top = "1rem",
  margin_bottom = "1rem", tabset_theme = "pills"
) %>%
  add_page(
    "Home",
    text = md_text(
      "# Welcome to the Format Options Demo",
      "",
      "This dashboard showcases **all the new HTML format customization options**:",
      "",
      "## New Features",
      "",
      "- **Navbar Color**: Custom `navbar_color` parameter",
      "- **Typography**: `mainfont`, `fontsize`, `fontcolor`, `linkcolor`",
      "- **Code Styling**: `monofont`, `monobackgroundcolor`",
      "- **Layout**: `linestretch`, `max_width`, margins",
      "",
      "## Example Code",
      "",
      "```r",
      "library(dashboardr)",
      "dashboard <- create_dashboard(",
      "  navbar_color = '#1e40af',",
      "  mainfont = 'Inter',",
      "  fontsize = '17px'",
      ")",
      "```",
      "",
      "Notice the beautiful typography and spacing!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page(
    "Analysis",
    text = "## Car Performance Analysis\n\nExplore fuel efficiency and performance metrics.",
    data = cars_data,
    visualizations = car_viz
  )

generate_dashboard(demo1_dashboard, render = TRUE, open = "browser")


################################################################################
# DEMO 2: Pipeable Theme System - ASCoR Theme
################################################################################

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  🎓 DEMO 2: ASCoR/UvA Theme (Pipeable!)                           ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

demo2_dashboard <- create_dashboard(
  output_dir = "demo2_ascor_theme",
  title = "Demo: ASCoR Theme"
) %>%
  # NEW: Pipe theme directly into dashboard!
  apply_theme(theme_ascor()) %>%
  add_page(
    "Welcome",
    text = md_text(
      "# University of Amsterdam - ASCoR",
      "",
      "This dashboard uses the **ASCoR/UvA theme** with:",
      "",
      "- UvA red (#CB0D0D) branding",
      "- Professional Inter font",
      "- Clean, academic styling",
      "",
      "## Apply the Theme",
      "",
      "```r",
      "dashboard <- create_dashboard('my_dashboard', 'My Research') %>%",
      "  apply_theme(theme_ascor()) %>%",
      "  add_page('Home', text = '# Welcome')",
      "```",
      "",
      "That's it! The theme is applied via piping. 🎉"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page(
    "Research Data",
    text = "## Vehicle Research Data\n\nAnalyzing automotive performance.",
    data = cars_data,
    visualizations = car_viz
  )

generate_dashboard(demo2_dashboard, render = TRUE, open = "browser")


################################################################################
# DEMO 3: All Available Themes
################################################################################

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  🎨 DEMO 3: Theme Gallery (All Available Themes)                 ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

# Academic Theme (Blue)
cat("→ Generating Academic Theme dashboard...\n")
demo3a_dashboard <- create_dashboard(
  output_dir = "demo3a_academic_theme",
  title = "Demo: Academic Theme"
) %>%
  apply_theme(theme_academic()) %>%
  add_page(
    "Home",
    text = md_text(
      "# Academic Theme",
      "",
      "Clean, professional theme suitable for any academic institution.",
      "",
      "```r",
      "apply_theme(theme_academic())",
      "```"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page("Data", data = cars_data, visualizations = car_viz)

generate_dashboard(demo3a_dashboard, render = TRUE, open = "browser")


# Modern Theme - Purple
cat("→ Generating Modern Theme (Purple) dashboard...\n")
demo3b_dashboard <- create_dashboard(
  output_dir = "demo3b_modern_purple",
  title = "Demo: Modern Purple Theme"
) %>%
  apply_theme(theme_modern(style = "white")) %>%
  add_page(
    "Home",
    text = md_text(
      "# Modern Purple Theme",
      "",
      "Sleek, contemporary design for tech companies.",
      "",
      "```r",
      "apply_theme(theme_modern(style = 'purple'))",
      "```",
      "",
      "Available colors: blue, purple, green, orange"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page("Analytics", data = cars_data, visualizations = car_viz)

generate_dashboard(demo3b_dashboard, render = TRUE, open = "browser")


# Modern Theme - Green
cat("→ Generating Modern Theme (Green) dashboard...\n")
demo3c_dashboard <- create_dashboard(
  output_dir = "demo3c_modern_green",
  title = "Demo: Modern Green Theme"
) %>%
  apply_theme(theme_modern(style = "green")) %>%
  add_page(
    "Home",
    text = md_text(
      "# Modern Green Theme",
      "",
      "Fresh, eco-friendly design.",
      "",
      "```r",
      "apply_theme(theme_modern(style = 'green'))",
      "```"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page("Data", data = cars_data, visualizations = car_viz)

generate_dashboard(demo3c_dashboard, render = TRUE, open = "browser")


# Minimal Theme
cat("→ Generating Minimal Theme dashboard...\n")
demo3d_dashboard <- create_dashboard(
  output_dir = "demo3d_minimal_theme",
  title = "Demo: Minimal Theme"
) %>%
  apply_theme(theme_minimal()) %>%
  add_page(
    "Home",
    text = md_text(
      "# Minimal Theme",
      "",
      "Ultra-clean, content-focused design.",
      "",
      "```r",
      "apply_theme(theme_minimal())",
      "```"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page("Report", data = cars_data, visualizations = car_viz)

generate_dashboard(demo3d_dashboard, render = TRUE, open = "browser")


################################################################################
# DEMO 4: Custom Academic Theme with University Colors
################################################################################

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  🏛️  DEMO 4: Custom Academic Theme (Your University Colors)      ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

demo4_dashboard <- create_dashboard(
  output_dir = "demo4_custom_university",
  title = "Demo: Custom University Theme"
) %>%
  # Use academic theme with custom color (e.g., Harvard Crimson)
  apply_theme(theme_academic(accent_color = "#A51C30")) %>%
  add_page(
    "Home",
    text = md_text(
      "# Custom University Branding",
      "",
      "The academic theme accepts **any color** for your institution:",
      "",
      "```r",
      "# Harvard Crimson",
      "apply_theme(theme_academic(accent_color = '#A51C30'))",
      "",
      "# Oxford Blue",
      "apply_theme(theme_academic(accent_color = '#002147'))",
      "",
      "# Stanford Cardinal",
      "apply_theme(theme_academic(accent_color = '#8C1515'))",
      "```",
      "",
      "Perfect for any university or research institution!"
    ),
    is_landing_page = TRUE
  ) %>%
  add_page("Research", data = cars_data, visualizations = car_viz)

generate_dashboard(demo4_dashboard, render = TRUE, open = "browser")


################################################################################
# DEMO 5: Full ASCoR Dashboard Function
################################################################################

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  🎓 DEMO 5: Full ASCoR Dashboard (with GSS data)                 ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

# Check if gssr package is available
if (requireNamespace("gssr", quietly = TRUE)) {
  ascor_dashboard(directory = "demo5_full_ascor")
} else {
  cat("⚠️  Skipping full ASCoR dashboard (requires 'gssr' package)\n")
  cat("   Install with: install.packages('gssr')\n")
}


################################################################################
# SUMMARY
################################################################################

cat("\n\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║  ✨ DEMO COMPLETE! All Features Showcased                        ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n\n")

cat("Generated dashboards:\n")
cat("  1. demo1_format_options/    - HTML format options & navbar color\n")
cat("  2. demo2_ascor_theme/       - ASCoR/UvA theme (pipeable)\n")
cat("  3. demo3a_academic_theme/   - Academic theme\n")
cat("  4. demo3b_modern_purple/    - Modern purple theme\n")
cat("  5. demo3c_modern_green/     - Modern green theme\n")
cat("  6. demo3d_minimal_theme/    - Minimal theme\n")
cat("  7. demo4_custom_university/ - Custom university colors\n")
if (requireNamespace("gssr", quietly = TRUE)) {
  cat("  8. demo5_full_ascor/        - Full ASCoR dashboard with GSS data\n")
}

cat("\n")
cat("🎨 NEW FEATURES:\n")
cat("  ✓ navbar_color parameter\n")
cat("  ✓ HTML format options (fonts, colors, margins, etc.)\n")
cat("  ✓ Pipeable theme system\n")
cat("  ✓ theme_ascor(), theme_uva(), theme_academic()\n")
cat("  ✓ theme_modern(), theme_minimal()\n")
cat("  ✓ apply_theme() function\n")
cat("  ✓ Full ASCoR/UvA branded dashboard\n")

cat("\n")
cat("📚 Quick Start:\n")
cat("  dashboard <- create_dashboard('my_dash', 'My Dashboard') %>%\n")
cat("    apply_theme(theme_ascor()) %>%\n")
cat("    add_page('Home', text = '# Welcome')\n")
cat("\n")
cat("Happy dashing! 🚀\n\n")

