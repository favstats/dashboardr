# =================================================================
# quarto_yml
# =================================================================


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
#' @keywords internal
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
  
  # Add resources to copy assets directory to output
  yaml_lines <- c(yaml_lines, "  resources:")
  yaml_lines <- c(yaml_lines, "    - assets/")

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

  # Navbar background color is handled via SCSS (not directly in YAML)
  # Quarto only accepts Bootstrap color names for navbar.background
  # Custom colors (navbar_bg_color) are applied via SCSS theme file

  # Navbar brand
  if (!is.null(proj$navbar_brand)) {
    yaml_lines <- c(yaml_lines, paste0("    brand: \"", proj$navbar_brand, "\""))
  }

  # Navbar toggle
  if (!is.null(proj$navbar_toggle)) {
    yaml_lines <- c(yaml_lines, paste0("    toggle: ", proj$navbar_toggle))
  }

  # Add logo if provided (at navbar level, before left/right sections)
  # Use basename since the logo file is copied to the output directory
  if (!is.null(proj$logo)) {
    yaml_lines <- c(yaml_lines, paste0("    logo: ", basename(proj$logo)))
  }

  # Separate pages by navbar alignment
  pages_left <- list()
  pages_right <- list()
  
  # Find landing page
  landing_page_name <- NULL
  for (page_name in names(proj$pages)) {
    if (proj$pages[[page_name]]$is_landing_page) {
      landing_page_name <- page_name
      break
    }
  }
  
  # Group pages by alignment
  for (page_name in names(proj$pages)) {
    page <- proj$pages[[page_name]]
    # Skip landing page as it's added separately with href: index.qmd
    if (page$is_landing_page) {
      next
    }
    
    # Determine alignment (default to "left")
    if (is.null(page$navbar_align)) {
      align <- "left"
    } else {
      align <- page$navbar_align
    }
    
    if (align == "right") {
      pages_right[[page_name]] <- page
    } else {
      pages_left[[page_name]] <- page
    }
  }

  # Left navigation
  yaml_lines <- c(yaml_lines, "    left:")

  # Add landing page link if there's a landing page (only if not using navbar sections)
  # Skip if show_in_nav is FALSE (pageless dashboard, created with name = "")
  landing_show_in_nav <- if (!is.null(landing_page_name)) {
    proj$pages[[landing_page_name]]$show_in_nav %||% TRUE
  } else {
    TRUE
  }
  if (!is.null(landing_page_name) && (is.null(proj$navbar_sections) || length(proj$navbar_sections) == 0)) {
    if (landing_show_in_nav) {
      landing_page <- proj$pages[[landing_page_name]]
      
      # Build text with icon if provided (same pattern as other pages)
      landing_text <- .quarto_nav_text(landing_page_name, landing_page$icon)
      
      yaml_lines <- c(yaml_lines,
        "      - href: index.qmd",
        paste0("        text: ", landing_text)
      )
    } else {
      # Pageless dashboard: emit a minimal hidden entry so Quarto's left: isn't empty
      # Use a single space (not empty string) to prevent Quarto from
      # extracting page content as the nav text
      yaml_lines <- c(yaml_lines,
        "      - href: index.qmd",
        "        text: \" \""
      )
    }
  }

  # Add navigation links - support both regular pages and navbar sections
  # Initialize right_sections before the if block so it's available for right navbar processing
  right_sections <- list()
  
  if (!is.null(proj$navbar_sections) && length(proj$navbar_sections) > 0) {
    # Collect pages that are in menus or sidebars
    pages_in_sections <- character(0)
    
    # Separate left and right aligned sections
    left_sections <- list()
    for (sec in proj$navbar_sections) {
      if (!is.null(sec$align) && sec$align == "right") {
        right_sections <- c(right_sections, list(sec))
        # Also track pages in right-aligned sections so they don't appear as individual navbar items
        if (!is.null(sec$menu_pages)) {
          pages_in_sections <- c(pages_in_sections, sec$menu_pages)
        }
      } else {
        left_sections <- c(left_sections, list(sec))
      }
    }
    
    # Hybrid navigation mode - add LEFT-ALIGNED navbar sections that link to sidebar groups
    for (section in left_sections) {
      if (!is.null(section$sidebar)) {
        # This is a sidebar reference (hybrid navigation)
        yaml_lines <- c(yaml_lines, paste0("      - sidebar:", section$sidebar))
        
        # Track pages in this sidebar
        if (!is.null(proj$sidebar_groups)) {
          for (sg in proj$sidebar_groups) {
            if (!is.null(sg$id) && sg$id == section$sidebar) {
              pages_in_sections <- c(pages_in_sections, sg$pages)
              break
            }
          }
        }
      } else if (!is.null(section$menu_pages)) {
        # Track pages in this menu
        pages_in_sections <- c(pages_in_sections, section$menu_pages)
        
        # This is a dropdown menu
        text_content <- .quarto_nav_text(section$text, section$icon)
        yaml_lines <- c(yaml_lines,
          paste0("      - text: ", text_content),
          "        menu:"
        )
        
        # Add menu items for each page
        for (page_name in section$menu_pages) {
          if (!is.null(proj$pages[[page_name]])) {
            page <- proj$pages[[page_name]]
            
            # Generate filename same way as other pages
            filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
            page_qmd <- paste0(filename, ".qmd")
            
            # Get page text with icon if available
            page_text_content <- .quarto_nav_text(page_name, page$icon)
            
            yaml_lines <- c(yaml_lines,
              paste0("          - href: ", page_qmd),
              paste0("            text: ", page_text_content)
            )
          }
        }
      } else if (!is.null(section$href)) {
        # This is a regular link
        text_content <- .quarto_nav_text(section$text, section$icon)
        yaml_lines <- c(yaml_lines,
          paste0("      - href: ", section$href),
          paste0("        text: ", text_content)
        )
      }
    }
    
    # Now add any left-aligned pages that are NOT in any menu or sidebar
    for (page_name in names(pages_left)) {
      if (!page_name %in% pages_in_sections) {
        page <- pages_left[[page_name]]
        
        # Use lowercase with underscores for filenames
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
        
        # Build text with icon if provided
        text_content <- .quarto_nav_text(page_name, page$icon)
        
        yaml_lines <- c(yaml_lines,
                        paste0("      - href: ", filename, ".qmd"),
                        paste0("        text: ", text_content)
        )
      }
    }
  } else {
    # Simple navigation mode - add left-aligned pages
    for (page_name in names(pages_left)) {
      page <- pages_left[[page_name]]

      # Use lowercase with underscores for filenames
      filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

      # Build text with icon if provided
      text_content <- .quarto_nav_text(page_name, page$icon)

      yaml_lines <- c(yaml_lines,
                      paste0("      - href: ", filename, ".qmd"),
                      paste0("        text: ", text_content)
      )
    }
  }
  
  # Right navigation - add right-aligned pages before tools
  if (length(pages_right) > 0) {
    has_right_pages <- TRUE
  } else {
    has_right_pages <- FALSE
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

  # Check if we have custom navbar elements
  custom_navbar_right <- list()
  custom_navbar_left <- list()
  if (!is.null(proj$navbar_elements) && length(proj$navbar_elements) > 0) {
    for (elem in proj$navbar_elements) {
      if (!is.null(elem$align) && elem$align == "left") {
        custom_navbar_left <- c(custom_navbar_left, list(elem))
      } else {
        custom_navbar_right <- c(custom_navbar_right, list(elem))
      }
    }
  }
  
  # Add left section for custom navbar elements if any
  if (length(custom_navbar_left) > 0) {
    for (elem in custom_navbar_left) {
      if (!is.null(elem$text) || !is.null(elem$icon)) {
        yaml_lines <- c(yaml_lines,
          paste0("      - text: ", .quarto_nav_text(elem$text %||% "", elem$icon)),
          paste0("        href: ", elem$href)
        )
      }
    }
  }
  
  # Add right section if we have right-aligned pages OR tools OR custom elements OR right sections
  has_right_sections <- length(right_sections) > 0
  if (has_right_pages || length(tools) > 0 || length(custom_navbar_right) > 0 || has_right_sections) {
    yaml_lines <- c(yaml_lines, "    right:")
    
    # First, add right-aligned navbar sections (menus/dropdowns)
    if (has_right_sections) {
      for (section in right_sections) {
        if (!is.null(section$menu_pages)) {
          # This is a dropdown menu
          text_content <- .quarto_nav_text(section$text, section$icon)
          yaml_lines <- c(yaml_lines,
            paste0("      - text: ", text_content),
            "        menu:"
          )
          
          # Add menu items for each page
          for (page_name in section$menu_pages) {
            if (!is.null(proj$pages[[page_name]])) {
              page <- proj$pages[[page_name]]
              
              # Generate filename same way as other pages
              filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
              page_qmd <- paste0(filename, ".qmd")
              
              # Get page text with icon if available
              page_text_content <- .quarto_nav_text(page_name, page$icon)
              
              yaml_lines <- c(yaml_lines,
                paste0("          - href: ", page_qmd),
                paste0("            text: ", page_text_content)
              )
            }
          }
        } else if (!is.null(section$href)) {
          # This is a regular right-aligned link
          text_content <- .quarto_nav_text(section$text, section$icon)
          yaml_lines <- c(yaml_lines,
            paste0("      - href: ", section$href),
            paste0("        text: ", text_content)
          )
        }
      }
    }
    
    # Next, add right-aligned pages
    if (has_right_pages) {
      for (page_name in names(pages_right)) {
        page <- pages_right[[page_name]]

        # Use lowercase with underscores for filenames
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))

        # Build text with icon if provided
        text_content <- .quarto_nav_text(page_name, page$icon)

        yaml_lines <- c(yaml_lines,
                        paste0("      - href: ", filename, ".qmd"),
                        paste0("        text: ", text_content)
        )
      }
    }
    
    # Then, add custom navbar elements (right-aligned)
    for (elem in custom_navbar_right) {
      if (!is.null(elem$text) || !is.null(elem$icon)) {
        yaml_lines <- c(yaml_lines,
          paste0("      - text: ", .quarto_nav_text(elem$text %||% "", elem$icon)),
          paste0("        href: ", elem$href)
        )
      }
    }
    
    # Finally, add tools (github, twitter, etc.)
    for (tool in tools) {
      yaml_lines <- c(yaml_lines,
        paste0("      - icon: ", tool$icon),
        paste0("        href: ", tool$href)
      )
    }
  }

  # Add search setting
  if (isTRUE(proj$search)) {
    yaml_lines <- c(yaml_lines, "    search: true")
  } else {
    yaml_lines <- c(yaml_lines, "    search: false")
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
            text_content <- .quarto_nav_text(matching_page, proj$pages[[matching_page]]$icon)

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
          landing_page <- proj$pages[[landing_page_name]]
          
          # Build text with icon if provided
          landing_text <- .quarto_nav_text(landing_page_name, landing_page$icon)
          
          yaml_lines <- c(yaml_lines, paste0("      - text: ", landing_text))
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
          text_content <- .quarto_nav_text(page_name, proj$pages[[page_name]]$icon)

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
    if (is.list(proj$page_footer) && 
        !is.null(proj$page_footer$structure) && 
        proj$page_footer$structure == "structured") {
      # Structured footer with left/center/right
      yaml_lines <- c(yaml_lines, "  page-footer:")
      
      # Helper function to properly escape or format footer content
      format_footer_content <- function(content) {
        # If content contains HTML (has < and > characters), use literal block scalar
        if (grepl("<.*>", content)) {
          return(paste0("|", "\n      ", content))
        } else {
          # Simple text - escape quotes and use quoted string
          escaped <- gsub('"', '\\"', content, fixed = TRUE)
          return(paste0('"', escaped, '"'))
        }
      }
      
      if (!is.null(proj$page_footer$left) && proj$page_footer$left != "") {
        formatted <- format_footer_content(proj$page_footer$left)
        if (startsWith(formatted, "|")) {
          yaml_lines <- c(yaml_lines, paste0("    left: ", formatted))
        } else {
          yaml_lines <- c(yaml_lines, paste0("    left: ", formatted))
        }
      }
      if (!is.null(proj$page_footer$center) && proj$page_footer$center != "") {
        formatted <- format_footer_content(proj$page_footer$center)
        if (startsWith(formatted, "|")) {
          yaml_lines <- c(yaml_lines, paste0("    center: ", formatted))
        } else {
          yaml_lines <- c(yaml_lines, paste0("    center: ", formatted))
        }
      }
      if (!is.null(proj$page_footer$right) && proj$page_footer$right != "") {
        formatted <- format_footer_content(proj$page_footer$right)
        if (startsWith(formatted, "|")) {
          yaml_lines <- c(yaml_lines, paste0("    right: ", formatted))
        } else {
          yaml_lines <- c(yaml_lines, paste0("    right: ", formatted))
        }
      }
    } else if (is.character(proj$page_footer)) {
      # Simple string footer - escape quotes
      escaped <- gsub('"', '\\"', proj$page_footer, fixed = TRUE)
      yaml_lines <- c(yaml_lines, paste0("  page-footer: \"", escaped, "\""))
    }
  }

  # Add format section with theme and SCSS
  yaml_lines <- c(yaml_lines,
    "",
    "format:",
    "  html:",
    "    prefer-html: true",
    "    theme:"
  )
  
  # Add base theme
  yaml_lines <- c(yaml_lines, paste0("      - ", proj$theme %||% "default"))
  
  # Add tabset theme SCSS if specified
  if (!is.null(proj$tabset_theme) && proj$tabset_theme != "none") {
    tabset_scss_file <- paste0("_tabset_", proj$tabset_theme, ".scss")
    yaml_lines <- c(yaml_lines, paste0("      - ", tabset_scss_file))
  }
  
  # Add generated color override SCSS if colors are customized
  if (!is.null(proj$tabset_colors) && length(proj$tabset_colors) > 0) {
    yaml_lines <- c(yaml_lines, "      - _tabset_colors.scss")
  }
  
  # Add theme customization SCSS if navbar_bg_color or other custom theme options are set
  if (!is.null(proj$navbar_bg_color) || !is.null(proj$navbar_text_color) || !is.null(proj$navbar_text_hover_color)) {
    yaml_lines <- c(yaml_lines, "      - _theme_custom.scss")
  }
  
  # Add custom SCSS if provided
  if (!is.null(proj$custom_scss)) {
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_scss))
  }
  
  yaml_lines <- c(yaml_lines, "")

  # Add CSS files (assets + custom)
  # Always include modal.css and pagination.css from assets
  css_files <- c("assets/modal.css", "assets/pagination.css")
  
  # Add custom CSS if provided
  if (!is.null(proj$custom_css)) {
    css_files <- c(css_files, proj$custom_css)
  }
  
  # Write CSS section
  if (length(css_files) > 0) {
    yaml_lines <- c(yaml_lines, "    css:")
    for (css_file in css_files) {
      yaml_lines <- c(yaml_lines, paste0("      - ", css_file))
    }
  }

  # Add HTML format options
  if (!is.null(proj$max_width)) {
    yaml_lines <- c(yaml_lines, paste0("    max-width: ", proj$max_width))
  }
  
  # Collect all content that needs to go in include-in-header
  header_content <- c()
  
  # Add Google Fonts import in header if needed
  if (!is.null(proj$mainfont) || !is.null(proj$monofont)) {
    fonts_to_import <- c()
    
    # Common Google Fonts that need importing
    google_fonts <- c("Fira Sans", "Fira Code", "Inter", "Roboto", "Lato", 
                     "Source Sans Pro", "Source Code Pro", "IBM Plex Mono", 
                     "JetBrains Mono")
    
    if (!is.null(proj$mainfont) && proj$mainfont %in% google_fonts) {
      fonts_to_import <- c(fonts_to_import, proj$mainfont)
    }
    if (!is.null(proj$monofont) && proj$monofont %in% google_fonts) {
      fonts_to_import <- c(fonts_to_import, proj$monofont)
    }
    
    # Add font imports to header content
    if (length(fonts_to_import) > 0) {
      # Convert font names to Google Fonts format (replace spaces with +)
      font_params <- sapply(unique(fonts_to_import), function(f) {
        paste0("family=", gsub(" ", "+", f), ":wght@300;400;500;600;700")
      })
      
      import_url <- paste0("https://fonts.googleapis.com/css2?", 
                          paste(font_params, collapse = "&"), 
                          "&display=swap")
      
      header_content <- c(header_content,
                         paste0("        <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"),
                         paste0("        <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"),
                         paste0("        <link href=\"", import_url, "\" rel=\"stylesheet\">"))
    }
  }
  
  if (!is.null(proj$mainfont)) {
    yaml_lines <- c(yaml_lines, paste0("    mainfont: \"", proj$mainfont, "\""))
  }
  if (!is.null(proj$fontsize)) {
    yaml_lines <- c(yaml_lines, paste0("    fontsize: ", proj$fontsize))
  }
  if (!is.null(proj$fontcolor)) {
    yaml_lines <- c(yaml_lines, paste0("    fontcolor: \"", proj$fontcolor, "\""))
  }
  if (!is.null(proj$linkcolor)) {
    yaml_lines <- c(yaml_lines, paste0("    linkcolor: \"", proj$linkcolor, "\""))
  }
  if (!is.null(proj$monofont)) {
    yaml_lines <- c(yaml_lines, paste0("    monofont: \"", proj$monofont, "\""))
  }
  if (!is.null(proj$monobackgroundcolor)) {
    yaml_lines <- c(yaml_lines, paste0("    monobackgroundcolor: \"", proj$monobackgroundcolor, "\""))
  }
  if (!is.null(proj$linestretch)) {
    yaml_lines <- c(yaml_lines, paste0("    linestretch: ", proj$linestretch))
  }
  if (!is.null(proj$backgroundcolor)) {
    yaml_lines <- c(yaml_lines, paste0("    backgroundcolor: \"", proj$backgroundcolor, "\""))
  }
  if (!is.null(proj$margin_left)) {
    yaml_lines <- c(yaml_lines, paste0("    margin-left: \"", proj$margin_left, "\""))
  }
  if (!is.null(proj$margin_right)) {
    yaml_lines <- c(yaml_lines, paste0("    margin-right: \"", proj$margin_right, "\""))
  }
  if (!is.null(proj$margin_top)) {
    yaml_lines <- c(yaml_lines, paste0("    margin-top: \"", proj$margin_top, "\""))
  }
  if (!is.null(proj$margin_bottom)) {
    yaml_lines <- c(yaml_lines, paste0("    margin-bottom: \"", proj$margin_bottom, "\""))
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
  if (!is.null(proj$code_folding) && isTRUE(proj$code_folding)) {
    yaml_lines <- c(yaml_lines, "    code-fold: true")
  }

  # Add code tools
  if (!is.null(proj$code_tools) && isTRUE(proj$code_tools)) {
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
  
  # Add self-contained option
  if (!is.null(proj$self_contained) && proj$self_contained) {
    yaml_lines <- c(yaml_lines, "    self-contained: true")
  }
  
  # Add code-overflow option
  if (!is.null(proj$code_overflow)) {
    yaml_lines <- c(yaml_lines, paste0("    code-overflow: ", proj$code_overflow))
  }
  
  # Add html-math-method option
  if (!is.null(proj$html_math_method)) {
    yaml_lines <- c(yaml_lines, paste0("    html-math-method: ", proj$html_math_method))
  }
  
  # Add viewport meta tag if specified
  if (!is.null(proj$viewport_width)) {
    yaml_lines <- c(yaml_lines, "    html-meta:")
    
    # Check if viewport_width is already a full string (advanced usage)
    if (is.character(proj$viewport_width) && grepl("width=", proj$viewport_width)) {
      # User provided full viewport string
      viewport_value <- proj$viewport_width
    } else {
      # Build viewport string from components
      viewport_parts <- c()
      
      # Add width
      if (is.numeric(proj$viewport_width)) {
        viewport_parts <- c(viewport_parts, paste0("width=", proj$viewport_width))
      } else if (is.character(proj$viewport_width)) {
        viewport_parts <- c(viewport_parts, paste0("width=", proj$viewport_width))
      }
      
      # Add initial scale if specified
      if (!is.null(proj$viewport_scale)) {
        viewport_parts <- c(viewport_parts, paste0("initial-scale=", proj$viewport_scale))
      }
      
      # Add user-scalable
      if (!is.null(proj$viewport_user_scalable)) {
        scalable_value <- if (proj$viewport_user_scalable) "yes" else "no"
        viewport_parts <- c(viewport_parts, paste0("user-scalable=", scalable_value))
      }
      
      viewport_value <- paste(viewport_parts, collapse=", ")
    }
    
    yaml_lines <- c(yaml_lines, paste0("      viewport: \"", viewport_value, "\""))
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
    # Plausible analytics - supports two formats:
    # 1. Simple domain string: "example.com" \u2192 uses Quarto's built-in plausible integration
    # 2. List with script_hash: list(domain = "example.com", script_hash = "pa-XXX") \u2192 uses custom proxy script
    
    if (is.list(proj$plausible) && !is.null(proj$plausible$script_hash)) {
      # Proxy script format with custom hash (for ad-blocker bypass)
      script_hash <- proj$plausible$script_hash
      domain <- proj$plausible$domain %||% ""
      
      header_content <- c(header_content,
                         "        <!-- Privacy-friendly analytics by Plausible -->",
                         paste0("        <script async src=\"https://plausible.io/js/", 
                                script_hash, ".js\"></script>"),
                         "        <script>",
                         "          window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},plausible.init=plausible.init||function(i){plausible.o=i||{}};",
                         "          plausible.init()",
                         "        </script>")
    } else {
      # Standard format - use Quarto's built-in plausible support
      domain <- if (is.list(proj$plausible)) {
        proj$plausible$domain
      } else {
        proj$plausible
      }
      
      if (!is.null(domain) && nzchar(domain)) {
        yaml_lines <- c(yaml_lines, "    plausible:")
        yaml_lines <- c(yaml_lines, paste0("      domain: \"", domain, "\""))
      }
    }
  }
  
  # Add BOMBPROOF tab-jump prevention script (always included)
  # This is a multi-layer defense against scroll jumping:
  # 1. Locks scroll position with CSS class during tab transition
  # Tab scroll fix - reference external file (copied to assets/ during generation)
  # Prevents page jumping when clicking on tabs in panel-tabsets
  header_content <- c(header_content,
    "        <script src=\"assets/tab-scroll-fix.js\"></script>"
  )
  
  # Write the collected header content once
  if (length(header_content) > 0) {
    yaml_lines <- c(yaml_lines, "    include-in-header:")
    yaml_lines <- c(yaml_lines, "      text: |")
    yaml_lines <- c(yaml_lines, header_content)
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

  # Add mobile TOC if enabled
  if (!is.null(proj$mobile_toc) && proj$mobile_toc) {
    yaml_lines <- c(yaml_lines, "    include-after-body:")
    yaml_lines <- c(yaml_lines, "      text: |")
    yaml_lines <- c(yaml_lines, "        <script>")
    yaml_lines <- c(yaml_lines, "          document.addEventListener(\"DOMContentLoaded\", function () {")
    yaml_lines <- c(yaml_lines, "              var toc = document.createElement(\"div\");")
    yaml_lines <- c(yaml_lines, "              toc.id = \"custom-toc\";")
    yaml_lines <- c(yaml_lines, "              toc.style.position = \"fixed\";")
    yaml_lines <- c(yaml_lines, "              toc.style.top = \"0\";")
    yaml_lines <- c(yaml_lines, "              toc.style.right = \"-300px\";")
    yaml_lines <- c(yaml_lines, "              toc.style.width = \"260px\";")
    yaml_lines <- c(yaml_lines, "              toc.style.height = \"100%\";")
    yaml_lines <- c(yaml_lines, "              toc.style.background = \"white\";")
    yaml_lines <- c(yaml_lines, "              toc.style.padding = \"10px\";")
    yaml_lines <- c(yaml_lines, "              toc.style.boxShadow = \"0px 2px 5px rgba(0, 0, 0, 0.2)\";")
    yaml_lines <- c(yaml_lines, "              toc.style.transition = \"right 0.3s ease-in-out\";")
    yaml_lines <- c(yaml_lines, "              toc.style.overflowY = \"auto\";")
    yaml_lines <- c(yaml_lines, "              toc.style.zIndex = \"999\";")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              var tocTitle = document.createElement(\"h3\");")
    yaml_lines <- c(yaml_lines, "              tocTitle.innerText = \"Navigation\";")
    yaml_lines <- c(yaml_lines, "              toc.appendChild(tocTitle);")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              var headers = document.querySelectorAll(\"h2, h3, h4\");")
    yaml_lines <- c(yaml_lines, "              headers.forEach(function (header, index) {")
    yaml_lines <- c(yaml_lines, "                  if (!header.id) {")
    yaml_lines <- c(yaml_lines, "                      header.id = \"section-\" + index;")
    yaml_lines <- c(yaml_lines, "                  }")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "                  var link = document.createElement(\"a\");")
    yaml_lines <- c(yaml_lines, "                  link.innerText = header.innerText;")
    yaml_lines <- c(yaml_lines, "                  link.href = \"#\" + header.id;")
    yaml_lines <- c(yaml_lines, "                  link.style.display = \"block\";")
    yaml_lines <- c(yaml_lines, "                  link.style.padding = \"5px 0\";")
    yaml_lines <- c(yaml_lines, "                  link.style.color = \"#007bff\";")
    yaml_lines <- c(yaml_lines, "                  link.style.textDecoration = \"none\";")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "                  toc.appendChild(link);")
    yaml_lines <- c(yaml_lines, "              });")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              document.body.appendChild(toc);")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              var button = document.createElement(\"button\");")
    yaml_lines <- c(yaml_lines, "              button.id = \"toggle-toc\";")
    yaml_lines <- c(yaml_lines, "              button.innerHTML = \"\U0001f4d1\";")
    yaml_lines <- c(yaml_lines, "              button.style.position = \"fixed\";")
    yaml_lines <- c(yaml_lines, "              button.style.top = \"15px\";")
    yaml_lines <- c(yaml_lines, "              button.style.right = \"15px\";")
    yaml_lines <- c(yaml_lines, "              button.style.backgroundColor = \"white\";")
    yaml_lines <- c(yaml_lines, "              button.style.color = \"#333\";")
    yaml_lines <- c(yaml_lines, "              button.style.border = \"2px solid #ccc\";")
    yaml_lines <- c(yaml_lines, "              button.style.padding = \"10px 12px\";")
    yaml_lines <- c(yaml_lines, "              button.style.cursor = \"pointer\";")
    yaml_lines <- c(yaml_lines, "              button.style.borderRadius = \"8px\";")
    yaml_lines <- c(yaml_lines, "              button.style.fontSize = \"22px\";")
    yaml_lines <- c(yaml_lines, "              button.style.zIndex = \"1000\";")
    yaml_lines <- c(yaml_lines, "              button.style.boxShadow = \"0px 3px 6px rgba(0, 0, 0, 0.2)\";")
    yaml_lines <- c(yaml_lines, "              button.style.width = \"50px\";")
    yaml_lines <- c(yaml_lines, "              button.style.height = \"50px\";")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              document.body.appendChild(button);")
    yaml_lines <- c(yaml_lines, "          ")
    yaml_lines <- c(yaml_lines, "              button.addEventListener(\"click\", function () {")
    yaml_lines <- c(yaml_lines, "                  if (toc.style.right === \"0px\") {")
    yaml_lines <- c(yaml_lines, "                      toc.style.right = \"-300px\";")
    yaml_lines <- c(yaml_lines, "                  } else {")
    yaml_lines <- c(yaml_lines, "                      toc.style.right = \"0px\";")
    yaml_lines <- c(yaml_lines, "                  }")
    yaml_lines <- c(yaml_lines, "              });")
    yaml_lines <- c(yaml_lines, "          });")
    yaml_lines <- c(yaml_lines, "        </script>")
  }

  # Note: iconify extension is installed as a shortcode extension, not a filter
  # It will be automatically available once installed in _extensions/
  # No need to add it to the filters section

  yaml_lines
}


# Generate default page content when no custom template is used

#' Generate lazy loading script for charts
#'
#' Creates JavaScript code for Intersection Observer-based lazy loading
#' and tab-aware rendering of charts
#'
#' @param lazy_load_margin Viewport margin for intersection observer
#' @param lazy_load_tabs Whether to enable tab-aware lazy loading
#' @return Character vector of script lines
#' @keywords internal
.generate_lazy_load_script <- function(lazy_load_margin = "200px", lazy_load_tabs = TRUE, theme = "light", debug = FALSE) {
  # Build theme-aware skeleton styles
  skeleton_css <- paste0("
<style>
/* Chart Lazy Loading Styles */
.chart-lazy {
  position: relative;
  min-height: 400px;
  margin: 1rem 0;
}

.chart-skeleton {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 1rem;
  transition: opacity 0.3s ease;
}

.chart-spinner {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.chart-loading-text {
  font-size: 0.9rem;
  font-weight: 500;
  letter-spacing: 0.5px;
}

/* Theme: Light */
.chart-skeleton.theme-light {
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid rgba(0, 0, 0, 0.05);
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.chart-skeleton.theme-light .chart-spinner {
  border: 3px solid rgba(148, 163, 184, 0.2);
  border-top-color: rgba(15, 23, 42, 0.8);
}

.chart-skeleton.theme-light .chart-loading-text {
  color: rgba(15, 23, 42, 0.7);
}

/* Theme: Glass */
.chart-skeleton.theme-glass {
  background: rgba(255, 255, 255, 0.25);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.08);
}

.chart-skeleton.theme-glass .chart-spinner {
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top-color: rgba(15, 23, 42, 0.7);
}

.chart-skeleton.theme-glass .chart-loading-text {
  color: rgba(15, 23, 42, 0.8);
}

/* Theme: Dark */
.chart-skeleton.theme-dark {
  background: rgba(15, 23, 42, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.chart-skeleton.theme-dark .chart-spinner {
  border: 3px solid rgba(148, 163, 184, 0.3);
  border-top-color: rgba(255, 255, 255, 0.9);
}

.chart-skeleton.theme-dark .chart-loading-text {
  color: rgba(255, 255, 255, 0.9);
}

/* Theme: Accent */
.chart-skeleton.theme-accent {
  background: rgba(255, 255, 255, 0.98);
  border: 1px solid rgba(59, 130, 246, 0.15);
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(59, 130, 246, 0.15);
}

.chart-skeleton.theme-accent .chart-spinner {
  border: 3px solid rgba(59, 130, 246, 0.2);
  border-top-color: rgba(59, 130, 246, 0.9);
}

.chart-skeleton.theme-accent .chart-loading-text {
  color: rgba(15, 23, 42, 0.8);
}
</style>

<script>
// Chart Lazy Loading System
(function() {
  const THEME = '", theme, "';
  const DEBUG = ", tolower(as.character(debug)), ";
  
  // Track which charts have been initialized
  const initializedCharts = new Set();
  
  // Queue of charts waiting to be initialized
  const chartQueue = [];
  let isProcessingQueue = false;
  
  // Performance tracking
  let totalChartsLoaded = 0;
  let totalLoadTime = 0;
  const chartTimings = [];
  
  // Create skeleton loader dynamically
  function createSkeleton(container) {
    const skeleton = document.createElement('div');
    skeleton.className = 'chart-skeleton theme-' + THEME;
    skeleton.innerHTML = `
      <div class=\"chart-spinner\"></div>
      <div class=\"chart-loading-text\">Loading visualization...</div>
    `;
    container.appendChild(skeleton);
    return skeleton;
  }
  
  // Initialize a single chart
  function initChart(container) {
    const chartId = container.id;
    if (initializedCharts.has(chartId)) return;
    
    const startTime = DEBUG ? performance.now() : 0;
    
    initializedCharts.add(chartId);
    container.dataset.loaded = 'true';
    
    // Remove skeleton loader
    const skeleton = container.querySelector('.chart-skeleton');
    if (skeleton) {
      skeleton.style.opacity = '0';
      setTimeout(() => skeleton.remove(), 300);
    }
    
    // Trigger Highcharts reflow if present
    setTimeout(() => {
      if (window.Highcharts) {
        Highcharts.charts.forEach(chart => {
          if (chart && chart.reflow) chart.reflow();
        });
      }
      
      // Debug logging
      if (DEBUG) {
        const loadTime = performance.now() - startTime;
        totalChartsLoaded++;
        totalLoadTime += loadTime;
        chartTimings.push({ id: chartId, time: loadTime });
        
        console.log(`\U0001f4ca Chart loaded: ${chartId} (${loadTime.toFixed(2)}ms)`);
        console.log(`   Total: ${totalChartsLoaded} charts, Avg: ${(totalLoadTime/totalChartsLoaded).toFixed(2)}ms`);
      }
    }, 50);
  }
  
  // Process chart queue in batches
  function processQueue() {
    if (isProcessingQueue || chartQueue.length === 0) return;
    
    isProcessingQueue = true;
    const batchSize = 3;
    const batch = chartQueue.splice(0, batchSize);
    
    if (DEBUG) {
      console.log(`\u26a1 Processing batch of ${batch.length} charts (${chartQueue.length} remaining)`);
    }
    
    batch.forEach(container => initChart(container));
    
    if (chartQueue.length > 0) {
      requestIdleCallback(() => {
        isProcessingQueue = false;
        processQueue();
      }, { timeout: 2000 });
    } else {
      isProcessingQueue = false;
      
      if (DEBUG && totalChartsLoaded > 0) {
        console.log(`\u2705 All charts loaded! Summary:`);
        console.log(`   Total charts: ${totalChartsLoaded}`);
        console.log(`   Total time: ${totalLoadTime.toFixed(2)}ms`);
        console.log(`   Average time per chart: ${(totalLoadTime/totalChartsLoaded).toFixed(2)}ms`);
        console.log(`   Slowest chart: ${Math.max(...chartTimings.map(t => t.time)).toFixed(2)}ms`);
        console.log(`   Fastest chart: ${Math.min(...chartTimings.map(t => t.time)).toFixed(2)}ms`);
      }
    }
  }
  
  // Intersection Observer for scroll-based lazy loading
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting && entry.target.dataset.loaded === 'false') {
        chartQueue.push(entry.target);
        observer.unobserve(entry.target);
        processQueue();
      }
    });
  }, { rootMargin: '", lazy_load_margin, "' });
  
  // Initialize observers when DOM is ready
  function initLazyLoading() {
    document.querySelectorAll('.chart-lazy[data-loaded=\"false\"]').forEach(container => {
      // Create skeleton for each lazy chart
      createSkeleton(container);
      // Start observing
      observer.observe(container);
    });
  }
  ", 
  if (lazy_load_tabs) {
    "
  // Tab-aware rendering: load charts when tab becomes visible
  function initTabAwareLoading() {
    document.querySelectorAll('.panel-tabset').forEach(tabset => {
      const tabs = tabset.querySelectorAll('[role=\"tab\"]');
      
      tabs.forEach(tab => {
        tab.addEventListener('click', function() {
          setTimeout(() => {
            const targetId = this.getAttribute('aria-controls');
            if (!targetId) return;
            
            const targetPanel = document.getElementById(targetId);
            if (!targetPanel) return;
            
            // Initialize any lazy charts in this tab
            const lazyCharts = targetPanel.querySelectorAll('.chart-lazy[data-loaded=\"false\"]');
            lazyCharts.forEach(chart => {
              chartQueue.push(chart);
              observer.unobserve(chart);
            });
            processQueue();
          }, 50);
        });
      });
    });
  }
  "
  } else {
    ""
  },
  "
  // Start lazy loading when document is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initLazyLoading();",
      if (lazy_load_tabs) "
      initTabAwareLoading();" else "",
      "
    });
  } else {
    initLazyLoading();",
    if (lazy_load_tabs) "
    initTabAwareLoading();" else "",
    "
  }
})();
</script>
")
  
  c(
    "",
    "```{=html}",
    skeleton_css,
    "```",
    ""
  )
}

.generate_loading_overlay_chunk <- function(theme = "light", text = "Loading", duration_ms = 2200) {
  c(
    "",
    "```{r, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}",
    "# Use dashboardr's loading overlay function",
    paste0("dashboardr::create_loading_overlay(\"", text, "\", ", duration_ms, ", theme = \"", theme, "\")"),
    "```",
    ""
  )
}


#' Generate SCSS for custom tabset colors
#'
#' Internal helper to generate SCSS code that overrides tabset colors
#'
#' @param colors Named list of color values
#' @return Character vector of SCSS lines
#' @noRd
.generate_tabset_color_scss <- function(colors) {
  scss_lines <- c(
    "/*-- scss:rules --*/",
    "",
    "/* Custom tabset color overrides */",
    ""
  )
  
  # Map color keys to CSS selectors and properties
  if (!is.null(colors$inactive_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item {",
      paste0("  background-color: ", colors$inactive_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$inactive_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item {",
      paste0("  color: ", colors$inactive_text, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$active_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-tabs .nav-link.active {",
      paste0("  background-color: ", colors$active_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$active_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-tabs .nav-link.active {",
      paste0("  color: ", colors$active_text, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$hover_bg)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item:hover {",
      paste0("  background-color: ", colors$hover_bg, " !important;"),
      "}"
    )
  }
  
  if (!is.null(colors$hover_text)) {
    scss_lines <- c(scss_lines,
      ".panel-tabset .nav-item:hover {",
      paste0("  color: ", colors$hover_text, " !important;"),
      "}"
    )
  }
  
  scss_lines
}


#' Generate SCSS for custom theme options
#'
#' Internal helper to generate SCSS code for theme customizations like navbar color
#'
#' @param proj Dashboard project object
#' @return Character vector of SCSS lines
#' @noRd
.generate_theme_custom_scss <- function(proj) {
  scss_lines <- c(
    "/*-- scss:rules --*/",
    "",
    "/* Custom theme overrides */",
    ""
  )
  
  # Navbar background color
  if (!is.null(proj$navbar_bg_color)) {
    scss_lines <- c(scss_lines,
      "/* Custom navbar background color */",
      ".navbar {",
      paste0("  background-color: ", proj$navbar_bg_color, " !important;"),
      "}",
      ""
    )
  }
  
  # Navbar text color
  if (!is.null(proj$navbar_text_color)) {
    scss_lines <- c(scss_lines,
      "/* Custom navbar text color */",
      ".navbar, .navbar a, .navbar .navbar-brand, .navbar .navbar-nav .nav-link {",
      paste0("  color: ", proj$navbar_text_color, " !important;"),
      "}",
      "",
      "/* Navbar icons and SVG elements */",
      ".navbar svg, .navbar .aa-DetachedSearchButton svg, .navbar button svg {",
      paste0("  fill: ", proj$navbar_text_color, " !important;"),
      paste0("  stroke: ", proj$navbar_text_color, " !important;"),
      "}",
      "",
      "/* Navbar search button */",
      ".navbar .aa-DetachedSearchButton, .navbar button {",
      paste0("  color: ", proj$navbar_text_color, " !important;"),
      "}",
      ""
    )
  }
  
  # Navbar text hover color
  if (!is.null(proj$navbar_text_hover_color)) {
    scss_lines <- c(scss_lines,
      "/* Custom navbar text hover color */",
      ".navbar a:hover, .navbar .navbar-brand:hover, .navbar .navbar-nav .nav-link:hover {",
      paste0("  color: ", proj$navbar_text_hover_color, " !important;"),
      "}",
      "",
      "/* Navbar icons and SVG hover */",
      ".navbar a:hover svg, .navbar .aa-DetachedSearchButton:hover svg, .navbar button:hover svg {",
      paste0("  fill: ", proj$navbar_text_hover_color, " !important;"),
      paste0("  stroke: ", proj$navbar_text_hover_color, " !important;"),
      "}",
      ""
    )
  }
  
  scss_lines
}


# ===================================================================
# Custom Progress Display
# ===================================================================

#' Check if any icons are used in the dashboard
#'
#' Internal function to detect if iconify shortcodes are present
#' in the dashboard content.
#'
#' @param proj A dashboard_project object
#' @return Logical indicating if icons are present
#' @keywords internal
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
#' @keywords internal
.install_iconify_extension <- function(output_dir) {
  # Ensure Quarto is discoverable (also checks RStudio-bundled path)
  .find_quarto_path()

  # Check if Quarto is available
  quarto_result <- tryCatch({
    system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    NULL
  })

  if (is.null(quarto_result) || length(quarto_result) == 0) {
    message("Quarto is not installed. Cannot install iconify extension automatically.")
    message("To install Quarto: https://quarto.org/docs/get-started/")
    message("Or install the extension manually:")
    message("  quarto add mcanouil/quarto-iconify")
    return(FALSE)
  }

  # Check if iconify extension is already installed
  iconify_dir <- file.path(output_dir, "_extensions", "mcanouil", "iconify")
  if (dir.exists(iconify_dir) && file.exists(file.path(iconify_dir, "_extension.yml"))) {
    message("Iconify extension already installed")
    return(TRUE)
  }

  # Try to install using Quarto CLI
  tryCatch({
    message("Installing iconify extension using Quarto CLI...")

    # Save current working directory
    old_wd <- getwd()
    setwd(output_dir)
    on.exit(setwd(old_wd), add = TRUE)

    # Use Quarto's official extension installation command
    # The --no-prompt flag avoids interactive prompts
    result <- system2("quarto",
                     c("add", "mcanouil/quarto-iconify", "--no-prompt"),
                     stdout = TRUE,
                     stderr = TRUE)

    # Check for errors
    if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
      warning("Failed to install iconify extension via Quarto CLI")
      message("Output: ", paste(result, collapse = "\n"))
      message("\nTry installing manually from the output directory:")
      message("  cd ", output_dir)
      message("  quarto add mcanouil/quarto-iconify")
      return(FALSE)
    }

    # Verify installation
    if (dir.exists(iconify_dir) && file.exists(file.path(iconify_dir, "_extension.yml"))) {
      message("Iconify extension installed successfully")
      return(TRUE)
    } else {
      warning("Iconify extension files not found after installation")
      message("Please install manually:")
      message("  cd ", output_dir)
      message("  quarto add mcanouil/quarto-iconify")
      return(FALSE)
    }

  }, error = function(e) {
    warning("Failed to install iconify extension: ", e$message)
    message("Please install manually:")
    message("  cd ", output_dir)
    message("  quarto add mcanouil/quarto-iconify")
    return(FALSE)
  })
}
