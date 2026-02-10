# Add iframe

Add iframe

## Usage

``` r
add_iframe(
  content,
  src,
  height = "500px",
  width = "100%",
  style = NULL,
  tabgroup = NULL,
  show_when = NULL
)
```

## Arguments

- content:

  A content_collection object

- src:

  iframe source URL

- height:

  iframe height (default: "500px")

- width:

  iframe width (default: "100%")

- style:

  Optional inline CSS style string applied to the iframe element (e.g.,
  `"border: none; border-radius: 8px;"`). Useful for removing borders,
  adding shadows, or any custom styling.

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

Updated content_collection
