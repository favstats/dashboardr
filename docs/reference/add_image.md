# Add image to content collection (pipeable)

Adds an image block to a content collection. Can be used standalone or
in a pipe. Supports viz_collection as first argument for seamless
piping.

## Usage

``` r
add_image(
  content_collection = NULL,
  src,
  alt = NULL,
  caption = NULL,
  width = NULL,
  height = NULL,
  align = c("center", "left", "right"),
  link = NULL,
  class = NULL
)
```

## Arguments

- content_collection:

  A content_collection, viz_collection, or NULL

- src:

  Image source path or URL

- alt:

  Alt text for the image

- caption:

  Optional caption text displayed below the image

- width:

  Optional width (e.g., "300px", "50%", "100%")

- height:

  Optional height (e.g., "200px")

- align:

  Image alignment: "left", "center", "right" (default: "center")

- link:

  Optional URL to link the image to

- class:

  Optional CSS class for custom styling

## Value

Updated content_collection object

## Examples

``` r
if (FALSE) { # \dontrun{
# Standalone
img <- add_image(src = "logo.png", alt = "Logo")

# Pipe with content
content <- create_content() %>%
  add_text("Welcome!") %>%
  add_image(src = "chart.png", alt = "Chart")

# Pipe directly from viz
content <- create_viz() %>%
  add_viz(type = "bar", x_var = "category") %>%
  add_image(src = "logo.png", alt = "Logo")
} # }
```
