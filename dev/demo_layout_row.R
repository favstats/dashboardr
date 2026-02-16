# Demo: layout row with mixed content types (Issue #15 fix)
#
# Shows that add_layout_row() correctly renders items side by side
# in non-dashboard mode (no sidebar) using Quarto layout-ncol divs.

library(dashboardr)

out_dir <- file.path(tempdir(), "layout_row_demo")
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE)

content <- create_content(data = mtcars) |>
  # Row of 3 metrics
  add_layout_column() |>
  add_layout_row() |>
    add_metric(value = 32, title = "Observations", icon = "ph:database") |>
    add_metric(value = 6, title = "Cylinders", icon = "ph:engine") |>
    add_metric(value = 21.0, title = "Avg MPG", icon = "ph:gas-pump") |>
  end_layout_row() |>
  end_layout_column() |>

  # Row of 2 text blocks
  add_layout_column() |>
  add_layout_row() |>
    add_text("**Left column**: This text appears on the left side.") |>
    add_text("**Right column**: This text appears on the right side.") |>
  end_layout_row() |>
  end_layout_column() |>

  # Row with a table and a chart
  add_layout_column() |>
  add_layout_row() |>
    add_table(head(mtcars[, 1:4], 5)) |>
    add_text("A summary table alongside other content, all in one row.") |>
  end_layout_row() |>
  end_layout_column() |>

  # Row of 2 charts side by side
  add_layout_column() |>
  add_layout_row() |>
    add_viz(type = "bar", x_var = "cyl", title = "By Cylinders") |>
    add_viz(type = "bar", x_var = "gear", title = "By Gears") |>
  end_layout_row() |>
  end_layout_column() |>

  # A regular chart below (full width)
  add_viz(type = "bar", x_var = "cyl", title = "Cars by Cylinder Count")

proj <- create_dashboard(
  output_dir = out_dir,
  title = "Layout Row Demo"
) |>
  add_page("Index", data = mtcars, content = content, is_landing_page = TRUE)

generate_dashboard(proj, render = TRUE, open = "browser")
