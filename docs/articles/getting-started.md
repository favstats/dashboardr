# Getting Started with dashboardr

This vignette walks you through building your first interactive
dashboard with dashboardr. By the end, you’ll understand the core
concepts and have a working dashboard you can customize.

## What is dashboardr?

dashboardr lets you build interactive HTML dashboards from R using a
simple, composable grammar. Think of it like building with Lego blocks:

- **No web development needed**: just R code
- **Interactive charts** powered by Highcharts
- **Beautiful themes** from Bootswatch
- **Flexible layouts** with tabs, pages, and navigation

## Installation

Install dashboardr from GitHub:

``` r
devtools::install_github("favstats/dashboardr")
```

## What We’ll Build

In this tutorial, we’ll create a dashboard exploring the General Social
Survey (GSS), a long-running survey of American attitudes and
demographics. We’ll build charts showing education levels, happiness,
and how they relate to each other.

First, let’s load the packages and prepare our data:

``` r
library(dashboardr)
library(dplyr)
library(gssr)
#> Warning: package 'gssr' was built under R version 4.4.3

# Load GSS data and select relevant variables
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year >= 2010, !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))
```

We now have a dataset with about 22,000 respondents from 2010 onwards,
with variables for demographics (age, sex, race, education) and
attitudes (happiness, political views).

## The Three Layers

Just as ggplot2 builds plots from layers (data, aesthetics, geoms),
dashboardr builds dashboards from three layers:

![Diagram showing the three layers: Content (visualizations, text) flows
into Page, and Pages flow into Dashboard.](workflow_example.png)

dashboardr workflow: Content flows to Page flows to Dashboard

| Layer | Purpose | Key Functions |
|----|----|----|
| **Content** | What to show (charts, text) | [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md), [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md), [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md) |
| **Page** | Where content lives | [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md), [`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md) |
| **Dashboard** | Final output + config | [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md), [`add_pages()`](https://favstats.github.io/dashboardr/reference/add_pages.md) |

Each layer flows into the next using pipes (`%>%`), making your code
readable and modular.

## Layer 1: Content

Content collections hold your visualizations and text. You create one
with
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md),
passing the data and a default chart type:

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") 

print(demographics)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 1 items | ✔ data: 21788 rows x 7 cols
#> 
#> • [Viz] Education (bar) x=degree
```

Here
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
sets up a container with the GSS data and says “make bar charts by
default.” Then
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
adds a bar chart of the `degree` variable. The print output shows what’s
inside: one visualization ready to go.

Use
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
to see the actual chart. Note this might differ slightly from how
content will eventually look like in your dashboard as it creates a
simple preview of your data.

``` r
demographics %>% preview()
```

Preview

Education

You can keep adding to content collections. Use `tabgroup` to organize
charts into tabs:

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "demographics") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes")

demographics %>% preview()
```

Preview

demographics

attitudes

Education

Race

Happiness

## Layer 2: Pages

Pages organize content and define your dashboard’s navigation. Each page
becomes a separate HTML file.

A simple landing page with just text:

``` r
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Welcome!", "", "Explore the General Social Survey data.")

home %>% preview()
```

Preview

Welcome!

Explore the General Social Survey data.

The `is_landing_page = TRUE` makes this the default page when someone
opens your dashboard.

Now an analysis page that uses our content from Layer 1. You can also
add text directly to pages:

``` r
analysis <- create_page("Analysis", data = gss) %>%
  add_text("## Demographic Overview", "Explore how GSS respondents break down by key categories.") %>%
  add_content(demographics)

print(analysis)
#> -- Page: Analysis ───────────────────────────────────────────────
#> ✔ data: 21788 rows x 7 cols 
#> 4 items
#> 
#> ℹ [Text]
#> ❯ [Tab] demographics (2 vizs)
#>   • [Viz] Education (bar) x=degree
#>   • [Viz] Race (bar) x=race
#> ❯ [Tab] attitudes (1 viz)
#>   • [Viz] Happiness (bar) x=happy
```

The
[`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md)
function connects layers: it takes the content collection you built
earlier and attaches it to the page. The page’s `data` argument provides
the dataset for any visualizations that need it.

``` r
analysis %>% preview()
```

Preview

Demographic Overview

Explore how GSS respondents break down by key categories.

demographics

attitudes

Education

Race

Happiness

You can also add visualizations directly to pages without creating a
separate content collection first:

``` r
quick_page <- create_page("Quick", data = gss, type = "bar") %>%
  add_text("## Quick Analysis") %>%
  add_viz(x_var = "happy", title = "Happiness Levels")

quick_page %>% preview()
```

Preview

Quick Analysis

Happiness Levels

## Layer 3: Dashboard

The dashboard brings pages together and configures the final output. You
specify where to save files, pick a theme, and add your pages:

``` r
my_dashboard <- create_dashboard(
  title = "GSS Explorer", 
  output_dir = "my_dashboard",
  theme = "flatly"
) %>%
  add_pages(home, analysis) 

my_dashboard
```

Dashboard Preview: GSS Explorer

Home

Analysis

Welcome!

Explore the General Social Survey data.

Demographic Overview

Explore how GSS respondents break down by key categories.

demographics

attitudes

Education

Race

Happiness

Pages appear in the navbar in the order you add them.

To generate the final HTML dashboard:

``` r
my_dashboard %>%
  generate_dashboard(render = TRUE, open = "browser")
```

This creates Quarto files, renders them to HTML, and opens the result in
your browser.

You can also preview dashboards without generating everything with
Quarto:

``` r
my_dashboard %>% preview()
```

Dashboard Preview: GSS Explorer

Home

Analysis

Welcome!

Explore the General Social Survey data.

Demographic Overview

Explore how GSS respondents break down by key categories.

demographics

attitudes

Education

Race

Happiness

## Complete Example

Here’s everything together, from data to published dashboard:

``` r
library(dashboardr)
library(dplyr)
library(gssr)

# Prepare data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year >= 2010, !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))

# LAYER 1: Build content collections
demographics <- create_content(type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "overview") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "overview") %>%
  add_viz(x_var = "sex", title = "Gender", tabgroup = "overview")

cross_tabs <- create_content(type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", 
          title = "Happiness by Education", tabgroup = "analysis", 
          stacked_type = "percent") %>%
  add_viz(x_var = "polviews", stack_var = "happy",
          title = "Happiness by Politics", tabgroup = "analysis",
          stacked_type = "percent")

# LAYER 2: Create pages
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# GSS Explorer", "", 
           "Explore trends in American society using the General Social Survey.",
           "", "Navigate using the tabs above.")

analysis <- create_page("Analysis", data = gss, icon = "ph:chart-bar") %>%
  add_content(demographics) %>%
  add_content(cross_tabs)

about <- create_page("About", navbar_align = "right", icon = "ph:info") %>%
  add_text("## About This Dashboard", "",
           "Created with dashboardr. Data from the GSS (2010-2024).")

# LAYER 3: Assemble and generate
onemin_dashboard <- create_dashboard(
  title = "GSS Data Explorer",
  output_dir = "gss_dashboard",
  theme = "flatly",
  search = TRUE
) %>%
  add_pages(home, analysis, about) 

onemin_dashboard %>% 
  generate_dashboard(render = TRUE, open = "browser")
```

Here’s what the *one minute* dashboard structure looks like:

``` r
print(onemin_dashboard)
#> 
#> +==============================================================================
#> | [*] DASHBOARD PROJECT
#> +==============================================================================
#> | [T] Title: GSS Data Explorer
#> | [>] Output: /Users/favstats/Dropbox/postdoc/gss_dashboard
#> |
#> | [+] FEATURES:
#> |    * [?] Search
#> |    * [#] Theme: flatly
#> |    * [~] Tabs: minimal
#> |
#> | [P] PAGES (3):
#> | +- [P] Home [[H] Landing]
#> | +- [P] Analysis [[i] Icon, [d] 1 dataset]
#> | +- [P] About [[i] Icon, -> Right]
#> +==============================================================================
```

## Tips

1.  **Print often**: use [`print()`](https://rdrr.io/r/base/print.html)
    to inspect structure before generating
2.  **Preview as you go**: use
    [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
    to see charts without building everything
3.  **Start simple**: build one page first, then expand
4.  **Use tabgroups**: they make complex dashboards navigable
5.  **Build content separately**: create reusable collections, attach to
    multiple pages

## Learn More

| Topic | Vignette |
|----|----|
| All visualization types, tabgroups, filtering | [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) |
| Page options, icons, performance settings | [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) |
| Themes, navigation, navbar customization | [`vignette("dashboards")`](https://favstats.github.io/dashboardr/articles/dashboards.md) |
| Icons, debugging, advanced tips | [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) |
