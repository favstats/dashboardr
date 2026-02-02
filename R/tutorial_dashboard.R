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

  # Load GSS data for realistic examples
  data(gss_panel20, package = "gssr")
  gss_clean <- gss_panel20 %>%
    dplyr::select(
      age_1a, sex_1a, degree_1a, region_1a,
      happy_1a, trust_1a, fair_1a, helpful_1a,
      polviews_1a, partyid_1a, class_1a
    ) %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(), ~ !is.na(.)))

  # Create visualizations using examples from stackedbar_vignette.Rmd
  # Using create_content() to interleave visualizations with code accordions
  analysis_vizzes <- create_content() %>%
    # First tabset: Demographics (2 visualizations)
    add_viz(type = "stackedbar",
            x_var = "degree_1a",
            stack_var = "happy_1a",
            title = "Change the title here...",
            subtitle = "You can add a subtitle using the subtitle argument",
            x_label = "Education Level",
            y_label = "Percentage of Respondents",
            stack_label = "Happiness Level",
            stacked_type = "percent",
            x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
            stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
            tooltip_suffix = "%",
            color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
            text = "If you want to add text within the tab, you can do so here.",
            text_position = "above",
            icon = "ph:chart-bar",
            height = 500,
            tabgroup = "demographics") %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "Change the title here...",
        subtitle = "You can add a subtitle using the subtitle argument",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "If you want to add text within the tab, you can do so here.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 500,
        tabgroup = "demographics")
```
[Full documentation](../articles/tutorial_dashboard_code.html#stacked-bar-happiness-education)',
      tabgroup = "demographics"
    ) %>%
    add_viz(type = "stackedbar",
            x_var = "sex_1a",
            stack_var = "happy_1a",
            title = "Tabset #2",
            subtitle = "Another example subtitle here!",
            x_label = "Gender",
            y_label = "Percentage of Respondents",
            stack_label = "Happiness Level",
            stacked_type = "percent",
            stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
            tooltip_suffix = "%",
            color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
            text = "Change the position of the text using the `text_position` argument.",
            text_position = "below",
            icon = "ph:gender-intersex",
            height = 450,
            tabgroup = "demographics") %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "stackedbar",
        x_var = "sex_1a",
        stack_var = "happy_1a",
        title = "Tabset #2",
        subtitle = "Another example subtitle here!",
        x_label = "Gender",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "Change the position of the text using the `text_position` argument.",
        text_position = "below",
        icon = "ph:gender-intersex",
        height = 450,
        tabgroup = "demographics")
```
[Full documentation](../articles/tutorial_dashboard_code.html#stacked-bar-happiness-gender)',
      tabgroup = "demographics"
    ) %>%
    # Second tabset: Social Issues (2 visualizations)
    add_viz(type = "heatmap",
            x_var = "degree_1a",
            y_var = "age_1a",
            value_var = "trust_1a",
            title = "Trust by Education and Age",
            subtitle = "Average trust levels across education and age groups",
            x_label = "Example x axis",
            y_label = "Customizable y label",
            value_label = "You can change the label here too...",
            x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
            color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
            tooltip_prefix = "Trust: ",
            tooltip_suffix = "/3",
            tooltip_labels_format = "{point.value:.2f}",
            text = "Here's another example of the kind of plots you can generate in your dashboard.",
            text_position = "above",
            icon = "ph:heatmap",
            height = 600,
            tabgroup = "social") %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "heatmap",
        x_var = "degree_1a",
        y_var = "age_1a",
        value_var = "trust_1a",
        title = "Trust by Education and Age",
        subtitle = "Average trust levels across education and age groups",
        x_label = "Example x axis",
        y_label = "Customizable y label",
        value_label = "You can change the label here too...",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Heres another example of the kind of plots you can generate in your dashboard.",
        text_position = "above",
        icon = "ph:heatmap",
        height = 600,
        tabgroup = "social")
```
[Full documentation](../articles/tutorial_dashboard_code.html#heatmap-trust-education-age)',
      tabgroup = "social"
    ) %>%
    add_viz(type = "heatmap",
            x_var = "region_1a",
            y_var = "degree_1a",
            value_var = "trust_1a",
            title = "Trust by Region and Education",
            subtitle = "Educational and regional patterns in trust levels",
            x_label = "Region",
            y_label = "Education Level",
            value_label = "Trust Level",
            y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
            color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
            tooltip_prefix = "Trust: ",
            tooltip_suffix = "/3",
            tooltip_labels_format = "{point.value:.2f}",
            text = "Educational and regional patterns in trust distribution.",
            text_position = "above",
            icon = "ph:chart-pie",
            height = 550,
            tabgroup = "social") %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "heatmap",
        x_var = "region_1a",
        y_var = "degree_1a",
        value_var = "trust_1a",
        title = "Trust by Region and Education",
        subtitle = "Educational and regional patterns in trust levels",
        x_label = "Region",
        y_label = "Education Level",
        value_label = "Trust Level",
        y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Educational and regional patterns in trust distribution.",
        text_position = "above",
        icon = "ph:chart-pie",
        height = 550,
        tabgroup = "social")
```
[Full documentation](../articles/tutorial_dashboard_code.html#heatmap-trust-region-education)',
      tabgroup = "social"
    ) %>%
    # Set custom tab group labels
    set_tabgroup_labels(list(
      demographics = "Example 1: Stacked Bars",
      social = "Example 2: Heatmap"
    ))

  # Create additional visualizations for a second page with single charts
  # Using create_content() to interleave visualizations with code accordions
  summary_vizzes <- create_content() %>%
    # Single chart (no tabgroup) - will be standalone
    add_viz(type = "stackedbar",
            x_var = "degree_1a",
            stack_var = "happy_1a",
            title = "This is a standalone chart.",
            subtitle = "Here you'll notice that this is a standalone plot.",
            x_label = "Education Level",
            y_label = "Percentage of Respondents",
            stack_label = "Happiness Level",
            stacked_type = "percent",
            x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
            stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
            tooltip_suffix = "%",
            color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
            text = "This standalone chart shows the overall distribution of happiness across education levels.",
            text_position = "above",
            icon = "ph:chart-bar",
            height = 600) %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "This is a standalone chart.",
        subtitle = "Here youll notice that this is a standalone plot.",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "This standalone chart shows the overall distribution of happiness across education levels.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 600)
```
[Full documentation](../articles/tutorial_dashboard_code.html#standalone-happiness-education)'
    ) %>%
    # Another single chart
    add_viz(type = "heatmap",
            x_var = "partyid_1a",
            y_var = "polviews_1a",
            value_var = "trust_1a",
            title = "Here's another summary chart",
            subtitle = "This summary chart visualizes trust patterns across political groups",
            x_label = "Party Identification",
            y_label = "Political Views",
            value_label = "Trust Level",
            x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                        "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
            y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                        "Slightly Conservative", "Conservative", "Extremely Conservative"),
            color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
            tooltip_prefix = "Trust: ",
            tooltip_suffix = "/3",
            tooltip_labels_format = "{point.value:.2f}",
            text = "Subtitle for your standalone chart.",
            text_position = "below",
            icon = "ph:shield-check",
            height = 700) %>%
    add_accordion(
      title = "{{< iconify ph code >}} View R Code",
      text = '```r
add_viz(type = "heatmap",
        x_var = "partyid_1a",
        y_var = "polviews_1a",
        value_var = "trust_1a",
        title = "Heres another summary chart",
        subtitle = "This summary chart visualizes trust patterns across political groups",
        x_label = "Party Identification",
        y_label = "Political Views",
        value_label = "Trust Level",
        x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                    "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
        y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                    "Slightly Conservative", "Conservative", "Extremely Conservative"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Subtitle for your standalone chart.",
        text_position = "below",
        icon = "ph:shield-check",
        height = 700)
```
[Full documentation](../articles/tutorial_dashboard_code.html#standalone-trust-politics)'
    )

  # Create tutorial dashboard
  dashboard <- create_dashboard(
    output_dir = qmds_dir,
    title = "Tutorial Dashboard",
    logo = "https://ropercenter.cornell.edu/sites/default/files/styles/600x/public/Images/GSSLogo6x4.png?itok=ZzGhUDbL",
    allow_inside_pkg = TRUE,
    search = TRUE,
    theme = "flatly",
    author = "dashboardr team",
    description = "This is a tutorial dashboard that demonstrates how to use the functionality and logic.",
    page_footer = "© 2025 dashboardr Package - All Rights Reserved",
    date = "2024-01-15",
    breadcrumbs = TRUE,
    page_navigation = TRUE,
    back_to_top = TRUE,
    reader_mode = FALSE,
    repo_url = "https://github.com/favstats/dashboardr",
    navbar_style = "dark",
    navbar_brand = "Dashboardr",
    navbar_toggle = "collapse",
    math = "katex",
    code_folding = "show",
    code_tools = TRUE,
    # toc = "floating",
    # toc_depth = 3,
    google_analytics = "GA-XXXXXXXXX",
    plausible = "example.com",
    gtag = "GTM-XXXXXXX",
    value_boxes = TRUE,
    metrics_style = "bootstrap",
    page_layout = "full",
    shiny = FALSE,
    publish_dir = directory,
    github_pages = "main",
    netlify = list(redirects = "/* /index.html 200")
  ) %>%
    # Landing page with icon - DigIQ Monitor style
    add_page(
      name = "Welcome to the Tutorial Dashboard!",
      text = md_text(
        "Welcome to the **Tutorial Dashboard**, providing insights into the General Social Survey (GSS) data!",
        "",
        "This dashboard demonstrates how to use the **dashboardr** package to create beautiful, interactive dashboards using real survey data.",
        "",
        "The tutorial is divided into main sections:",
        "",
        "[{{< iconify ph chart-line >}} Example Dashboard](example_dashboard.html) - Tabbed visualizations with stacked bars and heatmaps",
        "",
        "[{{< iconify ph chart-pie >}} Standalone Charts](standalone_charts.html) - Charts without tabsets",
        "",
        "[{{< iconify ph chalkboard-simple >}} Text Page](text_only_page.html) - Text-only content example",
        "",
        "[{{< iconify ph link >}} Showcase Dashboard](showcase_dashboard.html) - Full feature demonstration",
        "",
        "{{< iconify ph cursor-click-fill >}} Click on the hyperlinks above for quick navigation.",
        "",
        "---",
        "",
        "## Dashboard File Structure",
        "",
        "When you create a dashboard with dashboardr, the following files are generated:",
        "",
        "```",
        "tutorial_dashboard/",
        "├── _quarto.yml",
        "├── index.qmd",
        "├── example_dashboard.qmd",
        "├── standalone_charts.qmd",
        "├── text_only_page.qmd",
        "└── showcase_dashboard.qmd",
        "```",
        "",
        "---",
        "",
        "## About the Data",
        "",
        "This dashboard uses data from the **General Social Survey (GSS)**, a nationally representative survey of adults in the United States conducted since 1972. We explore patterns in:",
        "",
        "- **Happiness** - Self-reported happiness levels",
        "- **Trust** - Interpersonal trust measures",
        "- **Political attitudes** - Party identification and ideological views",
        "",
        "## Getting Started with dashboardr",
        "",
        "Each visualization includes a collapsible **View R Code** section showing exactly how it was created. Click the accordion to see the code and link to full documentation."
      ),
      content = create_content() %>%
        add_accordion(
          title = "{{< iconify ph code >}} View Full Dashboard Code",
          text = '```r
library(dashboardr)
library(dplyr)

# Load GSS data
data(gss_panel20, package = "gssr")
gss_clean <- gss_panel20 %>%
  select(age_1a, sex_1a, degree_1a, region_1a,
         happy_1a, trust_1a, fair_1a, helpful_1a,
         polviews_1a, partyid_1a, class_1a) %>%
  filter(if_any(everything(), ~ !is.na(.)))

# Create visualizations
analysis_vizzes <- create_content() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a", stack_var = "happy_1a",
          title = "Happiness by Education",
          tabgroup = "demographics") %>%
  add_viz(type = "heatmap",
          x_var = "degree_1a", y_var = "age_1a", value_var = "trust_1a",
          title = "Trust by Education and Age",
          tabgroup = "social")

# Create dashboard
create_dashboard(
  output_dir = "my_dashboard",
  title = "My Dashboard",
  logo = "logo.png",
  theme = "flatly"
) %>%
  add_page(name = "Welcome", text = "Landing page content",
           icon = "ph:house", is_landing_page = TRUE) %>%
  add_page(name = "Analysis", data = gss_clean,
           content = analysis_vizzes, icon = "ph:chart-line") %>%
  generate_dashboard()
```
[View full tutorial_dashboard.R source code](https://github.com/favstats/dashboardr/blob/main/R/tutorial_dashboard.R)'
        ),
      icon = "ph:house",
      is_landing_page = TRUE
    ) %>%
    # Analysis page with data and visualizations
    add_page(
      name = "Example Dashboard",
      text = md_text(
        "Here, you can see how to add text within a dashboard.",
        "",
        "## Add a new heading like this",
        "",
        "A line break is displayed when you add a new section."
      ),
      data = gss_clean,
      content = analysis_vizzes,
      icon = "ph:chart-line"
    ) %>%
    # Summary page with standalone charts (no tabsets)
    add_page(
      name = "Standalone Charts",
      text = md_text(
        "This page demonstrates standalone charts (no tabsets) for key findings.",
        "",
        "For example, you could use this layout to visualize the most important trends or overarching themes of your data."
      ),
      data = gss_clean,
      content = summary_vizzes,
      icon = "ph:chart-pie"
    )  %>%
    # Text-only page with icon showcasing card function
    add_page(
      name = "Text-Only Page",
      icon = "ph:chalkboard-simple-bold",
      text = md_text(
        "You can also have a text-only page in your dashboard.",
        "",
        "This might be useful if you want to add some context or extra information about your plots."
      )
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
          height = 450) %>%
  # Social class distribution - bar chart
  add_viz(type = "bar",
          x_var = "class",
          group_var = "sex",
          title = "Social Class by Gender",
          subtitle = "Self-reported social class distribution",
          x_label = "Social Class",
          y_label = "Count",
          x_order = c("lower class", "working class", "middle class", "upper class"),
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
      type = "checkbox",
      filter_var = "degree",
      options = c("less than high school", "high school", "associate/junior college", 
                  "bachelor's", "graduate"),
      default_selected = c("less than high school", "high school", "associate/junior college", 
                           "bachelor's", "graduate")
    ) %>%
    add_input(
      input_id = "gender_filter",
      label = "Gender:",
      type = "checkbox",
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

# Create comprehensive dashboard

dashboard <- create_dashboard(
  output_dir = qmds_dir,
  title = "GSS Data Explorer",
  logo = "https://ropercenter.cornell.edu/sites/default/files/styles/600x/public/Images/GSSLogo6x4.png?itok=ZzGhUDbL",
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
  # sidebar = TRUE,
  # sidebar_style = "docked",
  # sidebar_background = "light",
  # sidebar_foreground = "dark",
  # sidebar_border = TRUE,
  # sidebar_alignment = "left",
  # sidebar_collapse_level = 2,
  # sidebar_pinned = FALSE,
  # sidebar_tools = list(
  #   list(icon = "github", href = "https://github.com/username/dashboardr", text = "Source Code"),
  #   list(icon = "twitter", href = "https://twitter.com/username", text = "Follow Us")
  # ),
  breadcrumbs = TRUE,
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
  google_analytics = "GA-XXXXXXXXX",
  plausible = "example.com",
  gtag = "GTM-XXXXXXX",
  value_boxes = TRUE,
  metrics_style = "bootstrap",
  page_layout = "full",
  shiny = TRUE,
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
