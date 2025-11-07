#!/usr/bin/env Rscript
# YOUR EXACT USE CASE - Simplest Possible Syntax
# This is how you would use modals in your actual dashboard

library(dashboardr)

# Sample data
data <- mtcars

# ============================================================================
# EXACTLY WHAT YOU ASKED FOR - SUPER SIMPLE NOW!
# ============================================================================
# No need to manually enable modals - add_modal() does it automatically!

all_content <- create_content() %>%
  # Your original content with modal link
  add_text(md_text(
    "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
    "create_blockquote('Which of the following icons refer to the function for cutting or removing parts of a picture (\\\"cropping\\\")?', preset = 'question')",
    "```",
    "",
    "[{{< iconify ph:cards >}} See all Digital Content Creation results](#digital-content-creation){.modal-link}"
  )) %>%
  
  # Define the modal - add_modal() automatically enables modals!
  add_modal(
    modal_id = "digital-content-creation",
    title = "Digital Content Creation - Complete Results",
    modal_content = "Participants scored 78% overall on digital content creation tasks.
                     
                     Key findings:
                     - Image editing (cropping, resizing): 82% correct
                     - Document formatting: 75% correct  
                     - Video editing: 71% correct
                     
                     The cropping icon question specifically had 88% correct answers,
                     indicating strong familiarity with basic image editing tools."
  )

# That's it! Create dashboard as usual
dashboard <- create_dashboard(
  name = "your_dashboard",
  output_dir = tempfile(),
  title = "Digital Skills Survey",
  allow_inside_pkg = TRUE
) %>%
  add_page(
    name = "Results",
    data = data,
    content = all_content,
    is_landing_page = TRUE
  )

generate_dashboard(dashboard, render = TRUE, open = "browser")

# ============================================================================
# MORE EXAMPLES YOU CAN USE
# ============================================================================

# With image
example_with_image <- create_content() %>%
  add_text("[View chart](#chart-modal){.modal-link}") %>%
  add_modal(
    modal_id = "chart-modal",
    title = "Performance Chart",
    image = "path/to/chart.png",
    modal_content = "This chart shows the distribution of scores."
  )

# With data.frame (auto-converts to HTML table!)
example_with_data <- create_content() %>%
  add_text("[View raw data](#data-modal){.modal-link}") %>%
  add_modal(
    modal_id = "data-modal", 
    title = "Raw Data",
    modal_content = head(mtcars, 10)  # Automatically becomes a nice table!
  )

# With custom HTML if you need it
example_with_html <- create_content() %>%
  add_modal(
    modal_id = "custom",
    modal_content = "<ul><li>Point 1</li><li>Point 2</li></ul>"
  )

cat("\n")
cat("==============================================\n")
cat("  ✓ YOUR USE CASE IS READY\n")
cat("==============================================\n\n")
cat("SUPER SIMPLE SYNTAX (AUTO-ENABLED!):\n\n")
cat("create_content() %>%\n")
cat("  add_text('[Link](#id){.modal-link}') %>%\n")
cat("  add_modal(modal_id = 'id', ...)\n\n")
cat("That's it! Modals auto-enable when you use add_modal().\n")
cat("Pure R, fully pipeable, zero boilerplate.\n\n")

