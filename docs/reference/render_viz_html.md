# Render a viz result as raw HTML

In `results='asis'` chunks (e.g. when using
[`show_when_open`](https://favstats.github.io/dashboardr/reference/show_when_open.md)),
bare htmlwidget objects are NOT rendered by knitr. This helper converts
the widget (or tagList from `.embed_cross_tab`) to HTML and
[`cat()`](https://rdrr.io/r/base/cat.html)s it so it appears in the
output.

## Usage

``` r
render_viz_html(result)
```

## Arguments

- result:

  A highcharter object, htmlwidget, shiny.tag, or shiny.tag.list

## Value

Called for its side-effect ([`cat()`](https://rdrr.io/r/base/cat.html)).

## Examples

``` r
if (FALSE) { # \dontrun{
# In a QMD chunk with results='asis':
show_when_open('{"var":"year","op":"eq","val":"2024"}')
result <- viz_bar(data = df, x_var = "category")
render_viz_html(result)
show_when_close()
} # }
```
