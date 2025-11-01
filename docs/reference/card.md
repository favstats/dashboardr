# Create a Bootstrap card component

Helper function to create Bootstrap card components for displaying
content in a structured way. Useful for author profiles, feature
highlights, or any content that benefits from card layout.

## Usage

``` r
card(
  content,
  title = NULL,
  image = NULL,
  image_alt = NULL,
  footer = NULL,
  class = NULL,
  style = NULL
)
```

## Arguments

- content:

  Card content (text, HTML, or other elements)

- title:

  Optional card title

- image:

  Optional image URL or path

- image_alt:

  Alt text for the image

- footer:

  Optional card footer content

- class:

  Additional CSS classes for the card

- style:

  Additional inline styles for the card

## Value

HTML div element with Bootstrap card classes

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple text card
card("This is a simple card with just text content")

# Card with title and image
card(
  content = "This is the card body content",
  title = "Card Title",
  image = "https://example.com/image.jpg",
  image_alt = "Description of image"
)

# Author card
card(
  content = "Dr. Jane Smith is a researcher specializing in data science and visualization.",
  title = "Dr. Jane Smith",
  image = "https://example.com/jane.jpg",
  footer = "Website: janesmith.com"
)
} # }
```
