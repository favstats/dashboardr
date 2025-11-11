# Test add_navbar_element() function
devtools::load_all()

# Create sample data
mtcars_data <- mtcars

# Create simple content
content <- create_viz(
  type = "histogram",
  color_palette = c("#3498DB"),
  bins = 20
) %>%
  add_viz(
    x_var = "mpg",
    title = "Miles Per Gallon Distribution"
  )

# Create dashboard with custom navbar elements
dashboard <- create_dashboard(
  output_dir = "test_navbar_element",
  title = "Dashboard with Custom Navbar Links"
) %>%
  add_page(
    name = "Home",
    content = content,
    data = mtcars_data,
    is_landing_page = TRUE,
    icon = "ph:house-fill"
  ) %>%
  # Add a "Powered by" link with icon and text
  add_navbar_element(
    text = "Powered by Acme Corp",
    icon = "ph:lightning-fill",
    href = "https://example.com",
    align = "right"
  ) %>%
  # Add a documentation link
  add_navbar_element(
    text = "Documentation",
    icon = "ph:book-open-fill",
    href = "https://docs.example.com",
    align = "right"
  ) %>%
  # Add an icon-only GitHub link
  add_navbar_element(
    icon = "ph:github-logo",
    href = "https://github.com",
    align = "right"
  )

# Generate and render
generate_dashboard(
  proj = dashboard,
  render = TRUE,
  open = "browser"
)

