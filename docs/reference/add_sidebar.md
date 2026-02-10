# Add a sidebar to a page

Creates a sidebar container that can hold inputs, text, images, and
other content. Use with end_sidebar() to close the sidebar and return to
main content.

## Usage

``` r
add_sidebar(
  content,
  width = "250px",
  position = c("left", "right"),
  title = NULL,
  background = NULL,
  padding = NULL,
  border = TRUE,
  open = TRUE,
  class = NULL
)
```

## Arguments

- content:

  Content collection or page_object

- width:

  CSS width for sidebar (default "250px")

- position:

  Sidebar position: "left" (default) or "right"

- title:

  Optional title displayed at top of sidebar

- background:

  Background color (CSS color value, e.g., "#f8f9fa", "white",
  "transparent")

- padding:

  Padding inside the sidebar (CSS value, e.g., "1rem", "20px")

- border:

  Show border on sidebar edge. TRUE (default), FALSE, or CSS border
  value

- open:

  Whether sidebar starts open (default TRUE). Set FALSE to start
  collapsed.

- class:

  Additional CSS class(es) to add to the sidebar

## Value

A sidebar_container for piping

## Details

Sidebars are collapsible vertical panels that appear alongside the main
content. They're ideal for placing filter controls, navigation, or
supplementary information.

## Important - Heading Levels

When using a sidebar, the page is rendered in Quarto dashboard format
where heading levels have special meaning:

- `##` creates new rows/columns (avoid in main content)

- `###` creates cards/sections (safe to use)

To avoid layout issues, use `###` headings or plain text in the main
content area after the sidebar. For advanced layouts, prefer explicit
[`add_layout_column()`](https://favstats.github.io/dashboardr/reference/add_layout_column.md)
/
[`add_layout_row()`](https://favstats.github.io/dashboardr/reference/add_layout_row.md)
APIs instead of heading-based layout shaping.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic sidebar with filters
content <- create_content() %>%
  add_sidebar(width = "300px") %>%
    add_text("### Filters") %>%
    add_input(input_id = "country", filter_var = "country", options = countries) %>%
    add_divider() %>%
    add_image(src = "logo.png") %>%
  end_sidebar() %>%
  add_viz(viz_bar(...))

# Right-positioned sidebar
content <- create_content() %>%
  add_sidebar(position = "right", title = "Options") %>%
    add_input(input_id = "metric", filter_var = "metric", type = "radio",
              options = c("Revenue", "Users", "Growth")) %>%
  end_sidebar() %>%
  add_viz(viz_timeline(...))

# Styled sidebar with custom background and no border
content <- create_content() %>%
  add_sidebar(width = "300px", background = "#f8f9fa", 
              padding = "1.5rem", border = FALSE) %>%
    add_text("### Settings") %>%
  end_sidebar()
} # }
```
