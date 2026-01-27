# Getting Started with dashboardr

This vignette walks you through building your first interactive
dashboard with dashboardr. By the end, you’ll understand the core
concepts and have a working dashboard you can customize.

## 📦 What is dashboardr?

dashboardr lets you build *interactive HTML dashboards* from R using a
simple, composable grammar.

## 📥 Installation

Install dashboardr from GitHub:

``` r
devtools::install_github("favstats/dashboardr")
```

## 🏗️ What We’ll Build

To showcase what `dashboardr` can do, we’ll create a dashboard exploring
the [General Social Survey (GSS)](https://kjhealy.github.io/gssr/), a
long-running survey of American attitudes and demographics. We’ll build
charts showing education levels, happiness, and how they relate to each
other.

First, let’s load the packages and prepare our data:

``` r
library(dashboardr)
library(dplyr)
library(gssr)

# Load GSS data and select relevant variables (latest wave only)
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE), !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))
```

We now have a dataset with about 3139 respondents from 2024 onwards,
with variables for demographics (age, sex, race, education) and
attitudes (happiness, political views).

## 🧱 Core Concepts

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

  

### Layer 1: Content

Content collections hold your visualizations, text, and more (iframes,
custom HTML). You create one with
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md),
passing the data and a default chart type:

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") 

print(demographics)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 1 items | ✔ data: 3139 rows x 7 cols
#> 
#> • [Viz] Education (bar) x=degree
```

Here
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
sets up a container with the GSS data (`data = gss`) and says “make bar
charts by default” (`type = "bar"`). Then
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
adds a bar chart of the `degree` variable. The print output shows what’s
inside: one visualization ready to go.

Use
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
to see the actual chart. Note this differs from how content will
eventually look like in your dashboard as it creates a simple preview of
your data.

``` r
demographics %>% preview()
```

Preview

Education

You can keep adding to content collections. Use `tabgroup` to organize
charts into tabs. The code below will crate two tabs, one titled
“Demographics” and one titled “Attitudes”.

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Attitudes")

demographics %>% preview()
```

Preview

Demographics

Attitudes

Education

Happiness

### Layer 2: Pages

Pages organize content and define your dashboard’s *navigation*. Each
page becomes a separate HTML file.

Let’s create something every dashboard needs: a simple landing page:

``` r
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text(
    "# Welcome!", 
    "", 
    "Explore the General Social Survey data.")

home %>% preview()
```

Preview

Welcome!

Explore the General Social Survey data.

With `add_text` you can just provide a series of markdown code! A `""`
marks a linebreak. The `is_landing_page = TRUE` makes this the default
page when someone opens your dashboard.

Now an analysis page that uses our content from Layer 1. If you like you
can *also* `add_text` directly to pages:

``` r
analysis <- create_page("Analysis", data = gss) %>%
  add_text("## Demographic Overview", "Explore how GSS respondents break down by key categories.") %>%
  add_content(demographics)

print(analysis)
#> -- Page: Analysis ───────────────────────────────────────────────
#> ✔ data: 3139 rows x 7 cols 
#> 3 items
#> 
#> ℹ [Text]
#> ❯ [Tab] Demographics (1 viz)
#>   • [Viz] Education (bar) x=degree
#> ❯ [Tab] Attitudes (1 viz)
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

Demographics

Attitudes

Education

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

### Layer 3: Dashboard

The dashboard brings pages together and configures the final output. You
specify where to save files, pick a theme, and add your pages:

``` r
my_dashboard <- create_dashboard(
  title = "GSS Explorer", 
  output_dir = "my_dashboard",
  theme = "cosmo"
) %>%
  add_pages(home, analysis) 

print(my_dashboard)
#> 
#> 📊 DASHBOARD PROJECT ====================================================
#> │ 🏷️  Title: GSS Explorer
#> │ 📁 Output: /Users/favstats/Dropbox/postdoc/my_dashboard
#> │
#> │ ⚙️  FEATURES:
#> │    • 🔍 Search
#> │    • 🎨 Theme: cosmo
#> │    • 📑 Tabs: minimal
#> │
#> │ 📄 PAGES (2):
#> │ ├─ 📄 Home [🏠 Landing]
#> │ └─ 📄 Analysis [💾 1 dataset]
#> ══ ═════════════════════════════════════════════════════════════════════════
```

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

Demographics

Attitudes

Education

Happiness

## ⚡ Your first Dashboard in 1 Minute

Here’s everything together, from data to published dashboard. Just copy
paste, run it, and you will have your first dashboard:

``` r
library(dashboardr)
library(dplyr)
library(gssr)

# Prepare data (latest wave only)
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE), !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))

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
#> 📊 DASHBOARD PROJECT ====================================================
#> │ 🏷️  Title: GSS Data Explorer
#> │ 📁 Output: /Users/favstats/Dropbox/postdoc/gss_dashboard
#> │
#> │ ⚙️  FEATURES:
#> │    • 🔍 Search
#> │    • 🎨 Theme: flatly
#> │    • 📑 Tabs: minimal
#> │
#> │ 📄 PAGES (3):
#> │ ├─ 📄 Home [🏠 Landing]
#> │ ├─ 📄 Analysis [🏷️ Icon, 💾 1 dataset]
#> │ └─ 📄 About [🏷️ Icon, ➡️ Right]
#> ══ ═════════════════════════════════════════════════════════════════════════
```

``` r
preview(onemin_dashboard)
```

Dashboard Preview: GSS Data Explorer

Home

Analysis

About

GSS Explorer

Explore trends in American society using the General Social Survey.

Navigate using the tabs above.

overview

analysis

About This Dashboard

Created with dashboardr. Data from the GSS (2010-2024).

## 💡 Tips

1.  **Print often**: use [`print()`](https://rdrr.io/r/base/print.html)
    to inspect structure before generating
2.  **Preview as you go**: use
    [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
    to see charts without building everything
3.  **Start simple**: build one piece of content first, then the page,
    then expand
4.  **Use tabgroups**: they make complex dashboards navigable
5.  **Build content separately**: create reusable collections, attach to
    multiple pages

## 🔧 Function Overview

dashboardr uses consistent naming conventions so you always know what a
function does:

| Prefix | Purpose | Examples |
|----|----|----|
| `create_*` | **Create containers** - Start a new dashboard, page, or content collection that holds other elements | [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md), [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md), [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md) |
| `add_*` | **Add to containers** - Insert visualizations, text, pages, or other content into an existing object | [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md), [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md), [`add_page()`](https://favstats.github.io/dashboardr/reference/add_page.md), [`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md), [`add_callout()`](https://favstats.github.io/dashboardr/reference/add_callout.md) |
| `viz_*` | **Build visualizations** - Create individual charts directly (histogram, bar, timeline, etc.) | [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md), [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md), [`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md), [`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md) |
| `set_*` | **Modify properties** - Change settings on an existing object, like custom tab labels | [`set_tabgroup_labels()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md) |
| `generate_*` | **Produce output** - Create the final Quarto files and optionally render to HTML | [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md) |
| `theme_*` | **Apply styling** - Set visual themes for colors, fonts, and overall appearance | [`theme_modern()`](https://favstats.github.io/dashboardr/reference/theme_modern.md), [`theme_clean()`](https://favstats.github.io/dashboardr/reference/theme_clean.md), [`theme_academic()`](https://favstats.github.io/dashboardr/reference/theme_academic.md) |
| `combine_*` | **Merge collections** - Join multiple content or viz collections into one | [`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md), [`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md) |
| [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md) | **Quick look** - See how content, pages, or dashboards will look without generating files | [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md) |

### The Typical Pattern

Most dashboardr code follows this pattern:

``` r
# 1. CREATE a container
create_content(data = my_data, type = "bar") %>%
  # 2. ADD elements to it
  add_viz(x_var = "category", title = "My Chart") %>%
  add_text("## Summary", "Key findings here.")
```

The container functions (`create_*`) start the chain, then `add_*`
functions build it up. This works at every layer:

- **Content**: `create_content() %>% add_viz() %>% add_text()`
- **Page**: `create_page() %>% add_content() %>% add_viz()`
- **Dashboard**:
  `create_dashboard() %>% add_pages() %>% generate_dashboard()`

## 📚 Learn More

| Topic | Vignette |
|----|----|
| All visualization types, tabgroups, filtering | [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) |
| Page options, icons, performance settings | [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) |
| Themes, navigation, navbar customization | [`vignette("dashboards")`](https://favstats.github.io/dashboardr/articles/dashboards.md) |
| Icons, debugging, advanced tips | [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) |
