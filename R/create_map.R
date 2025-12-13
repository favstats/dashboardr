# =================================================================
# create_map.R - Interactive Map Visualization
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
#' @param tooltip_vars Character vector of variables to show in tooltip
#' @param tooltip_format Custom tooltip format string (overrides tooltip_vars)
#' @param height Chart height in pixels (default: 500)
#' @param border_color Border color between regions (default: "#FFFFFF")
#' @param border_width Border width (default: 0.5
#' @param credits Show Highcharts credits (default: FALSE)
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
#' create_map(
#'   data = country_data,
#'   value_var = "total_ads",
#'   join_var = "iso2c",
#'   title = "Ad Spending by Country"
#' )
#'
#' # With click navigation to country dashboards
#' create_map(
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
create_map <- function(
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
    tooltip_vars = NULL,
    tooltip_format = NULL,
    height = 500,
    border_color = "#FFFFFF",
    border_width = 0.5,
    credits = FALSE,
    ...
) {
  # Validate required parameters


  if (missing(value_var) || is.null(value_var)) {
    stop("value_var is required for create_map()")
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

  # Determine map join key based on map type
  # World maps use "iso-a2", US maps use different keys

  map_join_key <- if (grepl("world", map_type, ignore.case = TRUE)) {
    "iso-a2"
  } else if (grepl("us-all|usa", map_type, ignore.case = TRUE)) {
    "postal-code"
  } else {
    "hc-key"  # Generic fallback

  }

  # Build the base map
  hc <- highcharter::hcmap(
    map = map_type,
    data = data,
    value = value_var,
    joinBy = c(map_join_key, join_var),
    name = legend_title,
    borderColor = border_color,
    borderWidth = border_width,
    nullColor = na_color,
    ...
  )

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
    # Use explicit stops
    n_stops <- length(color_stops)
    hc <- hc %>% highcharter::hc_colorAxis(
      stops = highcharter::color_stops(n_stops, color_palette),
      min = min(color_stops, na.rm = TRUE),
      max = max(color_stops, na.rm = TRUE)
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
    # Need to handle both point properties and options
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

  # Tooltip configuration
  if (!is.null(tooltip_format)) {
    # Custom format string
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format)
  } else if (!is.null(tooltip_vars) && length(tooltip_vars) > 0) {
    # Build tooltip from variable list
    tooltip_parts <- sapply(tooltip_vars, function(v) {
      paste0(v, ": {point.", v, "}")
    })
    tooltip_format <- paste0(
      "<b>{point.name}</b><br/>",
      paste(tooltip_parts, collapse = "<br/>")
    )
    hc <- hc %>% highcharter::hc_tooltip(pointFormat = tooltip_format)
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
