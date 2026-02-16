# dev/demo_standalone_metrics.R
# Demo: enhanced metric cards with standalone generation
# Exercises bg_color, text_color, value_prefix, value_suffix, border_radius,
# and the layout-row style parameter.

library(dashboardr)

out_dir <- file.path(tempdir(), "standalone_metrics")
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE)

content <- create_content(data = mtcars) |>
  # Row of 3 colored metrics (centered)
  add_layout_column() |>
  add_layout_row(style = "text-align: center;") |>
    add_metric(value = 32, title = "Observations", icon = "ph:database",
               bg_color = "#3498db", text_color = "#ffffff") |>
    add_metric(value = 6, title = "Cylinder Types", icon = "ph:engine",
               bg_color = "#27ae60", text_color = "#ffffff",
               border_radius = "12px") |>
    add_metric(value = "21.0", title = "Average MPG", icon = "ph:gas-pump",
               bg_color = "#9b59b6", text_color = "#ffffff",
               value_suffix = " mpg") |>
  end_layout_row() |>
  end_layout_column() |>
  # Row of 2 accent-border metrics with prefix/suffix
  add_layout_column() |>
  add_layout_row() |>
    add_metric(value = 3.22, title = "Mean Displacement",
               color = "#e74c3c", value_prefix = "~", value_suffix = "L",
               subtitle = "Across all models") |>
    add_metric(value = "146", title = "Avg Horsepower",
               color = "#f39c12", icon = "ph:lightning",
               subtitle = "Mean HP rating") |>
  end_layout_row() |>
  end_layout_column() |>
  # Full-width chart
  add_viz(type = "bar", x_var = "cyl", title = "Cars by Cylinder Count")

proj <- create_dashboard(
  output_dir = out_dir,
  title = "Standalone Metrics Demo"
) |>
  add_page("Index", data = mtcars, content = content, is_landing_page = TRUE)

generate_dashboard(proj, standalone = TRUE, open = "browser")
