# Test mobile-friendly features with actual content

devtools::load_all()
library(tidyverse)

# Sample data
data <- mtcars %>%
  rownames_to_column("car") %>%
  mutate(
    cyl = factor(cyl),
    transmission = factor(am, levels = 0:1, labels = c("Automatic", "Manual"))
  )

# Create a comprehensive dashboard with mobile TOC
create_dashboard(
  title = "🚗 Mobile-Friendly Car Dashboard",
  page_layout = "full",      # ← Full width for better mobile experience
  mobile_toc = TRUE,          # ← Adds collapsible TOC button (📑)
  theme = "lumen",
  back_to_top = TRUE,
  publish_dir = "test_mobile_dashboard"
) %>%

  # === HOME PAGE ===
  add_page(
    name = "Home",
    description = "**Welcome to the Mobile-Friendly Dashboard Demo!**

This dashboard demonstrates the new mobile features:

- 📱 **Full-width layout** - Charts use all available space
- 📑 **Mobile TOC** - Click the 📑 button in the top-right corner!
- 🎯 **Proper viewport** - No weird zooming on mobile phones
- 📊 **Interactive charts** - Try them on your mobile device

## Quick Navigation

Use the sidebar (desktop) or the 📑 button (mobile) to jump between sections:

1. **Overview** - Key statistics and summary
2. **Performance** - MPG and horsepower analysis
3. **Engine Details** - Cylinder and displacement info
4. **Comparison** - Side-by-side comparisons

## Test on Mobile

1. Open this dashboard on your phone
2. Look for the 📑 icon in the top-right corner
3. Tap it to see the navigation menu slide in
4. Tap outside or tap again to close it

The charts should look great and be fully interactive on mobile!"
  ) %>%

  # === OVERVIEW PAGE ===
  add_page(
    name = "Overview"
  ) %>%
  add_viz_content(
    create_bar(
      data = data,
      x_var = "cyl",
      title = "Cars by Cylinder Count",
      horizontal = TRUE,
      bar_type = "count"
    )
  ) %>%

  # === PERFORMANCE PAGE ===
  add_page(
    name = "Performance",
    description = "## ⚡ Performance Analysis

### Fuel Efficiency

Miles per gallon (MPG) distribution across all vehicles."
  ) %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "mpg",
      title = "Miles Per Gallon Distribution",
      histogram_type = "count",
      bins = 10
    )
  ) %>%
  add_section("### Horsepower Analysis") %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "hp",
      title = "Horsepower Distribution",
      histogram_type = "count",
      bins = 8
    )
  ) %>%
  add_section("### MPG by Transmission Type") %>%
  add_viz_content(
    create_bar(
      data = data,
      x_var = "transmission",
      group_var = "cyl",
      title = "MPG by Transmission and Cylinders",
      horizontal = TRUE
    )
  ) %>%

  # === ENGINE DETAILS PAGE ===
  add_page(
    name = "Engine Details",
    description = "## 🔧 Engine Specifications

### Cylinder Configuration

How many cylinders do these classic cars have?"
  ) %>%
  add_viz_content(
    create_stackedbar(
      data = data,
      x_var = "cyl",
      stack_var = "transmission",
      title = "Transmission Type by Cylinder Count",
      stacked_type = "percent",
      horizontal = FALSE
    )
  ) %>%
  add_section("### Displacement Analysis") %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "disp",
      title = "Engine Displacement (cubic inches)",
      histogram_type = "count",
      bins = 10
    )
  ) %>%
  add_section("### Weight Distribution") %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "wt",
      title = "Vehicle Weight (1000 lbs)",
      histogram_type = "count",
      bins = 10
    )
  ) %>%

  # === COMPARISON PAGE ===
  add_page(
    name = "Comparison",
    description = "## 🔍 Detailed Comparisons

### Efficiency vs Power

#### High MPG Cars (> 25 MPG)"
  ) %>%
  add_viz_content(
    create_bar(
      data = data %>% filter(mpg > 25),
      x_var = "car",
      title = "Most Fuel Efficient Cars",
      horizontal = TRUE,
      bar_type = "count"
    )
  ) %>%
  add_viz_content(
    create_bar(
      data = data %>% filter(hp > 150),
      x_var = "car",
      title = "Most Powerful Cars",
      horizontal = TRUE,
      bar_type = "count"
    )
  ) %>%
  add_section("### Cylinders vs Transmission") %>%

  # Generate and open
  generate_dashboard(render = TRUE, open = "browser")

cat("\n✅ Enhanced Mobile Dashboard Created!\n\n")
cat("Features:\n")
cat("  ✅ page_layout: 'full' (full viewport width)\n")
cat("  ✅ mobile_toc: TRUE (📑 button for navigation)\n")
cat("  ✅ viewport meta tag (proper mobile rendering)\n")
cat("  ✅ Multiple pages with actual visualizations\n")
cat("  ✅ Multiple sections per page (for TOC)\n\n")
cat("📱 Test on Mobile:\n")
cat("  1. Open on your phone\n")
cat("  2. Tap the 📑 icon (top-right)\n")
cat("  3. See the navigation slide in!\n")
cat("  4. Notice all the H2/H3/H4 headers in the TOC\n\n")
cat("Dashboard location: test_mobile_dashboard/\n")
