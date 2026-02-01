# Add a callout to a page

Add callout boxes directly to a page object.

## Usage

``` r
add_callout.page_object(
  page,
  text,
  type = "note",
  title = NULL,
  tabgroup = NULL
)
```

## Arguments

- page:

  A page_object created by create_page()

- text:

  Callout text content

- type:

  Callout type: "note", "tip", "warning", "important", "caution"

- title:

  Optional callout title

- tabgroup:

  Optional tabgroup

## Value

The updated page_object
