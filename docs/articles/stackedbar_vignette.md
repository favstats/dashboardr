# Creating Interactive Stacked Bar Charts with \`viz_stackedbar\`

### 📖 Introduction

Welcome to this comprehensive guide on using the `viz_stackedbar`
function from the `dashboardr` package. This unified function creates
highly customizable interactive stacked bar charts from survey data,
supporting two powerful modes:

**Mode 1: Grouped/Crosstab Mode** (use `x_var` + `stack_var`)

- Shows how one variable breaks down by another (e.g., education by
  gender)
- Use when your data is in long/tidy format
- Example:
  `viz_stackedbar(data, x_var = "education", stack_var = "gender")`

**Mode 2: Multi-Variable/Battery Mode** (use `x_vars`)

- Compares response distributions across multiple survey questions
- Use when you have multiple columns with the same response scale (e.g.,
  Likert items)
- Example: `viz_stackedbar(data, x_vars = c("q1", "q2", "q3"))`

The function handles many common data preparation tasks automatically,
including:

- Converting `haven_labelled` columns (from SPSS imports) to R factors
- Mapping raw values to descriptive labels
- Binning continuous variables into meaningful categories
- Handling missing values explicitly or implicitly
- Creating both count-based and percentage-based visualizations
- Customizing colors, ordering, and interactive tooltips

This vignette demonstrates both modes using the General Social Survey
(GSS) Panel 2020 dataset.

### ⚙️ Getting Started

First, let’s load the necessary libraries and examine our data set.

``` r
library(gssr)
library(dplyr)
library(highcharter)
library(tidyr)
library(dashboardr)

# Load GSS Panel 2020 data
data(gss_panel20)
```

### 📋 Data Preparation

Let’s prepare our working dataset using the 2020 wave variables.

``` r
# Create a working dataset with key _1a variables from 2020
gss_clean <- gss_panel20 %>%
  select(
    # Demographics
    age_1a, sex_1a, race_1a, degree_1a, region_1a,
    # Attitudes and behaviors
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, attend_1a,
    # Economic
    income_1a, class_1a
  ) %>%
  # Remove completely empty rows
  filter(if_any(everything(), ~ !is.na(.)))

# Check the data structure
glimpse(gss_clean)
#> Rows: 2,867
#> Columns: 14
#> $ age_1a      <dbl+lbl> 47, 61, 72, 43, 55, 53, 50, 23, 45, 71, 33, 86, 32, 60…
#> $ sex_1a      <dbl+lbl> 1, 1, 1, 2, 2, 2, 1, 2, 1, 1, 2, 2, 1, 2, 1, 2, 1, 2, …
#> $ race_1a     <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 2, 1, 2, 2, 1, 1, 1, 3, …
#> $ degree_1a   <dbl+lbl> 3, 1, 3, 1, 4, 2, 1, 1, 1, 2, 1, 1, 1, 1, 0, 1, 1, 0, …
#> $ region_1a   <dbl+lbl> 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, …
#> $ happy_1a    <dbl+lbl>     2,     2,     1,     2,     1,     1,     2,     1…
#> $ trust_1a    <dbl+lbl> NA(i),     3,     1, NA(i),     1,     1, NA(i),     2…
#> $ fair_1a     <dbl+lbl> NA(i),     1,     1, NA(i),     2,     2, NA(i),     1…
#> $ helpful_1a  <dbl+lbl> NA(i),     2,     2, NA(i),     3,     1, NA(i),     1…
#> $ polviews_1a <dbl+lbl>     4,     2,     6,     4,     3,     3,     3,     5…
#> $ partyid_1a  <dbl+lbl>     3,     2,     5,     5,     1,     1,     5,     2…
#> $ attend_1a   <dbl+lbl> 0, 0, 7, 6, 0, 0, 1, 5, 6, 0, 5, 3, 5, 6, 1, 8, 8, 8, …
#> $ income_1a   <dbl+lbl> NA(n),    12,    12, NA(n), NA(n),    12, NA(n),    12…
#> $ class_1a    <dbl+lbl>     3, NA(d),     3,     3,     3,     3,     3,     2…

# Examine some key variables
table(gss_clean$degree_1a, useNA = "always")
#> 
#>    0    1    2    3    4 <NA> 
#>  328 1461  216  536  318    8
table(gss_clean$happy_1a, useNA = "always")
#> 
#>    1    2    3 <NA> 
#>  806 1601  452    8
```

## 📊 Basic Stacked Bar Charts

### Example 1: Education by Gender (Count-based)

Let’s start with a basic stacked bar chart showing educational
attainment by gender.

``` r
# Create basic stacked bar chart
plot1 <- viz_stackedbar(
  data = gss_clean,
  x_var = "degree_1a",
  stack_var = "sex_1a",
  title = "Educational Attainment by Gender",
  subtitle = "GSS Panel 2016 - Raw counts",
  x_label = "Highest Degree Completed",
  y_label = "Number of Respondents",
  stack_label = "Gender",
  stacked_type = "counts"
)

plot1
```

### Example 2: Happiness Distribution (Percentage-based)

Now let’s create a percentage-based stacked bar chart to show happiness
distribution across education levels.

``` r
# Define education order for logical display
education_order <- c("less than high school", "high school", "associate/junior college", "bachelor's", "graduate")

# Create percentage stacked bar chart
plot2 <- viz_stackedbar(
  data = gss_clean,
  x_var = "degree_1a",
  stack_var = "happy_1a",
  title = "Happiness Distribution Across Education Levels",
  subtitle = "Percentage breakdown within each education category",
  x_label = "Education Level",
  y_label = "Percentage of Respondents",
  stack_label = "Happiness Level",
  stacked_type = "percent",
  x_order = education_order,
  stack_order = c("very happy", "pretty happy", "not too happy"),
  tooltip_suffix = "%",
  color_palette = c("#2E86AB", "#A23B72", "#F18F01")
)

plot2
```

## ⚡ Advanced Features

### Example 3: Age Binning with Political Views

Let’s demonstrate binning continuous variables by creating age groups
and examining political views.

``` r
# First, let's clean and prepare the age variable
gss_clean_age <- gss_clean %>%
  # Ensure age is numeric and remove missing values for this analysis
  filter(!is.na(age_1a), !is.na(polviews_1a)) %>%
  mutate(
    # Convert age to numeric if it isn't already
    age_numeric = as.numeric(age_1a)
  )

# Check the cleaned data
cat("Cleaned age summary:\n")
#> Cleaned age summary:
summary(gss_clean_age$age_numeric)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   18.00   34.00   50.00   49.26   62.00   89.00

# Define age breaks and labels (adjusted if needed based on actual data range)
age_range <- range(gss_clean_age$age_numeric, na.rm = TRUE)
cat("Age range in data:", age_range[1], "to", age_range[2], "\n")
#> Age range in data: 18 to 89
```

``` r
# Adjust breaks to match actual data range
age_breaks <- c(18, 30, 45, 60, 75, Inf)
age_labels <- c("18-29", "30-44", "45-59", "60-74", "75+")

# Map political views to shorter labels
polviews_map <- list(
  "extremely liberal" = "Ext. Liberal",
  "liberal" = "Liberal", 
  "slightly liberal" = "Sl. Liberal",
  "moderate, middle of the road" = "Moderate",
  "slightly conservative" = "Sl. Conservative",
  "conservative" = "Conservative",
  "extremely conservative" = "Ext. Conservative"
)

polviews_order <- list("Ext. Liberal", "Liberal", "Sl. Liberal",
                       "Moderate", "Sl. Conservative", "Conservative", 
                       "Ext. Conservative")



# Create chart with age binning and value mapping using the numeric age
plot3 <- viz_stackedbar(
  data = gss_clean_age,
  x_var = "age_numeric",  # Use the numeric version
  stack_var = "polviews_1a",
  title = "Political Views by Age Group",
  subtitle = "Distribution of political ideology across age cohorts",
  x_label = "Age Group",
  stack_label = "Political Views",
  x_breaks = age_breaks,
  x_bin_labels = age_labels,
  stack_map_values = polviews_map,
  stacked_type = "percent",
  tooltip_suffix = "%",
  x_tooltip_suffix = " years",
  color_palette = c("#d7191c", "#fdae61", "#fee08b", "#e6f598", "#abdda4", "#66c2a5", "#2b83ba"),
  stack_order = polviews_order
)

plot3
```

### Example 4: Including Missing Values

Let’s create a chart that explicitly shows missing data patterns.

``` r
## Example 4: Including Missing Values

# Let's create a chart that explicitly shows missing data patterns.

# Create chart including NA values (using default "(Missing)" labels)
plot4 <- viz_stackedbar(
  data = gss_clean,
  x_var = "race_1a",
  stack_var = "attend_1a",
  title = "Religious Attendance by Race/Ethnicity",
  subtitle = "Including non-responses as explicit categories",
  x_label = "Race/Ethnicity",
  stack_label = "Religious Attendance Frequency",
  include_na = TRUE,
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#8e0152", "#c51b7d", "#de77ae", "#f1b6da", "#fde0ef", 
                   "#e6f5d0", "#b8e186", "#7fbc41", "#4d9221", "#276419")
)

plot4
```

### Example 5: Custom Value Mapping

Let’s demonstrate comprehensive value mapping for cleaner labels.

``` r

# Create mappings for cleaner display
sex_map <- list("male" = "Men", "female" = "Women")
class_map <- list(
  "lower class" = "Lower",
  "working class" = "Working", 
  "middle class" = "Middle",
  "upper class" = "Upper"
)

# Create chart with custom mappings
plot5 <- viz_stackedbar(
  data = gss_panel20,
  x_var = "class_1a",
  stack_var = "sex_1a",
  title = "Gender Distribution Across Social Classes",
  subtitle = "With custom labels and ordering",
  x_label = "Self-Reported Social Class",
  stack_label = "Gender",
  x_map_values = class_map,
  stack_map_values = sex_map,
  x_order = c("Lower", "Working", "Middle", "Upper"),
  stack_order = c("Women", "Men"),
  stacked_type = "counts",
  tooltip_prefix = "Count: ",
  color_palette = c("#E07A5F", "#3D5A80")
)

plot5
```

## 🔬 Complex Analysis Examples

### Example 6: Regional Patterns in Trust

Let’s examine how trust levels vary across regions and social classes.

``` r

# Recode labels to fix the mistake
trust_map <- list(
  "can't trust" = "Can Trust",
  "can't be too careful" = "Can't Be Too Careful",
  "depends" = "It Depends"
)

# Create regional trust analysis
plot6 <- viz_stackedbar(
  data = gss_panel20,
  x_var = "region_1a",
  stack_var = "trust_1a",
  stack_map_values = trust_map,
  title = "Do You Trust Strangers?",
  subtitle = "Regional variation in interpersonal trust",
  x_label = "US Region",
  stack_label = "Trust Level",
  stack_order = c("Can Trust", "Can't Be Too Careful", "It Depends"),
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#2E8B57", "#CD5C5C", "#DAA520")
)

plot6
```

## 📊 Multi-Variable Mode: Comparing Survey Questions

The `viz_stackedbar` function also supports comparing multiple survey
questions side-by-side. This is particularly useful for visualizing
survey batteries (sets of questions with the same response scale).

### Example 7: Basic Multi-Variable Comparison

When you have multiple columns representing different questions with the
same response categories, use `x_vars` to compare them:

``` r
# Define the questions to compare
social_questions <- c("trust_1a", "fair_1a", "helpful_1a")
social_labels <- c(
  "Interpersonal Trust",
  "Fairness of Others",
  "Helpfulness of Others"
)

# Create multi-variable comparison chart
plot7 <- viz_stackedbar(
  data = gss_clean,
  x_vars = social_questions,
  x_var_labels = social_labels,
  title = "Social Attitudes and Trust",
  subtitle = "Distribution of responses across social attitude questions",
  x_label = "Social Attitude Dimension",
  stack_label = "Response Level",
  stacked_type = "percent",
  tooltip_suffix = "%"
)

plot7
```

### Example 8: Multi-Variable with Response Mapping

You can standardize response labels across questions and customize the
display. It’s helpful to first check what the actual response values
are:

``` r
# First, examine what the actual response values are
cat("Unique trust responses:\n")
#> Unique trust responses:
print(unique(as.character(gss_clean$trust_1a)))
#> [1] NA  "3" "1" "2"

cat("\nUnique fair responses:\n")
#> 
#> Unique fair responses:
print(unique(as.character(gss_clean$fair_1a)))
#> [1] NA  "1" "2" "3"
```

Now create a mapping to standardize the labels:

``` r
# Create response mapping for cleaner labels
response_map <- list(
  "can't trust" = "High Trust/Positive",
  "can't be too careful" = "Low Trust/Negative",
  "depends" = "Situational/Neutral",
  "would try to be fair" = "High Trust/Positive",
  "would take advantage of you" = "Low Trust/Negative",
  "try to be helpful" = "High Trust/Positive",
  "looking out for themselves" = "Low Trust/Negative"
)

# Define response order (from negative to positive)
response_order <- c("Low Trust/Negative", "Situational/Neutral", "High Trust/Positive")

# Create chart with custom mapping and ordering
plot8 <- viz_stackedbar(
  data = gss_clean,
  x_vars = social_questions,
  x_var_labels = social_labels,
  title = "Social Trust Dimensions with Standardized Responses",
  subtitle = "Responses mapped to consistent positive/negative categories",
  x_label = "Trust Dimension",
  stack_label = "Trust Level",
  stack_map_values = response_map,
  stack_order = response_order,
  stacked_type = "percent",
  tooltip_suffix = "%",
  color_palette = c("#d62728", "#ffbb78", "#2ca02c"),
  include_na = TRUE,
  na_label_stack = "No Answer"
)

plot8
```

### Example 9: Single Variable with x_vars (Compact Display)

The `x_vars` parameter also works with a single variable. This is useful
when you want the compact styling of multi-variable mode for a single
question:

``` r
# Single variable with x_vars - great for compact horizontal displays
plot9a <- viz_stackedbar(
  data = gss_clean,
  x_vars = "happy_1a",
  x_var_labels = "General Happiness",
  title = "Happiness Distribution",
  x_label = "Well-being Measure",
  stack_label = "Happiness Level",
  stacked_type = "percent",
  horizontal = TRUE,
  tooltip_suffix = "%",
  color_palette = c("#2E8B57", "#FFD700", "#CD5C5C", "grey")
)

plot9a
```

### Example 9b: Horizontal Multi-Variable Chart

For better readability with long labels, use horizontal orientation:

``` r
# Horizontal chart for survey battery
plot9b <- viz_stackedbar(
  data = gss_clean,
  x_vars = c("trust_1a", "fair_1a", "helpful_1a"),
  x_var_labels = c(
    "Can people be trusted?",
    "Are people generally fair?",
    "Are people generally helpful?"
  ),
  title = "Social Capital Dimensions",
  subtitle = "GSS Panel 2016",
  stacked_type = "percent",
  horizontal = TRUE,
  tooltip_suffix = "%",
  color_palette = c("#8c510a", "#d8b365", "#f6e8c3", "grey"),
  include_na = TRUE,
  na_label_stack = "No response"
)

plot9b
```

### Example 10: Survey Battery Analysis

Survey batteries are sets of related questions with the same response
scale. Here’s how to create a comprehensive battery analysis:

``` r
# Create a social trust battery
trust_battery <- c("trust_1a", "fair_1a", "helpful_1a")
trust_battery_labels <- c(
  "Interpersonal Trust",
  "Perceived Fairness",
  "Perceived Helpfulness"
)

# Create a comprehensive battery analysis
plot10 <- viz_stackedbar(
  data = gss_clean,
  x_vars = trust_battery,
  x_var_labels = trust_battery_labels,
  title = "Social Trust Battery - Complete Analysis",
  subtitle = "Comprehensive view of social trust dimensions with enhanced tooltips",
  x_label = "Trust Dimension",
  stack_label = "Response Category",
  stacked_type = "percent",
  tooltip_prefix = "Percentage: ",
  tooltip_suffix = "% of respondents",
  show_var_tooltip = TRUE,
  include_na = TRUE,
  na_label_stack = "No answer",
  color_palette = c("#8c510a", "#d8b365", "#f6e8c3", "darkgrey")
)

plot10
```

### Example 11: Publication-Ready Chart

Let’s create a fully customized, publication-ready chart:

``` r
# Create the most polished example
plot11 <- viz_stackedbar(
  data = gss_clean,
  x_vars = social_questions,
  x_var_labels = c(
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
  show_var_tooltip = TRUE
)

plot11
```

## 🏷️ Labels and Tooltips Reference

### Summary of Label and Tooltip Options

The
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
function offers extensive customization for labels and tooltips:

| Parameter | Description | Example |
|----|----|----|
| `x_label` | X-axis title | `"Question"` |
| `y_label` | Y-axis title (auto-set based on stacked_type) | `"Percentage"` |
| `stack_label` | Legend title | `"Response Category"` |
| `x_var_labels` | Custom labels for each question (multi-variable mode) | `c("Trust", "Fairness")` |
| `tooltip_prefix` | Text before value in tooltip | `"Score: "` |
| `tooltip_suffix` | Text after value in tooltip | `"%"`, `" respondents"` |
| `x_tooltip_suffix` | Text after category name in tooltip | `" question"` |
| `show_var_tooltip` | Show question name in tooltip (multi-variable mode) | `TRUE` |

``` r
# Example with all label/tooltip options
viz_stackedbar(
  data = gss_clean,
  x_vars = c("trust_1a", "fair_1a"),
  x_var_labels = c("Trust", "Fairness"),
  title = "Social Attitudes",
  x_label = "Attitude Measure",
  y_label = "Percent of Respondents",
  stack_label = "Response Level",
  stacked_type = "percent",
  tooltip_prefix = "",
  tooltip_suffix = "% responded",
  show_var_tooltip = TRUE
)
```

### When to Use Each Mode

| Mode | Use Case | Parameters |
|----|----|----|
| **Grouped/Crosstab** | One variable broken down by another | `x_var` + `stack_var` |
| **Multi-Variable** | Compare multiple questions side-by-side | `x_vars` |

**Use Grouped Mode when:** - You want to show how education levels
differ by gender - You’re creating a cross-tabulation visualization -
Your data is already in long/tidy format

**Use Multi-Variable Mode when:** - You’re comparing multiple survey
questions - Your questions share the same response categories - You want
to visualize a Likert scale battery

## 💡 Summary and Best Practices

### ✅ Key Features Demonstrated

1.  **Two flexible modes**: Grouped/crosstab (`x_var` + `stack_var`) and
    multi-variable (`x_vars`)
2.  **Basic stacked bars** with both count and percentage displays
3.  **Age binning** for continuous variables
4.  **Value mapping** for cleaner, more descriptive labels
5.  **Custom ordering** for logical presentation of categories
6.  **Missing value handling** with explicit NA categories
7.  **Multi-variable comparisons** for survey batteries and Likert
    scales
8.  **Custom color palettes** for different data types and branding
9.  **Comprehensive tooltips** with prefixes, suffixes, and formatting
10. **Horizontal orientation** for better readability with long labels

### 🎯 Best Practices for Stacked Bar Charts

#### General Guidelines

1.  Choose appropriate stacking type

- Use “normal” or “counts” for comparing absolute counts across groups
- Use “percent” for comparing proportions within groups

2.  Order categories logically

- When remapping values, remember to use the variable names as in the
  DataFrame
- Use natural ordering for ordinal variables (e.g., Likert scales)
- Consider frequency-based ordering for nominal categories
- Place “Other” or “Missing” categories at the end

#### Multi-Variable Mode Best Practices

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
- Use “counts” when absolute counts matter more than proportions

3.  Handle missing data thoughtfully

- Decide whether to include or exclude missing categories
- Use include_na = TRUE when missing patterns are meaningful
- Provide clear labels for missing categories

4.  Use appropriate colors

- Use diverging palettes for scales with meaningful center points
- Use qualitative palettes for nominal categories
- Ensure sufficient contrast between adjacent categories
- Consider colorblind accessibility

5.  Customize tooltips for clarity

- Include units and context in tooltips
- Use prefixes/suffixes to clarify meaning
- Format numbers appropriately for your audience

6.  Consider your audience

- Use descriptive labels rather than codes
- Provide clear titles and subtitles
- Include sample sizes in subtitles when relevant

### 🌍 Common Use Cases

The `viz_stackedbar` function is particularly useful for:

- **Survey response analysis**: Displaying Likert scale responses across
  demographics
- **Demographic breakdowns**: Showing composition of groups by various
  characteristics  
- **Attitude research**: Comparing opinions across different populations
- **Market research**: Analyzing customer segments and preferences
- **Educational research**: Examining outcomes across different groups
- **Health surveys**: Displaying health behaviors or outcomes by
  demographics

### 📚 Conclusion

The
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
function provides a unified, comprehensive solution for creating
publication-ready stacked bar charts from survey data. Its two flexible
modes handle the most common visualization needs:

- **Grouped/Crosstab Mode** (`x_var` + `stack_var`): Show how one
  variable breaks down by another
- **Multi-Variable Mode** (`x_vars`): Compare response distributions
  across multiple survey questions

Key advantages include:

- **Unified interface** - one function for both crosstabs and survey
  batteries
- **Automatic data preparation** for common survey data formats
- **Smart mode detection** based on the parameters you provide
- **Flexible binning and mapping** for continuous and coded variables
- **Comprehensive missing data handling** options
- **Interactive tooltips** for enhanced data exploration
- **Publication-ready styling** with extensive customization options

**Note:** If you were previously using
[`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md)
for multi-variable comparisons, you can now use
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
with the same parameters. The old function still works but
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
is now the recommended approach for all stacked bar chart needs.
