# Test different viewport options for mobile rendering

devtools::load_all()
library(tidyverse)

# Sample data
data <- mtcars %>% rownames_to_column("car")

cat("Creating test dashboards with different viewport settings...\n\n")

# ===== OPTION 1: Default (Responsive) =====
cat("1. Creating RESPONSIVE dashboard (default)...\n")
create_dashboard(
  title = "Option 1: Responsive (Default)",
  # viewport_width = NULL (default)
  publish_dir = "test_viewport_1_responsive"
) %>%
  add_page(name = "Home", description = "**Default responsive behavior**\n\nNo viewport set. Mobile browsers optimize for mobile.") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# ===== OPTION 2: Fixed Desktop Width =====
cat("2. Creating DESKTOP FIXED WIDTH dashboard (1200px)...\n")
create_dashboard(
  title = "Option 2: Desktop Fixed (1200px)",
  viewport_width = 1200,  # Forces desktop rendering at 1200px
  publish_dir = "test_viewport_2_fixed"
) %>%
  add_page(name = "Home", description = "**Fixed desktop width: 1200px**\n\nMobile renders at 1200px like desktop. Users can pinch-zoom.") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# ===== OPTION 3: Fixed Width + Zoom Out =====
cat("3. Creating DESKTOP + ZOOM OUT dashboard...\n")
create_dashboard(
  title = "Option 3: Desktop + Zoom (1200px @ 0.3)",
  viewport_width = 1200,
  viewport_scale = 0.3,  # Zoom out to fit whole page
  publish_dir = "test_viewport_3_zoomed"
) %>%
  add_page(name = "Home", description = "**Desktop width with zoom: 1200px @ 0.3 scale**\n\nShows whole page on mobile, users can zoom in to details.") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# ===== OPTION 4: Ultra-Wide =====
cat("4. Creating ULTRA-WIDE dashboard (1600px)...\n")
create_dashboard(
  title = "Option 4: Ultra-Wide (1600px)",
  viewport_width = 1600,
  publish_dir = "test_viewport_4_ultrawide"
) %>%
  add_page(name = "Home", description = "**Ultra-wide: 1600px**\n\nFor really wide dashboards.") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# ===== OPTION 5: Advanced Custom String =====
cat("5. Creating CUSTOM viewport string...\n")
create_dashboard(
  title = "Option 5: Custom Viewport String",
  viewport_width = "width=1200, minimum-scale=0.5, maximum-scale=2.0",
  publish_dir = "test_viewport_5_custom"
) %>%
  add_page(name = "Home", description = "**Custom viewport string**\n\nFull control: `width=1200, minimum-scale=0.5, maximum-scale=2.0`") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# ===== OPTION 6: With Mobile TOC =====
cat("6. Creating DESKTOP WIDTH + MOBILE TOC...\n")
create_dashboard(
  title = "Option 6: Desktop + Mobile TOC",
  viewport_width = 1200,
  mobile_toc = TRUE,  # Adds the 📑 button
  publish_dir = "test_viewport_6_with_toc"
) %>%
  add_page(name = "Home", description = "**Desktop width + Mobile TOC**\n\nCombines desktop rendering with collapsible navigation button (📑).") %>%
  add_viz_content(create_bar(data = data, x_var = "cyl", title = "Cars by Cylinder")) %>%
  add_page(name = "Page 2", description = "Second page for testing navigation") %>%
  add_viz_content(create_histogram(data = data, x_var = "mpg", title = "MPG Distribution")) %>%
  generate_dashboard(render = TRUE, open = FALSE)

cat("\n✅ All test dashboards created!\n\n")
cat("Test Directories Created:\n")
cat("  1. test_viewport_1_responsive/    (default responsive)\n")
cat("  2. test_viewport_2_fixed/         (1200px fixed)\n")
cat("  3. test_viewport_3_zoomed/        (1200px @ 0.3 scale)\n")
cat("  4. test_viewport_4_ultrawide/     (1600px)\n")
cat("  5. test_viewport_5_custom/        (custom string)\n")
cat("  6. test_viewport_6_with_toc/      (1200px + mobile TOC)\n\n")
cat("📱 Open these on your mobile device to compare!\n")
cat("   Try #2 first (fixed 1200px) - likely what you want.\n\n")

# Open the first one for quick testing
cat("Opening Option 2 (Fixed 1200px) in browser...\n")
browseURL("test_viewport_2_fixed/index.html")









