# Text Positioning Demo
# Demonstrates the new text_before_* and text_after_* parameters

devtools::load_all()

# Create sample data
data <- mtcars

# ==============================================================================
# SCENARIO 1: Single Visualization (No Tabset)
# ==============================================================================

cat("\n=== SCENARIO 1: Single Visualization ===\n")
cat("When there's only one viz, text_before_viz and text_after_viz work\n")
cat("but text_before_tabset and text_after_tabset are ignored (no tabset created)\n\n")

single_viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "Fuel Efficiency Distribution",
    text_before_viz = "This should be before the viz.",
    text_after_viz = "This should be after the viz."
  )

# ==============================================================================
# SCENARIO 2: Multiple Visualizations in a Tabset
# ==============================================================================

cat("\n=== SCENARIO 2: Multiple Visualizations in Tabset ===\n")
cat("With multiple tabs, all text positioning parameters are available\n\n")

tabset_viz <- create_viz(
  text_before_tabset = "This should be before the tabset opens.",
  text_after_tabset = "This should be after the tabset closes."
) %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "MPG Distribution",
    tabgroup = "Vehicle Analysis / Performance",
    text_before_viz = "This should be before the first viz.",
    text_after_viz = "This should be after the first viz."
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "hp",
    title = "Horsepower Distribution",
    tabgroup = "Vehicle Analysis / Performance",
    text_before_viz = "This should be before the second viz.",
    text_after_viz = "This should be after the second viz."
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "wt",
    title = "Weight Distribution",
    tabgroup = "Vehicle Analysis / Performance",
    text_before_viz = "This should be before the third viz.",
    text_after_viz = "This should be after the third viz."
  )

# ==============================================================================
# SCENARIO 3: Nested Tabsets
# ==============================================================================

cat("\n=== SCENARIO 3: Nested Tabsets ===\n")
cat("Text positioning works at each nesting level\n\n")

nested_viz <- create_viz() %>%
  # Age group
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "18-24",
    tabgroup = "Demographics / Age",
    text_before_tabset = "This should be before the Age tabset.",
    text_after_tabset = "This should be after the Age tabset.",
    text_before_viz = "This should be before viz in Age > 18-24."
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "hp",
    title = "25-34",
    tabgroup = "Demographics / Age",
    text_before_viz = "This should be before viz in Age > 25-34."
  ) %>%
  # Gender group
  add_viz(
    type = "histogram",
    x_var = "wt",
    title = "Male",
    tabgroup = "Demographics / Gender",
    text_before_tabset = "This should be before the Gender tabset.",
    text_before_viz = "This should be before viz in Gender > Male."
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "Female",
    tabgroup = "Demographics / Gender",
    text_before_viz = "This should be before viz in Gender > Female."
  )

# ==============================================================================
# SCENARIO 4: Backward Compatibility (old 'text' parameter)
# ==============================================================================

cat("\n=== SCENARIO 4: Backward Compatibility ===\n")
cat("The old 'text' parameter still works (maps to text_before_viz)\n\n")

backward_viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "mpg",
    title = "Using Old Syntax",
    text = "This uses the old 'text' parameter (maps to text_before_viz).",
    text_position = "above"  # default
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "hp",
    title = "Using New Syntax",
    text_before_viz = "This uses the new 'text_before_viz' parameter."
  )

# ==============================================================================
# CREATE SINGLE DASHBOARD WITH ALL SCENARIOS
# ==============================================================================

dashboard <- create_dashboard("text_demo", "demo", allow_inside_pkg = TRUE) %>%
  add_page("Single Viz", data = data, visualizations = single_viz) %>%
  add_page("Tabset Demo", data = data, visualizations = tabset_viz) %>%
  add_page("Nested Demo", data = data, visualizations = nested_viz) %>%
  add_page("Backward Compat", data = data, visualizations = backward_viz)

generate_dashboard(dashboard, render = TRUE, open = "browser")

cat("\n✅ Generated: Text positioning demo\n")
cat("   Output:", dashboard$output_dir, "\n")

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("TEXT POSITIONING PARAMETERS - SUMMARY\n")
cat("================================================================================\n")
cat("\n")
cat("Available parameters:\n")
cat("  • text_before_tabset  - Appears before ::: {.panel-tabset} opens\n")
cat("  • text_after_tabset   - Appears after ::: closes\n")
cat("  • text_before_viz     - Appears before each visualization\n")
cat("  • text_after_viz      - Appears after each visualization\n")
cat("\n")
cat("When to use each:\n")
cat("  • Single viz:  Use text_before_viz and text_after_viz\n")
cat("  • Tabset:      All four parameters available\n")
cat("  • Nested:      Apply at each nesting level as needed\n")
cat("\n")
cat("Backward compatibility:\n")
cat("  • 'text' parameter still works (maps to text_before_viz by default)\n")
cat("  • Use text_position='below' to map to text_after_viz\n")
cat("\n")
cat("================================================================================\n")

