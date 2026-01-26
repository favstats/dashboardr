# Content Collections: Deep Dive

``` r
library(dashboardr)
library(dplyr)
library(gssr)
#> Warning: package 'gssr' was built under R version 4.4.3
data(gss_all)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, wtssall) %>%
  filter(year >= 2010, !is.na(age), !is.na(sex), !is.na(race), !is.na(degree))
```

This vignette goes deep into content collections - the first layer of
dashboardr’s architecture. For a quick overview, see
[`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md).

## What Content Collections Store

A content collection is a container that holds:

- **Visualizations** - Charts and graphs
- **Text blocks** - Markdown content
- **Callouts** - Highlighted notes, tips, warnings
- **Images** - Static images with captions
- **Accordions** - Collapsible sections
- **Cards** - Styled content blocks
- **Code blocks** - Syntax-highlighted code
- **Pagination markers** - Page breaks

Everything is stored in a unified `items` list, and you can inspect it
anytime:

``` r
content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_text("## Analysis", "", "Key findings:") %>%
  add_callout("Sample size: 21,788", type = "note")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 21788 rows x 8 cols
#> 
#> * [Viz] Education (bar) x=degree
#> i [Text]
#> ! [Callout]
```

## The Defaults System

When you create a content collection, you set **defaults** that apply to
all visualizations:

``` r
# These defaults apply to ALL add_viz() calls
content <- create_content(
  data = gss,
  type = "bar",
  color_palette = c("#3498DB"),
  drop_na_vars = TRUE,
  bar_type = "percent"
)

# This viz inherits all defaults
content <- content %>%
  add_viz(x_var = "degree", title = "Education (defaults)")

# This viz overrides color_palette but keeps other defaults
content <- content %>%
  add_viz(x_var = "race", title = "Race (green)", color_palette = c("#2ECC71"))

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 21788 rows x 8 cols
#> 
#> * [Viz] Education (defaults) (bar) x=degree
#> * [Viz] Race (green) (bar) x=race
```

``` r
content %>% preview()
```

Preview

Education (defaults)

Race (green)

### Available Default Parameters

| Parameter | Description | Example |
|----|----|----|
| `type` | Visualization type | `"bar"`, `"histogram"`, `"stackedbar"` |
| `color_palette` | Colors for charts | `c("#3498DB", "#E74C3C")` |
| `drop_na_vars` | Remove NA values | `TRUE` |
| `weight_var` | Survey weight column | `"weight"` |
| `bar_type` | Count or percent | `"percent"` |
| `bins` | Histogram bins | `30` |

## Visualization Types in Detail

### Bar Charts

``` r
# Basic bar
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education Levels") %>%
  preview()
```

Preview

Education Levels

``` r
# Percentage bar
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "race", title = "Race (%)", bar_type = "percent") %>%
  preview()
```

Preview

Race (%)

``` r
# Grouped bar
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", group_var = "sex", title = "Education by Sex") %>%
  preview()
```

Preview

Education by Sex

### Stacked Bars

``` r
# Count stacked
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Happiness by Education") %>%
  preview()
```

Preview

Happiness by Education

``` r
# Percent stacked (100% bars)
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Happiness by Education (%)",
          stacked_type = "percent") %>%
  preview()
```

Preview

Happiness by Education (%)

``` r
# Horizontal stacked
create_content(data = gss, type = "stackedbar") %>%
  add_viz(x_var = "degree", stack_var = "happy", title = "Horizontal",
          stacked_type = "percent", horizontal = TRUE) %>%
  preview()
```

Preview

Horizontal

### Histograms

``` r
create_content(data = gss, type = "histogram") %>%
  add_viz(x_var = "age", title = "Age Distribution", bins = 25,
          x_label = "Age (years)", y_label = "Frequency") %>%
  preview()
```

Preview

Age Distribution

### Multiple Stacked Bars (Likert Scales)

For survey questions with the same response scale, use
`type = "stackedbars"`:

``` r
# Within create_content() workflow
create_content(data = survey_data, type = "stackedbars") %>%
  add_viz(
    questions = c("q1", "q2", "q3", "q4"),
    question_labels = c("I trust the company", 
                        "I feel valued",
                        "I have opportunities",
                        "I would recommend"),
    title = "Employee Sentiment",
    stacked_type = "percent",
    horizontal = TRUE
  ) %>%
  preview()
```

### Timeline

Track changes over time:

``` r
create_content(data = gss, type = "timeline") %>%
  add_viz(
    time_var = "year",
    response_var = "happy",
    title = "Happiness Over Time",
    chart_type = "line"
  ) %>%
  preview()
```

Preview

Happiness Over Time

### Heatmap

Visualize intensity across two dimensions:

``` r
create_content(data = gss, type = "heatmap") %>%
  add_viz(
    x_var = "degree",
    y_var = "happy",
    title = "Happiness by Education",
    agg_fun = "count"
  ) %>%
  preview()
```

Preview

No content to render.

## Organizing with Tabgroups

Tabgroups create tabbed interfaces in your dashboard:

``` r
content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demographics") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "demographics") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes") %>%
  add_viz(x_var = "polviews", title = "Politics", tabgroup = "attitudes")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 4 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] demographics (2 vizs)
#>   * [Viz] Education (bar) x=degree
#>   * [Viz] Race (bar) x=race
#> > [Tab] attitudes (2 vizs)
#>   * [Viz] Happiness (bar) x=happy
#>   * [Viz] Politics (bar) x=polviews
```

``` r
content %>% preview()
```

Preview

demographics

attitudes

Education

Race

Happiness

Politics

### Nested Tabgroups

For complex dashboards, you can create **multi-level tab hierarchies**
using `/` as a separator. This creates tabs within tabs:

    tabgroup = "parent/child"

**How it works:**

- `"demographics"` → Creates a single tab called “demographics”
- `"demographics/education"` → Creates a “demographics” tab, and
  *inside* it, an “education” sub-tab
- `"demographics/education/trends"` → Three levels deep

**Example: Organizing a survey dashboard**

``` r
nested <- create_content(data = gss, type = "bar") %>%
  # Top-level: "Demographics" with two sub-tabs

  add_viz(x_var = "degree", title = "Education Level", 
          tabgroup = "Demographics/Education") %>%
  add_viz(x_var = "race", title = "Race Distribution", 
          tabgroup = "Demographics/Education") %>%
  add_viz(x_var = "age", title = "Age Distribution", 
          tabgroup = "Demographics/Age") %>%
  

  # Top-level: "Attitudes" with sub-tabs
  add_viz(x_var = "happy", title = "General Happiness", 
          tabgroup = "Attitudes/Wellbeing") %>%
  add_viz(x_var = "polviews", title = "Political Views", 
          tabgroup = "Attitudes/Politics")

print(nested)
#> -- Content Collection ----------------------------------------------------------
#> 5 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] Demographics (2 tabs)
#>   > [Tab] Education (2 vizs)
#>     * [Viz] Education Level (bar) x=degree
#>     * [Viz] Race Distribution (bar) x=race
#>   > [Tab] Age (1 viz)
#>     * [Viz] Age Distribution (bar) x=age
#> > [Tab] Attitudes (2 tabs)
#>   > [Tab] Wellbeing (1 viz)
#>     * [Viz] General Happiness (bar) x=happy
#>   > [Tab] Politics (1 viz)
#>     * [Viz] Political Views (bar) x=polviews
```

**The structure:**

    ├─ Demographics          (top-level tab)
    │  ├─ Education          (sub-tab with 2 charts)
    │  └─ Age                (sub-tab with 1 chart)
    │
    └─ Attitudes             (top-level tab)
       ├─ Wellbeing          (sub-tab with 1 chart)
       └─ Politics           (sub-tab with 1 chart)

**When to use nested tabs:**

- You have many visualizations that need organization
- Content naturally falls into categories and subcategories
- You want to keep related charts together without overwhelming users

**Tip:** Don’t go deeper than 2-3 levels. Too much nesting makes
navigation confusing.

### Custom Tab Labels

Replace tabgroup IDs with readable labels:

``` r
labeled <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demo") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes") %>%
  set_tabgroup_labels(
    demo = "Demographics",
    attitudes = "Attitudes & Values"
  )

print(labeled)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
labeled %>% preview()
```

Preview

demo

attitudes

Education

Happiness

## Text and Content Blocks

### Text Blocks

[`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md)
accepts multiple strings that become separate paragraphs:

``` r
content <- create_content(type = "bar") %>%
  add_text(
    "## Survey Results",
    "",
    "This section presents key findings from the General Social Survey.",
    "",
    "### Key Highlights",
    "",
    "- Education levels vary significantly",
    "- Happiness correlates with education",
    "- Political views are polarized"
  )

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> i [Text]
```

### Callouts

Five callout types for different purposes:

``` r
content <- create_content(type = "bar") %>%
  add_callout("This is a note", type = "note") %>%
  add_callout("This is a tip", type = "tip") %>%
  add_callout("This is a warning", type = "warning") %>%
  add_callout("This is a caution", type = "caution") %>%
  add_callout("This is important", type = "important")

print(content)
#> -- Content Collection ----------------------------------------------------------
#> 5 items | x no data
#> 
#> ! [Callout]
#> ! [Callout]
#> ! [Callout]
#> ! [Callout]
#> ! [Callout]
```

### Images

Add images with optional captions:

``` r
img_content <- create_content() %>%
  add_image("workflow_example.png", caption = "Figure 1: The dashboardr workflow")

print(img_content)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> (*) [Image]
```

### Accordions

Collapsible content sections - great for supplementary information:

``` r
accordion_content <- create_content() %>%
  add_accordion(
    title = "Methodology Details",
    text = "This survey used stratified random sampling with a margin of error of +/-3%."
  ) %>%
  add_accordion(
    title = "Data Sources", 
    text = "Data from the General Social Survey (GSS), collected by NORC at the University of Chicago."
  )

print(accordion_content)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | x no data
#> 
#> = [Accordion] Methodology Details
#> = [Accordion] Data Sources
```

### Cards

Styled content blocks with optional headers:

``` r
card_content <- create_content() %>%
  add_card(
    title = "Key Finding",
    text = "Education level is strongly correlated with reported happiness."
  )

print(card_content)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | x no data
#> 
#> [x] [Card] Key Finding
```

### Dividers

Visual separators between content sections:

``` r
divider_content <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education") %>%
  add_divider() %>%
  add_viz(x_var = "happy", title = "Happiness")

print(divider_content)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 21788 rows x 8 cols
#> 
#> * [Viz] Education (bar) x=degree
#> - [Divider]
#> * [Viz] Happiness (bar) x=happy
```

``` r
divider_content %>% preview()
```

Preview

Education

------------------------------------------------------------------------

Happiness

## Combining Collections

### The + Operator

Merge collections while preserving structure:

``` r
demographics <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demo")

attitudes <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes")

combined <- demographics + attitudes
print(combined)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
combined %>% preview()
```

Preview

demo

attitudes

Education

Happiness

### combine_viz()

Same as `+` but in pipe-friendly form:

``` r
all_content <- demographics %>%
  combine_viz(attitudes)

print(all_content)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [Tab] attitudes (1 viz)
#>   * [Viz] Happiness (bar) x=happy
```

``` r
all_content %>% preview()
```

Preview

demo

attitudes

Education

Happiness

### Adding Pagination

Insert page breaks between sections:

``` r
section1 <- create_content(type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demo")

section2 <- create_content(type = "stackedbar") %>%
  add_viz(x_var = "happy", stack_var = "sex", title = "Happiness", tabgroup = "cross")

paginated <- section1 %>%
  add_pagination() %>%
  combine_viz(section2)

print(paginated)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | x no data
#> 
#> > [Tab] demo (1 viz)
#>   * [Viz] Education (bar) x=degree
#> > [PageBreak]
#> > [Tab] cross (1 viz)
#>   * [Viz] Happiness (stackedbar) x=happy, stack=sex
```

## Filtering Data

Apply data filters to individual visualizations:

``` r
filtered <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Male", filter = ~ sex == 1, tabgroup = "by_sex") %>%
  add_viz(x_var = "happy", title = "Female", filter = ~ sex == 2, tabgroup = "by_sex")

print(filtered)
#> -- Content Collection ----------------------------------------------------------
#> 2 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] by_sex (2 vizs)
#>   * [Viz] Male (bar) x=happy +filter
#>   * [Viz] Female (bar) x=happy +filter
```

``` r
filtered %>% preview()
```

Preview

by_sex

Male

Female

### Complex Filters

``` r
complex <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Young Adults", 
          filter = ~ age >= 18 & age <= 35, tabgroup = "age_groups") %>%
  add_viz(x_var = "happy", title = "Middle Age", 
          filter = ~ age > 35 & age <= 55, tabgroup = "age_groups") %>%
  add_viz(x_var = "happy", title = "Older Adults", 
          filter = ~ age > 55, tabgroup = "age_groups")

print(complex)
#> -- Content Collection ----------------------------------------------------------
#> 3 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] age_groups (3 vizs)
#>   * [Viz] Young Adults (bar) x=happy +filter
#>   * [Viz] Middle Age (bar) x=happy +filter
#>   * [Viz] Older Adults (bar) x=happy +filter
```

``` r
complex %>% preview()
```

Preview

age_groups

Young Adults

Middle Age

Older Adults

### Filter-Aware Grouping with title_tabset

When using filters, use `title_tabset` to create automatic sub-tabs
within a tabgroup:

``` r
# Same visualization, different subsets, automatic sub-tabs
gender_comparison <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Happiness", 
          filter = ~ sex == 1, title_tabset = "Male", tabgroup = "happiness") %>%
  add_viz(x_var = "happy", title = "Happiness", 
          filter = ~ sex == 2, title_tabset = "Female", tabgroup = "happiness") %>%
  add_viz(x_var = "degree", title = "Education", 
          filter = ~ sex == 1, title_tabset = "Male", tabgroup = "education") %>%
  add_viz(x_var = "degree", title = "Education", 
          filter = ~ sex == 2, title_tabset = "Female", tabgroup = "education")

print(gender_comparison)
#> -- Content Collection ----------------------------------------------------------
#> 4 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] happiness (2 vizs)
#>   * [Viz] Happiness (bar) x=happy +filter
#>   * [Viz] Happiness (bar) x=happy +filter
#> > [Tab] education (2 vizs)
#>   * [Viz] Education (bar) x=degree +filter
#>   * [Viz] Education (bar) x=degree +filter
```

The `title_tabset` parameter creates a second level of tabs - perfect
for comparing the same chart across different subgroups!

## Batch Creation with add_vizzes()

Create multiple visualizations in one call:

``` r
vars <- c("degree", "race", "happy", "polviews")
labels <- c("Education", "Race", "Happiness", "Politics")

batch <- create_content(data = gss, type = "bar") %>%
  add_vizzes(x_var = vars, title = labels, tabgroup = "survey")

print(batch)
#> -- Content Collection ----------------------------------------------------------
#> 4 items | v data: 21788 rows x 8 cols
#> 
#> > [Tab] survey (4 vizs)
#>   * [Viz] Education (bar) x=degree
#>   * [Viz] Race (bar) x=race
#>   * [Viz] Happiness (bar) x=happy
#>   * [Viz] Politics (bar) x=polviews
```

## Survey Weights

Apply survey weights to all visualizations:

``` r
weighted <- create_content(data = gss, type = "bar", weight_var = "wtssall") %>%
  add_viz(x_var = "degree", title = "Weighted Education")

print(weighted)
#> -- Content Collection ----------------------------------------------------------
#> 1 items | v data: 21788 rows x 8 cols
#> 
#> * [Viz] Weighted Education (bar) x=degree
```

``` r
weighted %>% preview()
```

Preview

Weighted Education

## Previewing Content

Use
[`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
to see content before adding to a dashboard:

``` r
# Quick preview (fast, no Quarto)
content %>% preview()

# Full Quarto preview (slower, full features)
content %>% preview(quarto = TRUE)

# Save to specific location
content %>% preview(path = "my_preview.html")
```

## Next Steps

Once you have content, add it to a page:

``` r
create_page("Analysis", data = gss) %>%
  add_content(demographics) %>%
  add_content(attitudes)
```

See
[`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md)
for page creation details.
