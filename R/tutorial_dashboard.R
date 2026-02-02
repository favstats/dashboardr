#' Generate a tutorial dashboard.
#'
#' This function creates and renders a detailed tutorial dashboard showcasing
#' various features of the dashboardr package. It includes examples of
#' stacked bar charts, heatmaps, multiple pages, and custom components.
#'
#' @param directory Character string. Directory where the dashboard files will be created.
#'   Defaults to "tutorial_dashboard". Quarto will render HTML to directory/docs/.
#' @param open Logical or character. Whether to open the dashboard after rendering.
#'   Use TRUE or "browser" to open in browser (default), FALSE to not open. Default is "browser".
#'
#' @details
#' The dashboard uses data from the General Social Survey (GSS) to
#' demonstrate visualization and layout options.
#'
#' @return Invisibly returns the dashboard_project object.
#' @export
#'
#' @examples
#' \dontrun{
#' # Run the tutorial dashboard (requires Quarto CLI and 'gssr' package)
#' tutorial_dashboard()
#'
#' # Specify custom directory
#' tutorial_dashboard(directory = "my_tutorial")
#'
#' # Don't open browser
#' tutorial_dashboard(open = FALSE)
#' }
tutorial_dashboard <- function(directory = "tutorial_dashboard", open = "browser") {
  qmds_dir <- directory  # Use directory parameter for QMD files location

  # Ensure output directory exists and copy logo
  if (!dir.exists(qmds_dir)) dir.create(qmds_dir, recursive = TRUE)
  logo_src <- system.file("assets", "gss_logo.png", package = "dashboardr")
  if (file.exists(logo_src)) {
    file.copy(logo_src, file.path(qmds_dir, "gss_logo.png"), overwrite = TRUE)
  }

  # Load GSS panel data for cross-sectional charts
  data(gss_panel20, package = "gssr")
  gss_clean <- gss_panel20 %>%
    dplyr::mutate(
      degree = as.character(haven::as_factor(degree_1a)),
      happy = as.character(haven::as_factor(happy_1a)),
      sex = as.character(haven::as_factor(sex_1a)),
      region = as.character(haven::as_factor(region_1a))
    ) %>%
    dplyr::filter(!is.na(degree), !is.na(happy), !is.na(sex))

  # Load GSS all data for time series (timeline chart)
  data(gss_all, package = "gssr")
  gss_time <- gss_all %>%
    dplyr::mutate(
      happy = as.character(haven::as_factor(happy))
    ) %>%
    dplyr::filter(!is.na(happy), !is.na(year), happy %in% c("very happy", "pretty happy", "not too happy"))

  # FULL Charts page code for accordion
  charts_page_code <- "```r
# === CHARTS PAGE ===
# This page shows a bar chart and stacked bar chart

# Data preparation
library(gssr)
data(gss_panel20, package = \"gssr\")
gss_clean <- gss_panel20 %>%
  dplyr::mutate(
    degree = as.character(haven::as_factor(degree_1a)),
    happy = as.character(haven::as_factor(happy_1a))
  ) %>%
  dplyr::filter(!is.na(degree), !is.na(happy))

# Create visualizations
chart_vizzes <- create_content() %>%
  add_viz(type = \"bar\",
          x_var = \"degree\",
          title = \"Education Level Distribution\",
          subtitle = \"Count of respondents by highest degree attained\",
          x_label = \"Education\",
          y_label = \"Count\",
          x_order = c(\"less than high school\", \"high school\",
                      \"associate/junior college\", \"bachelor's\", \"graduate\"),
          color_palette = c(\"#3498db\", \"#2ecc71\", \"#9b59b6\", \"#e74c3c\", \"#f39c12\"),
          height = 400) %>%
  add_viz(type = \"stackedbar\",
          x_var = \"degree\",
          stack_var = \"happy\",
          title = \"Happiness by Education Level\",
          subtitle = \"Self-reported happiness across education groups\",
          x_label = \"Education\",
          y_label = \"Percentage\",
          stack_label = \"Happiness\",
          stacked_type = \"percent\",
          x_order = c(\"less than high school\", \"high school\",
                      \"associate/junior college\", \"bachelor's\", \"graduate\"),
          stack_order = c(\"very happy\", \"pretty happy\", \"not too happy\"),
          color_palette = c(\"#27ae60\", \"#f39c12\", \"#e74c3c\"),
          height = 450)

# Create page and add content
charts_page <- create_page(name = \"Charts\", data = gss_clean, icon = \"ph:chart-bar\") %>%
  add_content(chart_vizzes)
```"

  # Create chart visualizations (3 standalone charts)
  chart_vizzes <- create_content() %>%
    # 1. Bar chart
    add_viz(type = "bar",
            x_var = "degree",
            title = "Education Level Distribution",
            subtitle = "Count of respondents by highest degree attained",
            x_label = "Education",
            y_label = "Count",
            x_order = c("less than high school", "high school",
                        "associate/junior college", "bachelor's", "graduate"),
            color_palette = c("#3498db", "#2ecc71", "#9b59b6", "#e74c3c", "#f39c12"),
            height = 400) %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = "```r
add_viz(type = \"bar\",
        x_var = \"degree\",
        title = \"Education Level Distribution\",
        subtitle = \"Count of respondents by highest degree attained\",
        x_label = \"Education\",
        y_label = \"Count\",
        x_order = c(\"less than high school\", \"high school\",
                    \"associate/junior college\", \"bachelor's\", \"graduate\"),
        color_palette = c(\"#3498db\", \"#2ecc71\", \"#9b59b6\", \"#e74c3c\", \"#f39c12\"),
        height = 400)
```"
    ) %>%
    # 2. Stacked bar chart
    add_viz(type = "stackedbar",
            x_var = "degree",
            stack_var = "happy",
            title = "Happiness by Education Level",
            subtitle = "Self-reported happiness across education groups",
            x_label = "Education",
            y_label = "Percentage",
            stack_label = "Happiness",
            stacked_type = "percent",
            x_order = c("less than high school", "high school",
                        "associate/junior college", "bachelor's", "graduate"),
            stack_order = c("very happy", "pretty happy", "not too happy"),
            color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
            height = 450) %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = "```r
add_viz(type = \"stackedbar\",
        x_var = \"degree\",
        stack_var = \"happy\",
        title = \"Happiness by Education Level\",
        subtitle = \"Self-reported happiness across education groups\",
        x_label = \"Education\",
        y_label = \"Percentage\",
        stack_label = \"Happiness\",
        stacked_type = \"percent\",
        x_order = c(\"less than high school\", \"high school\",
                    \"associate/junior college\", \"bachelor's\", \"graduate\"),
        stack_order = c(\"very happy\", \"pretty happy\", \"not too happy\"),
        color_palette = c(\"#27ae60\", \"#f39c12\", \"#e74c3c\"),
        height = 450)
```"
    )

  # FULL Timeline page code for accordion
  timeline_page_code <- '```r
# === TIMELINE PAGE ===
# This page shows happiness trends over 50+ years

# Data preparation - use gss_all for time series
library(gssr)
data(gss_all, package = "gssr")
gss_time <- gss_all %>%
  dplyr::mutate(
    happy = as.character(haven::as_factor(happy))
  ) %>%
  dplyr::filter(
    !is.na(happy),
    !is.na(year),
    happy %in% c("very happy", "pretty happy", "not too happy")
  )

# Create visualization
timeline_viz <- create_content() %>%
  add_viz(type = "timeline",
          time_var = "year",
          y_var = "happy",
          title = "Happiness Trends Over Time (1972-2024)",
          subtitle = "How has happiness changed across 50+ years?",
          x_label = "Year",
          y_label = "Percentage",
          y_levels = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450)

# Create page and add content
timeline_page <- create_page(name = "Timeline", data = gss_time, icon = "ph:chart-line") %>%
  add_content(timeline_viz)
```'

  # Timeline chart (needs gss_time data with year variable)
  timeline_viz <- create_content() %>%
    add_viz(type = "timeline",
            time_var = "year",
            y_var = "happy",
            title = "Happiness Trends Over Time (1972-2024)",
            subtitle = "How has happiness changed across 50+ years?",
            x_label = "Year",
            y_label = "Percentage",
            y_levels = c("very happy", "pretty happy", "not too happy"),
            color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
            height = 450)

  # FULL Text & Content page code for accordion
  text_page_code <- '```r
# === TEXT & CONTENT PAGE ===
# This page demonstrates markdown formatting and content blocks

# Create content with text and accordions
text_content <- create_content() %>%
  add_text(md_text(
    "This page demonstrates text formatting and content blocks.",
    "",
    "You can use **bold text** for emphasis, *italics* for subtle highlighting,",
    "and `inline code` for technical terms like `add_viz()`.",
    "",
    "Combine styles: ***bold and italic*** or **`bold code`**.",
    "Add [hyperlinks](https://dashboardr.dev) to external resources.",
    "",
    "Lists work too:",
    "",
    "- First item with **bold**",
    "- Second item with *italics*",
    "- Third item with `code`"
  )) %>%
  add_accordion(
    title = "What is an accordion?",
    text = "An **accordion** is a collapsible content block. Users click to
           expand and reveal hidden content. Great for FAQs or code examples."
  ) %>%
  add_accordion(
    title = "Pro tip: Nested content",
    text = md_text(
      "Inside accordions, you can include:",
      "",
      "- Markdown formatting like **bold** and *italics*",
      "- Code blocks for examples",
      "- Links to documentation"
    )
  ) %>%
  add_text("Text-only pages are useful for documentation or methodology notes.")

# Create page and add content
text_page <- create_page(name = "Text & Content", icon = "ph:chalkboard-simple-bold") %>%
  add_content(text_content)
```'

  # Full code for the landing page accordion
  full_code <- "```r
library(dashboardr)
library(gssr)

# === DATA PREPARATION ===

# Cross-sectional data (for bar/stackedbar charts)
data(gss_panel20, package = \"gssr\")
gss_clean <- gss_panel20 %>%
  dplyr::mutate(
    degree = as.character(haven::as_factor(degree_1a)),
    happy = as.character(haven::as_factor(happy_1a))
  ) %>%
  dplyr::filter(!is.na(degree), !is.na(happy))

# Time series data (for timeline chart)
data(gss_all, package = \"gssr\")
gss_time <- gss_all %>%
  dplyr::mutate(happy = as.character(haven::as_factor(happy))) %>%
  dplyr::filter(!is.na(happy), !is.na(year),
                happy %in% c(\"very happy\", \"pretty happy\", \"not too happy\"))

# === CHARTS PAGE ===

chart_vizzes <- create_content() %>%
  add_viz(type = \"bar\",
          x_var = \"degree\",
          title = \"Education Level Distribution\",
          subtitle = \"Count of respondents by highest degree attained\",
          x_label = \"Education\",
          y_label = \"Count\",
          x_order = c(\"less than high school\", \"high school\",
                      \"associate/junior college\", \"bachelor's\", \"graduate\"),
          color_palette = c(\"#3498db\", \"#2ecc71\", \"#9b59b6\", \"#e74c3c\", \"#f39c12\"),
          height = 400) %>%
  add_viz(type = \"stackedbar\",
          x_var = \"degree\",
          stack_var = \"happy\",
          title = \"Happiness by Education Level\",
          subtitle = \"Self-reported happiness across education groups\",
          x_label = \"Education\",
          y_label = \"Percentage\",
          stack_label = \"Happiness\",
          stacked_type = \"percent\",
          x_order = c(\"less than high school\", \"high school\",
                      \"associate/junior college\", \"bachelor's\", \"graduate\"),
          stack_order = c(\"very happy\", \"pretty happy\", \"not too happy\"),
          color_palette = c(\"#27ae60\", \"#f39c12\", \"#e74c3c\"),
          height = 450)

charts_page <- create_page(name = \"Charts\", data = gss_clean, icon = \"ph:chart-bar\") %>%
  add_content(chart_vizzes)

# === TIMELINE PAGE ===

timeline_viz <- create_content() %>%
  add_viz(type = \"timeline\",
          time_var = \"year\",
          y_var = \"happy\",
          title = \"Happiness Trends Over Time (1972-2024)\",
          subtitle = \"How has happiness changed across 50+ years?\",
          x_label = \"Year\",
          y_label = \"Percentage\",
          y_levels = c(\"very happy\", \"pretty happy\", \"not too happy\"),
          color_palette = c(\"#27ae60\", \"#f39c12\", \"#e74c3c\"),
          height = 450)

timeline_page <- create_page(name = \"Timeline\", data = gss_time, icon = \"ph:chart-line\") %>%
  add_content(timeline_viz)

# === TEXT & CONTENT PAGE ===

text_content <- create_content() %>%
  add_text(md_text(
    \"This page demonstrates text formatting and content blocks.\",
    \"\",
    \"You can use **bold text**, *italics*, and `inline code`.\",
    \"\",
    \"Lists work too:\",
    \"\",
    \"- First item with **bold**\",
    \"- Second item with *italics*\",
    \"- Third item with `code`\"
  )) %>%
  add_accordion(
    title = \"What is an accordion?\",
    text = \"A collapsible content block. Great for FAQs or code examples.\"
  )

text_page <- create_page(name = \"Text & Content\", icon = \"ph:chalkboard-simple-bold\") %>%
  add_content(text_content)

# === CREATE DASHBOARD ===

dashboard <- create_dashboard(
  output_dir = \"tutorial_dashboard\",
  title = \"Tutorial Dashboard\",
  logo = \"gss_logo.png\",
  theme = \"flatly\"
) %>%
  add_pages(charts_page, timeline_page, text_page)

# Generate the dashboard
generate_dashboard(dashboard)
```"

  # Create tutorial dashboard
  dashboard <- create_dashboard(
    output_dir = qmds_dir,
    title = "Tutorial Dashboard",
    logo = "gss_logo.png",
    allow_inside_pkg = TRUE,
    search = TRUE,
    theme = "flatly",
    navbar_bg_color = "#f0f0f0",
    navbar_text_color = "#3A1B00E6",
    navbar_text_hover_color = "lightgrey",
    author = "dashboardr team",
    description = "This is a tutorial dashboard that demonstrates how to use the functionality and logic.",
    page_footer = "© 2025 dashboardr Package - All Rights Reserved",
    date = "2024-01-15",
    page_navigation = TRUE,
    back_to_top = TRUE,
    reader_mode = FALSE,
    repo_url = "https://github.com/favstats/dashboardr",
    navbar_style = "dark",
    navbar_brand = "Dashboardr",
    navbar_toggle = "collapse",
    math = "katex",
    metrics_style = "bootstrap",
    page_layout = "full",
    publish_dir = directory,
    github_pages = "main"
  ) %>%
    # Landing page with icon
    add_page(
      name = "Welcome",
      content = create_content() %>%
        add_accordion(
          title = "{{< iconify ph code >}} View Full Dashboard Code",
          text = paste0(full_code, '\n\n[{{< iconify ph github-logo >}} View complete R script on GitHub](https://github.com/favstats/dashboardr/blob/main/inst/examples/tutorial_dashboard_code.R)')
        ) %>%
        add_text(md_text(
          "Welcome to the **Tutorial Dashboard**, providing insights into the General Social Survey (GSS) data!",
          "",
          "This dashboard demonstrates how to use the **dashboardr** package to create beautiful, interactive dashboards using real survey data.",
          "",
          "---",
          "",
          "## Dashboard File Structure",
          "",
          "dashboardr generates [Quarto](https://quarto.org) dashboards. Quarto is an open-source publishing system that renders `.qmd` (Quarto Markdown) files into HTML, PDF, and other formats. You write content in Markdown with embedded R code, and Quarto renders it into a polished output.",
          "",
          "When you run `tutorial_dashboard()`, the following files are created:",
          "",
          "```",
          "tutorial_dashboard/",
          "├── _quarto.yml              # Project config (title, theme, navigation)",
          "├── index.qmd                # Landing page (this page)",
          "├── charts.qmd               # Bar and stacked bar charts",
          "├── timeline.qmd             # Time series chart (uses gss_all data)",
          "├── text___content.qmd       # Text and content blocks demo",
          "└── showcase_dashboard.qmd   # Full feature demonstration",
          "```",
          "",
          "**Key files:**",
          "",
          "- **`_quarto.yml`** - The project configuration file. Controls the dashboard title, theme, navbar, and which pages appear in the navigation.",
          "- **`.qmd` files** - Each page is a separate Quarto Markdown file containing text and R code chunks that generate visualizations.",
          "",
          "To render the dashboard, Quarto executes the R code in each `.qmd` file and produces the final HTML. dashboardr handles all the code generation for you!",
          "",
          "---",
          "",
          "## About the Data",
          "",
          "This dashboard uses data from the **General Social Survey (GSS)**, a nationally representative survey of adults in the United States conducted since 1972. We explore patterns in:",
          "",
          "- **Happiness** - Self-reported happiness levels (very happy, pretty happy, not too happy)",
          "- **Education** - Highest degree attained",
          "- **Trends over time** - How attitudes change across 50+ years of surveys (1972-2024)",
          "",
          "## Getting Started with dashboardr",
          "",
          "Each visualization includes a collapsible **View R Code** section showing exactly how it was created."
        )),
      icon = "ph:house",
      is_landing_page = TRUE
    ) %>%
    # Charts page with bar, stackedbar, timeline
    add_page(
      name = "Charts",
      content = create_content() %>%
        add_accordion(
          title = "{{< iconify ph code >}} View Full Page Code",
          text = charts_page_code
        ) %>%
        add_text("This page demonstrates three common chart types: a **bar chart** for counts, and a **stacked bar chart** for proportions.") %>%
        merge_collections(chart_vizzes),
      data = gss_clean,
      icon = "ph:chart-bar"
    ) %>%
    # Add timeline separately with gss_time data
    add_page(
      name = "Timeline",
      content = create_content() %>%
        add_accordion(
          title = "{{< iconify ph code >}} View Full Page Code",
          text = timeline_page_code
        ) %>%
        add_text("The **timeline chart** visualizes trends across the 50+ year history of the GSS (1972-2024).") %>%
        merge_collections(timeline_viz),
      data = gss_time,
      icon = "ph:chart-line"
    ) %>%
    # Text & Content page demonstrating markdown and accordions
    add_page(
      name = "Text & Content",
      icon = "ph:chalkboard-simple-bold",
      content = create_content() %>%
        add_accordion(
          title = "{{< iconify ph code >}} View Full Page Code",
          text = text_page_code
        ) %>%
        add_text(md_text(
          "This page demonstrates text formatting and content blocks available in dashboardr.",
          "",
          "You can use **bold text** for emphasis, *italics* for subtle highlighting, and `inline code` for technical terms or function names like `add_viz()`.",
          "",
          "Combine styles: ***bold and italic*** or **`bold code`**. Add [hyperlinks](https://dashboardr.dev) to external resources.",
          "",
          "Lists work too:",
          "",
          "- First item with **bold**",
          "- Second item with *italics*",
          "- Third item with `code`"
        )) %>%
        add_accordion(
          title = "{{< iconify ph question >}} What is an accordion?",
          text = "An **accordion** is a collapsible content block. Users click to expand and reveal hidden content. Great for FAQs, code examples, or additional details that might clutter the main page."
        ) %>%
        add_accordion(
          title = "{{< iconify ph lightbulb >}} Pro tip: Nested content",
          text = md_text(
            "Inside accordions, you can include:",
            "",
            "- Markdown formatting like **bold** and *italics*",
            "- Code blocks for examples",
            "- Links to documentation",
            "",
            "This keeps your dashboard clean while providing depth for curious users."
          )
        ) %>%
        add_text(md_text(
          "---",
          "",
          "Text-only pages are useful for documentation, methodology notes, data sources, or any context that helps users understand your visualizations."
        ))
    ) %>%
  # Showcase placeholder with link
  add_page(
    name = "Showcase Dashboard",
    icon = "ph:link",
    text = md_text(
      "## {{< iconify ph rocket >}} Explore the Full Showcase",
      "",
      "Ready to see all the features dashboardr has to offer?",
      "",
      "The **Showcase Dashboard** demonstrates the complete power of the dashboardr package, including:",
      "",
      "- **Interactive Filters** - Page sidebars with checkbox, dropdown, and radio filters",
      "- **Value Boxes** - Key metrics at a glance with custom styling",
      "- **Input Controls** - Select, switch, checkbox, radio, and slider inputs",
      "- **Content Blocks** - Callouts, cards, accordions, and more",
      "- **Advanced Visualizations** - Multiple tabset groups with various chart types",
      "",
      "---",
      "",
      "{{< iconify ph arrow-square-out >}} **[Open Showcase Dashboard](../showcase/index.html)**",
      "",
      "Or run it locally:",
      "",
      "```r",
      "library(dashboardr)",
      "showcase_dashboard()",
      "```"
    )
  )  %>%
  add_powered_by_dashboardr(style = "badge", size = "large")

  # Generate the dashboard
  cat("\n=== Generating Dashboard ===\n")
  generate_dashboard(dashboard, render = TRUE, open = open)

  invisible(dashboard) # Return the dashboard object invisibly
}




#' Generate a showcase dashboard demonstrating all dashboardr features.
#'
#' This function creates and renders a comprehensive showcase dashboard that
#' demonstrates the full breadth of the dashboardr package. It includes multiple
#' visualization types, tabset grouping, standalone charts, and various page layouts.
#'
#' @details
#' The showcase dashboard uses General Social Survey (GSS) data to demonstrate:
#' \itemize{
#'   \item Multiple tabset groups (Demographics, Politics, Social Issues)
#'   \item Stacked bar charts with custom styling
#'   \item Heatmaps with custom color palettes
#'   \item Standalone charts without tabsets
#'   \item Text-only pages with card layouts
#'   \item Mixed content pages (text + visualizations)
#'   \item Custom icons throughout
#'   \item All advanced dashboard features
#' }
#'
#' This dashboard is more comprehensive than the tutorial dashboard and showcases
#' the full power of dashboardr for creating complex, multi-page dashboards.
#'
#' @param directory Character string. Directory where the dashboard files will be created.
#'   Defaults to "showcase_dashboard". Quarto will render HTML to directory/docs/.
#' @param open Logical or character. Whether to open the dashboard after rendering.
#'   Use TRUE or "browser" to open in browser (default), FALSE to not open. Default is "browser".
#'
#' @return Invisibly returns the dashboard_project object.
#' @export
#'
#' @examples
#' \dontrun{
#' # Run the showcase dashboard (requires Quarto CLI and 'gssr' package)
#' showcase_dashboard()
#'
#' # Specify custom directory
#' showcase_dashboard(directory = "my_showcase")
#'
#' # Don't open browser
#' showcase_dashboard(open = FALSE)
#' }
showcase_dashboard <- function(directory = "showcase_dashboard", open = "browser") {
  qmds_dir <- directory  # Use directory parameter for QMD files location

  # Ensure output directory exists and copy logo
  if (!dir.exists(qmds_dir)) dir.create(qmds_dir, recursive = TRUE)
  logo_src <- system.file("assets", "gss_logo.png", package = "dashboardr")
  if (file.exists(logo_src)) {
    file.copy(logo_src, file.path(qmds_dir, "gss_logo.png"), overwrite = TRUE)
  }

# Load GSS data for realistic examples
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  dplyr::select(
    age_1a, sex_1a, degree_1a, region_1a,
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, class_1a
  ) %>%
  dplyr::filter(dplyr::if_any(dplyr::everything(), ~ !is.na(.))) %>%
  dplyr::mutate(
    # Convert haven labels to character for cleaner processing
    sex = as.character(haven::as_factor(sex_1a)),
    degree_raw = as.character(haven::as_factor(degree_1a)),
    region = as.character(haven::as_factor(region_1a)),
    happy_raw = as.character(haven::as_factor(happy_1a)),
    trust = as.character(haven::as_factor(trust_1a)),
    polviews = as.character(haven::as_factor(polviews_1a)),
    partyid = as.character(haven::as_factor(partyid_1a)),
    class_raw = as.character(haven::as_factor(class_1a)),
    age = as.numeric(age_1a),
    # Recode education levels
    degree = dplyr::case_match(
      degree_raw,
      "Lt High School" ~ "less than high school",
      "High School" ~ "high school",
      "Junior College" ~ "associate/junior college",
      "Bachelor" ~ "bachelor's",
      "Graduate" ~ "graduate",
      .default = degree_raw
    ),
    # Recode happiness to lowercase
    happy = dplyr::case_match(
      happy_raw,
      "Very Happy" ~ "very happy",
      "Pretty Happy" ~ "pretty happy",
      "Not Too Happy" ~ "not too happy",
      .default = tolower(happy_raw)
    ),
    # Recode social class
    class = dplyr::case_match(
      class_raw,
      "Lower Class" ~ "lower class",
      "Working Class" ~ "working class",
      "Middle Class" ~ "middle class",
      "Upper Class" ~ "upper class",
      .default = tolower(class_raw)
    )
  ) %>%
  dplyr::filter(!is.na(age), !is.na(sex), !is.na(degree))

# Demographics page: diverse chart types showing age, education, happiness
# Tab 1: Happiness - stackedbar + boxplot
# Tab 2: Age Distribution - histogram + density
# Tab 3: Education - bar chart + heatmap
analysis_vizzes <- create_content() %>%
  # Tab 1: Happiness
  add_viz(type = "stackedbar",
          x_var = "degree",
          stack_var = "happy",
          title = "Happiness by Education Level",
          subtitle = "How does education relate to self-reported happiness?",
          x_label = "Education Level",
          y_label = "Percentage",
          stack_label = "Happiness",
          stacked_type = "percent",
          x_order = c("less than high school", "high school", "associate/junior college", "bachelor's", "graduate"),
          stack_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450,
          tabgroup = "happiness") %>%
  add_viz(type = "boxplot",
          x_var = "happy",
          y_var = "age",
          title = "Age Distribution by Happiness Level",
          subtitle = "Are happier people younger or older?",
          x_label = "Happiness Level",
          y_label = "Age (years)",
          x_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450,
          tabgroup = "happiness") %>%
  # Tab 2: Age Distribution
  add_viz(type = "histogram",
          x_var = "age",
          title = "Age Distribution of Respondents",
          subtitle = "Overall age distribution in the GSS sample",
          x_label = "Age (years)",
          y_label = "Count",
          bins = 25,
          color_palette = c("#3498db"),
          height = 400,
          tabgroup = "age") %>%
  add_viz(type = "density",
          x_var = "age",
          group_var = "sex",
          title = "Age Distribution by Gender",
          subtitle = "Comparing age distributions between men and women",
          x_label = "Age (years)",
          color_palette = c("#3498db", "#e74c3c"),
          height = 400,
          tabgroup = "age") %>%
  # Tab 3: Education patterns
  add_viz(type = "bar",
          x_var = "degree",
          title = "Education Level Distribution",
          subtitle = "Sample composition by highest degree attained",
          x_label = "Education Level",
          y_label = "Count",
          x_order = c("less than high school", "high school", "associate/junior college", "bachelor's", "graduate"),
          color_palette = c("#1abc9c", "#3498db", "#9b59b6", "#e74c3c", "#f39c12"),
          height = 400,
          tabgroup = "education") %>%
  add_viz(type = "heatmap",
          x_var = "degree",
          y_var = "region",
          value_var = "age",
          title = "Mean Age by Education and Region",
          subtitle = "Geographic and educational patterns in respondent age",
          x_label = "Education Level",
          y_label = "Region",
          value_label = "Mean Age",
          x_order = c("less than high school", "high school", "associate/junior college", "bachelor's", "graduate"),
          color_palette = c("#f7fbff", "#deebf7", "#9ecae1", "#3182bd", "#08519c"),
          data_labels_enabled = TRUE,
          tooltip_labels_format = "{point.value:.1f}",
          height = 500,
          tabgroup = "education") %>%
  set_tabgroup_labels(list(
    happiness = "Happiness",
    age = "Age Distribution",
    education = "Education"
  ))

# Political Attitudes page: diverse visualizations
summary_vizzes <- create_content() %>%
  # Happiness by political ideology - stackedbar (ordered liberal to conservative)
  add_viz(type = "stackedbar",
          x_var = "polviews",
          stack_var = "happy",
          title = "Happiness by Political Ideology",
          subtitle = "How happiness varies across the political spectrum",
          x_label = "Political Views",
          y_label = "Percentage",
          stack_label = "Happiness",
          stacked_type = "percent",
          x_order = c("extremely liberal", "liberal", "slightly liberal",
                      "moderate, middle of the road",
                      "slightly conservative", "conservative", "extremely conservative"),
          stack_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 500) %>%
  # Heatmap by ideology and social class
  add_viz(type = "heatmap",
          x_var = "polviews",
          y_var = "class",
          value_var = "age",
          title = "Mean Age by Ideology and Social Class",
          subtitle = "Demographic patterns across political and class lines",
          x_label = "Political Views",
          y_label = "Social Class",
          value_label = "Mean Age",
          x_order = c("extremely liberal", "liberal", "slightly liberal",
                      "moderate, middle of the road",
                      "slightly conservative", "conservative", "extremely conservative"),
          y_order = c("lower class", "working class", "middle class", "upper class"),
          color_palette = c("#f7fbff", "#c6dbef", "#6baed6", "#2171b5", "#08306b"),
          data_labels_enabled = TRUE,
          tooltip_labels_format = "{point.value:.1f}",
          height = 450) %>%
  # Political ideology by gender - bar chart
  add_viz(type = "bar",
          x_var = "polviews",
          group_var = "sex",
          title = "Political Ideology by Gender",
          subtitle = "Distribution of political views across genders",
          x_label = "Political Views",
          y_label = "Count",
          x_order = c("extremely liberal", "liberal", "slightly liberal",
                      "moderate, middle of the road",
                      "slightly conservative", "conservative", "extremely conservative"),
          color_palette = c("#3498db", "#e74c3c"),
          height = 400)

# Trust & Social Capital page with sidebar filters
# NEW: Filters now use cross-tab client-side aggregation for true data filtering!
# filter_var can be ANY column - the chart will recalculate based on selections
sidebar_content <- create_content(data = gss_clean) %>%
  add_sidebar(width = "280px", title = "Filter Data") %>%
    add_input(
      input_id = "education_filter",
      label = "Education Level:",
      type = "radio",
      filter_var = "degree",
      stacked = T, ncol = 2, add_all = T,
      stacked_align = "center",
      group_align = "center",
      options = c("less than high school", "high school", "associate/junior college",
                  "bachelor's", "graduate"),
      default_selected = c("less than high school", "high school", "associate/junior college",
                           "bachelor's", "graduate")
    ) %>%
    add_input(
      input_id = "gender_filter",
      label = "Gender:",
      type = "checkbox",
      stacked = T, ncol = 2, add_all = T,
      stacked_align = "center",
      group_align = "center",
      filter_var = "sex",
      options = c("male", "female"),
      default_selected = c("male", "female")
    ) %>%
  end_sidebar() %>%
  # Happiness by region - stackedbar (will recalculate based on education/gender filters)
  add_viz(type = "stackedbar",
          x_var = "region",
          stack_var = "happy",
          title = "Happiness by Region",
          subtitle = "Filter by education and gender to see how happiness varies",
          x_label = "Region",
          y_label = "Percentage",
          stack_label = "Happiness",
          stacked_type = "percent",
          stack_order = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 550)

# Calculate metrics for value boxes (handling haven labels)
n_respondents <- format(nrow(gss_clean), big.mark = ",")
n_regions <- length(unique(as.character(gss_clean$region_1a)))

# Full code for the landing page accordion
showcase_code <- '```r
library(dashboardr)
library(gssr)
library(dplyr)

# Load and prepare GSS data
data(gss_all)
gss_clean <- gss_all %>%
  filter(year >= 2010) %>%
  mutate(
    sex = haven::as_factor(sex),
    degree = haven::as_factor(degree),
    happy = haven::as_factor(happy),
    region = haven::as_factor(region),
    polviews = haven::as_factor(polviews),
    partyid = haven::as_factor(partyid)
  ) %>%
  filter(!is.na(age), !is.na(sex), !is.na(degree))

# Create visualizations with nested tabsets
analysis_vizzes <- create_content() %>%
  add_viz(type = "stackedbar",
          x_var = "degree", stack_var = "happy",
          title = "Happiness by Education",
          tabgroup = "happiness") %>%
  add_viz(type = "boxplot",
          x_var = "happy", y_var = "age",
          title = "Age by Happiness",
          tabgroup = "happiness") %>%
  add_viz(type = "histogram",
          x_var = "age",
          title = "Age Distribution",
          tabgroup = "age")

# Create dashboard with value boxes
dashboard <- create_dashboard(
  output_dir = "showcase_dashboard",
  title = "GSS Data Explorer",
  theme = "flatly"
) %>%
  add_page(
    name = "Overview",
    content = create_content() %>%
      add_value_box_row() %>%
        add_value_box(title = "Respondents", value = "2,849") %>%
        add_value_box(title = "Very Happy", value = "32%") %>%
      end_value_box_row(),
    is_landing_page = TRUE
  ) %>%
  add_page(
    name = "Demographics",
    data = gss_clean,
    content = analysis_vizzes
  )

# Generate
generate_dashboard(dashboard)
```'

# Create comprehensive dashboard

dashboard <- create_dashboard(
  output_dir = qmds_dir,
  title = "GSS Data Explorer",
  logo = "gss_logo.png",
  allow_inside_pkg = TRUE,
  github = "https://github.com/favstats/dashboardr",
  search = TRUE,
  theme = "flatly",
  navbar_bg_color = "#f0f0f0",
  navbar_text_color = "#3A1B00E6",
  navbar_text_hover_color = "lightgrey",
  author = "GSS Research Team",
  description = "Comprehensive data analysis dashboard with all features",
  page_footer = "© 2025 dashboardr Package - All Rights Reserved",
  date = "2024-01-15",
  tabset_theme = "minimal",
  page_navigation = TRUE,
  back_to_top = TRUE,
  reader_mode = TRUE,
  repo_url = "https://github.com/favstats/dashboardr",
  navbar_style = "dark",
  navbar_brand = "Dashboardr",
  navbar_toggle = "collapse",
  math = "katex",
  code_folding = "show",
  code_tools = TRUE,
  # toc = "floating",
  # toc_depth = 3,
  value_boxes = TRUE,
  metrics_style = "bootstrap",
  page_layout = "full",
  publish_dir = directory,
  github_pages = "main",
  netlify = list(redirects = "/* /index.html 200")
) %>%
  # Landing page with KPIs
  add_page(
    name = "Overview",
    text = md_text(
      "# General Social Survey 2020",
      "",
      "Exploring happiness, trust, and social attitudes across America."
    ),
    content = create_content() %>%
      add_accordion(
        title = "{{< iconify ph code >}} View Full Dashboard Code",
        text = paste0(showcase_code, '\n\n[View full showcase_dashboard source code](https://github.com/favstats/dashboardr/blob/main/R/tutorial_dashboard.R)')
      ) %>%
      add_value_box_row() %>%
        add_value_box(
          title = "Total Respondents",
          value = n_respondents,
          logo_text = "N",
          bg_color = "#3498db",
          description = "Complete survey responses"
        ) %>%
        add_value_box(
          title = "Very Happy",
          value = "32%",
          logo_text = "{{< iconify ph smiley >}}",
          bg_color = "#27ae60",
          description = "Report being very happy"
        ) %>%
        add_value_box(
          title = "Trust Others",
          value = "34%",
          logo_text = "{{< iconify ph handshake >}}",
          bg_color = "#9b59b6",
          description = "Believe most people can be trusted"
        ) %>%
      end_value_box_row() %>%
      add_value_box_row() %>%
        add_value_box(
          title = "College Educated",
          value = "28%",
          logo_text = "{{< iconify ph graduation-cap >}}",
          bg_color = "#f39c12",
          description = "Hold bachelor's degree or higher"
        ) %>%
        add_value_box(
          title = "Regions",
          value = as.character(n_regions),
          logo_text = "{{< iconify ph map-pin >}}",
          bg_color = "#e74c3c",
          description = "Geographic regions covered"
        ) %>%
        add_value_box(
          title = "Survey Year",
          value = "2020",
          logo_text = "{{< iconify ph calendar >}}",
          bg_color = "#1abc9c",
          description = "Data collection period"
        ) %>%
      end_value_box_row() %>%
      add_text("---") %>%
      add_text("## Quick Navigation") %>%
      add_text("[{{< iconify ph users-three >}} Demographics](demographics.html) - Explore happiness and wellbeing by demographic groups") %>%
      add_text("") %>%
      add_text("[{{< iconify ph handshake >}} Trust & Social Capital](trust___social_capital.html) - Filter and explore trust patterns across regions") %>%
      add_text("") %>%
      add_text("[{{< iconify ph chart-bar >}} Political Attitudes](political_attitudes.html) - Party identification and ideology breakdowns") %>%
      add_text("") %>%
      add_text("[{{< iconify ph info >}} About](about.html) - Data sources and methodology"),
    icon = "ph:house",
    is_landing_page = TRUE
  ) %>%
  # Demographics page with nested tabsets
  add_page(
    name = "Demographics",
    text = md_text(
      "Explore how happiness, trust, and wellbeing vary across demographic groups.",
      "",
      "Use the tabs below to examine different aspects of the data."
    ),
    data = gss_clean,
    content = analysis_vizzes,
    icon = "ph:users-three"
  ) %>%
  # Trust page with sidebar and interactive filters
  add_page(
    name = "Trust & Social Capital",
    text = md_text(
      "Use the filters to explore regional patterns in social trust."
    ),
    data = gss_clean,
    content = sidebar_content,
    icon = "ph:handshake"
  ) %>%
  # Political attitudes page
  add_page(
    name = "Political Attitudes",
    text = md_text(
      "Party identification and ideological views across different groups."
    ),
    data = gss_clean,
    content = summary_vizzes,
    icon = "ph:chart-bar"
  ) %>%
  # About page
  add_page(
    name = "About",
    icon = "ph:info",
    text = md_text(
      "## About the General Social Survey",
      "",
      "The **General Social Survey (GSS)** is a nationally representative survey of adults in the United States, conducted since 1972 by NORC at the University of Chicago.",
      "",
      "The GSS monitors societal change and the growing complexity of American society. It is one of the most frequently analyzed sources of information in the social sciences.",
      "",
      "**Learn more:** [GSS Website](https://gss.norc.org/)",
      "",
      "---",
      "",
      "## Variables in This Dashboard",
      "",
      "| Variable | Description |",
      "|----------|-------------|",
      "| **Happiness** | Self-reported general happiness (Very Happy, Pretty Happy, Not Too Happy) |",
      "| **Trust** | Interpersonal trust (Can Trust, Can't Be Too Careful, Depends) |",
      "| **Education** | Highest degree attained |",
      "| **Political Views** | Liberal-conservative self-placement |",
      "| **Party ID** | Political party identification |",
      "| **Region** | Census region of residence |",
      "| **Age** | Respondent's age |",
      "| **Gender** | Respondent's gender |",
      "",
      "---",
      "",
      "## Data Citation",
      "",
      "Smith, Tom W., Davern, Michael, Freese, Jeremy, and Morgan, Stephen L., General Social Surveys, 1972-2022 [machine-readable data file].",
      "Principal Investigator, Tom W. Smith; Co-Principal Investigators, Michael Davern, Jeremy Freese and Stephen L. Morgan; Sponsored by National Science Foundation.",
      "",
      "---",
      "",
      "*This dashboard was created with [dashboardr](https://github.com/favstats/dashboardr).*"
    )
  ) %>%
  add_powered_by_dashboardr(style = "badge", size = "large")

# Generate the dashboard
cat("\n=== Generating Dashboard ===\n")
generate_dashboard(dashboard, render = TRUE, open = open)

invisible(dashboard) # Return the dashboard object invisibly
}
