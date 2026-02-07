# Select

# Select

## Select Dropdown Input

The **select** input creates a searchable dropdown. Use
`select_multiple` for multi-select or `select_single` for single
selection.

This example uses **grouped options** to organize countries by region:

``` r
add_input(
  input_id = "country_filter",
  label = "Select Countries",
  type = "select_multiple",
  filter_var = "country",
  options = list(
    "Americas" = c("United States", "Brazil"),
    "Europe" = c("United Kingdom", "Germany", "France"),
    "Asia-Pacific" = c("Japan", "China", "Australia"),
    "Benchmarks" = c("Global Average")
  ),
  default_selected = c("United States", "Germany"),
  placeholder = "Choose countries to compare...",
  width = "500px"
)
```

Select Countries United States Brazil United Kingdom Germany France
Japan China Australia Global AverageCountries are grouped by region.
Select multiple to compare.

## Female Authorship Trends
