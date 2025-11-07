# Modal Functionality in dashboardr

The `dashboardr` package includes built-in modal functionality that allows you to display images, text, and other content in popup overlays instead of navigating to new pages.

## Features

- ✨ **Simple to use** - Just a few functions to create modals
- 🖼️ **Images + Text** - Display images with descriptions
- 📱 **Responsive** - Works on mobile and desktop
- ⌨️ **Keyboard support** - Press ESC to close
- 🎨 **Customizable** - Add custom HTML content
- 🚀 **Zero configuration** - Assets are automatically included

## Quick Start

### 1. Enable Modal Functionality

Add `enable_modals()` to your page content (only needed once per page):

```r
content <- htmltools::tagList(
  enable_modals(),
  # ... rest of your content
)
```

### 2. Create a Modal Link and Content

Use `quick_modal()` for simple cases:

```r
quick_modal(
  link_text = "View Chart",
  modal_id = "my-chart",
  title = "Sales Chart",
  image = "charts/sales.png",
  text = "This chart shows Q4 sales performance."
)
```

### 3. Generate Your Dashboard

The modal assets (CSS and JS) are automatically copied when you generate:

```r
generate_dashboard(dashboard, render = TRUE)
```

## Functions

### `enable_modals()`

Enables modal functionality on a page. Call once per page.

**Returns:** HTML tags that include modal CSS and JavaScript

**Example:**
```r
page_content <- htmltools::tagList(
  enable_modals(),
  htmltools::tags$h1("My Page")
)
```

---

### `modal_link(text, modal_id, class = NULL)`

Creates a clickable link that opens a modal.

**Parameters:**
- `text` - Text to display for the link
- `modal_id` - ID of the modal to open (must match a `modal_content()` ID)
- `class` - Optional CSS classes for styling

**Example:**
```r
modal_link("View Details", "details-modal")
modal_link("Open Chart", "chart1", class = "btn btn-primary")
```

---

### `modal_content(modal_id, ..., title = NULL, image = NULL, text = NULL)`

Defines the content that appears in a modal.

**Parameters:**
- `modal_id` - Unique ID for this modal
- `title` - Optional title displayed at top
- `image` - Optional image URL or path
- `text` - Optional HTML or text content
- `...` - Additional HTML elements

**Example:**
```r
modal_content(
  modal_id = "details-modal",
  title = "Study Details",
  image = "images/methodology.png",
  text = "<p>This study used a mixed-methods approach...</p>"
)
```

---

### `quick_modal(link_text, modal_id, title = NULL, image = NULL, text = NULL, ...)`

Convenience function that creates both the link and content in one call.

**Example:**
```r
quick_modal(
  link_text = "See Results",
  modal_id = "results",
  title = "Study Results",
  image = "results.png",
  text = "<p>Key findings...</p>"
)
```

## Examples

### Simple Text Modal

```r
htmltools::tagList(
  enable_modals(),
  
  htmltools::tags$p(
    "Click ",
    modal_link("here", "info"),
    " for more information."
  ),
  
  modal_content(
    modal_id = "info",
    title = "Additional Information",
    text = "<p>This is some helpful information.</p>"
  )
)
```

### Image with Description

```r
htmltools::tagList(
  enable_modals(),
  
  modal_link("View Visualization", "viz1"),
  
  modal_content(
    modal_id = "viz1",
    title = "Data Visualization",
    image = "charts/distribution.png",
    text = "
      <h3>Key Insights</h3>
      <ul>
        <li>Peak activity at 3pm</li>
        <li>Weekend trends differ significantly</li>
        <li>Seasonal variation observed</li>
      </ul>
    "
  )
)
```

### Multiple Images Side by Side

```r
htmltools::tagList(
  enable_modals(),
  
  modal_link("Compare Charts", "comparison"),
  
  modal_content(
    modal_id = "comparison",
    htmltools::tags$h2("Before and After"),
    htmltools::tags$div(
      style = "display: flex; gap: 10px;",
      htmltools::tags$div(
        style = "flex: 1;",
        htmltools::tags$img(src = "before.png", style = "width: 100%;"),
        htmltools::tags$p("Before intervention")
      ),
      htmltools::tags$div(
        style = "flex: 1;",
        htmltools::tags$img(src = "after.png", style = "width: 100%;"),
        htmltools::tags$p("After intervention")
      )
    )
  )
)
```

### Using in add_text()

You can use modals with `add_text()`:

```r
viz <- create_viz() %>%
  add_text(enable_modals()) %>%
  add_text("
    ## Survey Results
    
    Click to view detailed charts:
    - [Demographics](javascript:void(0)){data-modal='demo-chart'}
    - [Responses](javascript:void(0)){data-modal='response-chart'}
  ") %>%
  add_text(modal_content(
    modal_id = "demo-chart",
    title = "Demographics",
    image = "demo.png"
  ))
```

### In a Full Dashboard

```r
library(dashboardr)

# Create dashboard
dashboard <- create_dashboard(
  name = "my_dashboard",
  output_dir = "output",
  title = "Research Dashboard"
)

# Page content with modals
content <- htmltools::tagList(
  enable_modals(),
  
  htmltools::tags$h2("Study Overview"),
  htmltools::tags$p("Click links below for detailed views:"),
  
  htmltools::tags$ul(
    htmltools::tags$li(modal_link("Methodology", "methods")),
    htmltools::tags$li(modal_link("Results", "results")),
    htmltools::tags$li(modal_link("Conclusions", "conclusions"))
  ),
  
  modal_content(
    modal_id = "methods",
    title = "Methodology",
    image = "methods_diagram.png",
    text = "<p>We used a randomized controlled trial...</p>"
  ),
  
  modal_content(
    modal_id = "results",
    title = "Key Results",
    image = "results_chart.png",
    text = "
      <h3>Findings</h3>
      <ol>
        <li>Significant effect observed (p < 0.001)</li>
        <li>Effect size: Cohen's d = 0.8</li>
      </ol>
    "
  ),
  
  modal_content(
    modal_id = "conclusions",
    title = "Conclusions",
    text = "<p>Our findings suggest...</p>"
  )
)

# Add page
dashboard <- dashboard %>%
  add_page("Overview", content = content, is_landing_page = TRUE)

# Generate
generate_dashboard(dashboard, render = TRUE)
```

## Styling

The modals use clean, modern styling by default. You can customize appearance by:

1. **Override CSS classes** - Add custom styles in your Quarto YAML
2. **Inline styles** - Use the `style` attribute in HTML elements
3. **Custom classes** - Add classes to `modal_link()` for button styling

### Custom Button Styling

```r
# Make the link look like a button
modal_link(
  "View Report", 
  "report",
  class = "btn btn-primary"
)
```

### Custom Modal Content Styling

```r
modal_content(
  modal_id = "styled",
  htmltools::tags$div(
    style = "
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      border-radius: 10px;
    ",
    htmltools::tags$h2("Custom Styled Content"),
    htmltools::tags$p("This modal has custom styling!")
  )
)
```

## Tips

1. **Unique IDs** - Each modal must have a unique `modal_id`
2. **Image paths** - Use relative paths from your dashboard output directory
3. **Large images** - Images are automatically sized to fit the modal
4. **Keyboard shortcuts** - Users can press ESC to close modals
5. **Click outside** - Clicking the dark overlay also closes the modal
6. **Accessibility** - Modals include proper ARIA labels

## Troubleshooting

**Modal doesn't appear:**
- Make sure you called `enable_modals()` on the page
- Check that `modal_id` matches between link and content
- Verify the modal assets were copied (check `output_dir/assets/` folder)

**Image doesn't show:**
- Verify the image path is correct relative to output directory
- Check image file exists in the output directory
- Use browser developer tools to check for 404 errors

**Styling looks wrong:**
- Clear browser cache and reload
- Check for CSS conflicts with custom styles
- Verify modal.css was copied to assets folder

## See Also

- [Demo Example](../examples/modal_demo.R) - Complete working example
- `?enable_modals` - Function documentation
- `?modal_link` - Link creation
- `?modal_content` - Content definition

