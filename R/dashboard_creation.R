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
#' @param tabset_theme Tabset theme: "minimal" (default), "modern", "pills", "classic",
#'   "underline", "segmented", or "none"
#' @param tabset_colors Named list of tabset colors (e.g., list(active_bg = "#2563eb"))
#' @param author Author name for the site (optional)
#' @param description Site description for SEO (optional)
#' @param page_footer Custom footer text (optional)
#' @param date Site creation/update date (optional)
#' @param sidebar Enable/disable global sidebar (default: FALSE)
#' @param sidebar_style Sidebar style (floating, docked, etc.) (optional)
#' @param sidebar_foreground Sidebar foreground (text) color (optional)
#' @param sidebar_border Whether to show sidebar border (default TRUE)
#' @param sidebar_alignment Sidebar alignment: "left" (default) or "right"
#' @param sidebar_collapse_level Heading level at which sidebar items collapse (default 2)
#' @param sidebar_pinned Whether sidebar is pinned open (default FALSE)
#' @param sidebar_tools Sidebar tools configuration (optional)
#' @param sidebar_contents Sidebar contents configuration (optional)
#' @param sidebar_background Sidebar background color (optional)
#' @param breadcrumbs Whether to show breadcrumbs navigation (default TRUE)
#' @param page_navigation Whether to show prev/next page navigation (default FALSE)
#' @param back_to_top Whether to show a back-to-top button (default FALSE)
#' @param reader_mode Whether to enable reader mode (default FALSE)
#' @param repo_url Repository URL for source code link (optional)
#' @param repo_actions Repository actions configuration (optional)
#' @param navbar_style Navbar style (default, dark, light) (optional)
#' @param navbar_bg_color Navbar background color (CSS color value, e.g., "#2563eb", "rgb(37, 99, 235)") (optional)
#' @param navbar_text_color Navbar text color (CSS color value, e.g., "#ffffff", "rgb(255, 255, 255)") (optional)
#' @param navbar_text_hover_color Navbar text color on hover (CSS color value, e.g., "#f0f0f0") (optional)
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
#' @param page_layout Quarto page layout mode. Default is "full" for better mobile responsiveness.
#'   Other options: "article" (constrained width), "custom". See Quarto docs for details.
#' @param mobile_toc Logical. If TRUE, adds a collapsible mobile-friendly TOC button
#'   that appears in the top-right corner. Useful for mobile/tablet viewing. Default: FALSE.
#' @param viewport_width Numeric or character. Controls mobile viewport behavior. Default is NULL
#'   (standard responsive behavior). Set to a number (e.g., 1200) to force desktop rendering width
#'   on mobile devices. Useful if charts look squished on mobile. Can also be a full viewport string
#'   like "width=1400, minimum-scale=0.5" for advanced control.
#' @param viewport_scale Numeric. Initial zoom scale for mobile devices (e.g., 0.3 to zoom out,
#'   1.0 for no zoom). Only used if viewport_width is set. Default: NULL (no scale specified).
#' @param viewport_user_scalable Logical. Allow users to pinch-zoom on mobile? Default: TRUE.
#'   Only relevant if viewport_width is set.
#' @param self_contained Logical. If TRUE, produces a standalone HTML file with all dependencies
#'   embedded. Makes files larger but more portable and can improve mobile rendering consistency.
#'   Default: FALSE.
#' @param code_overflow Character. Controls code block overflow behavior. Options: "wrap" (wrap long lines),
#'   "scroll" (horizontal scrollbar). Default: NULL (Quarto default). Set to "wrap" to prevent
#'   horizontal scrolling issues on mobile.
#' @param html_math_method Character. Method for rendering math equations. Options: "mathjax", "katex",
#'   "webtex", "gladtex", "mathml". Default: NULL (Quarto default).
#' @param google_analytics Google Analytics ID (optional)
#' @param plausible Plausible analytics script hash (e.g., "pa-UnPiJwxFi8TS").
#'   Find your script hash in Plausible Settings > Tracking Code (Script Installation tab).
#'   This format includes ad-blocker bypass and doesn't require specifying your domain.
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
#' @param pagination_separator Text to show in pagination navigation (e.g., "of" -> "1 of 3"), default: "of". Applies to all paginated pages unless overridden at page level.
#' @param pagination_position Default position for pagination controls: "bottom" (default, sticky at bottom), "top" (inline with page title), or "both" (top and bottom). This sets the default for all paginated pages. Individual pages can override this by passing position to add_pagination().
#' @param powered_by_dashboardr Whether to automatically add "Powered by dashboardr" branding (default: TRUE). When TRUE, adds a badge-style branding element. Can be overridden by explicitly calling add_powered_by_dashboardr() with custom options, or set to FALSE to disable entirely.
#' @param chart_export Whether to enable chart export functionality (default FALSE)
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @param contextual_viz_errors Logical. If TRUE, generated visualization chunks wrap viz calls
#'   in tryCatch and prepend contextual labels (title/type) to error messages. Default: FALSE.
#' @param url_params Logical. If TRUE, enable URL parameter support for inputs. Default: FALSE.
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
#'   page_footer = "(c) 2024 Company Name",
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
#'   mainfont = "Fira Sans",           # Smooth, modern (default choice)
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
                            tabset_theme = "minimal",
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
                            navbar_text_hover_color = NULL,
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
                            page_layout = "full",
                            mobile_toc = FALSE,
                            viewport_width = NULL,
                            viewport_scale = NULL,
                            viewport_user_scalable = TRUE,
                            self_contained = FALSE,
                            code_overflow = NULL,
                            html_math_method = NULL,
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
                            pagination_separator = "of",
                            pagination_position = "bottom",
                            powered_by_dashboardr = TRUE,
                            chart_export = FALSE,
                            backend = "highcharter",
                            contextual_viz_errors = FALSE,
                            url_params = FALSE) {

  output_dir <- .resolve_output_dir(output_dir, allow_inside_pkg)

  # Default lazy_load_tabs to TRUE if lazy_load_charts is enabled
  if (is.null(lazy_load_tabs)) {
    lazy_load_tabs <- lazy_load_charts
  }

  # Validate backend
  backend <- .normalize_backend(backend)
  valid_backends <- c("highcharter", "plotly", "echarts4r", "ggiraph")
  backend <- match.arg(backend, valid_backends)
  
  if (!is.logical(contextual_viz_errors) || length(contextual_viz_errors) != 1 || is.na(contextual_viz_errors)) {
    stop("contextual_viz_errors must be TRUE or FALSE", call. = FALSE)
  }

  # Validate tabset_theme
  valid_themes <- c("modern", "minimal", "pills", "classic", "underline", "segmented", "none")
  if (!is.null(tabset_theme) && !tabset_theme %in% valid_themes) {
    .stop_with_suggestion("tabset_theme", tabset_theme, valid_themes)
  }
  
  # Validate pagination_position
  if (!pagination_position %in% c("bottom", "top", "both")) {
    stop("pagination_position must be one of: 'bottom', 'top', 'both'", call. = FALSE)
  }

  # Validate tabset_colors if provided
  if (!is.null(tabset_colors)) {
    if (!is.list(tabset_colors)) {
      stop("tabset_colors must be a named list (e.g., list(active_bg = '#2563eb', active_text = '#fff'))", call. = FALSE)
    }
    valid_color_keys <- c("inactive_bg", "inactive_text", "active_bg", "active_text", "hover_bg", "hover_text")
    invalid_keys <- setdiff(names(tabset_colors), valid_color_keys)
    if (length(invalid_keys) > 0) {
      warning("Unknown tabset_colors keys: ", paste(invalid_keys, collapse = ", "),
              "\nValid keys: ", paste(valid_color_keys, collapse = ", "))
    }
  }

  # Warn if output directory already exists (but don't create it - that happens in generate_dashboard)
  if (dir.exists(output_dir) && warn_before_overwrite && !isTRUE(getOption("knitr.in.progress"))) {
    message(
      "Output directory already exists: ", output_dir, "\n",
      "Files may be overwritten when generate_dashboard() is called."
    )
  }

  # Return project object for piping
  # Note: Output directory is created in generate_dashboard(), not here
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
    navbar_text_hover_color = navbar_text_hover_color,
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
    mobile_toc = mobile_toc,
    viewport_width = viewport_width,
    viewport_scale = viewport_scale,
    viewport_user_scalable = viewport_user_scalable,
    self_contained = self_contained,
    code_overflow = code_overflow,
    html_math_method = html_math_method,
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
    pagination_position = pagination_position,
    powered_by_dashboardr = powered_by_dashboardr,
    chart_export = chart_export,
    backend = backend,
    contextual_viz_errors = contextual_viz_errors,
    url_params = url_params,
    pages = list(),
    data_files = NULL
  ), class = "dashboard_project")
}

#' Recursively check if any spec in a list has show_when set
#' @param specs List of visualization specs (may contain nested_children)
#' @return Logical
#' @keywords internal
.specs_contain_show_when <- function(specs) {
  if (is.null(specs) || length(specs) == 0) return(FALSE)
  for (s in specs) {
    if (!is.list(s)) next
    if (!is.null(s$show_when)) return(TRUE)
    if (!is.null(s$nested_children) && length(s$nested_children) > 0) {
      if (.specs_contain_show_when(s$nested_children)) return(TRUE)
    }
  }
  FALSE
}

#' Recursively check if any content block has show_when set
#' @param blocks List of content blocks (may contain nested content collections)
#' @return Logical
#' @keywords internal
.blocks_contain_show_when <- function(blocks) {
  if (is.null(blocks) || length(blocks) == 0) return(FALSE)
  for (b in blocks) {
    if (inherits(b, "content_block") && !is.null(b$show_when)) return(TRUE)
    if (is_content(b) && !is.null(b$items) && length(b$items) > 0) {
      if (.blocks_contain_show_when(b$items)) return(TRUE)
    }
  }
  FALSE
}

.dataset_hash_for_path <- function(existing_data, path) {
  if (is.null(path)) return(NULL)
  existing_data[[path]] %||% existing_data[[basename(path)]]
}

.queue_dataset_for_project <- function(proj, existing_data, df) {
  data_hash <- digest::digest(df)

  existing_path <- NULL
  for (p in names(existing_data)) {
    if (identical(existing_data[[p]], data_hash)) {
      existing_path <- p
      break
    }
  }

  if (is.null(existing_path)) {
    base <- "dataset"
    if (nrow(df) < 1000) {
      base <- paste0(base, "_small")
    } else if (nrow(df) > 5000) {
      base <- paste0(base, "_large")
    }
    base <- paste0(base, "_", nrow(df), "obs")
    candidate <- paste0(base, ".rds")
    counter <- 2
    while (candidate %in% names(existing_data)) {
      candidate <- paste0(base, "_", counter, ".rds")
      counter <- counter + 1
    }
    existing_path <- candidate

    existing_data[[existing_path]] <- data_hash
    if (is.null(proj$data_files)) {
      proj$data_files <- list()
    }
    proj$data_files[[existing_path]] <- data_hash
    if (is.null(proj$pending_data)) {
      proj$pending_data <- list()
    }
    proj$pending_data[[existing_path]] <- df
  }

  list(
    proj = proj,
    existing_data = existing_data,
    path = basename(existing_path),
    hash = data_hash
  )
}

.next_dataset_ref_name <- function(existing_names) {
  if (!("dataset" %in% existing_names)) return("dataset")
  idx <- 2L
  repeat {
    candidate <- paste0("dataset_", idx)
    if (!(candidate %in% existing_names)) return(candidate)
    idx <- idx + 1L
  }
}

.build_page_hash_to_ref <- function(existing_data, data_path) {
  hash_to_ref <- list()

  if (!is.null(data_path) && !is.list(data_path)) {
    page_hash <- .dataset_hash_for_path(existing_data, data_path)
    if (!is.null(page_hash)) {
      hash_to_ref[[page_hash]] <- "data"
    }
  } else if (is.list(data_path) && length(data_path) > 0) {
    for (nm in names(data_path)) {
      h <- .dataset_hash_for_path(existing_data, data_path[[nm]])
      if (!is.null(h)) {
        hash_to_ref[[h]] <- nm
      }
    }
  }

  hash_to_ref
}

.intern_inline_viz_data_node <- function(item, page_name, path_label, proj, existing_data, data_path, is_multi_dataset, hash_to_ref) {
  if (is.null(item) || !is.list(item)) {
    return(list(
      item = item,
      proj = proj,
      existing_data = existing_data,
      data_path = data_path,
      is_multi_dataset = is_multi_dataset,
      hash_to_ref = hash_to_ref
    ))
  }

  if (identical(item$type, "viz") && !is.null(item$data_serialized) && nzchar(item$data_serialized)) {
    viz_label <- item$title %||% item$viz_type %||% path_label
    viz_df <- tryCatch(
      as.data.frame(eval(parse(text = item$data_serialized), envir = baseenv())),
      error = function(e) {
        stop(
          "Failed to deserialize inline viz data in page '", page_name,
          "' (", viz_label, "): ", conditionMessage(e),
          call. = FALSE
        )
      }
    )

    viz_hash <- digest::digest(viz_df)
    dataset_ref <- hash_to_ref[[viz_hash]] %||% NULL

    if (is.null(dataset_ref)) {
      queued <- .queue_dataset_for_project(proj, existing_data, viz_df)
      proj <- queued$proj
      existing_data <- queued$existing_data

      if (is.null(data_path)) {
        data_path <- queued$path
        is_multi_dataset <- FALSE
        dataset_ref <- "data"
      } else if (!is.list(data_path)) {
        data_path <- list(data = basename(data_path))
        is_multi_dataset <- TRUE
        dataset_ref <- .next_dataset_ref_name(names(data_path))
        data_path[[dataset_ref]] <- queued$path
      } else {
        dataset_ref <- .next_dataset_ref_name(names(data_path))
        data_path[[dataset_ref]] <- queued$path
      }
      hash_to_ref[[viz_hash]] <- dataset_ref
    }

    item$data <- dataset_ref
    item$data_serialized <- NULL
    item$data_is_dataframe <- FALSE
  }

  if (!is.null(item$items) && is.list(item$items) && length(item$items) > 0) {
    for (k in seq_along(item$items)) {
      child_label <- paste0(path_label, " > item ", k)
      child_result <- .intern_inline_viz_data_node(
        item$items[[k]],
        page_name = page_name,
        path_label = child_label,
        proj = proj,
        existing_data = existing_data,
        data_path = data_path,
        is_multi_dataset = is_multi_dataset,
        hash_to_ref = hash_to_ref
      )
      item$items[[k]] <- child_result$item
      proj <- child_result$proj
      existing_data <- child_result$existing_data
      data_path <- child_result$data_path
      is_multi_dataset <- child_result$is_multi_dataset
      hash_to_ref <- child_result$hash_to_ref
    }
  }

  list(
    item = item,
    proj = proj,
    existing_data = existing_data,
    data_path = data_path,
    is_multi_dataset = is_multi_dataset,
    hash_to_ref = hash_to_ref
  )
}

.intern_inline_viz_data_for_page <- function(proj, page_name, data_path, is_multi_dataset, visualizations, content_blocks) {
  existing_data <- proj$data_files %||% list()
  hash_to_ref <- .build_page_hash_to_ref(existing_data, data_path)

  if (!is.null(visualizations) && is_content(visualizations) &&
      !is.null(visualizations$items) && length(visualizations$items) > 0) {
    for (i in seq_along(visualizations$items)) {
      result <- .intern_inline_viz_data_node(
        visualizations$items[[i]],
        page_name = page_name,
        path_label = paste0("visualizations item ", i),
        proj = proj,
        existing_data = existing_data,
        data_path = data_path,
        is_multi_dataset = is_multi_dataset,
        hash_to_ref = hash_to_ref
      )
      visualizations$items[[i]] <- result$item
      proj <- result$proj
      existing_data <- result$existing_data
      data_path <- result$data_path
      is_multi_dataset <- result$is_multi_dataset
      hash_to_ref <- result$hash_to_ref
    }
  }

  if (!is.null(content_blocks) && length(content_blocks) > 0) {
    for (i in seq_along(content_blocks)) {
      result <- .intern_inline_viz_data_node(
        content_blocks[[i]],
        page_name = page_name,
        path_label = paste0("content_blocks[[", i, "]]"),
        proj = proj,
        existing_data = existing_data,
        data_path = data_path,
        is_multi_dataset = is_multi_dataset,
        hash_to_ref = hash_to_ref
      )
      content_blocks[[i]] <- result$item
      proj <- result$proj
      existing_data <- result$existing_data
      data_path <- result$data_path
      is_multi_dataset <- result$is_multi_dataset
      hash_to_ref <- result$hash_to_ref
    }
  }

  list(
    proj = proj,
    data_path = data_path,
    is_multi_dataset = is_multi_dataset,
    visualizations = visualizations,
    content_blocks = content_blocks
  )
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
#' @param visualizations Content collection or list of visualization specs
#' @param content Alternative to visualizations - supports content collections
#' @param text Optional markdown text content for the page
#' @param icon Optional iconify icon shortcode (e.g., "ph:users-three")
#' @param is_landing_page Whether this should be the landing page (default: FALSE)
#' @param show_in_nav Whether to show this page in the navbar (default: TRUE).
#'   Set to FALSE for pageless dashboards (created with `create_page("")`).
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
#' @param pagination_separator Text to show in pagination navigation (e.g., "of" -> "1 of 3"), default: NULL = inherit from dashboard
#' @param time_var Name of the time/x-axis column in the data (e.g., "year", "decade", "date").
#'   Used by input filters when switching metrics. If NULL (default), the JavaScript will try to 
#'   auto-detect from common column names (year, decade, time, date).
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
#'
#' # Page with explicit time variable for metric switching
#' dashboard <- dashboard %>%
#'   add_page("Trends", data = trend_data, visualizations = trend_viz, time_var = "decade")
#' }
add_dashboard_page <- function(proj, name, data = NULL, data_path = NULL,
                               template = NULL, params = list(),
                               visualizations = NULL, content = NULL, text = NULL, icon = NULL,
                               is_landing_page = FALSE,
                               show_in_nav = TRUE,
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
                               pagination_separator = NULL,
                               time_var = NULL) {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object", call. = FALSE)
  }

 # If 'name' is a page_object, delegate to add_pages
  if (inherits(name, "page_object")) {
    return(add_pages(proj, name))
  }

  # Handle content and visualizations parameters - make them completely interchangeable
  # Both can accept viz_collection, content_collection, content_block, or list
  content_blocks <- NULL

  # Merge content and visualizations - if both provided, combine them
  # If one is provided, use it as the primary source
  combined_input <- NULL
  if (!is.null(content) && !is.null(visualizations)) {
    # Both provided - combine them
    combined_input <- list(visualizations, content)
  } else if (!is.null(content)) {
    combined_input <- content
  } else if (!is.null(visualizations)) {
    combined_input <- visualizations
  }

  if (!is.null(combined_input)) {
    # Process the combined input (can be content collection, content_block, or list)
    if (is_content(combined_input)) {
      # Content/viz collection - check if items have tabgroups
      has_tabgroups <- FALSE
      if (!is.null(combined_input$items) && length(combined_input$items) > 0) {
        has_tabgroups <- any(sapply(combined_input$items, function(item) {
          if (is.null(item) || !is.list(item)) return(FALSE)
          !is.null(item$tabgroup) && length(item$tabgroup) > 0
        }))
      }
      
      # Check if this is a mixed collection (from + operator) with both viz and content
      has_viz_items <- any(sapply(combined_input$items, function(item) {
        if (is.null(item) || !is.list(item)) return(FALSE)
        item_type <- item$type %||% ""
        item_type %in% c("viz", "pagination")
      }))
      has_content_items <- any(sapply(combined_input$items, function(item) {
        if (is.null(item) || !is.list(item)) return(FALSE)
        item_type <- item$type %||% ""
        !(item_type %in% c("viz", "pagination"))
      }))
      is_mixed_collection <- has_viz_items && has_content_items
      
      if (isTRUE(is_mixed_collection) || isTRUE(has_tabgroups)) {
        # Mixed collection (from + operator) OR items have tabgroups
        # Keep together to preserve order
        if (has_content_items) {
          # Mixed collection (e.g., from content + viz) - keep together to preserve order
          # Pass the whole collection to content_blocks, page_generation will handle ordering
          content_blocks <- list(combined_input)
          
          # Also extract viz items for setup chunk (filter creation)
          viz_specs <- list()
          for (item in combined_input$items) {
            if (is.null(item)) next
            item_type <- if (is.list(item) && !is.null(item$type)) as.character(item$type)[1] else NULL
            if (!is.null(item_type) && (item_type == "viz" || item_type == "pagination")) {
              viz_specs <- c(viz_specs, list(item))
            }
          }
          
          # Create viz collection for setup chunk only (not for rendering)
          if (length(viz_specs) > 0) {
            viz_list <- create_viz()
            viz_list$items <- viz_specs
            if (!is.null(combined_input$tabgroup_labels)) {
              viz_list$tabgroup_labels <- combined_input$tabgroup_labels
            }
            if (!is.null(combined_input$defaults)) {
              viz_list$defaults <- combined_input$defaults
            }
            visualizations <- viz_list
            # Mark that visualizations should NOT be rendered separately 
            # (they're embedded in content_blocks)
            visualizations$.embedded_in_content <- TRUE
          }
        } else {
          # Pure viz collection - pass to visualizations as before
          visualizations <- combined_input
        }
        
        # Propagate needs_inputs flag
        if (isTRUE(combined_input$needs_inputs)) {
          needs_inputs <- TRUE
        }
      } else {
        # No tabgroups - use legacy behavior: separate viz and content blocks
        viz_specs <- list()
        content_list <- list()

        for (item in combined_input$items) {
          if (is.null(item)) next
          
          is_coll <- is_content(item)
          is_block <- is_content_block(item)

          if (is_coll) {
            if (!is.null(item$items) && length(item$items) > 0) {
              for (sub_item in item$items) {
                if (is.null(sub_item)) next
                item_type <- if (is.list(sub_item) && !is.null(sub_item$type)) as.character(sub_item$type)[1] else NULL
                if (!is.null(item_type) && length(item_type) == 1 && (item_type == "viz" || item_type == "pagination")) {
                  viz_specs <- c(viz_specs, list(sub_item))
                } else if (is_content_block(sub_item)) {
                  content_list <- c(content_list, list(sub_item))
                }
              }
            }
          } else if (is_block) {
            content_list <- c(content_list, list(item))
          } else {
            item_type <- if (is.list(item) && !is.null(item$type)) as.character(item$type)[1] else NULL
            if (!is.null(item_type) && length(item_type) == 1 && (item_type == "viz" || item_type == "pagination")) {
              viz_specs <- c(viz_specs, list(item))
            }
          }
        }

        if (length(viz_specs) > 0) {
          viz_list <- create_viz()
          viz_list$items <- viz_specs
          if (!is.null(combined_input$tabgroup_labels)) {
            viz_list$tabgroup_labels <- combined_input$tabgroup_labels
          }
          if (!is.null(combined_input$defaults)) {
            viz_list$defaults <- combined_input$defaults
          }
          visualizations <- viz_list
        } else {
          visualizations <- NULL
        }

        if (length(content_list) > 0) {
          content_blocks <- content_list
        }
      }
    } else if (is_content_block(combined_input)) {
      # Single content block
      content_blocks <- list(combined_input)
    } else if (is.list(combined_input)) {
      # List of mixed content - extract viz_collections and content blocks
      viz_list <- NULL
      content_list <- list()
      combined_labels <- list()
      combined_defaults <- list()

      for (item in combined_input) {
        # Skip NULL items
        if (is.null(item)) next

        # Check class membership safely
        is_coll <- is_content(item)
        is_block <- is_content_block(item)

        if (is_coll) {
          # Preserve tabgroup_labels from this collection
          if (!is.null(item$tabgroup_labels)) {
            for (label_name in names(item$tabgroup_labels)) {
              combined_labels[[label_name]] <- item$tabgroup_labels[[label_name]]
            }
          }
          
          # Preserve defaults from this collection
          if (!is.null(item$defaults) && length(item$defaults) > 0) {
            for (default_name in names(item$defaults)) {
              combined_defaults[[default_name]] <- item$defaults[[default_name]]
            }
          }
          
          # Process content collection - extract viz and content separately
          if (!is.null(item$items) && length(item$items) > 0) {
            for (sub_item in item$items) {
              # Skip NULL sub_items
              if (is.null(sub_item)) next

              # Check if it's a viz or pagination item
              item_type <- if (is.list(sub_item) && !is.null(sub_item$type)) as.character(sub_item$type)[1] else NULL
              if (!is.null(item_type) && length(item_type) == 1 && (item_type == "viz" || item_type == "pagination")) {
                # Add viz items AND pagination markers to viz_list
                if (is.null(viz_list)) {
                  viz_list <- create_viz()
                  viz_list$items <- list(sub_item)
                } else {
                  viz_list$items <- c(viz_list$items, list(sub_item))
                }
              } else if (is_content_block(sub_item)) {
                content_list <- c(content_list, list(sub_item))
              }
            }
          }
        } else if (is_block) {
          content_list <- c(content_list, list(item))
        } else {
          stop("content/visualizations items must be content collection, content_block, or list of these", call. = FALSE)
        }
      }
      
      # Add collected tabgroup_labels and defaults to viz_list
      if (!is.null(viz_list)) {
        if (length(combined_labels) > 0) {
          viz_list$tabgroup_labels <- combined_labels
        }
        if (length(combined_defaults) > 0) {
          viz_list$defaults <- combined_defaults
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
      stop("content/visualizations must be a content collection, content_block, or list of these", call. = FALSE)
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

  # Fallback to collection-level data if page-level data is not provided
  # This allows create_viz(data = df) to pass data through without needing it in add_page()
  if (is.null(data) && is.null(data_path)) {
    # Check if visualizations/content collection has inline data
    if (!is.null(combined_input) && is_content(combined_input) && !is.null(combined_input$data)) {
      data <- combined_input$data
    }
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
    # Multiple datasets - defer saving to generate_dashboard
    if (is.null(data_path)) {
      data_path <- list()

      for (dataset_name in names(data)) {
        dataset <- data[[dataset_name]]

        # Validate that each dataset is actually a data frame
        if (!is.data.frame(dataset)) {
          stop("Dataset '", dataset_name, "' must be a data frame, got: ", class(dataset)[1], call. = FALSE)
        }

        # Check if we've already queued this exact dataset
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
          base_name <- paste0(dataset_name, "_", nrow(dataset), "obs")
          data_file_name <- paste0(base_name, ".rds")
          dataset_path <- data_file_name
          
          # Handle filename collisions - add counter if path already exists
          if (dataset_path %in% names(proj$data_files)) {
            counter <- 2
            while (paste0(base_name, "_", counter, ".rds") %in% names(proj$data_files)) {
              counter <- counter + 1
            }
            dataset_path <- paste0(base_name, "_", counter, ".rds")
          }

          # Track this dataset
          if (is.null(proj$data_files)) {
            proj$data_files <- list()
          }
          proj$data_files[[dataset_path]] <- data_hash
          
          # Queue data for saving during generate_dashboard
          if (is.null(proj$pending_data)) {
            proj$pending_data <- list()
          }
          proj$pending_data[[dataset_path]] <- dataset
        }

        data_path[[dataset_name]] <- basename(dataset_path)
      }
    }
  } else if (!is.null(data)) {
    # Single dataset - defer saving to generate_dashboard
    if (is.null(data_path)) {
      # Check if we've already queued this exact dataset
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
        
        # Handle filename collisions - add counter if path already exists
        if (data_path %in% names(proj$data_files)) {
          counter <- 2
          while (paste0(data_name, "_", counter, ".rds") %in% names(proj$data_files)) {
            counter <- counter + 1
          }
          data_path <- paste0(data_name, "_", counter, ".rds")
        }

        # Track this dataset
        if (is.null(proj$data_files)) {
          proj$data_files <- list()
        }
        proj$data_files[[data_path]] <- data_hash
        
        # Queue data for saving during generate_dashboard
        if (is.null(proj$pending_data)) {
          proj$pending_data <- list()
        }
        proj$pending_data[[data_path]] <- data
      }
    }
    data_path <- basename(data_path)
  }

  # Intern inline viz-level data frames into page/global dataset files so
  # generated QMD uses shared dataset objects instead of huge inline literals.
  # This runs across both top-level visualizations and visualizations embedded in
  # mixed content blocks.
  if (!is.null(visualizations) || !is.null(content_blocks)) {
    intern_result <- .intern_inline_viz_data_for_page(
      proj = proj,
      page_name = name,
      data_path = data_path,
      is_multi_dataset = is_multi_dataset,
      visualizations = visualizations,
      content_blocks = content_blocks
    )
    proj <- intern_result$proj
    data_path <- intern_result$data_path
    is_multi_dataset <- intern_result$is_multi_dataset
    visualizations <- intern_result$visualizations
    content_blocks <- intern_result$content_blocks
  }

  # Process visualization specifications
  viz_specs <- NULL
  viz_embedded_in_content <- FALSE

  if (!is.null(visualizations)) {
    # Check if visualizations are embedded in content (from + operator)
    # In that case, we still need them for setup chunk but not for separate rendering
    if (isTRUE(visualizations$.embedded_in_content)) {
      viz_embedded_in_content <- TRUE
    }
    
    if (is_content(visualizations)) {
      viz_specs <- .process_visualizations(
        visualizations,
        data_path,
        context_label = paste0("page '", name, "'")
      )
    }
  }

  # Check if modals are needed
  needs_modals <- FALSE
  if (!is.null(visualizations) && isTRUE(visualizations$needs_modals)) {
    needs_modals <- TRUE
  }
  if (!is.null(combined_input) && isTRUE(combined_input$needs_modals)) {
    needs_modals <- TRUE
  }
  # Also check original content parameter (combined_input may be a list)
  if (!is.null(content) && is_content(content) && isTRUE(content$needs_modals)) {
    needs_modals <- TRUE
  }
  
  # Check if inputs are needed
  needs_inputs <- FALSE
  if (!is.null(visualizations) && isTRUE(visualizations$needs_inputs)) {
    needs_inputs <- TRUE
  }
  if (!is.null(combined_input) && isTRUE(combined_input$needs_inputs)) {
    needs_inputs <- TRUE
  }
  # Also check original content parameter (combined_input may be a list)
  if (!is.null(content) && is_content(content) && isTRUE(content$needs_inputs)) {
    needs_inputs <- TRUE
  }
  # Check sidebar for inputs
  if (!is.null(combined_input) && is_content(combined_input) && 
      !is.null(combined_input$sidebar) && isTRUE(combined_input$sidebar$needs_inputs)) {
    needs_inputs <- TRUE
  }
  if (!is.null(content) && is_content(content) && 
      !is.null(content$sidebar) && isTRUE(content$sidebar$needs_inputs)) {
    needs_inputs <- TRUE
  }
  
  # Check if metric data embedding is needed (for filter_var = "metric" inputs)
  needs_metric_data <- FALSE
  if (!is.null(combined_input) && isTRUE(combined_input$needs_metric_data)) {
    needs_metric_data <- TRUE
  }
  if (!is.null(content) && is_content(content) && isTRUE(content$needs_metric_data)) {
    needs_metric_data <- TRUE
  }
  # Check sidebar for needs_metric_data
  if (!is.null(combined_input) && is_content(combined_input) && 
      !is.null(combined_input$sidebar) && isTRUE(combined_input$sidebar$needs_metric_data)) {
    needs_metric_data <- TRUE
  }
  if (!is.null(content) && is_content(content) && 
      !is.null(content$sidebar) && isTRUE(content$sidebar$needs_metric_data)) {
    needs_metric_data <- TRUE
  }

  # Check if linked (cascading) inputs are used in sidebar
  needs_linked_inputs <- FALSE
  if (!is.null(combined_input) && is_content(combined_input) && 
      !is.null(combined_input$sidebar) && isTRUE(combined_input$sidebar$needs_linked_inputs)) {
    needs_linked_inputs <- TRUE
  }
  if (!is.null(content) && is_content(content) && 
      !is.null(content$sidebar) && isTRUE(content$sidebar$needs_linked_inputs)) {
    needs_linked_inputs <- TRUE
  }
  
  # Extract tabgroup_labels from visualizations or combined_input
  page_tabgroup_labels <- NULL
  if (!is.null(visualizations) && !is.null(visualizations$tabgroup_labels)) {
    page_tabgroup_labels <- visualizations$tabgroup_labels
  } else if (!is.null(combined_input) && !is.null(combined_input$tabgroup_labels)) {
    page_tabgroup_labels <- combined_input$tabgroup_labels
  } else if (!is.null(content) && is_content(content) && !is.null(content$tabgroup_labels)) {
    page_tabgroup_labels <- content$tabgroup_labels
  }
  
  # Extract sidebar from content collections
  page_sidebar <- NULL
  if (!is.null(combined_input) && is_content(combined_input) && !is.null(combined_input$sidebar)) {
    page_sidebar <- combined_input$sidebar
  } else if (!is.null(content) && is_content(content) && !is.null(content$sidebar)) {
    page_sidebar <- content$sidebar
  } else if (!is.null(content_blocks) && length(content_blocks) > 0) {
    # Check content_blocks for sidebars
    for (block in content_blocks) {
      if (is_content(block) && !is.null(block$sidebar)) {
        page_sidebar <- block$sidebar
        break
      }
    }
  }
  if (!is.null(page_sidebar) && isTRUE(page_sidebar$needs_linked_inputs)) {
    needs_linked_inputs <- TRUE
  }

  # Check if any visualization or content block uses show_when (conditional visibility)
  needs_show_when <- FALSE
  if (!is.null(viz_specs) && length(viz_specs) > 0) {
    needs_show_when <- .specs_contain_show_when(viz_specs)
  }
  if (!needs_show_when) {
    if (!is.null(content_blocks) && length(content_blocks) > 0) {
      needs_show_when <- .blocks_contain_show_when(content_blocks)
    }
  }
  if (!needs_show_when && !is.null(content) && is_content(content)) {
    needs_show_when <- .blocks_contain_show_when(content$items)
  }
  if (!needs_show_when && !is.null(combined_input) && is_content(combined_input)) {
    needs_show_when <- .blocks_contain_show_when(combined_input$items)
  }

  # Create page record
  page <- list(
    name = name,
    data_path = data_path,
    is_multi_dataset = is_multi_dataset,
    template = template,
    params = params,
    visualizations = viz_specs,
    viz_embedded_in_content = viz_embedded_in_content,
    content_blocks = content_blocks,
    sidebar = page_sidebar,
    needs_modals = needs_modals,
    needs_inputs = needs_inputs,
    needs_metric_data = needs_metric_data,
    needs_linked_inputs = needs_linked_inputs,
    needs_show_when = needs_show_when,
    time_var = time_var,
    text = text,
    icon = icon,
    is_landing_page = is_landing_page,
    show_in_nav = show_in_nav,
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
    pagination_separator = pagination_separator %||% proj$pagination_separator %||% "of",
    chart_export = proj$chart_export %||% FALSE,
    backend = proj$backend %||% "highcharter",
    contextual_viz_errors = proj$contextual_viz_errors %||% FALSE,
    url_params = proj$url_params %||% FALSE,
    tabgroup_labels = page_tabgroup_labels
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
#' @inheritParams add_dashboard_page
#'
#' @return Modified dashboard project with the new page added.
#'
#' @seealso \code{\link{add_dashboard_page}} for full parameter documentation.
#'
#' @export
add_page <- add_dashboard_page


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
  # Helper to safely print UTF-8 text
  .cat_utf8 <- function(..., sep = "") {
    text <- paste(..., sep = sep)
    text <- enc2utf8(text)
    cat(text, sep = "")
  }
  
  # Helper function to print page badges
  .print_page_badges <- function(page) {
    badges <- c()
    if (!is.null(page$is_landing_page) && page$is_landing_page) badges <- c(badges, "\U0001F3E0 Landing")
    if (!is.null(page$icon)) badges <- c(badges, "\U0001F3F7\uFE0F Icon")
    if (!is.null(page$overlay) && page$overlay) badges <- c(badges, "\U0001F504 Overlay")
    if (!is.null(page$navbar_align) && page$navbar_align == "right") badges <- c(badges, "\u27A1\uFE0F Right")
    if (!is.null(page$data_path)) {
      num_datasets <- if (is.list(page$data_path)) length(page$data_path) else 1
      badges <- c(badges, paste0("\U0001F4BE ", num_datasets, " dataset", if (num_datasets > 1) "s" else ""))
    }

    if (length(badges) > 0) {
      .cat_utf8(" [", paste(badges, collapse = ", "), "]")
    }
  }

  .cat_utf8("\n")
  .cat_utf8("\U0001F4CA DASHBOARD PROJECT ", strrep("=", 52), "\n")
  .cat_utf8("\u2502 \U0001F3F7\uFE0F  Title: ", x$title, "\n")

  if (!is.null(x$author)) {
    .cat_utf8("\u2502 \U0001F464 Author: ", x$author, "\n")
  }

  if (!is.null(x$description)) {
    .cat_utf8("\u2502 \U0001F4DD Description: ", x$description, "\n")
  }

  .cat_utf8("\u2502 \U0001F4C1 Output: ", .resolve_output_dir(x$output_dir, x$allow_inside_pkg), "\n")

  # Show key features in a compact grid
  features <- c()
  if (x$sidebar) features <- c(features, "\U0001F5C2\uFE0F Sidebar")
  if (x$search) features <- c(features, "\U0001F50D Search")
  if (!is.null(x$theme)) features <- c(features, paste0("\U0001F3A8 Theme: ", x$theme))
  if (!is.null(x$tabset_theme)) features <- c(features, paste0("\U0001F4D1 Tabs: ", x$tabset_theme))
  if (x$shiny) features <- c(features, "\u2728 Shiny")
  if (x$observable) features <- c(features, "\U0001F441\uFE0F Observable")

  if (length(features) > 0) {
    .cat_utf8("\u2502\n")
    .cat_utf8("\u2502 \u2699\uFE0F  FEATURES:\n")
    for (feat in features) {
      .cat_utf8("\u2502    \u2022 ", feat, "\n")
    }
  }

  # Show social/analytics
  links <- c()
  if (!is.null(x$github)) links <- c(links, "\U0001F4BB GitHub")
  if (!is.null(x$twitter)) links <- c(links, "\U0001F426 Twitter")
  if (!is.null(x$linkedin)) links <- c(links, "\U0001F4BC LinkedIn")
  if (!is.null(x$google_analytics)) links <- c(links, "\U0001F4CA Analytics")

  if (length(links) > 0) {
    .cat_utf8("\u2502\n")
    .cat_utf8("\u2502 \U0001F517 INTEGRATIONS: ", paste(links, collapse = ", "), "\n")
  }

  # Build page structure tree
  .cat_utf8("\u2502\n")
  .cat_utf8("\u2502 \U0001F4C4 PAGES (", length(x$pages), "):\n")

  if (length(x$pages) == 0) {
    .cat_utf8("\u2502    (no pages yet)\n")
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
          .cat_utf8("\u2502 ", if (is_last_section) "\u2514\u2500" else "\u251C\u2500", " \U0001F5C2\uFE0F ", section$text, " (Sidebar)\n")
          section_prefix <- paste0("\u2502 ", if (is_last_section) "   " else "\u2502  ")

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

              .cat_utf8(section_prefix, if (is_last_page) "\u2514\u2500" else "\u251C\u2500", " \U0001F4C4 ", page_name)
              .print_page_badges(page)
              .cat_utf8("\n")
            }
          }
        } else if (section$type == "menu") {
          # Dropdown menu
          .cat_utf8("\u2502 ", if (is_last_section) "\u2514\u2500" else "\u251C\u2500", " \U0001F4C2 ", section$text, " (Menu)\n")
          section_prefix <- paste0("\u2502 ", if (is_last_section) "   " else "\u2502  ")

          for (j in seq_along(section$menu_pages)) {
            page_name <- section$menu_pages[j]
            pages_in_structure <- c(pages_in_structure, page_name)
            page <- x$pages[[page_name]]
            is_last_page <- (j == length(section$menu_pages))

            .cat_utf8(section_prefix, if (is_last_page) "\u2514\u2500" else "\u251C\u2500", " \U0001F4C4 ", page_name)
            .print_page_badges(page)
            .cat_utf8("\n")
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

          .cat_utf8("\u2502 ", if (is_last) "\u2514\u2500" else "\u251C\u2500", " \U0001F4C4 ", page_name)
          .print_page_badges(page)
          .cat_utf8("\n")
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
          .cat_utf8("\u2502 \u2514\u2500 \U0001F4C4 ", page_name)
          page_prefix <- "\u2502    "
        } else {
          .cat_utf8("\u2502 \u251C\u2500 \U0001F4C4 ", page_name)
          page_prefix <- "\u2502 \u2502  "
        }

        # Page badges
        .print_page_badges(page)
        .cat_utf8("\n")

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
                .cat_utf8(prefix, "\u2514\u2500 \U0001F4C1 ", name, "\n")
                new_prefix <- paste0(prefix, "   ")
              } else {
                .cat_utf8(prefix, "\u251C\u2500 \U0001F4C1 ", name, "\n")
                new_prefix <- paste0(prefix, "\u2502  ")
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

                type_label <- v$type %||% "viz"
                title_text <- if (!is.null(v$title)) paste0(": ", substr(v$title, 1, 40)) else ""
                if (!is.null(v$title) && nchar(v$title) > 40) title_text <- paste0(title_text, "...")

                if (is_last_item) {
                  .cat_utf8(new_prefix, "\u2514\u2500 \U0001F4CA [", type_label, "]", title_text, "\n")
                } else {
                  .cat_utf8(new_prefix, "\u251C\u2500 \U0001F4CA [", type_label, "]", title_text, "\n")
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

  .cat_utf8("\u2550\u2550 ", strrep("\u2550", 73), "\n\n")
  invisible(x)
}
