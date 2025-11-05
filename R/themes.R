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
#'   `navbar_bg_color`, `navbar_text_color`, `mainfont`, `fontsize`, `fontcolor`, `linkcolor`, `monofont`, 
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
#'     theme_minimal(),
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
#' @param navbar_bg_color Navbar background color. Default: "#CB0D0D" (UvA red)
#' @param navbar_text_color Navbar text color. Default: "#ffffff" (white)
#' @param mainfont Main body font. Default: "Fira Sans"
#' @param fontsize Base font size. Default: "16px"
#' @param fontcolor Main text color. Default: "#2c2c2c"
#' @param linkcolor Hyperlink color. Default: "#CB0D0D" (UvA red)
#' @param monofont Code font family. Default: "Fira Code"
#' @param monobackgroundcolor Code block background. Default: "#f8f8f8"
#' @param linestretch Line height multiplier. Default: 1.6
#' @param backgroundcolor Page background color. Default: "#ffffff"
#' @param max_width Maximum content width. Default: "1200px"
#' @param margin_left Left margin. Default: "2rem"
#' @param margin_right Right margin. Default: "2rem"
#' @param margin_top Top margin. Default: "1rem"
#' @param margin_bottom Bottom margin. Default: "1rem"
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
theme_ascor <- function(navbar_style = "dark",
                       navbar_bg_color = "#CB0D0D",
                       navbar_text_color = "#ffffff",
                       mainfont = "Fira Sans",
                       fontsize = "16px",
                       fontcolor = "#2c2c2c",
                       linkcolor = "#CB0D0D",
                       monofont = "Fira Code",
                       monobackgroundcolor = "#f8f8f8",
                       linestretch = 1.6,
                       backgroundcolor = "#ffffff",
                       max_width = "1200px",
                       margin_left = "2rem",
                       margin_right = "2rem",
                       margin_top = "1rem",
                       margin_bottom = "1rem") {
  list(
    # Colors
    navbar_bg_color = navbar_bg_color,
    navbar_text_color = navbar_text_color,
    linkcolor = linkcolor,
    backgroundcolor = backgroundcolor,
    
    # Typography
    mainfont = mainfont,
    fontsize = fontsize,
    fontcolor = fontcolor,
    monofont = monofont,
    monobackgroundcolor = monobackgroundcolor,
    linestretch = linestretch,
    
    # Layout
    max_width = max_width,
    margin_left = margin_left,
    margin_right = margin_right,
    margin_top = margin_top,
    margin_bottom = margin_bottom,
    
    # Navbar styling
    navbar_style = navbar_style,
    navbar_brand = "ASCoR"
  )
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
#' @param navbar_bg_color Navbar background color. Defaults to `accent_color`
#' @param navbar_text_color Navbar text color. Default: "#ffffff" (white)
#' @param mainfont Main body font. Default: "Fira Sans"
#' @param fontsize Base font size. Default: "16px"
#' @param fontcolor Main text color. Default: "#1f2937"
#' @param linkcolor Hyperlink color. Defaults to `accent_color`
#' @param monofont Code font family. Default: "Source Code Pro"
#' @param monobackgroundcolor Code block background. Default: "#f8fafc"
#' @param linestretch Line height multiplier. Default: 1.6
#' @param backgroundcolor Page background color. Default: "#ffffff"
#' @param max_width Maximum content width. Default: "1200px"
#' @param margin_left Left margin. Default: "2rem"
#' @param margin_right Right margin. Default: "2rem"
#' @param margin_top Top margin. Default: "1rem"
#' @param margin_bottom Bottom margin. Default: "1rem"
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
theme_academic <- function(accent_color = "#2563eb", 
                          navbar_style = "dark",
                          navbar_bg_color = accent_color,
                          navbar_text_color = "#ffffff",
                          mainfont = "Fira Sans",
                          fontsize = "16px",
                          fontcolor = "#1f2937",
                          linkcolor = accent_color,
                          monofont = "Source Code Pro",
                          monobackgroundcolor = "#f8fafc",
                          linestretch = 1.6,
                          backgroundcolor = "#ffffff",
                          max_width = "1200px",
                          margin_left = "2rem",
                          margin_right = "2rem",
                          margin_top = "1rem",
                          margin_bottom = "1rem") {
  list(
    # Colors
    navbar_bg_color = navbar_bg_color,
    navbar_text_color = navbar_text_color,
    linkcolor = linkcolor,
    backgroundcolor = backgroundcolor,
    
    # Typography
    mainfont = mainfont,
    fontsize = fontsize,
    fontcolor = fontcolor,
    monofont = monofont,
    monobackgroundcolor = monobackgroundcolor,
    linestretch = linestretch,
    
    # Layout
    max_width = max_width,
    margin_left = margin_left,
    margin_right = margin_right,
    margin_top = margin_top,
    margin_bottom = margin_bottom,
    
    # Navbar
    navbar_style = navbar_style
  )
}


#' Apply a Modern Tech Theme to Dashboard
#'
#' Returns a sleek, modern theme suitable for tech companies and data science teams.
#' Features bold colors and contemporary typography. All parameters can be overridden.
#'
#' @param style Style variant. Options: "blue" (default), "purple", "green", "orange", "white"
#' @param navbar_bg_color Navbar background color. Defaults based on `style`
#' @param navbar_text_color Navbar text color. Default: "#ffffff" (white)
#' @param mainfont Main body font. Default: "Roboto"
#' @param fontsize Base font size. Default: "16px"
#' @param fontcolor Main text color. Default: "#1f2937"
#' @param linkcolor Hyperlink color. Defaults based on `style`
#' @param monofont Code font family. Default: "JetBrains Mono"
#' @param monobackgroundcolor Code block background. Default: "#f1f5f9"
#' @param linestretch Line height multiplier. Default: 1.5
#' @param backgroundcolor Page background color. Default: "#ffffff"
#' @param max_width Maximum content width. Default: "1400px"
#' @param margin_left Left margin. Default: "2rem"
#' @param margin_right Right margin. Default: "2rem"
#' @param margin_top Top margin. Default: "1rem"
#' @param margin_bottom Bottom margin. Default: "1rem"
#' @param navbar_style Navbar style ("dark" or "light"). Defaults based on `style`
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
theme_modern <- function(style = c("blue", "purple", "green", "orange", "white"),
                        navbar_bg_color = NULL,
                        navbar_text_color = "#ffffff",
                        mainfont = "Roboto",
                        fontsize = "16px",
                        fontcolor = "#1f2937",
                        linkcolor = NULL,
                        monofont = "JetBrains Mono",
                        monobackgroundcolor = "#f1f5f9",
                        linestretch = 1.5,
                        backgroundcolor = "#ffffff",
                        max_width = "1400px",
                        margin_left = "2rem",
                        margin_right = "2rem",
                        margin_top = "1rem",
                        margin_bottom = "1rem",
                        navbar_style = NULL) {
  style <- match.arg(style)
  
  # Define style-specific defaults
  style_defaults <- list(
    blue = list(navbar = "#1e40af", link = "#2563eb", navbar_style = "dark"),
    purple = list(navbar = "#7c3aed", link = "#8b5cf6", navbar_style = "dark"),
    green = list(navbar = "#059669", link = "#10b981", navbar_style = "dark"),
    orange = list(navbar = "#ea580c", link = "#f97316", navbar_style = "dark"),
    white = list(navbar = "#ffffff", link = "#2563eb", navbar_style = "light")
  )
  
  selected_defaults <- style_defaults[[style]]
  
  # Use provided values or fall back to style defaults
  if (is.null(navbar_bg_color)) navbar_bg_color <- selected_defaults$navbar
  if (is.null(linkcolor)) linkcolor <- selected_defaults$link
  if (is.null(navbar_style)) navbar_style <- selected_defaults$navbar_style
  
  list(
    # Colors
    navbar_bg_color = navbar_bg_color,
    navbar_text_color = navbar_text_color,
    linkcolor = linkcolor,
    backgroundcolor = backgroundcolor,
    
    # Typography
    mainfont = mainfont,
    fontsize = fontsize,
    fontcolor = fontcolor,
    monofont = monofont,
    monobackgroundcolor = monobackgroundcolor,
    linestretch = linestretch,
    
    # Layout
    max_width = max_width,
    margin_left = margin_left,
    margin_right = margin_right,
    margin_top = margin_top,
    margin_bottom = margin_bottom,
    
    # Navbar
    navbar_style = navbar_style
  )
}


#' Apply a Minimal Clean Theme to Dashboard
#'
#' Returns an ultra-clean, minimalist theme with maximum focus on content.
#' Perfect for portfolios, reports, and clean presentations.
#' All parameters can be overridden to customize the theme.
#'
#' @param navbar_bg_color Navbar background color. Default: "#ffffff"
#' @param navbar_text_color Navbar text color. Default: "#1f2937" (dark gray)
#' @param mainfont Main body font. Default: "Source Sans Pro"
#' @param fontsize Base font size. Default: "17px"
#' @param fontcolor Main text color. Default: "#374151"
#' @param linkcolor Hyperlink color. Default: "#3b82f6"
#' @param monofont Code font family. Default: "IBM Plex Mono"
#' @param monobackgroundcolor Code block background. Default: "#f9fafb"
#' @param linestretch Line height multiplier. Default: 1.7
#' @param backgroundcolor Page background color. Default: "#ffffff"
#' @param max_width Maximum content width. Default: "900px"
#' @param margin_left Left margin. Default: "3rem"
#' @param margin_right Right margin. Default: "3rem"
#' @param margin_top Top margin. Default: "2rem"
#' @param margin_bottom Bottom margin. Default: "2rem"
#' @param navbar_style Navbar style. Default: "light"
#'
#' @return A named list of theme parameters
#' @export
#'
#' @examples
#' \dontrun{
#' # Use default minimal theme
#' dashboard <- create_dashboard("minimal_dashboard", "Clean Report") %>%
#'   apply_theme(theme_minimal()) %>%
#'   add_page("Report", text = "# Executive Summary")
#' 
#' # Customize with wider layout and different font
#' dashboard <- create_dashboard("custom_minimal", "Custom Report") %>%
#'   apply_theme(theme_minimal(
#'     mainfont = "Inter",
#'     max_width = "1200px",
#'     fontsize = "18px"
#'   ))
#' }
theme_minimal <- function(navbar_bg_color = "#ffffff",
                         navbar_text_color = "#1f2937",
                         mainfont = "Source Sans Pro",
                         fontsize = "17px",
                         fontcolor = "#374151",
                         linkcolor = "#3b82f6",
                         monofont = "IBM Plex Mono",
                         monobackgroundcolor = "#f9fafb",
                         linestretch = 1.7,
                         backgroundcolor = "#ffffff",
                         max_width = "900px",
                         margin_left = "3rem",
                         margin_right = "3rem",
                         margin_top = "2rem",
                         margin_bottom = "2rem",
                         navbar_style = "light") {
  list(
    # Colors
    navbar_bg_color = navbar_bg_color,
    navbar_text_color = navbar_text_color,
    linkcolor = linkcolor,
    backgroundcolor = backgroundcolor,
    
    # Typography
    mainfont = mainfont,
    fontsize = fontsize,
    fontcolor = fontcolor,
    monofont = monofont,
    monobackgroundcolor = monobackgroundcolor,
    linestretch = linestretch,
    
    # Layout
    max_width = max_width,
    margin_left = margin_left,
    margin_right = margin_right,
    margin_top = margin_top,
    margin_bottom = margin_bottom,
    
    # Navbar
    navbar_style = navbar_style
  )
}

