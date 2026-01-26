# Dashboards: Deep Dive

``` r
library(dashboardr)
library(dplyr)
library(gssr)
#> Warning: package 'gssr' was built under R version 4.4.3
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year >= 2010, !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))
```

This vignette goes deep into dashboards - the third layer of
dashboardr’s architecture. For a quick overview, see
[`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md).

## What Dashboards Do

Dashboards are the **assembly layer** that:

1.  Collect pages into a single website
2.  Configure global appearance (themes, navbar, colors)
3.  Add navigation features (search, breadcrumbs, dropdowns)
4.  Handle publishing (output directories, metadata)
5.  Generate the final HTML output

## Creating Dashboards

### Basic Creation

``` r
dashboard <- create_dashboard(
  title = "My Dashboard",
  output_dir = "my_dashboard"
)

print(dashboard)
#> 
#> +==============================================================================
#> | [*] DASHBOARD PROJECT
#> +==============================================================================
#> | [T] Title: My Dashboard
#> | [>] Output: /Users/favstats/Dropbox/postdoc/my_dashboard
#> |
#> | [+] FEATURES:
#> |    * [?] Search
#> |    * [~] Tabs: minimal
#> |
#> | [P] PAGES (0):
#> |    (no pages yet)
#> +==============================================================================
```

### Key Parameters

| Parameter | Description | Example |
|----|----|----|
| `title` | Dashboard title (appears in navbar and browser tab) | `"GSS Explorer"` |
| `output_dir` | Directory for generated files | `"output"` |
| `theme` | Quarto theme | `"flatly"` |
| `author` | Author name for metadata | `"Dr. Jane Smith"` |
| `description` | SEO description | `"Survey analysis dashboard"` |

### Adding Pages

Use
[`add_pages()`](https://favstats.github.io/dashboardr/reference/add_pages.md)
to add page objects:

``` r
# Create content
charts <- create_content(type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "overview") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "overview")

# Create pages
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text("# Welcome!", "", "Explore the data.")

analysis <- create_page("Analysis", data = gss) %>%
  add_content(charts)

about <- create_page("About", navbar_align = "right") %>%
  add_text("## About", "", "Dashboard created with dashboardr.")

# Add pages to dashboard
dashboard <- create_dashboard(title = "GSS Explorer", output_dir = "output") %>%
  add_pages(home, analysis, about)

print(dashboard)
#> 
#> +==============================================================================
#> | [*] DASHBOARD PROJECT
#> +==============================================================================
#> | [T] Title: GSS Explorer
#> | [>] Output: /Users/favstats/Dropbox/postdoc/output
#> |
#> | [+] FEATURES:
#> |    * [?] Search
#> |    * [~] Tabs: minimal
#> |
#> | [P] PAGES (3):
#> | +- [P] Home [[H] Landing]
#> | +- [P] Analysis [[d] 1 dataset]
#> | +- [P] About [-> Right]
#> +==============================================================================
```

Pages appear in the navbar in the order they’re added.

## Themes

### Built-in Quarto Themes

``` r
# Clean and modern (recommended)
create_dashboard(title = "Clean", output_dir = "out", theme = "flatly")

# Professional and corporate
create_dashboard(title = "Corporate", output_dir = "out", theme = "cosmo")

# Academic and scholarly
create_dashboard(title = "Academic", output_dir = "out", theme = "journal")

# Luxurious and elegant
create_dashboard(title = "Elegant", output_dir = "out", theme = "lux")

# Simple and minimal
create_dashboard(title = "Minimal", output_dir = "out", theme = "simplex")
```

### Custom Themes with apply_theme()

dashboardr includes pre-built themes for common use cases:

``` r
# Academic/research style
dashboard %>% apply_theme(theme_academic())

# Modern tech style
dashboard %>% apply_theme(theme_modern())

# Clean minimal style
dashboard %>% apply_theme(theme_clean())

# UvA/ASCoR branding
dashboard %>% apply_theme(theme_ascor())
dashboard %>% apply_theme(theme_uva())
```

### Customizing Themes

Override any theme parameter:

``` r
dashboard %>% apply_theme(
  theme_modern("blue"),
  navbar_bg_color = "#2C3E50",
  navbar_text_color = "#FFFFFF",
  navbar_text_hover_color = "#3498DB",
  mainfont = "Inter",
  fontsize = "16px",
  fontcolor = "#333333",
  linkcolor = "#3498DB",
  backgroundcolor = "#FFFFFF",
  max_width = "1400px"
)
```

## Navbar Styling

### Basic Navbar Colors

``` r
create_dashboard(
  title = "Dark Navbar",
  output_dir = "out",
  navbar_style = "dark",
  navbar_bg_color = "#2C3E50",
  navbar_text_color = "#ECF0F1"
)
```

### Light vs Dark Navbar

``` r
# Dark navbar (light text on dark background)
create_dashboard(title = "Dark", output_dir = "out", navbar_style = "dark")

# Light navbar (dark text on light background)
create_dashboard(title = "Light", output_dir = "out", navbar_style = "light")
```

## Tab Styling

### Tab Themes

``` r
create_dashboard(
  title = "Modern Tabs",
  output_dir = "out",
  tabset_theme = "modern"
)
```

Available themes: `"default"`, `"modern"`, `"pills"`, `"minimal"`

### Custom Tab Colors

``` r
create_dashboard(
  title = "Custom Colors",
  output_dir = "out",
  tabset_theme = "modern",
  tabset_colors = list(
    active_bg = "#3498DB",       # Active tab background
    active_text = "#FFFFFF",     # Active tab text
    inactive_bg = "#ECF0F1",     # Inactive tab background
    inactive_text = "#7F8C8D",   # Inactive tab text
    hover_bg = "#BDC3C7",        # Hover background
    border_color = "#DDDDDD"     # Tab border color
  )
)
```

## Navigation Features

### Enhanced Navigation

``` r
create_dashboard(
  title = "Enhanced Nav",
  output_dir = "out",
  breadcrumbs = TRUE,        # Show breadcrumb trail
  page_navigation = TRUE,    # Prev/next links at page bottom
  back_to_top = TRUE,        # "Back to top" button
  search = TRUE              # Search functionality
)
```

### Dropdown Menus

Create dropdown menus in the navbar:

``` r
create_dashboard(
  title = "With Dropdowns",
  output_dir = "out",
  navbar_left = list(
    list(
      text = "Analysis",
      menu = list(
        list(text = "Demographics", href = "demographics.html"),
        list(text = "Attitudes", href = "attitudes.html"),
        list(text = "Trends", href = "trends.html"),
        list(text = "---"),  # Divider
        list(text = "Download Data", href = "data.csv")
      )
    ),
    list(
      text = "Reports",
      menu = list(
        list(text = "Monthly Report", href = "monthly.html"),
        list(text = "Quarterly Report", href = "quarterly.html")
      )
    )
  )
)
```

### Sidebar Navigation

For dashboards with many pages, use sidebar navigation:

``` r
create_dashboard(
  title = "Sidebar Nav",
  output_dir = "out",
  sidebar = TRUE,
  sidebar_title = "Navigation",
  sidebar_style = "floating"  # or "docked"
)
```

## Social Links

Add social media and contact links to the navbar:

``` r
create_dashboard(
  title = "Social",
  output_dir = "out",
  github = "https://github.com/username/project",
  twitter = "https://twitter.com/username",
  linkedin = "https://linkedin.com/in/username",
  email = "user@example.com",
  website = "https://example.com"
)
```

## Publishing

### Separate Output and Publish Directories

For GitHub Pages deployment:

``` r
create_dashboard(
  title = "For GitHub Pages",
  output_dir = "src",           # Source Quarto files
  publish_dir = "../docs"       # Published HTML (GitHub Pages reads from /docs)
)
```

### Metadata

Add metadata for SEO and attribution:

``` r
create_dashboard(
  title = "With Metadata",
  output_dir = "out",
  author = "Dr. Jane Smith",
  description = "Comprehensive analysis of survey data with interactive visualizations",
  date = "2025-01-15",
  page_footer = "© 2025 My Organization. All rights reserved."
)
```

### Analytics

Track dashboard usage with Plausible Analytics:

``` r
create_dashboard(
  title = "With Analytics",
  output_dir = "out",
  plausible = "yourdomain.com"
)
```

## Generating Output

### Basic Generation

``` r
dashboard %>%
  generate_dashboard(render = TRUE, open = "browser")
```

### Generation Options

| Parameter          | Description                                           |
|--------------------|-------------------------------------------------------|
| `render = FALSE`   | Only create Quarto (.qmd) files, don’t render to HTML |
| `render = TRUE`    | Render to HTML (slower but complete)                  |
| `open = "browser"` | Open in default web browser                           |
| `open = "viewer"`  | Open in RStudio Viewer pane                           |
| `clean = TRUE`     | Remove intermediate files after rendering             |

### Development Workflow

During development, iterate quickly by skipping rendering:

``` r
# Fast iteration: just create QMD files
dashboard %>% generate_dashboard(render = FALSE)

# Check structure, make changes...

# When ready, full render
dashboard %>% generate_dashboard(render = TRUE, open = "browser")

# Final build with cleanup
dashboard %>% generate_dashboard(render = TRUE, clean = TRUE)
```

## Complete Example

``` r
library(dashboardr)
library(dplyr)
library(gssr)

# Load data
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year >= 2010, !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))

# === LAYER 1: CONTENT ===

demographics <- create_content(type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "demographics") %>%
  set_tabgroup_labels(demographics = "Demographics")

attitudes <- create_content(type = "bar") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes") %>%
  add_viz(x_var = "polviews", title = "Politics", tabgroup = "attitudes") %>%
  set_tabgroup_labels(attitudes = "Attitudes & Values")

crosstabs <- create_content(type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", 
          title = "Happiness by Education", tabgroup = "crosstabs",
          stacked_type = "percent") %>%
  set_tabgroup_labels(crosstabs = "Cross-Tabulations")

# === LAYER 2: PAGES ===

home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text(
    "# GSS Data Explorer",
    "",
    "Explore trends in American society through the General Social Survey (2010-2024).",
    "",
    "## About This Dashboard",
    "",
    "This dashboard presents interactive visualizations of GSS data covering:",
    "",
    "- **Demographics** - Education, race, age distributions",
    "- **Attitudes** - Happiness, political views, social trust",
    "- **Trends** - Changes over time in key indicators",
    "",
    "Use the navigation above to explore different aspects of the data."
  ) %>%
  add_callout("Data source: General Social Survey, NORC at University of Chicago", type = "note")

analysis <- create_page("Analysis", data = gss, 
                        overlay = TRUE, lazy_load_charts = TRUE) %>%
  add_content(demographics) %>%
  add_content(attitudes) %>%
  add_content(crosstabs)

about <- create_page("About", navbar_align = "right") %>%
  add_text(
    "## About This Dashboard",
    "",
    "Created with [dashboardr](https://github.com/favstats/dashboardr).",
    "",
    "### Methodology",
    "",
    "The General Social Survey (GSS) is a nationally representative survey",
    "of adults in the United States, conducted since 1972.",
    "",
    "### Contact",
    "",
    "For questions, please contact the research team."
  )

# === LAYER 3: DASHBOARD ===

dashboard <- create_dashboard(
  title = "GSS Data Explorer",
  output_dir = "gss_dashboard",
  theme = "flatly",
  tabset_theme = "modern",
  search = TRUE,
  breadcrumbs = TRUE,
  back_to_top = TRUE,
  github = "https://github.com/favstats/dashboardr",
  author = "Your Name",
  description = "Interactive exploration of General Social Survey data",
  page_footer = "Data: General Social Survey (2010-2024)"
) %>%
  add_pages(home, analysis, about) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

## Debugging

### Check Dashboard Structure

``` r
# Print dashboard to see all pages
print(dashboard)

# Print individual pages
print(analysis)

# Print content collections
print(demographics)
```

### Common Issues

**Pages not appearing:** - Check that you called
[`add_pages()`](https://favstats.github.io/dashboardr/reference/add_pages.md)
before
[`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)

**Visualizations not rendering:** - Ensure `data` is set on the page or
content collection - Check variable names match your data columns

**Tabs in wrong order:** - Tabs appear in the order you call
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)

### Test Without Full Render

``` r
# Fast test: just create QMD files
dashboard %>% generate_dashboard(render = FALSE)

# Check the generated .qmd files in output_dir
```

## Related Vignettes

- [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) -
  Quick overview
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  Layer 1: Content
- [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) -
  Layer 2: Pages
- [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) -
  Icons, timelines, heatmaps
