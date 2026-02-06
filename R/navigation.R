# =================================================================
# navigation
# =================================================================


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
    type = "sidebar",
    text = text,
    sidebar = sidebar_id
  )

  # Add icon if provided
  if (!is.null(icon)) {
    section$icon <- icon
  }

  section
}

#' Create a navbar dropdown menu
#'
#' Creates a dropdown menu in the navbar without requiring sidebar groups.
#' This is a simple nested menu structure.
#'
#' @param text Display text for the dropdown menu button
#' @param pages Character vector of page names to include in the dropdown
#' @param icon Optional icon for the menu button
#' @return List containing navbar menu configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a simple dropdown menu
#' dimensions_menu <- navbar_menu(
#'   text = "Dimensions",
#'   pages = c("Strategic Information", "Critical Information"),
#'   icon = "ph:book"
#' )
#' 
#' dashboard <- create_dashboard(
#'   navbar_sections = list(dimensions_menu)
#' )
#' }


#' Create a navbar dropdown menu
#'
#' Creates a dropdown menu in the navbar without requiring sidebar groups.
#' This is a simple nested menu structure.
#'
#' @param text Display text for the dropdown menu button
#' @param pages Character vector of page names to include in the dropdown
#' @param icon Optional icon for the menu button
#' @param align Where to place the menu in the navbar: "left" (default) or "right"
#' @return List containing navbar menu configuration
#' @export
#' @examples
#' \dontrun{
#' # Create a simple dropdown menu (left-aligned by default)
#' dimensions_menu <- navbar_menu(
#'   text = "Dimensions",
#'   pages = c("Strategic Information", "Critical Information"),
#'   icon = "ph:book"
#' )
#' 
#' # Create a right-aligned menu
#' more_info_menu <- navbar_menu(
#'   text = "More Info",
#'   pages = c("About", "Wave 1"),
#'   icon = "ph:info",
#'   align = "right"
#' )
#' 
#' dashboard <- create_dashboard(
#'   navbar_sections = list(dimensions_menu, more_info_menu)
#' )
#' }
navbar_menu <- function(text, pages, icon = NULL, align = c("left", "right")) {
  
  # Validate required parameters

  if (is.null(text) || !is.character(text) || length(text) != 1 || nchar(text) == 0) {
    stop("text must be a non-empty character string")
  }
  if (is.null(pages) || !is.character(pages) || length(pages) == 0) {
    stop("pages must be a non-empty character vector")
  }
  
  align <- match.arg(align)
  
  # Build the navbar menu configuration
  menu <- list(
    type = "menu",
    text = text,
    menu_pages = pages,  # Use menu_pages to distinguish from sidebar reference
    align = align
  )
  
  # Add icon if provided
  if (!is.null(icon)) {
    menu$icon <- icon
  }
  
  menu
}


#' Add a custom navbar element to dashboard
#'
#' Adds a custom link or element to the navbar. Can include text, icons, and external links.
#' Elements are added to the right side of the navbar by default but can be positioned left.
#'
#' @param proj Dashboard project object from create_dashboard()
#' @param text Display text for the element (optional if icon provided)
#' @param icon Iconify icon (e.g., "ph:lightning-fill") (optional)
#' @param href Hyperlink URL (required)
#' @param align Position in navbar: "left" or "right" (default: "right")
#'
#' @return Modified dashboard project object
#' @export
#'
#' @examples
#' \dontrun{
#' # Add a "Powered by X" link with icon
#' dashboard <- create_dashboard("my_dashboard", "My Dashboard") %>%
#'   add_page("Home", text = "# Welcome", is_landing_page = TRUE) %>%
#'   add_navbar_element(
#'     text = "Powered by X",
#'     icon = "ph:lightning-fill",
#'     href = "https://example.com",
#'     align = "right"
#'   )
#'
#' # Add multiple elements
#' dashboard <- create_dashboard("my_dashboard", "Dashboard") %>%
#'   add_page("Home", ...) %>%
#'   add_navbar_element(
#'     text = "Documentation",
#'     icon = "ph:book-open",
#'     href = "https://docs.example.com"
#'   ) %>%
#'   add_navbar_element(
#'     text = "Sponsor",
#'     icon = "ph:star-fill",
#'     href = "https://sponsor.com"
#'   )
#'
#' # Icon only (no text)
#' dashboard %>%
#'   add_navbar_element(
#'     icon = "ph:github-logo",
#'     href = "https://github.com/user/repo"
#'   )
#' }
add_navbar_element <- function(proj, text = NULL, icon = NULL, href, 
                               align = c("right", "left")) {
  if (!inherits(proj, "dashboard_project")) {
    stop("proj must be a dashboard_project object from create_dashboard()")
  }
  
  if (is.null(text) && is.null(icon)) {
    stop("Either text or icon (or both) must be provided")
  }
  
  if (missing(href) || is.null(href) || !is.character(href) || length(href) != 1 || nchar(href) == 0) {
    stop("href must be a non-empty URL string")
  }
  
  align <- match.arg(align)
  
  # Create element
  element <- list(
    type = "custom_link",
    text = text,
    icon = icon,
    href = href,
    align = align
  )
  
  # Initialize list if needed
  if (is.null(proj$navbar_elements)) {
    proj$navbar_elements <- list()
  }
  
  # Add element
  proj$navbar_elements <- c(proj$navbar_elements, list(element))
  
  proj
}
NA

