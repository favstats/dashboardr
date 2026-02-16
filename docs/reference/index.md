# Package index

## Dashboard Creation

Functions for creating and managing dashboards

- [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)
  : Create a new dashboard project
- [`add_dashboard_page()`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md)
  : Add a page to the dashboard
- [`add_page()`](https://favstats.github.io/dashboardr/reference/add_page.md)
  : Add Page to Dashboard (Alias)
- [`add_pages()`](https://favstats.github.io/dashboardr/reference/add_pages.md)
  : Add multiple pages to a dashboard
- [`create_page()`](https://favstats.github.io/dashboardr/reference/create_page.md)
  : Create a page object
- [`add_content()`](https://favstats.github.io/dashboardr/reference/add_content.md)
  : Add content collection(s) to a page
- [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)
  : Generate all dashboard files
- [`generate_dashboards()`](https://favstats.github.io/dashboardr/reference/generate_dashboards.md)
  : Generate multiple dashboards
- [`publish_dashboard()`](https://favstats.github.io/dashboardr/reference/publish_dashboard.md)
  : Publish dashboard to GitHub Pages
- [`update_dashboard()`](https://favstats.github.io/dashboardr/reference/update_dashboard.md)
  : Update dashboard on GitHub
- [`create_loading_overlay()`](https://favstats.github.io/dashboardr/reference/create_loading_overlay.md)
  : Create a loading overlay for a dashboard page
- [`create_pagination_nav()`](https://favstats.github.io/dashboardr/reference/create_pagination_nav.md)
  : Create pagination navigation controls for a dashboard page
- [`add_powered_by_dashboardr()`](https://favstats.github.io/dashboardr/reference/add_powered_by_dashboardr.md)
  : Add "Powered by dashboardr" branding to footer

## Demo Dashboards

Built-in demo dashboards showcasing package features

- [`tutorial_dashboard()`](https://favstats.github.io/dashboardr/reference/tutorial_dashboard.md)
  : Generate a tutorial dashboard.
- [`showcase_dashboard()`](https://favstats.github.io/dashboardr/reference/showcase_dashboard.md)
  : Generate a showcase dashboard demonstrating all dashboardr features.
- [`ascor_dashboard()`](https://favstats.github.io/dashboardr/reference/ascor_dashboard.md)
  : Generate an ASCoR-themed dashboard for the University of Amsterdam

## Visualization Creation

Functions for creating visualizations

- [`create_viz()`](https://favstats.github.io/dashboardr/reference/create_viz.md)
  : Create a new visualization collection
- [`create_content()`](https://favstats.github.io/dashboardr/reference/create_content.md)
  : Create a new content/visualization collection (alias for create_viz)
- [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
  : Add a visualization to the collection
- [`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
  : Add Multiple Visualizations at Once
- [`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
  : Combine visualization collections
- [`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md)
  : Combine content collections (universal combiner)
- [`merge_collections()`](https://favstats.github.io/dashboardr/reference/merge_collections.md)
  : Merge two content/viz collections
- [`add_pagination()`](https://favstats.github.io/dashboardr/reference/add_pagination.md)
  [`add_pagination.page_object()`](https://favstats.github.io/dashboardr/reference/add_pagination.md)
  : Add pagination break to visualization collection
- [`set_tabgroup_labels()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md)
  : Set or update tabgroup display labels
- [`preview()`](https://favstats.github.io/dashboardr/reference/preview.md)
  : Preview any dashboardr object
- [`save_widget()`](https://favstats.github.io/dashboardr/reference/save_widget.md)
  : Save widget as self-contained HTML
- [`validate_specs()`](https://favstats.github.io/dashboardr/reference/validate_specs.md)
  : Validate visualization specifications in a collection

## Visualization Types

Functions for different chart types

- [`viz_histogram()`](https://favstats.github.io/dashboardr/reference/viz_histogram.md)
  : Create an Histogram
- [`viz_density()`](https://favstats.github.io/dashboardr/reference/viz_density.md)
  : Create a Density Plot
- [`viz_boxplot()`](https://favstats.github.io/dashboardr/reference/viz_boxplot.md)
  : Create a Box Plot
- [`viz_bar()`](https://favstats.github.io/dashboardr/reference/viz_bar.md)
  : Create Bar Chart
- [`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
  : Create a Stacked Bar Chart
- [`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md)
  : Stacked Bar Charts for Multiple Variables (Superseded)
- [`viz_timeline()`](https://favstats.github.io/dashboardr/reference/viz_timeline.md)
  : Create a Timeline Chart
- [`viz_heatmap()`](https://favstats.github.io/dashboardr/reference/viz_heatmap.md)
  : Create a Heatmap
- [`viz_scatter()`](https://favstats.github.io/dashboardr/reference/viz_scatter.md)
  : Create Scatter Plot
- [`viz_map()`](https://favstats.github.io/dashboardr/reference/viz_map.md)
  : Create an interactive map visualization
- [`viz_treemap()`](https://favstats.github.io/dashboardr/reference/viz_treemap.md)
  : Create a treemap visualization
- [`viz_lollipop()`](https://favstats.github.io/dashboardr/reference/viz_lollipop.md)
  : Create a Lollipop Chart
- [`viz_dumbbell()`](https://favstats.github.io/dashboardr/reference/viz_dumbbell.md)
  : Create a Dumbbell Chart
- [`viz_funnel()`](https://favstats.github.io/dashboardr/reference/viz_funnel.md)
  : Create a Funnel Chart
- [`viz_gauge()`](https://favstats.github.io/dashboardr/reference/viz_gauge.md)
  : Create a Gauge or Bullet Chart
- [`viz_pie()`](https://favstats.github.io/dashboardr/reference/viz_pie.md)
  : Create a Pie or Donut Chart
- [`viz_sankey()`](https://favstats.github.io/dashboardr/reference/viz_sankey.md)
  : Create a Sankey Diagram
- [`viz_waffle()`](https://favstats.github.io/dashboardr/reference/viz_waffle.md)
  : Create a Waffle Chart

## Tooltip Customization

Functions for customizing chart tooltips

- [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  : Create a Tooltip Configuration
- [`print(`*`<dashboardr_tooltip>`*`)`](https://favstats.github.io/dashboardr/reference/print.dashboardr_tooltip.md)
  : Print method for tooltip configurations
- [`add_hc()`](https://favstats.github.io/dashboardr/reference/add_hc.md)
  : Add a custom highcharter chart

## Stacked Bar Charts

[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
is the unified function for all stacked bar charts. Use `x_var` +
`stack_var` for crosstabs, or `x_vars` for multi-variable comparisons.
[`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md)
is a legacy wrapper that calls
[`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md).

- [`viz_stackedbar()`](https://favstats.github.io/dashboardr/reference/viz_stackedbar.md)
  : Create a Stacked Bar Chart
- [`viz_stackedbars()`](https://favstats.github.io/dashboardr/reference/viz_stackedbars.md)
  : Stacked Bar Charts for Multiple Variables (Superseded)

## Navigation & Layout

Functions for dashboard navigation and structure

- [`navbar_section()`](https://favstats.github.io/dashboardr/reference/navbar_section.md)
  : Create a navbar section for hybrid navigation
- [`navbar_menu()`](https://favstats.github.io/dashboardr/reference/navbar_menu.md)
  : Create a navbar dropdown menu
- [`add_navbar_element()`](https://favstats.github.io/dashboardr/reference/add_navbar_element.md)
  : Add a custom navbar element to dashboard
- [`sidebar_group()`](https://favstats.github.io/dashboardr/reference/sidebar_group.md)
  : Create a sidebar group for hybrid navigation
- [`add_layout_column()`](https://favstats.github.io/dashboardr/reference/add_layout_column.md)
  : Start a manual layout column
- [`add_layout_row()`](https://favstats.github.io/dashboardr/reference/add_layout_row.md)
  : Start a manual layout row inside a layout column
- [`end_layout_row()`](https://favstats.github.io/dashboardr/reference/end_layout_row.md)
  : End a manual layout row
- [`end_layout_column()`](https://favstats.github.io/dashboardr/reference/end_layout_column.md)
  : End a manual layout column
- [`icon()`](https://favstats.github.io/dashboardr/reference/icon.md) :
  Create iconify icon shortcode

## Content Helpers

Functions for adding content to dashboards

- [`md_text()`](https://favstats.github.io/dashboardr/reference/md_text.md)
  : Create multi-line markdown text content
- [`text_lines()`](https://favstats.github.io/dashboardr/reference/text_lines.md)
  : Create text content from a character vector
- [`create_blockquote()`](https://favstats.github.io/dashboardr/reference/create_blockquote.md)
  : Create a Styled Blockquote
- [`card()`](https://favstats.github.io/dashboardr/reference/card.md) :
  Create a Bootstrap card component
- [`card_row()`](https://favstats.github.io/dashboardr/reference/card_row.md)
  : Display cards in a Bootstrap row
- [`spec_viz()`](https://favstats.github.io/dashboardr/reference/spec_viz.md)
  : Create a single visualization specification

## Content Blocks

Functions for adding rich content blocks to pages

- [`add_text()`](https://favstats.github.io/dashboardr/reference/add_text.md)
  : Add text to content collection (pipeable)
- [`add_image()`](https://favstats.github.io/dashboardr/reference/add_image.md)
  : Add image to content collection (pipeable)
- [`add_callout()`](https://favstats.github.io/dashboardr/reference/add_callout.md)
  : Add callout box
- [`add_divider()`](https://favstats.github.io/dashboardr/reference/add_divider.md)
  : Add horizontal divider
- [`add_code()`](https://favstats.github.io/dashboardr/reference/add_code.md)
  : Add code block
- [`add_card()`](https://favstats.github.io/dashboardr/reference/add_card.md)
  : Add card
- [`add_accordion()`](https://favstats.github.io/dashboardr/reference/add_accordion.md)
  : Add collapsible accordion/details section
- [`add_spacer()`](https://favstats.github.io/dashboardr/reference/add_spacer.md)
  : Add vertical spacer
- [`add_html()`](https://favstats.github.io/dashboardr/reference/add_html.md)
  : Add raw HTML content
- [`add_quote()`](https://favstats.github.io/dashboardr/reference/add_quote.md)
  : Add a blockquote
- [`add_badge()`](https://favstats.github.io/dashboardr/reference/add_badge.md)
  : Add a status badge

## HTML Helpers

Standalone HTML generation functions for use in custom content

- [`html_accordion()`](https://favstats.github.io/dashboardr/reference/html_accordion.md)
  : Create a collapsible accordion section
- [`html_badge()`](https://favstats.github.io/dashboardr/reference/html_badge.md)
  : Create a status badge
- [`html_card()`](https://favstats.github.io/dashboardr/reference/html_card.md)
  : Create a Bootstrap-style card
- [`html_divider()`](https://favstats.github.io/dashboardr/reference/html_divider.md)
  : Create a horizontal divider
- [`html_iframe()`](https://favstats.github.io/dashboardr/reference/html_iframe.md)
  : Create an iframe embed
- [`html_metric()`](https://favstats.github.io/dashboardr/reference/html_metric.md)
  : Create a metric card
- [`html_spacer()`](https://favstats.github.io/dashboardr/reference/html_spacer.md)
  : Create a vertical spacer

## Modals

Functions for adding interactive modal dialogs

- [`add_modal()`](https://favstats.github.io/dashboardr/reference/add_modal.md)
  : Add Modal to Content Collection (Pipeable)
- [`enable_modals()`](https://favstats.github.io/dashboardr/reference/enable_modals.md)
  : Enable Modal Functionality
- [`modal_content()`](https://favstats.github.io/dashboardr/reference/modal_content.md)
  : Create Modal Content Container
- [`modal_link()`](https://favstats.github.io/dashboardr/reference/modal_link.md)
  : Create Modal Link

## Metrics & Value Boxes

Functions for displaying KPIs and metrics

- [`add_metric()`](https://favstats.github.io/dashboardr/reference/add_metric.md)
  : Add a metric/value box
- [`add_value_box()`](https://favstats.github.io/dashboardr/reference/add_value_box.md)
  : Add a custom styled value box
- [`add_value_box_row()`](https://favstats.github.io/dashboardr/reference/add_value_box_row.md)
  : Start a value box row
- [`end_value_box_row()`](https://favstats.github.io/dashboardr/reference/end_value_box_row.md)
  : End a value box row
- [`render_value_box()`](https://favstats.github.io/dashboardr/reference/render_value_box.md)
  : Render a single value box
- [`render_value_box_row()`](https://favstats.github.io/dashboardr/reference/render_value_box_row.md)
  : Render a row of value boxes

## Interactive Inputs

Functions for adding interactive inputs to dashboards

- [`add_input()`](https://favstats.github.io/dashboardr/reference/add_input.md)
  : Add an interactive input filter
- [`add_filter()`](https://favstats.github.io/dashboardr/reference/add_filter.md)
  : Add a filter control (simplified interface)
- [`add_input_row()`](https://favstats.github.io/dashboardr/reference/add_input_row.md)
  : Start an input row
- [`add_reset_button()`](https://favstats.github.io/dashboardr/reference/add_reset_button.md)
  : Add a reset button to reset filters
- [`add_linked_inputs()`](https://favstats.github.io/dashboardr/reference/add_linked_inputs.md)
  : Add linked parent-child inputs (cascading dropdowns)
- [`enable_inputs()`](https://favstats.github.io/dashboardr/reference/enable_inputs.md)
  : Enable Input Filter Functionality
- [`enable_show_when()`](https://favstats.github.io/dashboardr/reference/enable_show_when.md)
  : Enable show_when (conditional visibility) script only
- [`enable_chart_export()`](https://favstats.github.io/dashboardr/reference/enable_chart_export.md)
  : Enable chart export buttons (PNG/SVG/PDF/CSV)
- [`enable_accessibility()`](https://favstats.github.io/dashboardr/reference/enable_accessibility.md)
  : Enable Accessibility Enhancements
- [`enable_url_params()`](https://favstats.github.io/dashboardr/reference/enable_url_params.md)
  : Enable URL Parameter Deep Linking
- [`end_input_row()`](https://favstats.github.io/dashboardr/reference/end_input_row.md)
  : End an input row
- [`render_input()`](https://favstats.github.io/dashboardr/reference/render_input.md)
  : Render an input widget
- [`render_input_row()`](https://favstats.github.io/dashboardr/reference/render_input_row.md)
  : Render a row of input widgets
- [`render_viz_html()`](https://favstats.github.io/dashboardr/reference/render_viz_html.md)
  : Render a viz result as raw HTML
- [`show_when_open()`](https://favstats.github.io/dashboardr/reference/show_when_open.md)
  : Open a conditional-visibility wrapper
- [`show_when_close()`](https://favstats.github.io/dashboardr/reference/show_when_close.md)
  : Close a conditional-visibility wrapper

## Sidebars

Functions for adding page sidebars with filters

- [`add_sidebar()`](https://favstats.github.io/dashboardr/reference/add_sidebar.md)
  : Add a sidebar to a page
- [`end_sidebar()`](https://favstats.github.io/dashboardr/reference/end_sidebar.md)
  : End a sidebar
- [`enable_sidebar()`](https://favstats.github.io/dashboardr/reference/enable_sidebar.md)
  : Enable Sidebar Styling

## Embedded Content

Functions for embedding external content

- [`add_widget()`](https://favstats.github.io/dashboardr/reference/add_widget.md)
  : Add a generic htmlwidget to the dashboard
- [`add_plotly()`](https://favstats.github.io/dashboardr/reference/add_plotly.md)
  : Add a plotly chart to the dashboard
- [`add_echarts()`](https://favstats.github.io/dashboardr/reference/add_echarts.md)
  : Add an echarts4r chart to the dashboard
- [`add_ggiraph()`](https://favstats.github.io/dashboardr/reference/add_ggiraph.md)
  : Add a ggiraph interactive plot to the dashboard
- [`add_ggplot()`](https://favstats.github.io/dashboardr/reference/add_ggplot.md)
  : Add a static ggplot2 plot to the dashboard
- [`add_leaflet()`](https://favstats.github.io/dashboardr/reference/add_leaflet.md)
  : Add a leaflet map to the dashboard
- [`add_iframe()`](https://favstats.github.io/dashboardr/reference/add_iframe.md)
  : Add iframe
- [`add_video()`](https://favstats.github.io/dashboardr/reference/add_video.md)
  : Add video

## Tables

Functions for adding tables to pages

- [`add_table()`](https://favstats.github.io/dashboardr/reference/add_table.md)
  : Add generic table (data frame)
- [`add_gt()`](https://favstats.github.io/dashboardr/reference/add_gt.md)
  : Add gt table
- [`add_reactable()`](https://favstats.github.io/dashboardr/reference/add_reactable.md)
  : Add reactable table
- [`add_DT()`](https://favstats.github.io/dashboardr/reference/add_DT.md)
  : Add DT datatable

## Themes & Styling

Functions for customizing dashboard appearance

- [`apply_theme()`](https://favstats.github.io/dashboardr/reference/apply_theme.md)
  : Apply Theme to Dashboard
- [`theme_modern()`](https://favstats.github.io/dashboardr/reference/theme_modern.md)
  : Apply a Modern Tech Theme to Dashboard
- [`theme_clean()`](https://favstats.github.io/dashboardr/reference/theme_clean.md)
  : Apply a Clean Theme to Dashboard
- [`theme_academic()`](https://favstats.github.io/dashboardr/reference/theme_academic.md)
  : Apply a Professional Academic Theme to Dashboard
- [`theme_ascor()`](https://favstats.github.io/dashboardr/reference/theme_ascor.md)
  : Apply ASCoR/UvA Theme to Dashboard
- [`theme_uva()`](https://favstats.github.io/dashboardr/reference/theme_uva.md)
  : Apply UvA Theme to Dashboard (Alias)

## Print Methods

S3 methods for displaying objects

- [`print(`*`<viz_collection>`*`)`](https://favstats.github.io/dashboardr/reference/print.viz_collection.md)
  : Print Visualization Collection
- [`print(`*`<dashboard_project>`*`)`](https://favstats.github.io/dashboardr/reference/print.dashboard_project.md)
  : Print Dashboard Project
- [`print(`*`<page_object>`*`)`](https://favstats.github.io/dashboardr/reference/print.page_object.md)
  : Print method for page objects
- [`print(`*`<dashboardr_widget>`*`)`](https://favstats.github.io/dashboardr/reference/print.dashboardr_widget.md)
  : Print method for dashboardr_widget - opens in viewer
- [`knit_print(`*`<content_collection>`*`)`](https://favstats.github.io/dashboardr/reference/knit_print.content_collection.md)
  : Knitr print method for content collections
- [`knit_print(`*`<page_object>`*`)`](https://favstats.github.io/dashboardr/reference/knit_print.page_object.md)
  : Knitr print method for page objects
- [`knit_print(`*`<dashboard_project>`*`)`](https://favstats.github.io/dashboardr/reference/knit_print.dashboard_project.md)
  : Knitr print method for dashboard projects
- [`show_structure()`](https://favstats.github.io/dashboardr/reference/show_structure.md)
  : Show collection structure (even with data attached)
- [`` `+`( ``*`<viz_collection>`*`)`](https://favstats.github.io/dashboardr/reference/plus-.viz_collection.md)
  : Combine Visualization Collections with + Operator
- [`` `+`( ``*`<content_collection>`*`)`](https://favstats.github.io/dashboardr/reference/plus-.content_collection.md)
  : Combine Content Collections with + Operator

## MCP Server

Model Context Protocol server for LLM-assisted dashboard coding

- [`dashboardr_mcp_server()`](https://favstats.github.io/dashboardr/reference/dashboardr_mcp_server.md)
  : Start dashboardr MCP Server

## Page Object Methods

S3 methods for page objects

- [`add_text.page_object()`](https://favstats.github.io/dashboardr/reference/add_text.page_object.md)
  : Add text to a page
- [`add_callout.page_object()`](https://favstats.github.io/dashboardr/reference/add_callout.page_object.md)
  : Add a callout to a page
- [`set_tabgroup_labels.page_object()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.page_object.md)
  : Set tabgroup labels for a page
