#' Generate an ASCoR-themed dashboard for the University of Amsterdam
#'
#' This function creates and renders a professional dashboard with ASCoR 
#' (Amsterdam School of Communication Research) and University of Amsterdam branding. 
#' The dashboard showcases the dashboardr package with UvA colors, styling, and branding.
#'
#' @param directory Character string. Directory where the dashboard files will be created.
#'   Defaults to "ascor_dashboard". Quarto will render HTML to directory/docs/.
#'
#' @details
#' The ASCoR dashboard features:
#' \itemize{
#'   \item UvA red (#CB0D0D) as primary branding color
#'   \item Professional typography with Inter font
#'   \item ASCoR logo in the navbar (if logo file is provided)
#'   \item Clean, academic styling appropriate for research communication
#'   \item Example visualizations using General Social Survey data
#' }
#'
#' @return Invisibly returns the dashboard_project object.
#' @export
#'
#' @examples
#' \dontrun{
#' # Run the ASCoR dashboard (requires Quarto CLI and 'gssr' package)
#' ascor_dashboard()
#' 
#' # Specify custom directory
#' ascor_dashboard(directory = "my_ascor_dashboard")
#' }
ascor_dashboard <- function(directory = "ascor_dashboard") {
  qmds_dir <- directory
  
  # Load GSS data for demonstration
  gss_panel20 <- NULL
  data(gss_panel20, package = "gssr", envir = environment())
  gss_clean <- gss_panel20 %>%
    dplyr::select(
      age_1a, sex_1a, degree_1a, region_1a,
      happy_1a, trust_1a, fair_1a, helpful_1a,
      polviews_1a, partyid_1a, class_1a
    ) %>%
    dplyr::filter(dplyr::if_any(dplyr::everything(), ~ !is.na(.)))
  
  # Create visualizations with ASCoR color scheme
  # UvA red (#CB0D0D) as primary accent color
  analysis_vizzes <- create_viz() %>%
    # Communication & Education
    add_viz(
      type = "stackedbar",
      x_var = "degree_1a",
      stack_var = "trust_1a",
      title = "Trust in Communication by Education Level",
      subtitle = "How education influences interpersonal trust",
      x_label = "Education Level",
      y_label = "Percentage of Respondents",
      stack_label = "Trust Level",
      stacked_type = "percent",
      x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
      stack_order = c("Can Trust", "Depends", "Can't Be Too Careful"),
      tooltip_suffix = "%",
      color_palette = c("#CB0D0D", "#8B0000", "#FF6B6B"),  # UvA reds
      text = "Trust is a fundamental element in communication research.",
      text_position = "above",
      icon = "ph:chats-circle",
      height = 500,
      tabgroup = "communication"
    ) %>%
    add_viz(
      type = "stackedbar",
      x_var = "sex_1a",
      stack_var = "helpful_1a",
      title = "Perceived Helpfulness by Gender",
      subtitle = "Gender differences in prosocial attitudes",
      x_label = "Gender",
      y_label = "Percentage of Respondents",
      stack_label = "Helpfulness Rating",
      stacked_type = "percent",
      tooltip_suffix = "%",
      color_palette = c("#CB0D0D", "#8B0000", "#FF6B6B"),  # UvA reds
      text = "Understanding prosocial behavior across demographics.",
      text_position = "below",
      icon = "ph:hand-heart",
      height = 450,
      tabgroup = "communication"
    ) %>%
    # Social Media & Politics
    add_viz(
      type = "heatmap",
      x_var = "partyid_1a",
      y_var = "polviews_1a",
      value_var = "trust_1a",
      title = "Trust Patterns in Political Communication",
      subtitle = "How political identity relates to interpersonal trust",
      x_label = "Party Identification",
      y_label = "Political Views",
      value_label = "Trust Level",
      x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                  "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
      y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                  "Slightly Conservative", "Conservative", "Extremely Conservative"),
      color_palette = c("#CB0D0D", "#E66B6B", "#EFEFEF", "#6B9BD1", "#003D7A"),  # UvA red to blue
      tooltip_prefix = "Trust: ",
      tooltip_suffix = "/3",
      tooltip_labels_format = "{point.value:.2f}",
      text = "Political polarization affects communication and trust.",
      text_position = "above",
      icon = "ph:megaphone",
      height = 600,
      tabgroup = "media"
    ) %>%
    add_viz(
      type = "stackedbar",
      x_var = "region_1a",
      stack_var = "trust_1a",
      title = "Regional Variation in Social Trust",
      subtitle = "Geographic patterns in communication attitudes",
      x_label = "US Region",
      y_label = "Percentage of Respondents",
      stack_label = "Trust Level",
      stacked_type = "percent",
      stack_order = c("Can Trust", "Depends", "Can't Be Too Careful"),
      tooltip_suffix = "%",
      color_palette = c("#CB0D0D", "#8B0000", "#FF6B6B"),  # UvA reds
      text = "Regional differences in trust and communication patterns.",
      text_position = "below",
      icon = "ph:map-trifold",
      height = 500,
      tabgroup = "media"
    ) %>%
    set_tabgroup_labels(list(
      communication = "Interpersonal Communication",
      media = "Media & Political Communication"
    ))
  
  # Create summary visualizations
  summary_vizzes <- create_viz() %>%
    add_viz(
      type = "heatmap",
      x_var = "degree_1a",
      y_var = "age_1a",
      value_var = "trust_1a",
      title = "Trust Across Age and Education",
      subtitle = "Demographic patterns in communication research",
      x_label = "Education Level",
      y_label = "Age Group",
      value_label = "Trust Level",
      x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
      color_palette = c("#CB0D0D", "#E66B6B", "#EFEFEF", "#B0B0B0", "#707070"),
      tooltip_prefix = "Trust: ",
      tooltip_suffix = "/3",
      tooltip_labels_format = "{point.value:.2f}",
      text = "A comprehensive view of trust patterns in communication.",
      text_position = "above",
      icon = "ph:users-three",
      height = 650
    )
  
  # Create the ASCoR-branded dashboard using the reusable theme
  dashboard <- create_dashboard(
    output_dir = qmds_dir,
    title = "ASCoR Research Dashboard",
    allow_inside_pkg = TRUE,
    
    # Metadata
    author = "Amsterdam School of Communication Research",
    description = "Research dashboard showcasing communication science data analysis",
    page_footer = "\u00a9 2025 University of Amsterdam - ASCoR",
    
    # Features
    search = TRUE,
    navbar_brand = "ASCoR",
    breadcrumbs = TRUE,
    page_navigation = TRUE,
    back_to_top = TRUE,
    tabset_theme = "modern",
    page_layout = "full"
  ) %>%
    # Apply ASCoR theme
    apply_theme(theme_ascor()) %>%
    # Landing page
    add_page(
      name = "Welcome",
      text = md_text(
        "# Welcome to the ASCoR Research Dashboard",
        "",
        "This dashboard demonstrates research capabilities using the **Amsterdam School of Communication Research** framework.",
        "",
        "## About ASCoR",
        "",
        "The Amsterdam School of Communication Research (ASCoR) is part of the **University of Amsterdam**. ",
        "ASCoR conducts fundamental and applied research in the field of human communication from a multi-disciplinary perspective.",
        "",
        "### Research Areas",
        "",
        "- **Corporate Communication**: Organizational communication, reputation management",
        "- **Political Communication**: Media effects, political participation, journalism",  
        "- **Entertainment Communication**: Media psychology, narrative persuasion",
        "- **Persuasive Communication**: Health communication, advertising effects",
        "",
        "## This Dashboard",
        "",
        "This dashboard uses data from the General Social Survey (GSS) to demonstrate patterns relevant to communication research:",
        "",
        "- Trust and interpersonal communication",
        "- Political communication and polarization",
        "- Demographic influences on communication attitudes",
        "",
        "Navigate through the pages above to explore the analyses."
      ),
      icon = "ph:graduation-cap",
      is_landing_page = TRUE
    ) %>%
    # Main analysis page
    add_page(
      name = "Communication Patterns",
      text = md_text(
        "## Analyzing Trust in Communication",
        "",
        "These visualizations explore how different factors influence trust and communication patterns ",
        "in society - key topics in communication science research."
      ),
      data = gss_clean,
      visualizations = analysis_vizzes,
      icon = "ph:chats-circle"
    ) %>%
    # Summary page
    add_page(
      name = "Key Findings",
      text = md_text(
        "# Research Summary",
        "",
        "This comprehensive heatmap shows the complex interplay between age, education, and trust - ",
        "fundamental variables in communication research.",
        "",
        "## Implications for Communication Science",
        "",
        "Understanding these patterns helps researchers:",
        "",
        "- Design effective communication interventions",
        "- Study information processing across demographics", 
        "- Analyze media effects in diverse populations",
        "- Develop targeted health and political communication strategies"
      ),
      data = gss_clean,
      visualizations = summary_vizzes,
      icon = "ph:chart-line-up"
    ) %>%
    # About page
    add_page(
      name = "About",
      text = md_text(
        "# About This Dashboard",
        "",
        "## Data Source",
        "",
        "This dashboard uses data from the **General Social Survey (GSS)**, a nationally representative ",
        "survey of adults in the United States conducted since 1972.",
        "",
        "## University of Amsterdam",
        "",
        "The University of Amsterdam (UvA) is one of Europe's leading research universities, founded in 1632. ",
        "The university has over 30,000 students and offers more than 200 English-taught programs.",
        "",
        "### ASCoR Mission",
        "",
        "ASCoR's mission is to conduct fundamental and applied research in human communication, contributing to:",
        "",
        "- Scientific understanding of communication processes",
        "- Evidence-based communication strategies",
        "- Training of future communication researchers",
        "- Societal impact through knowledge dissemination",
        "",
        "## Dashboard Created With",
        "",
        "This dashboard was created using the **dashboardr** R package, which makes it easy to create ",
        "beautiful, interactive dashboards for data analysis and research communication.",
        "",
        "### Learn More",
        "",
        "- **ASCoR Website**: [ascor.uva.nl](https://ascor.uva.nl)",
        "- **UvA Website**: [uva.nl](https://www.uva.nl)",
        "- **dashboardr Package**: Documentation and examples"
      ),
      icon = "ph:info"
    )
  
  # Generate the dashboard
  cat("\n\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557\n")
  cat("\u2551  \U0001f393 Generating ASCoR Dashboard (UvA)             \u2551\n")
  cat("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d\n\n")
  
  generate_dashboard(dashboard, render = TRUE, open = "browser")
  
  invisible(dashboard)
}

