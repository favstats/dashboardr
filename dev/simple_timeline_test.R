# Define the %||% operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Test with minimal data first
test_data <- data.frame(
  year = rep(2020:2022, each = 3),
  response = rep(c("Good", "Bad", "Neutral"), 3)
)

#simple call
simple_plot <- create_timeline(
  data = test_data,
  time_var = "year",
  response_var = "response",
  chart_type = "stacked_area"
)


simple_plot
