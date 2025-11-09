# Test with original working configuration (no viewport, with self_contained)

devtools::load_all()
library(tidyverse)

# Sample data
data <- mtcars %>% rownames_to_column("car")

cat("Creating dashboard with ORIGINAL WORKING configuration...\n\n")
cat("Settings:\n")
cat("  - page_layout: 'full'\n")
cat("  - mobile_toc: TRUE\n")
cat("  - self_contained: TRUE (embeds all CSS/JS)\n")
cat("  - code_overflow: 'wrap' (prevents horizontal scroll)\n")
cat("  - html_math_method: 'mathjax'\n")
cat("  - NO viewport meta tag (let browser decide)\n\n")

# Replicate your original working YAML
create_dashboard(
  title = "Original Working Config Test",
  theme = "lumen",
  page_layout = "full",
  mobile_toc = TRUE,
  self_contained = TRUE,        # ← From your original
  code_overflow = "wrap",        # ← From your original
  html_math_method = "mathjax",  # ← From your original
  # viewport_width = NULL,       # ← NOT SET (like your original!)
  publish_dir = "test_original_config"
) %>%
  add_page(
    name = "Home",
    description = "**Testing Original Working Configuration**

This replicates your original YAML settings that worked on mobile:

- ✅ `theme: lumen`
- ✅ `page-layout: full`
- ✅ `self-contained: true`
- ✅ `code-fold: true` (automatically set)
- ✅ `code-overflow: wrap`
- ✅ `html-math-method: mathjax`
- ✅ Mobile TOC script (📑 button)
- ❌ NO viewport meta tag

**Key Difference:** No viewport settings - let the browser handle it naturally."
  ) %>%
  add_viz_content(
    create_bar(
      data = data,
      x_var = "cyl",
      title = "Cars by Cylinder Count",
      horizontal = TRUE
    )
  ) %>%
  add_section("## Additional Chart") %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "mpg",
      title = "MPG Distribution"
    )
  ) %>%
  add_page(
    name = "Analysis",
    description = "## Performance Analysis"
  ) %>%
  add_viz_content(
    create_histogram(
      data = data,
      x_var = "hp",
      title = "Horsepower Distribution"
    )
  ) %>%
  generate_dashboard(render = TRUE, open = "browser")

cat("\n✅ Dashboard created with original working configuration!\n\n")
cat("📱 Test on your mobile device:\n")
cat("   - Open: test_original_config/index.html\n")
cat("   - Check if it works like your original\n")
cat("   - The 📑 button should be in the top-right\n")
cat("   - Charts should NOT be squished\n\n")
cat("This matches your YAML exactly (minus the ApexCharts script).\n")



