# Fix: enable_modals not exported error

## Quick Fix

In your R console, run:

```r
# Reload the package
devtools::load_all()

# Or if using installed package, reinstall:
devtools::install()
```

Then re-render your dashboard.

## What Happened

The package documentation was updated. You need to reload/reinstall for the `NAMESPACE` changes to take effect.

## Modern Modal Syntax (2024)

Only these 3 functions are needed:

### 1. `enable_modals()` - Enable modal functionality (once per page)
### 2. Markdown links with `{.modal-link}` class 
### 3. `add_modal()` - Pipeable function to define modals

## Complete Working Example

```r
library(dashboardr)

# Create content with modals
content <- create_content() %>%
  # Enable modals (required once per page)
  add_text(md_text(
    "```{r, echo=FALSE}",
    "dashboardr::enable_modals()",
    "```"
  )) %>%
  
  # Your content with modal link
  add_text(md_text(
    "## Results",
    "",
    "[{{< iconify ph:chart >}} View detailed results](#results-modal){.modal-link}"
  )) %>%
  
  # Define modal - just pipe it!
  add_modal(
    modal_id = "results-modal",
    title = "Detailed Results",
    modal_content = "Your content here..."
  )

# Create dashboard
dashboard <- create_dashboard("my_dash", "output") %>%
  add_page("Home", content = content)

# Generate
generate_dashboard(dashboard)
```

## What's Deprecated (Don't Use)

❌ `quick_modal()` - Use `add_modal()` instead  
❌ `modal_content_md()` - Use `add_modal()` instead  
❌ Non-pipeable syntax - Use pipeable `add_modal()`

## What to Keep Using

✅ `enable_modals()` - Required to activate modals  
✅ `add_modal()` - Modern pipeable function  
✅ `modal_link()` - Optional, for custom HTML  
✅ `modal_content()` - Optional, for custom HTML  
✅ Markdown links: `[Text](#id){.modal-link}`

## Syntax Summary

```r
# Pattern:
create_content() %>%
  add_text(enable_modals()) %>%
  add_text("[Link Text](#modal-id){.modal-link}") %>%
  add_modal(
    modal_id = "modal-id",
    title = "Title",
    modal_content = "Text, HTML, or data.frame"
  )
```

Done!

