# End a sidebar

Closes a sidebar container and returns to the parent content collection.
Must be called after add_sidebar() and all content additions.

## Usage

``` r
end_sidebar(sidebar_container)
```

## Arguments

- sidebar_container:

  Sidebar container object created by add_sidebar()

## Value

The parent content_collection or page_object for further piping

## Examples

``` r
if (FALSE) { # \dontrun{
content <- create_content() %>%
  add_sidebar() %>%
    add_text("## Filters") %>%
    add_input(input_id = "filter1", filter_var = "var1", options = c("A", "B")) %>%
  end_sidebar() %>%
  add_text("Content after the sidebar...")
} # }
```
