# Overview

# Overview

Code

# General Social Survey 2020

Exploring happiness, trust, and social attitudes across America.

View Full Dashboard Code

``` r
library(dashboardr)
library(gssr)
library(dplyr)

# Load and prepare GSS data
data(gss_all)
gss_clean <- gss_all %>%
  filter(year >= 2010) %>%
  mutate(
    sex = haven::as_factor(sex),
    degree = haven::as_factor(degree),
    happy = haven::as_factor(happy),
    region = haven::as_factor(region),
    polviews = haven::as_factor(polviews),
    partyid = haven::as_factor(partyid)
  ) %>%
  filter(!is.na(age), !is.na(sex), !is.na(degree))

# Create visualizations with nested tabsets
analysis_vizzes <- create_content() %>%
  add_viz(type = "stackedbar",
          x_var = "degree", stack_var = "happy",
          title = "Happiness by Education",
          tabgroup = "happiness") %>%
  add_viz(type = "boxplot",
          x_var = "happy", y_var = "age",
          title = "Age by Happiness",
          tabgroup = "happiness") %>%
  add_viz(type = "histogram",
          x_var = "age",
          title = "Age Distribution",
          tabgroup = "age")

# Create dashboard with value boxes
dashboard <- create_dashboard(
  output_dir = "showcase_dashboard",
  title = "GSS Data Explorer",
  theme = "flatly"
) %>%
  add_page(
    name = "Overview",
    content = create_content() %>%
      add_value_box_row() %>%
        add_value_box(title = "Respondents", value = "2,849") %>%
        add_value_box(title = "Very Happy", value = "32%") %>%
      end_value_box_row(),
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Demographics",
    data = gss_clean,
    content = analysis_vizzes
  )

# Generate
generate_dashboard(dashboard)
```

[View full showcase_dashboard source
code](https://github.com/favstats/dashboardr/blob/main/R/tutorial_dashboard.R)

N

Total Respondents

2,849

Very Happy

32%

Trust Others

34%

College Educated

28%

Regions

9

Survey Year

2020

------------------------------------------------------------------------

## Quick Navigation

[Demographics](https://favstats.github.io/dashboardr/live-demos/showcase/demographics.md) -
Explore happiness and wellbeing by demographic groups

[Trust & Social
Capital](https://favstats.github.io/dashboardr/live-demos/showcase/trust___social_capital.md) -
Filter and explore trust patterns across regions

[Political
Attitudes](https://favstats.github.io/dashboardr/live-demos/showcase/political_attitudes.md) -
Party identification and ideology breakdowns

[About](https://favstats.github.io/dashboardr/live-demos/showcase/about.md) -
Data sources and methodology

Back to top
