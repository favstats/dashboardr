# Add Modal to Content Collection (Pipeable)

Adds a modal definition to your content collection. Use markdown links
with .modal-link class to trigger the modal.

## Usage

``` r
add_modal(
  x,
  modal_id,
  title = NULL,
  modal_content = NULL,
  image = NULL,
  image_width = "100%",
  ...
)
```

## Arguments

- modal_id:

  Unique ID for this modal (used in markdown link)

- title:

  Modal title (optional)

- modal_content:

  Text content - can be plain text, HTML, or data.frame

- image:

  Optional image URL or path

- image_width:

  Width of the image (default "100%"). Can be percentage ("70%") or
  pixels ("500px")

- ...:

  Additional content (data.frames will be converted to tables)

- content_collection:

  A content_collection or viz_collection to add modal to

## Value

Updated content_collection with modal added

## Examples

``` r
if (FALSE) { # \dontrun{
# Pipeable syntax (RECOMMENDED)
content <- create_content() %>%
  add_text("## Results") %>%
  add_text("[View details](#details){.modal-link}") %>%
  add_modal(
    modal_id = "details",
    title = "Full Results",
    modal_content = "Detailed analysis here..."
  )

# With image (custom width)
content <- create_viz() %>%
  add_viz(type = "column", x_var = "x", y_var = "y") %>%
  add_modal(
    modal_id = "chart-details",
    title = "Chart Details",
    image = "chart.png",
    image_width = "70%",  # Control image width
    modal_content = "This chart shows..."
  )

# With data.frame (auto-converts to table)
content <- create_content() %>%
  add_text("[View data](#data){.modal-link}") %>%
  add_modal(
    modal_id = "data",
    title = "Raw Data",
    modal_content = head(mtcars, 10)
  )

# Works with page objects too
page <- create_page("Results", data = my_data, type = "bar") %>%
  add_text("[View details](#info){.modal-link}") %>%
  add_modal(
    modal_id = "info",
    title = "More Info",
    modal_content = "Additional details..."
  )
} # }
```
