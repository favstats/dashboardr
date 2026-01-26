# =============================================================================
# Example: Inline Data & Preview Feature
# =============================================================================
#
# This example demonstrates the new inline data and preview functionality:
# 1. Passing data directly to create_viz() / create_content()
# 2. Using preview() to render and view individual pieces
#
# Preview has two modes:
# - quarto = FALSE (default): Fast direct rendering using htmltools, no Quarto needed
#   Good for: Quick iteration on single charts, no tabsets
#
# - quarto = TRUE: Full Quarto rendering with tabsets/icons (requires Quarto)
#   Good for: Previewing with tabgroups, testing final appearance
#
# IMPORTANT: Tabgroups/tabsets ONLY work with quarto = TRUE!
#
# =============================================================================

library(dashboardr)
library(dplyr)
devtools::load_all()

# -----------------------------------------------------------------------------
# Example 1: Simple histogram with preview (fast direct mode - DEFAULT)
# -----------------------------------------------------------------------------

# Create a visualization with inline data and preview it
# This uses direct R rendering - fast and doesn't need Quarto!
create_viz(data = mtcars) %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "Miles Per Gallon Distribution"
  ) %>%
  preview()  # quarto = FALSE by default - fast!

# -----------------------------------------------------------------------------
# Example 2: Multiple charts WITHOUT tabgroups (works with quarto = FALSE)
# -----------------------------------------------------------------------------

# When you don't use tabgroups, direct mode works great
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG") %>%
  add_viz(type = "histogram", x_var = "hp", title = "Horsepower") %>%
  add_viz(type = "histogram", x_var = "wt", title = "Weight") %>%
  preview()  # All charts render vertically stacked

# -----------------------------------------------------------------------------
# Example 3: Tabgroups (MUST use quarto = TRUE)
# -----------------------------------------------------------------------------

# Tabgroups create tabbed interfaces - this REQUIRES Quarto!
# If you use tabgroups without quarto = TRUE, you'll get a warning

# Simple tabs - each tabgroup creates a separate tabset
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG", tabgroup = "Engine") %>%
  add_viz(type = "histogram", x_var = "hp", title = "HP", tabgroup = "Engine") %>%
  add_viz(type = "histogram", x_var = "disp", title = "Displacement", tabgroup = "Engine") %>%
  add_viz(type = "scatter", x_var = "wt", y_var = "mpg", title = "Weight vs MPG", tabgroup = "Weight") %>%
  add_viz(type = "scatter", x_var = "wt", y_var = "hp", title = "Weight vs HP", tabgroup = "Weight") #%>%
  # preview(title = "Engine Analysis", quarto = T)

# -----------------------------------------------------------------------------
# Example 4: Nested tabgroups with "/" syntax
# -----------------------------------------------------------------------------

# Use "/" to create nested tab levels: "Category/Subcategory"
create_viz(data = mtcars) %>%
  # First level: "Distributions", Second level: various metrics
  add_viz(type = "histogram", x_var = "mpg", title = "MPG Histogram",
          tabgroup = "Distributions/MPG") %>%
  add_viz(type = "histogram", x_var = "hp", title = "HP Histogram",
          tabgroup = "Distributions/Horsepower") %>%
  add_viz(type = "histogram", x_var = "wt", title = "NEXT TO IT",
          tabgroup = "Distributions/Weight") %>%
  add_viz(type = "histogram", x_var = "wt", title = "SUB1",
          tabgroup = "Distributions/Weight/add") %>%
  add_viz(type = "histogram", x_var = "wt", title = "SUB2",
          tabgroup = "Distributions/Weight/add") %>%
  # Different top-level tab
  add_viz(type = "scatter", x_var = "hp", y_var = "mpg", title = "HP vs MPG",
          tabgroup = "Relationships/Performance") %>%
  add_viz(type = "scatter", x_var = "wt", y_var = "mpg", title = "Weight vs MPG",
          tabgroup = "Relationships/Efficiency") %>%
  preview(title = "Nested Tabs Example", quarto = TRUE)

# -----------------------------------------------------------------------------
# Example 5: Custom path - save preview to specific location
# -----------------------------------------------------------------------------

# You can save to a specific file path:
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG") %>%
  preview(path = "~/Desktop/my_preview.html", open = TRUE)

# Or to a specific directory (preview.html created inside):
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "hp", title = "HP") %>%
  preview(path = "~/Desktop/dashboardr_previews/", open = TRUE)

# Combine with quarto = TRUE for full features:
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", tabgroup = "MPG") %>%
  add_viz(type = "histogram", x_var = "hp", tabgroup = "HP") %>%
  preview(path = "~/Desktop/tabbed_preview.html", quarto = TRUE)

# -----------------------------------------------------------------------------
# Example 6: What happens with tabgroups + quarto = FALSE (WARNING)
# -----------------------------------------------------------------------------

# This will work but show a warning about tabgroups needing Quarto
# The charts will render but WITHOUT the tabbed interface
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", tabgroup = "Test") %>%
  add_viz(type = "histogram", x_var = "hp", tabgroup = "Test") %>%
  preview(quarto = FALSE)  # Warning: tabgroups require quarto = TRUE

# -----------------------------------------------------------------------------
# Example 7: Content blocks with preview
# -----------------------------------------------------------------------------

# create_content() is an alias for create_viz() - use whichever you prefer
create_content(data = mtcars) %>%
  add_text("# Analysis Report\n\nThis is an **introduction** to our analysis.") %>%
  add_viz(type = "histogram", x_var = "mpg", title = "Distribution") %>%
  add_text("*Data source: mtcars dataset*") %>%
  preview()  # quarto = FALSE works for text + charts (no tabgroups)

# For full markdown rendering with tabgroups, use quarto = TRUE:
create_content(data = mtcars) %>%
  add_text("# Analysis Report") %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG", tabgroup = "Metrics") %>%
  add_viz(type = "histogram", x_var = "hp", title = "HP", tabgroup = "Metrics") %>%
  preview(quarto = TRUE)

# -----------------------------------------------------------------------------
# Example 8: Type defaults with create_content()
# -----------------------------------------------------------------------------

# Set type as a default - all add_viz() calls inherit it
survey_data <- data.frame(
  age_group = sample(c("18-24", "25-34", "35-44", "45+"), 200, replace = TRUE),
  gender = sample(c("M", "F", "Other"), 200, replace = TRUE),
  satisfaction = sample(c("Low", "Medium", "High"), 200, replace = TRUE)
)

create_content(
  data = survey_data,
  type = "stackedbar",      # Default type for all add_viz()
  stacked_type = "percent",
  horizontal = TRUE
) %>%
  add_viz(x_var = "age_group", stack_var = "satisfaction", title = "By Age") %>%
  add_viz(x_var = "gender", stack_var = "satisfaction", title = "By Gender") %>%
  preview()

# -----------------------------------------------------------------------------
# Example 9: Heatmap with value-based ordering
# -----------------------------------------------------------------------------

heatmap_data <- expand.grid(
  category = c("A", "B", "C", "D", "E"),
  measure = c("M1", "M2", "M3", "M4")
) %>%
  mutate(value = runif(20, 10, 100))

create_viz(data = heatmap_data) %>%
  add_viz(
    type = "heatmap",
    x_var = "category",
    y_var = "measure",
    value_var = "value",
    title = "Heatmap Ordered by Value",
    x_order_by = "desc",  # Order x-axis by descending mean value
    y_order_by = "asc"    # Order y-axis by ascending mean value
  ) %>%
  preview()

# -----------------------------------------------------------------------------
# Example 10: Stackedbar with clean defaults
# -----------------------------------------------------------------------------

# create_stackedbar() now has cleaner defaults:
# - stacked_type = "counts" (the default)
# - y_label = "Count" (auto-set based on stacked_type)
create_viz(data = mtcars) %>%
  add_viz(
    type = "stackedbar",
    x_var = "cyl",
    stack_var = "gear",
    title = "Cylinders by Gear"
  ) %>%
  preview()

# With percent stacking:
create_viz(data = mtcars) %>%
  add_viz(
    type = "stackedbar",
    x_var = "cyl",
    stack_var = "gear",
    stacked_type = "percent",  # y_label becomes "Percentage" automatically
    title = "Cylinders by Gear (%)"
  ) %>%
  preview()

# -----------------------------------------------------------------------------
# Example 11: Preview without opening (get path for later use)
# -----------------------------------------------------------------------------

html_path <- create_viz(data = iris) %>%
  add_viz(type = "histogram", x_var = "Sepal.Length", title = "Sepal Length") %>%
  preview(open = FALSE)

message("Preview saved to: ", html_path)

# You can open it later:
# browseURL(html_path)

# -----------------------------------------------------------------------------
# Summary: When to use each mode
# -----------------------------------------------------------------------------
#
# Use quarto = FALSE (default) when:
# - Quickly iterating on individual charts
# - No tabgroups needed
# - Speed is important
# - Quarto not installed
#
# Use quarto = TRUE when:
# - Using tabgroups (tabgroup = "...")
# - Need full Quarto theming
# - Testing final dashboard appearance
# - Using advanced markdown features
#
# Use path = "..." when:
# - You want to save to a specific location
# - Sharing the preview file
# - Organizing preview outputs
#
