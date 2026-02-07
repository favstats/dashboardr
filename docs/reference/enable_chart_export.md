# Enable chart export buttons (PNG/SVG/PDF/CSV)

Injects a script that enables Highcharts export functionality on all
charts. Charts will display a hamburger menu button that allows
downloading in various formats (PNG, SVG, PDF, CSV, full-screen view).

## Usage

``` r
enable_chart_export()
```

## Value

HTML script tag that enables chart exporting

## Details

This is typically called automatically when `chart_export = TRUE` is set
in
[`create_dashboard()`](https://favstats.github.io/dashboardr/reference/create_dashboard.md).
