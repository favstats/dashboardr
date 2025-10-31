# ===================================================================
# Dashboard Creation System with Piping Workflow
# ===================================================================
#
# This file implements a complete dashboard generation system that supports
# a fluent piping interface for building Quarto-based dashboards with
# interactive visualizations.
#
# Main workflow:
#   1. Create visualizations with create_viz() %>% add_viz()
#   2. Build dashboard with create_dashboard() %>% add_landingpage() %>% add_page()
#   3. Generate files with generate_dashboard()
#
# Key features:
#   - Automatic tab grouping for related visualizations
#   - Data deduplication across pages
#   - Descriptive file naming
#   - Custom print methods for clarity
# ===================================================================

# ===================================================================
# Internal Utility Functions
# ===================================================================

# Find package root by walking up directory tree looking for DESCRIPTION
.pkg_root <- function(start = getwd()) {
  cur <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(cur, "DESCRIPTION"))) return(cur)
    parent <- dirname(cur)
    if (identical(parent, cur)) return(NULL)
    cur <- parent
  }
}

# Check if one path is a subdirectory of another
.is_subpath <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  startsWith(paste0(path, "/"), paste0(root, "/"))
}

# Resolve output directory, relocating if inside package to avoid build issues
.resolve_output_dir <- function(output_dir, allow_inside_pkg = FALSE) {
  out_abs <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  pkg_root <- .pkg_root()

  if (!allow_inside_pkg && !is.null(pkg_root) && .is_subpath(out_abs, pkg_root)) {
    relocated <- file.path(dirname(pkg_root), basename(out_abs))
    message(
      "Detected package repo at: ", pkg_root, "\n",
      "Writing output outside the package at: ", relocated,
      " (set allow_inside_pkg = TRUE to disable relocation)"
    )
    out_abs <- relocated
  }
  out_abs
}

# Default value operator: return y if x is NULL
`%||%` <- function(x, y) if (is.null(x)) y else x

# Copy template files from package resources or create basic defaults
.copy_template <- function(template_name, output_dir) {
  template_path <- system.file(
    file.path("extdata/templates", template_name),
    package = "dashboardr"
  )

  if (template_path == "" || !file.exists(template_path)) {
    # Fallback: create basic templates if package resources are missing
    if (template_name == "index.qmd") {
      basic_template <- c(
        "---",
        "title: \"Welcome\"",
        "format: html",
        "---",
        "",
        "# Welcome to the Dashboard",
        "",
        "This is the home page of your dashboard."
      )
    } else if (template_name == "tutorial.qmd") {
      basic_template <- c(
        "---",
        "title: \"Tutorial\"",
        "format: html",
        "---",
        "",
        "# Tutorial",
        "",
        "This page contains tutorial information."
      )
    } else {
      stop("Missing template: ", template_name, " in package resources.")
    }

    target <- file.path(output_dir, template_name)
    writeLines(basic_template, target)
    return(target)
  }

  target <- file.path(output_dir, template_name)

  if (!file.exists(target)) {
    if (!file.copy(template_path, target)) {
      stop("Failed to copy template: ", template_name)
    }
  }

  target
}

#' Convert R objects to proper R code strings for generating .qmd files
#'
#' Internal function that converts R objects into properly formatted R code strings
#' for inclusion in generated Quarto markdown files. Handles various data types
#' and preserves special cases like data references.
#'
#' @param arg The R object to serialize
#' @param arg_name Optional name of the argument (for debugging)
#' @return Character string containing properly formatted R code
#' @details
#' This function handles:
#' - NULL values → "NULL"
#' - Character strings → quoted strings with escaped quotes
#' - Numeric values → unquoted numbers
#' - Logical values → "TRUE"/"FALSE"
#' - Named lists → "list(name1 = value1, name2 = value2)"
#' - Unnamed lists → "list(value1, value2)"
#' - Special identifiers like "data" → unquoted
#' - Complex objects → deparsed representation
.serialize_arg <- function(arg, arg_name = NULL) {
  if (is.null(arg)) {
    return("NULL")
  } else if (is.character(arg)) {
    if (length(arg) == 1) {
      # Don't quote special identifiers like 'data' or R expressions
      if (arg %in% c("data", "readRDS('dashboard_data.rds')")) {
        return(arg)
      }
      # Quote string literals and escape internal quotes
      return(paste0('"', gsub('"', '\\"', arg, fixed = TRUE), '"'))
    } else {
      # Create c() vector for multiple strings
      quoted_args <- paste0('"', gsub('"', '\\"', arg, fixed = TRUE), '"')
      return(paste0("c(", paste(quoted_args, collapse = ", "), ")"))
    }
  } else if (is.numeric(arg)) {
    if (length(arg) == 1) {
      return(as.character(arg))
    } else {
      return(paste0("c(", paste(arg, collapse = ", "), ")"))
    }
  } else if (is.logical(arg)) {
    if (length(arg) == 1) {
      return(as.character(toupper(arg)))
    } else {
      return(paste0("c(", paste(toupper(arg), collapse = ", "), ")"))
    }
  } else if (is.list(arg)) {
    # Handle named lists (like value mappings: list("Male" = "M", "Female" = "F"))
    if (!is.null(names(arg))) {
      items <- character(0)
      for (name in names(arg)) {
        value <- .serialize_arg(arg[[name]])
        items <- c(items, paste0('"', name, '" = ', value))
      }
      return(paste0("list(", paste(items, collapse = ", "), ")"))
    } else {
      # Unnamed lists
      items <- sapply(arg, .serialize_arg)
      return(paste0("list(", paste(items, collapse = ", "), ")"))
    }
  } else {
    # Fallback for complex objects: use deparse
    deparsed <- deparse(arg, width.cutoff = 500)
    if (length(deparsed) == 1) {
      return(deparsed)
    } else {
      return(paste(deparsed, collapse = " "))
    }
  }
}

# ===================================================================
# Visualization Specification System
# ===================================================================

#' Create a new visualization collection
#'
#' Initializes an empty collection for building up multiple visualizations
#' using the piping workflow. Optionally accepts custom display labels for
#' tab groups.
#'
#' @param tabgroup_labels Named vector/list mapping tabgroup IDs to display names
#' @return A viz_collection object
#' @export
#' @examples
#' \dontrun{
#' # Create viz collection with custom group labels
#' vizzes <- create_viz(tabgroup_labels = c("demo" = "Demographics",
#'                                           "pol" = "Political Views"))
#' }
create_viz <- function(tabgroup_labels = NULL) {
  structure(list(
    visualizations = list(),
    tabgroup_labels = tabgroup_labels
  ), class = "viz_collection")
}

#' Add a visualization to the collection
#'
#' Adds a single visualization specification to an existing collection.
#' Visualizations with the same tabgroup value will be organized into
#' tabs on the generated page.
#'
#' @param viz_collection A viz_collection object
#' @param type Visualization type: "stackedbar", "heatmap", "histogram", "timeline"
#' @param ... Additional parameters passed to the visualization function
#' @param tabgroup Optional group ID for organizing related visualizations
#' @param title Display title for the visualization
#' @param text Optional markdown text to display above the visualization
#' @param icon Optional iconify icon shortcode for the visualization
#' @param text_position Position of text relative to visualization ("above" or "below")
#' @param height Optional height in pixels for highcharter visualizations (numeric value)
#' @return The updated viz_collection object
#' @export
#' @examples
#' \dontrun{
#' page1_viz <- create_viz() %>%
#'   add_viz(type = "stackedbar", x_var = "education", stack_var = "gender",
#'           title = "Education by Gender", tabgroup = "demographics",
#'           text = "This chart shows educational attainment by gender.",
#'           icon = "ph:chart-bar")
#' }
add_viz <- function(viz_collection, type, ..., tabgroup = NULL, title = NULL, text = NULL, icon = NULL, text_position = "above", height = NULL) {
  # Validate first argument
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object")
  }

  # Validate type parameter
  if (is.null(type) || !is.character(type) || length(type) != 1 || nchar(type) == 0) {
    stop("type must be a non-empty character string")
  }

  # Validate supported visualization types
  supported_types <- c("stackedbar", "stackedbars", "heatmap", "histogram", "timeline")
  if (!type %in% supported_types) {
    warning("Unknown visualization type '", type, "'. Supported types: ",
            paste(supported_types, collapse = ", "))
  }

  # Validate tabgroup parameter
  if (!is.null(tabgroup)) {
    if (!is.character(tabgroup) || length(tabgroup) != 1 || nchar(tabgroup) == 0) {
      stop("tabgroup must be a non-empty character string or NULL")
    }
  }

  # Validate title parameter
  if (!is.null(title)) {
    if (!is.character(title) || length(title) != 1) {
      stop("title must be a character string or NULL")
    }
  }

  # Validate text parameter
  if (!is.null(text)) {
    if (!is.character(text) || length(text) != 1) {
      stop("text must be a character string or NULL")
    }
  }

  # Validate icon parameter
  if (!is.null(icon)) {
    if (!is.character(icon) || length(icon) != 1) {
      stop("icon must be a character string or NULL")
    }
    # Validate icon format (should be "collection:name" or already formatted shortcode)
    if (!grepl("^[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+$", icon) &&
        !grepl("\\{\\{< iconify", icon, fixed = TRUE)) {
      warning("Icon '", icon, "' should be in format 'collection:name' (e.g., 'ph:users-three') ",
              "or a pre-formatted iconify shortcode")
    }
  }

  # Validate text_position
  if (!text_position %in% c("above", "below")) {
    stop("text_position must be either 'above' or 'below'")
  }

  # Validate height parameter
  if (!is.null(height)) {
    if (!is.numeric(height) || length(height) != 1 || height <= 0) {
      stop("height must be a positive numeric value or NULL")
    }
  }

  # Bundle all parameters into a spec
  viz_spec <- list(
    type = type,
    tabgroup = tabgroup,
    title = title,
    text = text,
    icon = icon,
    text_position = text_position,
    height = height,
    ...
  )

  # Append to the collection
  viz_collection$visualizations <- c(viz_collection$visualizations, list(viz_spec))

  viz_collection
}

#' Set or update tabgroup display labels
#'
#' Updates the display labels for tab groups in a visualization collection.
#' Useful when you want to change the section headers after creating the collection.
#'
#' @param viz_collection A viz_collection object
#' @param labels Named character vector or list mapping tabgroup IDs to labels
#' @return The updated viz_collection
#' @export
#' @examples
#' \dontrun{
#' vizzes <- create_viz() %>%
#'   add_viz(type = "heatmap", tabgroup = "demo") %>%
#'   set_tabgroup_labels(c("demo" = "Demographic Breakdowns"))
#' }
set_tabgroup_labels <- function(viz_collection, labels) {
  if (!inherits(viz_collection, "viz_collection")) {
    stop("First argument must be a viz_collection object")
  }
  viz_collection$tabgroup_labels <- labels
  viz_collection
}

#' Create a single visualization specification
#'
#' Helper function to create individual viz specs that can be combined
#' into a list or used directly in add_page().
#'
#' @param type Visualization type
#' @param ... Additional parameters
#' @param tabgroup Optional group ID
#' @param title Display title
#' @return A list containing the visualization specification
#' @export
#' @examples
#' \dontrun{
#' viz1 <- spec_viz(type = "heatmap", x_var = "party", y_var = "ideology")
#' viz2 <- spec_viz(type = "histogram", x_var = "age")
#' page_viz <- list(viz1, viz2)
#' }
spec_viz <- function(type, ..., tabgroup = NULL, title = NULL) {
  list(
    type = type,
    tabgroup = tabgroup,
    title = title,
    ...
  )
}

# ===================================================================
# Core Dashboard Functions
# ===================================================================

#' Create a new dashboard project
#'
#' Initializes a dashboard project object that can be built up using
#' the piping workflow with add_landingpage() and add_page().
#'
#' @param output_dir Directory for generated files
#' @param title Overall title for the dashboard site
#' @param logo Optional logo filename (will be copied to output directory)
#' @param favicon Optional favicon filename (will be copied to output directory)
#' @param github GitHub repository URL (optional)
#' @param twitter Twitter profile URL (optional)
#' @param linkedin LinkedIn profile URL (optional)
#' @param email Email address (optional)
#' @param website Website URL (optional)
#' @param search Enable search functionality (default: TRUE)
#' @param theme Bootstrap theme (cosmo, flatly, journal, etc.) (optional)
#' @param custom_css Path to custom CSS file (optional)
#' @param custom_scss Path to custom SCSS file (optional)
#' @param author Author name for the site (optional)
#' @param description Site description for SEO (optional)
#' @param page_footer Custom footer text (optional)
#' @param date Site creation/update date (optional)
#' @param sidebar Enable/disable global sidebar (default: FALSE)
#' @param sidebar_style Sidebar style (floating, docked, etc.) (optional)
#' @param sidebar_background Sidebar background color (optional)
#' @param navbar_style Navbar style (default, dark, light) (optional)
#' @param navbar_brand Custom brand text (optional)
#' @param navbar_toggle Mobile menu toggle behavior (optional)
#' @param math Enable/disable math rendering (katex, mathjax) (optional)
#' @param code_folding Code folding behavior (none, show, hide) (optional)
#' @param code_tools Code tools (copy, download, etc.) (optional)
#' @param toc Table of contents (floating, left, right) (optional)
#' @param toc_depth TOC depth level (default: 3)
#' @param google_analytics Google Analytics ID (optional)
#' @param plausible Plausible analytics domain (optional)
#' @param gtag Google Tag Manager ID (optional)
#' @param value_boxes Enable value box styling (default: FALSE)
#' @param metrics_style Metrics display style (optional)
#' @param shiny Enable Shiny interactivity (default: FALSE)
#' @param observable Enable Observable JS (default: FALSE)
#' @param jupyter Enable Jupyter widgets (default: FALSE)
#' @param publish_dir Custom publish directory (optional)
#' @param github_pages GitHub Pages configuration (optional)
#' @param netlify Netlify deployment settings (optional)
#' @param allow_inside_pkg Allow output directory inside package (default FALSE)
#' @param warn_before_overwrite Warn before overwriting existing files (default TRUE)
#' @param sidebar_groups List of sidebar groups for hybrid navigation (optional)
#' @param navbar_sections List of navbar sections that link to sidebar groups (optional)
#' @return A dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' # Basic dashboard
#' dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")
#'
#' # Comprehensive dashboard with all features
#' dashboard <- create_dashboard(
#'   "my_dashboard",
#'   "My Analysis Dashboard",
#'   logo = "logo.png",
#'   github = "https://github.com/username/repo",
#'   twitter = "https://twitter.com/username",
#'   theme = "cosmo",
#'   author = "Dr. Jane Smith",
#'   description = "Comprehensive data analysis dashboard",
#'   page_footer = "© 2024 Company Name",
#'   sidebar = TRUE,
#'   toc = "floating",
#'   google_analytics = "GA-XXXXXXXXX",
#'   value_boxes = TRUE,
#'   shiny = TRUE
#' )
#' }
create_dashboard <- function(output_dir = "site",
                            title = "Dashboard",
                            logo = NULL,
                            favicon = NULL,
                            github = NULL,
                            twitter = NULL,
                            linkedin = NULL,
                            email = NULL,
                            website = NULL,
                            search = TRUE,
                            theme = NULL,
                            custom_css = NULL,
                            custom_scss = NULL,
                            author = NULL,
                            description = NULL,
                            page_footer = NULL,
                            date = NULL,
                            sidebar = FALSE,
                            sidebar_style = "docked",
                            sidebar_background = "light",
                            sidebar_foreground = NULL,
                            sidebar_border = TRUE,
                            sidebar_alignment = "left",
                            sidebar_collapse_level = 2,
                            sidebar_pinned = FALSE,
                            sidebar_tools = NULL,
                            sidebar_contents = NULL,
                            breadcrumbs = TRUE,
                            page_navigation = FALSE,
                            back_to_top = FALSE,
                            reader_mode = FALSE,
                            repo_url = NULL,
                            repo_actions = NULL,
                            navbar_style = NULL,
                            navbar_brand = NULL,
                            navbar_toggle = NULL,
                            math = NULL,
                            code_folding = NULL,
                            code_tools = NULL,
                            toc = NULL,
                            toc_depth = 3,
                            google_analytics = NULL,
                            plausible = NULL,
                            gtag = NULL,
                            value_boxes = FALSE,
                            metrics_style = NULL,
                            page_layout = NULL,
                            shiny = FALSE,
                            observable = FALSE,
                            jupyter = FALSE,
                            publish_dir = NULL,
                            github_pages = NULL,
                            netlify = NULL,
                             allow_inside_pkg = FALSE,
                             warn_before_overwrite = TRUE,
                             sidebar_groups = NULL,
                             navbar_sections = NULL) {

  output_dir <- .resolve_output_dir(output_dir, allow_inside_pkg)

  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  } else if (warn_before_overwrite) {
    message(
      "Output directory already exists: ", output_dir, "\n",
      "Files may be overwritten when generate_dashboard() is called."
    )
  }

  message("Dashboard project initialized at: ", output_dir)

  # Return project object for piping
  structure(list(
    output_dir = output_dir,
    title = title,
    logo = logo,
    favicon = favicon,
    github = github,
    twitter = twitter,
    linkedin = linkedin,
    email = email,
    website = website,
    search = search,
    theme = theme,
    custom_css = custom_css,
    custom_scss = custom_scss,
    author = author,
    description = description,
    page_footer = page_footer,
    date = date,
    sidebar = sidebar,
    sidebar_style = sidebar_style,
    sidebar_background = sidebar_background,
    sidebar_foreground = sidebar_foreground,
    sidebar_border = sidebar_border,
    sidebar_alignment = sidebar_alignment,
    sidebar_collapse_level = sidebar_collapse_level,
    sidebar_pinned = sidebar_pinned,
    sidebar_tools = sidebar_tools,
    sidebar_contents = sidebar_contents,
    breadcrumbs = breadcrumbs,
    page_navigation = page_navigation,
    back_to_top = back_to_top,
    reader_mode = reader_mode,
    repo_url = repo_url,
    repo_actions = repo_actions,
    navbar_style = navbar_style,
    navbar_brand = navbar_brand,
    navbar_toggle = navbar_toggle,
    math = math,
    code_folding = code_folding,
    code_tools = code_tools,
    toc = toc,
    toc_depth = toc_depth,
    google_analytics = google_analytics,
    plausible = plausible,
    gtag = gtag,
    value_boxes = value_boxes,
    metrics_style = metrics_style,
    page_layout = page_layout,
    shiny = shiny,
    observable = observable,
    jupyter = jupyter,
    publish_dir = publish_dir,
    github_pages = github_pages,
    netlify = netlify,
    allow_inside_pkg = allow_inside_pkg,
    warn_before_overwrite = warn_before_overwrite,
    sidebar_groups = sidebar_groups,
    navbar_sections = navbar_sections,
    pages = list(),
    data_files = NULL
  ), class = "dashboard_project")
}

#' Add a page to the dashboard
#'
#' Universal function for adding any type of page to the dashboard. Can create
#' landing pages, analysis pages, about pages, or any combination of text and
#' visualizations. All content is markdown-compatible.
#'
#' @param proj A dashboard_project object
#' @param name Page display name
#' @param data Optional data frame to save for this page
#' @param data_path Path to existing data file (alternative to data parameter)
#' @param template Optional custom template file path
#' @param params Parameters for template substitution
#' @param visualizations viz_collection or list of visualization specs
#' @param text Optional markdown text content for the page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @return The updated dashboard_project object
#' @export
#' @examples
#' \dontrun{
#' # Landing page
#' dashboard <- create_dashboard("test") %>%
#'   add_page("Welcome", text = "# Welcome\n\nThis is the main page.", is_landing_page = TRUE)
#'
#' # Analysis page with data and visualizations
#' dashboard <- dashboard %>%
#'   add_page("Demographics", data = survey_data, visualizations = demo_viz)
#'
#' # Text-only about page
#' dashboard <- dashboard %>%
#'   add_page("About", text = "# About This Study\n\nThis dashboard shows...")
#'
#' # Mixed content page
#' dashboard <- dashboard %>%
#'   add_page("Results", text = "# Key Findings\n\nHere are the results:",
#'            visualizations = results_viz, icon = "ph:chart-line")
#' }
add_dashboard_page <- function(proj, name, data = NULL, data_path = NULL,
                               template = NULL, params = list(),
                               visualizations = NULL, text = NULL, icon = NULL,
                               is_landing_page = FALSE) {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }

  # Handle data storage with deduplication
  if (!is.null(data)) {
    if (is.null(data_path)) {
      # Check if we've already saved this exact dataset
      data_hash <- digest::digest(data)
      existing_data <- proj$data_files %||% list()

      data_path <- NULL
      for (existing_path in names(existing_data)) {
        if (existing_data[[existing_path]] == data_hash) {
          data_path <- existing_path
          break
        }
      }

      # If not found, create a new descriptive filename
      if (is.null(data_path)) {
        data_name <- "gss_data"
        if (nrow(data) < 1000) {
          data_name <- paste0(data_name, "_small")
        } else if (nrow(data) > 5000) {
          data_name <- paste0(data_name, "_large")
        }
        data_name <- paste0(data_name, "_", nrow(data), "obs")
        data_path <- paste0(data_name, ".rds")

        # Track this dataset
        if (is.null(proj$data_files)) {
          proj$data_files <- list()
        }
        proj$data_files[[data_path]] <- data_hash
      }
    }

    # Save the data file
    output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    saveRDS(data, file.path(output_dir, basename(data_path)))
    data_path <- basename(data_path)
  }

  # Process visualization specifications
  viz_specs <- NULL
  if (!is.null(visualizations)) {
    viz_specs <- .process_visualizations(visualizations, data_path)
  }

  # Create page record
  page <- list(
    name = name,
    data_path = data_path,
    template = template,
    params = params,
    visualizations = viz_specs,
    text = text,
    icon = icon,
    is_landing_page = is_landing_page
  )

  proj$pages[[name]] <- page

  # Store landing page info if this is the landing page
  if (is_landing_page) {
    proj$landing_page <- name
  }

  proj
}

# Convenient alias for add_dashboard_page
#' @export
add_page <- add_dashboard_page


#' Create iconify icon shortcode
#'
#' Helper function to generate iconify icon shortcodes for use in pages and visualizations.
#'
#' @param icon_name Icon name in format "collection:name" (e.g., "ph:users-three")
#' @return Iconify shortcode string
#' @export
#' @examples
#' \dontrun{
#' icon("ph:users-three")  # Returns iconify shortcode
#' icon("emojione:flag-for-united-states")  # Returns iconify shortcode
#' }
icon <- function(icon_name) {
  # Convert "collection:name" to "{{< iconify collection name >}}"
  parts <- strsplit(icon_name, ":", fixed = TRUE)[[1]]
  if (length(parts) != 2) {
    stop("Icon name must be in format 'collection:name' (e.g., 'ph:users-three')")
  }
  paste0("{{< iconify ", parts[1], " ", parts[2], " >}}")
}

#' Create a Bootstrap card component
#'
#' Helper function to create Bootstrap card components for displaying content in a structured way.
#' Useful for author profiles, feature highlights, or any content that benefits from card layout.
#'
#' @param content Card content (text, HTML, or other elements)
#' @param title Optional card title
#' @param image Optional image URL or path
#' @param image_alt Alt text for the image
#' @param footer Optional card footer content
#' @param class Additional CSS classes for the card
#' @param style Additional inline styles for the card
#' @return HTML div element with Bootstrap card classes
#' @export
#' @examples
#' \dontrun{
#' # Simple text card
#' card("This is a simple card with just text content")
#'
#' # Card with title and image
#' card(
#'   content = "This is the card body content",
#'   title = "Card Title",
#'   image = "https://example.com/image.jpg",
#'   image_alt = "Description of image"
#' )
#'
#' # Author card
#' card(
#'   content = "Dr. Jane Smith is a researcher specializing in data science and visualization.",
#'   title = "Dr. Jane Smith",
#'   image = "https://example.com/jane.jpg",
#'   footer = "Website: janesmith.com"
#' )
#' }
card <- function(content, title = NULL, image = NULL, image_alt = NULL,
                footer = NULL, class = NULL, style = NULL) {

  # Start building the card
  card_classes <- c("card", class)
  card_style <- style

  # Create the card structure
  card_div <- htmltools::div(
    class = paste(card_classes, collapse = " "),
    style = card_style
  )

  # Add image if provided
  if (!is.null(image)) {
    image_div <- htmltools::div(
      class = "card-img-top",
      htmltools::img(
        src = image,
        alt = image_alt %||% "",
        class = "img-fluid",
        style = "width: 100%; height: auto;"
      )
    )
    card_div <- htmltools::tagAppendChild(card_div, image_div)
  }

  # Create card body
  card_body <- htmltools::div(class = "card-body")

  # Add title if provided
  if (!is.null(title)) {
    title_div <- htmltools::div(
      class = "card-title",
      htmltools::h5(title)
    )
    card_body <- htmltools::tagAppendChild(card_body, title_div)
  }

  # Add content
  content_div <- htmltools::div(
    class = "card-text",
    content
  )
  card_body <- htmltools::tagAppendChild(card_body, content_div)

  # Add card body to card
  card_div <- htmltools::tagAppendChild(card_div, card_body)

  # Add footer if provided
  if (!is.null(footer)) {
    footer_div <- htmltools::div(
      class = "card-footer text-muted",
      footer
    )
    card_div <- htmltools::tagAppendChild(card_div, footer_div)
  }

  return(card_div)
}

#' Display cards in a Bootstrap row
#'
#' Helper function to display multiple cards in a responsive Bootstrap row layout.
#'
#' @param ... Card objects to display
#' @param cols Number of columns per row (default: 2)
#' @param class Additional CSS classes for the row
#' @return HTML div element with Bootstrap row classes containing the cards
#' @export
#' @examples
#' \dontrun{
#' # Display two cards in a row
#' card_row(card1, card2)
#'
#' # Display three cards in a row (3 columns)
#' card_row(card1, card2, card3, cols = 3)
#' }
card_row <- function(..., cols = 2, class = NULL) {
  cards <- list(...)

  # Calculate Bootstrap column class
  col_class <- paste0("col-md-", 12 %/% cols)

  # Create row with cards
  row_div <- htmltools::div(
    class = paste(c("row", class), collapse = " "),
    lapply(cards, function(card) {
      htmltools::div(class = col_class, card)
    })
  )

  return(row_div)
}

#' Create multi-line markdown text content
#'
#' Helper function to create readable multi-line markdown text content for pages.
#' Automatically handles line breaks and formatting for better readability.
#'
#' @param ... Text content as separate arguments or character vectors
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' # Method 1: Separate arguments
#' text_content <- md_text(
#'   "# Welcome",
#'   "",
#'   "This is a multi-line text block.",
#'   "",
#'   "## Features",
#'   "- Feature 1",
#'   "- Feature 2"
#' )
#'
#' # Method 2: Character vectors
#' lines <- c("# About", "", "This is about our study.")
#' text_content <- md_text(lines)
#'
#' # Use in add_page
#' add_page("About", text = text_content)
#' }
md_text <- function(...) {
  # Combine all arguments into a single character vector
  args <- list(...)
  content <- character(0)

  for (arg in args) {
    if (is.character(arg)) {
      content <- c(content, arg)
    } else {
      content <- c(content, as.character(arg))
    }
  }

  # Join with newlines
  paste(content, collapse = "\n")
}

#' Create text content from a character vector
#'
#' Alternative helper for creating text content from existing character vectors.
#'
#' @param lines Character vector of text lines
#' @return Single character string with proper line breaks
#' @export
#' @examples
#' \dontrun{
#' lines <- c("# Title", "", "Content here")
#' text_content <- text_lines(lines)
#' add_page("Page", text = text_content)
#' }
text_lines <- function(lines) {
  paste(lines, collapse = "\n")
}

# ===================================================================
# Automatic Iconify Extension Installation
# ===================================================================

#' Check if any icons are used in the dashboard
#'
#' Internal function to detect if iconify shortcodes are present
#' in the dashboard content.
#'
#' @param proj A dashboard_project object
#' @return Logical indicating if icons are present
.check_for_icons <- function(proj) {

  # Check all pages
  for (page in proj$pages) {
    if (!is.null(page$icon)) {
      return(TRUE)
    }

    # Check visualizations
    if (!is.null(page$visualizations)) {
      for (viz in page$visualizations) {
        if (!is.null(viz$icon)) {
          return(TRUE)
        }
        # Check nested visualizations in tab groups
        if (viz$type == "tabgroup" && !is.null(viz$visualizations)) {
          for (nested_viz in viz$visualizations) {
            if (!is.null(nested_viz$icon)) {
              return(TRUE)
            }
          }
        }
      }
    }
  }

  # Check navbar sections for icons
  if (!is.null(proj$navbar_sections)) {
    for (section in proj$navbar_sections) {
      if (!is.null(section$icon)) {
        return(TRUE)
      }
    }
  }

  FALSE
}

#' Install iconify extension automatically
#'
#' Downloads and installs the official iconify extension to the project directory
#' if icons are detected in the dashboard.
#'
#' @param output_dir The dashboard output directory
#' @return Logical indicating if installation was successful
.install_iconify_extension <- function(output_dir) {
  # Check if git is available
  git_result <- system2("git", "--version", stdout = TRUE, stderr = TRUE)
  if (length(git_result) == 0 || any(grepl("error|Error|ERROR|fatal", git_result))) {
    warning("Git is not installed. Cannot install iconify extension automatically.")
    message("To install iconify extension manually:")
    message("1. Install git from: https://git-scm.com/downloads")
    message("2. Or download the extension files manually from: https://github.com/mcanouil/quarto-iconify")
    return(FALSE)
  }

  # Try to install using git clone
  tryCatch({
    # Create extensions directory
    ext_dir <- file.path(output_dir, "_extensions", "mcanouil")
    if (!dir.exists(ext_dir)) {
      dir.create(ext_dir, recursive = TRUE)
    }

    iconify_dir <- file.path(ext_dir, "iconify")

    # Check if already installed
    if (dir.exists(iconify_dir) && file.exists(file.path(iconify_dir, "_extension.yml"))) {
      message("Iconify extension already installed")
      return(TRUE)
    }

    # Clone the official iconify extension
    old_wd <- getwd()
    setwd(output_dir)
    on.exit(setwd(old_wd), add = TRUE)

    # Remove existing directory if it exists
    if (dir.exists(iconify_dir)) {
      unlink(iconify_dir, recursive = TRUE)
    }

    # Clone to temporary directory first
    temp_dir <- file.path(output_dir, "_temp_iconify")
    if (dir.exists(temp_dir)) {
      unlink(temp_dir, recursive = TRUE)
    }

    result <- system2("git", c("clone", "https://github.com/mcanouil/quarto-iconify.git", temp_dir),
                     stdout = TRUE, stderr = TRUE)

    if (length(result) > 0 && any(grepl("error|Error|ERROR|fatal", result))) {
      warning("Failed to clone iconify extension: ", paste(result, collapse = " "))
      return(FALSE)
    }

    # Extract the actual extension files from the cloned repository
    # The quarto-iconify repository structure has the extension files in _extensions/iconify/
    source_ext_dir <- file.path(temp_dir, "_extensions", "iconify")
    if (dir.exists(source_ext_dir)) {
      # Create the target directory
      if (!dir.exists(iconify_dir)) {
        dir.create(iconify_dir, recursive = TRUE)
      }

      # Copy all files from the source extension directory
      files_to_copy <- list.files(source_ext_dir, full.names = TRUE)
      for (file in files_to_copy) {
        if (file.exists(file)) {
          file.copy(file, iconify_dir, overwrite = TRUE)
        }
      }
    } else {
      warning("Could not find iconify extension files in cloned repository")
      unlink(temp_dir, recursive = TRUE)
      return(FALSE)
    }

    # Clean up temporary directory
    unlink(temp_dir, recursive = TRUE)

    # Verify installation
    if (file.exists(file.path(iconify_dir, "_extension.yml"))) {
      message("Iconify extension installed successfully")
      return(TRUE)
    } else {
      warning("Iconify extension files not found after installation")
      return(FALSE)
    }

  }, error = function(e) {
    warning("Failed to install iconify extension: ", e$message)
    message("Manual installation required: git clone https://github.com/mcanouil/quarto-iconify.git _extensions/mcanouil/iconify")
    return(FALSE)
  })
}

# ===================================================================
# CLI Output and Display Functions
# ===================================================================

#' Show beautiful dashboard summary
#'
#' Internal function that displays a comprehensive summary of the generated
#' dashboard files and provides helpful guidance to users.
#'
#' @param proj A dashboard_project object
#' @param output_dir Path to the output directory
#' @return Invisible NULL
.show_dashboard_summary <- function(proj, output_dir) {
  cat("\n")
  cat("🎉 DASHBOARD GENERATED SUCCESSFULLY!\n")
  cat(paste(rep("═", 50), collapse = ""), "\n")

  # Dashboard info
  cat("📊 Dashboard: ", proj$title, "\n", sep = "")
  cat("📁 Location: ", output_dir, "\n", sep = "")
  cat("📄 Pages: ", length(proj$pages), "\n", sep = "")

  # Count visualizations
  total_viz <- 0
  for (page in proj$pages) {
    if (!is.null(page$visualizations)) {
      total_viz <- total_viz + length(page$visualizations)
    }
  }
  cat("📈 Visualizations: ", total_viz, "\n", sep = "")

  cat("\n")
  cat("📁 GENERATED FILES:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")

  # List all generated files (exclude site_libs and hidden files)
  files <- list.files(output_dir, recursive = TRUE, full.names = FALSE)
  files <- files[!grepl("^\\.", files)] # Exclude hidden files
  files <- files[!grepl("^docs/site_libs/", files)] # Exclude site_libs files

  # Group files by type
  qmd_files <- files[grepl("\\.qmd$", files)]
  rds_files <- files[grepl("\\.rds$", files)]
  yml_files <- files[grepl("\\.yml$", files)]
  other_files <- files[!grepl("\\.(qmd|rds|yml)$", files)]

  # Display QMD files (pages)
  if (length(qmd_files) > 0) {
    cat("📄 Pages (QMD files):\n")
    for (file in sort(qmd_files)) {
      page_name <- gsub("\\.qmd$", "", file)
      page_name <- gsub("_", " ", page_name)
      page_name <- tools::toTitleCase(page_name)
      cat("   • ", file, " → ", page_name, "\n", sep = "")
    }
    cat("\n")
  }

  # Display data files
  if (length(rds_files) > 0) {
    cat("💾 Data files:\n")
    for (file in sort(rds_files)) {
      file_size <- file.size(file.path(output_dir, file))
      size_str <- if (file_size > 1024*1024) {
        paste0(round(file_size/(1024*1024), 1), " MB")
      } else if (file_size > 1024) {
        paste0(round(file_size/1024, 1), " KB")
      } else {
        paste0(file_size, " B")
      }
      cat("   • ", file, " (", size_str, ")\n", sep = "")
    }
    cat("\n")
  }

  # Display configuration files
  if (length(yml_files) > 0) {
    cat("⚙️  Configuration:\n")
    for (file in sort(yml_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Display other files
  if (length(other_files) > 0) {
    cat("📎 Other files:\n")
    for (file in sort(other_files)) {
      cat("   • ", file, "\n", sep = "")
    }
    cat("\n")
  }

  # Next steps
  cat("🚀 NEXT STEPS:\n")
  cat(paste(rep("─", 30), collapse = ""), "\n")
  cat("1. Edit your dashboard:\n")
  cat("   • Modify QMD files to customize content and styling\n")
  cat("   • Add more visualizations using add_viz() with height parameters\n")
  cat("   • Customize the _quarto.yml configuration file\n")
  cat("\n")
  cat("2. Generate a new dashboard:\n")
  cat("   • Use create_dashboard() %>% add_page() %>% generate_dashboard()\n")
  cat("   • Try different themes, layouts, and features\n")
  cat("   • Experiment with height parameters for better proportions\n")
  cat("\n")
  cat("3. Deploy your dashboard:\n")
  cat("   • Use Quarto's publishing features (GitHub Pages, Netlify, etc.)\n")
  cat("   • Share the docs/ folder contents\n")
  cat("\n")


  cat("🎯 Happy dashing!\n")
  cat(paste(rep("═", 50), collapse = ""), "\n")
  cat("\n")

  invisible(NULL)
}

# ===================================================================
# Internal Visualization Processing
# ===================================================================

#' Process visualizations into organized specs with tab groups
#'
#' Unified internal function that handles both viz_collection and plain list inputs,
#' organizing visualizations into standalone items and tab groups based on their
#' tabgroup parameter.
#'
#' @param viz_input Either a viz_collection object or a plain list of visualization specs
#' @param data_path Path to the data file for this page (will be attached to each viz)
#' @param tabgroup_labels Optional named list/vector of custom display labels for tab groups
#' @return List of processed visualization specs, with standalone visualizations first,
#'         followed by tab group objects
#' @details
#' This function handles both viz_collection objects and plain lists of visualization
#' specifications. It:
#' - Attaches data_path to each visualization
#' - Groups visualizations by their tabgroup parameter
#' - Converts single-item groups to standalone visualizations with group titles
#' - Creates tab group objects for multi-item groups
#' - Applies custom tab group labels if provided
.process_visualizations <- function(viz_input, data_path, tabgroup_labels = NULL) {
  # Handle different input types
  if (inherits(viz_input, "viz_collection")) {
    if (is.null(viz_input) || length(viz_input$visualizations) == 0) {
      return(NULL)
    }
    viz_list <- viz_input$visualizations
    tabgroup_labels <- viz_input$tabgroup_labels
  } else if (is.list(viz_input)) {
    if (length(viz_input) == 0) {
      return(NULL)
    }
    viz_list <- viz_input
  } else {
    return(NULL)
  }

  # Attach data path to each visualization
  for (i in seq_along(viz_list)) {
    viz_list[[i]]$data_path <- data_path
  }

  # Separate visualizations by tabgroup
  tabgroups <- list()
  standalone_viz <- list()

  for (viz in viz_list) {
    if (is.null(viz$tabgroup)) {
      standalone_viz <- c(standalone_viz, list(viz))
    } else {
      if (is.null(tabgroups[[viz$tabgroup]])) {
        tabgroups[[viz$tabgroup]] <- list()
      }
      tabgroups[[viz$tabgroup]] <- c(tabgroups[[viz$tabgroup]], list(viz))
    }
  }

  # Build result: standalone first, then tab groups
  result <- list()

  # Add standalone visualizations
  for (viz in standalone_viz) {
    result <- c(result, list(viz))
  }

  # Process tab groups: single-viz groups become standalone with group title
  for (group_name in names(tabgroups)) {
    group_viz <- tabgroups[[group_name]]

    # Look up custom display label if provided
    display_label <- NULL
    if (!is.null(tabgroup_labels) && length(tabgroup_labels) > 0) {
      if (!is.null(names(tabgroup_labels))) {
        display_label <- tabgroup_labels[[group_name]]
      } else if (is.list(tabgroup_labels)) {
        display_label <- tabgroup_labels[[group_name]]
      }
    }

    if (length(group_viz) == 1) {
      # Single visualization in group - add as standalone with group title
      single_viz <- group_viz[[1]]
      # Use group label as title if viz doesn't have one
      if (is.null(single_viz$title) || single_viz$title == "") {
        single_viz$title <- display_label %||% group_name
      }
      result <- c(result, list(single_viz))
    } else {
      # Multiple visualizations - create tab group
      result <- c(result, list(list(
        type = "tabgroup",
        name = group_name,
        label = display_label,
        visualizations = group_viz
      )))
    }
  }

  result
}


# Process custom template files
.process_template <- function(template_path, params, output_dir) {
  if (is.null(template_path) || !file.exists(template_path)) {
    return(NULL)
  }

  content <- readLines(template_path, warn = FALSE)

  # Substitute template variables
  content <- .substitute_template_vars(content, params)

  content
}

# Replace {{variable}} placeholders in templates
.substitute_template_vars <- function(content, params) {
  for (param_name in names(params)) {
    pattern <- paste0("\\{\\{", param_name, "\\}\\}")
    replacement <- as.character(params[[param_name]])
    content <- gsub(pattern, replacement, content)
  }
  content
}

# Insert generated visualization code into template
.process_viz_specs <- function(content, viz_specs) {
  if (is.null(viz_specs) || length(viz_specs) == 0) {
    return(content)
  }

  viz_placeholder <- "{{visualizations}}"

  if (any(grepl(viz_placeholder, content, fixed = TRUE))) {
    viz_content <- .generate_viz_from_specs(viz_specs)
    new_content <- character(0)
    for (line in content) {
      if (grepl(viz_placeholder, line, fixed = TRUE)) {
        new_content <- c(new_content, viz_content)
      } else {
        new_content <- c(new_content, line)
      }
    }
    content <- new_content
  }

  content
}

# ===================================================================
# Code Generation for Visualizations
# ===================================================================

# Generate R code chunks for all visualizations in a page
.generate_viz_from_specs <- function(viz_specs) {
  lines <- character(0)

  for (i in seq_along(viz_specs)) {
    spec <- viz_specs[[i]]
    spec_name <- if (!is.null(names(viz_specs)[i]) && names(viz_specs)[i] != "") {
      names(viz_specs)[i]
    } else {
      paste0("viz_", i)
    }

    # Generate either single viz or tab group
    if (is.null(spec$type) || spec$type != "tabgroup") {
    lines <- c(lines, .generate_single_viz(spec_name, spec))
    } else {
      lines <- c(lines, .generate_tabgroup_viz(spec))
    }
  }

  lines
}

# Generate a single visualization R code chunk
.generate_single_viz <- function(spec_name, spec, skip_header = FALSE) {
  lines <- character(0)

  # Determine text position (default to "above" if not specified)
  text_position <- spec$text_position %||% "above"

  # Add section header with icon if provided (skip if in tabgroup)
  if (!skip_header && !is.null(spec$title)) {
    header_text <- spec$title
    if (!is.null(spec$icon)) {
      icon_shortcode <- if (grepl("{{< iconify", spec$icon, fixed = TRUE)) {
        spec$icon
      } else {
        icon(spec$icon)
      }
      header_text <- paste0(icon_shortcode, " ", spec$title)
    }
    lines <- c(lines, paste0("## ", header_text), "")
  }

  # Add custom text content if provided (above chart by default)
  if (!is.null(spec$text) && nzchar(spec$text) && text_position == "above") {
    lines <- c(lines, "", spec$text, "")
  }

  # Simple R chunk - global settings handle echo, warning, etc.
  lines <- c(lines,
    "```{r}",
    paste0("# ", spec$title %||% paste(spec$type, "visualization"))
  )

  # Dispatch to appropriate generator
  if ("type" %in% names(spec)) {
    lines <- c(lines, .generate_typed_viz(spec))
  } else if ("fn" %in% names(spec)) {
    lines <- c(lines, .generate_function_viz(spec))
  } else {
    lines <- c(lines, .generate_auto_viz(spec_name, spec))
  }

  lines <- c(lines, "```")

  # Add custom text content if provided (below chart)
  if (!is.null(spec$text) && nzchar(spec$text) && text_position == "below") {
    lines <- c(lines, "", spec$text, "")
  }

  lines <- c(lines, "")
  lines
}

#' Generate R code for typed visualizations
#'
#' Internal function that generates R code for specific visualization types
#' (stackedbar, heatmap, histogram, timeline) by mapping type names to
#' function names and serializing parameters.
#'
#' @param spec Visualization specification list containing type and parameters
#' @return Character vector of R code lines for the visualization
#' @details
#' This function:
#' - Maps visualization types to function names (e.g., "stackedbar" → "create_stackedbar")
#' - Excludes internal parameters (type, data_path, tabgroup, text, icon, text_position)
#' - Serializes all other parameters using .serialize_arg()
#' - Formats the function call with proper indentation
.generate_typed_viz <- function(spec) {
  lines <- character(0)

  ## TODO: this needs to create from some list of available visualizations (maybe!)
  # Map type to function name
  viz_function <- switch(spec$type,
                         "stackedbars" = "create_stackedbars",
                         "stackedbar" = "create_stackedbar",
                         "histogram" = "create_histogram",
                         "heatmap" = "create_heatmap",
                         "timeline" = "create_timeline",
                         spec$type
  )

  # Build argument list (exclude internal params)
  args <- list()

  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    args$data <- "data"  # Reference page-level data object
  }

  for (param in names(spec)) {
    if (!param %in% c("type", "data_path", "tabgroup", "text", "icon", "text_position", "height")) { # Exclude internal parameters
      args[[param]] <- .serialize_arg(spec[[param]])
    }
  }

  # Format function call with proper indentation
  if (length(args) == 0) {
    call_str <- paste0("result <- ", viz_function, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", viz_function, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- args[[i]]
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Generate code for custom function-based visualizations
.generate_function_viz <- function(spec) {
  lines <- character(0)

  # Load data if needed
  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    data_file <- basename(spec$data_path)
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  fn_name <- spec$fn
  args <- spec$args %||% list()

  if ("data" %in% names(args) && "data_path" %in% names(spec) && !is.null(spec$data_path)) {
    args$data <- "data"
  }

  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    serialized_args <- character(0)
    for (arg_name in names(args)) {
      serialized_args <- c(serialized_args,
                           paste0(arg_name, " = ", .serialize_arg(args[[arg_name]])))
    }
    args_str <- paste(serialized_args, collapse = ", ")
    call_str <- paste0("result <- ", fn_name, "(", args_str, ")")
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Auto-detect visualization type from parameters and generate code
.generate_auto_viz <- function(spec_name, spec) {
  lines <- character(0)

  # Load data if specified
  if ("data_path" %in% names(spec) && !is.null(spec$data_path)) {
    data_file <- basename(spec$data_path)
    lines <- c(lines, paste0("data <- readRDS('", data_file, "')"))
  }

  # Infer function name from parameters
  if ("questions" %in% names(spec)) {
    fn_name <- "create_stackedbars"
  } else if ("x_var" %in% names(spec) && "stack_var" %in% names(spec)) {
    fn_name <- "create_stackedbar"
  } else if ("x_var" %in% names(spec) && "y_var" %in% names(spec) && "value_var" %in% names(spec)) {
    fn_name <- "create_heatmap"
  } else if ("time_var" %in% names(spec)) {
    fn_name <- "create_timeline"
  } else if ("x_var" %in% names(spec)) {
    fn_name <- "create_histogram"
  } else {
    fn_name <- spec_name
  }

  # Clean up arguments
  args <- spec
  if ("data_path" %in% names(args) && !is.null(args$data_path)) {
    args$data_path <- NULL
    args$data <- "data"
  }
  if ("tabgroup" %in% names(args)) {
    args$tabgroup <- NULL
  }
  if ("text" %in% names(args)) {
    args$text <- NULL
  }
  if ("icon" %in% names(args)) {
    args$icon <- NULL
  }
  if ("text_position" %in% names(args)) {
    args$text_position <- NULL
  }
  if ("height" %in% names(args)) {
    args$height <- NULL
  }

  # Format function call
  if (length(args) == 0) {
    call_str <- paste0("result <- ", fn_name, "()")
  } else {
    arg_lines <- character(0)
    arg_lines <- c(arg_lines, paste0("result <- ", fn_name, "("))

    for (i in seq_along(args)) {
      arg_name <- names(args)[i]
      arg_value <- .serialize_arg(args[[arg_name]])
      comma <- if (i < length(args)) "," else ""
      arg_lines <- c(arg_lines, paste0("  ", arg_name, " = ", arg_value, comma))
    }

    arg_lines <- c(arg_lines, ")")
    call_str <- arg_lines
  }

  # Add height support if specified
  if (!is.null(spec$height)) {
    height_lines <- c(
      "",
      "# Apply height to highcharter object",
      paste0("if (inherits(result, 'highchart')) {"),
      paste0("  result <- highcharter::hc_chart(result, height = ", spec$height, ")"),
      paste0("}")
    )
    call_str <- c(call_str, height_lines)
  }

  # Always print the result
  call_str <- c(call_str, "", "result")

  c(lines, call_str)
}

# Generate Quarto tabset markup with visualizations
.generate_tabgroup_viz <- function(tabgroup_spec) {
  lines <- character(0)

  # Add section header if a label is provided
  if (!is.null(tabgroup_spec$label) && nzchar(tabgroup_spec$label)) {
    lines <- c(lines, paste0("## ", tabgroup_spec$label), "")
  } else if (!is.null(tabgroup_spec$name) && nzchar(tabgroup_spec$name)) {
    lines <- c(lines, paste0("## ", tabgroup_spec$name), "")
  }

  # Start tabset (only shows tabs if >1 viz)
  lines <- c(lines, "", "::: {.panel-tabset}", "")

  # Generate each tab
  for (i in seq_along(tabgroup_spec$visualizations)) {
    viz <- tabgroup_spec$visualizations[[i]]

    # Tab header: use viz title or default, with icon if provided
    viz_title <- if (is.null(viz$title) || length(viz$title) == 0 || viz$title == "") {
      paste0("Chart ", i)
    } else {
      viz$title
    }

    # Add icon to tab header if provided
    if (!is.null(viz$icon)) {
      icon_shortcode <- if (grepl("{{< iconify", viz$icon, fixed = TRUE)) {
        viz$icon
      } else {
        icon(viz$icon)
      }
      viz_title <- paste0(icon_shortcode, " ", viz_title)
    }

    lines <- c(lines, paste0("### ", viz_title), "")

    # Generate visualization code (skip header since we have tab header)
    viz_lines <- .generate_single_viz(paste0("tab_", i), viz, skip_header = TRUE)
    lines <- c(lines, viz_lines)

    if (i < length(tabgroup_spec$visualizations)) {
      lines <- c(lines, "")
    }
  }

  # Close tabset
  lines <- c(lines, "", ":::", "")

  lines
}

# ===================================================================
# Quarto File Generation
# ===================================================================

#' Generate _quarto.yml configuration file
#'
#' Internal function that generates the complete Quarto website configuration
#' file based on the dashboard project settings. Handles all Quarto website
#' features including navigation, styling, analytics, and deployment options.
#'
#' @param proj A dashboard_project object containing all configuration settings
#' @return Character vector of YAML lines for the _quarto.yml file
#' @details
#' This function generates a comprehensive Quarto configuration including:
#' - Project type and output directory
#' - Website title, favicon, and branding
#' - Navbar with social media links and search
#' - Sidebar with auto-generated navigation
#' - Format settings (theme, CSS, math, code features)
#' - Analytics (Google Analytics, Plausible, GTag)
#' - Deployment settings (GitHub Pages, Netlify)
#' - Iconify filter for icon support
.generate_quarto_yml <- function(proj) {
  yaml_lines <- c(
    "project:",
    "  type: website"
  )

  # Add output directory
  if (!is.null(proj$publish_dir)) {
    yaml_lines <- c(yaml_lines, paste0("  output-dir: ", proj$publish_dir))
  } else {
    yaml_lines <- c(yaml_lines, "  output-dir: docs")
  }

  yaml_lines <- c(yaml_lines, "")

  # Website configuration
  yaml_lines <- c(yaml_lines, "website:")
  yaml_lines <- c(yaml_lines, paste0("  title: \"", proj$title, "\""))

  # Add favicon if provided
  if (!is.null(proj$favicon)) {
    yaml_lines <- c(yaml_lines, paste0("  favicon: ", proj$favicon))
  }

  # Navbar configuration
  yaml_lines <- c(yaml_lines, "  navbar:")

  # Navbar style
  if (!is.null(proj$navbar_style)) {
    yaml_lines <- c(yaml_lines, paste0("    style: ", proj$navbar_style))
  }

  # Navbar brand
  if (!is.null(proj$navbar_brand)) {
    yaml_lines <- c(yaml_lines, paste0("    brand: \"", proj$navbar_brand, "\""))
  }

  # Navbar toggle
  if (!is.null(proj$navbar_toggle)) {
    yaml_lines <- c(yaml_lines, paste0("    toggle: ", proj$navbar_toggle))
  }

  # Left navigation
  yaml_lines <- c(yaml_lines, "    left:")

  # Add Home link if there's a landing page
  landing_page_name <- NULL
  for (page_name in names(proj$pages)) {
    if (proj$pages[[page_name]]$is_landing_page) {
      landing_page_name <- page_name
      break
    }
  }

  # Only add automatic "Home" link if not using navbar sections
  if (!is.null(landing_page_name) && (is.null(proj$navbar_sections) || length(proj$navbar_sections) == 0)) {
    yaml_lines <- c(yaml_lines,
    "      - href: index.qmd",
      "        text: \"Home\""
  )
  }

  # Add logo if provided
  if (!is.null(proj$logo)) {
    yaml_lines <- c(yaml_lines,
      paste0("    logo: ", proj$logo)
    )
  }

  # Add navigation links - support both regular pages and navbar sections
  if (!is.null(proj$navbar_sections) && length(proj$navbar_sections) > 0) {
    # Hybrid navigation mode - add navbar sections that link to sidebar groups
    for (section in proj$navbar_sections) {
      if (!is.null(section$sidebar)) {
        # This is a sidebar reference
        yaml_lines <- c(yaml_lines, paste0("      - sidebar:", section$sidebar))
      } else if (!is.null(section$href)) {
        # This is a regular link
        text_content <- paste0("\"", section$text, "\"")
        if (!is.null(section$icon)) {
          icon_shortcode <- if (grepl("{{< iconify", section$icon, fixed = TRUE)) {
            section$icon
          } else {
            icon(section$icon)
          }
          text_content <- paste0("\"", icon_shortcode, " ", section$text, "\"")
        }
        yaml_lines <- c(yaml_lines,
          paste0("      - href: ", section$href),
          paste0("        text: ", text_content)
        )
      }
    }
  } else {
    # Simple navigation mode - add all pages (existing behavior)
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]

      # Skip landing page in navbar since it's already linked as "Home"
      if (page$is_landing_page) {
        next
      }

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

      # Build text with icon if provided
      text_content <- paste0("\"", page_name, "\"")
      if (!is.null(page$icon)) {
        # Convert icon shortcode to proper format
        icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
          page$icon
        } else {
          icon(page$icon)
        }
        text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
      }

      yaml_lines <- c(yaml_lines,
                      paste0("      - href: ", filename, ".qmd"),
                      paste0("        text: ", text_content)
      )
    }
  }

  # Add tools section (right side of navbar)
  tools <- list()

  # Add social media and other tools
  if (!is.null(proj$github)) {
    tools <- c(tools, list(list(icon = "github", href = proj$github)))
  }
  if (!is.null(proj$twitter)) {
    tools <- c(tools, list(list(icon = "twitter", href = proj$twitter)))
  }
  if (!is.null(proj$linkedin)) {
    tools <- c(tools, list(list(icon = "linkedin", href = proj$linkedin)))
  }
  if (!is.null(proj$email)) {
    tools <- c(tools, list(list(icon = "envelope", href = paste0("mailto:", proj$email))))
  }
  if (!is.null(proj$website)) {
    tools <- c(tools, list(list(icon = "globe", href = proj$website)))
  }

  # Add tools section if any tools are provided
  if (length(tools) > 0) {
    yaml_lines <- c(yaml_lines, "    right:")
    for (tool in tools) {
      yaml_lines <- c(yaml_lines,
        paste0("      - icon: ", tool$icon),
        paste0("        href: ", tool$href)
      )
    }
  }

  # Add search if enabled
  if (proj$search) {
    yaml_lines <- c(yaml_lines, "    search: true")
  }

  # Sidebar configuration - supports both simple and hybrid navigation
  if (proj$sidebar || (!is.null(proj$sidebar_groups) && length(proj$sidebar_groups) > 0)) {
    yaml_lines <- c(yaml_lines, "  sidebar:")

    # Check if we're using hybrid navigation (sidebar groups)
    if (!is.null(proj$sidebar_groups) && length(proj$sidebar_groups) > 0) {
      # Hybrid navigation mode - multiple sidebar groups
      for (i in seq_along(proj$sidebar_groups)) {
        group <- proj$sidebar_groups[[i]]

        # Add group with ID
        yaml_lines <- c(yaml_lines, paste0("    - id: ", group$id))
        yaml_lines <- c(yaml_lines, paste0("      title: \"", group$title, "\""))

        # Add styling options (inherit from first group if not specified)
        if (!is.null(group$style)) {
          yaml_lines <- c(yaml_lines, paste0("      style: \"", group$style, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_style)) {
          yaml_lines <- c(yaml_lines, paste0("      style: \"", proj$sidebar_style, "\""))
        }

        if (!is.null(group$background)) {
          yaml_lines <- c(yaml_lines, paste0("      background: \"", group$background, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_background)) {
          yaml_lines <- c(yaml_lines, paste0("      background: \"", proj$sidebar_background, "\""))
        }

        if (!is.null(group$foreground)) {
          yaml_lines <- c(yaml_lines, paste0("      foreground: \"", group$foreground, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_foreground)) {
          yaml_lines <- c(yaml_lines, paste0("      foreground: \"", group$foreground, "\""))
        }

        if (!is.null(group$border)) {
          yaml_lines <- c(yaml_lines, paste0("      border: ", tolower(group$border)))
        } else if (i == 1 && !is.null(proj$sidebar_border)) {
          yaml_lines <- c(yaml_lines, paste0("      border: ", tolower(proj$sidebar_border)))
        }

        if (!is.null(group$alignment)) {
          yaml_lines <- c(yaml_lines, paste0("      alignment: \"", group$alignment, "\""))
        } else if (i == 1 && !is.null(proj$sidebar_alignment)) {
          yaml_lines <- c(yaml_lines, paste0("      alignment: \"", proj$sidebar_alignment, "\""))
        }

        if (!is.null(group$collapse_level)) {
          yaml_lines <- c(yaml_lines, paste0("      collapse-level: ", group$collapse_level))
        } else if (i == 1 && !is.null(proj$sidebar_collapse_level)) {
          yaml_lines <- c(yaml_lines, paste0("      collapse-level: ", proj$sidebar_collapse_level))
        }

        if (!is.null(group$pinned)) {
          yaml_lines <- c(yaml_lines, paste0("      pinned: ", tolower(group$pinned)))
        } else if (i == 1 && !is.null(proj$sidebar_pinned)) {
          yaml_lines <- c(yaml_lines, paste0("      pinned: ", tolower(proj$sidebar_pinned)))
        }

        # Add tools if specified
        if (!is.null(group$tools) && length(group$tools) > 0) {
          yaml_lines <- c(yaml_lines, "      tools:")
          for (tool in group$tools) {
            if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        - icon: ", tool$icon))
              yaml_lines <- c(yaml_lines, paste0("          href: ", tool$href))
              if ("text" %in% names(tool)) {
                yaml_lines <- c(yaml_lines, paste0("          text: \"", tool$text, "\""))
              }
            }
          }
        } else if (i == 1 && !is.null(proj$sidebar_tools) && length(proj$sidebar_tools) > 0) {
          yaml_lines <- c(yaml_lines, "      tools:")
          for (tool in proj$sidebar_tools) {
            if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        - icon: ", tool$icon))
              yaml_lines <- c(yaml_lines, paste0("          href: ", tool$href))
              if ("text" %in% names(tool)) {
                yaml_lines <- c(yaml_lines, paste0("          text: \"", tool$text, "\""))
              }
            }
          }
        }

        # Add contents for this group (only if there are pages)
        pages_added <- 0
        for (page_name in group$pages) {
          # Find matching page (case-insensitive)
          matching_page <- NULL
          for (actual_page_name in names(proj$pages)) {
            if (tolower(gsub("[^a-zA-Z0-9]", "_", actual_page_name)) == tolower(gsub("[^a-zA-Z0-9]", "_", page_name))) {
              matching_page <- actual_page_name
              break
            }
          }

          if (!is.null(matching_page)) {
            # Skip landing pages in sidebar groups (they're already in navbar)
            if (proj$pages[[matching_page]]$is_landing_page) {
              next
            }

            if (pages_added == 0) {
              yaml_lines <- c(yaml_lines, "      contents:")
            }
            pages_added <- pages_added + 1

            # Use lowercase with underscores for filenames
            filename <- tolower(gsub("[^a-zA-Z0-9]", "_", matching_page))

            # Build text with icon if provided
            text_content <- paste0("\"", matching_page, "\"")
            if (!is.null(proj$pages[[matching_page]]$icon)) {
              icon_shortcode <- if (grepl("{{< iconify", proj$pages[[matching_page]]$icon, fixed = TRUE)) {
                proj$pages[[matching_page]]$icon
              } else {
                icon(proj$pages[[matching_page]]$icon)
              }
              text_content <- paste0("\"", icon_shortcode, " ", matching_page, "\"")
            }

            yaml_lines <- c(yaml_lines,
              paste0("        - text: ", text_content),
              paste0("          href: ", filename, ".qmd")
            )
          }
        }

        # If no pages were added, add a placeholder to avoid empty contents
        if (pages_added == 0) {
          yaml_lines <- c(yaml_lines, "      contents:")
          yaml_lines <- c(yaml_lines, "        - text: \"No pages in this group\"")
          yaml_lines <- c(yaml_lines, "          href: #")
        }
      }
    } else {
      # Simple sidebar mode - single sidebar (existing behavior)

      # Sidebar style
      if (!is.null(proj$sidebar_style)) {
        yaml_lines <- c(yaml_lines, paste0("    style: \"", proj$sidebar_style, "\""))
      }

      # Sidebar background
      if (!is.null(proj$sidebar_background)) {
        yaml_lines <- c(yaml_lines, paste0("    background: \"", proj$sidebar_background, "\""))
      }

      # Sidebar foreground
      if (!is.null(proj$sidebar_foreground)) {
        yaml_lines <- c(yaml_lines, paste0("    foreground: \"", proj$sidebar_foreground, "\""))
      }

      # Sidebar border
      if (!is.null(proj$sidebar_border)) {
        yaml_lines <- c(yaml_lines, paste0("    border: ", tolower(proj$sidebar_border)))
      }

      # Sidebar alignment
      if (!is.null(proj$sidebar_alignment)) {
        yaml_lines <- c(yaml_lines, paste0("    alignment: \"", proj$sidebar_alignment, "\""))
      }

      # Sidebar collapse level
      if (!is.null(proj$sidebar_collapse_level)) {
        yaml_lines <- c(yaml_lines, paste0("    collapse-level: ", proj$sidebar_collapse_level))
      }

      # Sidebar pinned
      if (!is.null(proj$sidebar_pinned)) {
        yaml_lines <- c(yaml_lines, paste0("    pinned: ", tolower(proj$sidebar_pinned)))
      }

      # Sidebar tools
      if (!is.null(proj$sidebar_tools) && length(proj$sidebar_tools) > 0) {
        yaml_lines <- c(yaml_lines, "    tools:")
        for (tool in proj$sidebar_tools) {
          if (is.list(tool) && "icon" %in% names(tool) && "href" %in% names(tool)) {
            yaml_lines <- c(yaml_lines, paste0("      - icon: ", tool$icon))
            yaml_lines <- c(yaml_lines, paste0("        href: ", tool$href))
            if ("text" %in% names(tool)) {
              yaml_lines <- c(yaml_lines, paste0("        text: \"", tool$text, "\""))
            }
          }
        }
      }

      # Sidebar contents - auto-generate from pages if not specified
      if (!is.null(proj$sidebar_contents)) {
        yaml_lines <- c(yaml_lines, "    contents:")
        for (item in proj$sidebar_contents) {
          if (is.list(item)) {
            if ("text" %in% names(item) && "href" %in% names(item)) {
              yaml_lines <- c(yaml_lines, paste0("      - text: \"", item$text, "\""))
              yaml_lines <- c(yaml_lines, paste0("        href: ", item$href))
            } else if ("section" %in% names(item)) {
              yaml_lines <- c(yaml_lines, paste0("      - section: \"", item$section, "\""))
              if ("contents" %in% names(item)) {
                yaml_lines <- c(yaml_lines, "        contents:")
                for (subitem in item$contents) {
                  if (is.character(subitem)) {
                    yaml_lines <- c(yaml_lines, paste0("          - ", subitem))
                  } else if (is.list(subitem)) {
                    yaml_lines <- c(yaml_lines, paste0("          - text: \"", subitem$text, "\""))
                    yaml_lines <- c(yaml_lines, paste0("            href: ", subitem$href))
                  }
                }
              }
            }
          } else if (is.character(item)) {
            yaml_lines <- c(yaml_lines, paste0("      - ", item))
          }
        }
      } else {
        # Auto-generate sidebar contents from pages
        yaml_lines <- c(yaml_lines, "    contents:")

        # Add landing page first if it exists
        landing_page_name <- NULL
        for (page_name in names(proj$pages)) {
          if (proj$pages[[page_name]]$is_landing_page) {
            landing_page_name <- page_name
            break
          }
        }

        if (!is.null(landing_page_name)) {
          yaml_lines <- c(yaml_lines, "      - text: \"Home\"")
          yaml_lines <- c(yaml_lines, "        href: index.qmd")
        }

        # Add other pages
        for (page_name in names(proj$pages)) {
          if (!is.null(proj$landing_page) && page_name == proj$landing_page) {
            next  # Skip landing page as it's already added
          }

          # Use lowercase with underscores for filenames
          filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

          # Build text with icon if provided
          text_content <- paste0("\"", page_name, "\"")
          if (!is.null(proj$pages[[page_name]]$icon)) {
            icon_shortcode <- if (grepl("{{< iconify", proj$pages[[page_name]]$icon, fixed = TRUE)) {
              proj$pages[[page_name]]$icon
            } else {
              icon(proj$pages[[page_name]]$icon)
            }
            text_content <- paste0("\"", icon_shortcode, " ", page_name, "\"")
          }

          yaml_lines <- c(yaml_lines,
            paste0("      - text: ", text_content),
            paste0("        href: ", filename, ".qmd")
          )
        }
      }
    }
  }

  # Add breadcrumbs
  if (!is.null(proj$breadcrumbs)) {
    yaml_lines <- c(yaml_lines, paste0("  bread-crumbs: ", tolower(proj$breadcrumbs)))
  }

  # Add page navigation
  if (!is.null(proj$page_navigation)) {
    yaml_lines <- c(yaml_lines, paste0("  page-navigation: ", tolower(proj$page_navigation)))
  }

  # Add back to top
  if (!is.null(proj$back_to_top)) {
    yaml_lines <- c(yaml_lines, paste0("  back-to-top-navigation: ", tolower(proj$back_to_top)))
  }

  # Add reader mode
  if (!is.null(proj$reader_mode)) {
    yaml_lines <- c(yaml_lines, paste0("  reader-mode: ", tolower(proj$reader_mode)))
  }

  # Add repository URL and actions
  if (!is.null(proj$repo_url)) {
    yaml_lines <- c(yaml_lines, paste0("  repo-url: ", proj$repo_url))
    if (!is.null(proj$repo_actions) && length(proj$repo_actions) > 0) {
      actions_str <- paste(proj$repo_actions, collapse = ", ")
      yaml_lines <- c(yaml_lines, paste0("  repo-actions: [", actions_str, "]"))
    }
  }

  # Add page footer if provided
  if (!is.null(proj$page_footer)) {
    yaml_lines <- c(yaml_lines, paste0("  page-footer: \"", proj$page_footer, "\""))
  }

  # Add iconify filter for icon support
  yaml_lines <- c(yaml_lines,
    "",
    "format:",
    "  html:",
    "    theme:",
    paste0("      - ", proj$theme %||% "default"),
    ""
  )

  # Add custom CSS if provided
  if (!is.null(proj$custom_css)) {
    yaml_lines <- c(yaml_lines, "    css:")
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_css))
  }

  # Add custom SCSS if provided
  if (!is.null(proj$custom_scss)) {
    yaml_lines <- c(yaml_lines, "    scss:")
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_scss))
  }

  # Add table of contents (simplified)
  if (!is.null(proj$toc)) {
    yaml_lines <- c(yaml_lines, "    toc: true")
  }

  # Add math rendering
  if (!is.null(proj$math)) {
    yaml_lines <- c(yaml_lines, "    math:")
    yaml_lines <- c(yaml_lines, paste0("      engine: ", proj$math))
  }

  # Add code folding
  if (!is.null(proj$code_folding)) {
    yaml_lines <- c(yaml_lines, "    code-fold: true")
  }

  # Add code tools
  if (!is.null(proj$code_tools)) {
    yaml_lines <- c(yaml_lines, "    code-tools: true")
  }

  # Add value boxes
  if (proj$value_boxes) {
    yaml_lines <- c(yaml_lines, "    value-boxes: true")
  }

  # Add page layout
  if (!is.null(proj$page_layout)) {
    yaml_lines <- c(yaml_lines, paste0("    page-layout: ", proj$page_layout))
  }

  # Add Shiny
  if (proj$shiny) {
    yaml_lines <- c(yaml_lines, "    shiny: true")
  }

  # Add Observable
  if (proj$observable) {
    yaml_lines <- c(yaml_lines, "    observable: true")
  }

  # Add Jupyter
  if (proj$jupyter) {
    yaml_lines <- c(yaml_lines, "    jupyter: true")
  }

  # Add analytics
  if (!is.null(proj$google_analytics)) {
    yaml_lines <- c(yaml_lines, "    google-analytics:")
    yaml_lines <- c(yaml_lines, paste0("      id: \"", proj$google_analytics, "\""))
  }

  if (!is.null(proj$plausible)) {
    yaml_lines <- c(yaml_lines, "    plausible:")
    yaml_lines <- c(yaml_lines, paste0("      domain: \"", proj$plausible, "\""))
  }

  if (!is.null(proj$gtag)) {
    yaml_lines <- c(yaml_lines, "    gtag:")
    yaml_lines <- c(yaml_lines, paste0("      id: \"", proj$gtag, "\""))
  }

  # Add GitHub Pages
  if (!is.null(proj$github_pages)) {
    yaml_lines <- c(yaml_lines, "    github-pages:")
    if (is.character(proj$github_pages)) {
      yaml_lines <- c(yaml_lines, paste0("      branch: ", proj$github_pages))
    } else if (is.list(proj$github_pages)) {
      for (key in names(proj$github_pages)) {
        yaml_lines <- c(yaml_lines, paste0("      ", key, ": ", proj$github_pages[[key]]))
      }
    }
  }

  # Add Netlify
  if (!is.null(proj$netlify)) {
    yaml_lines <- c(yaml_lines, "    netlify:")
    if (is.list(proj$netlify)) {
      for (key in names(proj$netlify)) {
        yaml_lines <- c(yaml_lines, paste0("      ", key, ": ", proj$netlify[[key]]))
      }
    }
  }

  # Add iconify filter only if icons are used
  if (.check_for_icons(proj)) {
    yaml_lines <- c(yaml_lines,
      "",
      "filters:",
      "  - mcanouil/iconify"
    )
  }

  yaml_lines
}


# Generate default page content when no custom template is used
.generate_default_page_content <- function(page) {
  # Build title with icon if provided
  title_content <- page$name
  if (!is.null(page$icon)) {
    icon_shortcode <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
      page$icon
    } else {
      icon(page$icon)
    }
    title_content <- paste0(icon_shortcode, " ", page$name)
  }

  content <- c(
    "---",
    paste0("title: \"", title_content, "\""),
    "format: html",
    "---",
    ""
  )

  # Add custom text content if provided
  if (!is.null(page$text) && nzchar(page$text)) {
    content <- c(content, page$text, "")
  }

  # Add global setup chunk with libraries, data, and settings
  if (!is.null(page$data_path) || !is.null(page$visualizations)) {
    content <- c(content, .generate_global_setup_chunk(page))
  }

  # Add visualizations
  if (!is.null(page$visualizations)) {
    viz_content <- .generate_viz_from_specs(page$visualizations)
    content <- c(content, viz_content)
  } else if (is.null(page$text) || !nzchar(page$text)) {
    content <- c(content, "This page was generated without a template.")
  }

  content
}

#' Generate global setup chunk for QMD files
#'
#' Creates a comprehensive setup chunk that includes libraries, data loading,
#' and global settings to avoid repetition in individual visualizations.
#'
#' @param page Page object containing data_path and visualizations
#' @return Character vector of setup chunk lines
.generate_global_setup_chunk <- function(page) {
  lines <- c(
    "```{r setup}",
    "#| echo: false",
    "#| warning: false",
    "#| message: false",
    "#| error: false",
    "#| results: 'hide'",
    "",
    "# Load required libraries",
    "library(dashboardr)",
    "library(dplyr)",
    "library(highcharter)",
    "",
    "# Global chunk options",
    "knitr::opts_chunk$set(",
    "  echo = FALSE,",
    "  warning = FALSE,",
    "  message = FALSE,",
    "  error = FALSE,",
    "  fig.width = 12,",
    "  fig.height = 8,",
    "  dpi = 300",
    ")",
    ""
  )

  # Add data loading if data_path is present
  if (!is.null(page$data_path)) {
    data_file <- basename(page$data_path)
    lines <- c(lines,
      paste0("# Load data from ", data_file),
      paste0("data <- readRDS('", data_file, "')"),
      "",
      "# Data summary",
      "cat('Dataset loaded:', nrow(data), 'rows,', ncol(data), 'columns\\n')",
      ""
    )
  }

  # Add visualization-specific setup if visualizations are present
  if (!is.null(page$visualizations)) {
    lines <- c(lines,
      "# Visualization setup",
      "# All visualizations will use the loaded data and global settings",
      ""
    )
  }

  lines <- c(lines, "```", "")
  lines
}

# ===================================================================
# Dashboard Generation and Rendering
# ===================================================================

#' Generate all dashboard files
#'
#' Writes out all .qmd files, _quarto.yml, and optionally renders the dashboard
#' to HTML using Quarto.
#'
#' @param proj A dashboard_project object
#' @param render Whether to render to HTML (requires Quarto CLI)
#' @param open How to open the result: "browser", "viewer", or FALSE
#' @return Invisibly returns the project object
#' @export
#' @examples
#' \dontrun{
#' dashboard %>% generate_dashboard(render = TRUE, open = "browser")
#' }
generate_dashboard <- function(proj, render = TRUE, open = "browser") {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }

  output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  tryCatch({
    # Check if icons are used and install iconify extension if needed
    if (.check_for_icons(proj)) {
      # Check if iconify extension is already installed
      iconify_dir <- file.path(output_dir, "_extensions", "mcanouil", "iconify")
      if (!dir.exists(iconify_dir) || !file.exists(file.path(iconify_dir, "_extension.yml"))) {
        message("Icons detected in dashboard. Installing iconify extension...")

        # # Attempt to install iconify extension with proper error handling
        # install_success <- .install_iconify_extension(output_dir)
        # if (!install_success) {
        #   warning("Failed to install iconify extension automatically. Icons may not display correctly.")
        #   message("To fix this manually:")
        #   message("1. Install git: https://git-scm.com/downloads")
        #   message("2. Run: git clone https://github.com/mcanouil/quarto-iconify.git _extensions/mcanouil/iconify")
        #   message("3. Or remove icons from your dashboard to render without them")
        # }
    } else {
        message("Iconify extension already installed")
      }
    }

    # Copy logo and favicon if provided
    if (!is.null(proj$logo) && file.exists(proj$logo)) {
      file.copy(proj$logo, file.path(output_dir, basename(proj$logo)), overwrite = TRUE)
    }
    if (!is.null(proj$favicon) && file.exists(proj$favicon)) {
      file.copy(proj$favicon, file.path(output_dir, basename(proj$favicon)), overwrite = TRUE)
    }

    # Generate _quarto.yml
    yaml_content <- .generate_quarto_yml(proj)
    writeLines(yaml_content, file.path(output_dir, "_quarto.yml"))

    # Generate each page
    for (page_name in names(proj$pages)) {
      page <- proj$pages[[page_name]]

      # Skip landing page in regular pages loop - it's handled separately
      if (!is.null(proj$landing_page) && page_name == proj$landing_page) {
        next
      }

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
      page_file <- file.path(output_dir, paste0(filename, ".qmd"))

      if (!is.null(page$template)) {
        # Custom template
        content <- .process_template(page$template, page$params, output_dir)
        if (!is.null(page$visualizations)) {
          content <- .process_viz_specs(content, page$visualizations)
        }
      } else {
        # Default page generation
        content <- .generate_default_page_content(page)
      }

      writeLines(content, page_file)

      # Copy data file if needed
      if (!is.null(page$data_path)) {
        data_file_path <- file.path(output_dir, basename(page$data_path))
        target_path <- file.path(output_dir, basename(page$data_path))

        # Only copy if source and target are different
        if (normalizePath(data_file_path, mustWork = FALSE) != normalizePath(target_path, mustWork = FALSE)) {
          if (file.exists(data_file_path) && !file.copy(data_file_path, target_path, overwrite = TRUE)) {
            warning("Failed to copy data file: ", basename(page$data_path))
          }
        }
      }
    }

    # Generate landing page as index.qmd if specified
    if (!is.null(proj$landing_page)) {
      landing_page <- proj$pages[[proj$landing_page]]
      index_file <- file.path(output_dir, "index.qmd")

      if (!is.null(landing_page$template)) {
        # Custom template
        content <- .process_template(landing_page$template, landing_page$params, output_dir)
        if (!is.null(landing_page$visualizations)) {
          viz_content <- .generate_viz_from_specs(landing_page$visualizations)
          content <- c(content, "", viz_content)
        }
      } else {
        # Default content
        content <- .generate_default_page_content(landing_page)
      }

      writeLines(content, index_file)
    }

    message("Dashboard files generated successfully")

    # Render to HTML if requested
    render_success <- FALSE
    if (render) {
      render_success <- .render_dashboard(output_dir, open)
    }

    # Show beautiful CLI output after rendering (only if successful or not rendering)
    if (render_success || !render) {
      .show_dashboard_summary(proj, output_dir)
    }

  }, error = function(e) {
    stop("Failed to generate dashboard: ", e$message)
  })

  invisible(proj)
}

# Render Quarto project to HTML
.render_dashboard <- function(output_dir, open = FALSE) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    message("quarto package not available. Skipping render.")
    message("Install with: install.packages('quarto')")
    return(FALSE)
  }

  # Create docs folder even if rendering fails
  docs_dir <- file.path(output_dir, "docs")
  if (!dir.exists(docs_dir)) {
    dir.create(docs_dir, recursive = TRUE)
    message("Created docs folder. Note: Quarto rendering may have failed.")
  }

  owd <- setwd(normalizePath(output_dir))
  on.exit(setwd(owd), add = TRUE)

  tryCatch({
    quarto::quarto_render(".", as_job = FALSE)
    message("Dashboard rendered successfully")

    if (open == "browser") {
      index_file <- file.path(output_dir, "docs", "index.html")
      if (file.exists(index_file)) {
        utils::browseURL(index_file)
      }
    }
    return(TRUE)
  }, error = function(e) {
    warning("Failed to render dashboard: ", e$message)

    # Check if it's an iconify extension error
    if (grepl("iconify", e$message, ignore.case = TRUE)) {
      message("\n=== ICONIFY EXTENSION ERROR ===")
      message("The iconify extension is not installed. To fix this:")
      message("1. Install Quarto CLI: https://quarto.org/docs/get-started/")
      message("2. Run in your dashboard directory: quarto add mcanouil/quarto-iconify")
      message("3. Or run the provided script: ./install_iconify_manual.sh")
      message("\nAlternative: Remove icons from your dashboard calls to render without icons")
    } else {
      message("To fix this issue:")
      message("1. Install Quarto command-line tools from: https://quarto.org/docs/get-started/")
      message("2. Or run 'quarto install' in R to install via the quarto package")
    }
    message("3. The QMD files are ready for manual rendering with: quarto render")
    return(FALSE)
  })
}

# ===================================================================
# Custom Print Methods for Better User Experience
# ===================================================================

#' Print method for dashboard projects
#'
#' Displays a concise summary of the dashboard structure instead of
#' the raw list internals.
#'
#' @param x A dashboard_project object
#' @param ... Additional arguments (ignored)
#' @export
print.dashboard_project <- function(x, ...) {
  cat("Dashboard Project\n")
  cat("  Title: ", x$title, "\n", sep = "")
  cat("  Output: ", .resolve_output_dir(x$output_dir, x$allow_inside_pkg), "\n", sep = "")
  if (!is.null(x$data_files)) {
    cat("  Data files: ", length(x$data_files), "\n", sep = "")
  }

  # Show author and description
  if (!is.null(x$author)) {
    cat("  Author: ", x$author, "\n", sep = "")
  }
  if (!is.null(x$description)) {
    cat("  Description: ", x$description, "\n", sep = "")
  }

  # Show social media links if any are provided
  social_links <- c()
  if (!is.null(x$github)) social_links <- c(social_links, paste0("GitHub: ", x$github))
  if (!is.null(x$twitter)) social_links <- c(social_links, paste0("Twitter: ", x$twitter))
  if (!is.null(x$linkedin)) social_links <- c(social_links, paste0("LinkedIn: ", x$linkedin))
  if (!is.null(x$email)) social_links <- c(social_links, paste0("Email: ", x$email))
  if (!is.null(x$website)) social_links <- c(social_links, paste0("Website: ", x$website))

  if (length(social_links) > 0) {
    cat("  Social links: ", paste(social_links, collapse = ", "), "\n", sep = "")
  }

  # Show theme and styling
  styling <- c()
  if (!is.null(x$theme)) styling <- c(styling, paste0("Theme: ", x$theme))
  if (!is.null(x$custom_css)) styling <- c(styling, paste0("Custom CSS: ", x$custom_css))
  if (!is.null(x$custom_scss)) styling <- c(styling, paste0("Custom SCSS: ", x$custom_scss))
  if (x$value_boxes) styling <- c(styling, "Value boxes enabled")

  if (length(styling) > 0) {
    cat("  Styling: ", paste(styling, collapse = ", "), "\n", sep = "")
  }

  # Show layout features
  layout <- c()
  if (x$sidebar) layout <- c(layout, "Sidebar enabled")
  if (!is.null(x$toc)) layout <- c(layout, paste0("TOC: ", x$toc))
  if (!is.null(x$navbar_style)) layout <- c(layout, paste0("Navbar: ", x$navbar_style))
  if (x$search) layout <- c(layout, "Search enabled")

  if (length(layout) > 0) {
    cat("  Layout: ", paste(layout, collapse = ", "), "\n", sep = "")
  }

  # Show technical features
  technical <- c()
  if (!is.null(x$math)) technical <- c(technical, paste0("Math: ", x$math))
  if (!is.null(x$code_folding)) technical <- c(technical, paste0("Code folding: ", x$code_folding))
  if (!is.null(x$code_tools)) technical <- c(technical, "Code tools enabled")
  if (x$shiny) technical <- c(technical, "Shiny enabled")
  if (x$observable) technical <- c(technical, "Observable enabled")
  if (x$jupyter) technical <- c(technical, "Jupyter enabled")

  if (length(technical) > 0) {
    cat("  Technical: ", paste(technical, collapse = ", "), "\n", sep = "")
  }

  # Show analytics
  analytics <- c()
  if (!is.null(x$google_analytics)) analytics <- c(analytics, paste0("Google Analytics: ", x$google_analytics))
  if (!is.null(x$plausible)) analytics <- c(analytics, paste0("Plausible: ", x$plausible))
  if (!is.null(x$gtag)) analytics <- c(analytics, paste0("GTag: ", x$gtag))

  if (length(analytics) > 0) {
    cat("  Analytics: ", paste(analytics, collapse = ", "), "\n", sep = "")
  }
  cat("  Pages (", length(x$pages), "):\n", sep = "")
  if (length(x$pages) > 0) {
    for (page_name in names(x$pages)) {
      page <- x$pages[[page_name]]
      viz <- page$visualizations %||% list()
      num_viz <- length(viz)
      # Count tab groups vs standalone visualizations
      num_tabgroups <- sum(vapply(viz, function(v) identical(v$type, "tabgroup"), logical(1)))
      num_standalone <- num_viz - num_tabgroups
      cat("    • ", page_name, "\n", sep = "")
      if (!is.null(page$data_path)) cat("      data: ", page$data_path, "\n", sep = "")
      cat("      visualizations: ", num_viz,
          if (num_viz > 0) paste0(" (", num_standalone, " standalone, ", num_tabgroups, " tabgroup)") else "",
          "\n", sep = "")
      # Show compact list of visualizations
      if (num_viz > 0) {
        for (i in seq_along(viz)) {
          v <- viz[[i]]
          if (!identical(v$type, "tabgroup")) {
            title <- v$title %||% v$type
            group <- v$tabgroup %||% "-"
            cat("        - [", group, "] ", v$type, if (!is.null(v$title)) paste0(" — ", v$title) else "", "\n", sep = "")
          } else {
            cat("        - <tabgroup> ", v$name, " (", length(v$visualizations), " tabs)\n", sep = "")
          }
        }
      }
    }
  }
  invisible(x)
}

#' Print method for visualization collections
#'
#' Displays a summary of visualizations in the collection grouped by tabgroup.
#'
#' @param x A viz_collection object
#' @param ... Additional arguments (ignored)
#' @export
print.viz_collection <- function(x, ...) {
  total <- length(x$visualizations)
  cat("Visualization Collection\n")
  cat("  Count: ", total, "\n", sep = "")
  if (total == 0) return(invisible(x))

  # Summarize by tabgroup
  groups <- vapply(x$visualizations, function(v) v$tabgroup %||% "(none)", character(1))
  group_table <- sort(table(groups), decreasing = TRUE)
  cat("  Groups:\n")
  for (g in names(group_table)) {
    cat("    • ", g, ": ", group_table[[g]], "\n", sep = "")
  }
  cat("  Items:\n")
  for (i in seq_along(x$visualizations)) {
    v <- x$visualizations[[i]]
    title <- v$title %||% v$type
    group <- v$tabgroup %||% "(none)"
    cat("    ", sprintf("%2d", i), ") ", "[", group, "] ", v$type,
        if (!is.null(v$title)) paste0(" — ", v$title) else "",
        "\n", sep = "")
  }
  invisible(x)
}

# ===================================================================
# Hybrid Navigation Helper Functions
# ===================================================================

#' Create a sidebar group for hybrid navigation
#'
#' Helper function to create a sidebar group configuration for use with
#' hybrid navigation. Each group can have its own styling and contains
#' a list of pages.
#'
#' @param id Unique identifier for the sidebar group
#' @param title Display title for the sidebar group
#' @param pages Character vector of page names to include in this group
#' @param style Sidebar style (docked, floating, etc.) (optional)
#' @param background Background color (optional)
#' @param foreground Foreground color (optional)
#' @param border Show border (optional)
#' @param alignment Alignment (left, right) (optional)
#' @param collapse_level Collapse level for navigation (optional)
#' @param pinned Whether sidebar is pinned (optional)
#' @param tools List of tools to add to sidebar (optional)
#' @return List containing sidebar group configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a sidebar group for analysis pages
#' analysis_group <- sidebar_group(
#'   id = "analysis",
#'   title = "Data Analysis",
#'   pages = c("overview", "demographics", "findings"),
#'   style = "docked",
#'   background = "light"
#' )
#' }
sidebar_group <- function(id, title, pages, style = NULL, background = NULL,
                         foreground = NULL, border = NULL, alignment = NULL,
                         collapse_level = NULL, pinned = NULL, tools = NULL) {

  # Validate required parameters
  if (is.null(id) || !is.character(id) || length(id) != 1 || nchar(id) == 0) {
    stop("id must be a non-empty character string")
  }
  if (is.null(title) || !is.character(title) || length(title) != 1 || nchar(title) == 0) {
    stop("title must be a non-empty character string")
  }
  if (is.null(pages) || !is.character(pages) || length(pages) == 0) {
    stop("pages must be a non-empty character vector")
  }

  # Build the sidebar group configuration
  group <- list(
    id = id,
    title = title,
    pages = pages
  )

  # Add optional styling parameters
  if (!is.null(style)) group$style <- style
  if (!is.null(background)) group$background <- background
  if (!is.null(foreground)) group$foreground <- foreground
  if (!is.null(border)) group$border <- border
  if (!is.null(alignment)) group$alignment <- alignment
  if (!is.null(collapse_level)) group$collapse_level <- collapse_level
  if (!is.null(pinned)) group$pinned <- pinned
  if (!is.null(tools)) group$tools <- tools

  group
}

#' Create a navbar section for hybrid navigation
#'
#' Helper function to create a navbar section that links to a sidebar group
#' for hybrid navigation. This creates dropdown-style navigation.
#'
#' @param text Display text for the navbar item
#' @param sidebar_id ID of the sidebar group to link to
#' @param icon Optional icon for the navbar item
#' @return List containing navbar section configuration
#' @export
#' @examples
#' \dontrun{
#' # Create navbar sections that link to sidebar groups
#' analysis_section <- navbar_section("Analysis", "analysis", "ph:chart-bar")
#' reference_section <- navbar_section("Reference", "reference", "ph:book")
#' }
navbar_section <- function(text, sidebar_id, icon = NULL) {

  # Validate required parameters
  if (is.null(text) || !is.character(text) || length(text) != 1 || nchar(text) == 0) {
    stop("text must be a non-empty character string")
  }
  if (is.null(sidebar_id) || !is.character(sidebar_id) || length(sidebar_id) != 1 || nchar(sidebar_id) == 0) {
    stop("sidebar_id must be a non-empty character string")
  }

  # Build the navbar section configuration
  section <- list(
    text = text,
    sidebar = sidebar_id
  )

  # Add icon if provided
  if (!is.null(icon)) {
    section$icon <- icon
  }

  section
}

# ===================================================================
# Pipe Operator Support
# ===================================================================

# Import pipe operator from magrittr for fluent workflows
`%>%` <- magrittr::`%>%`

# ===================================================================
# Dashboard Publishing Functions
# ===================================================================

#' Publish dashboard to GitHub Pages or GitLab Pages
#'
#' This function automates the process of publishing a dashboard to GitHub Pages
#' or GitLab Pages. It handles git initialization, remote setup, and deployment
#' configuration.
#'
#' @param dashboard_path Path to the generated dashboard directory
#' @param platform Platform to publish to: "github" or "gitlab"
#' @param repo_name Name for the repository (defaults to dashboard directory name)
#' @param username GitHub/GitLab username (optional, will prompt if not provided)
#' @param private Whether to create a private repository (default: FALSE)
#' @param open_browser Whether to open the published dashboard in browser (default: TRUE)
#' @param commit_message Git commit message (default: "Deploy dashboard")
#' @param branch Branch to deploy from (default: "main")
#' @param docs_subdir Subdirectory containing the docs (default: "docs")
#' @param include_data Whether to include data files in the repository (default: FALSE)
#'
#' @return Invisibly returns the repository URL
#' @export
#'
#' @examples
#' \dontrun{
#' # After generating a dashboard
#' dashboard <- create_dashboard("my_dashboard") %>%
#'   add_page("Analysis", data = my_data, visualizations = my_viz) %>%
#'   generate_dashboard()
#'
#' # Publish to GitHub Pages
#' publish_dashboard("my_dashboard", platform = "github", username = "myusername")
#'
#' # Publish to GitLab Pages
#' publish_dashboard("my_dashboard", platform = "gitlab", username = "myusername")
#' }
publish_dashboard <- function(dashboard_path,
                             platform = c("github", "gitlab"),
                             repo_name = NULL,
                             username = NULL,
                             private = FALSE,
                             open_browser = FALSE,
                             commit_message = "Deploy dashboard",
                             branch = "main",
                             docs_subdir = "docs",
                             include_data = FALSE) {

  platform <- match.arg(platform)

  # Validate dashboard path
  if (!dir.exists(dashboard_path)) {
    stop("Dashboard directory does not exist: ", dashboard_path)
  }

  # Check if docs directory exists
  docs_path <- file.path(dashboard_path, docs_subdir)
  if (!dir.exists(docs_path)) {
    stop("Docs directory not found: ", docs_path,
         "\nMake sure to run generate_dashboard() first")
  }

  # Check if docs directory has content (at least one HTML file)
  html_files <- list.files(docs_path, pattern = "\\.html$", full.names = FALSE)
  if (length(html_files) == 0) {
    stop("Docs directory is empty or contains no HTML files: ", docs_path,
         "\nMake sure to run generate_dashboard() with render = TRUE first")
  }

  # Set default repo name
  if (is.null(repo_name)) {
    repo_name <- basename(normalizePath(dashboard_path))
  }

  # Get username if not provided
  if (is.null(username)) {
    username <- .get_username_interactive(platform)
  }

  cat("🚀 Publishing dashboard to ", platform, " Pages...\n", sep = "")
  cat("📁 Dashboard: ", dashboard_path, "\n", sep = "")
  cat("📦 Repository: ", username, "/", repo_name, "\n", sep = "")
  cat("🌐 Platform: ", platform, "\n\n", sep = "")

  # Step 1: Check for data files and warn user
  .check_data_files(dashboard_path, include_data)

  # Step 2: Initialize git repository
  .init_git_repo(dashboard_path)

  # Step 3: Create .gitignore
  .create_gitignore(dashboard_path, include_data)

  # Step 3: Create repository on platform
  repo_url <- .create_remote_repo(dashboard_path, platform, username, repo_name, private)

  # Step 4: Configure for Pages deployment
  .configure_pages_deployment(dashboard_path, platform, branch, docs_subdir)

  # Step 5: Commit and push
  .commit_and_push(dashboard_path, commit_message, branch)

  # Step 6: Get deployment URL
  deployment_url <- .get_deployment_url(platform, username, repo_name)

  cat("\n🎉 Dashboard published successfully!\n")
  cat("══════════════════════════════════════════════════\n")
  cat("🌐 Dashboard URL: ", deployment_url, "\n", sep = "")
  cat("📝 Repository: ", repo_url, "\n", sep = "")
  cat("\n⏱️  IMPORTANT: GitHub Pages deployment takes 2-5 minutes\n")
  cat("   Your dashboard will be available at the URL above once deployed\n")
  cat("   You can check deployment status in your repository's Actions tab\n\n")

  if (open_browser) {
    cat("🌐 Opening repository in browser (not dashboard - it's still building)...\n")
    .open_url(repo_url)
  } else {
    cat("💡 Tip: Visit the repository URL to monitor deployment progress\n")
  }

  invisible(deployment_url)
}

#' Get username interactively
#' @param platform Platform name
#' @return Username as string
#' @noRd
.get_username_interactive <- function(platform) {
  cat("Please enter your ", platform, " username:\n", sep = "")
  username <- readline("Username: ")

  if (is.null(username) || nchar(trimws(username)) == 0) {
    stop("Username is required for publishing")
  }

  trimws(username)
}

#' Initialize git repository using gert
#' @param path Dashboard path
#' @noRd
.init_git_repo <- function(path) {
  cat("📝 Initializing git repository...\n")

  # Check if already a git repo
  if (dir.exists(file.path(path, ".git"))) {
    cat("   ✓ Git repository already exists\n")
    return(invisible(TRUE))
  }

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.init_git_repo_system(path))
  }

  tryCatch({
    # Initialize git repository using gert
    gert::git_init(path)

    # Set default branch to main
    gert::git_branch_create("main", path)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .init_git_repo_system(path)
  })

  invisible(TRUE)
}

#' Initialize git repository using system git (fallback)
#' @param path Dashboard path
#' @noRd
.init_git_repo_system <- function(path) {
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Initialize git repository
    system2("git", c("init"), stdout = TRUE, stderr = TRUE)

    # Set default branch to main
    system2("git", c("branch", "-M", "main"), stdout = TRUE, stderr = TRUE)

    cat("   ✓ Git repository initialized\n")
  }, error = function(e) {
    stop("Failed to initialize git repository: ", e$message)
  })

  invisible(TRUE)
}

#' Check for data files and warn user
#' @param path Dashboard path
#' @param include_data Whether to include data files
#' @noRd
.check_data_files <- function(path, include_data) {
  cat("🔍 Checking for data files...\n")

  # Define comprehensive data file patterns
  data_patterns <- c(
    # R Data Files
    "*.rds", "*.RData", "*.rda", "*.RDS", "*.RDATA", "*.RDA",
    # CSV and Delimited Files
    "*.csv", "*.tsv", "*.txt", "*.dat", "*.tab",
    # Excel Files
    "*.xlsx", "*.xls", "*.xlsm", "*.xlsb",
    # Database Files
    "*.db", "*.sqlite", "*.sqlite3", "*.mdb", "*.accdb",
    # Statistical Software Files
    "*.sav", "*.dta", "*.sas7bdat", "*.por", "*.zsav",
    # JSON and XML (but exclude config files)
    "*.json", "*.xml",
    # Archive Files
    "*.zip", "*.tar", "*.tar.gz", "*.gz", "*.bz2", "*.7z", "*.rar",
    # Large Files
    "*.parquet", "*.feather", "*.fst", "*.h5", "*.hdf5"
  )

  # Find all data files
  data_files <- character(0)
  for (pattern in data_patterns) {
    # Convert glob pattern to regex
    regex_pattern <- gsub("\\*", ".*", pattern)
    # Make sure it matches the full filename, not just part of it
    regex_pattern <- paste0("^", regex_pattern, "$")

    files <- list.files(path, pattern = regex_pattern,
                       recursive = TRUE, full.names = FALSE, ignore.case = TRUE)
    data_files <- c(data_files, files)
  }

  # Also check for data directories
  data_dirs <- c("data", "datasets", "raw_data", "processed_data", "output_data")
  for (dir in data_dirs) {
    if (dir.exists(file.path(path, dir))) {
      data_files <- c(data_files, paste0(dir, "/"))
    }
  }

  # Check for large files (>10MB) that might be data
  large_files <- .find_large_files(path, size_mb = 10)
  if (length(large_files) > 0) {
    data_files <- c(data_files, large_files)
  }

  # Remove duplicates and sort
  data_files <- unique(sort(data_files))

  # Filter out common config files and Quarto-generated files that are not data
  config_files <- c("_quarto.yml", "quarto.yml", ".gitignore", "README.md", "LICENSE",
                   "DESCRIPTION", "NAMESPACE", "Makefile", "Dockerfile", ".dockerignore",
                   "index.html", "sitemap.xml", ".nojekyll")
  data_files <- data_files[!data_files %in% config_files]

  # Also filter out docs/search.json specifically (Quarto search index)
  data_files <- data_files[!grepl("^docs/search\\.json$", data_files)]

  if (length(data_files) > 0) {
    if (!include_data) {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be EXCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   🔒 Data files are excluded by default for security and size reasons\n")
      cat("   💡 To include data files, use: include_data = TRUE\n")
      cat("   ⚠️  WARNING: Only include data if you have permission to share it publicly\n\n")
    } else {
      cat("   ⚠️  Found ", length(data_files), " data file(s) that will be INCLUDED:\n", sep = "")
      for (file in head(data_files, 10)) {  # Show first 10
        cat("      - ", file, "\n", sep = "")
      }
      if (length(data_files) > 10) {
        cat("      ... and ", length(data_files) - 10, " more\n", sep = "")
      }
      cat("\n   ⚠️  WARNING: Data files will be committed to the repository!\n")
      cat("   🔒 Make sure you have permission to share this data publicly\n")
      cat("   💡 Consider using a private repository for sensitive data\n\n")
    }
  } else {
    cat("   ✓ No data files detected\n")
  }

  invisible(data_files)
}

#' Find large files that might be data
#' @param path Directory path
#' @param size_mb Minimum size in MB
#' @noRd
.find_large_files <- function(path, size_mb = 10) {
  all_files <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  large_files <- character(0)

  for (file in all_files) {
    if (file.exists(file) && !dir.exists(file)) {
      file_size <- file.size(file) / (1024 * 1024)  # Convert to MB
      if (file_size > size_mb) {
        # Get relative path
        rel_path <- gsub(paste0("^", path, "/?"), "", file)
        large_files <- c(large_files, rel_path)
      }
    }
  }

  large_files
}

#' Create comprehensive .gitignore file
#' @param path Dashboard path
#' @param include_data Whether to include data files (default: FALSE)
#' @noRd
.create_gitignore <- function(path, include_data = FALSE) {
  gitignore_path <- file.path(path, ".gitignore")

  if (file.exists(gitignore_path)) {
    cat("   ✓ .gitignore already exists\n")
    return(invisible(TRUE))
  }

  gitignore_content <- c(
    "# R",
    ".Rproj.user",
    ".Rhistory",
    ".RData",
    ".Ruserdata",
    "*.Rproj",
    "",
    "# Quarto",
    ".quarto/",
    "",
    "# OS",
    ".DS_Store",
    "Thumbs.db",
    "",
    "# IDE",
    ".vscode/",
    ".idea/",
    "",
    "# Temporary files",
    "*.tmp",
    "*.temp",
    "*.log"
  )

  # Add comprehensive data exclusions unless explicitly included
  if (!include_data) {
    data_exclusions <- c(
      "",
      "# DATA FILES - EXCLUDED BY DEFAULT",
      "# Uncomment specific lines below if you want to include certain data types",
      "",
      "# R Data Files",
      "*.rds",
      "*.RData",
      "*.rda",
      "*.RDS",
      "*.RDATA",
      "*.RDA",
      "",
      "# CSV and Delimited Files",
      "*.csv",
      "*.tsv",
      "*.txt",
      "*.dat",
      "*.tab",
      "",
      "# Excel Files",
      "*.xlsx",
      "*.xls",
      "*.xlsm",
      "*.xlsb",
      "",
      "# Database Files",
      "*.db",
      "*.sqlite",
      "*.sqlite3",
      "*.mdb",
      "*.accdb",
      "",
      "# Statistical Software Files",
      "*.sav",
      "*.dta",
      "*.sas7bdat",
      "*.por",
      "*.zsav",
      "",
      "# JSON and XML",
      "*.json",
      "*.xml",
      "*.yaml",
      "*.yml",
      "",
      "# Archive Files",
      "*.zip",
      "*.tar",
      "*.tar.gz",
      "*.gz",
      "*.bz2",
      "*.7z",
      "*.rar",
      "",
      "# Large Files (typically data)",
      "*.parquet",
      "*.feather",
      "*.fst",
      "*.h5",
      "*.hdf5",
      "",
      "# Data Directories",
      "data/",
      "datasets/",
      "raw_data/",
      "processed_data/",
      "output_data/",
      "",
      "# Backup Files",
      "*~",
      "*.bak",
      "*.backup",
      "*.orig"
    )
    gitignore_content <- c(gitignore_content, data_exclusions)
  } else {
    # If data is included, add a warning comment
    warning_content <- c(
      "",
      "# WARNING: Data files are being included in this repository",
      "# Make sure this is intentional and that you have permission to share this data",
      "# Consider using a private repository for sensitive data"
    )
    gitignore_content <- c(gitignore_content, warning_content)
  }

  writeLines(gitignore_content, gitignore_path)
  cat("   ✓ .gitignore created\n")

  invisible(TRUE)
}

#' Create remote repository
#' @param path Dashboard path
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @param private Whether private
#' @return Repository URL
#' @noRd
.create_remote_repo <- function(path, platform, username, repo_name, private) {
  cat("📦 Creating ", platform, " repository...\n", sep = "")

  repo_url <- if (platform == "github") {
    paste0("https://github.com/", username, "/", repo_name, ".git")
  } else {
    paste0("https://gitlab.com/", username, "/", repo_name, ".git")
  }

  # Check if usethis is available
  if (!requireNamespace("usethis", quietly = TRUE)) {
    cat("   ⚠️  usethis package not available. Please install it:\n")
    cat("      install.packages('usethis')\n")
    cat("   📝 Manual steps required:\n")
    cat("      1. Create repository at: ", repo_url, "\n", sep = "")
    cat("      2. Add remote: git remote add origin ", repo_url, "\n", sep = "")
    return(repo_url)
  }

  # Try to create repository using GitHub API
  tryCatch({
    .create_github_repo_simple(path, username, repo_name, private)
    cat("   ✓ Repository created successfully\n")
  }, error = function(e) {
    cat("   ⚠️  Could not create repository automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Please create repository manually:\n")
    cat("      URL: ", repo_url, "\n", sep = "")
    cat("   💡 Quick setup options:\n")
    cat("      1. Web interface: Visit https://github.com/new\n")
    cat("         - Repository name: ", repo_name, "\n", sep = "")
    cat("         - Visibility: ", if(private) "Private" else "Public", "\n", sep = "")
    cat("         - Don't initialize with README, .gitignore, or license\n")
    cat("      2. Then run these commands in your dashboard directory:\n")
    cat("         git remote add origin ", repo_url, "\n", sep = "")
    cat("         git push -u origin main\n", sep = "")
    cat("   🔧 Alternative: Use GitHub CLI if installed:\n")
    cat("         gh repo create ", username, "/", repo_name, " --", if(private) "private" else "public", " --source=. --remote=origin --push\n", sep = "")
  })

  invisible(repo_url)
}

#' Create GitHub repository using simple API approach
#' @param path Dashboard path
#' @param username GitHub username
#' @param repo_name Repository name
#' @param private Whether repository should be private
#' @noRd
.create_github_repo_simple <- function(path, username, repo_name, private) {
  # Check if httr is available
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("httr package is required for GitHub API calls. Please install it: install.packages('httr')")
  }

  # Get GitHub token from environment or usethis
  token <- Sys.getenv("GITHUB_PAT")
  if (token == "") {
    # Try to get token from usethis
    if (requireNamespace("usethis", quietly = TRUE)) {
      tryCatch({
        token <- usethis::gh_token()
      }, error = function(e) {
        stop("No GitHub token found. Please set GITHUB_PAT environment variable or run usethis::create_github_token()")
      })
    } else {
      stop("No GitHub token found. Please set GITHUB_PAT environment variable")
    }
  }

  # GitHub API endpoint
  url <- "https://api.github.com/user/repos"

  # Repository data
  repo_data <- list(
    name = repo_name,
    description = paste("Dashboard created with dashboardr package"),
    private = private,
    auto_init = FALSE
  )

  # Make API request
  response <- httr::POST(
    url,
    httr::add_headers(
      Authorization = paste("token", token),
      "User-Agent" = "dashboardr-package"
    ),
    httr::content_type_json(),
    body = jsonlite::toJSON(repo_data, auto_unbox = TRUE)
  )

  # Check response
  if (httr::status_code(response) == 201) {
    # Repository created successfully, add remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Remote origin added/updated\n")

    return(invisible(TRUE))
  } else if (httr::status_code(response) == 422) {
    # Repository already exists - this is actually fine, just add the remote
    repo_url <- paste0("https://github.com/", username, "/", repo_name, ".git")

    # Add or update remote using gert or system git
    if (requireNamespace("gert", quietly = TRUE)) {
      tryCatch({
        # Check if remote already exists
        remotes <- gert::git_remote_list(repo = path)
        if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
          # Update existing remote
          gert::git_remote_set_url("origin", repo_url, repo = path)
        } else {
          # Add new remote
          gert::git_remote_add("origin", repo_url, repo = path)
        }
      }, error = function(e) {
        # If gert fails, try system git
        old_wd <- getwd()
        setwd(path)
        on.exit(setwd(old_wd), add = TRUE)
        # Check if remote exists and update or add
        existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
        if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
          system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        } else {
          system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
        }
      })
    } else {
      old_wd <- getwd()
      setwd(path)
      on.exit(setwd(old_wd), add = TRUE)
      # Check if remote exists and update or add
      existing_remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
      if (length(existing_remotes) > 0 && any(grepl("origin", existing_remotes))) {
        system2("git", c("remote", "set-url", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      } else {
        system2("git", c("remote", "add", "origin", repo_url), stdout = TRUE, stderr = TRUE)
      }
    }

    cat("   ✓ Repository already exists, remote origin added/updated\n")

    return(invisible(TRUE))
  } else {
    # Parse error message
    error_content <- httr::content(response, "text")
    error_msg <- "Unknown error"
    tryCatch({
      error_json <- jsonlite::fromJSON(error_content)
      if ("message" %in% names(error_json)) {
        error_msg <- error_json$message
      }
    }, error = function(e) {
      error_msg <- error_content
    })

    stop("GitHub API error (", httr::status_code(response), "): ", error_msg)
  }
}

#' Add remote if it doesn't exist
#' @param path Dashboard path
#' @param repo_url Repository URL
#' @noRd
.add_remote_if_needed <- function(path, repo_url) {
  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  tryCatch({
    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      # Add remote
      gert::git_remote_add("origin", repo_url, repo = path)
      cat("   ✓ Remote origin added\n")
    }
  }, error = function(e) {
    # Silent fail - remote might already exist or other issue
  })

  invisible(TRUE)
}

#' Configure Pages deployment
#' @param path Dashboard path
#' @param platform Platform name
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_pages_deployment <- function(path, platform, branch, docs_subdir) {
  cat("⚙️  Configuring ", platform, " Pages deployment...\n", sep = "")

  if (platform == "github") {
    .configure_github_pages(path, branch, docs_subdir)
  } else {
    .configure_gitlab_pages(path, branch, docs_subdir)
  }

  invisible(TRUE)
}

#' Configure GitHub Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_github_pages <- function(path, branch, docs_subdir) {
  # Ensure the directory exists
  if (!dir.exists(path)) {
    stop("Dashboard directory does not exist: ", path)
  }

  # Create .nojekyll file to prevent Jekyll processing
  nojekyll_path <- file.path(path, ".nojekyll")
  if (!file.exists(nojekyll_path)) {
    writeLines("", nojekyll_path)
    cat("   ✓ .nojekyll file created\n")
  }

  # Create GitHub Actions workflow for deployment
  workflow_dir <- file.path(path, ".github", "workflows")
  if (!dir.exists(workflow_dir)) {
    dir.create(workflow_dir, recursive = TRUE)
  }

  workflow_content <- c(
    "name: Deploy to GitHub Pages",
    "",
    "on:",
    "  push:",
    "    branches: [ ", branch, " ]",
    "  workflow_dispatch:",
    "",
    "permissions:",
    "  contents: read",
    "  pages: write",
    "  id-token: write",
    "",
    "concurrency:",
    "  group: \"pages\"",
    "  cancel-in-progress: false",
    "",
    "jobs:",
    "  deploy:",
    "    environment:",
    "      name: github-pages",
    "      url: ${{ steps.deployment.outputs.page_url }}",
    "    runs-on: ubuntu-latest",
    "    steps:",
    "      - name: Checkout",
    "        uses: actions/checkout@v4",
    "      - name: Setup Pages",
    "        uses: actions/configure-pages@v4",
    "      - name: Upload artifact",
    "        uses: actions/upload-pages-artifact@v3",
    "        with:",
    "          path: ", docs_subdir,
    "      - name: Deploy to GitHub Pages",
    "        id: deployment",
    "        uses: actions/deploy-pages@v4"
  )

  workflow_file <- file.path(workflow_dir, "deploy.yml")
  writeLines(workflow_content, workflow_file)
  cat("   ✓ GitHub Actions workflow created\n")
}

#' Configure GitLab Pages
#' @param path Dashboard path
#' @param branch Branch name
#' @param docs_subdir Docs subdirectory
#' @noRd
.configure_gitlab_pages <- function(path, branch, docs_subdir) {
  # Create .gitlab-ci.yml
  gitlab_ci_content <- c(
    "pages:",
    "  stage: deploy",
    "  script:",
    "    - echo 'Deploying to GitLab Pages'",
    "  artifacts:",
    "    paths:",
    "      - ", docs_subdir,
    "  only:",
    "    - ", branch
  )

  gitlab_ci_path <- file.path(path, ".gitlab-ci.yml")
  writeLines(gitlab_ci_content, gitlab_ci_path)
  cat("   ✓ .gitlab-ci.yml created\n")
}

#' Commit and push changes using gert
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push <- function(path, commit_message, branch) {
  cat("📤 Committing and pushing changes...\n")

  # Check if gert is available
  if (!requireNamespace("gert", quietly = TRUE)) {
    cat("   ⚠️  gert package not available. Please install it:\n")
    cat("      install.packages('gert')\n")
    cat("   📝 Falling back to system git...\n")
    return(.commit_and_push_system(path, commit_message, branch))
  }

  tryCatch({
    # Check if there are changes to commit
    status <- gert::git_status(path)
    if (nrow(status) == 0) {
      cat("   ℹ️  No changes to commit\n")
      # Still try to push if there are commits but no changes
      remotes <- gert::git_remote_list(repo = path)
      if (nrow(remotes) > 0 && any(remotes$name == "origin")) {
        tryCatch({
          gert::git_push(remote = "origin", repo = path)
          cat("   ✓ Pushed existing commits to remote\n")
        }, error = function(e) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e$message, "\n", sep = "")
        })
      }
      return(invisible(TRUE))
    }

    # Add all files
    gert::git_add(".", repo = path)

    # Commit changes
    gert::git_commit(commit_message, repo = path)
    cat("   ✓ Changes committed\n")

    # Check if remote exists
    remotes <- gert::git_remote_list(repo = path)
    if (nrow(remotes) == 0 || !any(remotes$name == "origin")) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      tryCatch({
        gert::git_push(remote = "origin", repo = path)
        cat("   ✓ Changes pushed to remote\n")
      }, error = function(e) {
        cat("   ⚠️  Push failed. Trying to set upstream branch...\n")
        tryCatch({
          gert::git_push(remote = "origin", refspec = paste0("refs/heads/", branch, ":refs/heads/", branch), repo = path)
          cat("   ✓ Changes pushed to remote with upstream set\n")
        }, error = function(e2) {
          cat("   ⚠️  Push failed. Please check manually:\n")
          cat("      git push -u origin ", branch, "\n", sep = "")
          cat("      Error: ", e2$message, "\n", sep = "")
        })
      })
    }

  }, error = function(e) {
    cat("   ⚠️  gert failed, falling back to system git...\n")
    .commit_and_push_system(path, commit_message, branch)
  })

  invisible(TRUE)
}

#' Commit and push changes using system git (fallback)
#' @param path Dashboard path
#' @param commit_message Commit message
#' @param branch Branch name
#' @noRd
.commit_and_push_system <- function(path, commit_message, branch) {
  # Change to dashboard directory
  old_wd <- getwd()
  setwd(path)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch({
    # Add all files
    system2("git", c("add", "."), stdout = TRUE, stderr = TRUE)

    # Check if there are changes to commit
    status_result <- system2("git", c("status", "--porcelain"), stdout = TRUE)
    if (length(status_result) == 0 || all(status_result == "")) {
      cat("   ℹ️  No changes to commit\n")
      return(invisible(TRUE))
    }

    # Commit changes
    system2("git", c("commit", "-m", shQuote(commit_message)),
            stdout = TRUE, stderr = TRUE)
    cat("   ✓ Changes committed\n")

    # Check if remote exists before pushing
    remotes <- system2("git", c("remote", "-v"), stdout = TRUE, stderr = TRUE)
    if (length(remotes) == 0 || !any(grepl("origin", remotes))) {
      cat("   ⚠️  No remote origin found. Please add remote manually:\n")
      cat("      git remote add origin <repository-url>\n")
      cat("      git push -u origin ", branch, "\n", sep = "")
    } else {
      # Push to remote
      push_result <- system2("git", c("push", "-u", "origin", branch),
                            stdout = TRUE, stderr = TRUE)
      if (length(push_result) > 0 && any(grepl("pushed|Pushed", push_result))) {
        cat("   ✓ Changes pushed to remote\n")
      } else {
        cat("   ⚠️  Push may have failed. Please check manually:\n")
        cat("      git push -u origin ", branch, "\n", sep = "")
      }
    }

  }, error = function(e) {
    cat("   ⚠️  Could not commit/push automatically:\n")
    cat("      Error: ", e$message, "\n", sep = "")
    cat("   📝 Manual steps:\n")
    cat("      git add .\n")
    cat("      git commit -m \"", commit_message, "\"\n", sep = "")
    cat("      git push -u origin ", branch, "\n", sep = "")
  })

  invisible(TRUE)
}

#' Get deployment URL
#' @param platform Platform name
#' @param username Username
#' @param repo_name Repository name
#' @return Deployment URL
#' @noRd
.get_deployment_url <- function(platform, username, repo_name) {
  if (platform == "github") {
    paste0("https://", username, ".github.io/", repo_name)
  } else {
    paste0("https://", username, ".gitlab.io/", repo_name)
  }
}

#' Open URL in browser
#' @param url URL to open
#' @noRd
.open_url <- function(url) {
  if (interactive()) {
    tryCatch({
      utils::browseURL(url)
      cat("🌐 Opening dashboard in browser...\n")
    }, error = function(e) {
      cat("⚠️  Could not open browser automatically\n")
      cat("   Please visit: ", url, "\n", sep = "")
    })
  }
}
