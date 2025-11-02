# Stacked Bar Charts

Turns wide survey data (one column per question) into long format and
then creates a stacked‐bar chart where each bar is a question and each
stack is a Likert‐type response category.

## Usage

``` r
create_stackedbars(
  data,
  questions,
  question_labels = NULL,
  response_levels = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  stack_label = NULL,
  stacked_type = c("normal", "percent", "counts"),
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  color_palette = NULL,
  stack_order = NULL,
  x_order = NULL,
  include_na = FALSE,
  na_label_x = "(Missing)",
  na_label_stack = "(Missing)",
  x_breaks = NULL,
  x_bin_labels = NULL,
  x_map_values = NULL,
  stack_breaks = NULL,
  stack_bin_labels = NULL,
  stack_map_values = NULL,
  show_question_tooltip = TRUE,
  horizontal = FALSE,
  weight_var = NULL
)
```

## Arguments

- data:

  A data frame with one column per survey question (one row per
  respondent).

- questions:

  Character vector of column names to pivot (the survey questions).

- question_labels:

  Optional character vector of labels for the questions. Must be the
  same length as `questions`. If `NULL`, `questions` are used as labels.

- response_levels:

  Optional character vector of factor levels for the Likert responses
  (e.g. `c("Strongly Disagree", …, "Strongly Agree")`).

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional label for the X‐axis. Defaults to "Questions".

- y_label:

  Optional label for the Y‐axis. Defaults to "Number of Respondents" or
  "Percentage of Respondents" if `stacked_type = "percent"`.

- stack_label:

  Optional title for the stack legend. Set to NULL, NA, FALSE, or "" to
  hide the legend title completely.

- stacked_type:

  Type of stacking: `"normal"` or `"counts"` (raw counts) or `"percent"`
  (100% stacked). Defaults to `"normal"`. Note: "counts" is an alias for
  "normal".

- tooltip_prefix:

  Optional string prepended to tooltip values.

- tooltip_suffix:

  Optional string appended to tooltip values.

- x_tooltip_suffix:

  Optional string appended to X‐axis tooltip values.

- color_palette:

  Optional character vector of colors for the stacks.

- stack_order:

  Optional character vector specifying the order of response levels.

- x_order:

  Optional character vector specifying the order of questions.

- include_na:

  Logical. If `TRUE`, NA values are shown as explicit categories; if
  `FALSE`, rows with `NA` in question or response are dropped. Default
  `FALSE`.

- na_label_x:

  Optional string. Custom label for NA values in questions. Defaults to
  "(Missing)".

- na_label_stack:

  Optional string. Custom label for NA values in responses. Defaults to
  "(Missing)".

- x_breaks:

  Optional numeric vector of cut points to bin the questions (if they
  are numeric). Not typical for Likert.

- x_bin_labels:

  Optional character vector of labels for `x_breaks`.

- x_map_values:

  Optional named list to rename question values.

- stack_breaks:

  Optional numeric vector of cut points to bin the responses.

- stack_bin_labels:

  Optional character vector of labels for `stack_breaks`.

- stack_map_values:

  Optional named list to rename response values.

- show_question_tooltip:

  Logical. If `TRUE`, shows custom tooltip with question labels.

- horizontal:

  Logical. If `TRUE`, creates a horizontal bar chart (bars extend from
  left to right). If `FALSE` (default), creates a vertical column chart
  (bars extend from bottom to top). Note: When horizontal = TRUE, the
  stack order is automatically reversed so that the visual order of the
  stacks matches the legend order.

## Value

A `highcharter` stacked bar chart object.

## Examples

``` r
# Load GSS data
data(gss_all)
#> Warning: data set ‘gss_all’ not found

# Filter to recent years and select Likert-style questions
gss_recent <- gss_all %>%
  filter(year >= 2010) %>%
  select(year, confinan, confed, conmedic, conjudge, consci, conlegis)
#> Error in select(., year, confinan, confed, conmedic, conjudge, consci,     conlegis): could not find function "select"

# Example 1: Basic Likert chart - Confidence in institutions
confidence_questions <- c("confinan", "confed", "conmedic", "conjudge", "consci", "conlegis")
confidence_labels <- c(
  "Financial Institutions",
  "Education",
  "Medicine",
  "Courts/Justice",
  "Scientific Community",
  "Congress"
)

# Define response order (typical GSS confidence scale)
confidence_order <- c("A Great Deal", "Only Some", "Hardly Any")

plot1 <- create_stackedbars(
  data = gss_recent,
  questions = confidence_questions,
  question_labels = confidence_labels,
  title = "Confidence in American Institutions",
  subtitle = "GSS respondents 2010-present",
  x_label = "Institution",
  stack_label = "Level of Confidence",
  response_levels = confidence_order,
  stacked_type = "percent",
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
)
#> Error: object 'gss_recent' not found
plot1
#> Error: object 'plot1' not found

# Example 2: Including NA values with custom labels
plot2 <- create_stackedbars(
  data = gss_recent,
  questions = confidence_questions,
  question_labels = confidence_labels,
  title = "Confidence in Institutions (Including Non-Responses)",
  subtitle = "Showing missing data explicitly",
  x_label = "Institution",
  stack_label = "Response",
  include_na = TRUE,
  na_label_stack = "No Opinion/Refused",
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C", "#808080")
)
#> Error: object 'gss_recent' not found
plot2
#> Error: object 'plot2' not found

# Example 3: Custom response mapping and ordering
# Map GSS codes to more descriptive labels
confidence_map <- list(
  "A Great Deal" = "High Confidence",
  "Only Some" = "Moderate Confidence",
  "Hardly Any" = "Low Confidence"
)

plot3 <- create_stackedbars(
  data = gss_recent,
  questions = confidence_questions[1:4],  # Just first 4 institutions
  question_labels = confidence_labels[1:4],
  title = "Institutional Confidence with Custom Labels",
  subtitle = "Remapped response categories",
  stack_map_values = confidence_map,
  stack_order = c("High Confidence", "Moderate Confidence", "Low Confidence"),
  stacked_type = "normal",
  color_palette = c("#1f77b4", "#ff7f0e", "#d62728")
)
#> Error: object 'gss_recent' not found
plot3
#> Error: object 'plot3' not found

# Example 4: Custom question ordering and tooltips
# Reorder questions by typical confidence levels (highest to lowest)
custom_question_order <- c(
  "Scientific Community",
  "Medicine",
  "Education",
  "Courts/Justice",
  "Financial Institutions",
  "Congress"
)

plot4 <- create_stackedbars(
  data = gss_recent,
  questions = confidence_questions,
  question_labels = confidence_labels,
  title = "Institutional Confidence (Reordered)",
  subtitle = "Ordered from typically highest to lowest confidence",
  x_order = custom_question_order,
  response_levels = confidence_order,
  stacked_type = "percent",
  tooltip_prefix = "Response: ",
  tooltip_suffix = "% of respondents",
  x_tooltip_suffix = " institution",
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
)
#> Error: object 'gss_recent' not found
plot4
#> Error: object 'plot4' not found

# Example 5: Horizontal bar chart
plot5 <- create_stackedbars(
  data = gss_recent,
  questions = confidence_questions,
  question_labels = confidence_labels,
  title = "Confidence in American Institutions (Horizontal)",
  subtitle = "GSS respondents 2010-present",
  x_label = "Institution",
  stack_label = "Level of Confidence",
  response_levels = confidence_order,
  stacked_type = "percent",
  horizontal = TRUE,  # Creates horizontal bars
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C")
)
#> Error: object 'gss_recent' not found
plot5
#> Error: object 'plot5' not found

# Example 6: Working with different Likert scales
# Using happiness and life satisfaction questions if available
if (all(c("happy", "satfin", "satjob") %in% names(gss_all))) {
  satisfaction_data <- gss_all %>%
    filter(year >= 2010) %>%
    select(happy, satfin, satjob) %>%
    # Convert to consistent scale for demonstration
    mutate(across(everything(), as.character))

  satisfaction_questions <- c("happy", "satfin", "satjob")
  satisfaction_labels <- c("General Happiness", "Financial Satisfaction", "Job Satisfaction")

  plot6 <- create_stackedbars(
    data = satisfaction_data,
    questions = satisfaction_questions,
    question_labels = satisfaction_labels,
    title = "Life Satisfaction Measures",
    subtitle = "Multiple satisfaction domains",
    x_label = "Life Domain",
    stack_label = "Satisfaction Level",
    stacked_type = "percent",
    include_na = TRUE,
    na_label_stack = "Not Asked/No Answer"
  )
  plot6
}
#> Error: object 'gss_all' not found

```
