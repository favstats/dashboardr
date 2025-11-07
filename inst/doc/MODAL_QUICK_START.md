# Modal Quick Start - Auto-Enabled!

## Super Simple Approach

Just use `add_modal()` - it automatically enables modals for you!

```r
content <- create_content() %>%
  # 1. Add your content with modal link
  add_text("## Results") %>%
  add_text("[View details](#results){.modal-link}") %>%
  
  # 2. Define modal - automatically enables modals!
  add_modal(
    modal_id = "results",
    title = "Detailed Results",
    modal_content = "Full analysis here..."
  )
```

That's it! No `enable_modals()` needed - it's automatic!

## Examples

**Simple text modal:**
```r
create_content() %>%
  add_text("[View info](#info){.modal-link}") %>%
  add_modal(
    modal_id = "info",
    title = "Information",
    modal_content = "Your text here..."
  )
```

**With image:**
```r
create_content() %>%
  add_text("[View chart](#chart){.modal-link}") %>%
  add_modal(
    modal_id = "chart",
    title = "Sales Chart",
    image = "charts/sales.png",
    modal_content = "Chart description"
  )
```

**With data.frame (auto-converts to table!):**
```r
create_content() %>%
  add_text("[View data](#data){.modal-link}") %>%
  add_modal(
    modal_id = "data",
    title = "Raw Data",
    modal_content = head(mtcars)  # Automatically becomes a table!
  )
```

**With custom HTML (if needed):**
```r
create_content() %>%
  add_modal(
    modal_id = "custom",
    modal_content = "<ul><li>Item 1</li><li>Item 2</li></ul>"
  )
```

## Complete Dashboard Example

```r
library(dashboardr)

content <- create_content() %>%
  add_text("## Digital Skills Results") %>%
  add_text("[{{< iconify ph:chart >}} View full results](#results){.modal-link}") %>%
  add_modal(
    modal_id = "results",
    title = "Complete Results",
    modal_content = "Detailed analysis here..."
  )

dashboard <- create_dashboard("my_dash", "output") %>%
  add_page("Home", content = content)

generate_dashboard(dashboard)
```

Modals are automatically enabled when you use `add_modal()`!

## That's It!

✓ Pure R - no HTML/JS needed  
✓ Markdown links work naturally  
✓ Auto-converts data.frames to tables  
✓ HTML/JS available if you want it  

## Your Use Case Example

```r
content <- create_content() %>%
  add_text(md_text(
    "```{r, echo=FALSE, message=FALSE, warning=FALSE}",
    "create_blockquote('Which icon is for cropping?', preset = 'question')",
    "```",
    "",
    "[{{< iconify ph:cards >}} See all Digital Content Creation results](#dcc-results){.modal-link}"
  )) %>%
  add_modal(
    modal_id = "dcc-results",
    title = "Digital Content Creation - Full Results",
    modal_content = "Your detailed results here..."
  )
```

Done! That's all you need. Modals are automatically enabled!

