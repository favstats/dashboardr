# Create a Timeline Chart

Creates interactive timeline visualizations showing changes in survey
responses over time, or simple line charts for pre-aggregated time
series data. Supports multiple chart types including stacked areas, line
charts, and diverging bar charts.

## Usage

``` r
viz_timeline(
  data,
  time_var,
  y_var,
  group_var = NULL,
  agg = c("percentage", "mean", "sum", "none"),
  chart_type = "line",
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  y_max = NULL,
  y_min = NULL,
  color_palette = NULL,
  y_levels = NULL,
  y_breaks = NULL,
  y_bin_labels = NULL,
  y_map_values = NULL,
  y_filter = NULL,
  y_filter_combine = TRUE,
  y_filter_label = NULL,
  time_breaks = NULL,
  time_bin_labels = NULL,
  weight_var = NULL,
  include_na = FALSE,
  na_label_y = "(Missing)",
  na_label_group = "(Missing)",
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = ""
)
```

## Arguments

- data:

  A data frame containing time series data.

- time_var:

  Character string. Name of the time variable (e.g., "year", "wave").

- y_var:

  Character string. Name of the response/value variable.

- group_var:

  Optional character string. Name of grouping variable for separate
  series (e.g., "country", "gender"). Creates separate lines/areas for
  each group.

- agg:

  Character string specifying aggregation method:

  - `"percentage"` (default): Count responses and calculate percentages
    per time period. Use for survey data with categorical responses.

  - `"mean"`: Calculate mean of y_var per time period (and group if
    specified).

  - `"sum"`: Calculate sum of y_var per time period (and group if
    specified).

  - `"none"`: Use values directly without aggregation. Use for
    pre-aggregated data where each row represents one observation per
    time/group combination.

- chart_type:

  Character string. Type of chart: "line" (default) or "stacked_area".

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional character string. Label for the x-axis. Defaults to time_var
  name.

- y_label:

  Optional character string. Label for the y-axis. Defaults to
  "Percentage" for `agg = "percentage"`, or y_var name for other modes.

- y_max:

  Optional numeric value. Maximum value for the Y-axis.

- y_min:

  Optional numeric value. Minimum value for the Y-axis.

- color_palette:

  Optional character vector of color hex codes for the series.

- y_levels:

  Optional character vector specifying order of response categories.

- y_breaks:

  Optional numeric vector for binning numeric response values (e.g.,
  `c(0, 2.5, 5, 7)` to create bins 0-2.5, 2.5-5, 5-7).

- y_bin_labels:

  Optional character vector of labels for response bins (e.g.,
  `c("Low (1-2)", "Medium (3-5)", "High (6-7)")`).

- y_map_values:

  Optional named list to rename response values for display (e.g.,
  `list("1" = "Correct", "0" = "Incorrect")`). Applied to legend labels
  and data.

- y_filter:

  Optional numeric or character vector specifying which response values
  to include. For numeric responses, use a range like `5:7` to show only
  values 5, 6, and 7. For categorical responses, use category names like
  `c("Agree", "Strongly Agree")`. Applied BEFORE binning (filters raw
  values first, then bins the filtered data).

- y_filter_combine:

  Logical. When `y_filter` is used, should filtered values be combined
  into a single percentage? Defaults to `TRUE` (show combined % of all
  filtered values). Set to `FALSE` to show separate lines for each
  filtered value.

- y_filter_label:

  Character string. Custom label for the filtered responses in the
  legend. Only used when `y_filter` and `y_filter_combine = TRUE`. If
  `NULL` (default) and `group_var` is provided, shows only group names
  in legend (e.g., "AgeGroup1"). If `NULL` and no `group_var`, uses
  auto-generated label (e.g., "5-7" for `y_filter = 5:7`).

- time_breaks:

  Optional numeric vector for binning continuous time variables.

- time_bin_labels:

  Optional character vector of labels for time bins.

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders: `{x}`,
  `{y}`, `{value}`, `{series}`, `{percent}`. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended to values in tooltip.

- tooltip_suffix:

  Optional string appended to values in tooltip.

## Value

A highcharter plot object.

## Examples

``` r
# Load GSS data
data(gss_all)

# Basic timeline - confidence in institutions over time
plot1 <- viz_timeline(
           data = gss_all,
           time_var = "year",
           y_var = "confinan",
           title = "Confidence in Financial Institutions Over Time",
           y_max = 100
           )
plot1

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"line"},"title":{"text":"Confidence in Financial Institutions Over Time"},"yAxis":{"title":{"text":"Percentage"},"max":100},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"title":{"text":"year"},"allowDecimals":false},"series":[{"name":"a great deal","data":[[1975,32.9],[1976,40.5],[1977,42.7],[1978,33.4],[1980,32.5],[1982,26.4],[1983,24.1],[1984,32.5],[1986,21.4],[1987,28],[1988,27.4],[1989,19.4],[1990,18.2],[1991,12.6],[1993,15.3],[1994,18],[1996,25.4],[1998,26.3],[2000,29.9],[2002,22.4],[2004,28.2],[2006,30.6],[2008,19.5],[2010,10.6],[2012,11.2],[2014,14.3],[2016,14.1],[2018,19.2],[2021,18.1],[2022,16.6],[2024,17.4]],"type":"line","color":null},{"name":"only some","data":[[1975,55.7],[1976,49.2],[1977,48.3],[1978,54.7],[1980,51.8],[1982,57],[1983,59.7],[1984,56.5],[1986,60.8],[1987,57.8],[1988,59],[1989,60.7],[1990,59.2],[1991,52.8],[1993,58],[1994,61.6],[1996,57.7],[1998,57.3],[2000,55.6],[2002,59.1],[2004,57.5],[2006,54.8],[2008,59.7],[2010,48.1],[2012,51.2],[2014,53.2],[2016,54.4],[2018,56.3],[2021,59.8],[2022,57.9],[2024,56.7]],"type":"line","color":null},{"name":"hardly any","data":[[1975,11.4],[1976,10.2],[1977,9],[1978,11.9],[1980,15.7],[1982,16.6],[1983,16.2],[1984,11],[1986,17.8],[1987,14.3],[1988,13.6],[1989,20],[1990,22.6],[1991,34.6],[1993,26.7],[1994,20.4],[1996,16.9],[1998,16.4],[2000,14.4],[2002,18.6],[2004,14.3],[2006,14.6],[2008,20.8],[2010,41.3],[2012,37.6],[2014,32.4],[2016,31.6],[2018,24.5],[2021,22],[2022,25.5],[2024,25.9]],"type":"line","color":null}],"tooltip":{"useHTML":true,"headerFormat":"<b>{point.x}<\/b><br>","pointFormat":"{series.name}: {point.y:.1f}%"}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":[],"jsHooks":[]}
# Line chart by gender
plot2 <- viz_timeline(
   data = gss_all,
   time_var = "year",
   y_var = "happy",
   group_var = "sex",
   chart_type = "line",
   title = "Happiness Trends by Gender",
   y_levels = c("very happy", "pretty happy", "not too happy")
)
plot2

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"line"},"title":{"text":"Happiness Trends by Gender"},"yAxis":{"title":{"text":"Percentage"}},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"title":{"text":"year"},"allowDecimals":false},"series":[{"name":"very happy - male","data":[[1972,28.7],[1973,33.7],[1974,33.8],[1975,31.5],[1976,33],[1977,32.7],[1978,34.7],[1980,31],[1982,28.8],[1983,31.2],[1984,31.7],[1985,29.1],[1986,30.3],[1987,28.3],[1988,35.8],[1989,32.2],[1990,34.1],[1991,32.5],[1993,29.5],[1994,29.9],[1996,32],[1998,30.6],[2000,31.2],[2002,32.4],[2004,29.6],[2006,30.4],[2008,29.1],[2010,25.1],[2012,29.2],[2014,29.6],[2016,28.6],[2018,29.6],[2021,21.7],[2022,22.8],[2024,20.2]],"type":"line","color":null},{"name":"very happy - female","data":[[1972,31.8],[1973,37.8],[1974,41.5],[1975,33.9],[1976,34.9],[1977,36.6],[1978,34.1],[1980,36.2],[1982,31.9],[1983,31.1],[1984,36.8],[1985,28.3],[1986,33.7],[1987,29.7],[1988,32.6],[1989,33],[1990,32.9],[1991,30],[1993,33.2],[1994,28],[1996,29.1],[1998,32.6],[2000,32.1],[2002,28.5],[2004,32.9],[2006,31.1],[2008,30.2],[2010,27.4],[2012,31],[2014,32.2],[2016,27.9],[2018,30.1],[2021,17.7],[2022,21.6],[2024,21.3]],"type":"line","color":null},{"name":"pretty happy - male","data":[[1972,53.2],[1973,53.9],[1974,52],[1975,56.2],[1976,54.3],[1977,56],[1978,55.1],[1980,55.3],[1982,56.6],[1983,55.9],[1984,53.8],[1985,59.6],[1986,58.2],[1987,57.5],[1988,56.3],[1989,58.7],[1990,57.2],[1991,59.1],[1993,60.4],[1994,58.8],[1996,56.7],[1998,58.5],[2000,58.1],[2002,58.2],[2004,55.3],[2006,57],[2008,55.6],[2010,58],[2012,57],[2014,55.4],[2016,56.4],[2018,55.5],[2021,55],[2022,54.3],[2024,57.1]],"type":"line","color":null},{"name":"pretty happy - female","data":[[1972,53.3],[1973,48.6],[1974,46.3],[1975,52.4],[1976,52.7],[1977,51],[1978,56.8],[1980,50.7],[1982,53.7],[1983,56.2],[1984,51.3],[1985,60.3],[1986,54.9],[1987,57.4],[1988,57.1],[1989,56.9],[1990,57.9],[1991,57.2],[1993,55],[1994,59.1],[1996,58.2],[1998,54.3],[2000,57.5],[2002,56.4],[2004,55.1],[2006,55.5],[2008,53.8],[2010,58.1],[2012,54.7],[2014,55.5],[2016,55.7],[2018,56],[2021,59],[2022,55.9],[2024,58.2]],"type":"line","color":null},{"name":"not too happy - male","data":[[1972,18.1],[1973,12.5],[1974,14.2],[1975,12.3],[1976,12.7],[1977,11.3],[1978,10.2],[1980,13.6],[1982,14.6],[1983,12.9],[1984,14.5],[1985,11.3],[1986,11.4],[1987,14.2],[1988,7.9],[1989,9.1],[1990,8.699999999999999],[1991,8.4],[1993,10.1],[1994,11.3],[1996,11.3],[1998,10.9],[2000,10.7],[2002,9.4],[2004,15.1],[2006,12.6],[2008,15.3],[2010,17],[2012,13.8],[2014,15],[2016,15],[2018,14.9],[2021,23.2],[2022,22.9],[2024,22.7]],"type":"line","color":null},{"name":"not too happy - female","data":[[1972,14.9],[1973,13.6],[1974,12.2],[1975,13.7],[1976,12.4],[1977,12.4],[1978,9.1],[1980,13.1],[1982,14.4],[1983,12.7],[1984,11.9],[1985,11.4],[1986,11.4],[1987,12.9],[1988,10.3],[1989,10.1],[1990,9.199999999999999],[1991,12.9],[1993,11.9],[1994,12.9],[1996,12.7],[1998,13],[2000,10.4],[2002,15.1],[2004,12],[2006,13.4],[2008,16],[2010,14.4],[2012,14.3],[2014,12.3],[2016,16.5],[2018,13.9],[2021,23.2],[2022,22.5],[2024,20.4]],"type":"line","color":null}],"tooltip":{"useHTML":true,"headerFormat":"<b>{point.x}<\/b><br>","pointFormat":"{series.name}: {point.y:.1f}%"}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":[],"jsHooks":[]}
# Show only high responses (5-7 on a 1-7 scale) - COMBINED
plot3 <- viz_timeline(
   data = survey_data,
   time_var = "wave",
   y_var = "agreement",  # 1-7 scale
   group_var = "age_group",
   chart_type = "line",
   y_filter = 5:7,  # Show combined % who responded 5-7
   title = "% High Agreement (5-7) Over Time"
)
#> Error: object 'survey_data' not found
plot3
#> Error: object 'plot3' not found

# Custom legend label
plot4 <- viz_timeline(
   data = survey_data,
   time_var = "wave",
   y_var = "agreement",
   group_var = "age_group",
   chart_type = "line",
   y_filter = 5:7,
   y_filter_label = "High Agreement",  # Custom label instead of "5-7"
   title = "High Agreement Trends"
)
#> Error: object 'survey_data' not found
plot4
#> Error: object 'plot4' not found

# Show individual filtered values (not combined)
plot5 <- viz_timeline(
   data = survey_data,
   time_var = "wave",
   y_var = "agreement",
   chart_type = "line",
   y_filter = 5:7,
   y_filter_combine = FALSE,  # Show separate lines for 5, 6, 7
   title = "Individual High Responses"
)
#> Error: object 'survey_data' not found
plot5
#> Error: object 'plot5' not found

# Custom styling with colors and labels
plot6 <- viz_timeline(
   data = survey_data,
   time_var = "wave_time_label",
   y_var = "agreement",
   group_var = "age_group",
   chart_type = "line",
   y_filter = 4:5,
   title = "High Agreement Over Time",
   subtitle = "By Age Group",
   x_label = "Survey Wave",
   y_label = "% High Agreement",
   y_min = 0,
   y_max = 100,
   color_palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3")
)
#> Error: object 'survey_data' not found
plot6
#> Error: object 'plot6' not found

# Custom legend labels with y_map_values
plot7 <- viz_timeline(
   data = survey_data,
   time_var = "wave_time_label",
   y_var = "knowledge_item",
   chart_type = "line",
   y_filter = 1,
   y_map_values = list("1" = "Correct", "0" = "Incorrect"),
   title = "Knowledge Score Over Time",
   x_label = "Survey Wave",
   y_label = "% Correct",
   y_min = 0,
   y_max = 100
)
#> Error: object 'survey_data' not found
plot7
#> Error: object 'plot7' not found
```
