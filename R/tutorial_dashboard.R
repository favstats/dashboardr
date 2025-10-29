#' Generate a tutorial dashboard.
#'
#' This function creates and renders a detailed tutorial dashboard showcasing
#' various features of the dashboardr package. It includes examples of
#' stacked bar charts, heatmaps, multiple pages, and custom components.
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
#' }
tutorial_dashboard <- function() {

  # Load GSS data for realistic examples
  data(gss_panel20, package = "gssr") # Data is now handled by the function scope
  # Ensure gssr is imported and available via NAMESPACE
  gss_clean <- gss_panel20 %>%
    dplyr::select(
      age_1a, sex_1a, degree_1a, region_1a,
      happy_1a, trust_1a, fair_1a, helpful_1a,
      polviews_1a, partyid_1a, class_1a
    ) %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(), ~ !is.na(.)))

  # Create visualizations using examples from stackedbar_vignette.Rmd
  analysis_vizzes <- create_viz() %>%
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
    add_viz(type = "stackedbar",
            x_var = "sex_1a",
            stack_var = "happy_1a",
            title = "Tabset #2",
            subtitle = "Gender differences in reported happiness levels",
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
    # Second tabset: Social Issues (2 visualizations)
    add_viz(type = "heatmap",
            x_var = "degree_1a",
            y_var = "age_1a",
            value_var = "trust_1a",
            title = "Trust by Education and Age",
            subtitle = "Average trust levels across education and age groups",
            x_label = "Education Level",
            y_label = "Age Group",
            value_label = "Trust Level",
            x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
            color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
            tooltip_prefix = "Trust: ",
            tooltip_suffix = "/3",
            data_labels_format = "{point.value:.2f}",
            text = "This heatmap reveals trust patterns across education and age groups.",
            text_position = "below",
            icon = "ph:heatmap",
            height = 600,
            tabgroup = "social") %>%
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
            data_labels_format = "{point.value:.2f}",
            text = "Educational and regional patterns in trust distribution.",
            text_position = "above",
            icon = "ph:chart-pie",
            height = 550,
            tabgroup = "social") %>%
    # Set custom tab group labels
    set_tabgroup_labels(list(
      demographics = "Example 1: Stacked Bars",
      social = "Example 2: Heatmap"
    ))

  # Create additional visualizations for a second page with single charts
  # Renamed 'single_viz' to 'summary_vizzes' to resolve the "object not found" error
  summary_vizzes <- create_viz() %>%
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
    # Another single chart
    add_viz(type = "heatmap",
            x_var = "partyid_1a",
            y_var = "polviews_1a",
            value_var = "trust_1a",
            title = "Overall Trust by Politics",
            subtitle = "Complete trust patterns across political groups",
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
            data_labels_format = "{point.value:.2f}",
            text = "This standalone heatmap shows trust patterns across political groups.",
            text_position = "below",
            icon = "ph:shield-check",
            height = 700)

  # Create comprehensive dashboard with ALL features
  dashboard <- create_dashboard(
    output_dir = "tutorial_dashboard",
    title = "Tutorial Dashboard",
    # github = "https://github.com/favstats/dashboardr",
    # twitter = "https://twitter.com/username",
    # linkedin = "https://linkedin.com/in/username",
    # email = "user@example.com",
    # website = "https://example.com",
    search = TRUE,
    # theme = "cosmo", # Commented out as it's not a direct default for Quarto
    author = "dashboardr team",
    description = "This is a tutorial dashboard that demonstrates how to use the functionality and logic.",
    page_footer = "© 2025 dashboardr Package - All Rights Reserved",
    date = "2024-01-15",
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
    repo_url = "https://github.com/username/dashboardr",
    repo_actions = c("edit", "source", "issue"),
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
    publish_dir = "docs",
    github_pages = "main",
    netlify = list(redirects = "/* /index.html 200")
  ) %>%
    # Landing page with icon
    add_page(
      name = "Welcome to the Tutorial Dashboard!",
      text = md_text(
        "Thank you for downloading and using Dashboardr. We hope that you'll find it helpful and fun to use.",
        "",
        "## How to use this package",
        "Here's some information that you might find handy while you learn to use the package.",
        "This is a tutorial dashboard, which means that these pages were written by us, and are saved in the `dashboardr` R package.",
        "However, when you decide to call `create_dashboard()` using your own or sample data, an output directory will be generated.",
        "",
        "## Locating your dashboard",
        "Unless otherwise specified, your dashboard lives in the output directory! For example:",
        "",
        "C:/Users/user/test_dashboard",
        "├── index.qmd",
        "",
        "├── example_dashboard.qmd",
        "",
        "├── standalone_charts.qmd",
        "",
        "├── text_only_page.qmd",
        "",
        "└── showcase_dashboard.qmd",
        "",
        "## Editing your dashboard after rendering",
        "You'll also have the option to write a new GitHub repository. `dashboardr` will tell you where it is saved upon rendering.",
        "",
        "If you'd like to edit your pages further, you can do so by navigating to the output directory and editing the .qmd files manually.
        If that doesn't suit you, then you can also create visualizations with `create_viz() %>% add_viz()`, and build out the dashboard with `add_page()`.",
        "",
        "For an example of a dashboard that demonstrates the full breadth of this package, click on the Showcase tab on the toolbar above.
        This tutorial dashboard demonstrates the `dashboardr` package using real examples from the vignettes.",
        "",
        "## About this tutorial dashboard",
        "This dashboard uses data from the **General Social Survey (GSS)** to explore patterns in happiness, trust, and political attitudes.",
        "",
        "Navigate through the pages above to explore the data and see the package features in action."
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
      visualizations = analysis_vizzes,
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
      visualizations = summary_vizzes, # This now references the defined summary_vizzes
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
  # Showcase placeholder
  add_page(
    name = "Showcase Dashboard",
    icon = "ph:link",
    text = md_text(
      "This is a placeholder for a link to the showcase dashboard."
    )
  )

  # Generate the dashboard
  cat("\n=== Generating Dashboard ===\n")
  generate_dashboard(dashboard, render = TRUE, open = "browser")

  invisible(dashboard) # Return the dashboard object invisibly
}
