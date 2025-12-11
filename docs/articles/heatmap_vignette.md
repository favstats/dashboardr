# Creating Interactive Heatmaps with \`create_heatmap\`

### Introduction

Welcome to this guide on how to use the `create_heatmap` function as
part of the `dashboardr` package. This guide demonstrates how to use
this function to generate interactive heatmaps. In this demonstration,
we will use the `gss_2020` dataset from the `gssr` package to walk you
through how to use the function.

The `create_heatmap` function is designed to simplify the creation of
highly customizable heatmaps from raw or aggregated data. Heatmaps are
excellent for visualizing the relationship between two categorical
variables and a continuous outcome, using color intensity to represent
values. This function was designed to aid communication science
researchers, and other social science researchers, to visualize data
formats common in this line of work, namely, survey data.

It handles common data preparation steps such as:

- Converting `haven_labelled` columns (e.g., from SPSS imports) to R
  factors.
- Mapping raw values to more descriptive labels.
- Ordering categorical levels.
- Explicitly including or excluding `NA` values as distinct categories.
- Aggregating `value_var` if multiple observations exist for a given
  `(x, y)` cell.
- Setting up titles, labels, tooltips, and color scales.

This vignette demonstrates how to use the
[`create_heatmap()`](https://favstats.github.io/dashboardr/reference/create_heatmap.md)
function with the General Social Survey (GSS) Panel 2020 dataset. The
GSS Panel 2020 dataset follows the same respondents across three waves
(2016, 2018, 2020), providing rich longitudinal data for understanding
social attitudes and demographic patterns.

### Getting Started

First, let’s load the necessary libraries and the `gss_2020` dataset.

``` r
library(gssr)
library(dplyr)
library(highcharter)
library(tidyr)
library(dashboardr)

# Load GSS Panel 2020 data
data(gss_panel20)
```

### Data Preparation

With any data analysis, the first step is to examine the data (namely,
the variables) that we’re working with.

Once we have an idea of what the data looks like, we then need to
prepare our data by creating some meaningful categorical variables.

To keep it straightforward, we’re going to work with the first wave of
data, demarcated by the ‘\_1a’ suffix.

Let’s do so now:

``` r
# Check available _1a variables
wave_1a_vars <- names(gss_panel20)[grepl("_1a$", names(gss_panel20))]
cat("Available _1a variables:\n")
#> Available _1a variables:
print(wave_1a_vars[1:20])  # Show first 20
#>  [1] "wtssall_1a" "wtssnr_1a"  "vstrat_1a"  "vpsu_1a"    "year_1a"   
#>  [6] "id_1a"      "mar1_1a"    "mar2_1a"    "mar3_1a"    "mar4_1a"   
#> [11] "mar5_1a"    "mar6_1a"    "mar7_1a"    "mar8_1a"    "mar9_1a"   
#> [16] "mar10_1a"   "mar11_1a"   "mar12_1a"   "mar13_1a"   "mar14_1a"

# Create a working dataset with key _1a variables
gss_clean <- gss_panel20 %>%
  # Select relevant variables from wave 1a (2016)
  select(
    # Demographics
    age_1a, sex_1a, race_1a, degree_1a, region_1a,
    # Attitudes
    happy_1a, trust_1a, fair_1a, helpful_1a,
    # Economic
    income_1a, class_1a,
    # Political
    polviews_1a, partyid_1a
  ) %>%
  # Remove rows where all key variables are missing
  filter(!is.na(age_1a) | !is.na(sex_1a) | !is.na(race_1a)) %>%
  # Create age groups
  mutate(
    age_group = case_when(
      age_1a >= 18 & age_1a <= 29 ~ "18-29",
      age_1a >= 30 & age_1a <= 44 ~ "30-44", 
      age_1a >= 45 & age_1a <= 59 ~ "45-59",
      age_1a >= 60 & age_1a <= 74 ~ "60-74",
      age_1a >= 75 ~ "75+",
      TRUE ~ NA_character_
    ),
    # Create income groups
    income_group = case_when(
      as.numeric(income_1a) <= 3 ~ "Low",
      as.numeric(income_1a) <= 6 ~ "Middle-Low",
      as.numeric(income_1a) <= 9 ~ "Middle",
      as.numeric(income_1a) <= 12 ~ "Middle-High", 
      as.numeric(income_1a) > 12 ~ "High",
      TRUE ~ NA_character_
    )
  )

# Check our created variables
table(gss_clean$age_group, useNA = "always")
#> 
#> 18-29 30-44 45-59 60-74   75+  <NA> 
#>   481   737   780   598   261    10
table(gss_clean$income_group, useNA = "always")
#> 
#>         Low      Middle Middle-High  Middle-Low        <NA> 
#>         100         229        2055          49         434
```

## Basic Heatmap Examples

### Example 1: Average Age by Education and Gender

Let’s create a heatmap showing the average age across education levels
and gender.

``` r

# Prepare data for heatmap
age_education_data <- gss_clean %>%
  filter(!is.na(degree_1a), !is.na(sex_1a), !is.na(age_1a)) %>%
  group_by(degree_1a, sex_1a) %>%
  summarise(avg_age = mean(age_1a, na.rm = TRUE), .groups = 'drop')

# Recode Variables
sex_map <- list("1" = "Male",
                "2" = "Female")

edu_map = list("0" = "High School or Less",
               "1" =  "High School",
               "2" = "Associate/Junior College",
               "3" = "Bachelor's",
               "4" = "Master's or Higher")

# Create basic heatmap
plot1 <- create_heatmap(
  data = age_education_data,
  x_var = "degree_1a",
  y_var = "sex_1a", 
  value_var = "avg_age",
  y_map_values = sex_map,
  x_map_values = edu_map,
  title = "Average Age by Education Level and Gender",
  subtitle = "GSS Panel 2016 Wave",
  x_label = "Education Level",
  y_label = "Gender",
  value_label = "Average Age",
  color_palette = c("#ffffff", "#2E86AB")
)

plot1
```

### Example 2: Income Distribution with Custom Ordering

Let’s examine the relationship between age groups and education, showing
average income.

``` r

# Prepare income data
income_data <- gss_clean %>%
  filter(!is.na(age_group), !is.na(degree_1a), !is.na(income_1a)) %>%
  group_by(age_group, degree_1a) %>%
  summarise(avg_income = mean(as.numeric(income_1a), na.rm = TRUE), .groups = 'drop')

# Recode Variables
edu_map = list("0" = "High School or Less",
               "1" =  "High School",
               "2" = "Associate/Junior College",
               "3" = "Bachelor's",
               "4" = "Master's or Higher")

# Define custom orders
age_order <- c("18-29", "30-44", "45-59", "60-74", "75+")
education_order <- c("High School or Less", "High School", "Associate/Junior College", "Bachelor's", "Master's or Higher")

# Create heatmap with custom ordering
plot2 <- create_heatmap(
  data = income_data,
  x_var = "age_group",
  y_var = "degree_1a",
  y_map_values = edu_map,
  value_var = "avg_income",
  title = "Average Income by Age Group and Education",
  subtitle = "Higher values indicate higher income categories (2016)",
  x_label = "Age Group",
  y_label = "Education Level", 
  value_label = "Income Level",
  x_order = age_order,
  y_order = education_order,
  color_palette = c("#fff7ec", "#fee8c8", "#fdd49e", "#fdbb84", "#fc8d59", "#ef6548", "#d7301f"),
  x_tooltip_suffix = " years old",
  tooltip_labels_format = "{point.value:.1f}"
)

plot2
```

## Advanced Heatmap Features

### Example 3: Including Missing Values

Let’s create a heatmap that explicitly shows missing data patterns.

``` r

# Create data with some missing values for demonstration
happiness_data <- gss_clean %>%
  # Keep some NAs to demonstrate include_na feature
  group_by(race_1a, class_1a) %>%
  summarise(
    avg_happy = mean(as.numeric(happy_1a), na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  # Convert NaN to NA for demonstration
  mutate(avg_happy = ifelse(is.nan(avg_happy), NA, avg_happy))

race_map <- list("1" = "White",
                 "2" = "Black",
                 "3" = "Other"
  
)

class_map <- list("1"="Lower Class",
     "2" = "Working Class",
     "3" = "Middle Class",
     "4"="Upper Class")

# Create heatmap including NAs
plot3 <- create_heatmap(
  data = happiness_data,
  x_var = "race_1a",
  x_map_values = race_map,
  y_var = "class_1a",
  y_map_values = class_map,
  value_var = "avg_happy",
  title = "Average Happiness by Race and Social Class",
  subtitle = "Including missing data patterns (2016)",
  x_label = "Race/Ethnicity",
  y_label = "Social Class",
  value_label = "Happiness Level",
  include_na = TRUE,
  na_label_x = "Race Not Specified",
  na_label_y = "Class Not Specified", 
  na_color = "#cccccc",
  color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
  tooltip_prefix = "Happiness: ",
  tooltip_suffix = " (1-3 scale)"
)

plot3
```

### Example 4: Regional Analysis with Custom Colors

Let’s examine regional patterns in social attitudes.

``` r
# Map Values
edu_map = list("0" = "High School or Less",
               "1" =  "High School",
               "2" = "Associate/Junior College",
               "3" = "Bachelor's",
               "4" = "Master's or Higher")

region_map <- list("1" = "New England",
                   "2" = "Mid-Atlantic",
                   "3" = "East North Central",
                   "4" = "West North Central",
                   "5" = "South Atlantic",
                   "6" = "Deep South",
                   "7" = "West South Central",
                   "8" = "Mountain",
                   "9" = "West Coast"
  
)

# Create heatmap with custom styling
plot5 <- create_heatmap(
  data = gss_panel20,
  x_var = "region_1a", 
  y_var = "degree_1a",
  y_map_values = edu_map,
  x_map_values = region_map,
  value_var = "fair_1a",
  title = "Perceived Fairness by Region and Education",
  x_label = "US Region",
  y_label = "Education Level",
  value_label = "Fairness Rating",
  #y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
  color_palette = c("#ffffcc", "#a1dab4", "#41b6c4", "#2c7fb8", "#253494"),
  na_color = "#f0f0f0",
  tooltip_suffix = " (1-3 scale)",
  x_tooltip_prefix = "Region: ",
  y_tooltip_prefix = "Education: ",
  tooltip_labels_format = "{point.value:.2f}"
)

plot5
```

## Summary and Best Practices

### Key Features Demonstrated

1.  **Basic heatmaps** with continuous values mapped to color intensity
2.  **Custom ordering** of categorical variables for logical
    presentation
3.  **Missing value handling** with explicit NA categories and custom
    colors
4.  **Value mapping** for cleaner, more readable labels
5.  **Custom color palettes** for different data types and emphasis
6.  **Flexible aggregation** using different functions (mean, median)
7.  **Longitudinal analysis** showing change over time

### Best Practices for Heatmaps

``` r
# 1. Always check your data structure first!
glimpse(your_data)
table(your_data$x_var, your_data$y_var, useNA = "always")

# 2. Consider your audience when choosing colors
# - Use diverging palettes for data with meaningful zero/center point
# - Use sequential palettes for data with natural ordering
# - Ensure accessibility with colorblind-friendly palettes

# 3. Handle missing data thoughtfully
# - Decide whether to include or exclude missing categories
# - Use appropriate colors for missing data (often gray or transparent)
# - Document missing data patterns in subtitles

# 4. Order categories logically
# - Use natural ordering (e.g., age groups, education levels)
# - Consider frequency-based ordering for nominal categories
# - Place "Other" or "Missing" categories at the end

# 5. Customize tooltips for clarity
# - Include units and context
# - Use prefixes/suffixes to clarify meaning
# - Format numbers appropriately for your audience
```

### Conclusion

The
[`create_heatmap()`](https://favstats.github.io/dashboardr/reference/create_heatmap.md)
function provides a powerful and flexible way to visualize bivariate
relationships in survey data. By leveraging the rich GSS Panel 2020
dataset, we’ve demonstrated how heatmaps can reveal patterns in:

- Demographic distributions
- Attitude variations across groups  
- Regional and temporal patterns
- Missing data structures

The function’s extensive customization options allow for
publication-ready visualizations that can effectively communicate
complex social science findings to diverse audiences.
