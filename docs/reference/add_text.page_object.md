# Add text to a page

Add markdown text content directly to a page object.

## Usage

``` r
add_text.page_object(page, text, ..., tabgroup = NULL, show_when = NULL)
```

## Arguments

- page:

  A page_object created by create_page()

- text:

  First line of text

- ...:

  Additional text lines

- tabgroup:

  Optional tabgroup for the text

- show_when:

  One-sided formula controlling conditional display based on input
  values.

## Value

The updated page_object
