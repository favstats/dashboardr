# Create a loading overlay for a dashboard page

Creates an animated loading overlay that appears when the page loads and
automatically fades out after a specified duration. Useful for providing
visual feedback while charts and visualizations are rendering.

## Usage

``` r
create_loading_overlay(
  text = "Loading",
  timeout_ms = 2200,
  theme = c("light", "glass", "dark", "accent")
)
```

## Arguments

- text:

  Text to display in the loading overlay (default: "Loading")

- timeout_ms:

  Duration in milliseconds before the overlay hides (default: 2200)

- theme:

  Visual theme for the overlay. One of:

  - `"light"` - Clean white overlay with subtle shadow

  - `"glass"` - Glassmorphic semi-transparent overlay

  - `"dark"` - Dark gradient overlay

  - `"accent"` - Light overlay with blue accents

## Value

An htmltools tag object containing the overlay HTML, CSS, and JavaScript

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Quarto document R chunk:
dashboardr::create_loading_overlay("Loading Dashboard...", 2000, "glass")
} # }
```
