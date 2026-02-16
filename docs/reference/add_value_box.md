# Add a custom styled value box

Creates a modern value box with optional logo, custom background color,
and optional collapsible description. Perfect for displaying KPIs and
metrics with additional context.

## Usage

``` r
add_value_box(
  content,
  title,
  value,
  logo_url = NULL,
  logo_text = NULL,
  bg_color = "#2c3e50",
  description = NULL,
  description_title = "About this source",
  tabgroup = NULL,
  show_when = NULL,
  aria_label = NULL
)
```

## Arguments

- content:

  Content collection object or value_box_row_container

- title:

  Box title (small text above value)

- value:

  Main value to display (large text)

- logo_url:

  Optional URL or path to logo image

- logo_text:

  Optional text to display as logo (if no logo_url)

- bg_color:

  Background color (hex code), default "#2c3e50"

- description:

  Optional collapsible description text (markdown supported)

- description_title:

  Title for collapsible section, default "About this source"

- tabgroup:

  Optional tabgroup for organizing content (character vector for nested
  tabs)

- show_when:

  One-sided formula controlling conditional display based on input
  values.

- aria_label:

  Optional ARIA label for accessibility.

## Details

Can be used standalone or within a value box row:

- Standalone: create_content() %\>% add_value_box(...)

- In row: create_content() %\>% add_value_box_row() %\>%
  add_value_box(...) %\>% add_value_box(...)

## Examples

``` r
if (FALSE) { # \dontrun{
# Standalone value box
content <- create_content() %>%
  add_value_box(
    title = "Total Revenue",
    value = "EUR 1,234,567",
    logo_text = "$",
    bg_color = "#2E86AB"
  )

# Row of value boxes (pipeable!)
content <- create_content() %>%
  add_value_box_row() %>%
    add_value_box(title = "Users", value = "1,234") %>%
    add_value_box(title = "Revenue", value = "EUR 56K")
} # }
```
