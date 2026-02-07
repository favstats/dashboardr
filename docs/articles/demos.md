# Live Demos

## Community Gallery

Browse dashboards built with dashboardr by the community: **[View the
Gallery →](https://favstats.github.io/dashboardr/gallery/)**

Built something with dashboardr? **[Submit your
dashboard](https://github.com/favstats/dashboardr/issues/new?labels=gallery-submission&title=%5BGallery%5D+My+Dashboard)**
to the gallery and share it with the community!

## Overview

`dashboardr` includes several live demo dashboards that showcase its
capabilities. Each demo comes with complete code documentation showing
the exact R code used.

### Main Demos

- **Tutorial Dashboard** - Beginner-friendly introduction to dashboardr.
  [Code &
  Docs](https://favstats.github.io/dashboardr/articles/tutorial_dashboard_code.md)
  \| [Live
  Demo](https://favstats.github.io/dashboardr/live-demos/tutorial/index.md)
- **Showcase Dashboard** - Advanced dashboard with multiple pages and
  tabsets. [Code &
  Docs](https://favstats.github.io/dashboardr/articles/showcase_dashboard_code.md)
  \| [Live
  Demo](https://favstats.github.io/dashboardr/live-demos/showcase/index.md)
- **Interactive Inputs** - Gallery of input types (select, slider,
  switch, checkbox). [View
  Demo](https://favstats.github.io/dashboardr/live-demos/inputs/index.md)
- **Sidebar Demo** - Page sidebars with filters (checkbox, dropdown,
  slider). [View
  Demo](https://favstats.github.io/dashboardr/live-demos/sidebar/index.md)

### Advanced Demos

- **GSS Explorer (Sidebar)** - Full sidebar dashboard with cross-tab
  filtering, conditional visibility, dynamic titles, and consistent
  colors.
  [Code](https://favstats.github.io/dashboardr/pkgdown/build-sidebar-gss-demo.R)
  \| [View
  Demo](https://favstats.github.io/dashboardr/live-demos/sidebar-gss/index.md)
  \|
  [Documentation](https://favstats.github.io/dashboardr/articles/advanced-features.html#cross-tab-filtering-dynamic-titles)

### Real-World Dashboards

- **DigIQ Monitor** - A comprehensive digital competence monitor for
  Dutch citizens (ages 10-100), featuring 11 dimension pages,
  multilingual support (Dutch/English), paginated visualizations, and
  interactive modals. [View Live →](https://www.digiqmonitor.nl/)

### Tabset Theme Demos

Each tabset theme has its own demo dashboard showing 1, 2, and 3-level
nested tabs:

- **Pills** - Rounded pill-shaped tabs.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/pills/index.md)
- **Modern** - Clean contemporary styling.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/modern/index.md)
- **Minimal** - Subtle, understated tabs.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/minimal/index.md)
- **Classic** - Traditional tab appearance.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/classic/index.md)
- **Underline** - Underlined active tab.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/underline/index.md)
- **Segmented** - iOS-style segmented controls.
  [View](https://favstats.github.io/dashboardr/live-demos/tabsets/segmented/index.md)

### Loading Overlays

Demo of animated loading overlays with different themes (light, dark,
glass, accent). [View
Demo](https://favstats.github.io/dashboardr/live-demos/overlay/index.md)

## Tutorial Dashboard

The tutorial dashboard is perfect for learning the basics:

- Stacked bar charts with custom colors and ordering
- Heatmaps showing relationships between variables
- Tabset grouping for organizing visualizations
- Text-only pages for documentation
- **Collapsible code blocks** showing exact R code for each
  visualization

**[View Complete Code Documentation
→](https://favstats.github.io/dashboardr/articles/tutorial_dashboard_code.md)**

``` r
library(dashboardr)

# Generate and open the tutorial dashboard
tutorial_dashboard()
```

## Showcase Dashboard

The showcase dashboard demonstrates advanced features:

- Multiple tabset groups (Demographics, Politics, Social Issues)
- Complex visualizations with custom styling
- Mixed content pages (text + visualizations)
- Card layouts with images
- **Bidirectional links** between code documentation and live
  visualizations

**[View Complete Code Documentation
→](https://favstats.github.io/dashboardr/articles/showcase_dashboard_code.md)**

``` r
# Generate and open the showcase dashboard
showcase_dashboard()
```

## Setting a Tabset Theme

``` r
# Set theme at dashboard level
create_dashboard(
  title = "My Dashboard",
  output_dir = "my_dashboard",
  tabset_theme = "pills"
)
```

Available themes: `pills`, `modern`, `minimal`, `classic`, `underline`,
`segmented`.

## Creating Nested Tabs

``` r
# 1 Level - Different tabgroup names create separate tabs
create_viz() %>%
  add_viz(type = "bar", x_var = "age", tabgroup = "age") %>%
  add_viz(type = "bar", x_var = "education", tabgroup = "education") %>%
  add_viz(type = "bar", x_var = "region", tabgroup = "region")

# 2 Levels - Use "/" to create parent > child hierarchy
create_viz() %>%
  add_viz(type = "bar", x_var = "age", tabgroup = "satisfaction/by_age") %>%
  add_viz(type = "bar", x_var = "education", tabgroup = "satisfaction/by_education")

# 3 Levels - Add more "/" for deeper nesting
create_viz() %>%
  add_viz(type = "bar", x_var = "age", tabgroup = "survey/satisfaction/age") %>%
  add_viz(type = "bar", x_var = "education", tabgroup = "survey/demographics/education")
```

## Page Sidebars

Sidebars provide a dedicated space for filters that stays visible as
users scroll:

``` r
create_content(data = my_data) %>%
  add_sidebar(width = "280px", title = "Filters") %>%
    add_text("Filter the data:") %>%
    add_input(
      input_id = "country",
      label = "Countries:",
      type = "checkbox",
      filter_var = "country",
      options = c("USA", "UK", "Germany"),
      columns = 2  # 2-column grid layout
    ) %>%
  end_sidebar() %>%
  add_viz(type = "bar", x_var = "country")
```

Features:

- Left or right positioning (`position = "right"`)
- Multiple input types (checkbox, radio, dropdown, slider)
- Multi-column layouts for checkboxes (`columns = 2, 3, 4`)
- Mobile-responsive (stacks on small screens)

See the [Sidebar
Demo](https://favstats.github.io/dashboardr/live-demos/sidebar/index.md)
for live examples.

## Loading Overlays

``` r
# Add overlay to a page
add_page(
  name = "Analysis",
  data = my_data,
  visualizations = my_viz,
  overlay = TRUE,
  overlay_theme = "glass",
  overlay_text = "Loading charts...",
  overlay_duration = 2000
)
```

Available overlay themes: `light`, `dark`, `glass`, `accent`.

## Requirements

All demos require:

1.  **Quarto CLI** installed on your system
2.  **gssr package** for GSS data (for tutorial/showcase):

``` r
install.packages("gssr")
```

## Next Steps

After exploring the demos:

1.  Run
    [`tutorial_dashboard()`](https://favstats.github.io/dashboardr/reference/tutorial_dashboard.md)
    to see basic features
2.  Run
    [`showcase_dashboard()`](https://favstats.github.io/dashboardr/reference/showcase_dashboard.md)
    to see advanced capabilities
3.  Check out
    [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md)
    for detailed guides
4.  Browse the [Community
    Gallery](https://favstats.github.io/dashboardr/gallery/) for
    inspiration
5.  Use the demos as templates for your own projects
6.  [Submit your
    dashboard](https://github.com/favstats/dashboardr/issues/new?labels=gallery-submission&title=%5BGallery%5D+My+Dashboard)
    to the gallery!
