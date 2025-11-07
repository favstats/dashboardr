#!/usr/bin/env Rscript
# SIMPLEST Modal Example - Pure R Approach
# No HTML/JS needed - just R functions and markdown

library(dashboardr)

data <- mtcars

# ============================================================================
# SIMPLEST SYNTAX - Pipeable add_modal() with AUTO MODAL ENABLING!
# ============================================================================
# No need to manually call enable_modals() - add_modal() does it automatically!

all_content <- create_content() %>%
  # Your page content with modal links
  add_text(md_text(
    "## Digital Skills Survey Results",
    "",
    "### Question 1: Content Creation",
    "",
    "Which of the following icons refer to cropping an image?",
    "",
    "[{{< iconify ph:cards >}} See all Digital Content Creation results](#content-creation){.modal-link}",
    "",
    "---",
    "",
    "### Question 2: Information Skills", 
    "",
    "How do you evaluate source credibility?",
    "",
    "[{{< iconify ph:magnifying-glass >}} View Information Skills results](#info-skills){.modal-link}",
    "",
    "---",
    "",
    "### Raw Data",
    "",
    "[{{< iconify ph:table >}} View complete dataset](#raw-data){.modal-link}"
  )) %>%
  
  # Modal 1: Simple text
  add_modal(
    modal_id = "content-creation",
    title = "Digital Content Creation - Full Results",
    modal_content = "Participants scored 78% on content creation tasks. 
                     This included image editing (80%), document formatting (82%), 
                     and video creation (62%). Most participants showed strong 
                     proficiency with basic tools but struggled with advanced features."
  ) %>%
  
  # Modal 2: With image
  add_modal(
    modal_id = "info-skills",
    title = "Information Skills Results", 
    image = "https://via.placeholder.com/800x300.png?text=Info+Skills+Chart",
    modal_content = "Information literacy scores were highest at 85%.
                     Participants excelled at search strategies and
                     source evaluation."
  ) %>%
  
  # Modal 3: With data.frame (auto-converts to table!)
  add_modal(
    modal_id = "raw-data",
    title = "Raw Data",
    modal_content = head(mtcars, 10)
  )

# ============================================================================
# STEP 4: Create dashboard as usual
# ============================================================================

dashboard <- create_dashboard(
  name = "modal_r_first",
  output_dir = tempfile(),
  title = "R-First Modal Example",
  allow_inside_pkg = TRUE
) %>%
  add_page(
    name = "Survey",
    data = data,
    content = all_content,
    is_landing_page = TRUE
  )

# Generate
cat("\n")
cat("================================================\n")
cat("  SIMPLEST MODAL SYNTAX - AUTO-ENABLED!\n")
cat("================================================\n\n")
cat("1. Add markdown link:\n")
cat("   [Link Text](#modal-id){.modal-link}\n\n")
cat("2. Define modal in pure R:\n")
cat("   add_modal(\n")
cat("     modal_id = 'modal-id',\n")
cat("     title = 'Title',\n")
cat("     modal_content = 'Your text or data.frame'\n")
cat("   )\n\n")
cat("That's it! Modals are automatically enabled.\n\n")
cat("================================================\n\n")

generate_dashboard(dashboard, render = TRUE, open = "browser")

cat("\n✓ Done! Click the links to see modals\n\n")

