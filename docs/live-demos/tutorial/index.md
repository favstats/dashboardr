# Welcome to the Tutorial Dashboard!

# Welcome to the Tutorial Dashboard!

Code

Welcome to the **Tutorial Dashboard**, providing insights into the
General Social Survey (GSS) data!

This dashboard demonstrates how to use the **dashboardr** package to
create beautiful, interactive dashboards using real survey data.

The tutorial is divided into main sections:

[Example
Dashboard](https://favstats.github.io/dashboardr/live-demos/tutorial/example_dashboard.md) -
Tabbed visualizations with stacked bars and heatmaps

[Standalone
Charts](https://favstats.github.io/dashboardr/live-demos/tutorial/standalone_charts.md) -
Charts without tabsets

[Text
Page](https://favstats.github.io/dashboardr/live-demos/tutorial/text_only_page.md) -
Text-only content example

[Showcase
Dashboard](https://favstats.github.io/dashboardr/live-demos/tutorial/showcase_dashboard.md) -
Full feature demonstration

Click on the hyperlinks above for quick navigation.

------------------------------------------------------------------------

## Dashboard File Structure

When you create a dashboard with dashboardr, the following files are
generated:

    tutorial_dashboard/
    ├── _quarto.yml
    ├── index.qmd
    ├── example_dashboard.qmd
    ├── standalone_charts.qmd
    ├── text_only_page.qmd
    └── showcase_dashboard.qmd

------------------------------------------------------------------------

## About the Data

This dashboard uses data from the **General Social Survey (GSS)**, a
nationally representative survey of adults in the United States
conducted since 1972. We explore patterns in:

- **Happiness** - Self-reported happiness levels
- **Trust** - Interpersonal trust measures
- **Political attitudes** - Party identification and ideological views

## Getting Started with dashboardr

Each visualization includes a collapsible **View R Code** section
showing exactly how it was created. Click the accordion to see the code
and link to full documentation.

View Full Dashboard Code

``` r
library(dashboardr)
library(dplyr)

# Load GSS data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  select(age_1a, sex_1a, degree_1a, region_1a,
         happy_1a, trust_1a, fair_1a, helpful_1a,
         polviews_1a, partyid_1a, class_1a) %>%
  filter(if_any(everything(), ~ !is.na(.)))

# Create visualizations
analysis_vizzes <- create_content() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a", stack_var = "happy_1a",
          title = "Happiness by Education",
          tabgroup = "demographics") %>%
  add_viz(type = "heatmap",
          x_var = "degree_1a", y_var = "age_1a", value_var = "trust_1a",
          title = "Trust by Education and Age",
          tabgroup = "social")

# Create dashboard
create_dashboard(
  output_dir = "my_dashboard",
  title = "My Dashboard",
  logo = "logo.png",
  theme = "flatly"
) %>%
  add_page(name = "Welcome", text = "Landing page content",
           icon = "ph:house", is_landing_page = TRUE) %>%
  add_page(name = "Analysis", data = gss_clean,
           content = analysis_vizzes, icon = "ph:chart-line") %>%
  generate_dashboard()
```

[View full tutorial_dashboard.R source
code](https://github.com/favstats/dashboardr/blob/main/R/tutorial_dashboard.R)

Back to top
