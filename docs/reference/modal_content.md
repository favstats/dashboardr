# Create Modal Content Container

Creates a hidden div that contains the content to be displayed in a
modal. The content will be shown when a link with matching modal_id is
clicked.

## Usage

``` r
modal_content(modal_id, ..., title = NULL, image = NULL, text = NULL)
```

## Arguments

- modal_id:

  Unique ID for this modal content

- ...:

  Content to display in modal (images, text, HTML)

- title:

  Optional title to display at top of modal

- image:

  Optional image path or URL to display

- text:

  Optional text/HTML content to display below image

## Value

HTML div element

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple text modal
modal_content(
  modal_id = "info",
  title = "Information",
  text = "This is some important information."
)

# Modal with image and text
modal_content(
  modal_id = "chart1",
  title = "Sales Chart",
  image = "charts/sales.png",
  text = "This chart shows sales trends over the past year."
)

# Custom content
modal_content(
  modal_id = "custom",
  htmltools::tags$h2("Custom Title"),
  htmltools::tags$img(src = "image.jpg"),
  htmltools::tags$p("Description text"),
  htmltools::tags$ul(
    htmltools::tags$li("Point 1"),
    htmltools::tags$li("Point 2")
  )
)
} # }
```
