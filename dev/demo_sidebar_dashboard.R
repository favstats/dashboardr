# =============================================================================
# Demo: Sidebar dashboard with real GSS data (linked dropdowns + show_when)
#
# Uses the General Social Survey (gssr package) to demonstrate:
#   - add_linked_inputs(): topic dimension controls which GSS questions appear
#   - add_input(): wave year (2022 / 2024 / Over Time),
#                  Compare by (Overall / Sex / Race / Age / Education / Pol. Views)
#   - add_viz(show_when = ~ ...): stacked bar for a single year, timeline for trend
#
# Data structure: pre-aggregated counts in long format
#   (dimension, question, time_period, breakdown_type, breakdown_value, response, n)
# =============================================================================

devtools::load_all()
library(dplyr)
library(tidyr)
library(gssr)

data("gss_all")

# ---- Configuration ----------------------------------------------------------

# Dimension → Question mapping (for linked inputs)
questions_by_dimension <- list(
  "Social Issues"       = c("Marijuana Legalization", "Death Penalty", "Gun Control"),
  "Spending Priorities" = c("Environment", "Healthcare", "Race"),
  "Institutional Trust" = c("Congress", "Supreme Court", "Press", "Banks & Finance"),
  "Social Trust"        = c("General Trust", "Fairness", "Helpfulness")
)

# Question → GSS variable name
question_var <- c(
  "Marijuana Legalization" = "grass",
  "Death Penalty"          = "cappun",
  "Gun Control"            = "gunlaw",
  "Environment"            = "natenvir",
  "Healthcare"             = "natheal",
  "Race"                   = "natrace",
  "Congress"               = "conlegis",
  "Supreme Court"          = "conjudge",
  "Press"                  = "conpress",
  "Banks & Finance"        = "confinan",
  "General Trust"          = "trust",
  "Fairness"               = "fair",
  "Helpfulness"            = "helpful"
)

# Reverse map: question → dimension
question_dim <- unlist(lapply(names(questions_by_dimension), function(d) {
  setNames(rep(d, length(questions_by_dimension[[d]])), questions_by_dimension[[d]])
}))

# Response labels (numeric GSS code → readable label)
resp_labels <- list(
  grass    = c("1" = "Legal", "2" = "Not Legal"),
  cappun   = c("1" = "Favor", "2" = "Oppose"),
  gunlaw   = c("1" = "Favor", "2" = "Oppose"),
  natenvir = c("1" = "Too Little", "2" = "About Right", "3" = "Too Much"),
  natheal  = c("1" = "Too Little", "2" = "About Right", "3" = "Too Much"),
  natrace  = c("1" = "Too Little", "2" = "About Right", "3" = "Too Much"),
  conlegis = c("1" = "A Great Deal", "2" = "Only Some", "3" = "Hardly Any"),
  conjudge = c("1" = "A Great Deal", "2" = "Only Some", "3" = "Hardly Any"),
  conpress = c("1" = "A Great Deal", "2" = "Only Some", "3" = "Hardly Any"),
  confinan = c("1" = "A Great Deal", "2" = "Only Some", "3" = "Hardly Any"),
  trust    = c("1" = "Can Trust", "2" = "Can't Be Too Careful", "3" = "Depends"),
  fair     = c("1" = "Fair", "2" = "Take Advantage", "3" = "Depends"),
  helpful  = c("1" = "Helpful", "2" = "Look Out for Self", "3" = "Depends")
)

# "Key" response for the timeline (% choosing this answer over time)
key_resp <- c(
  grass    = "Legal",
  cappun   = "Favor",
  gunlaw   = "Favor",
  natenvir = "Too Little",
  natheal  = "Too Little",
  natrace  = "Too Little",
  conlegis = "A Great Deal",
  conjudge = "A Great Deal",
  conpress = "A Great Deal",
  confinan = "A Great Deal",
  trust    = "Can Trust",
  fair     = "Fair",
  helpful  = "Helpful"
)

# Map question labels → key response (for dynamic title)
key_response_map <- setNames(key_resp[question_var], names(question_var))

# Two most recent GSS waves for the bar chart view
wave_years <- c(2022, 2024)

# ---- Recode helpers ---------------------------------------------------------

recode_age <- function(age) {
  case_when(
    age >= 18 & age <= 29 ~ "18-29",
    age >= 30 & age <= 44 ~ "30-44",
    age >= 45 & age <= 59 ~ "45-59",
    age >= 60             ~ "60+",
    TRUE                  ~ NA_character_
  )
}

recode_degree <- function(deg) {
  case_when(
    deg %in% c(0, 1) ~ "HS or Less",
    deg == 2          ~ "Some College",
    deg %in% c(3, 4) ~ "Bachelors+",
    TRUE              ~ NA_character_
  )
}

recode_polviews <- function(pv) {
  case_when(
    pv %in% 1:3 ~ "Liberal",
    pv == 4      ~ "Moderate",
    pv %in% 5:7 ~ "Conservative",
    TRUE         ~ NA_character_
  )
}

# ---- Prepare data -----------------------------------------------------------

# Select columns & recode breakdown variables
gss <- gss_all %>%
  select(year, age, sex, race, degree, polviews,
         all_of(unname(question_var))) %>%
  mutate(
    age_group      = recode_age(as.numeric(age)),
    sex_label      = case_when(as.numeric(sex) == 1 ~ "Male",
                               as.numeric(sex) == 2 ~ "Female"),
    race_label     = case_when(as.numeric(race) == 1 ~ "White",
                               as.numeric(race) == 2 ~ "Black",
                               as.numeric(race) == 3 ~ "Other"),
    degree_label   = recode_degree(as.numeric(degree)),
    polviews_label = recode_polviews(as.numeric(polviews))
  )

# Build response lookup table for efficient joining
resp_lookup <- bind_rows(lapply(names(resp_labels), function(v) {
  data.frame(
    gss_var       = v,
    response_code = as.numeric(names(resp_labels[[v]])),
    response      = unname(resp_labels[[v]]),
    stringsAsFactors = FALSE
  )
}))

# Pivot question variables to long format + join response labels
gss_long <- gss %>%
  mutate(across(all_of(unname(question_var)), as.numeric)) %>%
  pivot_longer(
    cols            = all_of(unname(question_var)),
    names_to        = "gss_var",
    values_to       = "response_code",
    values_drop_na  = TRUE
  ) %>%
  left_join(resp_lookup, by = c("gss_var", "response_code")) %>%
  filter(!is.na(response)) %>%
  mutate(
    question  = names(question_var)[match(gss_var, question_var)],
    dimension = unname(question_dim[question])
  )

# ---- Aggregate: bar data (wave years × breakdown types) ---------------------

compute_bar <- function(data, type, value_col = NULL) {
  if (is.null(value_col)) {
    data %>%
      count(dimension, question, gss_var, year, response, name = "n") %>%
      mutate(breakdown_type = "Overall", breakdown_value = "All")
  } else {
    data %>%
      filter(!is.na(.data[[value_col]])) %>%
      rename(breakdown_value = !!rlang::sym(value_col)) %>%
      count(dimension, question, gss_var, year, response,
            breakdown_value, name = "n") %>%
      mutate(breakdown_type = type)
  }
}

gss_waves <- gss_long %>% filter(year %in% wave_years)

bar_data <- bind_rows(
  compute_bar(gss_waves, "Overall"),
  compute_bar(gss_waves, "Sex",             "sex_label"),
  compute_bar(gss_waves, "Race",            "race_label"),
  compute_bar(gss_waves, "Age",             "age_group"),
  compute_bar(gss_waves, "Education",       "degree_label"),
  compute_bar(gss_waves, "Political Views", "polviews_label")
) %>%
  mutate(
    time_period = as.character(year),
    wave_date   = as.Date(paste0(year, "-06-15")),
    score       = NA_real_
  )

# ---- Aggregate: timeline data (all years × breakdown types) -----------------

compute_timeline <- function(data, type, value_col = NULL) {
  if (is.null(value_col)) {
    data %>%
      group_by(dimension, question, gss_var, year) %>%
      summarize(
        score = round(100 * sum(response == key_resp[first(gss_var)]) / n(), 1),
        .groups = "drop"
      ) %>%
      mutate(breakdown_type = "Overall", breakdown_value = "All")
  } else {
    data %>%
      filter(!is.na(.data[[value_col]])) %>%
      rename(breakdown_value = !!rlang::sym(value_col)) %>%
      group_by(dimension, question, gss_var, year, breakdown_value) %>%
      summarize(
        score = round(100 * sum(response == key_resp[first(gss_var)]) / n(), 1),
        .groups = "drop"
      ) %>%
      mutate(breakdown_type = type)
  }
}

timeline_data <- bind_rows(
  compute_timeline(gss_long, "Overall"),
  compute_timeline(gss_long, "Sex",             "sex_label"),
  compute_timeline(gss_long, "Race",            "race_label"),
  compute_timeline(gss_long, "Age",             "age_group"),
  compute_timeline(gss_long, "Education",       "degree_label"),
  compute_timeline(gss_long, "Political Views", "polviews_label")
) %>%
  mutate(
    time_period = "Over Time",
    wave_date   = as.Date(paste0(year, "-06-15")),
    response    = "Score",
    n           = NA_integer_
  )

# ---- Combine into single page dataset --------------------------------------

page_data <- bind_rows(bar_data, timeline_data) %>%
  select(dimension, question, time_period, year, wave_date,
         breakdown_type, breakdown_value, response, n, score)

# Chart ordering (covers all response categories across question types)
all_responses <- c(
  "Legal", "Not Legal",
  "Favor", "Oppose",
  "Too Little", "About Right", "Too Much",
  "A Great Deal", "Only Some", "Hardly Any",
  "Can Trust", "Can't Be Too Careful",
  "Fair", "Take Advantage",
  "Helpful", "Look Out for Self",
  "Depends"
)

all_groups <- c(
  "All",
  "Male", "Female",
  "Other", "Black", "White",
  "60+", "45-59", "30-44", "18-29",
  "Bachelors+", "Some College", "HS or Less",
  "Conservative", "Moderate", "Liberal"
)

# Consistent colors for breakdown groups across all charts
group_colors <- c(
  "All"            = "#4E79A7",
  "Male"           = "#F28E2B", "Female"         = "#E15759",
  "Other"          = "#76B7B2", "Black"          = "#59A14F", "White" = "#EDC948",
  "60+"            = "#B07AA1", "45-59"          = "#FF9DA7",
  "30-44"          = "#9C755F", "18-29"          = "#BAB0AC",
  "Bachelors+"    = "#4E79A7", "Some College"   = "#F28E2B",
  "HS or Less"     = "#E15759",
  "Conservative"   = "#E15759", "Moderate"       = "#76B7B2",
  "Liberal"        = "#4E79A7"
)

# ---- Dashboard --------------------------------------------------------------

if (!exists("output_dir")) output_dir <- "sidebar_gss_demo"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

explorer_content <- create_content(data = page_data) %>%
  add_sidebar(title = "Controls", width = "300px") %>%
    add_linked_inputs(
      parent = list(
        id      = "dimension",
        label   = "Topic",
        options = names(questions_by_dimension)
      ),
      child = list(
        id               = "question",
        label            = "<br>Question",
        options_by_parent = questions_by_dimension
      )
    ) %>%
    add_divider() %>%
    add_input(
      input_id         = "time_period",
      label            = "Time period",
      type             = "radio",
      filter_var       = "time_period",
      options          = c(as.character(wave_years), "Over Time"),
      default_selected = as.character(wave_years[1]),
      stacked          = TRUE,
      stacked_align    = "center",
      group_align      = "center"
    ) %>%
    add_input(
      input_id         = "breakdown",
      label            = "Compare by",
      type             = "radio",
      filter_var       = "breakdown_type",
      options          = c("Overall", "Sex", "Race", "Age",
                           "Education", "Political Views"),
      default_selected = "Overall",
      stacked          = TRUE,
      stacked_align    = "center",
      group_align      = "center"
    ) %>%
  end_sidebar() %>%
  # Overall view: single bar per question showing response distribution
  add_viz(
    type         = "stackedbar",
    x_var        = "question",
    stack_var    = "response",
    y_var        = "n",
    title        = "{dimension}: {question} by {breakdown}",
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_order  = all_responses,
    stack_label  = "Response",
    show_when    = ~ time_period %in% c("2022", "2024") & breakdown == "Overall"
  ) %>%
  # Comparison view: response bars stacked by breakdown groups
  add_viz(
    type         = "stackedbar",
    x_var        = "response",
    stack_var    = "breakdown_value",
    y_var        = "n",
    title        = "{dimension}: {question} by {breakdown} ({time_period})",
    stacked_type = "percent",
    horizontal   = TRUE,
    stack_order    = all_groups,
    x_order        = all_responses,
    stack_label    = "Group",
    color_palette  = group_colors,
    show_when      = ~ time_period %in% c("2022", "2024") & breakdown != "Overall"
  ) %>%
  add_viz(
    type          = "timeline",
    time_var      = "year",
    y_var         = "score",
    group_var     = "breakdown_value",
    agg           = "none",
    group_order   = rev(all_groups),
    color_palette = group_colors,
    title       = "{dimension} - {question}: % responding '{key_response}' by {breakdown}",
    x_label     = "Year",
    y_label     = "% Key Response",
    show_when  = ~ time_period == "Over Time",
    title_map  = list(key_response = key_response_map)
  )

dashboard <- create_dashboard("11111", "GSS Explorer", theme = "litera") %>%
  add_page("Explorer", data = page_data, content = explorer_content)

generate_dashboard(dashboard, render = T)

# generate_dashboard(dashboard, render = !isTRUE(getOption("dashboardr.no_render", FALSE)))
message("Dashboard generated in: ", output_dir)

