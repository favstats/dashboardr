# Preview a visualization or content collection

Renders a content/visualization collection to HTML and displays it in
the RStudio Viewer pane or browser. Useful for developing and testing
individual pieces of a dashboard without building the entire project.

## Usage

``` r
preview(
  collection,
  title = "Preview",
  open = TRUE,
  clean = FALSE,
  quarto = FALSE,
  theme = "cosmo",
  path = NULL
)
```

## Arguments

- collection:

  A content_collection or viz_collection object created with
  [`create_viz`](https://favstats.github.io/dashboardr/reference/create_viz.md)
  or
  [`create_content`](https://favstats.github.io/dashboardr/reference/create_content.md).
  Must have data attached (via `data` parameter in
  create_viz/create_content).

- title:

  Optional title for the preview document (default: "Preview")

- open:

  Whether to automatically open the result in viewer/browser (default:
  TRUE)

- clean:

  Whether to clean up temporary files after viewing (default: FALSE)

- quarto:

  Whether to use Quarto for rendering (default: FALSE). When FALSE
  (default), uses direct R rendering which is faster and doesn't require
  Quarto. When TRUE, creates a full Quarto document (useful for testing
  tabsets/icons).

- theme:

  Bootstrap theme for Quarto preview (default: "cosmo", only used when
  quarto=TRUE)

- path:

  Optional path to save the preview. If NULL (default), uses a temp
  directory. Can be a directory path (preview.html will be created
  inside) or a file path ending in .html.

## Value

Invisibly returns the path to the generated HTML file.

## Details

The preview function has two modes:

**Direct mode (quarto = FALSE, default):**

- Directly calls visualization functions with the attached data

- Wraps results in a simple HTML page using htmltools

- Fast and doesn't require Quarto installation

- Best for quick iteration during development

**Quarto mode (quarto = TRUE):**

- Creates a temporary Quarto document

- Renders with full Quarto features (tabsets, icons, theming)

- Requires Quarto to be installed

- Best for testing final dashboard appearance

## Examples

``` r
if (FALSE) { # \dontrun{
# Create and preview a single chart (fast direct mode)
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
  preview()

# Preview with Quarto for full features (required for tabsets!)
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", tabgroup = "MPG") %>%
  add_viz(type = "histogram", x_var = "hp", tabgroup = "HP") %>%
  preview(quarto = TRUE)

# Save preview to specific location
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg") %>%
  preview(path = "~/Desktop/my_preview.html")

# Preview without opening (just render)
html_path <- my_viz %>% preview(open = FALSE)
} # }
```
