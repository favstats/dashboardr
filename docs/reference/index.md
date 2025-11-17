# Package index

## Dashboard Creation

Functions for creating and managing dashboards

- [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)
  : Create a new dashboard project
- [`add_dashboard_page()`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md)
  : Add a page to the dashboard
- [`add_page()`](https://favstats.github.io/dashboardr/reference/add_page.md)
  : Add Page to Dashboard (Alias)
- [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)
  : Generate all dashboard files
- [`publish_dashboard()`](https://favstats.github.io/dashboardr/reference/publish_dashboard.md)
  : Publish dashboard to GitHub Pages
- [`update_dashboard()`](https://favstats.github.io/dashboardr/reference/update_dashboard.md)
  : Update dashboard on GitHub
- [`add_loading_overlay()`](https://favstats.github.io/dashboardr/reference/add_loading_overlay.md)
  : Add a loading overlay to a dashboard page
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
  : Parse tabgroup into normalized hierarchy
- [`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
  : Add Multiple Visualizations at Once
- [`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
  : Combine visualization collections
- [`combine_content()`](https://favstats.github.io/dashboardr/reference/combine_content.md)
  : Combine content collections (universal combiner)
- [`add_pagination()`](https://favstats.github.io/dashboardr/reference/add_pagination.md)
  : Create a sidebar group for hybrid navigation
- [`set_tabgroup_labels()`](https://favstats.github.io/dashboardr/reference/set_tabgroup_labels.md)
  : Set or update tabgroup display labels

## Visualization Types

Functions for different chart types

- [`create_histogram()`](https://favstats.github.io/dashboardr/reference/create_histogram.md)
  : Create an Histogram
- [`create_bar()`](https://favstats.github.io/dashboardr/reference/create_bar.md)
  : Create Bar Chart
- [`create_stackedbar()`](https://favstats.github.io/dashboardr/reference/create_stackedbar.md)
  : Create a Stacked Bar Chart
- [`create_stackedbars()`](https://favstats.github.io/dashboardr/reference/create_stackedbars.md)
  : Stacked Bar Charts
- [`create_timeline()`](https://favstats.github.io/dashboardr/reference/create_timeline.md)
  : Create a Timeline Chart
- [`create_heatmap()`](https://favstats.github.io/dashboardr/reference/create_heatmap.md)
  : Create a Heatmap

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

## Embedded Content

Functions for embedding external content

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
  : Create a new dashboard project
- [`print(`*`<dashboard_project>`*`)`](https://favstats.github.io/dashboardr/reference/print.dashboard_project.md)
  : Create iconify icon shortcode
- [`` `+`( ``*`<viz_collection>`*`)`](https://favstats.github.io/dashboardr/reference/plus-.viz_collection.md)
  : Combine Visualization Collections with + Operator
- [`` `+`( ``*`<content_collection>`*`)`](https://favstats.github.io/dashboardr/reference/plus-.content_collection.md)
  : Combine Content Collections with + Operator
