# Demo: Content Blocks and Flexible Text Positioning
# Showcases all the new features added to dashboardr
#
# Run with: Rscript -e "devtools::load_all(); source('dev/demo_content_blocks.R')"
# Or from R console: devtools::load_all(); source('dev/demo_content_blocks.R')

devtools::load_all()
# library(dashboardr)
# library(dplyr)

# Create sample data
set.seed(123)
survey_data <- data.frame(
  age = sample(18:65, 500, replace = TRUE),
  satisfaction = sample(c("Very Satisfied", "Satisfied", "Neutral", "Dissatisfied", "Very Dissatisfied"),
                       500, replace = TRUE),
  department = sample(c("Sales", "Engineering", "Marketing", "Support"), 500, replace = TRUE),
  years = sample(1:20, 500, replace = TRUE)
)

# =============================================================================
# Demo 1: Enhanced text positioning in add_viz
# =============================================================================

viz_with_text_positioning <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "age",
    title = "Age Distribution Analysis",
    tabgroup = "demographics",

    # NEW: Text above the title/header
    text_above_title = md_text(
      "### Survey Context",
      "",
      "This section analyzes respondent demographics from our Q4 2024 survey."
    ),

    # NEW: Text above the tabset (only shows when tabgroup is used)
    text_above_tabs = md_text(
      "The following visualizations break down our data by key demographic factors.",
      "Click through the tabs to explore different dimensions."
    ),

    # NEW: Text above the graph itself
    text_above_graphs = "**Figure 1:** Distribution shows a balanced age range across respondents.",

    # NEW: Text below the graph
    text_below_graphs = md_text(
      "*Note: Sample size n=500. Data collected Oct-Dec 2024.*",
      "",
      "Key takeaway: Our respondent pool adequately represents all age groups."
    )
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "years",
    title = "Years of Experience",
    tabgroup = "demographics",

    text_above_graphs = "**Figure 2:** Experience levels vary significantly across departments.",
    text_below_graphs = "*Average experience: 8.5 years (SD: 5.2)*"
  )

# =============================================================================
# Demo 2: Using create_content() for pipeable syntax
# =============================================================================
# The new pipeable syntax makes content composition natural and readable!

# =============================================================================
# Demo 3: Create the dashboard
# =============================================================================

# Create the dashboard
dashboard <- create_dashboard(
  output_dir = "content_blocks_demo",
  title = "Content Blocks Demo Dashboard",
  author = "dashboardr Team",
  description = "Demonstrating flexible content blocks and text positioning",
  search = TRUE,
  tabset_theme = "modern",
  allow_inside_pkg = TRUE
)

# Landing page with mixed content
# NEW PIPEABLE SYNTAX!
home_content <- create_content() %>%
  add_image(src = "https://picsum.photos/id/180/200/80",
            alt = "Dashboard Banner",
            align = "center",
            width = "200px") %>%
  add_text(md_text(
    "# Welcome to the Content Blocks Demo",
    "",
    "This dashboard demonstrates the new **flexible content system** in dashboardr.",
    "",
    "## Key Features",
    "",
    "- **Text Positioning**: Control exactly where text appears relative to visualizations",
    "- **Text Blocks**: Add standalone markdown content anywhere",
    "- **Image Blocks**: Include images with captions, sizing, and alignment",
    "- **Mixed Content**: Combine text, images, and visualizations freely",
    "- **Pipeable Syntax**: Chain content with %>% operator!",
    "",
    "Let's explore each feature below!"
  )) %>%
  add_image(src = "https://picsum.photos/id/1002/600/400",
            alt = "Data Analysis Concept",
            caption = "Figure A: Modern data visualization enables better insights and decision-making",
            width = "600px",
            align = "center",
            link = "https://dashboardr.org") %>%
  add_text(md_text(
    "---",
    "",
    "Use the navigation menu above to explore the full dashboard."
  ))

dashboard <- dashboard %>%
  add_page(
    name = "Home",
    is_landing_page = TRUE,
    icon = "ph:house",
    content = home_content
  )

# Analysis page with visualizations and surrounding context
# NEW PIPEABLE SYNTAX - pipe directly from viz!
page_content <- viz_with_text_positioning %>%
  add_text(md_text(
    "# Respondent Demographics",
    "",
    "Understanding who participated in our survey is crucial for interpreting results."
  )) %>%
  add_text(md_text(
    "## Interpretation",
    "",
    "The age distribution shows a well-balanced sample across all age groups,",
    "ensuring our findings represent diverse perspectives.",
    "",
    "Experience levels correlate strongly with age, as expected."
  ))

dashboard <- dashboard %>%
  add_page(
    name = "Demographics Analysis",
    data = survey_data,
    icon = "ph:users-three",
    content = page_content
  )

# Methodology page with text and images
# 🎉 NEW PIPEABLE SYNTAX!
methodology_content <- create_content() %>%
  add_text(md_text(
    "## Methodology",
    "",
    "Data was collected through an online survey platform with the following parameters:",
    "",
    "- **Sample Size**: 500 respondents",
    "- **Duration**: October - December 2024",
    "- **Sampling Method**: Stratified random sampling",
    "- **Response Rate**: 68.5%"
  )) %>%
  add_spacer(height = "1rem") %>%
  add_callout(
    "**Important**: All data was anonymized and handled in compliance with GDPR and institutional ethics guidelines.",
    type = "important",
    title = "Ethics & Privacy"
  ) %>%
  add_spacer(height = "1.5rem") %>%
  add_image(src = "https://picsum.photos/id/119/300/200",
            alt = "Research and Development",
            caption = "Our research methodology follows best practices in data science",
            width = "300px",
            align = "right") %>%
  add_text(md_text(
    "### Data Quality Assurance",
    "",
    "All responses underwent rigorous quality checks:",
    "",
    "1. **Completeness**: Removed responses with >20% missing data",
    "2. **Consistency**: Validated response patterns for logical consistency",
    "3. **Duplication**: Checked for and removed duplicate entries",
    "4. **Outliers**: Investigated extreme values for data entry errors"
  )) %>%
  add_divider() %>%
  add_callout(
    "The survey achieved a 68.5% response rate, exceeding our target of 60%.",
    type = "tip",
    title = "High Response Rate"
  )

dashboard <- dashboard %>%
  add_page(
    name = "Methodology",
    icon = "ph:flask",
    content = methodology_content
  )

# NEW! Advanced Content Types page - showcasing all new features
advanced_content <- create_content() %>%
  add_text(md_text(
    "# Advanced Content Types",
    "",
    "Dashboardr now supports a rich ecosystem of content types!"
  )) %>%
  add_spacer(height = "2rem") %>%

  # Callout boxes
  add_text("## Callout Boxes") %>%
  add_callout("This is a note callout - perfect for general information.", type = "note", title = "Note") %>%
  add_spacer(height = "0.5rem") %>%
  add_callout("Tips provide helpful suggestions to your readers.", type = "tip", title = "Pro Tip") %>%
  add_spacer(height = "0.5rem") %>%
  add_callout("Warning! Use this for cautionary information.", type = "warning", title = "Warning") %>%
  add_spacer(height = "0.5rem") %>%
  add_callout("Important information that shouldn't be missed.", type = "important", title = "Critical") %>%
  add_spacer(height = "2rem") %>%

  # Dividers
  add_text("## Visual Dividers") %>%
  add_text("Dividers help separate sections:") %>%
  add_spacer(height = "0.5rem") %>%
  add_text("*Content above divider*") %>%
  add_divider() %>%
  add_text("*Content below divider*") %>%
  add_spacer(height = "2rem") %>%

  # Code blocks
  add_text("## Code Blocks") %>%
  add_text("Share code with syntax highlighting:") %>%
  add_code(
    code = "# Create a beautiful dashboard\ndashboard <- create_dashboard('my_dashboard', 'My Dashboard')\n\n# Add content with the new pipeable syntax\ncontent <- create_content() %>%\n  add_text('# Welcome!') %>%\n  add_viz(type = 'histogram', x_var = 'age')\n\ndashboard %>%\n  add_page('Analysis', content = content) %>%\n  generate_dashboard()",
    language = "r",
    caption = "Example: Creating a dashboard with the new syntax",
    filename = "example.R"
  ) %>%
  add_spacer(height = "2rem") %>%

  # Cards
  add_text("## Content Cards") %>%
  add_card(
    title = "Feature Highlight",
    text = "Content cards are perfect for highlighting key information or creating visually distinct sections in your dashboard."
  ) %>%
  add_spacer(height = "2rem") %>%

  # Actual iframe example
  add_text("## Embedded Content") %>%
  add_text("Embed external websites directly into your dashboard:") %>%
  add_spacer(height = "0.5rem") %>%
  add_iframe("https://www.openstreetmap.org/export/embed.html?bbox=-0.004017949104309083%2C51.47612752641776%2C0.00030577182769775396%2C51.478569861898606&layer=mapnik",
             height = "400px", width = "100%") %>%
  add_spacer(height = "1rem") %>%
  add_text("### Video Embeds") %>%
  add_text("YouTube videos work seamlessly:") %>%
  add_spacer(height = "0.5rem") %>%
  add_video("https://www.youtube.com/watch?v=dQw4w9WgXcQ", height = "315px") %>%
  add_spacer(height = "2rem") %>%

  # Accordion
  add_text("## Collapsible Sections") %>%
  add_accordion(
    title = "Click to expand: Technical Details",
    text = md_text(
      "### Implementation Details",
      "",
      "The content system uses a unified architecture where:",
      "",
      "- All content types are stored in a single `$items` list",
      "- Each item has a `type` field (viz, text, image, callout, etc.)",
      "- Content can be composed using the `%>%` operator",
      "- Both `create_viz()` and `create_content()` are aliases",
      "",
      "This makes it incredibly flexible and intuitive!"
    )
  ) %>%
  add_spacer(height = "2rem")

# Create table objects BEFORE the pipeline (cleaner & shows full power!)

# Simple kable data
simple_table_data <- head(mtcars[, 1:5], 5)

# DT with custom styling - pass the STYLED object!
if (requireNamespace("DT", quietly = TRUE)) {
  dt_table <- DT::datatable(
    head(mtcars, 10),
    options = list(
      pageLength = 5,
      scrollX = TRUE,
      dom = 'Bfrtip'
    ),
    filter = 'top',
    class = 'cell-border stripe'
  )
} else {
  dt_table <- head(mtcars, 10)
}

# GT with actual styling - pass the STYLED object!
viz_comparison_data <- data.frame(
  Package = c("ggplot2", "plotly", "highcharter"),
  Type = c("Static", "Interactive", "Interactive"),
  Popularity = c("⭐⭐⭐⭐⭐", "⭐⭐⭐⭐", "⭐⭐⭐⭐"),
  Best_For = c("Publications", "Exploration", "Dashboards")
)

if (requireNamespace("gt", quietly = TRUE)) {
  gt_table <- gt::gt(viz_comparison_data) %>%
    gt::tab_header(
      title = "R Visualization Packages",
      subtitle = "Comparison of popular packages"
    ) %>%
    gt::cols_label(
      Package = "📦 Package",
      Type = "Type",
      Popularity = "Popularity",
      Best_For = "Best For"
    )
} else {
  gt_table <- viz_comparison_data
}

# Reactable with custom styling - pass the STYLED object!
gdp_data <- data.frame(
  Country = c("USA", "China", "Japan", "Germany", "UK"),
  GDP_Trillion = c(25.5, 17.9, 4.9, 4.3, 3.1),
  Population_M = c(331, 1439, 125, 83, 67),
  GDP_Per_Capita = c(77000, 12400, 39000, 52000, 46000)
)

if (requireNamespace("reactable", quietly = TRUE)) {
  reactable_table <- reactable::reactable(
    gdp_data,
    columns = list(
      Country = reactable::colDef(name = "🌍 Country", minWidth = 100),
      GDP_Trillion = reactable::colDef(
        name = "GDP (Trillion $)",
        format = reactable::colFormat(prefix = "$", digits = 1)
      ),
      Population_M = reactable::colDef(
        name = "Population (M)",
        format = reactable::colFormat(separators = TRUE)
      ),
      GDP_Per_Capita = reactable::colDef(
        name = "GDP per Capita",
        format = reactable::colFormat(prefix = "$", separators = TRUE)
      )
    ),
    sortable = TRUE,
    filterable = TRUE,
    searchable = TRUE,
    striped = TRUE,
    highlight = TRUE,
    defaultPageSize = 5
  )
} else {
  reactable_table <- gdp_data
}

# Now add tables to the content
advanced_content <- advanced_content %>%
  # Tables section
  add_text("## Tables & Data Display") %>%
  add_text("Display data in various table formats:") %>%
  add_spacer(height = "1rem") %>%

  add_text("### Simple Table (knitr::kable)") %>%
  add_table(simple_table_data, caption = "First 5 rows of mtcars dataset") %>%
  add_divider(style = "dashed") %>%

  add_text("### Interactive Table (DT)") %>%
  add_text("Pass a fully styled DT object with filters, custom CSS, and options:") %>%
  add_DT(dt_table) %>%
  add_callout(
    "This DT table has top filters, custom styling, and pagination - all preserved!",
    type = "tip"
  ) %>%
  add_divider(style = "dashed") %>%

  add_text("### Styled Table (gt)") %>%
  add_text("Pass a gt object with custom headers, labels, and formatting:") %>%
  add_gt(gt_table) %>%
  add_callout(
    "The gt table includes custom headers, emoji labels, and formatting - all preserved!",
    type = "note"
  ) %>%
  add_divider(style = "dashed") %>%

  add_text("### Modern Table (reactable)") %>%
  add_text("Pass a reactable object with custom columns, formatting, and interactivity:") %>%
  add_reactable(reactable_table) %>%
  add_callout(
    "This reactable has custom column formatting, dollar signs, number separators, and full interactivity!",
    type = "tip"
  ) %>%

  # Metrics and badges
  add_text("## Metrics & Badges") %>%
  add_text("Display key metrics with icons:") %>%
  add_spacer(height = "1rem") %>%
  add_metric(
    value = "2,867",
    title = "Active Users",
    icon = "ph:users",
    color = "#2E86AB",
    subtitle = "↑ 12% from last month"
  ) %>%
  add_metric(
    value = "98.5%",
    title = "Uptime",
    icon = "ph:check-circle",
    color = "#198754"
  ) %>%
  add_spacer(height = "1rem") %>%
  add_text("Add status badges:") %>%
  add_text(" ") %>%
  add_badge("New Feature", "success") %>%
  add_text(" ") %>%
  add_badge("Beta", "warning") %>%
  add_text(" ") %>%
  add_badge("Deprecated", "danger") %>%
  add_text(" ") %>%
  add_badge("Documentation", "info") %>%
  add_spacer(height = "2rem") %>%

  # Quotes
  add_text("## Blockquotes") %>%
  add_text("Add quotes with attribution:") %>%
  add_spacer(height = "1rem") %>%
  add_quote(
    "The best dashboards are the ones that tell a story, not just display data.",
    attribution = "Edward Tufte",
    cite = "https://www.edwardtufte.com"
  ) %>%
  add_spacer(height = "2rem") %>%

  # Raw HTML
  add_text("## Raw HTML") %>%
  add_text("Need maximum flexibility? Use raw HTML:") %>%
  add_spacer(height = "1rem") %>%
  add_html("<div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; border-radius: 12px; text-align: center;'><h3 style='margin: 0; font-size: 1.5rem;'>Custom Styled Content</h3><p style='margin-top: 0.5rem; opacity: 0.9;'>Use add_html() for complete control over styling and layout</p></div>") %>%
  add_spacer(height = "2rem") %>%

  # Spacers
  add_text("## Spacing Control") %>%
  add_text("Use `add_spacer()` to control vertical spacing between elements.") %>%
  add_text("*Default spacing*") %>%
  add_spacer(height = "4rem") %>%
  add_text("*Large spacing (4rem) above this text*") %>%
  add_spacer(height = "2rem") %>%

  add_divider() %>%
  add_callout(
    "All these content types can be freely mixed with visualizations using the pipeable syntax!",
    type = "tip",
    title = "Mix and Match"
  )

dashboard <- dashboard %>%
  add_page(
    name = "Advanced Content",
    icon = "ph:magic-wand",
    content = advanced_content
  )

# =============================================================================
# Demo 4: Page Data vs Table Data - Show both patterns!
# =============================================================================

# PATTERN A: Standalone tables (data embedded in table objects)
# This is what we showed above - tables created independently

# PATTERN B: Page data integration - tables use page's data!
# Build content explaining the two patterns
page_data_content <- create_content() %>%
  add_text(md_text(
    "# Data Integration Patterns",
    "",
    "Dashboardr supports two approaches for table data:",
    "",
    "## Pattern A: Standalone Tables",
    "",
    "Create fully styled table objects with their own data, then add them:",
    ""
  )) %>%
  add_code(
    code = "# Create table with its own data\nmy_table <- DT::datatable(\n  my_data,\n  filter = 'top',\n  options = list(pageLength = 5)\n)\n\n# Add to page (no data= needed)\ncontent <- create_content() %>%\n  add_DT(my_table)\n\nadd_page('Tables', content = content)",
    language = "r",
    caption = "Pattern A: Standalone tables with embedded data"
  ) %>%
  add_spacer(height = "1rem") %>%
  add_text(md_text(
    "## Pattern B: Page Data Integration",
    "",
    "Pass data to `add_page()`, and tables/visualizations use that data:",
    ""
  )) %>%
  add_code(
    code = "# Data passed to page\nadd_page(\n  'Analysis',\n  data = survey_data,  # <-- Page-level data\n  content = viz_collection\n)\n\n# All visualizations in viz_collection use survey_data automatically!",
    language = "r",
    caption = "Pattern B: Page-level data shared across content"
  ) %>%
  add_spacer(height = "2rem") %>%
  add_text(md_text(
    "## Live Example: Page Data Pattern",
    "",
    "This page uses the survey data passed to `add_page(data = survey_data)`,",
    "so visualizations automatically reference it:",
    ""
  )) %>%
  add_spacer(height = "1rem")

# Add visualizations that use page data
page_data_viz <- create_viz() %>%
  add_viz(
    type = "histogram",
    x_var = "age",
    title = "Age Distribution",
    tabgroup = "survey",
    text_above_graphs = "This visualization uses the page's `survey_data` automatically!"
  ) %>%
  add_viz(
    type = "histogram",
    x_var = "years",
    title = "Years of Experience",
    tabgroup = "survey",
    text_above_graphs = "Same data source - no need to specify it again!"
  )

# Add final summary after visualizations
page_data_summary <- create_content() %>%
  add_spacer(height = "2rem") %>%
  add_callout(
    md_text(
      "**Key Insight**: When you pass `data` to `add_page()`, all visualizations",
      "use that dataset. This is perfect for pages that analyze a single dataset",
      "from multiple angles. Use standalone tables when you need different data",
      "sources on the same page!"
    ),
    type = "tip",
    title = "When to Use Each Pattern"
  )

# Combine using list() - add_page accepts mixed content!
page_data_content_final <- list(
  page_data_content,
  page_data_viz,
  page_data_summary
)

dashboard <- dashboard %>%
  add_page(
    name = "Data Patterns",
    icon = "ph:database",
    data = survey_data,  # <-- Page-level data!
    content = page_data_content_final
  )

# =============================================================================
# Demo 10: Custom Value Boxes with Descriptions
# =============================================================================

value_boxes_content <- create_content() %>%
  add_text(md_text(
    "# Value Boxes & KPIs",
    "",
    "Custom styled value boxes are perfect for displaying key metrics with optional descriptions."
  )) %>%
  add_spacer(height = "1rem") %>%
  add_text(md_text("## Single Value Boxes")) %>%
  add_value_box(
    title = "Total Revenue",
    value = "€1,234,567",
    logo_text = "💰",
    bg_color = "#2E86AB",
    description = md_text(
      "Revenue from all sources in Q4 2024, including:",
      "",
      "- Product sales: €890,000",
      "- Services: €234,567",
      "- Subscriptions: €110,000"
    ),
    description_title = "Revenue Breakdown"
  ) %>%
  add_spacer(height = "1rem") %>%
  add_value_box(
    title = "Active Users",
    value = "45,678",
    logo_text = "👥",
    bg_color = "#A23B72",
    description = md_text(
      "Monthly active users across all platforms.",
      "",
      "- **Web**: 28,456",
      "- **Mobile**: 15,222",
      "- **API**: 2,000"
    ),
    description_title = "Platform Breakdown"
  ) %>%
  add_spacer(height = "2rem") %>%
  add_text(md_text("## Value Box Rows")) %>%
  add_text("Use the pipeable `add_value_box_row() %>% ... %>% end_value_box_row()` syntax:") %>%
  add_spacer(height = "1rem") %>%
  add_value_box_row() %>%
    add_value_box(
      title = "politiekereclame.nl",
      value = "€2.4M",
      logo_text = "🗳️",
      bg_color = "#4c5f7a"#,
      # description = md_text(
      #   "[politiekereclame.nl](https://politiekereclame.nl) is the central platform",
      #   "for EU political advertising transparency in the Netherlands.",
      #   "",
      #   "Covers TV, radio, newspapers, magazines, outdoor, and online advertising."
      # )
    ) %>%
    add_value_box(
      title = "Ster Transparency",
      value = "€1.8M",
      logo_text = "📺",
      bg_color = "#3d7068"#,
      # description = md_text(
      #   "[Ster](https://www.ster.nl) is the advertising sales organization",
      #   "for Dutch public broadcasting (NPO).",
      #   "",
      #   "Includes television, radio, and online channels."
      # )
    ) %>%
    add_value_box(
      title = "DPG Media",
      value = "€950K",
      logo_text = "📰",
      bg_color = "#5b8db8"#,
      # description = md_text(
      #   "[DPG Media](https://www.dpgmedia.nl) operates major Dutch newspapers,",
      #   "magazines, and digital platforms.",
      #   "",
      #   "Spending reported in brackets (estimates shown)."
      # )
    ) %>%
  end_value_box_row() %>%
  add_spacer(height = "2rem") %>%
  add_callout(
    md_text(
      "**Pro Tip:** Value boxes automatically stack on mobile devices for optimal viewing.",
      "",
      "You can use:",
      "- `logo_url` for image logos",
      "- `logo_text` for emoji or text",
      "- `description` for collapsible details",
      "- Custom `bg_color` for brand colors"
    ),
    type = "tip",
    title = "Customization Options"
  )

dashboard <- dashboard %>%
  add_page(
    name = "Value Boxes",
    icon = "ph:chart-line-up",
    content = value_boxes_content
  )



# About page demonstrating backward compatibility
dashboard <- dashboard %>%
  add_page(
    name = "About",
    icon = "ph:info",
    text = md_text(
      "# About This Demo",
      "",
      "This dashboard showcases the full range of dashboardr's content capabilities:",
      "",
      "### 1. Flexible Text Positioning",
      "",
      "Add text above titles, tabs, graphs, or below graphs for complete control over documentation.",
      "",
      "### 2. Rich Content Blocks",
      "",
      "Mix text, images, and visualizations freely using the pipeable `create_content()` syntax.",
      "",
      "### 3. Advanced Content Types",
      "",
      "Use callouts, dividers, code blocks, cards, accordions, metrics, value boxes, and more.",
      "",
      "### 4. Mixed Content",
      "",
      "Use the `content` parameter in `add_page()` to freely mix text, images, and visualizations.",
      "",
      "### 5. Default Parameters",
      "",
      "Set defaults with `create_content()` or `create_viz()` to maintain consistency across visualizations.",
      "",
      "---",
      "",
      "*Built with dashboardr - A Grammar of Dashboards*"
    )
  )

# Generate and optionally open
cat("\nGenerating Content Blocks Demo Dashboard...\n")
dashboard %>%
  generate_dashboard()

cat("\nDemo dashboard generated successfully!\n")
cat("Location: content_blocks_demo/\n")
cat("Open index.html or .qmd files to view\n\n")

# Print summary
print(dashboard)

cat("\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("  Features Demonstrated\n")
cat("═══════════════════════════════════════════════════════════\n")
cat("UNIFIED PIPEABLE SYNTAX - One simple workflow:\n")
cat("   create_viz() and create_content() are now aliases!\n")
cat("   Chain add_viz(), add_text(), add_image() in any order.\n\n")
cat("✓ Unified API            - create_viz() = create_content()\n")
cat("✓ text_above_title       - Text before the section header\n")
cat("✓ text_above_tabs        - Text before tabset (when using tabgroups)\n")
cat("✓ text_above_graphs      - Text between tabs and visualization\n")
cat("✓ text_below_graphs      - Text after visualization\n")
cat("✓ add_text()             - Standalone or pipeable text blocks\n")
cat("✓ add_image()            - Images with captions, sizing, alignment\n")
cat("✓ add_callout()          - Info/warning/tip/important boxes\n")
cat("✓ add_divider()          - Visual section separators\n")
cat("✓ add_code()             - Code blocks with syntax highlighting\n")
cat("✓ add_card()             - Content cards for highlights\n")
cat("✓ add_accordion()        - Collapsible sections\n")
cat("✓ add_spacer()           - Control vertical spacing\n")
cat("✓ add_iframe()           - Embed external content\n")
cat("✓ add_video()            - Video embeds\n")
cat("✓ add_table()            - Static tables (gt, reactable, DT)\n")
cat("✓ add_html()             - Raw HTML for maximum flexibility\n")
cat("✓ add_quote()            - Blockquotes with attribution\n")
cat("✓ add_badge()            - Status indicators\n")
cat("✓ add_metric()           - Simple metrics with icons\n")
cat("✓ add_value_box()        - Styled KPI boxes with descriptions\n")
cat("✓ add_value_box_row()    - Multiple value boxes in responsive rows\n")
cat("✓ content parameter      - Mix ALL content types on pages\n")
cat("✓ md_text() integration  - Seamless multi-line text composition\n")
cat("✓ create_content() defaults - Set consistent parameters across all vizzes\n")
cat("═══════════════════════════════════════════════════════════\n")


