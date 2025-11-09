# Test pagination position options (top/bottom/both)

devtools::load_all()
library(tidyverse)

# Sample data
data <- mtcars %>% rownames_to_column("car")

cat("Testing pagination position options...\n\n")

# Create visualizations with pagination breaks
create_many_vizzes <- function() {
  viz <- create_viz_collection()
  
  # Page 1: 5 charts
  for (i in 1:5) {
    viz <- viz %>% add_viz_content(
      create_bar(data = data, x_var = "cyl", title = paste("Chart", i))
    )
  }
  
  viz <- viz %>% add_pagination(position = "top")  # ← NEW: position argument!
  
  # Page 2: 5 more charts
  for (i in 6:10) {
    viz <- viz %>% add_viz_content(
      create_histogram(data = data, x_var = "mpg", title = paste("Chart", i))
    )
  }
  
  viz <- viz %>% add_pagination(position = "top")
  
  # Page 3: 5 more charts
  for (i in 11:15) {
    viz <- viz %>% add_viz_content(
      create_bar(data = data, x_var = "gear", title = paste("Chart", i))
    )
  }
  
  viz
}

# Test 1: Bottom position (default)
cat("1. Creating dashboard with BOTTOM pagination (default)...\n")
create_dashboard(
  title = "Test 1: Bottom Pagination",
  publish_dir = "test_pagination_bottom"
) %>%
  add_page(
    name = "Analysis",
    description = "**Pagination at bottom** (default)\n\n← [1 / 3] → will be at bottom of page"
  ) %>%
  add_viz_content(
    create_viz_collection() %>%
      add_viz_content(create_bar(data = data, x_var = "cyl", title = "Chart 1")) %>%
      add_viz_content(create_bar(data = data, x_var = "gear", title = "Chart 2")) %>%
      add_pagination(position = "bottom") %>%
      add_viz_content(create_histogram(data = data, x_var = "mpg", title = "Chart 3")) %>%
      add_viz_content(create_histogram(data = data, x_var = "hp", title = "Chart 4"))
  ) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# Test 2: Top position (breadcrumb-like)
cat("2. Creating dashboard with TOP pagination (breadcrumb-style)...\n")
create_dashboard(
  title = "Test 2: Top Pagination (Breadcrumb-Like)",
  publish_dir = "test_pagination_top"
) %>%
  add_page(
    name = "Analysis",
    description = "**Pagination at top** (breadcrumb-style)\n\nLook for: **Page 1 / 3** at the top!"
  ) %>%
  add_viz_content(
    create_viz_collection() %>%
      add_viz_content(create_bar(data = data, x_var = "cyl", title = "Chart 1")) %>%
      add_viz_content(create_bar(data = data, x_var = "gear", title = "Chart 2")) %>%
      add_pagination(position = "top") %>%  # ← TOP!
      add_viz_content(create_histogram(data = data, x_var = "mpg", title = "Chart 3")) %>%
      add_viz_content(create_histogram(data = data, x_var = "hp", title = "Chart 4"))
  ) %>%
  generate_dashboard(render = TRUE, open = FALSE)

# Test 3: Both positions
cat("3. Creating dashboard with BOTH top and bottom pagination...\n")
create_dashboard(
  title = "Test 3: Both Top & Bottom",
  publish_dir = "test_pagination_both"
) %>%
  add_page(
    name = "Analysis",
    description = "**Pagination at both top AND bottom**\n\nNavigation appears at top (sticky) and bottom!"
  ) %>%
  add_viz_content(
    create_viz_collection() %>%
      add_viz_content(create_bar(data = data, x_var = "cyl", title = "Chart 1")) %>%
      add_viz_content(create_bar(data = data, x_var = "gear", title = "Chart 2")) %>%
      add_pagination(position = "both") %>%  # ← BOTH!
      add_viz_content(create_histogram(data = data, x_var = "mpg", title = "Chart 3")) %>%
      add_viz_content(create_histogram(data = data, x_var = "hp", title = "Chart 4"))
  ) %>%
  generate_dashboard(render = TRUE, open = "browser")

cat("\n✅ All test dashboards created!\n\n")
cat("Test Directories:\n")
cat("  1. test_pagination_bottom/  (default, at bottom)\n")
cat("  2. test_pagination_top/     (breadcrumb-style at top) ← RECOMMENDED!\n")
cat("  3. test_pagination_both/    (both top and bottom)\n\n")
cat("📍 Key Features:\n")
cat("  - Top position: Sticky at top, breadcrumb-like styling\n")
cat("  - Shows 'Page 1 / 3' format (minimal text)\n")
cat("  - Uses '/' separator (language-agnostic)\n")
cat("  - Super intuitive navigation!\n\n")
cat("Opening Test 3 (both positions) in browser...\n")



