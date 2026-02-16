# Create a metric card

Create a metric card

## Usage

``` r
html_metric(
  value,
  title,
  icon = NULL,
  color = NULL,
  subtitle = NULL,
  aria_label = NULL
)
```

## Arguments

- value:

  The metric value to display.

- title:

  Metric title.

- icon:

  Optional icon name (e.g. "mdi:account"). Uses the iconify web
  component.

- color:

  Optional accent color for left border.

- subtitle:

  Optional subtitle text.

- aria_label:

  Optional ARIA label for accessibility.

## Value

An htmltools tag object.
