# ===================================================================
# Theme Validation Helpers
# ===================================================================

#' Validate a CSS color value
#' @noRd
.validate_color <- function(value, param_name) {
  if (is.null(value)) return(invisible(NULL))
  
  if (!is.character(value) || length(value) != 1) {
    stop(sprintf(
      "Theme error: '%s' must be a single character string, got %s.\n  Example: %s = \"#CB0D0D\" or %s = \"red\"",
      param_name, class(value)[1], param_name, param_name
    ), call. = FALSE)
  }
  
  # Valid patterns: hex (#RGB, #RRGGBB, #RRGGBBAA), rgb(), rgba(), hsl(), hsla(), named colors
  valid_patterns <- c(
    "^#[0-9A-Fa-f]{3}$",           # #RGB
    "^#[0-9A-Fa-f]{6}$",           # #RRGGBB
    "^#[0-9A-Fa-f]{8}$",           # #RRGGBBAA
    "^rgb\\s*\\(",                  # rgb(...)
    "^rgba\\s*\\(",                 # rgba(...)
    "^hsl\\s*\\(",                  # hsl(...)
    "^hsla\\s*\\(",                 # hsla(...)
    "^var\\s*\\("                   # var(--custom-prop)
  )
  
  # Common named colors (subset for validation)
  named_colors <- c(
    "transparent", "inherit", "currentColor",
    "black", "white", "red", "green", "blue", "yellow", "orange", "purple",
    "pink", "gray", "grey", "brown", "cyan", "magenta", "lime", "navy",
    "teal", "maroon", "olive", "silver", "aqua", "fuchsia"
  )
  
  is_valid <- any(sapply(valid_patterns, function(p) grepl(p, value, ignore.case = TRUE))) ||
              tolower(value) %in% named_colors
  
  if (!is_valid) {
    stop(sprintf(
      "Theme error: '%s' has invalid color value: \"%s\"\n  Valid formats: hex (#RRGGBB), rgb(), rgba(), or named color (e.g., \"red\")\n  Example: %s = \"#CB0D0D\"",
      param_name, value, param_name
    ), call. = FALSE)
  }
  
  invisible(NULL)
}

#' Validate a CSS size value (must have units)
#' @noRd
.validate_size <- function(value, param_name) {
  if (is.null(value)) return(invisible(NULL))
  
  if (!is.character(value) || length(value) != 1) {
    stop(sprintf(
      "Theme error: '%s' must be a character string with units, got %s.\n  Example: %s = \"16px\" or %s = \"1.2rem\"",
      param_name, class(value)[1], param_name, param_name
    ), call. = FALSE)
  }
  
  # Valid CSS units
  valid_pattern <- "^[0-9]+(\\.[0-9]+)?(px|em|rem|%|vh|vw|pt|cm|mm|in|ex|ch|vmin|vmax)$"
  
  if (!grepl(valid_pattern, value, ignore.case = TRUE)) {
    stop(sprintf(
      "Theme error: '%s' has invalid size value: \"%s\"\n  Size values must include units (px, em, rem, %%, vh, etc.)\n  Example: %s = \"16px\" or %s = \"1.5rem\"",
      param_name, value, param_name, param_name
    ), call. = FALSE)
  }
  
  invisible(NULL)
}

#' Validate a numeric value
#' @noRd
.validate_numeric <- function(value, param_name) {
  if (is.null(value)) return(invisible(NULL))
  
  if (!is.numeric(value) || length(value) != 1) {
    stop(sprintf(
      "Theme error: '%s' must be a single number, got %s.\n  Example: %s = 1.6",
      param_name, class(value)[1], param_name
    ), call. = FALSE)
  }
  
  invisible(NULL)
}

#' Validate a font name
#' @noRd
.validate_font <- function(value, param_name) {
  if (is.null(value)) return(invisible(NULL))
  
  if (!is.character(value) || length(value) != 1) {
    stop(sprintf(
      "Theme error: '%s' must be a character string, got %s.\n  Example: %s = \"Fira Sans\"",
      param_name, class(value)[1], param_name
    ), call. = FALSE)
  }
  
  # Check for obviously invalid characters that would break SCSS
  if (grepl("[{};<>]", value)) {
    stop(sprintf(
      "Theme error: '%s' contains invalid characters: \"%s\"\n  Font names should not contain {, }, ;, <, or >\n  Example: %s = \"Fira Sans\"",
      param_name, value, param_name
    ), call. = FALSE)
  }
  
  invisible(NULL)
}

#' Validate all theme parameters
#' @noRd
.validate_theme <- function(theme) {
  # Color parameters
  color_params <- c("navbar_bg_color", "navbar_text_color", "navbar_text_hover_color",
                    "linkcolor", "fontcolor", "backgroundcolor", "monobackgroundcolor")
  for (param in color_params) {
    if (!is.null(theme[[param]])) {
      .validate_color(theme[[param]], param)
    }
  }
  

  # Size parameters (must have units)
  size_params <- c("fontsize", "max_width", "margin_left", "margin_right", 
                   "margin_top", "margin_bottom")
  for (param in size_params) {
    if (!is.null(theme[[param]])) {
      .validate_size(theme[[param]], param)
    }
  }
  
  # Numeric parameters
  if (!is.null(theme$linestretch)) {
    .validate_numeric(theme$linestretch, "linestretch")
  }
  
  # Font parameters
  font_params <- c("mainfont", "monofont")
  for (param in font_params) {
    if (!is.null(theme[[param]])) {
      .validate_font(theme[[param]], param)
    }
  }
  
  invisible(NULL)
}


# ===================================================================
# Theme Application
# ===================================================================

#' Apply Theme to Dashboard
#'
#' Applies a theme to an existing dashboard_project object or returns theme parameters
#' for use in `create_dashboard()`. Supports piping for easy theme application.
#' You can override any theme parameter by passing it as an additional argument.
#'
#' @param proj Optional. A dashboard_project object to apply the theme to. 
#'   If NULL, returns the theme parameters as a list.
#' @param theme A theme list (e.g., from `theme_ascor()`, `theme_academic()`, etc.)
#' @param ... Additional parameters to override theme defaults. Can include any of:
#'   `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`, `mainfont`, `fontsize`, `fontcolor`, `linkcolor`, `monofont`, 
#'   `monobackgroundcolor`, `linestretch`, `backgroundcolor`, `max_width`, 
#'   `margin_left`, `margin_right`, `margin_top`, `margin_bottom`
#'
#' @return If proj is provided, returns the modified dashboard_project object.
#'   If proj is NULL, returns the theme list.
#' @export
#'
#' @examples
#' \dontrun{
#' # Method 1: Pipe theme directly into dashboard (EASIEST!)
#' dashboard <- create_dashboard("my_dashboard", "My Research") %>%
#'   apply_theme(theme_ascor()) %>%
#'   add_page("Home", text = "# Welcome", is_landing_page = TRUE)
#'
#' # Method 2: Override specific theme parameters
#' dashboard <- create_dashboard("tech_dash", "Tech Dashboard") %>%
#'   apply_theme(theme_modern("purple"), mainfont = "Roboto", fontsize = "18px") %>%
#'   add_page("Data", visualizations = my_viz)
#'
#' # Method 3: Get theme parameters only
#' ascor_params <- apply_theme(theme = theme_ascor())
#' 
#' # Method 4: Customize multiple parameters
#' dashboard <- create_dashboard("custom", "Custom Dashboard") %>%
#'   apply_theme(
#'     theme_clean(),
#'     mainfont = "Inter",
#'     fontsize = "18px",
#'     linkcolor = "#8B0000",
#'     max_width = "1400px"
#'   )
#' }
apply_theme <- function(proj = NULL, theme, ...) {
  # Get any override parameters
  overrides <- list(...)
  
  # Apply overrides to theme
  if (length(overrides) > 0) {
    for (param_name in names(overrides)) {
      theme[[param_name]] <- overrides[[param_name]]
    }
  }
  
  # Validate all theme parameters BEFORE applying

  # This prevents invalid values from corrupting Quarto's SASS cache
  .validate_theme(theme)
  
  if (is.null(proj)) {
    # Just return the theme (with overrides applied)
    return(theme)
  }
  
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object from create_dashboard()")
  }
  
  # Apply theme parameters to the dashboard object
  for (param_name in names(theme)) {
    proj[[param_name]] <- theme[[param_name]]
  }
  
  proj
}


#' Apply ASCoR/UvA Theme to Dashboard
#'
#' Returns a list of styling parameters that apply University of Amsterdam 
#' and ASCoR (Amsterdam School of Communication Research) branding to a dashboard.
#' Can be used with `apply_theme()` for piping or unpacked into `create_dashboard()`.
#' All parameters can be overridden to customize the theme.
#'
#' @param navbar_style Style of the navbar. Options: "dark" (default), "light". 
#'   Dark style works best with UvA red.
#' @param ... Additional theme parameters to override defaults. Can include any styling parameter
#'   like `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.
#'
#' @return A named list of theme parameters that can be unpacked into `create_dashboard()`
#' @export
#'
#' @details
#' The ASCoR theme includes:
#' \itemize{
#'   \item UvA red (#CB0D0D) as primary brand color
#'   \item Professional Fira Sans font for body text
#'   \item Fira Code for code blocks
#'   \item Optimal readability settings
#'   \item Clean, academic styling
#' }
#'
#' @examples
#' \dontrun{
#' # Method 1: Use default ASCoR theme
#' dashboard <- create_dashboard("my_dashboard", "My Research Dashboard") %>%
#'   apply_theme(theme_ascor()) %>%
#'   add_page("Home", text = "# Welcome", is_landing_page = TRUE)
#' 
#' # Method 2: Override specific parameters
#' dashboard <- create_dashboard("custom", "Custom ASCoR Dashboard") %>%
#'   apply_theme(theme_ascor(
#'     fontsize = "18px",
#'     max_width = "1400px",
#'     mainfont = "Inter"
#'   ))
#' }
theme_ascor <- function(navbar_style = "dark", ...) {
  # Default ASCoR/UvA theme settings
  defaults <- list(
    # Colors
    navbar_bg_color = "#CB0D0D",          # UvA red
    navbar_text_color = "#ffffff",         # White text
    navbar_text_hover_color = "#f0f0f0",  # Light gray on hover
    linkcolor = "#CB0D0D",                 # UvA red for links
    backgroundcolor = "#ffffff",           # White background
    
    # Typography
    mainfont = "Fira Sans",                # Smooth, modern, professional
    fontsize = "16px",                     # Optimal readability
    fontcolor = "#2c2c2c",                 # Dark gray for text
    monofont = "Fira Code",                # Code font with ligatures
    monobackgroundcolor = "#f8f8f8",       # Light gray for code blocks
    linestretch = 1.6,                     # Comfortable line spacing
    
    # Layout
    max_width = "1200px",                  # Maximum content width
    margin_left = "2rem",
    margin_right = "2rem",
    margin_top = "1rem",
    margin_bottom = "1rem",
    
    # Navbar styling
    navbar_style = navbar_style,
    navbar_brand = "ASCoR"
  )
  
  # Merge with any custom overrides from ...
  overrides <- list(...)
  modifyList(defaults, overrides)
}


#' Apply UvA Theme to Dashboard (Alias)
#'
#' Alias for `theme_ascor()`. Returns University of Amsterdam branding parameters.
#'
#' @inheritParams theme_ascor
#' @return A named list of theme parameters
#' @export
#'
#' @examples
#' \dontrun{
#' # Pipe UvA theme into dashboard
#' dashboard <- create_dashboard("uva_dashboard", "UvA Research Dashboard") %>%
#'   apply_theme(theme_uva()) %>%
#'   add_page("Home", text = "# Welcome")
#' }
theme_uva <- function(navbar_style = "dark") {
  theme_ascor(navbar_style = navbar_style)
}


#' Apply a Professional Academic Theme to Dashboard
#'
#' Returns a clean, professional theme suitable for academic and research dashboards.
#' Uses neutral colors and excellent typography for maximum readability.
#' All parameters can be overridden to customize the theme.
#'
#' @param accent_color Primary accent color (hex code). Default: "#2563eb" (blue)
#' @param navbar_style Style of the navbar. Options: "dark" (default), "light"
#' @param ... Additional theme parameters to override defaults. Can include any styling parameter
#'   like `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.
#'
#' @return A named list of theme parameters that can be unpacked into `create_dashboard()`
#' @export
#'
#' @details
#' The academic theme provides:
#' \itemize{
#'   \item Clean, neutral color scheme
#'   \item Professional typography (Fira Sans + Source Code Pro)
#'   \item High readability settings
#'   \item Suitable for any academic institution
#' }
#'
#' @examples
#' \dontrun{
#' # Use default academic theme
#' dashboard <- create_dashboard("academic_dashboard", "Research Dashboard") %>%
#'   apply_theme(theme_academic()) %>%
#'   add_page("Home", text = "# Welcome")
#' 
#' # Custom accent color and font
#' dashboard <- create_dashboard("my_university", "University Research") %>%
#'   apply_theme(theme_academic(
#'     accent_color = "#8B0000",
#'     mainfont = "Roboto",
#'     fontsize = "17px"
#'   ))
#' }
theme_academic <- function(accent_color = "#2563eb", navbar_style = "dark", ...) {
  # Default academic theme settings
  defaults <- list(
    # Colors
    navbar_bg_color = accent_color,
    navbar_text_color = "#ffffff",
    navbar_text_hover_color = "#f0f0f0",
    linkcolor = accent_color,
    backgroundcolor = "#ffffff",
    
    # Typography
    mainfont = "Fira Sans",
    fontsize = "16px",
    fontcolor = "#1f2937",                 # Professional dark gray
    monofont = "Source Code Pro",
    monobackgroundcolor = "#f8fafc",       # Very light gray
    linestretch = 1.6,
    
    # Layout
    max_width = "1200px",
    margin_left = "2rem",
    margin_right = "2rem",
    margin_top = "1rem",
    margin_bottom = "1rem",
    
    # Navbar
    navbar_style = navbar_style
  )
  
  # Merge with any custom overrides from ...
  overrides <- list(...)
  modifyList(defaults, overrides)
}


#' Apply a Modern Tech Theme to Dashboard
#'
#' Returns a sleek, modern theme suitable for tech companies and data science teams.
#' Features bold colors and contemporary typography. All parameters can be overridden.
#'
#' @param style Style variant. Options: "blue" (default), "purple", "green", "orange", "white"
#' @param ... Additional theme parameters to override defaults. Can include any styling parameter
#'   like `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.
#'
#' @return A named list of theme parameters
#' @export
#'
#' @examples
#' \dontrun{
#' # Use default modern blue theme
#' dashboard <- create_dashboard("tech_dashboard", "Data Science Dashboard") %>%
#'   apply_theme(theme_modern()) %>%
#'   add_page("Analytics", visualizations = my_viz)
#' 
#' # Purple variant with custom font
#' dashboard <- create_dashboard("purple_dashboard", "Analytics Dashboard") %>%
#'   apply_theme(theme_modern(style = "purple", mainfont = "Inter", fontsize = "18px")) %>%
#'   add_page("Data", data = my_data)
#' 
#' # White navbar
#' dashboard <- create_dashboard("clean_dashboard", "Clean Dashboard") %>%
#'   apply_theme(theme_modern(style = "white")) %>%
#'   add_page("Home", text = "# Welcome")
#' }
theme_modern <- function(style = c("blue", "purple", "green", "orange", "white"), ...) {
  style <- match.arg(style)
  
  # Define style-specific defaults
  style_defaults <- list(
    blue = list(
      navbar = "#1e40af", link = "#2563eb", navbar_style = "dark",
      navbar_text = "#ffffff", navbar_text_hover = "#e0e0e0"
    ),
    purple = list(
      navbar = "#7c3aed", link = "#8b5cf6", navbar_style = "dark",
      navbar_text = "#ffffff", navbar_text_hover = "#e0e0e0"
    ),
    green = list(
      navbar = "#059669", link = "#10b981", navbar_style = "dark",
      navbar_text = "#ffffff", navbar_text_hover = "#e0e0e0"
    ),
    orange = list(
      navbar = "#ea580c", link = "#f97316", navbar_style = "dark",
      navbar_text = "#ffffff", navbar_text_hover = "#e0e0e0"
    ),
    white = list(
      navbar = "#ffffff", link = "#2563eb", navbar_style = "light",
      navbar_text = "#1f2937", navbar_text_hover = "#374151"
    )
  )
  
  selected_defaults <- style_defaults[[style]]
  
  # Default modern theme settings
  defaults <- list(
    # Colors
    navbar_bg_color = selected_defaults$navbar,
    navbar_text_color = selected_defaults$navbar_text,
    navbar_text_hover_color = selected_defaults$navbar_text_hover,
    linkcolor = selected_defaults$link,
    backgroundcolor = "#ffffff",
    
    # Typography - tech feel
    mainfont = "Roboto",
    fontsize = "16px",
    fontcolor = "#1f2937",
    monofont = "JetBrains Mono",
    monobackgroundcolor = "#f1f5f9",
    linestretch = 1.5,
    
    # Layout
    max_width = "1400px",                  # Wider for data dashboards
    margin_left = "2rem",
    margin_right = "2rem",
    margin_top = "1rem",
    margin_bottom = "1rem",
    
    # Navbar
    navbar_style = selected_defaults$navbar_style
  )
  
  # Merge with any custom overrides from ...
  overrides <- list(...)
  modifyList(defaults, overrides)
}


#' Apply a Clean Theme to Dashboard
#'
#' Returns an ultra-clean, minimalist theme with maximum focus on content.
#' Perfect for portfolios, reports, and clean presentations.
#' All parameters can be overridden to customize the theme.
#'
#' @param ... Additional theme parameters to override defaults. Can include any styling parameter
#'   like `navbar_bg_color`, `navbar_text_color`, `navbar_text_hover_color`, `mainfont`, `fontsize`, etc.
#'
#' @return A named list of theme parameters
#' @export
#'
#' @examples
#' \dontrun{
#' # Use default clean theme
#' dashboard <- create_dashboard("clean_dashboard", "Clean Report") %>%
#'   apply_theme(theme_clean()) %>%
#'   add_page("Report", text = "# Executive Summary")
#' 
#' # Customize with wider layout and different font
#' dashboard <- create_dashboard("custom_clean", "Custom Report") %>%
#'   apply_theme(theme_clean(
#'     mainfont = "Inter",
#'     max_width = "1200px",
#'     fontsize = "18px"
#'   ))
#' }
theme_clean <- function(...) {
  # Default minimal theme settings
  defaults <- list(
    # Colors - subtle and minimal
    navbar_bg_color = "#ffffff",
    navbar_text_color = "#1f2937",
    navbar_text_hover_color = "#374151",
    linkcolor = "#3b82f6",
    backgroundcolor = "#ffffff",
    
    # Typography - clean and simple
    mainfont = "Source Sans Pro",
    fontsize = "17px",
    fontcolor = "#374151",
    monofont = "IBM Plex Mono",
    monobackgroundcolor = "#f9fafb",
    linestretch = 1.7,
    
    # Layout - airy and spacious
    max_width = "900px",                   # Narrower for better readability
    margin_left = "3rem",
    margin_right = "3rem",
    margin_top = "2rem",
    margin_bottom = "2rem",
    
    # Navbar
    navbar_style = "light"
  )
  
  # Merge with any custom overrides from ...
  overrides <- list(...)
  modifyList(defaults, overrides)
}

