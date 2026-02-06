# Dashboards: Deep Dive

This vignette covers **dashboards** - the third layer of dashboardr’s
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

> **See it in action:** Check out the [live demo
> dashboard](https://favstats.github.io/dashboardr/live-demos/showcase/index.md)
> to see what a complete dashboard looks like.

## 📦 What the Dashboard Object Does

The
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)
function returns a **dashboard project object** - the container that
assembles everything into a final website. It:

1.  **Collects pages** into a single navigable website
2.  **Configures global appearance** (themes, navbar styling, colors)
3.  **Adds navigation features** (search, breadcrumbs, dropdown menus)
4.  **Handles publishing settings** (output directories, metadata,
    analytics)
5.  **Generates the final HTML** when you call
    [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)

## 🏗️ Creating Dashboards

### Basic Creation

``` r
dashboard <- create_dashboard(
  title = "My Dashboard",
  output_dir = "my_dashboard"
)

print(dashboard)
#> 
#> 📊 DASHBOARD PROJECT ====================================================
#> │ 🏷️  Title: My Dashboard
#> │ 📁 Output: my_dashboard
#> │
#> │ ⚙️  FEATURES:
#> │    • 🔍 Search
#> │    • 📑 Tabs: minimal
#> │
#> │ 📄 PAGES (0):
#> │    (no pages yet)
#> ══ ═════════════════════════════════════════════════════════════════════════
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
#> 📊 DASHBOARD PROJECT ====================================================
#> │ 🏷️  Title: GSS Explorer
#> │ 📁 Output: /Users/favstats/Dropbox/postdoc/output
#> │
#> │ ⚙️  FEATURES:
#> │    • 🔍 Search
#> │    • 📑 Tabs: minimal
#> │
#> │ 📄 PAGES (3):
#> │ ├─ 📄 Home [🏠 Landing]
#> │ ├─ 📄 Analysis [💾 1 dataset]
#> │ └─ 📄 About [➡️ Right]
#> ══ ═════════════════════════════════════════════════════════════════════════
```

Pages appear in the navbar in the order they’re added.

## ⚙️ Generating Output

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

## 🎨 Themes

### Built-in Quarto Themes

dashboardr uses [Bootswatch](https://bootswatch.com/) themes via Quarto.
**Preview all themes at [bootswatch.com](https://bootswatch.com/)**
before choosing!

| Theme | Style | Preview |
|----|----|----|
| `flatly` | Clean and modern (recommended) | [View](https://bootswatch.com/flatly/) |
| `cosmo` | Professional and corporate | [View](https://bootswatch.com/cosmo/) |
| `journal` | Academic and scholarly | [View](https://bootswatch.com/journal/) |
| `lux` | Luxurious and elegant | [View](https://bootswatch.com/lux/) |
| `simplex` | Simple and minimal | [View](https://bootswatch.com/simplex/) |
| `litera` | Clean and readable | [View](https://bootswatch.com/litera/) |
| `minty` | Fresh and friendly | [View](https://bootswatch.com/minty/) |
| `slate` | Dark professional | [View](https://bootswatch.com/slate/) |
| `darkly` | Full dark mode | [View](https://bootswatch.com/darkly/) |
| `cerulean` | Blue corporate | [View](https://bootswatch.com/cerulean/) |

``` r
# Clean and modern (recommended)
create_dashboard(title = "Clean", output_dir = "out", theme = "flatly")

# Professional and corporate
create_dashboard(title = "Corporate", output_dir = "out", theme = "cosmo")

# Academic and scholarly
create_dashboard(title = "Academic", output_dir = "out", theme = "journal")

# Dark mode
create_dashboard(title = "Dark", output_dir = "out", theme = "darkly")
```

> **Tip:** The Bootswatch preview shows Bootstrap components. Your
> dashboard will look similar but with dashboardr’s specific layout and
> styling applied.

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

## 🧭 Navbar Styling

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

## 📑 Tab Styling

### Tab Themes

``` r
create_dashboard(
  title = "Modern Tabs",
  output_dir = "out",
  tabset_theme = "modern"
)
```

Available themes: `"default"`, `"modern"`, `"pills"`, `"minimal"`

For detailed examples and custom colors, see
[`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md).

## 🔀 Navigation Features

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

### Dropdown Menus & Sidebar

For advanced navbar customization including dropdown menus and sidebar
navigation, see
[`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md).

## 🔗 Social Links

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

## 🚀 Publishing

For deployment to GitHub Pages, Netlify, or other hosting platforms, see
[`vignette("publishing_dashboards")`](https://favstats.github.io/dashboardr/articles/publishing_dashboards.md).

### Metadata

Add metadata for SEO and attribution:

``` r
create_dashboard(
  title = "With Metadata",
  output_dir = "out",
  author = "Dr. Jane Smith",
  description = "Comprehensive analysis of survey data with interactive visualizations",
  date = "2025-01-15",
  page_footer = "Copyright 2025 My Organization. All rights reserved."
)
```

### Analytics

Track dashboard usage with [Plausible Analytics](https://plausible.io/):

``` r
create_dashboard(
  title = "With Analytics",
  output_dir = "out",
  plausible = "yourdomain.com"  # Your Plausible site ID
)
```

You’ll need to [set up a Plausible
account](https://plausible.io/register) and add your domain first.

## 📋 Complete Example

Here’s a full example putting it all together:

``` r
# Create a complete survey dashboard
survey_dashboard <- create_dashboard(

title = "GSS Data Explorer",
  output_dir = "gss_out",
  theme = "flatly",
  search = TRUE,
  breadcrumbs = TRUE,
  back_to_top = TRUE,
  github = "https://github.com/example/gss-dashboard"
)

# Landing page
home <- create_page("Home", is_landing_page = TRUE) %>%
  add_text(
    "# GSS Data Explorer",
    "",
    "Interactive exploration of General Social Survey data.",
    "",
    "Use the navigation above to explore different sections."
  ) %>%
  add_callout("Click Demographics or Attitudes to see visualizations.", type = "tip")

# Demographics page with charts
demographics <- create_page("Demographics", data = gss, type = "bar",
                           icon = "ph:users", overlay = TRUE) %>%
  add_text("## Demographic Distributions") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Variables") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "Variables")

# Attitudes page
attitudes <- create_page("Attitudes", data = gss, type = "bar",
                        icon = "ph:heart", overlay = TRUE) %>%
  add_text("## Attitudes & Values") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Measures")

# About page (right-aligned in navbar)
about <- create_page("About", navbar_align = "right", icon = "ph:info") %>%
  add_text(
    "## About This Dashboard",
    "",
    "Created with [dashboardr](https://github.com/favstats/dashboardr).",
    "",
    "Data: General Social Survey (GSS), NORC."
  )

# Assemble dashboard
survey_dashboard <- survey_dashboard %>%
  add_pages(home, demographics, attitudes, about)

print(survey_dashboard)
#> 
#> 📊 DASHBOARD PROJECT ====================================================
#> │ 🏷️  Title: GSS Data Explorer
#> │ 📁 Output: gss_out
#> │
#> │ ⚙️  FEATURES:
#> │    • 🔍 Search
#> │    • 🎨 Theme: flatly
#> │    • 📑 Tabs: minimal
#> │
#> │ 🔗 INTEGRATIONS: 💻 GitHub
#> │
#> │ 📄 PAGES (4):
#> │ ├─ 📄 Home [🏠 Landing]
#> │ ├─ 📄 Demographics [🏷️ Icon, 🔄 Overlay, 💾 1 dataset]
#> │ ├─ 📄 Attitudes [🏷️ Icon, 🔄 Overlay, 💾 1 dataset]
#> │ └─ 📄 About [🏷️ Icon, ➡️ Right]
#> ══ ═════════════════════════════════════════════════════════════════════════
```

To generate this dashboard:

``` r
survey_dashboard %>% generate_dashboard(render = TRUE, open = "browser")
```

> **See a live version:** Check out the [live demo
> dashboard](https://favstats.github.io/dashboardr/live-demos/showcase/index.md)
> for a working example with similar structure.

## 📚 Related Vignettes

- [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) -
  Quick overview
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  Layer 1: Content
- [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) -
  Layer 2: Pages
- [`vignette("advanced-features")`](https://favstats.github.io/dashboardr/articles/advanced-features.md) -
  Icons, inputs, filtering, tab styling
- [`vignette("publishing_dashboards")`](https://favstats.github.io/dashboardr/articles/publishing_dashboards.md) -
  Deployment guide
