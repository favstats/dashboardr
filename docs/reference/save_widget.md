# Save widget as self-contained HTML

Save widget as self-contained HTML

## Usage

``` r
save_widget(widget, file, selfcontained = TRUE)
```

## Arguments

- widget:

  A dashboardr widget created with preview(output = "widget")

- file:

  Path to save the HTML file

- selfcontained:

  Whether to embed all dependencies (default: TRUE)

## Value

Invisibly returns the file path

## Examples

``` r
if (FALSE) { # \dontrun{
widget <- my_viz %>% preview(output = "widget")
save_widget(widget, "my_chart.html")
} # }
```
