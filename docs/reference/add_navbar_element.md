# Add a custom navbar element to dashboard

Adds a custom link or element to the navbar. Can include text, icons,
and external links. Elements are added to the right side of the navbar
by default but can be positioned left.

## Usage

``` r
add_navbar_element(
  proj,
  text = NULL,
  icon = NULL,
  href,
  align = c("right", "left")
)
```

## Arguments

- proj:

  Dashboard project object from create_dashboard()

- text:

  Display text for the element (optional if icon provided)

- icon:

  Iconify icon (e.g., "ph:lightning-fill") (optional)

- href:

  Hyperlink URL (required)

- align:

  Position in navbar: "left" or "right" (default: "right")

## Value

Modified dashboard project object

## Examples

``` r
if (FALSE) { # \dontrun{
# Add a "Powered by X" link with icon
dashboard <- create_dashboard("my_dashboard", "My Dashboard") %>%
  add_page("Home", text = "# Welcome", is_landing_page = TRUE) %>%
  add_navbar_element(
    text = "Powered by X",
    icon = "ph:lightning-fill",
    href = "https://example.com",
    align = "right"
  )

# Add multiple elements
dashboard <- create_dashboard("my_dashboard", "Dashboard") %>%
  add_page("Home", ...) %>%
  add_navbar_element(
    text = "Documentation",
    icon = "ph:book-open",
    href = "https://docs.example.com"
  ) %>%
  add_navbar_element(
    text = "Sponsor",
    icon = "ph:star-fill",
    href = "https://sponsor.com"
  )

# Icon only (no text)
dashboard %>%
  add_navbar_element(
    icon = "ph:github-logo",
    href = "https://github.com/user/repo"
  )
} # }
```
