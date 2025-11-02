#!/usr/bin/env Rscript
# Test browser opening with output in parent directory

devtools::load_all(".")

# Create simple data
data <- data.frame(x = rnorm(100))

# Create dashboard with output in a different location
dashboard <- create_dashboard(
  "../test_output_parent",  # Parent directory
  "Test Parent Dir Browser"
) %>%
  add_page("Home", data = data, is_landing_page = TRUE)

# Test with render = TRUE, open = "browser"
cat("\n=== TESTING: output_dir = '../test_output_parent', open = 'browser' ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")

cat("\n✅ Test complete. Check if browser opened.\n")

