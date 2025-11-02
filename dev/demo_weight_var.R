#!/usr/bin/env Rscript
# Demo: Using weight_var for weighted survey data analysis

devtools::load_all(".")

# Create sample survey data with weights
set.seed(123)
survey_data <- data.frame(
  age = sample(c("18-30", "31-50", "51+"), 1000, replace = TRUE),
  education = sample(c("High School", "Bachelor", "Graduate"), 1000, replace = TRUE),
  satisfaction = sample(1:5, 1000, replace = TRUE),
  year = sample(2020:2023, 1000, replace = TRUE),
  weight = runif(1000, 0.5, 2.0)  # Survey weights
)

cat("=== DEMO: Weighted Survey Data Analysis ===\n\n")

# Example 1: Weighted histogram
cat("1. Weighted histogram of education levels\n")
weighted_hist <- create_histogram(
  data = survey_data,
  x_var = "education",
  weight_var = "weight",
  title = "Education Distribution (Weighted)",
  histogram_type = "percent"
)
cat("   ✓ Created weighted histogram\n\n")

# Example 2: Weighted bar chart
cat("2. Weighted bar chart of satisfaction by age\n")
weighted_bar <- create_bar(
  data = survey_data,
  x_var = "satisfaction",
  group_var = "age",
  weight_var = "weight",
  title = "Satisfaction by Age (Weighted)",
  bar_type = "percent"
)
cat("   ✓ Created weighted bar chart\n\n")

# Example 3: Weighted stacked bar
cat("3. Weighted stacked bar of satisfaction by education\n")
weighted_stacked <- create_stackedbar(
  data = survey_data,
  x_var = "education",
  stack_var = "satisfaction",
  weight_var = "weight",
  title = "Satisfaction by Education (Weighted)",
  stacked_type = "percent"
)
cat("   ✓ Created weighted stacked bar\n\n")

# Example 4: Weighted timeline
cat("4. Weighted timeline of satisfaction over years\n")
weighted_timeline <- create_timeline(
  data = survey_data,
  time_var = "year",
  response_var = "satisfaction",
  weight_var = "weight",
  title = "Satisfaction Trends (Weighted)"
)
cat("   ✓ Created weighted timeline\n\n")

# Example 5: Using weight_var with create_viz defaults
cat("5. Using weight_var as default in create_viz\n")
viz <- create_viz(
  type = "histogram",
  x_var = "age",
  weight_var = "weight",  # Set once for all visualizations
  histogram_type = "percent"
) %>%
  add_viz(title = "Age Distribution - Wave 1", filter = ~ year == 2020) %>%
  add_viz(title = "Age Distribution - Wave 2", filter = ~ year == 2021) %>%
  add_viz(title = "Age Distribution - Wave 3", filter = ~ year == 2022)

cat("   ✓ Created 3 visualizations with shared weight_var\n")
cat("   All visualizations use the same weight variable!\n\n")

# Example 6: Override weight in add_viz
cat("6. Override weight_var in specific visualizations\n")
survey_data$weight2 <- runif(1000, 1, 3)

viz2 <- create_viz(
  type = "bar",
  x_var = "education",
  weight_var = "weight",
  bar_type = "percent"
) %>%
  add_viz(title = "Using weight") %>%
  add_viz(title = "Using weight2", weight_var = "weight2") %>%
  add_viz(title = "Unweighted", weight_var = NULL)

cat("   ✓ Created visualizations with different weights\n\n")

cat("=== KEY FEATURES ===\n")
cat("✓ All visualization functions support weight_var:\n")
cat("  • create_histogram()\n")
cat("  • create_bar()\n")
cat("  • create_stackedbar()\n")
cat("  • create_stackedbars()\n")
cat("  • create_timeline()\n")
cat("  • create_heatmap()\n\n")

cat("✓ Weights are applied during aggregation:\n")
cat("  • Counts become sum of weights\n")
cat("  • Percentages calculated from weighted counts\n")
cat("  • Heatmap uses weighted.mean() when applicable\n\n")

cat("✓ Works with create_viz() defaults:\n")
cat("  • Set weight_var once in create_viz()\n")
cat("  • All add_viz() calls inherit it\n")
cat("  • Override in specific add_viz() as needed\n\n")

cat("🎉 Weight support fully implemented!\n")

