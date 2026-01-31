# Preview any dashboardr object

Universal preview function that renders any dashboardr object to HTML
and displays it in the RStudio Viewer pane or browser. Supports
dashboard_project, page_object, content_collection, viz_collection, and
individual content_block objects. Useful for developing and testing
dashboards without building the entire project.

## Usage

``` r
preview(
  collection,
  title = "Preview",
  open = TRUE,
  clean = FALSE,
  quarto = FALSE,
  theme = "cosmo",
  path = NULL,
  page = NULL,
  debug = FALSE,
  output = c("viewer", "widget")
)
```

## Arguments

- collection:

  A dashboardr object to preview. Can be any of:

  - `dashboard_project` - previews all pages with full styling

  - `page_object` - previews a single page

  - `content_collection` or `viz_collection` - previews
    content/visualizations

  - `content_block` - previews a single content block (text, callout,
    etc.)

  For collections with visualizations, data must be attached via the
  `data` parameter in
  [`create_viz()`](https://favstats.github.io/dashboardr/reference/create_viz.md)/[`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md).

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

- page:

  Optional page name to preview (only used for dashboard_project
  objects). When NULL, previews all pages. When specified, previews only
  the named page.

- debug:

  Whether to show debug messages like file paths (default: FALSE).

- output:

  Output mode: "viewer" (default) opens in RStudio viewer/browser,
  "widget" returns an htmltools widget that can be saved as
  self-contained HTML with
  [`save_widget()`](https://favstats.github.io/dashboardr/reference/save_widget.md)
  or embedded in R Markdown/Quarto documents.

## Value

For output="viewer": invisibly returns the path to the generated HTML
file. For output="widget": returns a dashboardr_widget object that can
be saved or embedded.

## Details

The preview function has two modes:

**Direct mode (quarto = FALSE, default):**

- Directly calls visualization functions with the attached data

- Renders all content blocks (text, callouts, cards, tables, etc.)

- Includes interactive elements (inputs, modals) with CDN dependencies

- Wraps results in a styled HTML page using htmltools

- Fast and doesn't require Quarto installation

- Best for quick iteration during development

**Quarto mode (quarto = TRUE):**

- Creates a temporary Quarto document

- Renders with full Quarto features (tabsets, icons, theming)

- Applies dashboard styling (navbar colors, fonts, tabset themes)

- Requires Quarto to be installed

- Best for testing final dashboard appearance

**Supported content types:** Text/display: text, html, quote, badge,
metric Layout: divider, spacer, card, accordion Media: image, video,
iframe Tables: gt, reactable, DT, table Interactive: input, input_row,
modal Value boxes: value_box, value_box_row

## Examples

``` r
if (FALSE) { # \dontrun{
# Preview a dashboard project
my_dashboard %>% preview()
my_dashboard %>% preview(page = "Analysis")  # Preview specific page
my_dashboard %>% preview(quarto = TRUE)  # Full Quarto rendering

# Preview a page object
create_page("Analysis", data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg") %>%
  preview()

# Preview a visualization collection
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", title = "MPG Distribution") %>%
  preview()

# Preview with Quarto for full features (required for tabsets!)
create_viz(data = mtcars) %>%
  add_viz(type = "histogram", x_var = "mpg", tabgroup = "MPG") %>%
  add_viz(type = "histogram", x_var = "hp", tabgroup = "HP") %>%
  preview(quarto = TRUE)

# Preview content blocks
create_content() %>%
  add_text("# Hello World") %>%
  add_callout("Important note", type = "tip") %>%
  preview()

# Save preview to specific location
my_viz %>% preview(path = "~/Desktop/my_preview.html")

# Preview without opening (just render)
html_path <- my_viz %>% preview(open = FALSE)

# Return as widget (for embedding in R Markdown or saving as self-contained HTML)
widget <- my_viz %>% preview(output = "widget")
htmltools::save_html(widget, "my_chart.html", selfcontained = TRUE)

# In R Markdown/Quarto, widgets display inline automatically
my_viz %>% preview(output = "widget")
} # }
```
