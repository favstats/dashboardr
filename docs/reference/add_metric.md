# Add a metric/value box

Add a metric/value box

## Usage

``` r
add_metric(
  content,
  value,
  title,
  icon = NULL,
  color = NULL,
  subtitle = NULL,
  tabgroup = NULL,
  show_when = NULL,
  aria_label = NULL
)
```

## Arguments

- content:

  Content collection object

- value:

  The metric value

- title:

  Metric title

- icon:

  Optional icon

- color:

  Optional color theme

- subtitle:

  Optional subtitle text

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

- aria_label:

  Optional ARIA label for accessibility.
