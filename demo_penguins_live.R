# ============================================================================
# LIVE CODING SCRIPT (3-5 minutes to type)
# ============================================================================
# Copy and paste this section by section during your demo

library(dashboardr)
library(palmerpenguins)
data("penguins")

# ============================================================================
# STEP 1: Simplest Dashboard (30 seconds)
# ============================================================================

create_dashboard("Penguins") %>%
  add_page("Overview", data = penguins,
           content = create_viz() %>%
             add_viz(type = "scatter", 
                     x_var = "flipper_length_mm", 
                     y_var = "body_mass_g")) %>%
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# STEP 2: Add More Visualizations (1 minute)
# ============================================================================

create_dashboard("Penguins") %>%
  add_page("Overview", data = penguins,
           content = create_viz() %>%
             add_viz(type = "scatter", 
                     x_var = "flipper_length_mm", 
                     y_var = "body_mass_g",
                     color_var = "species") %>%
             add_viz(type = "histogram", x_var = "body_mass_g") %>%
             add_viz(type = "stackedbar", x_var = "species", fill_var = "sex")) %>%
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# STEP 3: Add Tabs & Content (1.5 minutes)
# ============================================================================

create_dashboard("Penguins", theme = "cosmo") %>%
  add_page("Analysis", data = penguins,
           content = create_viz() %>%
             
             # Add a callout
             add_callout("Palmer Penguins", 
                         "3 species across Antarctic islands 🐧",
                         type = "note") %>%
             
             # Tabbed visualizations
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
                     tabgroup = "Size") %>%
             add_viz(type = "histogram", x_var = "body_mass_g",
                     tabgroup = "Distribution") %>%
             add_viz(type = "stackedbar", x_var = "island", fill_var = "species",
                     tabgroup = "Location")) %>%
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# STEP 4: Multiple Pages & Nested Tabs (2 minutes)
# ============================================================================

create_dashboard("Penguin Dashboard", theme = "flatly") %>%
  
  # Page 1: By Species with nested tabs
  add_page("By Species", data = penguins,
           content = create_viz() %>%
             add_text("🐧 **Three penguin species** in the Palmer Archipelago") %>%
             
             add_viz(type = "histogram", x_var = "body_mass_g",
                     tabgroup = "Adelie", filter = species == "Adelie") %>%
             add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
                     tabgroup = "Adelie/Bills", filter = species == "Adelie") %>%
             
             add_viz(type = "histogram", x_var = "body_mass_g",
                     tabgroup = "Gentoo", filter = species == "Gentoo") %>%
             add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
                     tabgroup = "Gentoo/Bills", filter = species == "Gentoo")) %>%
  
  # Page 2: Summary stats
  add_page("Summary", data = penguins,
           content = create_viz() %>%
             add_value_box(value = 3, title = "Species", icon = "bi-egg") %>%
             add_value_box(value = 344, title = "Penguins", icon = "bi-graph-up") %>%
             add_divider() %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
                     color_var = "species")) %>%
  
  generate_dashboard(render = TRUE, open = "browser")


# ============================================================================
# PRO TIPS FOR LIVE CODING:
# ============================================================================
# 1. Start with STEP 1 - show how simple it is
# 2. Build up gradually through STEP 2-4
# 3. Between steps, show the rendered dashboard in browser
# 4. Highlight: piping %>%, tabgroups, mixing content + viz
# 5. End by showing the full STEP 4 dashboard
#
# TIME: 3-5 minutes total
# FEATURES SHOWN: 8+ features in <50 lines of code!
# ============================================================================

