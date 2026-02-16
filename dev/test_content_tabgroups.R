# ============================================================================
# Test: Content tabgroups for ALL block types
# ============================================================================
# Demonstrates that tabgroup works for text, reactable, gt, html, and other
# content block types — not just viz items.

devtools::load_all()
library(reactable)
library(gt)

# --- Test 1: create_page() piped items with tabgroups ---
page1 <- create_page("Piped Content Tabs") %>%
  add_text("# Content Tabgroups Test", "This page tests tabgroups for content blocks.") %>%
  add_text("Hello from **Tab A**!", tabgroup = "Tab A") %>%
  add_text("Hello from **Tab B**!", tabgroup = "Tab B") %>%
  add_text("This text has no tabgroup and appears normally.")

# --- Test 2: create_content() collection with mixed content tabgroups ---
content2 <- create_content() %>%
  add_text("## Tables in Tabs") %>%
  add_reactable(
    reactable::reactable(
      data.frame(x = 1:5, y = letters[1:5]),
      striped = TRUE
    ),
    tabgroup = "Reactable"
  ) %>%
  add_gt(
    gt::gt(data.frame(Name = c("Alice", "Bob"), Score = c(90, 85))) %>%
      gt::tab_header(title = "Scores"),
    tabgroup = "GT Table"
  ) %>%
  add_html("<p style='color: blue;'>Custom HTML content in a tab</p>",
           tabgroup = "HTML Block")

page2 <- create_page("Collection Tabs") %>%
  add_content(content2)

# --- Test 3: Nested tabgroups ("Parent/Child" notation) ---
page3 <- create_page("Nested Tabs") %>%
  add_text("Content under **Analysis > Summary**", tabgroup = "Analysis/Summary") %>%
  add_text("Content under **Analysis > Details**", tabgroup = "Analysis/Details") %>%
  add_text("Content under **Data > Raw**", tabgroup = "Data/Raw") %>%
  add_text("Content under **Data > Processed**", tabgroup = "Data/Processed")

# --- Test 4: Mixed viz + content in same collection with tabgroups ---
sample_data <- data.frame(
  category = rep(c("A", "B", "C"), each = 10),
  value = rnorm(30, mean = 50, sd = 10)
)

content4 <- create_content(data = sample_data) %>%
  add_viz(type = "bar", x_var = "category", tabgroup = "Chart") %>%
  add_text("Here is a **text explanation** in its own tab.", tabgroup = "Explanation") %>%
  add_reactable(
    reactable::reactable(sample_data, compact = TRUE),
    tabgroup = "Data Table"
  )

page4 <- create_page("Mixed Viz + Content", data = sample_data) %>%
  add_content(content4)

# --- Test 5: Complex 3-level nested tabgroups (all content types) ---
# Hierarchy: Report > Section > Subsection
# Uses add_text, add_card, add_reactable, add_gt, add_html across nested levels
content5 <- create_content() %>%
  add_text("## Complex Hierarchy Test", "3-level nesting: Report > Section > Subsection") %>%
  # Level 1: Report, Level 2: Overview, Level 3: Intro
  add_text("**Report > Overview > Intro**: Welcome text.", tabgroup = "Report/Overview/Intro") %>%
  # Level 1: Report, Level 2: Overview, Level 3: Summary
  add_card(
    title = "Key Stats",
    text = "Report > Overview > Summary card.",
    tabgroup = "Report/Overview/Summary"
  ) %>%
  # Level 1: Report, Level 2: Data, Level 3: Raw
  add_reactable(
    reactable::reactable(data.frame(id = 1:3, raw = c("a", "b", "c")), compact = TRUE),
    tabgroup = "Report/Data/Raw"
  ) %>%
  # Level 1: Report, Level 2: Data, Level 3: Processed
  add_gt(
    gt::gt(data.frame(metric = c("Mean", "SD"), value = c(10.5, 2.1))),
    tabgroup = "Report/Data/Processed"
  ) %>%
  # Level 1: Appendix, Level 2: Methods
  add_text("**Appendix > Methods**: Methodology notes.", tabgroup = "Appendix/Methods") %>%
  # Level 1: Appendix, Level 2: Code
  add_html("<pre><code># R code snippet</code></pre>", tabgroup = "Appendix/Code")

page5 <- create_page("Complex Hierarchies") %>%
  add_content(content5)

# --- Test 6: Piped page with 3-level nesting (standalone blocks) ---
page6 <- create_page("Piped Complex Tabs") %>%
  add_text("# Deep Nesting") %>%
  add_text("Under **A > 1 > i**", tabgroup = "A/1/i") %>%
  add_text("Under **A > 1 > ii**", tabgroup = "A/1/ii") %>%
  add_text("Under **A > 2 > alpha**", tabgroup = "A/2/alpha") %>%
  add_text("Under **B > X**", tabgroup = "B/X") %>%
  add_card(title = "Card in B/Y", text = "Standalone card in nested tab.", tabgroup = "B/Y")

# --- Test 7: add_echarts(), add_ggiraph(), add_ggplot() convenience functions ---
library(ggplot2)
library(echarts4r)

# echarts4r chart
ec_chart <- sample_data %>%
  dplyr::group_by(category) %>%
  dplyr::summarise(mean_val = mean(value), .groups = "drop") %>%
  e_charts(category) %>%
  e_bar(mean_val) %>%
  e_title("Mean by Category (echarts4r)")

# ggplot static plot
gg_plot <- ggplot(sample_data, aes(x = category, y = value, fill = category)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Value Distribution (ggplot2)")

content7 <- create_content() %>%
  add_text("## Charts via add_echarts / add_ggplot") %>%
  add_echarts(ec_chart, title = "ECharts Bar", tabgroup = "ECharts") %>%
  add_ggplot(gg_plot, title = "GGPlot Boxplot", height = 5, tabgroup = "GGPlot")

page7 <- create_page("Backend Charts") %>%
  add_content(content7)

# --- Build dashboard ---
output_dir <- "/tmp/content_tabgroups_test"
cat("Generating dashboard to:", output_dir, "\n")

create_dashboard(
  title = "Content Tabgroups Test",
  output_dir = "uh"
) %>%
  add_page(page1) %>%
  add_page(page2) %>%
  add_page(page3) %>%
  add_page(page4) %>%
  add_page(page5) %>%
  add_page(page6) %>%
  add_page(page7) %>%
  generate_dashboard()

cat("\n=== Dashboard generated! ===\n")
cat("Output directory:", output_dir, "\n")
cat("\nTo render:\n")
cat("  cd", output_dir, "\n")
cat("  quarto render\n")
