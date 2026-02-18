# =============================================================================
# demo_algosoc_patterns.R — Simplified AlgoSoc-Style Dashboard
#
# A fully self-contained example that demonstrates the button_group + radio +
# show_when architecture used in the AlgoSoc AI Opinion Monitor dashboard.
#
# EVERYTHING is written out explicitly — no helper functions, no loops over
# sections, no abstraction layers. Just linear, step-by-step dashboard
# construction so you can follow along and understand every piece.
#
# Features demonstrated:
#   1. Topic switching     — button_group with show_when (no data filtering)
#   2. Wave/time switching — radio with show_when (no data filtering)
#   3. Demographic mode    — button_group with show_when (no data filtering)
#   4. Demographic filter  — button_group with filter_var = data column
#                            (actual client-side cross_tab filtering!)
#   5. Stacked bar charts  — Likert-scale survey items (horizontal, percent)
#   6. Bar charts          — Categorical data (vertical, percent, sorted)
#   7. Timeline charts     — Over Time view (multi-series with group_var)
#   8. "Not available"     — Handling sections missing from certain waves
#   9. Dynamic context     — Text that changes based on active filters
#
# How to run:
#   source("dev/demo_algosoc_patterns.R")
#
# =============================================================================

devtools::load_all()
library(dplyr)
library(tidyr)

# =============================================================================
# STEP 1: Generate Synthetic Survey Data
#
# We simulate a 2-wave survey with 400 respondents per wave.
# Each respondent has:
#   - Demographics: age_group, gender
#   - Likert items (1-7 scale): aware_recognize, aware_settings,
#     trust_news, trust_health
#   - Categorical choice: top_priority
# =============================================================================

set.seed(42)
n <- 400

wave1 <- tibble(
  wave       = 1L,
  wave_label = "March 2024",
  age_group  = sample(c("18-29", "30-49", "50-64", "65+"), n, replace = TRUE,
                       prob = c(0.20, 0.30, 0.25, 0.25)),
  gender     = sample(c("Male", "Female"), n, replace = TRUE),
  # "AI Awareness" items (available in both waves)
  aware_recognize = sample(1:7, n, replace = TRUE,
                           prob = c(0.05, 0.08, 0.12, 0.20, 0.25, 0.18, 0.12)),
  aware_settings  = sample(1:7, n, replace = TRUE,
                           prob = c(0.10, 0.15, 0.15, 0.20, 0.18, 0.12, 0.10)),
  # "AI Trust" items (we'll pretend these are only in Wave 2)
  trust_news   = NA_real_,
  trust_health = NA_real_,
  # "Top Priority" categorical (available in both waves)
  top_priority = sample(
    c("Privacy", "Fairness", "Transparency", "Safety", "Efficiency", "Accountability"),
    n, replace = TRUE, prob = c(0.25, 0.20, 0.18, 0.15, 0.12, 0.10)
  )
)

wave2 <- tibble(
  wave       = 2L,
  wave_label = "December 2024",
  age_group  = sample(c("18-29", "30-49", "50-64", "65+"), n, replace = TRUE,
                       prob = c(0.20, 0.30, 0.25, 0.25)),
  gender     = sample(c("Male", "Female"), n, replace = TRUE),
  # "AI Awareness" items (slightly different distributions to show change)
  aware_recognize = sample(1:7, n, replace = TRUE,
                           prob = c(0.03, 0.06, 0.10, 0.18, 0.28, 0.22, 0.13)),
  aware_settings  = sample(1:7, n, replace = TRUE,
                           prob = c(0.08, 0.12, 0.13, 0.18, 0.22, 0.15, 0.12)),
  # "AI Trust" items (only in Wave 2)
  trust_news   = sample(1:7, n, replace = TRUE,
                         prob = c(0.12, 0.15, 0.18, 0.25, 0.15, 0.10, 0.05)),
  trust_health = sample(1:7, n, replace = TRUE,
                         prob = c(0.08, 0.10, 0.15, 0.20, 0.22, 0.15, 0.10)),
  # "Top Priority" (shifted preferences)
  top_priority = sample(
    c("Privacy", "Fairness", "Transparency", "Safety", "Efficiency", "Accountability"),
    n, replace = TRUE, prob = c(0.22, 0.22, 0.20, 0.16, 0.10, 0.10)
  )
)

survey_data <- bind_rows(wave1, wave2)
survey_data$wave_label <- factor(survey_data$wave_label,
                                  levels = c("March 2024", "December 2024"))

cat("Survey data:", nrow(survey_data), "rows,", ncol(survey_data), "columns\n")

# --- Color palettes ---
likert_colors <- c("#2ca02c", "#1f77b4", "#ff7f0e")  # green, blue, orange
bar_colors    <- c("#F7A35C", "#ADD8E6", "#E9BB97", "#E4D354",
                   "#90EE90", "#1F78B4", "#F4A8A8", "#C29EC4")


# =============================================================================
# STEP 2: Build Page 1 — "Attitudes"
#
# This page has TWO topics, selectable via a button_group:
#   Topic A: "AI Awareness"  (stackedbar, available in BOTH waves)
#   Topic B: "AI Trust"      (stackedbar, available in Wave 2 ONLY)
#
# Architecture:
#   [AI Awareness] [AI Trust]           <- topic button_group (show_when only)
#   (o) Mar 2024  (o) Dec 2024  (o) OT  <- view radio (show_when only)
#   *Question text*                      <- show_when by topic
#   [Chart]                              <- show_when by topic & view & demo
#   [Overall] [By Age] [By Gender]       <- demo button_group (show_when only)
#   [All] [18-29] [30-49] [50-64] [65+]  <- secondary filter (actual filtering!)
# =============================================================================

# Select only the columns this page needs
page1_data <- survey_data %>%
  select(wave, wave_label, age_group, gender,
         aware_recognize, aware_settings, trust_news, trust_health)

# Start building the content collection, attaching the page data
page1_content <- create_content(data = page1_data)

# --- Page introduction text ---
page1_content <- page1_content %>%
  add_text("*Select a topic and time period to explore the results.*")


# -------------------------------------------------------------------------
# INPUT: Topic button_group
#
# KEY CONCEPT: filter_var = "topic_att" does NOT match any column in the data.
# This means it ONLY creates a JavaScript variable for show_when conditions.
# It does NOT filter the chart data.
# -------------------------------------------------------------------------
page1_content <- page1_content %>%
  add_input(
    input_id     = "topic_att",
    label        = "",
    type         = "button_group",
    filter_var   = "topic_att",             # NOT in data → show_when only
    options      = c("AI Awareness", "AI Trust"),
    default_selected = "AI Awareness",
    inline       = TRUE,
    group_align  = "center",
    width        = "100%"
  )


# -------------------------------------------------------------------------
# INPUT: View radio (wave selection + Over Time)
#
# Same concept: filter_var = "view_att" is NOT in the data → show_when only.
# We CANNOT use "wave_label" as filter_var because "Over Time" doesn't exist
# as a wave_label value, which would break all the charts.
# -------------------------------------------------------------------------
page1_content <- page1_content %>%
  add_input(
    input_id     = "view_att",
    label        = "",
    type         = "radio",
    filter_var   = "view_att",              # NOT in data → show_when only
    options      = c("March 2024", "December 2024", "Over Time"),
    default_selected = "December 2024",
    inline       = TRUE,
    group_align  = "center",
    width        = "100%"
  )


# -------------------------------------------------------------------------
# Topic-specific question text (visible only when that topic is selected)
# -------------------------------------------------------------------------
page1_content <- page1_content %>%
  add_text(
    "*To what extent can you recognize and manage AI personalization?*",
    show_when = ~ topic_att == "AI Awareness"
  ) %>%
  add_text(
    "*How much do you trust AI systems in the following domains?*",
    show_when = ~ topic_att == "AI Trust"
  )


# -------------------------------------------------------------------------
# Dynamic context text — shows which demographic filter is currently active
# These reference "demo_att" which is defined further below as a button_group.
# show_when formulas work as long as the filter_var exists on the page.
# -------------------------------------------------------------------------
page1_content <- page1_content %>%
  add_text("**Showing: All respondents**",
           show_when = ~ demo_att == "Overall") %>%
  add_text("**Showing: Filtered by age group**",
           show_when = ~ demo_att == "By Age") %>%
  add_text("**Showing: Filtered by gender**",
           show_when = ~ demo_att == "By Gender")


# =========================================================================
# TOPIC A: "AI Awareness" — Stacked Bar Charts
#
# Variables: aware_recognize, aware_settings (1-7 Likert scale)
# Binned into 3 categories: Agree (5-7), Neutral (4), Disagree (1-3)
# Available in: Wave 1 AND Wave 2
#
# We need separate charts for each combination of:
#   wave (March 2024, December 2024) × demo (Overall, By Age, By Gender)
# Plus timeline charts for Over Time × demo.
#
# Total: 6 cross-sectional charts + 3 timeline charts = 9 charts
# =========================================================================

# --- WAVE 1, OVERALL ---
# cross_tab_filter_vars = character(0) means NO demographic filtering.
# We also select() only the survey variables (no age_group/gender columns),
# so the chart data is as lean as possible.
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 1) %>%
                     select(aware_recognize, aware_settings),
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = character(0),    # No filtering for "Overall"
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "March 2024" &
                     demo_att == "Overall"
  )


# --- WAVE 1, BY AGE ---
# cross_tab_filter_vars = "age_group" enables client-side filtering.
# The chart data MUST include the age_group column for this to work.
# When the user clicks "30-49" in the secondary age button_group,
# dashboardr's cross_tab JS filters the chart data to only those rows.
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 1),   # keeps age_group!
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "age_group",    # ← actual data filtering!
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "March 2024" &
                     demo_att == "By Age"
  )


# --- WAVE 1, BY GENDER ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 1),   # keeps gender!
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "gender",       # ← actual data filtering!
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "March 2024" &
                     demo_att == "By Gender"
  )


# --- WAVE 2, OVERALL ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2) %>%
                     select(aware_recognize, aware_settings),
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = character(0),
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "December 2024" &
                     demo_att == "Overall"
  )


# --- WAVE 2, BY AGE ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2),
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "age_group",
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "December 2024" &
                     demo_att == "By Age"
  )


# --- WAVE 2, BY GENDER ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2),
    x_vars       = c("aware_recognize", "aware_settings"),
    x_var_labels = c("I recognize AI personalization", "I know AI settings"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Disagree (1-3)", "Neutral (4)", "Agree (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "gender",
    height       = 400,
    show_when    = ~ topic_att == "AI Awareness" &
                     view_att == "December 2024" &
                     demo_att == "By Gender"
  )


# -------------------------------------------------------------------------
# OVER TIME: Timeline Charts for "AI Awareness"
#
# For timelines, we pivot the data from wide to long format so multiple
# survey items become a single y_var column with a group_var for labels.
# This creates one multi-series line chart instead of separate charts.
#
# The y_filter parameter controls which numeric values count as the
# "positive" response (5-7 = "Agree"), and agg = "percentage" calculates
# the % of respondents in that range per time point.
# -------------------------------------------------------------------------

# Pivot wide → long: two columns become rows with item_label
awareness_long <- page1_data %>%
  filter(!is.na(aware_recognize)) %>%    # drop Wave 2's trust-only rows
  pivot_longer(
    cols      = c(aware_recognize, aware_settings),
    names_to  = "item_var",
    values_to = "item_value"
  ) %>%
  mutate(item_label = factor(
    item_var,
    levels = c("aware_recognize", "aware_settings"),
    labels = c("I recognize AI personalization", "I know AI settings")
  ))


# --- OVER TIME, OVERALL ---
page1_content <- page1_content %>%
  add_viz(
    type      = "timeline",
    data      = awareness_long %>% select(wave_label, item_value, item_label),
    time_var  = "wave_label",
    y_var     = "item_value",
    group_var = "item_label",             # creates one line per survey item
    y_filter  = 5:7,                      # count values 5, 6, 7 as "positive"
    y_filter_combine = TRUE,
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    y_label   = "% Agreeing (5-7)",
    cross_tab_filter_vars = character(0),
    height    = 400,
    show_when = ~ topic_att == "AI Awareness" &
                   view_att == "Over Time" &
                   demo_att == "Overall"
  )


# --- OVER TIME, BY AGE ---
# Notice: data includes age_group, and cross_tab_filter_vars = "age_group".
# When user clicks a specific age in the secondary button group, the
# timeline recalculates using only that age group's data.
page1_content <- page1_content %>%
  add_viz(
    type      = "timeline",
    data      = awareness_long,            # includes age_group column
    time_var  = "wave_label",
    y_var     = "item_value",
    group_var = "item_label",
    y_filter  = 5:7,
    y_filter_combine = TRUE,
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    y_label   = "% Agreeing (5-7)",
    cross_tab_filter_vars = "age_group",
    height    = 400,
    show_when = ~ topic_att == "AI Awareness" &
                   view_att == "Over Time" &
                   demo_att == "By Age"
  )


# --- OVER TIME, BY GENDER ---
page1_content <- page1_content %>%
  add_viz(
    type      = "timeline",
    data      = awareness_long,            # includes gender column
    time_var  = "wave_label",
    y_var     = "item_value",
    group_var = "item_label",
    y_filter  = 5:7,
    y_filter_combine = TRUE,
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    y_label   = "% Agreeing (5-7)",
    cross_tab_filter_vars = "gender",
    height    = 400,
    show_when = ~ topic_att == "AI Awareness" &
                   view_att == "Over Time" &
                   demo_att == "By Gender"
  )


# =========================================================================
# TOPIC B: "AI Trust" — Stacked Bar Charts
#
# Variables: trust_news, trust_health (1-7 Likert scale)
# Available in: Wave 2 ONLY
#
# This demonstrates how to handle sections that are missing from
# certain survey waves — we show "not available" text instead.
# =========================================================================

# --- "NOT AVAILABLE" for Wave 1 ---
# When the user selects "AI Trust" topic + "March 2024" wave,
# we show an informational message instead of a chart.
page1_content <- page1_content %>%
  add_text(
    "*This question was not included in the March 2024 survey wave.*",
    show_when = ~ topic_att == "AI Trust" & view_att == "March 2024"
  )


# --- WAVE 2, OVERALL ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2) %>%
                     select(trust_news, trust_health),
    x_vars       = c("trust_news", "trust_health"),
    x_var_labels = c("Trust AI in News", "Trust AI in Healthcare"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Little trust (1-3)", "Somewhat (4)", "Trust (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = character(0),
    height       = 400,
    show_when    = ~ topic_att == "AI Trust" &
                     view_att == "December 2024" &
                     demo_att == "Overall"
  )


# --- WAVE 2, BY AGE ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2),
    x_vars       = c("trust_news", "trust_health"),
    x_var_labels = c("Trust AI in News", "Trust AI in Healthcare"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Little trust (1-3)", "Somewhat (4)", "Trust (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "age_group",
    height       = 400,
    show_when    = ~ topic_att == "AI Trust" &
                     view_att == "December 2024" &
                     demo_att == "By Age"
  )


# --- WAVE 2, BY GENDER ---
page1_content <- page1_content %>%
  add_viz(
    type         = "stackedbar",
    data         = page1_data %>% filter(wave == 2),
    x_vars       = c("trust_news", "trust_health"),
    x_var_labels = c("Trust AI in News", "Trust AI in Healthcare"),
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_breaks     = c(0, 3.5, 4.5, 7),
    stack_bin_labels = c("Little trust (1-3)", "Somewhat (4)", "Trust (5-7)"),
    color_palette    = likert_colors,
    cross_tab_filter_vars = "gender",
    height       = 400,
    show_when    = ~ topic_att == "AI Trust" &
                     view_att == "December 2024" &
                     demo_att == "By Gender"
  )


# --- "NOT AVAILABLE" for Over Time (single wave = no trend possible) ---
page1_content <- page1_content %>%
  add_text(
    "*Over Time view is not available — this topic has only one wave of data.*",
    show_when = ~ topic_att == "AI Trust" & view_att == "Over Time"
  )


# =========================================================================
# DEMOGRAPHIC CONTROLS (placed at the bottom of the page)
#
# This is the crucial part of the architecture:
#
# 1. PRIMARY button_group: "Overall" / "By Age" / "By Gender"
#    - filter_var = "demo_att" (NOT in data → show_when control only)
#    - Clicking "By Age" doesn't filter anything; it just changes which
#      secondary button_group is visible
#
# 2. SECONDARY button_groups: one per demographic dimension
#    - filter_var = "age_group" or "gender" (IS in data → actual filtering!)
#    - Visible only when the matching primary option is selected (show_when)
#    - add_all = TRUE adds an "All" button that shows unfiltered data
#    - When user clicks e.g. "30-49", the cross_tab JS filters chart data
#      to only rows where age_group == "30-49"
# =========================================================================

# PRIMARY: demographic mode selector (show_when only, no data filtering)
page1_content <- page1_content %>%
  add_input(
    input_id     = "demo_att",
    label        = "",
    type         = "button_group",
    filter_var   = "demo_att",              # NOT in data → show_when only
    options      = c("Overall", "By Age", "By Gender"),
    default_selected = "Overall",
    inline       = TRUE,
    group_align  = "center",
    width        = "100%"
  )


# SECONDARY: Age group filter (actual data filtering!)
# Only visible when "By Age" is selected in the primary button_group.
# add_all = TRUE prepends an "All" option (default) that shows all data.
page1_content <- page1_content %>%
  add_input(
    input_id     = "age_filter_att",
    label        = "",
    type         = "button_group",
    filter_var   = "age_group",             # IS in data → actual filtering!
    options      = c("18-29", "30-49", "50-64", "65+"),
    default_selected = "18-29",
    add_all      = TRUE,                    # adds "All" as first option
    inline       = TRUE,
    group_align  = "center",
    width        = "100%",
    show_when    = ~ demo_att == "By Age"   # only visible in "By Age" mode
  )


# SECONDARY: Gender filter (actual data filtering!)
# Only visible when "By Gender" is selected.
page1_content <- page1_content %>%
  add_input(
    input_id     = "gender_filter_att",
    label        = "",
    type         = "button_group",
    filter_var   = "gender",                # IS in data → actual filtering!
    options      = c("Male", "Female"),
    default_selected = "Male",
    add_all      = TRUE,
    inline       = TRUE,
    group_align  = "center",
    width        = "100%",
    show_when    = ~ demo_att == "By Gender"
  )


# =============================================================================
# STEP 3: Build Page 2 — "Values"
#
# This page has just ONE topic (no topic switching needed), demonstrating
# the bar chart type with a categorical variable.
#
# Topic: "Top Priorities" — which values do people rank as most important?
# Chart type: bar (vertical, percent, sorted by value)
# Available in: Wave 1 AND Wave 2
# =============================================================================

page2_data <- survey_data %>%
  select(wave, wave_label, age_group, gender, top_priority)

page2_content <- create_content(data = page2_data)

page2_content <- page2_content %>%
  add_text("*Which values do people consider most important for AI systems?*")


# -------------------------------------------------------------------------
# INPUT: View radio (no topic button_group needed — single topic page)
# -------------------------------------------------------------------------
page2_content <- page2_content %>%
  add_input(
    input_id     = "view_val",
    label        = "",
    type         = "radio",
    filter_var   = "view_val",
    options      = c("March 2024", "December 2024", "Over Time"),
    default_selected = "December 2024",
    inline       = TRUE,
    group_align  = "center",
    width        = "100%"
  )


# -------------------------------------------------------------------------
# Dynamic context text
# -------------------------------------------------------------------------
page2_content <- page2_content %>%
  add_text("**Showing: All respondents**",
           show_when = ~ demo_val == "Overall") %>%
  add_text("**Showing: Filtered by age group**",
           show_when = ~ demo_val == "By Age") %>%
  add_text("**Showing: Filtered by gender**",
           show_when = ~ demo_val == "By Gender")


# =========================================================================
# BAR CHARTS: "Top Priorities"
#
# bar_type = "percent" shows the percentage of respondents choosing each value.
# sort_by_value = TRUE + sort_desc = TRUE orders bars from most to least chosen.
# horizontal = FALSE gives us vertical bars (column chart).
# =========================================================================

# --- WAVE 1, OVERALL ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 1) %>% select(top_priority),
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = character(0),
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "March 2024" & demo_val == "Overall"
  )


# --- WAVE 1, BY AGE ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 1),   # keeps age_group
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = "age_group",
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "March 2024" & demo_val == "By Age"
  )


# --- WAVE 1, BY GENDER ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 1),
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = "gender",
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "March 2024" & demo_val == "By Gender"
  )


# --- WAVE 2, OVERALL ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 2) %>% select(top_priority),
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = character(0),
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "December 2024" & demo_val == "Overall"
  )


# --- WAVE 2, BY AGE ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 2),
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = "age_group",
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "December 2024" & demo_val == "By Age"
  )


# --- WAVE 2, BY GENDER ---
page2_content <- page2_content %>%
  add_viz(
    type          = "bar",
    data          = page2_data %>% filter(wave == 2),
    x_var         = "top_priority",
    bar_type      = "percent",
    horizontal    = FALSE,
    sort_by_value = TRUE,
    sort_desc     = TRUE,
    color_palette = bar_colors,
    cross_tab_filter_vars = "gender",
    y_label       = "% Naming as #1 Priority",
    height        = 450,
    show_when     = ~ view_val == "December 2024" & demo_val == "By Gender"
  )


# -------------------------------------------------------------------------
# OVER TIME: Timeline Charts for "Top Priorities"
#
# For a categorical variable, the timeline shows the % choosing each
# category over time. No pivoting needed — just pass the categorical
# column as y_var and let agg = "percentage" handle the rest.
# -------------------------------------------------------------------------

# --- OVER TIME, OVERALL ---
page2_content <- page2_content %>%
  add_viz(
    type      = "timeline",
    data      = page2_data %>% select(wave_label, top_priority),
    time_var  = "wave_label",
    y_var     = "top_priority",
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    cross_tab_filter_vars = character(0),
    y_label   = "% Naming as #1 Priority",
    height    = 450,
    show_when = ~ view_val == "Over Time" & demo_val == "Overall"
  )


# --- OVER TIME, BY AGE ---
page2_content <- page2_content %>%
  add_viz(
    type      = "timeline",
    data      = page2_data,                # includes age_group
    time_var  = "wave_label",
    y_var     = "top_priority",
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    cross_tab_filter_vars = "age_group",
    y_label   = "% Naming as #1 Priority",
    height    = 450,
    show_when = ~ view_val == "Over Time" & demo_val == "By Age"
  )


# --- OVER TIME, BY GENDER ---
page2_content <- page2_content %>%
  add_viz(
    type      = "timeline",
    data      = page2_data,                # includes gender
    time_var  = "wave_label",
    y_var     = "top_priority",
    agg       = "percentage",
    chart_type    = "line",
    color_palette = bar_colors,
    cross_tab_filter_vars = "gender",
    y_label   = "% Naming as #1 Priority",
    height    = 450,
    show_when = ~ view_val == "Over Time" & demo_val == "By Gender"
  )


# -------------------------------------------------------------------------
# DEMOGRAPHIC CONTROLS for Page 2 (same pattern as Page 1)
# -------------------------------------------------------------------------

# PRIMARY: demographic mode selector
page2_content <- page2_content %>%
  add_input(
    input_id     = "demo_val",
    label        = "",
    type         = "button_group",
    filter_var   = "demo_val",
    options      = c("Overall", "By Age", "By Gender"),
    default_selected = "Overall",
    inline       = TRUE,
    group_align  = "center",
    width        = "100%"
  )

# SECONDARY: Age group filter
page2_content <- page2_content %>%
  add_input(
    input_id     = "age_filter_val",
    label        = "",
    type         = "button_group",
    filter_var   = "age_group",
    options      = c("18-29", "30-49", "50-64", "65+"),
    default_selected = "18-29",
    add_all      = TRUE,
    inline       = TRUE,
    group_align  = "center",
    width        = "100%",
    show_when    = ~ demo_val == "By Age"
  )

# SECONDARY: Gender filter
page2_content <- page2_content %>%
  add_input(
    input_id     = "gender_filter_val",
    label        = "",
    type         = "button_group",
    filter_var   = "gender",
    options      = c("Male", "Female"),
    default_selected = "Male",
    add_all      = TRUE,
    inline       = TRUE,
    group_align  = "center",
    width        = "100%",
    show_when    = ~ demo_val == "By Gender"
  )


# =============================================================================
# STEP 4: Build Home Page
#
# A simple landing page with introductory text and navigation links.
# No data or charts — just HTML content.
# =============================================================================

home_content <- create_content() %>%
  add_text(paste0(
    '<blockquote style="border-left: 4px solid #f39917; padding: 12px 20px; ',
    'background: #fff8ef; font-size: 1.1em;">',
    'Welcome to this <strong>demo dashboard</strong> showing the ',
    'button_group + show_when architecture used in the AlgoSoc AI Opinion Monitor.',
    '</blockquote>\n\n',
    'This dashboard demonstrates how to build interactive survey dashboards with ',
    '<strong>dashboardr</strong> using:\n\n',
    '- **Topic switching** via button groups\n',
    '- **Wave/time period selection** via radio buttons\n',
    '- **Demographic filtering** with secondary button groups\n',
    '- **Stacked bar charts** for Likert-scale survey items\n',
    '- **Bar charts** for categorical data\n',
    '- **Timeline charts** for tracking trends over time\n',
    '- **Conditional visibility** (show_when) tying everything together\n\n',
    'Navigate to the pages using the links in the navbar above.'
  ))


# =============================================================================
# STEP 5: Assemble Dashboard and Generate
#
# This is where everything comes together:
#   1. create_dashboard() sets global options (title, theme, backend, etc.)
#   2. add_page() attaches each page with its data and content
#   3. generate_dashboard() renders the Quarto site and opens it
# =============================================================================

# Resolve output directory
output_dir <- file.path(tempdir(), "demo_algosoc")

dashboard <- create_dashboard(
  output_dir  = "algosoc",
  title       = "Input w/o Sidebar Demo",
  backend     = "echarts4r",
  sidebar     = FALSE,
  mainfont    = "Roboto",
  fontsize    = "16px",
  linkcolor   = "#f39917",
  max_width   = "1200px",
  page_layout = "full",
  cross_tab_data_mode = "asset",
  deferred_charts     = TRUE
)

# Add the Home page (landing page)
dashboard <- dashboard %>%
  add_page(
    name            = "Home",
    content         = home_content,
    icon            = "ph:house-fill",
    is_landing_page = TRUE
  )

# Add Page 1: Attitudes (stackedbar charts with topic switching)
dashboard <- dashboard %>%
  add_page(
    name    = "Attitudes",
    data    = page1_data,
    content = page1_content,
    icon    = "ph:head-circuit"
  )

# Add Page 2: Values (bar charts, single topic)
dashboard <- dashboard %>%
  add_page(
    name    = "Values",
    data    = page2_data,
    content = page2_content,
    icon    = "ph:globe-hemisphere-west"
  )

# Generate and open the dashboard!
dashboard %>%
  generate_dashboard(render = TRUE, open = TRUE)

cat("\nDashboard generated at:", normalizePath(output_dir), "\n")
