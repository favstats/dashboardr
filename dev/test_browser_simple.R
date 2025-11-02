#!/usr/bin/env Rscript
# Simple test to debug browser opening

devtools::load_all(".")

# Create simple data
data <- data.frame(x = rnorm(100))

# Create simple dashboard
dashboard <- create_dashboard(
  "test_browser_simple",
  "Test Browser"
) %>%
  add_page("Home", data = data, is_landing_page = TRUE)

# Test with render = TRUE, open = "browser"
cat("\n=== TESTING: render = TRUE, open = 'browser' ===\n")
generate_dashboard(dashboard, render = TRUE, open = "browser")

cat("\n✅ Test complete. Check the DEBUG messages above.\n")
cat("   If browseURL() was called but browser didn't open, the issue is with browseURL() itself.\n")

