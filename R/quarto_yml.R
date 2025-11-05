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
    # Skip landing page as it becomes "Home"
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

  # Add Home link if there's a landing page (only if not using navbar sections)
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
    # Collect pages that are in menus or sidebars
    pages_in_sections <- character(0)
    
    # Hybrid navigation mode - add navbar sections that link to sidebar groups
    for (section in proj$navbar_sections) {
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
            page_text_content <- paste0("\"", page_name, "\"")
            if (!is.null(page$icon)) {
              page_icon <- if (grepl("{{< iconify", page$icon, fixed = TRUE)) {
                page$icon
              } else {
                icon(page$icon)
              }
              page_text_content <- paste0("\"", page_icon, " ", page_name, "\"")
            }
            
            yaml_lines <- c(yaml_lines,
              paste0("          - href: ", page_qmd),
              paste0("            text: ", page_text_content)
            )
          }
        }
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
    
    # Now add any left-aligned pages that are NOT in any menu or sidebar
    for (page_name in names(pages_left)) {
      if (!page_name %in% pages_in_sections) {
        page <- pages_left[[page_name]]
        
        # Use lowercase with underscores for filenames
        filename <- tolower(gsub("[^a-zA-Z0-9]", "_", page_name))
        
        # Build text with icon if provided
        text_content <- paste0("\"", page_name, "\"")
        if (!is.null(page$icon)) {
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
  } else {
    # Simple navigation mode - add left-aligned pages
    for (page_name in names(pages_left)) {
      page <- pages_left[[page_name]]

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

  # Add right section if we have right-aligned pages OR tools
  if (has_right_pages || length(tools) > 0) {
    yaml_lines <- c(yaml_lines, "    right:")
    
    # First, add right-aligned pages
    if (has_right_pages) {
      for (page_name in names(pages_right)) {
        page <- pages_right[[page_name]]

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
    
    # Then, add tools
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

  # Add format section with theme and SCSS
  yaml_lines <- c(yaml_lines,
    "",
    "format:",
    "  html:",
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
  
  # Add custom SCSS if provided
  if (!is.null(proj$custom_scss)) {
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_scss))
  }
  
  yaml_lines <- c(yaml_lines, "")

  # Add custom CSS if provided
  if (!is.null(proj$custom_css)) {
    yaml_lines <- c(yaml_lines, "    css:")
    yaml_lines <- c(yaml_lines, paste0("      - ", proj$custom_css))
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
        
        console.log(`📊 Chart loaded: ${chartId} (${loadTime.toFixed(2)}ms)`);
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
      console.log(`⚡ Processing batch of ${batch.length} charts (${chartQueue.length} remaining)`);
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
        console.log(`✅ All charts loaded! Summary:`);
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
    paste0("dashboardr::add_loading_overlay(\"", text, "\", ", duration_ms, ", theme = \"", theme, "\")"),
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

# ===================================================================
# Custom Progress Display
# ===================================================================

#' Show custom progress message
#'
#' @param msg Message to display
#' @param icon Emoji or symbol to prefix
#' @param show_progress Whether to show progress


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


#' Install iconify extension automatically
#'
#' Downloads and installs the official iconify extension to the project directory
#' if icons are detected in the dashboard.
#'
#' @param output_dir The dashboard output directory
#' @return Logical indicating if installation was successful
#' @keywords internal
.install_iconify_extension <- function(output_dir) {
  # Check if Quarto is available
  quarto_result <- tryCatch({
    system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
  }, error = function(e) {
    NULL
  })

  if (is.null(quarto_result) || length(quarto_result) == 0) {
    warning("Quarto is not installed. Cannot install iconify extension automatically.")
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


