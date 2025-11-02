# Demo: Generate a complete dashboard using add_vizzes()
# This shows how add_vizzes() simplifies creating multiple similar visualizations

# Load package
# getwd()
# devtools::load_all("..")
library(dashboardr)
library(dplyr)

cat("🚀 Creating demo dashboard with add_vizzes()...\n\n")

# ============================================
# Create Sample Survey Data
# ============================================
set.seed(123)
n <- 500

data <- data.frame(
  wave = sample(1:3, n, replace = TRUE),

  # Information Skills (3 questions)
  SInfo1 = sample(1:7, n, replace = TRUE),  # Search keywords
  SInfo2 = sample(1:7, n, replace = TRUE),  # Find answers
  SInfo3 = sample(1:7, n, replace = TRUE),  # Use search functions

  # Communication Skills (3 questions)
  SComm1 = sample(1:7, n, replace = TRUE),  # Choose right tool
  SComm2 = sample(1:7, n, replace = TRUE),  # Write clearly
  SComm3 = sample(1:7, n, replace = TRUE),  # Use emoticons

  # Demographics
  AgeGroup = sample(c("18-25", "26-35", "36-50", "50+"), n, replace = TRUE),
  Gender = sample(c("Male", "Female", "Other"), n, replace = TRUE),
  Education = sample(c("High School", "Bachelor", "Master", "PhD"), n, replace = TRUE)
)

# Save data
data_file <- "demo_survey_data.rds"
saveRDS(data, data_file)

cat("📊 Created survey data:", n, "responses,", ncol(data), "variables\n")
cat("📁 Saved to:", data_file, "\n\n")

# ============================================
# Define Question Labels
# ============================================
info_questions <- c(
  "I know how to choose good keywords for online searches",
  "I know how I can find answers to my questions on the internet",
  "I know how I can use search functions effectively"
)

comm_questions <- c(
  "I know which communication tool fits which situation",
  "I can write messages that are clear and appropriate",
  "I know when it is appropriate to use emoticons"
)

info_vars <- c("SInfo1", "SInfo2", "SInfo3")
comm_vars <- c("SComm1", "SComm2", "SComm3")

response_labs <- c("Low (1-3)", "Medium (4)", "High (5-7)")

# ============================================
# Build Visualizations using add_vizzes()!
# ============================================
cat("🎨 Creating visualizations...\n")

# 1. Information Skills - Wave Comparison (using stackedbars)
info_overall <- create_viz(
  type = "stackedbars",
  questions = info_vars,
  question_labels = info_questions,
  stacked_type = "percent",
  horizontal = TRUE,
  stack_breaks = c(0.5, 3.5, 4.5, 7.5),
  stack_bin_labels = response_labs,
  stack_order = response_labs,
  color_palette = c("#d7191c", "#fdae61", "#2b83ba"),
  drop_na_vars = TRUE
) |>
  add_viz(
    title = "Information Skills - Wave 1",
    filter = ~ wave == 1,
    tabgroup = "info/wave1/overall"
  ) |>
  add_viz(
    title = "Information Skills - Wave 2",
    filter = ~ wave == 2,
    tabgroup = "info/wave2/overall"
  ) |>
  add_viz(
    title = "Information Skills - Wave 3",
    filter = ~ wave == 3,
    tabgroup = "info/wave3/overall"
  )

# 2. Information Skills - By Demographics (Wave 1)
# OLD WAY: Would need 9 separate add_viz() calls!
# NEW WAY: Use add_vizzes() - just 3 calls!

info_wave1_age <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = TRUE,
  x_breaks = c(0.5, 3.5, 4.5, 7.5),
  x_bin_labels = response_labs,
  stack_order = response_labs,
  filter = ~ wave == 1,
  drop_na_vars = TRUE,
  color_palette = c("#d7191c", "#fdae61", "#2b83ba")
) |>
  add_vizzes(
    x_var = info_vars,
    stack_var = "AgeGroup",
    title = info_questions,
    .tabgroup_template = "info/wave1/age/q{i}"
  )

info_wave1_gender <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = TRUE,
  x_breaks = c(0.5, 3.5, 4.5, 7.5),
  x_bin_labels = response_labs,
  stack_order = response_labs,
  filter = ~ wave == 1,
  drop_na_vars = TRUE,
  color_palette = c("#d7191c", "#fdae61", "#2b83ba")
) |>
  add_vizzes(
    x_var = info_vars,
    stack_var = "Gender",
    title = info_questions,
    .tabgroup_template = "info/wave1/gender/q{i}"
  )

info_wave1_edu <- create_viz(
  type = "stackedbar",
  stacked_type = "percent",
  horizontal = TRUE,
  x_breaks = c(0.5, 3.5, 4.5, 7.5),
  x_bin_labels = response_labs,
  stack_order = response_labs,
  filter = ~ wave == 1,
  drop_na_vars = TRUE,
  color_palette = c("#d7191c", "#fdae61", "#2b83ba")
) |>
  add_vizzes(
    x_var = info_vars,
    stack_var = "Education",
    title = info_questions,
    .tabgroup_template = "info/wave1/education/q{i}"
  )

# 3. Information Skills - Over Time
info_overtime <- create_viz(
  type = "timeline",
  time_var = "wave",
  chart_type = "line",
  response_filter = 5:7,
  response_filter_label = "High (5-7)",
  color_palette = c("#d7191c", "#fdae61", "#2b83ba")
) |>
  add_vizzes(
    response_var = info_vars,
    group_var = "AgeGroup",
    .tabgroup_template = "info/overtime/age/q{i}",
    .title_template = "Q{i} - Trends by Age"
  )

# 4. Communication Skills - Overview
comm_viz <- create_viz(
  type = "stackedbars",
  questions = comm_vars,
  question_labels = comm_questions,
  stacked_type = "percent",
  horizontal = TRUE,
  stack_breaks = c(0.5, 3.5, 4.5, 7.5),
  stack_bin_labels = response_labs,
  stack_order = response_labs,
  color_palette = c("#e66101", "#fdb863", "#5e3c99"),
  drop_na_vars = TRUE
) |>
  add_viz(
    title = "Communication Skills - All Waves",
    tabgroup = "comm/overall"
  )

# Combine all visualizations
all_viz <- info_overall |>
  combine_viz(info_wave1_age) |>
  combine_viz(info_wave1_gender) |>
  combine_viz(info_wave1_edu) |>
  combine_viz(info_overtime) |>
  combine_viz(comm_viz) |>
  set_tabgroup_labels(list(
    info = "📊 Information Skills",
    comm = "💬 Communication Skills",
    wave1 = "Wave 1",
    wave2 = "Wave 2",
    wave3 = "Wave 3",
    overall = "Overall",
    age = "By Age",
    gender = "By Gender",
    education = "By Education",
    overtime = "Over Time"
  ))

cat("✅ Created", length(all_viz$visualizations), "visualizations\n")
cat("   - Using add_vizzes() saved ~20 lines of repetitive code!\n\n")

# ============================================
# Generate Dashboard
# ============================================
cat("📝 Generating dashboard...\n")

output_dir <- "demo_add_vizzes_dashboard"

proj <- create_dashboard(output_dir = output_dir) |>
  add_dashboard_page(
    "skills",
    visualizations = all_viz,
    data_path = data_file
  )

generate_dashboard(proj, render = FALSE)

cat("\n")
cat("═══════════════════════════════════════════════════════\n")
cat("🎉 DASHBOARD GENERATED SUCCESSFULLY!\n")
cat("═══════════════════════════════════════════════════════\n")
cat("📁 Location:", normalizePath(output_dir), "\n")
cat("📄 Main file:", file.path(output_dir, "skills.qmd"), "\n")
cat("📊 Visualizations:", length(all_viz$visualizations), "\n\n")

cat("🔍 Structure created:\n")
cat("   ├─ Information Skills\n")
cat("   │  ├─ Wave 1 (Overall + By Age/Gender/Education)\n")
cat("   │  ├─ Wave 2 (Overall)\n")
cat("   │  ├─ Wave 3 (Overall)\n")
cat("   │  └─ Over Time (By Age)\n")
cat("   └─ Communication Skills (Overall)\n\n")

cat("💡 Key benefits of add_vizzes():\n")
cat("   ✅ Created 3 viz with 1 call instead of 3\n")
cat("   ✅ Automatic tabgroup templating\n")
cat("   ✅ Parallel title expansion\n")
cat("   ✅ Less repetitive code\n")
cat("   ✅ Easier to maintain\n\n")

cat("🚀 To view the dashboard:\n")
cat("   1. Navigate to:", output_dir, "\n")
cat("   2. Run: quarto preview skills.qmd\n")
cat("   3. Or render: quarto render\n")
cat("═══════════════════════════════════════════════════════\n")

