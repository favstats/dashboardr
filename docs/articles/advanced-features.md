# Advanced Features

This vignette covers advanced dashboardr features: interactive inputs,
data filtering, batch creation, survey weights, icons, and navigation
customization.

📂 **Data Setup** (click to expand)

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Load GSS data
data(gss_all)

# Latest wave only (for most examples)
gss <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews, wtssps) %>%
  filter(year == max(year, na.rm = TRUE)) %>%
  filter(
    happy %in% 1:3,
    polviews %in% 1:7,
    !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)
  ) %>%
  mutate(
    happy = droplevels(as_factor(happy)),
    polviews = droplevels(as_factor(polviews)),
    degree = droplevels(as_factor(degree)),
    sex = droplevels(as_factor(sex)),
    race = droplevels(as_factor(race))
  )
```

## 🔍 Filtering Data

Filters let you create multiple visualizations from the same dataset,
each showing a different subset. Instead of manually splitting your data
into separate data frames, you define the filter condition directly in
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md).

### Why Use Filters?

**Without filters**, you’d need to create separate datasets:

``` r
# Tedious approach - don't do this
males <- gss %>% filter(sex == 1)
females <- gss %>% filter(sex == 2)

create_content(data = males, type = "bar") %>%
  add_viz(x_var = "happy", title = "Male")

create_content(data = females, type = "bar") %>%
  add_viz(x_var = "happy", title = "Female")
```

**With filters**, one dataset serves all visualizations:

``` r
# Clean approach - do this!
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Male", filter = ~ sex == "male") %>%
  add_viz(x_var = "happy", title = "Female", filter = ~ sex == "female")
```

### Filter Syntax

Filters use R’s formula syntax with a tilde (`~`). The expression after
`~` is evaluated against your data:

| Filter | Meaning |
|----|----|
| `~ sex == 1` | Rows where sex equals 1 |
| `~ age > 30` | Rows where age is greater than 30 |
| `~ race == "white"` | Rows where race is “white” |
| `~ age >= 18 & age <= 35` | Rows where age is between 18 and 35 |
| `~ degree %in% c("bachelor", "graduate")` | Rows where degree is bachelor or graduate |

### Basic Example: Comparing Groups

Show the same variable for different subgroups side by side:

``` r
filtered <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Male", filter = ~ sex == "male", tabgroup = "Male") %>%
  add_viz(x_var = "happy", title = "Female", filter = ~ sex == "female", tabgroup = "Female")

print(filtered)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 2 items | ✔ data: 2997 rows x 8 cols
#> 
#> ❯ [Tab] Male (1 viz)
#>   • [Viz] Male (bar) x=happy +filter
#> ❯ [Tab] Female (1 viz)
#>   • [Viz] Female (bar) x=happy +filter
```

``` r
filtered %>% preview()
```

Preview

Male

Female

Male

Female

This creates two charts in the same tabgroup - one filtered to males,
one to females. Users can switch between them to compare happiness
distributions.

### Complex Filters: Multiple Conditions

Combine conditions with `&` (and) and `|` (or). Here we create one
tabgroup (“age_groups”) with three tabs, each showing happiness for a
different age range:

``` r
complex <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Young Adults (18-35)", 
          filter = ~ age >= 18 & age <= 35, tabgroup = "Youngsters") %>%
  add_viz(x_var = "happy", title = "Middle Age (36-55)", 
          filter = ~ age > 35 & age <= 55, tabgroup = "Middlers") %>%
  add_viz(x_var = "happy", title = "Older Adults (55+)", 
          filter = ~ age > 55, tabgroup = "Olders")

print(complex)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 3 items | ✔ data: 2997 rows x 8 cols
#> 
#> ❯ [Tab] Youngsters (1 viz)
#>   • [Viz] Young Adults (18-35) (bar) x=happy +filter
#> ❯ [Tab] Middlers (1 viz)
#>   • [Viz] Middle Age (36-55) (bar) x=happy +filter
#> ❯ [Tab] Olders (1 viz)
#>   • [Viz] Older Adults (55+) (bar) x=happy +filter
```

``` r
complex %>% preview()
#> Warning: There were 2 warnings in `dplyr::filter()`.
#> The first warning was:
#> ℹ In argument: `age >= 18 & age <= 35`.
#> Caused by warning in `Ops.factor()`:
#> ! '>=' not meaningful for factors
#> ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning.
#> Warning: There were 2 warnings in `dplyr::filter()`.
#> The first warning was:
#> ℹ In argument: `age > 35 & age <= 55`.
#> Caused by warning in `Ops.factor()`:
#> ! '>' not meaningful for factors
#> ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning.
#> Warning: There was 1 warning in `dplyr::filter()`.
#> ℹ In argument: `age > 55`.
#> Caused by warning in `Ops.factor()`:
#> ! '>' not meaningful for factors
```

Preview

Youngsters

Middlers

Olders

Young Adults (18-35)

Middle Age (36-55)

Older Adults (55+)

### Filters vs. group_var

**When to use `filter`:** - You want completely separate charts for each
group - Groups need different titles, settings, or tabgroups - You’re
comparing the same variable across subsets

**When to use `group_var`:** - You want grouped bars within a single
chart - Direct visual comparison in one view

``` r
# Using filter: separate charts per group
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", title = "Happiness (Male)", filter = ~ sex == "male", tabgroup = "separate") %>%
  add_viz(x_var = "happy", title = "Happiness (Female)", filter = ~ sex == "female", tabgroup = "separate") %>%
  preview()
```

Preview

separate

Happiness (Male)

Happiness (Female)

``` r
# Using group_var: one chart with grouped bars
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "happy", group_var = "sex", title = "Happiness by Sex") %>%
  preview()
```

Preview

Happiness by Sex

### Filter + title_tabset: Organized Comparisons

When you’re comparing the **same variable across multiple groups**,
`title_tabset` creates a second level of tabs:

- `tabgroup` = the **category** (e.g., “Happiness”, “Education”)
- `title_tabset` = the **variant** within that category (e.g., “Male”,
  “Female”)

``` r
gender_comparison <- create_content(data = gss, type = "bar") %>%
  # Happiness tabgroup with Male/Female sub-tabs
  add_viz(x_var = "happy", title = "Happiness", 
          filter = ~ sex == "male", title_tabset = "Male", tabgroup = "happiness") %>%
  add_viz(x_var = "happy", title = "Happiness", 
          filter = ~ sex == "female", title_tabset = "Female", tabgroup = "happiness") %>%
  # Education tabgroup with Male/Female sub-tabs
  add_viz(x_var = "degree", title = "Education", 
          filter = ~ sex == "male", title_tabset = "Male", tabgroup = "education") %>%
  add_viz(x_var = "degree", title = "Education", 
          filter = ~ sex == "female", title_tabset = "Female", tabgroup = "education")

print(gender_comparison)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 4 items | ✔ data: 2997 rows x 8 cols
#> 
#> ❯ [Tab] happiness (2 vizs)
#>   • [Viz] Happiness (bar) x=happy +filter
#>   • [Viz] Happiness (bar) x=happy +filter
#> ❯ [Tab] education (2 vizs)
#>   • [Viz] Education (bar) x=degree +filter
#>   • [Viz] Education (bar) x=degree +filter
```

``` r
gender_comparison %>% preview()
```

Preview

happiness

education

Male

Female

Happiness

Happiness

Male

Female

Education

Education

## 📚 Batch Creation with add_vizzes()

When you need to create many similar visualizations,
[`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
lets you do it in one call instead of repeating
[`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
multiple times.

### The Problem: Repetitive Code

``` r
# Tedious and error-prone
create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "survey") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "survey") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "survey") %>%
  add_viz(x_var = "polviews", title = "Politics", tabgroup = "survey")
```

### The Solution: Vector Parameters

With
[`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md),
pass vectors for the parameters that vary, and single values for
parameters that stay the same:

``` r
vars <- c("degree", "race", "happy", "polviews")
labels <- c("Education", "Race", "Happiness", "Politics")

batch <- create_content(data = gss, type = "bar") %>%
  add_vizzes(x_var = vars, title = labels, tabgroup = "survey")

print(batch)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 4 items | ✔ data: 2997 rows x 8 cols
#> 
#> ❯ [Tab] survey (4 vizs)
#>   • [Viz] Education (bar) x=degree
#>   • [Viz] Race (bar) x=race
#>   • [Viz] Happiness (bar) x=happy
#>   • [Viz] Politics (bar) x=polviews
```

``` r
batch %>% preview()
```

Preview

survey

Education

Race

Happiness

Politics

### How It Works

**Vector parameters** (vary per visualization): - `x_var`, `y_var`,
`stack_var`, `group_var`, `title`, `questions` - Must all have the same
length

**Scalar parameters** (shared across all): - `type`, `color_palette`,
`bar_type`, `horizontal`, `tabgroup` (if single value), etc. - Applied
to every visualization

### Different Tabgroups Per Viz

Pass `tabgroup` as a vector to put each visualization in a different
tab:

``` r
create_content(data = gss, type = "bar") %>%
  add_vizzes(
    x_var = c("degree", "happy", "polviews"),
    title = c("Education", "Happiness", "Politics"),
    tabgroup = c("demographics", "wellbeing", "attitudes")
  ) %>%
  preview()
```

Preview

demographics

wellbeing

attitudes

Education

Happiness

Politics

## 🎚️ Interactive Inputs

Interactive input widgets transform your dashboard from a static report
into an **exploratory data tool**. Users can filter data, adjust
parameters, and see visualizations update in real-time.

> **🔗 See it in action:** Check out the [Features
> Demo](https://favstats.github.io/dashboardr/live-demos/features/index.md)
> to try all input types with real GSS data!

### How Inputs Work

The input system connects **user controls** to **data columns**:

    User selects "Bachelor's" in dropdown
            ↓
    filter_var = "degree" tells dashboardr which column to filter
            ↓
    Data is filtered to rows where degree == "Bachelor's"
            ↓
    All visualizations on the page update automatically

**Basic pattern:**

``` r
create_page("Analysis", data = my_data, type = "bar") %>%
  add_input_row() %>%
    add_input(input_id = "edu", label = "Education", 
              filter_var = "degree", options_from = "degree") %>%
  end_input_row() %>%
  add_viz(x_var = "happy", title = "Happiness")  # Automatically filtered!
```

> **Note:** Inputs show as placeholders in
> [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md).
> They become fully interactive when you run
> `generate_dashboard(render = TRUE)` and view in a browser.

### Input Types

| Type              | Best For                             | Selection    |
|-------------------|--------------------------------------|--------------|
| `select_multiple` | Many categories (10+)                | Multiple     |
| `select_single`   | Many categories, pick one            | Single       |
| `checkbox`        | Few categories (3-6)                 | Multiple     |
| `radio`           | Mutually exclusive choices           | Single       |
| `slider`          | Numeric ranges or ordered categories | Single value |
| `switch`          | Toggle a series on/off               | Boolean      |

### Select Dropdowns

``` r
# Single selection
add_input(
  input_id = "metric",
  label = "Select Metric",
  type = "select_single",
  filter_var = "metric",
  options = c("Sales", "Revenue", "Profit"),
  default_selected = "Sales"
)

# Multiple selection
add_input(
  input_id = "countries",
  label = "Select Countries",
  type = "select_multiple",
  filter_var = "country",
  options_from = "country",  # Get options from data column
  placeholder = "Choose countries..."
)
```

#### Grouped Options

For long lists, organize options into groups:

``` r
# Create grouped options (named list)
countries_by_region <- list(
  "Europe" = c("Germany", "France", "UK", "Spain"),
  "Asia" = c("China", "Japan", "India", "Korea"),
  "Americas" = c("USA", "Canada", "Brazil", "Mexico")
)

add_input(
  input_id = "country",
  label = "Select Country",
  type = "select_multiple",
  filter_var = "country",
  options = countries_by_region,  # Grouped!
  default_selected = c("USA", "Germany")
)
```

### Checkbox & Radio Buttons

``` r
# Checkboxes - multiple selection, all visible
add_input(
  input_id = "race",
  label = "Race",
  type = "checkbox",
  filter_var = "race",
  options_from = "race",
  inline = TRUE  # Horizontal layout
)

# Radio buttons - single selection
add_input(
  input_id = "sex",
  label = "Gender",
  type = "radio",
  filter_var = "sex",
  options_from = "sex",
  inline = TRUE
)
```

### Sliders

Sliders work for numeric data or ordered categories:

``` r
# Numeric slider
add_input(
  input_id = "year",
  label = "Year",
  type = "slider",
  filter_var = "year",
  min = 2010,
  max = 2024,
  step = 1,
  value = 2020,
  show_value = TRUE
)

# Slider with custom labels (for ordered categories)
add_input(
  input_id = "decade",
  label = "Starting Decade",
  type = "slider",
  filter_var = "decade",
  min = 1,
  max = 6,
  step = 1,
  value = 1,
  labels = c("1970s", "1980s", "1990s", "2000s", "2010s", "2020s")
)
```

### Switch (Toggle Series)

Switches toggle a specific data series on/off. Unlike other inputs that
filter data, a switch with `toggle_series` controls visibility of a
named series in your chart:

``` r
add_input(
  input_id = "show_avg",
  label = "Show Global Average",
  type = "switch",
  filter_var = "country",
  toggle_series = "Global Average",  # Must match a value in your data
  value = TRUE,  # Start with it shown
  override = TRUE
)
```

### Input Layout

Use
[`add_input_row()`](https://favstats.github.io/dashboardr/reference/add_input_row.md)
to organize inputs horizontally:

``` r
create_page("Analysis", data = gss, type = "bar") %>%
  # First row: main filters
  add_input_row(style = "inline", align = "center") %>%
    add_input(input_id = "edu", label = "Education", 
              filter_var = "degree", options_from = "degree",
              width = "300px") %>%
    add_input(input_id = "race", label = "Race",
              type = "checkbox", filter_var = "race", 
              options_from = "race", inline = TRUE) %>%
  end_input_row() %>%
  # Second row: additional controls
  add_input_row() %>%
    add_input(input_id = "sex", label = "Gender",
              type = "radio", filter_var = "sex",
              options_from = "sex", inline = TRUE) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", title = "Happiness Distribution")
```

### Input Parameters Reference

| Parameter | Description | Used With |
|----|----|----|
| `input_id` | Unique identifier | All |
| `label` | Display label | All |
| `type` | Input type | All |
| `filter_var` | Column to filter | All |
| `options` | Manual list of options | select, checkbox, radio |
| `options_from` | Column to get options from | select, checkbox, radio |
| `default_selected` | Pre-selected values | select, checkbox, radio |
| `min`, `max`, `step` | Range settings | slider |
| `value` | Default value | slider, switch |
| `labels` | Custom labels for slider positions | slider |
| `toggle_series` | Series name to show/hide | switch |
| `override` | Override other filters | switch |
| `inline` | Horizontal layout | checkbox, radio |
| `width` | Input width (CSS) | select |
| `placeholder` | Placeholder text | select |
| `help` | Help text below input | All |

### Complete Example

Here’s a full working example with multiple input types:

``` r
library(dashboardr)
library(dplyr)
library(gssr)
library(haven)

# Prepare data
data(gss_all)
gss_inputs <- gss_all %>%
  select(year, age, sex, race, degree, happy, polviews) %>%
  filter(year >= 2010, happy %in% 1:3,
         !is.na(age), !is.na(sex), !is.na(race), !is.na(degree)) %>%
  mutate(across(c(happy, degree, sex, race), ~droplevels(as_factor(.))))

# Create page with inputs
inputs_page <- create_page("Explorer", data = gss_inputs, type = "bar") %>%
  add_text(
    "## GSS Data Explorer",
    "",
    "Filter the data using the controls below. All charts update automatically."
  ) %>%
  add_input_row() %>%
    add_input(
      input_id = "edu",
      label = "Education Level",
      type = "select_multiple",
      filter_var = "degree",
      options_from = "degree",
      width = "250px"
    ) %>%
    add_input(
      input_id = "race",
      label = "Race",
      type = "checkbox",
      filter_var = "race",
      options_from = "race",
      inline = TRUE
    ) %>%
  end_input_row() %>%
  add_input_row() %>%
    add_input(
      input_id = "sex",
      label = "Gender",
      type = "radio",
      filter_var = "sex",
      options_from = "sex",
      inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "Results") %>%
  add_viz(x_var = "polviews", title = "Political Views", tabgroup = "Results")

# Generate
create_dashboard(title = "GSS Explorer", output_dir = "gss_explorer") %>%
  add_pages(inputs_page) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

## ⚖️ Survey Weights

Survey data often requires weighting to produce
population-representative estimates. Without weights, your sample might
over- or under-represent certain groups.

### Why Use Weights?

**Unweighted data** shows your raw sample distribution - useful for
understanding who responded, but may not reflect the actual population.

**Weighted data** adjusts for sampling design and non-response, giving
you estimates that better represent the target population.

### Applying Weights

Set `weight_var` in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
to apply weights to all visualizations. The GSS provides several weight
variables; `wtssps` is the recommended post-stratification weight for
recent years:

``` r
# Compare unweighted vs weighted
unweighted <- create_content(data = gss, type = "bar") %>%
  add_viz(x_var = "degree", title = "Education (Unweighted)", tabgroup = "comparison")

weighted <- create_content(data = gss, type = "bar", weight_var = "wtssps") %>%
  add_viz(x_var = "degree", title = "Education (Weighted)", tabgroup = "comparison")

# Combine to see the difference
(unweighted + weighted) %>% preview()
```

Preview

comparison

Education (Unweighted)

Education (Weighted)

Notice how the distributions differ - the weighted version adjusts for
the fact that more educated people are typically overrepresented in
survey samples.

### Weight as a Default

When you set `weight_var` in
[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md),
it applies to **all** visualizations in that collection:

``` r
# All three charts use the same weight
weighted_collection <- create_content(data = gss, type = "bar", weight_var = "wtssps") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "weighted") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "weighted") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "weighted")

print(weighted_collection)
#> -- Content Collection ──────────────────────────────────────────────────────────
#> 3 items | ✔ data: 2997 rows x 8 cols
#> 
#> ❯ [Tab] weighted (3 vizs)
#>   • [Viz] Education (bar) x=degree
#>   • [Viz] Race (bar) x=race
#>   • [Viz] Happiness (bar) x=happy
```

``` r
weighted_collection %>% preview()
```

Preview

weighted

Education

Race

Happiness

## 🎯 Customizing Tooltips

dashboardr provides a flexible 3-tier system for customizing chart
tooltips, from quick tweaks to full control.

### Quick Customization (Tier 1)

Add prefix or suffix text to tooltip values:

``` r
viz_bar(data = gss, x_var = "degree", 
        tooltip_prefix = "Count: ",
        tooltip_suffix = " respondents")
```

### Format Strings (Tier 2)

Use format strings with `{placeholders}` for more control:

``` r
viz_bar(data = gss, x_var = "degree", 
        tooltip = "{category}: {value} people ({percent})")
```

Available placeholders vary by chart type:

| Placeholder | Description | Charts |
|----|----|----|
| `{value}` | Primary value | All |
| `{category}` | X-axis category | bar, histogram, stackedbar |
| `{x}`, `{y}` | Coordinates | scatter, heatmap |
| `{series}` | Series name | Grouped charts |
| `{percent}` | Percentage | Percent-type charts |
| [name](https://github.com/christopherkenny/name) | Point name | All |

### Full Control (Tier 3)

Use the
[`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md)
helper for complete customization including styling:

``` r
viz_bar(data = gss, x_var = "degree",
        tooltip = tooltip(
          format = "<b>{category}</b><br/>Count: {value}",
          backgroundColor = "#f8f9fa",
          borderColor = "#dee2e6",
          borderRadius = 8,
          style = list(fontSize = "14px")
        ))
```

The
[`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md)
function exposes all Highcharts tooltip options:

- `format` - Format string with {placeholders}
- `shared` - Share tooltip across series (TRUE/FALSE)
- `backgroundColor`, `borderColor`, `borderRadius` - Visual styling
- `style` - CSS styles as a named list
- `header` - Header format (use FALSE to hide)
- `enabled` - Enable/disable tooltips entirely

All chart functions
([`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md),
[`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md),
[`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md),
etc.) support the same tooltip parameters for consistent behavior across
your dashboard.

## 🎨 Icons

dashboardr uses [Iconify](https://icon-sets.iconify.design/) for
**200,000+ icons** from 100+ icon sets.

### Icon Format

Icons use the format `set:icon-name`:

``` r
icon = "ph:house-fill"       # Phosphor Icons
icon = "mdi:chart-line"      # Material Design Icons
icon = "bi:graph-up"         # Bootstrap Icons
```

### Popular Icon Sets

| Set | Prefix | Style | Examples |
|----|----|----|----|
| [Phosphor](https://phosphoricons.com/) | `ph:` | Clean, modern | `ph:chart-line`, `ph:users-fill`, `ph:gear-fill` |
| [Material Design](https://icon-sets.iconify.design/mdi/) | `mdi:` | Google style | `mdi:chart-bar`, `mdi:account-group` |
| [Bootstrap](https://icons.getbootstrap.com/) | `bi:` | Bootstrap style | `bi:graph-up`, `bi:people-fill` |
| [Font Awesome](https://fontawesome.com/) | `fa:` | Classic | `fa:chart-bar`, `fa:users` |

### Page Icons

Add icons to pages in the navbar:

``` r
create_page("Home", icon = "ph:house-fill")
create_page("Analysis", icon = "ph:chart-bar-fill")
create_page("Settings", icon = "ph:gear-fill", navbar_align = "right")
```

### Tabgroup Icons

Add icons to tab labels using Quarto shortcodes:

``` r
viz <- create_content(type = "bar") %>%
  add_viz(x_var = "age", tabgroup = "demographics") %>%
  add_viz(x_var = "income", tabgroup = "financial") %>%
  set_tabgroup_labels(
    demographics = "{{< iconify ph:users-fill >}} Demographics",
    financial = "{{< iconify ph:currency-dollar >}} Financial"
  )
```

### Icons in Text

Use Quarto shortcodes in markdown text:

``` r
add_text(
  "## Features {{< iconify ph:sparkle-fill >}}",
  "",
  "- {{< iconify ph:check-circle-fill >}} Easy to use",
  "- {{< iconify ph:lightning-fill >}} Fast performance",
  "- {{< iconify ph:heart-fill >}} Beautiful design"
)
```

### Finding Icons

1.  Visit [Iconify Icon Sets](https://icon-sets.iconify.design/)
2.  Search for what you need (e.g., “chart”, “user”, “settings”)
3.  Click an icon to see its name
4.  Use it as `set:icon-name`

**Common choices by purpose:**

| Purpose            | Recommended Icons                                |
|--------------------|--------------------------------------------------|
| Home/Landing       | `ph:house-fill`, `ph:home`                       |
| Charts/Analysis    | `ph:chart-line`, `ph:chart-bar-fill`, `ph:graph` |
| Users/Demographics | `ph:users-fill`, `ph:user-circle`                |
| Settings/Config    | `ph:gear-fill`, `ph:sliders`                     |
| Info/About         | `ph:info-fill`, `ph:question`                    |
| Download/Export    | `ph:download-simple`, `ph:export`                |
| Time/Trends        | `ph:clock`, `ph:trend-up`                        |

### Best Practice: Consistency

Pick one icon set and stick with it throughout your dashboard:

``` r
# Good: All Phosphor icons
create_page("Home", icon = "ph:house-fill")
create_page("Analysis", icon = "ph:chart-line")
create_page("About", icon = "ph:info-fill")

# Avoid: Mixed icon sets (inconsistent visual style)
create_page("Home", icon = "ph:house-fill")
create_page("Analysis", icon = "bi:graph-up")     # Different set
create_page("About", icon = "mdi:information")    # Another set
```

## 🧭 Navbar Customization

The navbar is the main navigation bar at the top of your dashboard. You
can customize it extensively to add dropdown menus, external links, and
control how pages are arranged.

### Dropdown Menus

Dropdown menus let you organize related links or pages under a single
menu item. This is useful when you have many pages or want to include
quick links to downloads, documentation, or related resources.

Use `navbar_left` to place menus on the left side of the navbar, or
`navbar_right` for the right side. Each menu item is a list with:

- **`text`**: The label shown in the navbar
- **`menu`**: A list of sub-items, each with `text` and `href`
- **`"---"`**: Creates a visual divider between menu items

``` r
create_dashboard(
  title = "My Dashboard",
  output_dir = "output",
  navbar_left = list(
    list(
      text = "Analysis",
      menu = list(
        list(text = "Demographics", href = "demographics.html"),
        list(text = "Trends", href = "trends.html"),
        list(text = "---"),  # Divider
        list(text = "Download Data", href = "data.csv")
      )
    )
  )
)
```

### External Links

Add links to external resources like GitHub repositories, documentation
sites, or data sources. These appear as clickable items in the navbar
and open in a new tab when clicked.

Each link can include:

- **`text`**: The visible label
- **`href`**: The URL (can be internal `.html` pages or external
  `https://` URLs)
- **`icon`**: An optional Iconify icon code (see the Icons section for
  available icons)

``` r
create_dashboard(
  title = "My Dashboard",
  output_dir = "output",
  navbar_right = list(
    list(text = "GitHub", href = "https://github.com/org/repo", icon = "ph:github-logo"),
    list(text = "Documentation", href = "https://docs.example.com")
  )
)
```

### Sidebar Navigation

For dashboards with many pages (10+), consider using sidebar navigation
instead of the top navbar. The sidebar provides more vertical space for
page links and can include hierarchical organization.

Available sidebar options:

| Parameter | Description |
|----|----|
| `sidebar = TRUE` | Enable sidebar navigation |
| `sidebar_title` | Title shown at the top of the sidebar |
| `sidebar_style` | `"floating"` (overlays content) or `"docked"` (pushes content) |

``` r
create_dashboard(
  title = "My Dashboard",
  output_dir = "output",
  sidebar = TRUE,
  sidebar_title = "Navigation",
  sidebar_style = "floating"  # or "docked"
)
```

> **Tip:** Sidebar navigation works especially well on mobile devices
> where horizontal navbar space is limited.

### Page Alignment

By default, all pages appear on the left side of the navbar. You can
move specific pages to the right side using `navbar_align = "right"`.
This is a common pattern for utility pages like “About”, “Settings”, or
“Help” that users access less frequently.

``` r
home <- create_page("Home", icon = "ph:house-fill")
analysis <- create_page("Analysis", icon = "ph:chart-bar-fill")
about <- create_page("About", icon = "ph:info-fill", navbar_align = "right")
settings <- create_page("Settings", icon = "ph:gear-fill", navbar_align = "right")

create_dashboard(title = "My Dashboard") %>%
  add_pages(home, analysis, about, settings)
```

The resulting navbar will show: `Home | Analysis` on the left, and
`About | Settings` on the right.

## 🎨 Tab Styling

Customize the appearance of tabs within your pages using `tabset_theme`
and `tabset_colors`. Tab styling affects how tabbed content (created via
`tabgroup`) appears to users.

### Available Themes

Four built-in themes provide different visual styles for your tabs. Each
theme changes the shape, spacing, and general appearance of the tab
buttons.

| Theme | Description | Best For |
|----|----|----|
| `"default"` | Standard Quarto tabs with underline indicator | General use, compatibility |
| `"modern"` | Clean look with subtle backgrounds | Professional dashboards |
| `"pills"` | Rounded pill-shaped buttons | Friendly, approachable interfaces |
| `"minimal"` | Subtle text-only with hover effects | Content-focused designs |

``` r
# Modern theme
modern_page <- create_page("Modern", data = gss, type = "bar", tabset_theme = "modern") %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "A") %>%
  add_viz(x_var = "race", title = "Race", tabgroup = "B")

print(modern_page)
#> -- Page: Modern ─────────────────────────────────────────────────
#> ✔ data: 2997 rows x 8 cols | default: bar 
#> 2 items
#> 
#> ❯ [Tab] A (1 viz)
#>   • [Viz] Education (bar) x=degree
#> ❯ [Tab] B (1 viz)
#>   • [Viz] Race (bar) x=race
```

> **Note:** Tab themes are fully rendered in the generated dashboard.
> Use `generate_dashboard(render = TRUE)` to see the complete styling.

### Custom Colors

Beyond the built-in themes, you can fully customize tab colors to match
your brand or create unique visual designs. Use `tabset_colors` to
define a custom color scheme.

The `tabset_colors` parameter accepts a named list with the following
color options:

| Parameter       | Description                          | Default         |
|-----------------|--------------------------------------|-----------------|
| `active_bg`     | Background color of the selected tab | Theme-dependent |
| `active_text`   | Text color of the selected tab       | Theme-dependent |
| `inactive_bg`   | Background color of unselected tabs  | Transparent     |
| `inactive_text` | Text color of unselected tabs        | Gray            |
| `hover_bg`      | Background color when hovering       | Light gray      |

All colors can be specified as hex codes (e.g., `"#3498DB"`), RGB values
(e.g., `"rgb(52, 152, 219)"`), or named colors (e.g., `"steelblue"`).

``` r
# Blue theme
blue_tabs <- create_page(
  "Blue Theme",
  data = gss,
  type = "bar",
  tabset_theme = "pills",
  tabset_colors = list(
    active_bg = "#3498DB",      # Active tab background
    active_text = "#FFFFFF",    # Active tab text
    inactive_bg = "#ECF0F1",    # Inactive tab background
    inactive_text = "#7F8C8D",  # Inactive tab text
    hover_bg = "#BDC3C7"        # Hover background
  )
) %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "demo") %>%
  add_viz(x_var = "happy", title = "Happiness", tabgroup = "attitudes")

print(blue_tabs)
#> -- Page: Blue Theme ─────────────────────────────────────────────
#> ✔ data: 2997 rows x 8 cols | default: bar 
#> 2 items
#> 
#> ❯ [Tab] demo (1 viz)
#>   • [Viz] Education (bar) x=degree
#> ❯ [Tab] attitudes (1 viz)
#>   • [Viz] Happiness (bar) x=happy
```

> **Note:** Custom tab colors (like `tabset_colors`) are only visible in
> the generated dashboard, not in
> [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md).

### Example: Corporate Theme

Match your organization’s brand colors for a cohesive, professional
look. Start with your primary brand color for `active_bg`, then derive
the other colors from it (lighter versions for `inactive_bg` and
`hover_bg`):

``` r
# Corporate red theme
corporate <- create_page(
  "Corporate",
  data = gss,
  type = "bar",
  tabset_theme = "modern",
  tabset_colors = list(
    active_bg = "#C0392B",      # Brand red
    active_text = "#FFFFFF",
    inactive_bg = "#FADBD8",    # Light red
    inactive_text = "#922B21",
    hover_bg = "#E6B0AA"
  )
) %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Q1") %>%
  add_viz(x_var = "race", title = "Demographics", tabgroup = "Q2") %>%
  add_viz(x_var = "happy", title = "Satisfaction", tabgroup = "Q3")

print(corporate)
#> -- Page: Corporate ──────────────────────────────────────────────
#> ✔ data: 2997 rows x 8 cols | default: bar 
#> 3 items
#> 
#> ❯ [Tab] Q1 (1 viz)
#>   • [Viz] Education (bar) x=degree
#> ❯ [Tab] Q2 (1 viz)
#>   • [Viz] Demographics (bar) x=race
#> ❯ [Tab] Q3 (1 viz)
#>   • [Viz] Satisfaction (bar) x=happy
```

### Example: Dark Theme

For dashboards with dark backgrounds, use high-contrast colors to ensure
readability. The `pills` theme works particularly well with dark designs
because the rounded buttons create clear visual boundaries:

``` r
# Dark theme
dark_tabs <- create_page(
  "Dark Theme",
  data = gss,
  type = "bar",
  tabset_theme = "pills",
  tabset_colors = list(
    active_bg = "#2ECC71",      # Bright green accent
    active_text = "#1A1A1A",
    inactive_bg = "#2C3E50",    # Dark background
    inactive_text = "#95A5A6",  # Muted text
    hover_bg = "#34495E"
  )
) %>%
  add_viz(x_var = "degree", title = "Education", tabgroup = "Data") %>%
  add_viz(x_var = "happy", title = "Results", tabgroup = "Analysis")

print(dark_tabs)
#> -- Page: Dark Theme ─────────────────────────────────────────────
#> ✔ data: 2997 rows x 8 cols | default: bar 
#> 2 items
#> 
#> ❯ [Tab] Data (1 viz)
#>   • [Viz] Education (bar) x=degree
#> ❯ [Tab] Analysis (1 viz)
#>   • [Viz] Results (bar) x=happy
```

> **Note:** Tab styling (custom colors, themes) is fully visible only in
> the generated dashboard. The
> [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
> function shows a simplified version without custom tab colors.

## ⚡ Lazy Loading

> **Warning:** Lazy loading is currently **experimental** and may not
> work reliably in all browsers or configurations. Use with caution in
> production dashboards.

Lazy loading is a performance optimization technique that defers
rendering charts and tab content until they’re actually needed. Instead
of loading everything when the page opens, content loads as the user
scrolls to it or clicks on a tab. This can significantly improve initial
page load times for dashboards with many visualizations.

### When to Use Lazy Loading

Consider lazy loading if your dashboard has:

- **Many visualizations** (20+) that slow down initial page load
- **Multiple tabs** where users typically only view a few
- **Heavy charts** like maps or complex scatter plots

### Enable Lazy Loading

| Parameter | Description | Default |
|----|----|----|
| `lazy_load_charts` | Load charts only when scrolled into view | `FALSE` |
| `lazy_load_margin` | Distance from viewport to start loading (CSS units) | `"200px"` |
| `lazy_load_tabs` | Load tab content only when tab is clicked | `FALSE` |

``` r
create_page(
  "Large Analysis",
  data = data,
  lazy_load_charts = TRUE,     # Load charts as user scrolls
  lazy_load_margin = "300px",  # Start loading 300px before visible
  lazy_load_tabs = TRUE        # Load tab content when clicked
)
```

### When to Use

### Loading Overlays

Loading overlays provide visual feedback while content renders. They
display a spinner or animation that disappears once the page is ready,
creating a polished user experience.

> **See it in action:** Check out the [Features
> Demo](https://favstats.github.io/dashboardr/live-demos/features/index.md)
> to experience loading overlays - navigate to the “Loading Overlay”
> page and reload to see the effect.

| Parameter | Description | Options |
|----|----|----|
| `overlay` | Enable loading overlay | `TRUE` / `FALSE` |
| `overlay_theme` | Visual style of the overlay | `"light"`, `"dark"`, `"glass"`, `"accent"` |
| `overlay_text` | Custom message to display | Any string |
| `overlay_duration` | Minimum display time (milliseconds) | e.g., `1500` |

``` r
create_page(
  "Analysis",
  data = large_dataset,
  overlay = TRUE,
  overlay_theme = "glass",      # Frosted glass effect
  overlay_text = "Loading analysis...",
  overlay_duration = 1500       # Show for at least 1.5 seconds
)
```

## 🏷️ Powered by dashboardr Branding

Add a subtle “Powered by dashboardr” badge to your dashboard footer.
This is entirely optional but helps spread the word about dashboardr!

``` r
dashboard <- create_dashboard("my_project", "My Dashboard") %>%
  add_pages(home, analysis, about) %>%
  add_powered_by_dashboardr()
```

### Style Options

Choose a style that fits your dashboard’s aesthetic:

| Style       | Description                             |
|-------------|-----------------------------------------|
| `"default"` | Subtle text with the dashboardr logo    |
| `"minimal"` | Just text, no logo - most unobtrusive   |
| `"badge"`   | Rounded background badge - more visible |

``` r
# Default - subtle text with logo
dashboard %>% add_powered_by_dashboardr(style = "default")

# Minimal - just text, no logo
dashboard %>% add_powered_by_dashboardr(style = "minimal")

# Badge - rounded background badge
dashboard %>% add_powered_by_dashboardr(style = "badge")
```

### Size Options

Control how prominent the branding appears:

``` r
# Small (default) - unobtrusive
dashboard %>% add_powered_by_dashboardr(size = "small")

# Medium - more visible
dashboard %>% add_powered_by_dashboardr(size = "medium")

# Large - prominent
dashboard %>% add_powered_by_dashboardr(size = "large")
```

### Combining with Custom Footer

The branding automatically positions to the right side of the footer,
leaving room for your own text on the left:

``` r
create_dashboard(
  "my_project",
  title = "My Dashboard",
  page_footer = "© 2025 My Organization"
) %>%
  add_powered_by_dashboardr()
# Result: Your text on left, dashboardr badge on right
```

## Related Vignettes

- [`vignette("getting-started")`](https://favstats.github.io/dashboardr/articles/getting-started.md) -
  Quick overview
- [`vignette("content-collections")`](https://favstats.github.io/dashboardr/articles/content-collections.md) -
  Content collections deep dive
- [`vignette("pages")`](https://favstats.github.io/dashboardr/articles/pages.md) -
  Pages deep dive
- [`vignette("dashboards")`](https://favstats.github.io/dashboardr/articles/dashboards.md) -
  Dashboard creation
