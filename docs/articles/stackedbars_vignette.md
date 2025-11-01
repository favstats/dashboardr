# Getting Started With \`create_stackedbars()\`

Welcome to this comprehensive guide on using the `create_stackedbars`
function from the `dashboardr` package. This function is specifically
designed to handle a common challenge in survey research: visualizing
responses to multiple Likert-type questions simultaneously.

The `create_stackedbars` function transforms wide survey data (where
each question is a separate column) into an elegant stacked bar chart
where: - Each bar represents a different survey question - Each stack
within a bar represents a response category (e.g., “Strongly Agree”,
“Agree”, etc.) - Colors show the distribution of responses across all
questions

This approach is particularly valuable for: - **Comparing response
patterns** across multiple related questions - **Identifying questions**
with similar or different response distributions - **Visualizing survey
batteries** (sets of questions with the same response scale) - **Showing
institutional confidence**, satisfaction measures, or attitude scales

The function handles many data preparation tasks automatically,
including pivoting from wide to long format, managing `haven_labelled`
variables from SPSS data, and creating publication-ready interactive
visualizations.

### Getting Started

Let’s load the necessary libraries and examine our dataset. For this
demonstration, we will be using the 2020 wave from the GSS dataset.

``` r
library(gssr)
```

    ## Warning: package 'gssr' was built under R version 4.4.3

    ## Error in get(paste0(generic, ".", class), envir = get_method_env()) : 
    ##   object 'type_sum.accel' not found

    ## Package loaded. To attach the GSS data, type data(gss_all) at the console.
    ## For the panel data and documentation, type e.g. data(gss_panel08_long) and data(gss_panel_doc).
    ## For help on a specific GSS variable, type ?varname at the console.

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(highcharter)
```

    ## Registered S3 method overwritten by 'quantmod':
    ##   method            from
    ##   as.zoo.data.frame zoo

    ## Highcharts (www.highcharts.com) is a Highsoft software product which is

    ## not free for commercial and Governmental use

``` r
library(tidyr)
library(dashboardr)

# Load GSS Panel 2020 data
data(gss_panel20)
```

### Data Preparation

Let’s identify and prepare Likert-type questions from the 2016 wave
(`_1a` variables) for ease of use in this practical.

``` r
# Look for confidence-related questions (common Likert-type questions in GSS)
confidence_vars <- names(gss_panel20)[grepl("^con.*_1a$", names(gss_panel20))]
cat("Confidence variables found:\n")
```

    ## Confidence variables found:

``` r
print(confidence_vars)
```

    ##  [1] "conarmy_1a"  "conbus_1a"   "conclerg_1a" "condom_1a"   "condrift_1a"
    ##  [6] "coneduc_1a"  "confed_1a"   "confinan_1a" "coninc_1a"   "conjudge_1a"
    ## [11] "conlabor_1a" "conlegis_1a" "conmedic_1a" "conpress_1a" "conrinc_1a" 
    ## [16] "consci_1a"   "consent_1a"  "contv_1a"    "conbiz_1a"   "conchurh_1a"
    ## [21] "concong_1a"  "concourt_1a" "condemnd_1a" "conf2f_1a"   "conschls_1a"
    ## [26] "conwkday_1a"

``` r
# Look for other attitude/satisfaction variables
attitude_vars <- names(gss_panel20)[grepl("(trust|fair|helpful|happy).*_1a$", names(gss_panel20))]
cat("\nAttitude variables found:\n")
```

    ## 
    ## Attitude variables found:

``` r
print(attitude_vars)
```

    ##  [1] "fair_1a"      "happy_1a"     "helpful_1a"   "trust_1a"     "befair_1a"   
    ##  [6] "cantrust_1a"  "fairearn_1a"  "spvtrfair_1a" "trustman_1a"  "trustsci_1a" 
    ## [11] "unhappy_1a"

``` r
# Create a working dataset with key Likert-type variables
gss_likert <- gss_panel20 %>%
  select(
    # Confidence in institutions (if available)
    any_of(confidence_vars),
    # Individual attitudes
    trust_1a, fair_1a, helpful_1a, happy_1a,
    # Additional context variables
    age_1a, sex_1a, degree_1a
  ) %>%
  # Remove completely empty rows
  filter(if_any(everything(), ~ !is.na(.)))

# Examine the response patterns for key variables
cat("Trust responses:\n")
```

    ## Trust responses:

``` r
table(gss_likert$trust_1a, useNA = "always")
```

    ## 
    ##    1    2    3 <NA> 
    ##  623 1244   79  921

``` r
cat("\nFair responses:\n") 
```

    ## 
    ## Fair responses:

``` r
table(gss_likert$fair_1a, useNA = "always")
```

    ## 
    ##    1    2    3 <NA> 
    ##  797 1028  114  928

``` r
cat("\nHelpful responses:\n")
```

    ## 
    ## Helpful responses:

``` r
table(gss_likert$helpful_1a, useNA = "always")
```

    ## 
    ##    1    2    3 <NA> 
    ##  917  892  137  921

``` r
cat("\nHappy responses:\n")
```

    ## 
    ## Happy responses:

``` r
table(gss_likert$happy_1a, useNA = "always")
```

    ## 
    ##    1    2    3 <NA> 
    ##  806 1601  452    8

## Basic Multi-Question Charts

### Example 1: Social Trust and Attitudes

Now that we have our simplified data set, let’s create our first
multi-question chart using social attitude variables.

``` r
# Define our questions and labels
social_questions <- c("trust_1a", "fair_1a", "helpful_1a")
social_labels <- c(
  "Interpersonal Trust",
  "Fairness of Others", 
  "Helpfulness of Others"
)

# Create basic multi-question chart
plot1 <- create_stackedbars(
  data = gss_likert,
  questions = social_questions,
  question_labels = social_labels,
  title = "Social Attitudes and Trust",
  subtitle = "GSS Panel 2016 - Distribution of responses across social attitude questions",
  x_label = "Social Attitude Dimension",
  stack_label = "Response Level",
  stacked_type = "normal"
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot1
```

### Example 2: Percentage-Based Comparison

Now let’s create a percentage-based chart to better compare response
patterns across questions.

``` r
# Create percentage-based chart with custom colors
plot2 <- create_stackedbars(
  data = gss_likert,
  questions = social_questions,
  question_labels = social_labels,
  title = "Social Attitudes - Response Distribution",
  subtitle = "Percentage breakdown showing response patterns across questions",
  x_label = "Social Attitude Dimension",
  stack_label = "Response Category",
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba")
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot2
```

## Advanced Customization

### Example 3: Custom Response Ordering and Mapping

Let’s create a more sophisticated chart with custom response ordering
and cleaner labels.

``` r
# First, let's examine what the actual response values are
cat("Unique trust responses:\n")
```

    ## Unique trust responses:

``` r
print(unique(as.character(gss_likert$trust_1a)))
```

    ## [1] NA  "3" "1" "2"

``` r
cat("\nUnique fair responses:\n")
```

    ## 
    ## Unique fair responses:

``` r
print(unique(as.character(gss_likert$fair_1a)))
```

    ## [1] NA  "1" "2" "3"

``` r
#TODO: There is a "Series 4" I think for NA values, that needs to be dealt with, i.e. ideally that has its own value?
# Create response mapping for cleaner labels
response_map <- list(
  "can't trust" = "High Trust/Positive", # I know this doesn't make sense, let's just pretend for the sake of the demo
  "can't be too careful" = "Low Trust/Negative", 
  "depends" = "Situational/Neutral",
  "would try to be fair" = "High Trust/Positive",
  "would take advantage of you" = "Low Trust/Negative",
  "depends" = "Situational/Neutral",
  "try to be helpful" = "High Trust/Positive",
  "looking out for themselves" = "Low Trust/Negative",
  "depends" = "Situational/Neutral"
)

# Define response order (from negative to positive)
response_order <- c("Low Trust/Negative", "Situational/Neutral", "High Trust/Positive")

# Create chart with custom mapping and ordering
plot3 <- create_stackedbars(
  data = gss_likert,
  questions = social_questions,
  question_labels = social_labels,
  title = "Social Trust Dimensions with Standardized Responses",
  subtitle = "Responses mapped to consistent positive/negative categories",
  x_label = "Trust Dimension",
  stack_label = "Trust Level",
  stack_map_values = response_map,
  stack_order = response_order,
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#d62728", "#ffbb78", "#2ca02c", "grey")
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

    ## Warning: stack_order provided with stack_map_values. Ensure stack_order refers
    ## to the *new* mapped labels.

``` r
plot3
```

### Example 4: Including Missing Values

Let’s create a chart that explicitly shows missing data patterns.

``` r
# Create chart including NA values
plot4 <- create_stackedbars(
  data = gss_likert,
  questions = social_questions,
  question_labels = social_labels,
  title = "Social Attitudes Including Non-Responses",
  subtitle = "Showing missing data patterns explicitly",
  x_label = "Social Attitude Question",
  stack_label = "Response",
  stack_map_values = response_map,
  include_na = TRUE,
  na_label_stack = "No Answer/Not Asked",
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("forestgreen", "darkred", "grey", "yellow")
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot4
```

## Working with Different Question Types

### Example 5: Happiness and Life Satisfaction

Let’s work with happiness as a different type of Likert scale.

``` r
# Create a happiness-focused analysis
happiness_questions <- c("happy_1a")
happiness_labels <- c("General Happiness")

# Check happiness response values
cat("Happiness responses:\n")
```

    ## Happiness responses:

``` r
table(gss_likert$happy_1a, useNA = "always")
```

    ## 
    ##    1    2    3 <NA> 
    ##  806 1601  452    8

``` r
# Create happiness chart
plot5 <- create_stackedbars(
  data = gss_likert,
  questions = "happy_1a",
  title = "General Happiness Distribution",
  x_label = "Well-being Measure",
  stack_label = "Happiness Level",
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C", "grey")
)
```

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot5
```

### Example 6: Combining Different Question Types

Let’s create a comprehensive chart combining different types of attitude
questions. In general, we recommend to have one battery per chart. But,
if you really want to have different responses in the same chart, then
you’ll need to standardize the response labels before charting,
especially if using SPSS data.

``` r
#TODO: this chart I dont get it has so many different scales, I think ideally should only be used with same scale?
# Standardize responses before charting
gss_standardized <- gss_likert %>%
  mutate(
    # Convert haven_labelled to character with labels first
    trust_1a_char = as.character(haven::as_factor(trust_1a, levels = "labels")),
    fair_1a_char = as.character(haven::as_factor(fair_1a, levels = "labels")),
    helpful_1a_char = as.character(haven::as_factor(helpful_1a, levels = "labels")),
    happy_1a_char = as.character(haven::as_factor(happy_1a, levels = "labels")),
    
    # Now do the case_when with the actual text labels
    trust_1a_std = case_when(
      trust_1a_char == "Can Trust" ~ "Positive",
      trust_1a_char == "Can't Be Too Careful" ~ "Negative", 
      trust_1a_char == "Depends" ~ "Neutral",
      TRUE ~ trust_1a_char
    ),
    fair_1a_std = case_when(
      fair_1a_char == "Most People Try to Be Fair" ~ "Positive",
      fair_1a_char == "Most People Try to Take Advantage" ~ "Negative",
      fair_1a_char == "Depends" ~ "Neutral",  # Fixed: was trust_1a
      TRUE ~ fair_1a_char
    ),
    helpful_1a_std = case_when(
      helpful_1a_char == "Most People Try to Be Helpful" ~ "Positive",
      helpful_1a_char == "Most People Look Out for Themselves" ~ "Negative",
      helpful_1a_char == "Depends" ~ "Neutral",  # Fixed: was trust_1a
      TRUE ~ helpful_1a_char
    ),
    happy_1a_std = case_when(
      happy_1a_char == "Very Happy" ~ "Positive",
      happy_1a_char == "Pretty Happy" ~ "Neutral",
      happy_1a_char == "Not Too Happy" ~ "Negative",
      TRUE ~ happy_1a_char
    )
  )
```

``` r
# Check what the actual labels are after conversion
cat("Trust labels:\n")
```

    ## Trust labels:

``` r
table(gss_standardized$trust_1a_char, useNA = "always")
```

    ## 
    ## can't be too careful          can't trust              depends 
    ##                 1244                  623                   79 
    ##                 <NA> 
    ##                  921

``` r
cat("\nFair labels:\n") 
```

    ## 
    ## Fair labels:

``` r
table(gss_standardized$fair_1a_char, useNA = "always")
```

    ## 
    ##                     depends would take advantage of you 
    ##                         114                         797 
    ##        would try to be fair                        <NA> 
    ##                        1028                         928

``` r
cat("\nHelpful labels:\n")
```

    ## 
    ## Helpful labels:

``` r
table(gss_standardized$helpful_1a_char, useNA = "always")
```

    ## 
    ##                    depends looking out for themselves 
    ##                        137                        892 
    ##          try to be helpful                       <NA> 
    ##                        917                        921

``` r
cat("\nHappy labels:\n")
```

    ## 
    ## Happy labels:

``` r
table(gss_standardized$happy_1a_char, useNA = "always")
```

    ## 
    ## not too happy  pretty happy    very happy          <NA> 
    ##           452          1601           806             8

``` r
# Then use the standardized versions
standardized_questions <- c("trust_1a_std", "fair_1a_std", "helpful_1a_std", "happy_1a_std")

# Write the question labels
standardized_labels <- c(
  "Can People Be Trusted?",
  "Are People Generally Fair?", 
  "Are People Generally Helpful?",
  "How Happy Are You?"
)

# Create comprehensive chart
plot6 <- create_stackedbars(
  data = gss_standardized,
  questions = standardized_questions,
  question_labels = standardized_labels,
  title = "Social Attitudes and Well-being Battery",
  subtitle = "Multiple dimensions of social trust and personal happiness",
  x_label = "Question Domain",
  stack_label = "Response",
  stacked_type = "percent",
  tooltip_prefix = "Response: ",
  tooltip_suffix = "% of respondents",
  x_tooltip_suffix = " question"
)

plot6
```

## Advanced Analysis Techniques

### Example 7: Demographic Subgroup Analysis

Let’s create separate charts for different demographic groups.

``` r
## TODO: maybe we dont need the if logic here? I think is confusing for the tutorial.
# You probably noticed one of the response labels is incorrect. Let's fix that first. We can do this easily using mapping in the `create_barcharts` function.
trust_fix_map <- list(
  "can't trust" = "can trust"
  # Add other mappings if needed
)

# Next, let's examine what degree values actually exist
cat("Degree values in data:\n")
```

    ## Degree values in data:

``` r
table(gss_likert$degree_1a, useNA = "always")
```

    ## 
    ##    0    1    2    3    4 <NA> 
    ##  328 1461  216  536  318    8

``` r
# Convert degree to factor with labels to see what we're working with
degree_labels <- as.character(haven::as_factor(gss_likert$degree_1a, levels = "labels"))
cat("\nDegree labels:\n")
```

    ## 
    ## Degree labels:

``` r
table(degree_labels, useNA = "always")
```

    ## degree_labels
    ## associate/junior college               bachelor's                 graduate 
    ##                      216                      536                      318 
    ##              high school    less than high school                     <NA> 
    ##                     1461                      328                        8

``` r
# Create education groups based on actual data
gss_education <- gss_likert %>%
  mutate(
    degree_label = as.character(haven::as_factor(degree_1a, levels = "labels")),
    education_group = case_when(
      degree_label %in% c("less than high school", "high school") ~ "High School or Less",
      degree_label %in% c("associate/junior college", "bachelor's", "graduate") ~ "College or More",
      TRUE ~ "Other/Missing"
    )
  ) %>%
  filter(education_group != "Other/Missing")

# Check the groups
cat("\nEducation groups:\n")
```

    ## 
    ## Education groups:

``` r
table(gss_education$education_group, useNA = "always")
```

    ## 
    ##     College or More High School or Less                <NA> 
    ##                1070                1789                   0

``` r
# Filter for college or more
college_data <- gss_education %>%
  filter(education_group == "College or More")

cat("\nCollege data rows:", nrow(college_data), "\n")
```

    ## 
    ## College data rows: 1070

``` r
# Filter for high school or less  
high_school_data <- gss_education %>%
  filter(education_group == "High School or Less")

cat("High school data rows:", nrow(high_school_data), "\n")
```

    ## High school data rows: 1789

``` r
# Only create charts if we have sufficient data
if (nrow(college_data) > 50) {
  plot8a <- create_stackedbars(
    data = college_data,
    questions = social_questions,
    question_labels = social_labels,
    stack_map_values = trust_fix_map,
    title = "Social Attitudes Among College-Educated",
    subtitle = paste0("Junior college, bachelor's, and graduate degree holders (n=", nrow(college_data), ")"),
    x_label = "Social Attitude Dimension",
    stack_label = "Response",
    stacked_type = "percent",
    include_na = TRUE,
    na_label_stack = "No Answer",
    tooltip_suffix = "%",
    color_palette = c("#2166ac", "#762a83", "#5aae61", "darkgrey")
  )
  
  print("College-educated chart:")
  print(plot8a)
} else {
  cat("Not enough college-educated respondents for analysis\n")
}
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

    ## [1] "College-educated chart:"

``` r
if (nrow(high_school_data) > 50) {
  plot8b <- create_stackedbars(
    data = high_school_data,
    questions = social_questions,
    question_labels = social_labels,
    stack_map_values = trust_fix_map,
    title = "Social Attitudes Among High School Educated",
    subtitle = paste0("High school diploma or less (n=", nrow(high_school_data), ")"),
    x_label = "Social Attitude Dimension", 
    stack_label = "Response",
    stacked_type = "percent",
    include_na = TRUE,
    na_label_stack = "No Answer",
    tooltip_suffix = "%",
    color_palette = c("#2166ac", "#762a83", "#5aae61", "darkgrey")
  )
  
  print("High school educated chart:")
  print(plot8b)
} else {
  cat("Not enough high school educated respondents for analysis\n")
}
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2
    ## `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

    ## [1] "High school educated chart:"

## Working with Survey Batteries

### Example 9: Creating Question Batteries

Let’s demonstrate how to work with related sets of questions (survey
batteries).

``` r
# Create a social trust battery
trust_battery <- c("trust_1a", "fair_1a", "helpful_1a")
trust_battery_labels <- c(
  "Interpersonal Trust",
  "Perceived Fairness",
  "Perceived Helpfulness"
)

# Create a comprehensive battery analysis
plot9 <- create_stackedbars(
  data = gss_likert,
  questions = trust_battery,
  question_labels = trust_battery_labels,
  title = "Social Trust Battery - Complete Analysis",
  subtitle = "Comprehensive view of social trust dimensions with enhanced tooltips",
  x_label = "Trust Dimension",
  stack_label = "Response Category",
  stacked_type = "percent",
  tooltip_prefix = "Percentage: ",
  tooltip_suffix = "% of respondents",
  show_question_tooltip = TRUE,
  include_na = TRUE,
  na_label_stack= "No answer",
  color_palette = c("#8c510a", "#d8b365", "#f6e8c3", "darkgrey")
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot9
```

## Best Practices and Tips

### Example 10: Publication-Ready Chart

Let’s create a fully customized, publication-ready chart.

``` r
# Create the most polished example
plot10 <- create_stackedbars(
  data = gss_likert,
  questions = social_questions,
  question_labels = c(
    "Interpersonal Trust\n('Can most people be trusted?')",
    "Perceived Fairness\n('Do people try to be fair?')",
    "Perceived Helpfulness\n('Are people helpful?')"
  ),
  title = "Social Capital Dimensions in American Society",
  subtitle = "General Social Survey Panel 2016 (N = 2,867 respondents)\nPercentage distribution of responses across social trust measures",
  x_label = "Social Trust Dimension",
  stack_label = "Response Category",
  stacked_type = "percent",
  tooltip_prefix = "",
  tooltip_suffix = "% of respondents",
  x_tooltip_suffix = "",
  include_na = TRUE,
  na_label_stack = "No response",
  color_palette = c("#b2182b", "#ef8a62", "#fddbc7", "darkgrey"),
  show_question_tooltip = TRUE
)
```

    ## Warning: `trust_1a` and `fair_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Warning: `trust_1a` and `helpful_1a` have conflicting value labels.
    ## ℹ Labels for these values will be taken from `trust_1a`.
    ## ✖ Values: 1 and 2

    ## Note: Column 'response' was 'haven_labelled' and converted to factor (levels = values).

``` r
plot10
```

## Summary and Best Practices

### Key Features Demonstrated

1.  **Multi-question visualization** with automatic wide-to-long data
    transformation
2.  **Custom question labeling** for more descriptive axis labels
3.  **Response mapping and ordering** for consistent presentation
4.  **Missing value handling** with explicit NA categories
5.  **Percentage vs. count displays** for different analytical needs
6.  **Demographic subgroup analysis** for comparative insights
7.  **Survey battery analysis** for related question sets
8.  **Publication-ready styling** with comprehensive customization

### Best Practices for Multi-Question Charts

1.  Choose questions with similar response scales

- Use questions that have the same or compatible response categories
- Consider mapping different scales to common categories when
  appropriate

2.  Order questions logically

- Group related concepts together
- Consider ordering by typical response patterns (most positive to least
  positive)
- Place most important questions first

3.  Use appropriate stacking type

- Use “percent” for comparing response patterns across questions
- Use “normal” when absolute counts matter more than proportions

4.  Handle missing data thoughtfully

- Decide whether missing patterns are substantively meaningful
- Use include_na = TRUE when non-response patterns are important
- Provide clear labels for missing categories

5.  Choose colors carefully

- Use consistent color schemes across related charts
- Consider the meaning of response categories (positive/negative)
- Ensure sufficient contrast between adjacent categories
- Test for colorblind accessibility

6.  Customize tooltips for clarity

- Include question text in tooltips when helpful
- Use appropriate number formatting (percentages vs. counts)
- Provide context about sample sizes when relevant

### Conclusion

The
[`create_stackedbars()`](https://favstats.github.io/dashboardr/reference/create_stackedbars.md)
function provides a powerful solution for visualizing multiple
Likert-type survey questions simultaneously. Its key advantages include:

- **Automatic data transformation** from wide to long format
- **Flexible question labeling** for publication-ready displays
- **Comprehensive customization options** for professional presentations
- **Interactive tooltips** for enhanced data exploration
- **Consistent handling** of survey data complexities

By leveraging the GSS Panel 2020 dataset, we’ve demonstrated how this
function can reveal patterns in social attitudes, trust measures, and
other survey constructs. The ability to compare response distributions
across multiple related questions makes it an invaluable tool for survey
researchers, enabling them to communicate complex patterns in public
opinion and social attitudes effectively.

Whether you’re analyzing institutional confidence, social trust, life
satisfaction, or any other multi-item survey construct,
[`create_stackedbars()`](https://favstats.github.io/dashboardr/reference/create_stackedbars.md)
provides the flexibility and polish needed for both exploratory analysis
and publication-ready visualizations.
