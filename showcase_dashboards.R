# ===================================================================
# DASHBOARDR SHOWCASE: 12 DISTINCT DASHBOARD EXAMPLES
# ===================================================================
# This script demonstrates the full range of dashboardr capabilities
# through 12 distinct dashboard examples, each showcasing different
# use cases, features, and design patterns.

# Load the enhanced dashboard system
devtools::load_all()

# Load sample data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  select(
    age_1a, sex_1a, degree_1a, region_1a,
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, class_1a
  ) %>%
  filter(if_any(everything(), ~ !is.na(.)))

cat("🚀 DASHBOARDR SHOWCASE: 12 DISTINCT EXAMPLES\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ===================================================================
# EXAMPLE 1: SIMPLE SIDEBAR DASHBOARD
# ===================================================================

cat("1️⃣  SIMPLE SIDEBAR DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

simple_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          height = 400)

simple_dashboard <- create_dashboard(
  output_dir = "01_simple_sidebar",
  title = "Simple Sidebar Dashboard",
  author = "Data Analyst",
  description = "Basic dashboard with simple sidebar navigation",
  sidebar = TRUE,
  sidebar_style = "docked",
  sidebar_background = "light",
  theme = "cosmo"
) %>%
  add_page("Welcome", 
           text = md_text("# Welcome to Simple Sidebar", "", "This dashboard demonstrates basic sidebar navigation."), 
           is_landing_page = TRUE) %>%
  add_page("Analysis", 
           data = gss_clean, 
           visualizations = simple_viz,
           text = md_text("## Data Analysis", "", "Explore the data through interactive visualizations.")) %>%
  add_page("About", 
           text = md_text("# About", "", "Simple sidebar navigation example."))

cat("✅ Simple sidebar dashboard created\n\n")

# ===================================================================
# EXAMPLE 2: HYBRID NAVIGATION DASHBOARD
# ===================================================================

cat("2️⃣  HYBRID NAVIGATION DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

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

hybrid_dashboard <- create_dashboard(
  output_dir = "02_hybrid_navigation",
  title = "Hybrid Navigation Dashboard",
  author = "Data Analyst",
  description = "Advanced dashboard with hybrid navigation - navbar sections link to sidebar groups",
  sidebar_groups = list(analysis_group, reference_group),
  navbar_sections = list(analysis_section, reference_section),
  theme = "flatly"
) %>%
  add_page("Overview",
           text = md_text("# Analysis Overview", "", "This section contains all data analysis pages."),
           is_landing_page = TRUE) %>%
  add_page("Demographics",
           data = gss_clean,
           visualizations = analysis_viz,
           text = md_text("## Demographic Analysis", "", "Explore demographic patterns in the data.")) %>%
  add_page("Findings",
           data = gss_clean,
           visualizations = analysis_viz,
           text = md_text("## Key Findings", "", "Summary of main findings from the analysis.")) %>%
  add_page("About",
           text = md_text("# About This Study", "", "Information about the research methodology and data sources.")) %>%
  add_page("Methodology",
           text = md_text("# Methodology", "", "Detailed description of the research methods used.")) %>%
  add_page("Data",
           text = md_text("# Data Sources", "", "Information about the datasets used in this analysis."))

cat("✅ Hybrid navigation dashboard created\n\n")

# ===================================================================
# EXAMPLE 3: SOCIAL MEDIA DASHBOARD
# ===================================================================

cat("3️⃣  SOCIAL MEDIA DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

social_viz <- create_viz() %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Age Distribution",
          height = 300,
          tabgroup = "demographics") %>%
  add_viz(type = "stackedbar",
          x_var = "sex_1a",
          stack_var = "degree_1a",
          title = "Education by Gender",
          height = 300,
          tabgroup = "demographics")

social_dashboard <- create_dashboard(
  output_dir = "03_social_media",
  title = "Social Media Analytics Dashboard",
  author = "Social Media Analyst",
  description = "Dashboard with social media links and modern styling",
  github = "https://github.com/username/social-dashboard",
  twitter = "https://twitter.com/username",
  linkedin = "https://linkedin.com/in/username",
  email = "analyst@example.com",
  website = "https://example.com",
  theme = "journal",
  navbar_style = "dark",
  value_boxes = TRUE,
  search = TRUE
) %>%
  add_page("Dashboard", 
           text = md_text("# Social Media Analytics", "", "Real-time insights into social media performance."), 
           is_landing_page = TRUE) %>%
  add_page("Demographics", 
           data = gss_clean, 
           visualizations = social_viz,
           text = md_text("## Audience Demographics", "", "Understanding your audience composition.")) %>%
  add_page("Engagement", 
           data = gss_clean, 
           visualizations = social_viz,
           text = md_text("## Engagement Metrics", "", "How your audience interacts with content.")) %>%
  add_page("About", 
           text = md_text("# About This Dashboard", "", "Built with dashboardr for social media analytics."))

cat("✅ Social media dashboard created\n\n")

# ===================================================================
# EXAMPLE 4: ACADEMIC RESEARCH DASHBOARD
# ===================================================================

cat("4️⃣  ACADEMIC RESEARCH DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

research_viz <- create_viz() %>%
  add_viz(type = "heatmap",
          x_var = "polviews_1a",
          y_var = "degree_1a",
          value_var = "trust_1a",
          title = "Trust by Political Views and Education",
          height = 500,
          tabgroup = "analysis") %>%
  add_viz(type = "stackedbar",
          x_var = "region_1a",
          stack_var = "class_1a",
          title = "Social Class by Region",
          height = 400,
          tabgroup = "analysis")

research_dashboard <- create_dashboard(
  output_dir = "04_academic_research",
  title = "Academic Research Dashboard",
  author = "Dr. Jane Smith",
  description = "Comprehensive research dashboard with academic styling and features",
  theme = "bootstrap",
  math = "katex",
  code_folding = "show",
  code_tools = TRUE,
  toc = "floating",
  toc_depth = 3,
  google_analytics = "GA-XXXXXXXXX",
  page_footer = "© 2024 Research Institute. All rights reserved."
) %>%
  add_page("Abstract", 
           text = md_text("# Research Abstract", "", "This study examines the relationship between education, political views, and social trust using data from the General Social Survey."), 
           is_landing_page = TRUE) %>%
  add_page("Literature Review", 
           text = md_text("# Literature Review", "", "Previous research on social trust and political attitudes.")) %>%
  add_page("Methodology", 
           text = md_text("# Methodology", "", "## Data Collection", "", "We used data from the General Social Survey (GSS) panel study.")) %>%
  add_page("Analysis", 
           data = gss_clean, 
           visualizations = research_viz,
           text = md_text("## Data Analysis", "", "Statistical analysis of the relationships between variables.")) %>%
  add_page("Results", 
           data = gss_clean, 
           visualizations = research_viz,
           text = md_text("## Results", "", "Key findings from our analysis.")) %>%
  add_page("Discussion", 
           text = md_text("# Discussion", "", "Implications of our findings for understanding social trust.")) %>%
  add_page("References", 
           text = md_text("# References", "", "1. Smith, J. (2024). Social Trust and Education. *Journal of Sociology*."))

cat("✅ Academic research dashboard created\n\n")

# ===================================================================
# EXAMPLE 5: BUSINESS INTELLIGENCE DASHBOARD
# ===================================================================

cat("5️⃣  BUSINESS INTELLIGENCE DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

bi_viz <- create_viz() %>%
  add_viz(type = "stackedbars",
          questions = c("happy_1a", "trust_1a", "fair_1a", "helpful_1a"),
          title = "Social Attitudes Overview",
          height = 400,
          tabgroup = "metrics") %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Customer Age Distribution",
          height = 300,
          tabgroup = "demographics")

bi_dashboard <- create_dashboard(
  output_dir = "05_business_intelligence",
  title = "Business Intelligence Dashboard",
  author = "BI Team",
  description = "Executive dashboard for business intelligence and reporting",
  theme = "cerulean",
  value_boxes = TRUE,
  metrics_style = "bootstrap",
  page_layout = "wide",
  google_analytics = "GA-XXXXXXXXX",
  gtag = "GTM-XXXXXXX"
) %>%
  add_page("Executive Summary", 
           text = md_text("# Executive Summary", "", "Key performance indicators and business metrics."), 
           is_landing_page = TRUE) %>%
  add_page("KPIs", 
           data = gss_clean, 
           visualizations = bi_viz,
           text = md_text("## Key Performance Indicators", "", "Critical metrics for business success.")) %>%
  add_page("Demographics", 
           data = gss_clean, 
           visualizations = bi_viz,
           text = md_text("## Customer Demographics", "", "Understanding our customer base.")) %>%
  add_page("Trends", 
           data = gss_clean, 
           visualizations = bi_viz,
           text = md_text("## Market Trends", "", "Analysis of market trends and patterns.")) %>%
  add_page("Reports", 
           text = md_text("# Reports", "", "Download detailed reports and analysis."))

cat("✅ Business intelligence dashboard created\n\n")

# ===================================================================
# EXAMPLE 6: DATA SCIENCE PORTFOLIO
# ===================================================================

cat("6️⃣  DATA SCIENCE PORTFOLIO\n")
cat("───────────────────────────────────────────────────────────────────\n")

portfolio_viz <- create_viz() %>%
  add_viz(type = "timeline",
          time_var = "age_1a",
          title = "Age Timeline Analysis",
          height = 300,
          tabgroup = "projects") %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "degree_1a",
          value_var = "happy_1a",
          title = "Happiness Heatmap",
          height = 400,
          tabgroup = "projects")

portfolio_dashboard <- create_dashboard(
  output_dir = "06_data_science_portfolio",
  title = "Data Science Portfolio",
  author = "Data Scientist",
  description = "Personal portfolio showcasing data science projects and skills",
  github = "https://github.com/username",
  linkedin = "https://linkedin.com/in/username",
  email = "scientist@example.com",
  theme = "sandstone",
  custom_css = "custom.css",
  shiny = TRUE,
  observable = TRUE
) %>%
  add_page("Home", 
           text = md_text("# Data Science Portfolio", "", "Welcome to my data science portfolio showcasing various projects and analyses."), 
           is_landing_page = TRUE) %>%
  add_page("Projects", 
           data = gss_clean, 
           visualizations = portfolio_viz,
           text = md_text("## My Projects", "", "A collection of data science projects and analyses.")) %>%
  add_page("Skills", 
           text = md_text("# Technical Skills", "", "## Programming Languages", "", "- R", "- Python", "- SQL")) %>%
  add_page("Resume", 
           text = md_text("# Resume", "", "Professional experience and education.")) %>%
  add_page("Contact", 
           text = md_text("# Contact", "", "Get in touch for collaboration opportunities."))

cat("✅ Data science portfolio created\n\n")

# ===================================================================
# EXAMPLE 7: MINIMALIST DASHBOARD
# ===================================================================

cat("7️⃣  MINIMALIST DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

minimal_viz <- create_viz() %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Age Distribution",
          height = 300)

minimal_dashboard <- create_dashboard(
  output_dir = "07_minimalist",
  title = "Minimalist Dashboard",
  author = "Designer",
  description = "Clean, minimal dashboard design",
  theme = "minima",
  sidebar = FALSE,
  search = FALSE,
  toc = NULL
) %>%
  add_page("Data", 
           data = gss_clean, 
           visualizations = minimal_viz,
           text = md_text("# Data Visualization", "", "Simple, clean data presentation."), 
           is_landing_page = TRUE) %>%
  add_page("About", 
           text = md_text("# About", "", "Minimalist design principles."))

cat("✅ Minimalist dashboard created\n\n")

# ===================================================================
# EXAMPLE 8: MULTI-LANGUAGE DASHBOARD
# ===================================================================

cat("8️⃣  MULTI-LANGUAGE DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

multilang_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "sex_1a",
          title = "Education by Gender / Éducation par Genre",
          height = 400,
          tabgroup = "analysis") %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "polviews_1a",
          value_var = "trust_1a",
          title = "Trust by Region and Politics / Confiance par Région et Politique",
          height = 400,
          tabgroup = "analysis")

multilang_dashboard <- create_dashboard(
  output_dir = "08_multilanguage",
  title = "Multilingual Dashboard / Tableau de Bord Multilingue",
  author = "International Team",
  description = "Dashboard supporting multiple languages / Tableau de bord supportant plusieurs langues",
  theme = "united",
  custom_css = "multilang.css"
) %>%
  add_page("Welcome / Bienvenue", 
           text = md_text("# Welcome / Bienvenue", "", "This dashboard supports multiple languages. / Ce tableau de bord prend en charge plusieurs langues."), 
           is_landing_page = TRUE) %>%
  add_page("Analysis / Analyse", 
           data = gss_clean, 
           visualizations = multilang_viz,
           text = md_text("## Data Analysis / Analyse des Données", "", "Multilingual data analysis. / Analyse de données multilingue.")) %>%
  add_page("About / À Propos", 
           text = md_text("# About / À Propos", "", "Information about this dashboard. / Informations sur ce tableau de bord."))

cat("✅ Multilingual dashboard created\n\n")

# ===================================================================
# EXAMPLE 9: DARK THEME DASHBOARD
# ===================================================================

cat("9️⃣  DARK THEME DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

dark_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness by Education",
          height = 400,
          tabgroup = "analysis") %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Age Distribution",
          height = 300,
          tabgroup = "analysis")

dark_dashboard <- create_dashboard(
  output_dir = "09_dark_theme",
  title = "Dark Theme Dashboard",
  author = "Night Owl",
  description = "Dashboard with dark theme and modern styling",
  theme = "darkly",
  navbar_style = "dark",
  sidebar = TRUE,
  sidebar_style = "docked",
  sidebar_background = "dark",
  sidebar_foreground = "light",
  custom_css = "dark-theme.css"
) %>%
  add_page("Dashboard", 
           text = md_text("# Dark Theme Dashboard", "", "A modern dashboard with dark styling."), 
           is_landing_page = TRUE) %>%
  add_page("Analysis", 
           data = gss_clean, 
           visualizations = dark_viz,
           text = md_text("## Data Analysis", "", "Explore data in a dark, modern interface.")) %>%
  add_page("Settings", 
           text = md_text("# Settings", "", "Customize your dashboard experience."))

cat("✅ Dark theme dashboard created\n\n")

# ===================================================================
# EXAMPLE 10: INTERACTIVE DASHBOARD
# ===================================================================

cat("🔟 INTERACTIVE DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

interactive_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "sex_1a",
          title = "Education by Gender",
          height = 400,
          tabgroup = "interactive") %>%
  add_viz(type = "heatmap",
          x_var = "region_1a",
          y_var = "class_1a",
          value_var = "trust_1a",
          title = "Trust by Region and Class",
          height = 400,
          tabgroup = "interactive")

interactive_dashboard <- create_dashboard(
  output_dir = "10_interactive",
  title = "Interactive Dashboard",
  author = "Interactive Designer",
  description = "Highly interactive dashboard with Shiny and Observable integration",
  theme = "superhero",
  shiny = TRUE,
  observable = TRUE,
  jupyter = TRUE,
  value_boxes = TRUE,
  metrics_style = "bootstrap"
) %>%
  add_page("Interactive Analysis", 
           text = md_text("# Interactive Analysis", "", "Explore data with interactive visualizations and controls."), 
           is_landing_page = TRUE) %>%
  add_page("Charts", 
           data = gss_clean, 
           visualizations = interactive_viz,
           text = md_text("## Interactive Charts", "", "Hover, click, and explore the data.")) %>%
  add_page("Controls", 
           text = md_text("# Interactive Controls", "", "Use the controls below to filter and explore the data.")) %>%
  add_page("Documentation", 
           text = md_text("# Documentation", "", "How to use this interactive dashboard."))

cat("✅ Interactive dashboard created\n\n")

# ===================================================================
# EXAMPLE 11: PUBLISHING DASHBOARD
# ===================================================================

cat("1️⃣1️⃣ PUBLISHING DASHBOARD\n")
cat("───────────────────────────────────────────────────────────────────\n")

publishing_viz <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "polviews_1a",
          title = "Political Views by Education",
          height = 400,
          tabgroup = "content") %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Reader Age Distribution",
          height = 300,
          tabgroup = "content")

publishing_dashboard <- create_dashboard(
  output_dir = "11_publishing",
  title = "Publishing Dashboard",
  author = "Content Publisher",
  description = "Dashboard designed for content publishing and sharing",
  github = "https://github.com/username/publishing-dashboard",
  twitter = "https://twitter.com/username",
  linkedin = "https://linkedin.com/in/username",
  website = "https://example.com",
  theme = "readable",
  search = TRUE,
  toc = "left",
  page_footer = "Published with dashboardr | © 2024"
) %>%
  add_page("Latest Content", 
           text = md_text("# Latest Content", "", "Stay updated with our latest publications and insights."), 
           is_landing_page = TRUE) %>%
  add_page("Articles", 
           data = gss_clean, 
           visualizations = publishing_viz,
           text = md_text("## Featured Articles", "", "In-depth analysis and research articles.")) %>%
  add_page("Newsletter", 
           text = md_text("# Newsletter", "", "Subscribe to our newsletter for regular updates.")) %>%
  add_page("About", 
           text = md_text("# About Us", "", "Learn more about our publishing mission."))

cat("✅ Publishing dashboard created\n\n")

# ===================================================================
# EXAMPLE 12: COMPREHENSIVE SHOWCASE
# ===================================================================

cat("1️⃣2️⃣ COMPREHENSIVE SHOWCASE\n")
cat("───────────────────────────────────────────────────────────────────\n")

# Create multiple visualization types
comprehensive_viz <- create_viz() %>%
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
          tabgroup = "demographics") %>%
  add_viz(type = "histogram",
          x_var = "age_1a",
          title = "Age Distribution",
          height = 300,
          tabgroup = "demographics") %>%
  add_viz(type = "stackedbar",
          x_var = "polviews_1a",
          stack_var = "partyid_1a",
          title = "Party ID by Political Views",
          height = 400,
          tabgroup = "politics") %>%
  add_viz(type = "stackedbars",
          questions = c("happy_1a", "trust_1a", "fair_1a", "helpful_1a"),
          title = "Social Attitudes Overview",
          height = 400,
          tabgroup = "attitudes")

# Create comprehensive sidebar groups
demographics_group <- sidebar_group(
  id = "demographics",
  title = "Demographics",
  pages = c("overview", "age", "education", "gender"),
  style = "docked",
  background = "light"
)

politics_group <- sidebar_group(
  id = "politics",
  title = "Politics",
  pages = c("views", "parties", "analysis"),
  style = "docked",
  background = "dark",
  foreground = "light"
)

attitudes_group <- sidebar_group(
  id = "attitudes",
  title = "Social Attitudes",
  pages = c("trust", "happiness", "fairness", "helpfulness"),
  style = "docked",
  background = "primary"
)

# Create navbar sections
demographics_section <- navbar_section("Demographics", "demographics", "ph:users")
politics_section <- navbar_section("Politics", "politics", "ph:flag")
attitudes_section <- navbar_section("Attitudes", "attitudes", "ph:heart")

comprehensive_dashboard <- create_dashboard(
  output_dir = "12_comprehensive_showcase",
  title = "Comprehensive Data Showcase",
  author = "Data Science Team",
  description = "Comprehensive dashboard showcasing all dashboardr features and capabilities",
  github = "https://github.com/username/comprehensive-dashboard",
  twitter = "https://twitter.com/username",
  linkedin = "https://linkedin.com/in/username",
  email = "team@example.com",
  website = "https://example.com",
  theme = "cosmo",
  sidebar_groups = list(demographics_group, politics_group, attitudes_group),
  navbar_sections = list(demographics_section, politics_section, attitudes_section),
  value_boxes = TRUE,
  search = TRUE,
  toc = "floating",
  math = "katex",
  code_folding = "show",
  google_analytics = "GA-XXXXXXXXX",
  page_footer = "Comprehensive showcase built with dashboardr | © 2024"
) %>%
  add_page("Overview",
           text = md_text("# Comprehensive Data Showcase", "", "This dashboard demonstrates all the features and capabilities of the dashboardr package."),
           is_landing_page = TRUE) %>%
  add_page("Age Analysis",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Age Analysis", "", "Understanding age-related patterns in the data.")) %>%
  add_page("Education",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Education Analysis", "", "Educational attainment and its relationship to other variables.")) %>%
  add_page("Gender",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Gender Analysis", "", "Gender differences across various measures.")) %>%
  add_page("Political Views",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Political Views", "", "Analysis of political attitudes and preferences.")) %>%
  add_page("Party Affiliation",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Party Affiliation", "", "Political party identification and its correlates.")) %>%
  add_page("Trust",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Social Trust", "", "Levels of trust in society and institutions.")) %>%
  add_page("Happiness",
           data = gss_clean,
           visualizations = comprehensive_viz,
           text = md_text("## Happiness", "", "Subjective well-being and life satisfaction.")) %>%
  add_page("About",
           text = md_text("# About This Showcase", "", "This comprehensive dashboard demonstrates the full range of dashboardr capabilities."))

cat("✅ Comprehensive showcase dashboard created\n\n")

# ===================================================================
# GENERATE ALL DASHBOARDS
# ===================================================================

cat("🔨 GENERATING ALL DASHBOARDS...\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Generate all dashboards
dashboards <- list(
  simple_dashboard,
  hybrid_dashboard,
  social_dashboard,
  research_dashboard,
  bi_dashboard,
  portfolio_dashboard,
  minimal_dashboard,
  multilang_dashboard,
  dark_dashboard,
  interactive_dashboard,
  publishing_dashboard,
  comprehensive_dashboard
)

for (i in seq_along(dashboards)) {
  cat("Generating dashboard", i, "of", length(dashboards), "...\n")
  generate_dashboard(dashboards[[i]], render = TRUE)
}

cat("\n🎉 ALL DASHBOARDS GENERATED SUCCESSFULLY!\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# ===================================================================
# CREATE INDEX.QMD FILE
# ===================================================================

cat("📝 CREATING INDEX.QMD FILE...\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

index_content <- c(
  "---",
  "title: \"Dashboardr Showcase\"",
  "description: \"Comprehensive showcase of dashboardr capabilities through 12 distinct dashboard examples\"",
  "author: \"Dashboardr Team\"",
  "format:",
  "  html:",
  "    theme: cosmo",
  "    toc: true",
  "    toc-depth: 3",
  "    code-fold: show",
  "    code-tools: true",
  "    value-boxes: true",
  "    search: true",
  "---",
  "",
  "# Dashboardr Showcase",
  "",
  "Welcome to the comprehensive showcase of the **dashboardr** package! This collection demonstrates the full range of capabilities through 12 distinct dashboard examples, each showcasing different use cases, features, and design patterns.",
  "",
  "## 🚀 Quick Start",
  "",
  "Each dashboard example is self-contained and ready to run. Simply navigate to any dashboard directory and explore the features:",
  "",
  "```r",
  "# Load the package",
  "devtools::load_all()",
  "",
  "# Generate any dashboard",
  "generate_dashboard(your_dashboard, render = TRUE)",
  "```",
  "",
  "## 📊 Dashboard Examples",
  "",
  "### 1. [Simple Sidebar Dashboard](01_simple_sidebar/)",
  "**Basic sidebar navigation** - Perfect for getting started with dashboardr",
  "",
  "**Features:** Basic sidebar, simple navigation, clean design",
  "",
  "**Use Case:** Quick data exploration, simple reports",
  "",
  "---",
  "",
  "### 2. [Hybrid Navigation Dashboard](02_hybrid_navigation/)",
  "**Advanced navigation** - Navbar sections linked to sidebar groups",
  "",
  "**Features:** Hybrid navigation, multiple sidebar groups, complex layouts",
  "",
  "**Use Case:** Large datasets, complex analysis workflows",
  "",
  "---",
  "",
  "### 3. [Social Media Dashboard](03_social_media/)",
  "**Social integration** - Complete with social media links and modern styling",
  "",
  "**Features:** Social media links, modern themes, value boxes, search",
  "",
  "**Use Case:** Social media analytics, public dashboards",
  "",
  "---",
  "",
  "### 4. [Academic Research Dashboard](04_academic_research/)",
  "**Academic styling** - Perfect for research publications and academic work",
  "",
  "**Features:** Math support, code folding, academic themes, analytics",
  "",
  "**Use Case:** Research publications, academic presentations",
  "",
  "---",
  "",
  "### 5. [Business Intelligence Dashboard](05_business_intelligence/)",
  "**Executive dashboard** - Designed for business intelligence and reporting",
  "",
  "**Features:** Value boxes, wide layout, business themes, analytics",
  "",
  "**Use Case:** Executive reporting, business analytics",
  "",
  "---",
  "",
  "### 6. [Data Science Portfolio](06_data_science_portfolio/)",
  "**Personal portfolio** - Showcase data science projects and skills",
  "",
  "**Features:** Portfolio styling, project showcase, personal branding",
  "",
  "**Use Case:** Personal portfolios, project showcases",
  "",
  "---",
  "",
  "### 7. [Minimalist Dashboard](07_minimalist/)",
  "**Clean design** - Minimalist approach with focus on content",
  "",
  "**Features:** Minimal design, no sidebar, clean typography",
  "",
  "**Use Case:** Simple presentations, clean reports",
  "",
  "---",
  "",
  "### 8. [Multilingual Dashboard](08_multilanguage/)",
  "**International support** - Dashboard supporting multiple languages",
  "",
  "**Features:** Multilingual content, international themes",
  "",
  "**Use Case:** International projects, multilingual teams",
  "",
  "---",
  "",
  "### 9. [Dark Theme Dashboard](09_dark_theme/)",
  "**Modern dark styling** - Dark theme with modern design elements",
  "",
  "**Features:** Dark themes, modern styling, custom CSS",
  "",
  "**Use Case:** Modern presentations, developer-focused dashboards",
  "",
  "---",
  "",
  "### 10. [Interactive Dashboard](10_interactive/)",
  "**Highly interactive** - Shiny, Observable, and Jupyter integration",
  "",
  "**Features:** Shiny integration, Observable JS, interactive controls",
  "",
  "**Use Case:** Interactive analysis, dynamic dashboards",
  "",
  "---",
  "",
  "### 11. [Publishing Dashboard](11_publishing/)",
  "**Content publishing** - Designed for content publishing and sharing",
  "",
  "**Features:** Publishing features, content management, sharing",
  "",
  "**Use Case:** Content publishing, blog integration",
  "",
  "---",
  "",
  "### 12. [Comprehensive Showcase](12_comprehensive_showcase/)",
  "**Full feature showcase** - Demonstrates all dashboardr capabilities",
  "",
  "**Features:** All features, complex navigation, comprehensive examples",
  "",
  "**Use Case:** Feature demonstration, comprehensive analysis",
  "",
  "## 🛠️ Key Features Demonstrated",
  "",
  "### Navigation Systems",
  "- **Simple Sidebar**: Basic sidebar navigation",
  "- **Hybrid Navigation**: Navbar sections linked to sidebar groups",
  "- **Mixed Navigation**: Combination of regular and sidebar navigation",
  "",
  "### Visualizations",
  "- **Stacked Bar Charts**: Categorical data analysis",
  "- **Heatmaps**: Correlation and pattern analysis",
  "- **Histograms**: Distribution analysis",
  "- **Timeline Charts**: Temporal data visualization",
  "- **Multiple Chart Types**: Comprehensive visualization suite",
  "",
  "### Styling & Themes",
  "- **Bootstrap Themes**: Cosmo, Flatly, Journal, and more",
  "- **Custom CSS**: Personalized styling options",
  "- **Dark Themes**: Modern dark styling",
  "- **Responsive Design**: Mobile-friendly layouts",
  "",
  "### Advanced Features",
  "- **Social Media Integration**: GitHub, Twitter, LinkedIn links",
  "- **Search Functionality**: Built-in search capabilities",
  "- **Math Support**: LaTeX and MathJax integration",
  "- **Code Features**: Syntax highlighting, folding, tools",
  "- **Analytics**: Google Analytics, Plausible integration",
  "- **Interactive Elements**: Shiny, Observable, Jupyter support",
  "",
  "### Publishing & Deployment",
  "- **GitHub Pages**: Automated deployment",
  "- **GitLab Pages**: Alternative deployment option",
  "- **Data Security**: Comprehensive data exclusion",
  "- **Version Control**: Git integration",
  "",
  "## 📚 Getting Started",
  "",
  "1. **Explore the examples** - Browse through the different dashboard types",
  "2. **Choose your style** - Find the design pattern that fits your needs",
  "3. **Customize** - Modify the examples to match your data and requirements",
  "4. **Deploy** - Use the built-in publishing features to share your dashboard",
  "",
  "## 🔗 Resources",
  "",
  "- **Package Documentation**: [dashboardr documentation](https://github.com/username/dashboardr)",
  "- **GitHub Repository**: [Source code and issues](https://github.com/username/dashboardr)",
  "- **Examples Gallery**: [More examples and tutorials](https://github.com/username/dashboardr-examples)",
  "",
  "## 📄 License",
  "",
  "This showcase is part of the dashboardr package. See the package documentation for licensing information.",
  "",
  "---",
  "",
  "*Built with ❤️ using the dashboardr package*"
)

writeLines(index_content, "index.qmd")

cat("✅ Index.qmd file created\n\n")

cat("🎉 SHOWCASE COMPLETE!\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("📁 12 dashboard examples generated\n")
cat("📄 Index.qmd file created for easy navigation\n")
cat("🚀 Ready to explore and customize!\n\n")
cat("Next steps:\n")
cat("1. Open index.qmd in your browser\n")
cat("2. Navigate through the different examples\n")
cat("3. Choose your favorite style and customize it\n")
cat("4. Use publish_dashboard() to deploy your creation\n\n")
cat("Happy dashboarding! 🎉\n")
