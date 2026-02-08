# =================================================================
# viz_map.R - Interactive Map Visualization
# =================================================================

#' Create an interactive map visualization
#'
#' Creates a Highcharter choropleth map with optional click navigation
#' to other pages/dashboards. Designed to work within the dashboardr
#' visualization system via add_viz(type = "map", ...).
#'
#' @param data Data frame with geographic data
#' @param map_type Map type: "custom/world", "custom/world-highres",
#'   "countries/us/us-all", etc. See Highcharts map collection.
#' @param value_var Column name for color values (required)
#' @param join_var Column name to join with map geography (default: "iso2c")
#' @param title Chart title
#' @param subtitle Chart subtitle
#' @param legend_title Legend title (defaults to value_var)
#' @param color_stops Numeric vector of color gradient stops
#' @param color_palette Character vector of colors for gradient
#' @param na_color Color for missing/NA values (default: "#E0E0E0")
#' @param click_url_template URL template for click navigation.
#'   Use \code{\{var\}} syntax for variable substitution, e.g.,
#'   "\{iso2c\}_dashboard/index.html"
#' @param click_var Variable to use in click URL (defaults to join_var)
#' @param tooltip A tooltip configuration created with \code{\link{tooltip}()},
#'   OR a format string with \{placeholders\}. Available placeholders:
#'   \code{\{name\}}, \code{\{value\}}.
#'   See \code{\link{tooltip}} for full customization options.
#' @param tooltip_vars Character vector of variables to show in tooltip (legacy).
#' @param tooltip_format Custom tooltip format string using Highcharts syntax (legacy).
#'   For the simpler dashboardr placeholder syntax, use \code{tooltip} instead.
#' @param height Chart height in pixels (default: 500)
#' @param border_color Border color between regions (default: "#FFFFFF")
#' @param border_width Border width (default: 0.5
#' @param credits Show Highcharts credits (default: FALSE)
#' @param backend Rendering backend: "highcharter" (default), "plotly", "echarts4r", or "ggiraph".
#' @param ... Additional arguments passed to highcharter::hcmap()
#'
#' @return A highchart object
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic world map
#' country_data <- data.frame(
#'   iso2c = c("US", "DE", "FR"),
#'   total_ads = c(1000, 500, 300)
#' )
#'
#' viz_map(
#'   data = country_data,
#'   value_var = "total_ads",
#'   join_var = "iso2c",
#'   title = "Ad Spending by Country"
#' )
#'
#' # With click navigation to country dashboards
#' viz_map(
#'   data = country_data,
#'   value_var = "total_ads",
#'   click_url_template = "{iso2c}_dashboard/index.html",
#'   title = "Click a country to explore"
#' )
#'
#' # Using with add_viz()
#' viz <- create_viz() %>%
#'   add_viz(
#'     type = "map",
#'     value_var = "total_ads",
#'     join_var = "iso2c",
#'     click_url_template = "{iso2c}_dashboard/index.html"
#'   )
#' }
viz_map <- function(
    data,
    map_type = "custom/world",
    value_var,
    join_var = "iso2c",
    title = NULL,
    subtitle = NULL,
    legend_title = NULL,
    color_stops = NULL,
    color_palette = c("#f7fbff", "#08306b"),
    na_color = "#E0E0E0",
    click_url_template = NULL,
    click_var = NULL,
    tooltip = NULL,
    tooltip_vars = NULL,
    tooltip_format = NULL,
    height = 500,
    border_color = "#FFFFFF",
    border_width = 0.5,
    credits = FALSE,
    backend = "highcharter",
    ...
) {
  # Convert variable arguments to strings (supports both quoted and unquoted)
  value_var <- .as_var_string(rlang::enquo(value_var))
  join_var <- .as_var_string(rlang::enquo(join_var))
  click_var <- .as_var_string(rlang::enquo(click_var))
  tooltip_vars <- .as_var_strings(rlang::enquo(tooltip_vars))

  # Validate required parameters

  if (is.null(value_var)) {
    stop("value_var is required for viz_map()")
  }

  if (!value_var %in% names(data)) {
    stop("value_var '", value_var, "' not found in data")
  }

  if (!join_var %in% names(data)) {
    stop("join_var '", join_var, "' not found in data")
  }

  # Set legend title
  if (is.null(legend_title)) {
    legend_title <- value_var
  }

  # Determine map join key based on map type and data
  # World maps support both iso-a2 (2-letter) and iso-a3 (3-letter) codes
  # US maps use postal codes

  map_join_key <- if (grepl("world", map_type, ignore.case = TRUE)) {
    # Auto-detect 2-letter vs 3-letter country codes
    sample_values <- na.omit(data[[join_var]])
    if (length(sample_values) > 0) {
      # Check the most common string length
      avg_length <- mean(nchar(as.character(sample_values)))
      if (avg_length > 2.5) {
        "iso-a3"  # 3-letter codes like "USA", "DEU", "GBR"
      } else {
        "iso-a2"  # 2-letter codes like "US", "DE", "GB"
      }
    } else {
      "iso-a2"  # Default fallback
    }
  } else if (grepl("us-all|usa", map_type, ignore.case = TRUE)) {
    "postal-code"
  } else {
    "hc-key"  # Generic fallback
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(data[[value_var]], "haven_labelled")) {
      data[[value_var]] <- as.numeric(data[[value_var]])
    }
    if (inherits(data[[join_var]], "haven_labelled")) {
      data[[join_var]] <- as.character(haven::as_factor(data[[join_var]], levels = "values"))
    }
  }

  # Build config for backend dispatch
  config <- list(
    map_type = map_type,
    value_var = value_var,
    join_var = join_var,
    map_join_key = map_join_key,
    legend_title = legend_title,
    title = title,
    subtitle = subtitle,
    color_stops = color_stops,
    color_palette = color_palette,
    na_color = na_color,
    click_url_template = click_url_template,
    click_var = click_var,
    tooltip = tooltip,
    tooltip_vars = tooltip_vars,
    tooltip_format = tooltip_format,
    height = height,
    border_color = border_color,
    border_width = border_width,
    credits = credits,
    dots = list(...)
  )

  # Dispatch to backend renderer
  backend <- .normalize_backend(backend)
  backend <- match.arg(backend, c("highcharter", "plotly", "echarts4r", "ggiraph"))
  .assert_backend_supported("map", backend)
  render_fn <- switch(backend,
    highcharter = .viz_map_highcharter,
    plotly      = .viz_map_plotly,
    echarts4r   = .viz_map_echarts,
    ggiraph     = .viz_map_ggiraph
  )
  result <- render_fn(data, config)
  result <- .register_chart_widget(result, backend = backend)
  return(result)
}

# --- Highcharter backend (original implementation) ---
#' @keywords internal
.viz_map_highcharter <- function(data, config) {
  # Unpack config
  map_type <- config$map_type
  value_var <- config$value_var
  join_var <- config$join_var
  map_join_key <- config$map_join_key
  legend_title <- config$legend_title
  title <- config$title
  subtitle <- config$subtitle
  color_stops <- config$color_stops
  color_palette <- config$color_palette
  na_color <- config$na_color
  click_url_template <- config$click_url_template
  click_var <- config$click_var
  tooltip <- config$tooltip
  tooltip_vars <- config$tooltip_vars
  tooltip_format <- config$tooltip_format
  height <- config$height
  border_color <- config$border_color
  border_width <- config$border_width
  credits <- config$credits
  dots <- config$dots

  # Build the base map
  hc <- do.call(highcharter::hcmap, c(list(
    map = map_type,
    data = data,
    value = value_var,
    joinBy = c(map_join_key, join_var),
    name = legend_title,
    borderColor = border_color,
    borderWidth = border_width,
    nullColor = na_color
  ), dots))

  # Add title
  if (!is.null(title)) {
    hc <- hc %>% highcharter::hc_title(text = title)
  }

  # Add subtitle
  if (!is.null(subtitle)) {
    hc <- hc %>% highcharter::hc_subtitle(text = subtitle)
  }

  # Color scale configuration
  if (!is.null(color_stops) && length(color_stops) > 0) {
    # Use explicit stops - normalize breakpoints to 0-1 range
    stop_min <- min(color_stops, na.rm = TRUE)
    stop_max <- max(color_stops, na.rm = TRUE)
    stop_range <- stop_max - stop_min

    # Normalize stop positions to 0-1
    if (stop_range > 0) {
      normalized_positions <- (color_stops - stop_min) / stop_range
    } else {
      normalized_positions <- seq(0, 1, length.out = length(color_stops))
    }

    # Interpolate colors for each stop position
    n_stops <- length(color_stops)
    n_colors <- length(color_palette)

    # Generate colors at the stop positions
    if (n_colors >= n_stops) {
      # Use evenly-spaced colors from palette
      color_indices <- round(seq(1, n_colors, length.out = n_stops))
      stop_colors <- color_palette[color_indices]
    } else {
      # Interpolate colors using colorRampPalette
      color_fn <- grDevices::colorRampPalette(color_palette)
      stop_colors <- color_fn(n_stops)
    }

    # Create stops as list of [position, color] pairs
    custom_stops <- lapply(seq_len(n_stops), function(i) {
      list(normalized_positions[i], stop_colors[i])
    })

    hc <- hc %>% highcharter::hc_colorAxis(
      stops = custom_stops,
      min = stop_min,
      max = stop_max
    )
  } else {
    # Auto scale based on data
    hc <- hc %>% highcharter::hc_colorAxis(
      minColor = color_palette[1],
      maxColor = color_palette[length(color_palette)]
    )
  }

  # Click handler for navigation
  if (!is.null(click_url_template)) {
    # Default click_var to join_var
    if (is.null(click_var)) {
      click_var <- join_var
    }

    # Build JavaScript click handler
    click_js <- sprintf(
      "function() {
        var clickVal = this['%s'] || this.options['%s'] || this.properties['%s'];
        if (clickVal) {
          var url = '%s'.replace('{%s}', clickVal);
          window.location.href = url;
        }
      }",
      click_var, click_var, click_var, click_url_template, click_var
    )

    hc <- hc %>% highcharter::hc_plotOptions(
      series = list(
        cursor = "pointer",
        point = list(
          events = list(click = highcharter::JS(click_js))
        )
      )
    )
  }

  # --- TOOLTIP ---
  # Priority: tooltip_format > tooltip_vars > tooltip > default
  if (!is.null(tooltip_format)) {
    # Legacy: Custom format string (Highcharts syntax) - highest priority for backwards compat
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format)
  } else if (!is.null(tooltip_vars) && length(tooltip_vars) > 0) {
    # Legacy: Build tooltip from variable list
    tooltip_parts <- sapply(tooltip_vars, function(v) {
      paste0(v, ": {point.", v, "}")
    })
    tooltip_format_built <- paste0(
      "<b>{point.name}</b><br/>",
      paste(tooltip_parts, collapse = "<br/>")
    )
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format_built)
  } else if (!is.null(tooltip)) {
    # Use new unified tooltip system
    tooltip_result <- .process_tooltip_config(
      tooltip = tooltip,
      tooltip_prefix = NULL,
      tooltip_suffix = NULL,
      x_tooltip_suffix = NULL,
      chart_type = "map",
      context = list()
    )
    hc <- .apply_tooltip_to_hc(hc, tooltip_result)
  }

  # Chart configuration
  hc <- hc %>% highcharter::hc_chart(height = height)

  # Credits
  if (!credits) {
    hc <- hc %>% highcharter::hc_credits(enabled = FALSE)
  }

  # Add map navigation (zoom controls)
  hc <- hc %>% highcharter::hc_mapNavigation(
    enabled = TRUE,
    buttonOptions = list(
      verticalAlign = "bottom"
    )
  )

  hc
}

# --- Plotly backend ---
#' @keywords internal
.viz_map_plotly <- function(data, config) {
  rlang::check_installed("plotly", reason = "for plotly map backend")

  value_var <- config$value_var
  join_var <- config$join_var
  title <- config$title
  color_palette <- config$color_palette
  height <- config$height

  # Determine location mode from join key
  location_mode <- if (mean(nchar(as.character(data[[join_var]])), na.rm = TRUE) > 2.5) {
    "ISO-3"
  } else {
    "ISO-3"
  }

  p <- plotly::plot_ly(
    data = data,
    type = "choropleth",
    locations = stats::as.formula(paste0("~`", join_var, "`")),
    z = stats::as.formula(paste0("~`", value_var, "`")),
    locationmode = location_mode,
    colorscale = list(c(0, color_palette[1]), c(1, color_palette[length(color_palette)])),
    marker = list(line = list(color = config$border_color, width = config$border_width))
  )

  if (!is.null(title)) {
    p <- p %>% plotly::layout(title = title, height = height)
  } else {
    p <- p %>% plotly::layout(height = height)
  }

  p
}

# --- echarts4r backend ---
#' @keywords internal
.viz_map_echarts <- function(data, config) {
  rlang::check_installed("echarts4r", reason = "for echarts4r map backend")

  value_var <- config$value_var
  join_var <- config$join_var
  title <- config$title
  color_palette <- config$color_palette

  chart <- data %>%
    echarts4r::e_charts_(join_var) %>%
    echarts4r::e_map_(value_var) %>%
    echarts4r::e_visual_map_(value_var,
      inRange = list(color = color_palette)
    )

  if (!is.null(title)) {
    chart <- chart %>% echarts4r::e_title(title)
  }

  chart
}

# --- ggiraph backend ---
#' @keywords internal
.viz_map_ggiraph <- function(data, config) {
  rlang::check_installed("ggiraph", reason = "for ggiraph map backend")
  rlang::check_installed("sf", reason = "for ggiraph map backend")
  rlang::check_installed("rnaturalearth", reason = "for ggiraph map backend")

  value_var <- config$value_var
  join_var <- config$join_var
  title <- config$title
  color_palette <- config$color_palette
  height <- config$height

  # Get world map data
  world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

  # Determine join column in world data
  world_join <- if (mean(nchar(as.character(data[[join_var]])), na.rm = TRUE) > 2.5) {
    "iso_a3"
  } else {
    "iso_a2"
  }

  # Merge data
  world_merged <- merge(world, data, by.x = world_join, by.y = join_var, all.x = TRUE)

  p <- ggplot2::ggplot(world_merged) +
    ggiraph::geom_sf_interactive(
      ggplot2::aes(
        fill = .data[[value_var]],
        tooltip = paste0(.data[["name"]], ": ", .data[[value_var]]),
        data_id = .data[[world_join]]
      )
    ) +
    ggplot2::scale_fill_gradient(
      low = color_palette[1],
      high = color_palette[length(color_palette)],
      na.value = config$na_color
    ) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = title, fill = config$legend_title)

  ggiraph::girafe(ggobj = p, height_svg = height / 96)
}
