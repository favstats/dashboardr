# Create Bar Chart

Creates horizontal or vertical bar charts showing counts, percentages,
or means. Supports simple bars or grouped bars (when `group_var` is
provided). Can display error bars (standard deviation, standard error,
or confidence intervals) when showing means via `value_var`.

## Usage

``` r
viz_bar(
  data,
  x_var,
  group_var = NULL,
  value_var = NULL,
  title = NULL,
  subtitle = NULL,
  x_label = NULL,
  y_label = NULL,
  horizontal = FALSE,
  bar_type = "count",
  color_palette = NULL,
  group_order = NULL,
  x_order = NULL,
  sort_by_value = FALSE,
  sort_desc = TRUE,
  x_breaks = NULL,
  x_bin_labels = NULL,
  include_na = FALSE,
  na_label = "(Missing)",
  weight_var = NULL,
  error_bars = "none",
  ci_level = 0.95,
  error_bar_color = "black",
  error_bar_width = 50,
  tooltip = NULL,
  tooltip_prefix = "",
  tooltip_suffix = "",
  x_tooltip_suffix = "",
  data_labels_enabled = TRUE
)
```

## Arguments

- data:

  A data frame containing the survey data.

- x_var:

  Character string. Name of the categorical variable for the x-axis.

- group_var:

  Optional character string. Name of grouping variable to create
  separate bars (e.g., score ranges, categories). Creates
  grouped/clustered bars.

- value_var:

  Optional character string. Name of a numeric variable to aggregate.
  When provided, bars show the mean of this variable per category
  (instead of counts). Required for error bars with "sd", "se", or "ci".

- title:

  Optional main title for the chart.

- subtitle:

  Optional subtitle for the chart.

- x_label:

  Optional label for the x-axis. Defaults to `x_var` name.

- y_label:

  Optional label for the y-axis.

- horizontal:

  Logical. If `TRUE`, creates horizontal bars. Defaults to `FALSE`.

- bar_type:

  Character string. Type of bar chart: "count", "percent", or "mean".
  Defaults to "count". When `value_var` is provided, automatically
  switches to "mean".

- color_palette:

  Optional character vector of colors for the bars.

- group_order:

  Optional character vector specifying the order of groups (for
  `group_var`).

- x_order:

  Optional character vector specifying the order of x categories.

- sort_by_value:

  Logical. If `TRUE`, sort categories by their value (highest on top for
  horizontal bars).

- sort_desc:

  Logical. If `sort_by_value = TRUE`, sort descending (default) or
  ascending.

- x_breaks:

  Optional numeric vector for binning continuous x variables.

- x_bin_labels:

  Optional character vector of labels for x bins.

- include_na:

  Logical. Whether to include NA values as a separate category. Defaults
  to `FALSE`.

- na_label:

  Character string. Label for NA category if `include_na = TRUE`.
  Defaults to "(Missing)".

- weight_var:

  Optional character string. Name of a weight variable to use for
  weighted aggregation. When provided, counts are computed as the sum of
  weights instead of simple counts.

- error_bars:

  Character string. Type of error bars to display: "none" (default),
  "sd" (standard deviation), "se" (standard error), or "ci" (confidence
  interval). Requires `value_var` to be specified.

- ci_level:

  Numeric. Confidence level for confidence intervals. Defaults to 0.95
  (95% CI). Only used when `error_bars = "ci"`.

- error_bar_color:

  Character string. Color for error bars. Defaults to "black".

- error_bar_width:

  Numeric. Width of error bar whiskers as percentage (0-100). Defaults
  to 50.

- tooltip:

  A tooltip configuration created with
  [`tooltip()`](https://favstats.github.io/dashboardr/reference/tooltip.md),
  OR a format string with {placeholders}. Available placeholders:
  `{category}`, `{value}`, `{percent}`, `{series}`. For simple cases,
  use `tooltip_prefix` and `tooltip_suffix` instead. See
  [`tooltip`](https://favstats.github.io/dashboardr/reference/tooltip.md)
  for full customization options.

- tooltip_prefix:

  Optional string prepended to tooltip values (simple customization).

- tooltip_suffix:

  Optional string appended to tooltip values (simple customization).

- x_tooltip_suffix:

  Optional string appended to x-axis category in tooltips.

- data_labels_enabled:

  Logical. If TRUE, show value labels on bars. Default TRUE.

## Value

A highcharter plot object.

## Examples

``` r
# Simple bar chart showing counts (default)
plot1 <- viz_bar(
  data = survey_data,
  x_var = "category"
)
#> Error: object 'survey_data' not found
plot1
#> Error: object 'plot1' not found

# Horizontal bars with percentages
plot2 <- viz_bar(
  data = survey_data,
  x_var = "category",
  horizontal = TRUE,
  bar_type = "percent"
)
#> Error: object 'survey_data' not found
plot2
#> Error: object 'plot2' not found

# Grouped bars
plot3 <- viz_bar(
  data = survey_data,
  x_var = "question",
  group_var = "score_range",
  color_palette = c("#D2691E", "#4682B4", "#228B22"),
  group_order = c("Low (1-9)", "Middle (10-19)", "High (20-29)")
)
#> Error: object 'survey_data' not found
plot3
#> Error: object 'plot3' not found

# Bar chart with means and error bars (95% CI)
plot4 <- viz_bar(
  data = mtcars,
  x_var = "cyl",
  value_var = "mpg",
  error_bars = "ci",
  title = "Mean MPG by Cylinders",
  y_label = "Miles per Gallon"
)
plot4

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"column"},"title":{"text":"Mean MPG by Cylinders"},"yAxis":{"title":{"text":"Miles per Gallon"}},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0,"dataLabels":{"enabled":true,"format":"{point.y:.1f}"}},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"categories":["4","6","8"],"title":{"text":"cyl"}},"series":[{"data":[26.66,19.74,15.1],"name":"Miles per Gallon","id":"main_series","showInLegend":false,"colorByPoint":true},{"type":"errorbar","name":"CI Error","data":[{"low":23.63,"high":29.69},{"low":18.4,"high":21.09},{"low":13.62,"high":16.58}],"linkedTo":"main_series","showInLegend":false,"enableMouseTracking":true,"whiskerLength":"50%","color":"black","stemWidth":1.5}],"tooltip":{"formatter":"function() {\n             if (this.series.type === 'errorbar') {\n               return '<b>' + this.series.chart.xAxis[0].categories[this.point.x] + '<\/b><br/>' +\n                      '95% CI: ' + this.point.low.toFixed(2) + ' - ' + this.point.high.toFixed(2);\n             }\n             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;\n             return '<b>' + cat + '<\/b><br/>' +\n                    'Mean: ' + this.y.toFixed(2) + '';\n           }","useHTML":true}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":["hc_opts.tooltip.formatter"],"jsHooks":[]}
# Grouped means with standard error bars
plot5 <- viz_bar(
  data = mtcars,
  x_var = "cyl",
  group_var = "am",
  value_var = "mpg",
  error_bars = "se",
  title = "Mean MPG by Cylinders and Transmission"
)
plot5

{"x":{"hc_opts":{"chart":{"reflow":true,"type":"column"},"title":{"text":"Mean MPG by Cylinders and Transmission"},"yAxis":{"title":{"text":"Mean mpg"}},"credits":{"enabled":false},"exporting":{"enabled":false},"boost":{"enabled":false},"plotOptions":{"series":{"label":{"enabled":false},"turboThreshold":0,"dataLabels":{"enabled":true,"format":"{point.y:.1f}"}},"treemap":{"layoutAlgorithm":"squarified"}},"xAxis":{"categories":["4","6","8"],"title":{"text":"cyl"}},"series":[{"data":[22.9,19.12,15.05],"name":"0","id":"series_1"},{"data":[28.08,20.57,15.4],"name":"1","id":"series_2"},{"type":"errorbar","name":"0 SE","data":[{"low":22.06,"high":23.74},{"low":18.31,"high":19.94},{"low":14.25,"high":15.85}],"linkedTo":"series_1","showInLegend":false,"enableMouseTracking":true,"whiskerLength":"50%","color":"black","stemWidth":1.5},{"type":"errorbar","name":"1 SE","data":[{"low":26.49,"high":29.66},{"low":20.13,"high":21},{"low":15,"high":15.8}],"linkedTo":"series_2","showInLegend":false,"enableMouseTracking":true,"whiskerLength":"50%","color":"black","stemWidth":1.5}],"tooltip":{"formatter":"function() {\n             if (this.series.type === 'errorbar') {\n               var cat = this.series.chart.xAxis[0].categories[this.point.x];\n               return '<b>' + cat + '<\/b><br/>' +\n                      'SE: ' + this.point.low.toFixed(2) + ' - ' + this.point.high.toFixed(2);\n             }\n             var cat = this.point.category || this.series.chart.xAxis[0].categories[this.point.x] || this.x;\n             return '<b>' + cat + '<\/b><br/>' +\n                    this.series.name + ': ' + this.y.toFixed(2) + '';\n           }","useHTML":true}},"theme":{"chart":{"backgroundColor":"transparent"},"colors":["#7cb5ec","#434348","#90ed7d","#f7a35c","#8085e9","#f15c80","#e4d354","#2b908f","#f45b5b","#91e8e1"]},"conf_opts":{"global":{"Date":null,"VMLRadialGradientURL":"http =//code.highcharts.com/list(version)/gfx/vml-radial-gradient.png","canvasToolsURL":"http =//code.highcharts.com/list(version)/modules/canvas-tools.js","getTimezoneOffset":null,"timezoneOffset":0,"useUTC":true},"lang":{"contextButtonTitle":"Chart context menu","decimalPoint":".","downloadCSV":"Download CSV","downloadJPEG":"Download JPEG image","downloadPDF":"Download PDF document","downloadPNG":"Download PNG image","downloadSVG":"Download SVG vector image","downloadXLS":"Download XLS","drillUpText":"◁ Back to {series.name}","exitFullscreen":"Exit from full screen","exportData":{"annotationHeader":"Annotations","categoryDatetimeHeader":"DateTime","categoryHeader":"Category"},"hideData":"Hide data table","invalidDate":null,"loading":"Loading...","months":["January","February","March","April","May","June","July","August","September","October","November","December"],"noData":"No data to display","numericSymbolMagnitude":1000,"numericSymbols":["k","M","G","T","P","E"],"printChart":"Print chart","resetZoom":"Reset zoom","resetZoomTitle":"Reset zoom level 1:1","shortMonths":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"shortWeekdays":["Sat","Sun","Mon","Tue","Wed","Thu","Fri"],"thousandsSep":" ","viewData":"View data table","viewFullscreen":"View in full screen","weekdays":["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]}},"type":"chart","fonts":[],"debug":false},"evals":["hc_opts.tooltip.formatter"],"jsHooks":[]}
```
