# Pages: Deep Dive

This vignette covers **pages** - the second layer of dashboardr’s
architecture. For a quick overview, see
[`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md).

Throughout this vignette, we use the [General Social Survey
(GSS)](https://gssr.io/) as example data. Click below to see the data
loading code.

📦 **Data Loading Code** (click to expand)

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load latest wave only
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  # Filter to substantive responses (removes "don't know", "no answer", etc.)
  filter(
    happy %in% 1:3,        # very happy, pretty happy, not too happy
    polviews %in% 1:7,     # extremely liberal to extremely conservative
    !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)
  ) %>%
  mutate(
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race)),
    degree = droplevels(as_factor(degree)),
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews))
  )
```

## 📄 What is create_page()?

The
[`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md)
function creates a **page object** - a named destination in your
dashboard that users can navigate to. Every dashboard needs at least one
page: the landing page.

``` r
# Create a simple page
my_page <- create_page(
  name = "Home",
  data = gss,
  type = "bar"
)

print(my_page)
#> -- Page: Home ---------------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 
#> No content added yet
#>   Tip: Use add_viz(), add_text(), or add_content()
```

Pages can hold all the same content as
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
(visualizations, text, callouts, etc.), but they also carry **page-level
metadata** like the page name, icon, and navbar position.

### 🆚 create_page() vs create_content()

Both functions create containers for visualizations and content, but
they serve different purposes:

|  | [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md) | [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md) |
|----|----|----|
| **Purpose** | Build reusable content blocks | Create a dashboard page |
| **Page metadata** | No | Yes (icons, navbar position, overlays) |
| **Data defaults** | Yes | Yes |
| **Use with [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)** | Must be added to a page first | Can be added directly |

**Think of it this way:**

- [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
  = building blocks (reusable pieces)
- [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md)
  = the destination (what users navigate to)

## 🔀 Two Workflows

### Workflow 1: Simple Dashboards (Direct)

For straightforward dashboards, add content directly to pages:

``` r
# Everything in one chain
simple_page <- create_page("Analysis", data = gss, type = "bar") %>%
  add_text("## Education Distribution", "", "How education levels are distributed.") %>%
  add_viz(x_var = "degree", title = "Education Levels",
          x_label = "", y_label = "Respondents",
          color_palette = c("#3498DB")) %>%
  add_callout("Data from GSS 2022", type = "note")

print(simple_page)
#> -- Page: Analysis -----------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 3 items
#> 
#> i [Text]
#> * [Viz] Education Levels (bar) x=degree
#> ! [Callout]
```

``` r
simple_page %>% preview()
```

Preview

Education Distribution

How education levels are distributed.

Education Levels

**NOTE**

Data from GSS 2022

**When to use:** Quick dashboards, single-topic pages, prototyping.

### Workflow 2: Complex Dashboards (Modular)

For complex dashboards, build content separately, then assemble with
[`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md):

``` r
# Step 1: Build content pieces separately
intro_text <- create_content() %>%
  add_text("## Overview", "", "Key findings from the General Social Survey.")

demographic_charts <- create_content(type = "bar", y_label = "Count") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "Demographics",
          color_palette = c("#3498DB", "#E74C3C", "#27AE60"))

attitude_charts <- create_content(type = "bar", y_label = "Count") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Attitudes",
          color_palette = c("#27AE60", "#F39C12", "#E74C3C")) %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Attitudes")

# Step 2: Assemble into page
complex_page <- create_page("Full Analysis", data = gss) %>%
  add_content(intro_text) %>%
  add_content(demographic_charts) %>%
  add_content(attitude_charts)

print(complex_page)
#> -- Page: Full Analysis ------------------------------------------
#> v data: 2997 rows x 7 cols 
#> 5 items
#> 
#> i [Text]
#> > [Tab] Demographics (2 vizs)
#>   * [Viz] Education (bar) x=degree
#>   * [Viz] Race (bar) x=race
#> > [Tab] Attitudes (2 vizs)
#>   * [Viz] Happiness (bar) x=happy
#>   * [Viz] Political Views (bar) x=polviews
```

``` r
complex_page %>% preview()
```

Preview

Overview

Key findings from the General Social Survey.

Demographics

Attitudes

Education

Race

Happiness

Political Views

**When to use:** Multi-section pages, reusable content, complex layouts.

**Why this approach?**

1.  **Modularity** - Each content piece is self-contained and testable
2.  **Reusability** - Share content across multiple pages

**Rule of thumb:**

- Same viz type, same styling → build directly on
  [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md)
- Different viz types, different defaults → use
  [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
  first

3.  **Clarity** - Easier to understand page structure
4.  **Maintainability** - Update one section without touching others

## 📄 Page Types

There’s only one special page type in the API: **landing pages**
(`is_landing_page = TRUE`). All other “page types” below are just
examples of how you might configure pages with different content - the
possibilities depend entirely on what you add!

### Landing Pages

The only true page type distinction. Landing pages are full-width
welcome screens without sidebars:

``` r
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text(
    "# Welcome to the GSS Dashboard",
    "",
    "Explore insights from the General Social Survey.",
    "",
    "## What You'll Find",
    "",
    "- **Demographics** - Age, education, race distributions",
    "- **Attitudes** - Happiness, political views",
    "",
    "Click the tabs above to begin exploring!"
  ) %>%
  add_callout("Data source: General Social Survey, NORC", type = "note")

print(home)
#> -- Page: Home ---------------------------------------------------
#> landing page 
#> 2 items
#> 
#> i [Text]
#> ! [Callout]
```

``` r
home %>% preview()
```

Preview

Welcome to the GSS Dashboard

Explore insights from the General Social Survey.

What You'll Find

- **Demographics** - Age, education, race distributions

- **Attitudes** - Happiness, political views

Click the tabs above to begin exploring!

**NOTE**

Data source: General Social Survey, NORC

### Example: Analysis Pages

Standard pages with data and visualizations - just add charts!

``` r
analysis <- create_page("Analysis", data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "Demographics") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Attitudes")

print(analysis)
#> -- Page: Analysis -----------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 3 items
#> 
#> > [Tab] Demographics (2 vizs)
#>   * [Viz] Education (bar) x=degree
#>   * [Viz] Race (bar) x=race
#> > [Tab] Attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
analysis %>% preview()
```

Preview

Demographics

Attitudes

Education

Race

Happiness

### Example: Text-Only Pages

For documentation, methodology, or about sections - just add text!

``` r
about <- create_page("About") %>%
  add_text(
    "## About This Dashboard",
    "",
    "Created using [dashboardr](https://github.com/favstats/dashboardr).",
    "",
    "### Methodology",
    "",
    "The GSS is a nationally representative survey conducted by NORC.",
    "",
    "### Contact",
    "",
    "For questions, contact the research team."
  ) %>%
  add_accordion(
    title = "Technical Details",
    text = "Margin of error: +/- 3%. Confidence level: 95%."
  )

print(about)
#> -- Page: About --------------------------------------------------
#> 2 items
#> 
#> i [Text]
#> = [Accordion] Technical Details
```

``` r
about %>% preview()
```

Preview

About This Dashboard

Created using [dashboardr](https://github.com/favstats/dashboardr).

Methodology

The GSS is a nationally representative survey conducted by NORC.

Contact

For questions, contact the research team.

Technical Details

Margin of error: +/- 3%. Confidence level: 95%.

### Example: Dashboard-Style Pages

Metrics at top, charts below - combine value boxes with visualizations!

``` r
# Build dashboard content
dashboard_content <- create_content(data = gss, type = "bar") %>%
  add_value_box_row() %>%
    add_value_box(title = "Respondents", value = format(nrow(gss), big.mark = ","), bg_color = "#3498DB") %>%
    add_value_box(title = "Variables", value = "7", bg_color = "#27AE60") %>%
  end_value_box_row() %>%
  add_divider() %>%
  add_viz(x_var = "degree", title = "Education Distribution")

# Assemble page
dashboard_page <- create_page("Dashboard") %>%
  add_content(dashboard_content)

print(dashboard_page)
#> -- Page: Dashboard ----------------------------------------------
#> 3 items
#> 
#> * [value_box_row]
#> - [Divider]
#> * [Viz] Education Distribution (bar) x=degree
```

``` r
dashboard_page %>% preview()
```

Preview

Respondents

2,997

Variables

7

------------------------------------------------------------------------

Education Distribution

## ⚙️ Page Settings

### Icons

Icons appear in the navbar next to page names, helping users quickly
identify different sections of your dashboard. Use the `icon` parameter
with an icon code from any [Iconify](https://icon-sets.iconify.design/)
icon set:

``` r
page_with_icon <- create_page("Charts", icon = "ph:chart-bar-fill", data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education")

print(page_with_icon)
#> -- Page: Charts -------------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 1 items
#> 
#> * [Viz] Education (bar) x=degree
```

Popular icons from [Phosphor Icons](https://phosphoricons.com/):

| Icon | Code                |
|:----:|---------------------|
|      | `ph:house-fill`     |
|      | `ph:chart-bar-fill` |
|      | `ph:chart-line`     |
|      | `ph:users-fill`     |
|      | `ph:info-fill`      |
|      | `ph:gear-fill`      |

See
[`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md)
for more icon options and styling.

### Navbar Alignment

By default, pages appear on the left side of the navbar. Use
`navbar_align = "right"` to push pages to the right side - useful for
utility pages like “Settings”, “About”, or “Help” that shouldn’t be the
main focus:

``` r
settings_page <- create_page("Settings", navbar_align = "right") %>%
  add_text("This page appears on the right side of the navbar.")

print(settings_page)
#> -- Page: Settings -----------------------------------------------
#> 1 items
#> 
#> i [Text]
```

### Page-Level Defaults

Just like with
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md),
you can set visualization defaults that apply to all charts on the page.
Set them once in
[`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md),
and they flow through to all
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
calls. Individual visualizations can still override these defaults:

``` r
styled_page <- create_page(
  "Survey Results",
  data = gss,
  type = "bar",
  color_palette = c("#3498DB"),
  drop_na_vars = TRUE
) %>%
  add_viz(x_var = "degree", title = "Education (default blue)") %>%
  add_viz(x_var = "happy", title = "Happiness (custom red)", color_palette = c("#E74C3C"))

print(styled_page)
#> -- Page: Survey Results -----------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 2 items
#> 
#> * [Viz] Education (default blue) (bar) x=degree
#> * [Viz] Happiness (custom red) (bar) x=happy
```

``` r
styled_page %>% preview()
```

Preview

Education (default blue)

Happiness (custom red)

### Loading Overlays

For pages with many charts or complex visualizations, loading overlays
provide visual feedback while content renders. The overlay covers the
page with a spinner and optional message, then fades out once charts are
ready. This improves perceived performance and prevents users from
seeing partially-loaded content.

> **See it in action:** Check out the [Features
> Demo](https://favstats.github.io/dashboardr/live-demos/features/index.md) -
> navigate to the “Loading Overlay” page and reload to see all overlay
> themes in action.

**Note:** Loading overlays are only visible when viewing the generated
dashboard (not in
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)).
To see them in action, generate a dashboard with
[`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)
and open it in a browser.

``` r
overlay_page <- create_page(
  "With Overlay",
  data = gss,
  type = "bar",
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading visualizations...",
  overlay_duration = 1500
) %>%
  add_viz(x_var = "degree", title = "Education")

print(overlay_page)
#> -- Page: With Overlay -------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 1 items
#> 
#> * [Viz] Education (bar) x=degree
```

#### Overlay Themes

| Theme      | Description                                      |
|------------|--------------------------------------------------|
| `"glass"`  | Semi-transparent frosted glass effect (default)  |
| `"light"`  | Clean white background with subtle shadow        |
| `"dark"`   | Dark background, good for dark-themed dashboards |
| `"accent"` | Uses your dashboard’s accent color               |

#### Overlay Options

| Parameter          | Description                    | Default        |
|--------------------|--------------------------------|----------------|
| `overlay`          | Enable/disable loading overlay | `FALSE`        |
| `overlay_theme`    | Visual style                   | `"glass"`      |
| `overlay_text`     | Message shown during loading   | `"Loading..."` |
| `overlay_duration` | Minimum display time (ms)      | `1000`         |

## 📑 Pagination

Pagination creates **page breaks** within a single navbar page,
splitting content into scrollable sections.

``` r
paginated <- create_page("Long Report", data = gss, type = "bar") %>%
  add_text("## Section 1: Demographics") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_viz(x_var = "race", title = "Race") %>%
  add_pagination() %>%
  
  add_text("## Section 2: Attitudes") %>%
  add_viz(x_var = "happy", title = "Happiness") %>%
  add_pagination() %>%
  
  add_text("## Section 3: Summary") %>%
  add_text("Key findings from this analysis...")

print(paginated)
#> -- Page: Long Report --------------------------------------------
#> v data: 2997 rows x 7 cols | default: bar 
#> 9 items
#> 
#> i [Text]
#> * [Viz] Education (bar) x=degree
#> * [Viz] Race (bar) x=race
#> > [PageBreak]
#> i [Text]
#> * [Viz] Happiness (bar) x=happy
#> > [PageBreak]
#> i [Text]
#> i [Text]
```

| Context | Behavior |
|----|----|
| [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md) | Content appears continuously (no breaks) |
| Generated dashboard | Creates separate scrollable sections |

**When to use:**

- Long analysis pages with distinct sections
- Report-style dashboards
- Sequential workflows

> **Note:** For truly separate pages in the navbar, use multiple
> [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md)
> calls instead.

## 👁️ Previewing Pages

Preview pages the same way as content collections:

``` r
page %>% preview()
```

The same [preview
limitations](https://favstats.github.io/dashboardr/articles/content-collections.html#previewing-content)
apply.

## 📊 Data Inheritance

When you set `data` on a page, content collections inherit it:

``` r
# Content WITHOUT data
charts <- create_content(type = "bar") %>%
  add_viz(x_var = "degree", title = "Education")

# Page WITH data - charts will use page's data
page <- create_page("Analysis", data = gss) %>%
  add_content(charts)

print(page)
#> -- Page: Analysis -----------------------------------------------
#> v data: 2997 rows x 7 cols 
#> 1 items
#> 
#> * [Viz] Education (bar) x=degree
```

If a content collection has its own data, it takes precedence over page
data.

## ➡️ Next Steps

Once you have pages, add them to a dashboard:

``` r
create_dashboard(title = "GSS Explorer", output_dir = "output") %>%
  add_pages(home, analysis, about) %>%
  generate_dashboard(render = TRUE)
```

See
[`vignette("dashboards")`](https://favstats.github.io/dashboardr/articles/dashboards.md)
for dashboard creation details, and
[`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md)
for tab styling and navbar customization.
