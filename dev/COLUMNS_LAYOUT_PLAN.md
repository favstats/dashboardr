# Add Columns Layout Implementation Plan

## 🎯 Goal
Implement `add_columns()` for multi-column layouts that work seamlessly with the pipeable dashboardr syntax.

## 🤔 Design Considerations

### 1. **Syntax Options**

#### Option A: Nested Content (Recommended)
```r
content <- create_content() %>%
  add_columns(
    widths = c(8, 4),  # Bootstrap 12-column grid (8+4=12)
    column1 = create_content() %>%
      add_text("Main content here") %>%
      add_viz(viz_collection = my_viz),
    column2 = create_content() %>%
      add_metric(value = "1,234", title = "Total Users") %>%
      add_callout("Important note", type = "warning")
  )
```

**Pros:**
- Most flexible - can nest any content type
- Clear column structure
- Supports variable column counts (2, 3, 4 columns)
- Works with existing content_collection system

**Cons:**
- Slightly more verbose
- Requires naming columns

#### Option B: List-Based (Alternative)
```r
content <- create_content() %>%
  add_columns(
    widths = c(6, 6),
    list(
      add_text("Column 1"),
      add_viz(viz_collection = viz1)
    ),
    list(
      add_text("Column 2"),
      add_metric(value = "42", title = "Score")
    )
  )
```

**Pros:**
- Slightly more compact
- No need to name columns

**Cons:**
- Less explicit structure
- Harder to reference specific columns

### 2. **Column Width System**

Use Bootstrap's 12-column grid (most compatible with Quarto):

| Columns | Typical Widths | Use Case |
|---------|---------------|----------|
| 2 cols  | `c(6, 6)` | Equal split |
| 2 cols  | `c(8, 4)` | Main + sidebar |
| 2 cols  | `c(9, 3)` | Wide main + narrow sidebar |
| 3 cols  | `c(4, 4, 4)` | Equal thirds |
| 3 cols  | `c(6, 3, 3)` | Wide left + two narrow |
| 4 cols  | `c(3, 3, 3, 3)` | Equal quarters |

**Alternative:** Named presets for common layouts:
```r
add_columns(layout = "main_sidebar", ...)  # 8-4 split
add_columns(layout = "equal_2", ...)       # 6-6 split
add_columns(layout = "equal_3", ...)       # 4-4-4 split
```

### 3. **Responsive Behavior**

On small screens, columns should stack vertically automatically.

**Implementation:**
- Use Quarto's native column divs: `::: {.column width="50%"}`
- Or Bootstrap: `<div class="col-md-6">`
- Include responsive classes: `col-12 col-md-8` (full width on mobile, 8/12 on desktop)

### 4. **Nested Columns**

Should we support nesting columns within columns?

**Example:**
```r
add_columns(
  widths = c(8, 4),
  column1 = create_content() %>%
    add_text("Main area") %>%
    add_columns(  # Nested!
      widths = c(6, 6),
      ...
    ),
  column2 = create_content() %>%
    add_text("Sidebar")
)
```

**Decision:** Start simple (no nesting), add later if needed.

## 📋 Implementation Steps

### Step 1: Create `add_columns()` Function

**Location:** `R/content_collection.R`

```r
#' Add multi-column layout
#'
#' Creates a responsive multi-column layout. Columns automatically stack on small screens.
#'
#' @param content Content collection object
#' @param widths Numeric vector of column widths (must sum to 12 for Bootstrap grid)
#' @param ... Named arguments for each column (column1, column2, etc.)
#'   Each should be a content_collection object created with create_content()
#' @param gap Gap between columns (CSS value, default "1.5rem")
#' @param vertical_align Vertical alignment: "top", "center", "bottom", default "top"
#' @export
#' @examples
#' \dontrun{
#' content <- create_content() %>%
#'   add_columns(
#'     widths = c(8, 4),
#'     column1 = create_content() %>%
#'       add_text("Main content") %>%
#'       add_viz(viz_collection = my_viz),
#'     column2 = create_content() %>%
#'       add_metric(value = "1,234", title = "Users") %>%
#'       add_callout("Note", type = "info")
#'   )
#' }
add_columns <- function(content, widths, ..., gap = "1.5rem", vertical_align = "top") {
  # Validation
  if (!inherits(content, "content_collection")) {
    stop("First argument must be a content_collection object")
  }
  
  columns_content <- list(...)
  
  if (length(columns_content) != length(widths)) {
    stop("Number of columns must match length of widths vector")
  }
  
  if (sum(widths) != 12) {
    stop("Column widths must sum to 12 (Bootstrap grid system)")
  }
  
  # Validate that each column is a content_collection
  for (i in seq_along(columns_content)) {
    if (!inherits(columns_content[[i]], "content_collection")) {
      stop(paste0("Column ", i, " must be a content_collection object (use create_content())"))
    }
  }
  
  columns_block <- structure(list(
    type = "columns",
    widths = widths,
    columns = columns_content,
    gap = gap,
    vertical_align = vertical_align
  ), class = "content_block")
  
  content$items <- c(content$items, list(columns_block))
  content
}
```

### Step 2: Create Rendering Function

**Location:** `R/page_generation.R`

```r
#' Generate columns block markdown
#'
#' Internal function to generate markdown for multi-column layouts
#'
#' @param block Columns content block
#' @return Character vector of markdown lines
#' @keywords internal
.generate_columns_block <- function(block) {
  align_class <- switch(block$vertical_align,
    "center" = "align-items-center",
    "bottom" = "align-items-end",
    "top" = "align-items-start",
    "align-items-start"
  )
  
  lines <- c(
    "",
    paste0("<div class='row ", align_class, "' style='gap: ", block$gap, ";'>")
  )
  
  for (i in seq_along(block$columns)) {
    width <- block$widths[i]
    col_content <- block$columns[[i]]
    
    # Start column div with responsive classes
    lines <- c(
      lines,
      paste0("  <div class='col-12 col-md-", width, "'>")
    )
    
    # Recursively render each content item in the column
    for (item in col_content$items) {
      if (inherits(item, "content_block")) {
        # Generate content for this block
        item_lines <- switch(item$type,
          "text" = c("", item$content, ""),
          "image" = .generate_image_block(item),
          "callout" = .generate_callout_block(item),
          "divider" = .generate_divider_block(item),
          "code" = .generate_code_block(item),
          "card" = .generate_card_block(item),
          "metric" = .generate_metric_block(item),
          "value_box" = .generate_value_box_block(item),
          "badge" = .generate_badge_block(item),
          "spacer" = .generate_spacer_block(item),
          # Add other types as needed
          NULL
        )
        if (!is.null(item_lines)) {
          lines <- c(lines, paste0("    ", item_lines))
        }
      } else if (!is.null(item$type) && item$type == "viz") {
        # This is a visualization - need to generate it
        # This gets complex - may need to call viz generation functions
        # For now, add a placeholder/note
        lines <- c(lines, "    <!-- Visualization goes here -->")
      }
    }
    
    # Close column div
    lines <- c(lines, "  </div>")
  }
  
  lines <- c(lines, "</div>", "")
  lines
}
```

### Step 3: Add to Switch Statement

In `page_generation.R`, add to the main switch:
```r
"columns" = .generate_columns_block(block),
```

### Step 4: Update Print Method

In `print.content_collection` (or `print.viz_collection`), add display for columns:
```r
if (item$type == "columns") {
  n_cols <- length(item$columns)
  widths_str <- paste(item$widths, collapse = "-")
  cat(sprintf("  %s. [columns]: %d columns (%s)\n", idx, n_cols, widths_str))
}
```

## 🧪 Testing Strategy

### Test 1: Basic Two-Column Layout
```r
test_that("add_columns creates valid two-column layout", {
  content <- create_content() %>%
    add_columns(
      widths = c(6, 6),
      column1 = create_content() %>% add_text("Left"),
      column2 = create_content() %>% add_text("Right")
    )
  
  expect_s3_class(content, "content_collection")
  expect_equal(length(content$items), 1)
  expect_equal(content$items[[1]]$type, "columns")
  expect_equal(content$items[[1]]$widths, c(6, 6))
  expect_equal(length(content$items[[1]]$columns), 2)
})
```

### Test 2: Three-Column Layout
```r
test_that("add_columns works with three columns", {
  content <- create_content() %>%
    add_columns(
      widths = c(4, 4, 4),
      column1 = create_content() %>% add_text("A"),
      column2 = create_content() %>% add_text("B"),
      column3 = create_content() %>% add_text("C")
    )
  
  expect_equal(length(content$items[[1]]$columns), 3)
})
```

### Test 3: Width Validation
```r
test_that("add_columns validates width sum", {
  expect_error(
    create_content() %>%
      add_columns(
        widths = c(6, 8),  # Sum is 14, not 12!
        column1 = create_content(),
        column2 = create_content()
      ),
    "must sum to 12"
  )
})
```

### Test 4: Column Count Validation
```r
test_that("add_columns validates column count matches widths", {
  expect_error(
    create_content() %>%
      add_columns(
        widths = c(6, 6),  # 2 widths
        column1 = create_content()  # Only 1 column!
      ),
    "Number of columns must match"
  )
})
```

### Test 5: Rendering Test
```r
test_that("columns render to proper HTML structure", {
  content <- create_content() %>%
    add_columns(
      widths = c(8, 4),
      column1 = create_content() %>% add_text("Main"),
      column2 = create_content() %>% add_text("Sidebar")
    )
  
  # Create a test page and render
  # Check for Bootstrap row/col classes
  # Verify content appears in correct columns
})
```

## 🎨 Usage Examples

### Example 1: Classic Main + Sidebar
```r
dashboard <- create_dashboard(...) %>%
  add_page(
    name = "Analysis",
    content = create_content() %>%
      add_text(md_text("# Data Analysis")) %>%
      add_columns(
        widths = c(8, 4),
        column1 = create_content() %>%
          add_text("Main analysis content") %>%
          add_viz(viz_collection = analysis_viz) %>%
          add_text("Additional insights"),
        column2 = create_content() %>%
          add_metric(value = "1,234", title = "Total Records") %>%
          add_metric(value = "98%", title = "Quality Score") %>%
          add_callout("Data updated daily", type = "info")
      )
  )
```

### Example 2: Three Equal Columns for Comparison
```r
content <- create_content() %>%
  add_text(md_text("# Regional Comparison")) %>%
  add_columns(
    widths = c(4, 4, 4),
    column1 = create_content() %>%
      add_text("### North Region") %>%
      add_metric(value = "$1.2M", title = "Revenue") %>%
      add_viz(viz_collection = north_viz),
    column2 = create_content() %>%
      add_text("### Central Region") %>%
      add_metric(value = "$980K", title = "Revenue") %>%
      add_viz(viz_collection = central_viz),
    column3 = create_content() %>%
      add_text("### South Region") %>%
      add_metric(value = "$1.5M", title = "Revenue") %>%
      add_viz(viz_collection = south_viz)
  )
```

### Example 3: Four-Column Grid for Metrics
```r
content <- create_content() %>%
  add_text(md_text("# Dashboard Overview")) %>%
  add_columns(
    widths = c(3, 3, 3, 3),
    column1 = create_content() %>%
      add_metric(value = "1,234", title = "Users", icon = "ph:users"),
    column2 = create_content() %>%
      add_metric(value = "€56K", title = "Revenue", icon = "ph:currency-euro"),
    column3 = create_content() %>%
      add_metric(value = "+23%", title = "Growth", icon = "ph:trend-up"),
    column4 = create_content() %>%
      add_metric(value = "4.8/5", title = "Rating", icon = "ph:star")
  ) %>%
  add_divider() %>%
  add_text("Detailed analysis below...")
```

## 🚀 Alternative: Quarto-Native Approach

Instead of Bootstrap, could use Quarto's native column syntax:

```markdown
:::: {.columns}
::: {.column width="60%"}
Left column content
:::

::: {.column width="40%"}
Right column content
:::
::::
```

**Pros:**
- More Quarto-idiomatic
- Better Quarto integration
- Simpler HTML output

**Cons:**
- Less control over responsive behavior
- Harder to add custom styling

**Recommendation:** Use Quarto-native approach for better compatibility!

## 📝 Additional Considerations

1. **Gap Control:** Allow users to specify gap between columns
2. **Vertical Alignment:** Support `top`, `center`, `bottom` alignment
3. **Background Colors:** Optional background colors per column
4. **Mobile Behavior:** Ensure columns stack nicely on mobile
5. **Print Styles:** Make sure columns print well
6. **Accessibility:** Ensure screen readers handle column structure properly

## 🎯 Implementation Priority

1. **Phase 1 (MVP):**
   - Basic 2-3 column layouts
   - Equal and unequal widths
   - Text and metric content only

2. **Phase 2 (Full Features):**
   - Support all content types (viz, images, tables, etc.)
   - Custom gap and alignment
   - 4+ columns

3. **Phase 3 (Advanced):**
   - Nested columns
   - Background colors and borders
   - Custom CSS classes

## 💡 Summary

**Recommended Approach:**
1. Use named column syntax: `column1 = create_content() %>% ...`
2. Bootstrap 12-column grid for width specification
3. Responsive by default (stack on mobile)
4. Start with 2-3 columns, expand to 4+
5. Test-driven development (write tests first!)

**Key Challenge:** Rendering nested content_collection objects requires careful recursion in the generation function.

**Estimated Complexity:** Medium-High (requires recursion, careful HTML structure)

**Estimated Time:** 3-4 hours for MVP, 6-8 hours for full features

