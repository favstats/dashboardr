# Package index

## Dashboard Creation

Functions for creating and managing dashboards

- [`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md)
  : Create a dashboard
- [`add_dashboard_page()`](https://favstats.github.io/dashboardr/reference/add_dashboard_page.md)
  : Add a page to the dashboard
- [`add_page()`](https://favstats.github.io/dashboardr/reference/add_page.md)
  : Add Page to Dashboard (Alias)
- [`generate_dashboard()`](https://favstats.github.io/dashboardr/reference/generate_dashboard.md)
  : Generate all dashboard files
- [`publish_dashboard()`](https://favstats.github.io/dashboardr/reference/publish_dashboard.md)
  : Publish dashboard to GitHub Pages or GitLab Pages
- [`tutorial_dashboard()`](https://favstats.github.io/dashboardr/reference/tutorial_dashboard.md)
  : Generate a tutorial dashboard.

## Visualization Creation

Functions for creating visualizations

- [`create_viz()`](https://favstats.github.io/dashboardr/reference/create_viz.md)
  : Create a new visualization collection
- [`add_viz()`](https://favstats.github.io/dashboardr/reference/add_viz.md)
  : Add a visualization to the collection
- [`add_vizzes()`](https://favstats.github.io/dashboardr/reference/add_vizzes.md)
  : Add Multiple Visualizations at Once
- [`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
  : Combine visualization collections
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

## Print Methods

S3 methods for displaying objects

- [`print(`*`<viz_collection>`*`)`](https://favstats.github.io/dashboardr/reference/print.viz_collection.md)
  : Print Visualization Collection
- [`print(`*`<dashboard_project>`*`)`](https://favstats.github.io/dashboardr/reference/print.dashboard_project.md)
  : Print Dashboard Project
- [`` `+`( ``*`<viz_collection>`*`)`](https://favstats.github.io/dashboardr/reference/plus-.viz_collection.md)
  : Combine Visualization Collections with + Operator
