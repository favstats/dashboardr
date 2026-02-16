# Add a static ggplot2 plot to the dashboard

Embed a ggplot2 object directly into a dashboard page. The plot is
rendered as a static image via Quarto's built-in knitr graphics device.

## Usage

``` r
add_ggplot(
  content,
  plot,
  title = NULL,
  height = NULL,
  width = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection, page_object, or dashboard_project

- plot:

  A ggplot2 object (created with
  [`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html))

- title:

  Optional title displayed above the plot

- height:

  Optional figure height in inches (passed to knitr fig.height)

- width:

  Optional figure width in inches (passed to knitr fig.width)

- tabgroup:

  Optional tabgroup for organizing content

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content object
