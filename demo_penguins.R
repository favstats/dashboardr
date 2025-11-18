# ============================================================================
# Live Coding Demo: Palmer Penguins Dashboard
# ============================================================================
# A quick showcase of dashboardr features using the Palmer Penguins dataset

library(dashboardr)
library(palmerpenguins)  # install.packages("palmerpenguins")

# Load the data
data("penguins", package = "palmerpenguins")

# ============================================================================
# DEMO 1: Simple Dashboard (3 minutes)
# ============================================================================

create_dashboard("Penguin Explorer") %>%
  add_page(
    name = "Overview",
    data = penguins,
    
    # Mix content and visualizations
    content = create_viz() %>%
      add_callout(
        "Meet the Penguins!", 
        "Exploring 3 species across Antarctic islands 🐧",
        type = "note"
      ) %>%
      add_viz(type = "histogram", x_var = "body_mass_g") %>%
      add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g")
  ) %>%
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# DEMO 2: Tabbed Dashboard with Multiple Pages (5 minutes)
# ============================================================================

create_dashboard("Penguin Analytics", theme = "cosmo") %>%
  
  # Page 1: Species Comparison with Tabs
  add_page(
    name = "By Species",
    data = penguins,
    
    content = create_viz() %>%
      # Overview tab
      add_text("🐧 **Palmer Penguins**: 3 species, 3 islands, 344 observations") %>%
      
      # Species tabs with nested charts
      add_viz(type = "histogram", x_var = "body_mass_g", 
              tabgroup = "Adelie", filter = species == "Adelie") %>%
      add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
              tabgroup = "Adelie/Measurements", filter = species == "Adelie") %>%
      
      add_viz(type = "histogram", x_var = "body_mass_g",
              tabgroup = "Chinstrap", filter = species == "Chinstrap") %>%
      add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
              tabgroup = "Chinstrap/Measurements", filter = species == "Chinstrap") %>%
      
      add_viz(type = "histogram", x_var = "body_mass_g",
              tabgroup = "Gentoo", filter = species == "Gentoo") %>%
      add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
              tabgroup = "Gentoo/Measurements", filter = species == "Gentoo")
  ) %>%
  
  # Page 2: Island Distribution
  add_page(
    name = "By Island",
    data = penguins,
    
    content = create_viz() %>%
      add_callout(
        "Geographic Distribution",
        "Penguins across Biscoe, Dream, and Torgersen islands",
        type = "tip"
      ) %>%
      add_viz(type = "stackedbar", x_var = "island", fill_var = "species") %>%
      add_divider() %>%
      add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
              color_var = "island")
  ) %>%
  
  # Page 3: About
  add_page(
    name = "About",
    
    content = create_content() %>%
      add_text("# Palmer Penguins Dataset") %>%
      add_text("Data collected from Palmer Station, Antarctica") %>%
      add_quote(
        "This dataset contains size measurements for adult penguins observed on islands in the Palmer Archipelago, Antarctica.",
        attribution = "Dr. Kristen Gorman"
      ) %>%
      add_accordion(
        "Dataset Details",
        "**Variables**: species, island, bill length/depth, flipper length, body mass, sex, year\n\n**Time Period**: 2007-2009\n\n**Sample Size**: 344 penguins"
      ) %>%
      add_badge("Open Source", color = "success") %>%
      add_badge("R Package", color = "primary")
  ) %>%
  
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# DEMO 3: Advanced Features (8 minutes)
# ============================================================================

# Create reusable content blocks
species_intro <- create_content() %>%
  add_text("## Species Analysis") %>%
  add_callout(
    "Three Penguin Species",
    "Adelie, Chinstrap, and Gentoo penguins have distinct characteristics",
    type = "info"
  )

# Build dashboard with advanced features
create_dashboard("Penguin Research Dashboard", theme = "flatly") %>%
  
  add_page(
    name = "Executive Summary",
    data = penguins,
    
    content = create_viz() %>%
      # Value boxes
      add_value_box(
        value = 3,
        title = "Species",
        icon = "bi-egg",
        color = "primary"
      ) %>%
      add_value_box(
        value = 344,
        title = "Penguins",
        icon = "bi-graph-up",
        color = "success"
      ) %>%
      add_value_box(
        value = 3,
        title = "Islands",
        icon = "bi-geo-alt",
        color = "info"
      ) %>%
      
      add_divider() %>%
      
      # Tabbed visualizations
      add_viz(type = "stackedbar", x_var = "species", fill_var = "sex",
              tabgroup = "Demographics") %>%
      add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
              color_var = "species", tabgroup = "Morphology") %>%
      add_viz(type = "histogram", x_var = "body_mass_g", tabgroup = "Distribution")
  ) %>%
  
  add_page(
    name = "Detailed Analysis",
    data = penguins,
    
    content = create_viz() %>%
      # Mix content and viz in tabs
      add_text("📊 **Key Findings**", tabgroup = "Overview") %>%
      add_text("- Gentoo penguins are the largest species\n- Bill dimensions vary significantly by species\n- Sex differences are observable in body mass", tabgroup = "Overview") %>%
      
      add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
              color_var = "species", tabgroup = "Correlations/Size") %>%
      add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
              color_var = "species", tabgroup = "Correlations/Bill") %>%
      
      add_viz(type = "timeline", date_var = "year", y_var = "body_mass_g",
              tabgroup = "Trends")
  ) %>%
  
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# BONUS: One-Liner Dashboard 🚀
# ============================================================================

# The absolute quickest way to create a dashboard:
create_dashboard("Quick Penguins", output_dir = tempdir()) %>%
  add_page("Overview", data = penguins,
           content = create_viz() %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g") %>%
             add_viz(type = "histogram", x_var = "body_mass_g")) %>%
  generate_dashboard(render = TRUE, open = "browser")

