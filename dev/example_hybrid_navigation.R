# Hybrid Navigation Example
# This script demonstrates both simple sidebar and hybrid navigation features

# Load the enhanced dashboard system
devtools::load_all()
source("R/create_dashboard_new.R")

# Load sample data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  select(
    age_1a, sex_1a, degree_1a, region_1a,
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, class_1a
  ) %>%
  filter(if_any(everything(), ~ !is.na(.)))

cat("🚀 HYBRID NAVIGATION EXAMPLES\n")
cat("══════════════════════════════════════════════════\n\n")

# ===================================================================
# EXAMPLE 1: SIMPLE SIDEBAR (Existing Behavior)
# ===================================================================

cat("1️⃣  SIMPLE SIDEBAR EXAMPLE\n")
cat("──────────────────────────────────────────────────\n")

# Create visualizations for simple example
simple_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          height = 400)

# Simple dashboard with basic sidebar
simple_dashboard <- create_dashboard(
  output_dir = "simple_sidebar_example",
  title = "Simple Sidebar Dashboard",
  sidebar = TRUE,
  sidebar_style = "docked",
  sidebar_background = "light",
  author = "Data Analyst"
) %>%
  add_page("Welcome", text = "# Welcome\n\nThis is a simple sidebar example.", is_landing_page = TRUE) %>%
  add_page("Analysis", data = gss_clean, visualizations = simple_viz) %>%
  add_page("About", text = "# About\n\nSimple sidebar navigation.")

cat("✅ Simple sidebar dashboard created\n")
cat("📁 Location: simple_sidebar_example/\n\n")

# ===================================================================
# EXAMPLE 2: HYBRID NAVIGATION (New Feature)
# ===================================================================

cat("2️⃣  HYBRID NAVIGATION EXAMPLE\n")
cat("──────────────────────────────────────────────────\n")

# Create visualizations for different sections
analysis_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          height = 400,
          tabgroup = "demographics") %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "degree_1a",
          value_var = "trust_1a",
          title = "Trust by Region and Education",
          height = 500,
          tabgroup = "demographics")

reference_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "polviews_1a",
          stack_var = "partyid_1a",
          title = "Party ID by Political Views",
          height = 400)

# Create sidebar groups
analysis_group <- sidebar_group(
  id = "analysis",
  title = "Data Analysis",
  pages = c("overview", "demographics", "findings"),
  style = "docked",
  background = "light"
)

reference_group <- sidebar_group(
  id = "reference",
  title = "Reference",
  pages = c("about", "methodology", "data"),
  style = "docked",
  background = "dark",
  foreground = "light"
)

# Create navbar sections
analysis_section <- navbar_section("Analysis", "analysis", "ph:chart-bar")
reference_section <- navbar_section("Reference", "reference", "ph:book")

# Hybrid navigation dashboard
hybrid_dashboard <- create_dashboard(
  output_dir = "hybrid_navigation_example",
  title = "Hybrid Navigation Dashboard",
  author = "Data Analyst",
  description = "Dashboard with hybrid navigation - navbar sections link to sidebar groups",
  # Hybrid navigation parameters
  sidebar_groups = list(analysis_group, reference_group),
  navbar_sections = list(analysis_section, reference_section)
) %>%
  # Analysis section pages
  add_page("Overview",
           text = "# Analysis Overview\n\nThis section contains all data analysis pages.",
           is_landing_page = TRUE) %>%
  add_page("Demographics",
           data = gss_clean,
           visualizations = analysis_viz,
           text = "## Demographic Analysis\n\nExplore demographic patterns in the data.") %>%
  add_page("Findings",
           data = gss_clean,
           visualizations = analysis_viz,
           text = "## Key Findings\n\nSummary of main findings from the analysis.") %>%
  # Reference section pages
  add_page("About",
           text = "# About This Study\n\nInformation about the research methodology and data sources.") %>%
  add_page("Methodology",
           text = "# Methodology\n\nDetailed description of the research methods used.") %>%
  add_page("Data",
           text = "# Data Sources\n\nInformation about the datasets used in this analysis.")

cat("✅ Hybrid navigation dashboard created\n")
cat("📁 Location: hybrid_navigation_example/\n\n")

# ===================================================================
# EXAMPLE 3: MIXED NAVIGATION (Both Simple and Hybrid)
# ===================================================================

cat("3️⃣  MIXED NAVIGATION EXAMPLE\n")
cat("──────────────────────────────────────────────────\n")

# Create a dashboard that uses both regular navbar items and sidebar groups
mixed_dashboard <- create_dashboard(
  output_dir = "mixed_navigation_example",
  title = "Mixed Navigation Dashboard",
  author = "Data Analyst",
  # Mix of regular navbar items and sidebar groups
  navbar_sections = list(
    list(text = "Home", href = "index.qmd"),
    analysis_section,  # Links to sidebar group
    reference_section, # Links to sidebar group
    list(text = "Contact", href = "contact.qmd", icon = "ph:envelope")
  ),
  sidebar_groups = list(analysis_group, reference_group)
) %>%
  add_page("Welcome",
           text = "# Welcome\n\nThis dashboard mixes regular navbar items with sidebar groups.",
           is_landing_page = TRUE) %>%
  add_page("Demographics",
           data = gss_clean,
           visualizations = analysis_viz) %>%
  add_page("Findings",
           data = gss_clean,
           visualizations = analysis_viz) %>%
  add_page("About",
           text = "# About\n\nReference information.") %>%
  add_page("Methodology",
           text = "# Methodology\n\nResearch methods.") %>%
  add_page("Contact",
           text = "# Contact\n\nGet in touch with us.")

cat("✅ Mixed navigation dashboard created\n")
cat("📁 Location: mixed_navigation_example/\n\n")

# ===================================================================
# GENERATE ALL EXAMPLES
# ===================================================================

cat("🔨 GENERATING ALL DASHBOARDS...\n")
cat("══════════════════════════════════════════════════\n\n")

# # Generate simple sidebar example
# cat("Generating simple sidebar dashboard...\n")
# generate_dashboard(simple_dashboard, render = T)
#
# # Generate hybrid navigation example
# cat("Generating hybrid navigation dashboard...\n")
# generate_dashboard(hybrid_dashboard, render = T)

# Generate mixed navigation example
cat("Generating mixed navigation dashboard...\n")
generate_dashboard(mixed_dashboard, render = T)
