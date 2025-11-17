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
  github = "https://github.com/favstats/dashboardr",
  linkedin = "https://linkedin.com/in/username",
  email = "user@example.com",
  website = "https://www.dedigiq.nl/",
  title = "Dashboard with Custom Navbar Links"
) %>%
  add_page(
    name = "Home",
    content = content,
    data = mtcars_data,
    is_landing_page = TRUE,
    icon = "ph:house-fill",
  ) %>%
  # Add a "Powered by" link with icon and text
  add_navbar_element(
    text = "nl",
    icon = "circle-flags:lang-nl",
    href = "https://example.com",
    align = "right"
  )

# Generate and render
generate_dashboard(
  proj = dashboard,
  render = TRUE,
  open = "browser"
)

