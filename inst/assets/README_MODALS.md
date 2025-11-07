# Modal System for dashboardr

This directory contains the modal functionality assets for dashboardr.

## Files

- **modal.css** - Styling for the modal overlay and content
- **modal.js** - JavaScript to handle modal open/close interactions

## How It Works

1. When `generate_dashboard()` runs, these files are automatically copied to `output_dir/assets/`
2. Users call `enable_modals()` in their page content (once per page)
3. Users create markdown links with `{.modal-link}` class
4. Users define modals with pipeable `add_modal()` function
5. JavaScript watches for clicks on `.modal-link` elements and opens the corresponding modal

## Features

- Click link → open modal (no page navigation)
- ESC key or click overlay → close modal
- Responsive (works on mobile and desktop)
- Auto-converts data.frames to HTML tables
- Smooth fade-in animation
- Centered and scrollable for long content
- Fully pipeable R syntax

## Modern Usage (2024)

```r
# Pipeable approach - recommended!
content <- create_content() %>%
  add_text(md_text(
    "```{r, echo=FALSE}",
    "dashboardr::enable_modals()",
    "```"
  )) %>%
  add_text("[Click me](#my-modal){.modal-link}") %>%
  add_modal(
    modal_id = "my-modal",
    title = "Hello!",
    modal_content = "This is the modal content."
  )
```

## Markdown Link Syntax

Links need the `{.modal-link}` class:

```markdown
[Link Text](#modal-id){.modal-link}
[{{< iconify ph:chart >}} View Chart](#chart-modal){.modal-link}
```

## Documentation

See:
- `/inst/doc/MODAL_FIX.md` - Quick fix guide
- `/inst/doc/MODAL_QUICK_START.md` - Quick start guide
- `/inst/examples/YOUR_USE_CASE.R` - Your exact use case
- `/inst/examples/modal_r_first.R` - R-first approach
- `?add_modal` - R help documentation

