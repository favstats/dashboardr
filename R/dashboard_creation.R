# =================================================================
# dashboard_project
# =================================================================


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
#' @param navbar_bg_color Navbar background color (CSS color value, e.g., "#2563eb", "rgb(37, 99, 235)") (optional)
#' @param navbar_text_color Navbar text color (CSS color value, e.g., "#ffffff", "rgb(255, 255, 255)") (optional)
#' @param navbar_brand Custom brand text (optional)
#' @param navbar_toggle Mobile menu toggle behavior (optional)
#' @param max_width Maximum width for page content (e.g., "1400px", "90%") (optional)
#' @param mainfont Font family for document text. Recommended: "Fira Sans" (smooth, modern), 
#'   "Lato" (warm), "Source Sans Pro" (elegant), or "Roboto" (technical). 
#'   Default is "Fira Sans" for a smooth, professional look.
#' @param fontsize Base font size for document (default: "16px" for optimal readability)
#' @param fontcolor Default text color (e.g., "#1f2937" for readable dark gray) (optional)
#' @param linkcolor Default hyperlink color (e.g., "#2563eb" for vibrant blue) (optional)
#' @param monofont Font family for code elements. Recommended: "Fira Code" (with ligatures), 
#'   "JetBrains Mono", "Source Code Pro", or "IBM Plex Mono". Default: "Fira Code".
#' @param monobackgroundcolor Background color for code elements (e.g., "#f8fafc" for subtle gray) (optional)
#' @param linestretch Line height for text (default: 1.5) (optional)
#' @param backgroundcolor Background color for document (optional)
#' @param margin_left Left margin for document body (optional)
#' @param margin_right Right margin for document body (optional)
#' @param margin_top Top margin for document body (optional)
#' @param margin_bottom Bottom margin for document body (optional)
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
#' @param lazy_load_charts Enable lazy loading for charts (default: FALSE). When TRUE, charts only render when they scroll into view, dramatically improving initial page load time for pages with many visualizations.
#' @param lazy_load_margin Distance from viewport to start loading charts (default: "200px"). Larger values mean charts start loading earlier.
#' @param lazy_load_tabs Only render charts in the active tab (default: TRUE when lazy_load_charts is TRUE). Charts in hidden tabs load when the tab is clicked.
#' @param lazy_debug Enable debug logging to browser console for lazy loading (default: FALSE). When TRUE, prints timing information for each chart load.
#' @param pagination_separator Text to show in pagination navigation (e.g., "of" → "1 of 3"), default: "of". Applies to all paginated pages unless overridden at page level.
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
#' 
#' # Dashboard with lazy loading for better performance
#' dashboard <- create_dashboard(
#'   "fast_dashboard",
#'   "High Performance Dashboard",
#'   lazy_load_charts = TRUE,
#'   lazy_load_margin = "300px",
#'   lazy_load_tabs = TRUE
#' )
#' 
#' # Professional styling with modern fonts (Google Fonts work great!)
#' dashboard <- create_dashboard(
#'   "styled_dashboard",
#'   "Beautifully Styled Dashboard",
#'   navbar_bg_color = "#1e40af",     # Deep blue navbar
#'   mainfont = "Fira Sans",           # Smooth, modern (default choice) ⭐
#'   fontsize = "16px",
#'   fontcolor = "#1f2937",            # Dark gray for readability
#'   linkcolor = "#2563eb",            # Vibrant blue links
#'   monofont = "Fira Code",           # Code font with ligatures
#'   monobackgroundcolor = "#f8fafc",  # Light gray code background
#'   linestretch = 1.6,                # Comfortable line spacing
#'   backgroundcolor = "#ffffff"
#' )
#' 
#' # Alternative professional font combinations:
#' # Option 1: Warm & Friendly
#' dashboard <- create_dashboard(
#'   "friendly_dashboard",
#'   title = "Friendly Dashboard",
#'   mainfont = "Lato",                # Warm, approachable
#'   monofont = "JetBrains Mono"       # Excellent for code
#' )
#' 
#' # Option 2: Elegant & Refined
#' dashboard <- create_dashboard(
#'   "elegant_dashboard", 
#'   title = "Elegant Dashboard",
#'   mainfont = "Source Sans Pro",     # Elegant, highly readable
#'   monofont = "Source Code Pro"      # Matching code font
#' )
#' 
#' # Option 3: Technical Feel
#' dashboard <- create_dashboard(
#'   "tech_dashboard",
#'   title = "Tech Dashboard", 
#'   mainfont = "Roboto",              # Technical, clean
#'   monofont = "JetBrains Mono"       # Excellent for code
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
                            tabset_theme = "modern",
                            tabset_colors = NULL,
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
                            navbar_bg_color = NULL,
                            navbar_text_color = NULL,
                            navbar_brand = NULL,
                            navbar_toggle = NULL,
                            max_width = NULL,
                            mainfont = "Fira Sans",
                            fontsize = "16px",
                            fontcolor = NULL,
                            linkcolor = NULL,
                            monofont = "Fira Code",
                            monobackgroundcolor = NULL,
                            linestretch = NULL,
                            backgroundcolor = NULL,
                            margin_left = NULL,
                            margin_right = NULL,
                            margin_top = NULL,
                            margin_bottom = NULL,
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
                             navbar_sections = NULL,
                             lazy_load_charts = FALSE,
                             lazy_load_margin = "200px",
                             lazy_load_tabs = NULL,
                             lazy_debug = FALSE,
                             pagination_separator = "of") {

  output_dir <- .resolve_output_dir(output_dir, allow_inside_pkg)

  # Default lazy_load_tabs to TRUE if lazy_load_charts is enabled
  if (is.null(lazy_load_tabs)) {
    lazy_load_tabs <- lazy_load_charts
  }

  # Validate tabset_theme
  valid_themes <- c("modern", "minimal", "pills", "classic", "underline", "segmented", "none")
  if (!is.null(tabset_theme) && !tabset_theme %in% valid_themes) {
    .stop_with_suggestion("tabset_theme", tabset_theme, valid_themes)
  }

  # Validate tabset_colors if provided
  if (!is.null(tabset_colors)) {
    if (!is.list(tabset_colors)) {
      stop("tabset_colors must be a named list (e.g., list(active_bg = '#2563eb', active_text = '#fff'))")
    }
    valid_color_keys <- c("inactive_bg", "inactive_text", "active_bg", "active_text", "hover_bg", "hover_text")
    invalid_keys <- setdiff(names(tabset_colors), valid_color_keys)
    if (length(invalid_keys) > 0) {
      warning("Unknown tabset_colors keys: ", paste(invalid_keys, collapse = ", "),
              "\nValid keys: ", paste(valid_color_keys, collapse = ", "))
    }
  }

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
    tabset_theme = tabset_theme,
    tabset_colors = tabset_colors,
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
    navbar_bg_color = navbar_bg_color,
    navbar_text_color = navbar_text_color,
    navbar_brand = navbar_brand,
    navbar_toggle = navbar_toggle,
    max_width = max_width,
    mainfont = mainfont,
    fontsize = fontsize,
    fontcolor = fontcolor,
    linkcolor = linkcolor,
    monofont = monofont,
    monobackgroundcolor = monobackgroundcolor,
    linestretch = linestretch,
    backgroundcolor = backgroundcolor,
    margin_left = margin_left,
    margin_right = margin_right,
    margin_top = margin_top,
    margin_bottom = margin_bottom,
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
    lazy_load_charts = lazy_load_charts,
    lazy_load_margin = lazy_load_margin,
    lazy_load_tabs = lazy_load_tabs,
    lazy_debug = lazy_debug,
    pagination_separator = pagination_separator,
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
#' @param data Optional data frame to save for this page. Can also be a named list of data frames
#'   for using multiple datasets: `list(survey = df1, demographics = df2)`
#' @param data_path Path to existing data file (alternative to data parameter). Can also be a named
#'   list of file paths for multiple datasets
#' @param template Optional custom template file path
#' @param params Parameters for template substitution
#' @param visualizations viz_collection or list of visualization specs
#' @param text Optional markdown text content for the page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @param tabset_theme Optional tabset theme for this page (overrides dashboard-level theme)
#' @param tabset_colors Optional tabset colors for this page (overrides dashboard-level colors)
#' @param navbar_align Position of page in navbar: "left" (default) or "right"
#' @param overlay Whether to show a loading overlay on page load (default: FALSE)
#' @param overlay_theme Theme for loading overlay: "light", "glass", "dark", or "accent" (default: "light")
#' @param overlay_text Text to display in loading overlay (default: "Loading")
#' @param overlay_duration Duration in milliseconds for how long overlay stays visible (default: 2200)
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


#' Add a page to the dashboard
#'
#' Universal function for adding any type of page to the dashboard. Can create
#' landing pages, analysis pages, about pages, or any combination of text and
#' visualizations. All content is markdown-compatible.
#'
#' @param proj A dashboard_project object
#' @param name Page display name
#' @param data Optional data frame to save for this page. Can also be a named list of data frames
#'   for using multiple datasets: `list(survey = df1, demographics = df2)`
#' @param data_path Path to existing data file (alternative to data parameter). Can also be a named
#'   list of file paths for multiple datasets
#' @param template Optional custom template file path
#' @param params Parameters for template substitution
#' @param visualizations viz_collection or list of visualization specs
#' @param content Alternative to visualizations - supports content_collection or viz_collection
#' @param text Optional markdown text content for the page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @param tabset_theme Optional tabset theme for this page (overrides dashboard-level theme)
#' @param tabset_colors Optional tabset colors for this page (overrides dashboard-level colors)
#' @param navbar_align Position of page in navbar: "left" (default) or "right"
#' @param overlay Whether to show a loading overlay on page load (default: FALSE)
#' @param overlay_theme Theme for loading overlay: "light", "glass", "dark", or "accent" (default: "light")
#' @param overlay_text Text to display in loading overlay (default: "Loading")
#' @param overlay_duration Duration in milliseconds for how long overlay stays visible (default: 2200)
#' @param lazy_load_charts Override dashboard-level lazy loading setting for this page (default: NULL = inherit from dashboard)
#' @param lazy_load_margin Override viewport margin for lazy loading on this page (default: NULL = inherit from dashboard)
#' @param lazy_load_tabs Override tab-aware lazy loading for this page (default: NULL = inherit from dashboard)
#' @param lazy_debug Override debug mode for lazy loading on this page (default: NULL = inherit from dashboard)
#' @param pagination_separator Text to show in pagination navigation (e.g., "of" → "1 of 3"), default: NULL = inherit from dashboard
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
                               visualizations = NULL, content = NULL, text = NULL, icon = NULL,
                               is_landing_page = FALSE,
                               tabset_theme = NULL, tabset_colors = NULL,
                               navbar_align = c("left", "right"),
                               overlay = FALSE,
                               overlay_theme = c("light", "glass", "dark", "accent"),
                               overlay_text = "Loading",
                               overlay_duration = 2200,
                               lazy_load_charts = NULL,
                               lazy_load_margin = NULL,
                               lazy_load_tabs = NULL,
                               lazy_debug = NULL,
                               pagination_separator = NULL) {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object")
  }

  # Handle content parameter (alias for visualizations, but supports mixed content)
  # If both are provided, content takes precedence
  content_blocks <- NULL
  
  if (!is.null(content)) {
    # content can be: content_collection, viz_collection, content_block, or list of mixed content
    if (inherits(content, "content_collection")) {
      # New unified content collection system
      viz_specs <- list()
      content_list <- list()
      
      for (item in content$items) {
        if (!is.null(item$type) && (item$type == "viz" || item$type == "pagination")) {
          # This is a viz item OR pagination marker - both go to viz_specs
          viz_specs <- c(viz_specs, list(item))
        } else if (inherits(item, "content_block")) {
          # This is other content (text, image, etc)
          content_list <- c(content_list, list(item))
        }
      }
      
      # Create a viz_collection from the viz specs if we found any
      if (length(viz_specs) > 0) {
        viz_list <- create_viz()
        viz_list$items <- viz_specs
        visualizations <- viz_list
      }
      
      # Store content blocks
      if (length(content_list) > 0) {
        content_blocks <- content_list
      }
    } else if (inherits(content, "viz_collection")) {
      # Backward compatibility: treat viz_collection as visualizations
      if (is.null(visualizations)) {
        visualizations <- content
      }
    } else if (inherits(content, "content_block")) {
      # Single content block
      content_blocks <- list(content)
    } else if (is.list(content)) {
      # List of mixed content - extract viz_collections and content blocks
      viz_list <- NULL
      content_list <- list()
      
      for (item in content) {
        if (inherits(item, "content_collection")) {
          # Process content_collection - extract viz and content separately
          for (sub_item in item$items) {
            if (!is.null(sub_item$type) && (sub_item$type == "viz" || sub_item$type == "pagination")) {
              # Add viz items AND pagination markers to viz_list
              if (is.null(viz_list)) {
                viz_list <- create_viz()
                viz_list$items <- list(sub_item)
              } else {
                viz_list$items <- c(viz_list$items, list(sub_item))
              }
            } else if (inherits(sub_item, "content_block")) {
              content_list <- c(content_list, list(sub_item))
            }
          }
        } else if (inherits(item, "viz_collection")) {
          # Combine all viz_collections
          if (is.null(viz_list)) {
            viz_list <- item
          } else {
            viz_list <- combine_viz(viz_list, item)
          }
        } else if (inherits(item, "content_block")) {
          content_list <- c(content_list, list(item))
        } else {
          stop("Content items must be viz_collection, content_collection, content_block, or list of these")
        }
      }
      
      # Set visualizations if we found any
      if (!is.null(viz_list) && length(viz_list$items) > 0) {
        visualizations <- viz_list
      }
      
      # Store content blocks
      if (length(content_list) > 0) {
        content_blocks <- content_list
      }
    } else {
      stop("content must be a content_collection, viz_collection, content_block, or list of these")
    }
  }

  # Validate and match navbar alignment
  navbar_align <- match.arg(navbar_align)

  # Validate overlay parameters
  if (overlay) {
    overlay_theme <- match.arg(overlay_theme)
  }

  # Use dashboard-level tabset theme if page-level not specified
  if (is.null(tabset_theme)) {
    tabset_theme <- proj$tabset_theme
  }

  # Use dashboard-level tabset colors if page-level not specified
  if (is.null(tabset_colors)) {
    tabset_colors <- proj$tabset_colors
  }

  # Handle data storage with deduplication
  # Check if data is a named list (multiple datasets)
  # Must check all conditions explicitly to avoid issues
  is_multi_dataset <- FALSE
  if (!is.null(data)) {
    if (is.list(data)) {
      if (!is.data.frame(data)) {
        if (!is.null(names(data)) && length(names(data)) > 0) {
          is_multi_dataset <- TRUE
        }
      }
    }
  }

  if (is_multi_dataset) {
    # Multiple datasets - save each one
    if (is.null(data_path)) {
      data_path <- list()

      for (dataset_name in names(data)) {
        dataset <- data[[dataset_name]]

        # Validate that each dataset is actually a data frame
        if (!is.data.frame(dataset)) {
          stop("Dataset '", dataset_name, "' must be a data frame, got: ", class(dataset)[1])
        }

        # Check if we've already saved this exact dataset
        data_hash <- digest::digest(dataset)
        existing_data <- proj$data_files %||% list()

        dataset_path <- NULL
        for (existing_path in names(existing_data)) {
          if (existing_data[[existing_path]] == data_hash) {
            dataset_path <- existing_path
            break
          }
        }

        # If not found, create a new descriptive filename
        if (is.null(dataset_path)) {
          data_file_name <- paste0(dataset_name, "_", nrow(dataset), "obs.rds")
          dataset_path <- data_file_name

          # Track this dataset
          if (is.null(proj$data_files)) {
            proj$data_files <- list()
          }
          proj$data_files[[dataset_path]] <- data_hash
        }

        # Save the data file
        output_dir <- .resolve_output_dir(proj$output_dir, proj$allow_inside_pkg)
        if (!dir.exists(output_dir)) {
          dir.create(output_dir, recursive = TRUE)
        }
        saveRDS(dataset, file.path(output_dir, basename(dataset_path)))

        data_path[[dataset_name]] <- basename(dataset_path)
      }
    }
  } else if (!is.null(data)) {
    # Single dataset (original logic)
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
        data_name <- "dataset"
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
    if (inherits(visualizations, "viz_collection")) {
      viz_specs <- .process_visualizations(visualizations, data_path)
    }
  }

  # Create page record
  page <- list(
    name = name,
    data_path = data_path,
    is_multi_dataset = is_multi_dataset,
    template = template,
    params = params,
    visualizations = viz_specs,
    content_blocks = content_blocks,
    text = text,
    icon = icon,
    is_landing_page = is_landing_page,
    tabset_theme = tabset_theme,
    tabset_colors = tabset_colors,
    navbar_align = navbar_align,
    overlay = overlay,
    overlay_theme = if(overlay) overlay_theme else NULL,
    overlay_text = if(overlay) overlay_text else NULL,
    overlay_duration = if(overlay) overlay_duration else NULL,
    lazy_load_charts = lazy_load_charts %||% proj$lazy_load_charts,
    lazy_load_margin = lazy_load_margin %||% proj$lazy_load_margin,
    lazy_load_tabs = lazy_load_tabs %||% proj$lazy_load_tabs,
    lazy_debug = lazy_debug %||% proj$lazy_debug,
    pagination_separator = pagination_separator %||% proj$pagination_separator %||% "of"
  )

  proj$pages[[name]] <- page

  # Store landing page info if this is the landing page
  if (is_landing_page) {
    proj$landing_page <- name
  }

  proj
}

#' Add Page to Dashboard (Alias)
#'
#' Convenient alias for \code{\link{add_dashboard_page}}. Adds a new page to a dashboard project.
#'
#' @param proj Dashboard project object created by \code{\link{create_dashboard}}.
#' @param ... All arguments passed to \code{\link{add_dashboard_page}}.
#'
#' @return Modified dashboard project with the new page added.
#'
#' @seealso \code{\link{add_dashboard_page}} for full parameter documentation.
#'
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


#' Print Dashboard Project
#'
#' Displays a comprehensive summary of a dashboard project, including metadata,
#' features, pages, visualizations, and integrations.
#'
#' @param x A dashboard_project object created by \code{\link{create_dashboard}}.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Project metadata (title, author, description)
#'   \item Output directory
#'   \item Enabled features (sidebar, search, themes, Shiny, Observable)
#'   \item Integrations (GitHub, Twitter, LinkedIn, Analytics)
#'   \item Page structure with properties:
#'     \itemize{
#'       \item Landing page indicator
#'       \item Loading overlay indicator
#'       \item Right-aligned navbar indicator
#'       \item Associated datasets
#'       \item Nested visualization hierarchies
#'     }
#' }
#'
#' @export
print.dashboard_project <- function(x, ...) {
  # Helper function to print page badges
  .print_page_badges <- function(page) {
    badges <- c()
    if (!is.null(page$is_landing_page) && page$is_landing_page) badges <- c(badges, "🏠 Landing")
    if (!is.null(page$icon)) badges <- c(badges, paste0("🎯 Icon"))
    if (!is.null(page$overlay) && page$overlay) badges <- c(badges, paste0("⏳ Overlay"))
    if (!is.null(page$navbar_align) && page$navbar_align == "right") badges <- c(badges, "→ Right")
    if (!is.null(page$data_path)) {
      num_datasets <- if (is.list(page$data_path)) length(page$data_path) else 1
      badges <- c(badges, paste0("💾 ", num_datasets, " dataset", if (num_datasets > 1) "s" else ""))
    }

    if (length(badges) > 0) {
      cat(" [", paste(badges, collapse = ", "), "]", sep = "")
    }
  }

  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════════════════\n")
  cat("║ 🎨 DASHBOARD PROJECT\n")
  cat("╠══════════════════════════════════════════════════════════════════════════\n")
  cat("║ 📝 Title: ", x$title, "\n", sep = "")

  if (!is.null(x$author)) {
    cat("║ 👤 Author: ", x$author, "\n", sep = "")
  }

  if (!is.null(x$description)) {
    cat("║ 📄 Description: ", x$description, "\n", sep = "")
  }

  cat("║ 📁 Output: ", .resolve_output_dir(x$output_dir, x$allow_inside_pkg), "\n", sep = "")

  # Show key features in a compact grid
  features <- c()
  if (x$sidebar) features <- c(features, "📚 Sidebar")
  if (x$search) features <- c(features, "🔍 Search")
  if (!is.null(x$theme)) features <- c(features, paste0("🎨 Theme: ", x$theme))
  if (!is.null(x$tabset_theme)) features <- c(features, paste0("🗂️  Tabs: ", x$tabset_theme))
  if (x$shiny) features <- c(features, "⚡ Shiny")
  if (x$observable) features <- c(features, "👁️  Observable")

  if (length(features) > 0) {
    cat("║\n")
    cat("║ ⚙️  FEATURES:\n")
    for (feat in features) {
      cat("║    • ", feat, "\n", sep = "")
    }
  }

  # Show social/analytics
  links <- c()
  if (!is.null(x$github)) links <- c(links, paste0("🔗 GitHub"))
  if (!is.null(x$twitter)) links <- c(links, paste0("🐦 Twitter"))
  if (!is.null(x$linkedin)) links <- c(links, paste0("💼 LinkedIn"))
  if (!is.null(x$google_analytics)) links <- c(links, paste0("📊 Analytics"))

  if (length(links) > 0) {
    cat("║\n")
    cat("║ 🌐 INTEGRATIONS: ", paste(links, collapse = ", "), "\n", sep = "")
  }

  # Build page structure tree
  cat("║\n")
  cat("║ 📄 PAGES (", length(x$pages), "):\n", sep = "")

  if (length(x$pages) == 0) {
    cat("║    (no pages yet)\n")
  } else {
    # Check if there are navbar sections/menus with actual pages
    has_navbar_structure <- FALSE
    if (!is.null(x$navbar_sections) && length(x$navbar_sections) > 0) {
      # Check if any section has pages
      for (sec in x$navbar_sections) {
        if (!is.null(sec$type) && length(sec$type) > 0) {
          if ((sec$type == "sidebar" && length(sec$pages) > 0) ||
              (sec$type == "menu" && length(sec$menu_pages) > 0)) {
            has_navbar_structure <- TRUE
            break
          }
        }
      }
    }

    if (has_navbar_structure) {
      # Show pages organized by navbar structure
      pages_in_structure <- c()

      for (i in seq_along(x$navbar_sections)) {
        section <- x$navbar_sections[[i]]
        is_last_section <- (i == length(x$navbar_sections))

        # Skip if section type is missing
        if (is.null(section$type) || length(section$type) == 0) {
          next
        }

        if (section$type == "sidebar") {
          # Sidebar group - find the actual sidebar group by ID
          cat("║ ", if (is_last_section) "└─" else "├─", " 📚 ", section$text, " (Sidebar)\n", sep = "")
          section_prefix <- paste0("║ ", if (is_last_section) "   " else "│  ")

          # Find the sidebar group with matching ID
          sidebar_group <- NULL
          if (!is.null(x$sidebar_groups)) {
            for (sg in x$sidebar_groups) {
              if (!is.null(sg$id) && sg$id == section$sidebar) {
                sidebar_group <- sg
                break
              }
            }
          }

          # Display pages if sidebar group found
          if (!is.null(sidebar_group) && !is.null(sidebar_group$pages)) {
            for (j in seq_along(sidebar_group$pages)) {
              page_name <- sidebar_group$pages[j]
              pages_in_structure <- c(pages_in_structure, page_name)
              page <- x$pages[[page_name]]
              is_last_page <- (j == length(sidebar_group$pages))

              cat(section_prefix, if (is_last_page) "└─" else "├─", " 📄 ", page_name, sep = "")
              .print_page_badges(page)
              cat("\n")
            }
          }
        } else if (section$type == "menu") {
          # Dropdown menu
          cat("║ ", if (is_last_section) "└─" else "├─", " 📑 ", section$text, " (Menu)\n", sep = "")
          section_prefix <- paste0("║ ", if (is_last_section) "   " else "│  ")

          for (j in seq_along(section$menu_pages)) {
            page_name <- section$menu_pages[j]
            pages_in_structure <- c(pages_in_structure, page_name)
            page <- x$pages[[page_name]]
            is_last_page <- (j == length(section$menu_pages))

            cat(section_prefix, if (is_last_page) "└─" else "├─", " 📄 ", page_name, sep = "")
            .print_page_badges(page)
            cat("\n")
          }
        }
      }

      # Show any pages NOT in navbar structure
      all_page_names <- names(x$pages)
      pages_not_in_structure <- setdiff(all_page_names, pages_in_structure)

      if (length(pages_not_in_structure) > 0) {
        for (i in seq_along(pages_not_in_structure)) {
          page_name <- pages_not_in_structure[i]
          page <- x$pages[[page_name]]
          is_last <- (i == length(pages_not_in_structure)) && length(x$navbar_sections) == 0

          cat("║ ", if (is_last) "└─" else "├─", " 📄 ", page_name, sep = "")
          .print_page_badges(page)
          cat("\n")
        }
      }
    } else {
      # Flat list of pages (no navbar structure)
      page_names <- names(x$pages)

      for (i in seq_along(page_names)) {
        page_name <- page_names[i]
        page <- x$pages[[page_name]]
        is_last_page <- (i == length(page_names))

        # Page branch
        if (is_last_page) {
          cat("║ └─ 📄 ", page_name, sep = "")
          page_prefix <- "║    "
        } else {
          cat("║ ├─ 📄 ", page_name, sep = "")
          page_prefix <- "║ │  "
        }

        # Page badges
        .print_page_badges(page)
        cat("\n")

      # Show visualizations
      viz_list <- page$items %||% list()
      if (length(viz_list) > 0) {
        # Build tree for this page's visualizations
        viz_tree <- list()
        for (v in viz_list) {
          if (identical(v$type, "tabgroup")) {
            # Skip tabgroup wrappers, we'll show the actual viz hierarchy
            next
          }

          path <- if (is.null(v$tabgroup)) {
            c("(root)")
          } else if (is.character(v$tabgroup)) {
            v$tabgroup
          } else {
            c("(root)")
          }

          # Navigate to correct position
          current <- viz_tree
          for (j in seq_along(path)) {
            level_name <- path[j]
            if (is.null(current[[level_name]])) {
              current[[level_name]] <- list(.items = list(), .children = list())
            }
            if (j == length(path)) {
              current[[level_name]]$.items[[length(current[[level_name]]$.items) + 1]] <- v
            } else {
              current <- current[[level_name]]$.children
            }
          }
        }

        # Print visualization tree for this page
        .print_page_viz_tree <- function(node, prefix) {
          if (length(node) == 0) return()

          node_names <- setdiff(names(node), c(".items", ".children"))

          for (k in seq_along(node_names)) {
            name <- node_names[k]
            is_last <- (k == length(node_names))

            # Only show tabgroup folders if not root
            if (name != "(root)") {
              if (is_last) {
                cat(prefix, "└─ 📁 ", name, "\n", sep = "")
                new_prefix <- paste0(prefix, "   ")
              } else {
                cat(prefix, "├─ 📁 ", name, "\n", sep = "")
                new_prefix <- paste0(prefix, "│  ")
              }
            } else {
              new_prefix <- prefix
            }

            # Print items
            items <- node[[name]]$.items
            children <- node[[name]]$.children
            has_children <- length(children) > 0

            if (length(items) > 0) {
              for (m in seq_along(items)) {
                v <- items[[m]]
                is_last_item <- (m == length(items)) && !has_children

                type_icon <- switch(v$type,
                  "timeline" = "📈",
                  "stackedbar" = "📊",
                  "stackedbars" = "📊",
                  "heatmap" = "🗺️",
                  "histogram" = "📉",
                  "bar" = "📊",
                  "📊"
                )

                type_label <- v$type
                title_text <- if (!is.null(v$title)) paste0(": ", substr(v$title, 1, 40)) else ""
                if (!is.null(v$title) && nchar(v$title) > 40) title_text <- paste0(title_text, "...")

                if (is_last_item) {
                  cat(new_prefix, "└─ ", type_icon, " ", type_label, title_text, "\n", sep = "")
                } else {
                  cat(new_prefix, "├─ ", type_icon, " ", type_label, title_text, "\n", sep = "")
                }
              }
            }

            # Recursively print children
            if (has_children) {
              .print_page_viz_tree(children, new_prefix)
            }
          }
        }

        .print_page_viz_tree(viz_tree, page_prefix)
        }
      }
    }
  }

  cat("╚══════════════════════════════════════════════════════════════════════════\n\n")
  invisible(x)
}

#' Print Visualization Collection
#'
#' Displays a formatted summary of a visualization collection, including hierarchical
#' tabgroup structure, visualization types, titles, filters, and defaults.
#'
#' @param x A viz_collection object created by \code{\link{create_viz}}.
#' @param ... Additional arguments (currently ignored).
#'
#' @return Invisibly returns the input object \code{x}.
#'
#' @details
#' The print method displays:
#' \itemize{
#'   \item Total number of visualizations
#'   \item Default parameters (if set)
#'   \item Hierarchical tree structure showing tabgroup organization
#'   \item Visualization types with emoji indicators
#'   \item Filter status for each visualization
#' }
#'

