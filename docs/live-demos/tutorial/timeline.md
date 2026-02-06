# Timeline

# Timeline

View Full Page Code

``` r
# === TIMELINE PAGE ===
# This page shows happiness trends over 50+ years

# Data preparation - use gss_all for time series
library(gssr)
data(gss_all, package = "gssr")
gss_time <- gss_all %>%
  dplyr::mutate(
    happy = as.character(haven::as_factor(happy))
  ) %>%
  dplyr::filter(
    !is.na(happy),
    !is.na(year),
    happy %in% c("very happy", "pretty happy", "not too happy")
  )

# Create visualization
timeline_viz <- create_content() %>%
  add_viz(type = "timeline",
          time_var = "year",
          y_var = "happy",
          title = "Happiness Trends Over Time (1972-2024)",
          subtitle = "How has happiness changed across 50+ years?",
          x_label = "Year",
          y_label = "Percentage",
          y_levels = c("very happy", "pretty happy", "not too happy"),
          color_palette = c("#27ae60", "#f39c12", "#e74c3c"),
          height = 450)

# Create page and add content
timeline_page <- create_page(name = "Timeline", data = gss_time, icon = "ph:chart-line") %>%
  add_content(timeline_viz)
```

The **timeline chart** visualizes trends across the 50+ year history of
the GSS (1972-2024).

## Happiness Trends Over Time (1972-2024)

Back to top
