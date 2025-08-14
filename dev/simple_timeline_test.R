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

# Let's try using more complex data
# Load GSS data
data(gss_all)

# Basic timeline - confidence in institutions over time
plot1 <- create_timeline(
  data = gss_all,
  time_var = "year",
  response_var = "confinan",
  chart_type = "stacked_area",
  title = "Confidence in Financial Institutions Over Time",
  response_levels = c("A Great Deal", "Only Some", "Hardly Any")
)

plot1
# Blank chart

# debug
# first, let's check what the aggregated data looks like
debug_timeline <- function(data, time_var, response_var) {

  # Step 1: Check raw data
  cat("Step 1 - Raw data sample:\n")
  raw_sample <- data %>%
    select(all_of(c(time_var, response_var))) %>%
    slice_head(n = 10)
  print(raw_sample)

  # Step 2: After filtering NAs
  cat("\nStep 2 - After filtering NAs:\n")
  filtered_data <- data %>%
    select(all_of(c(time_var, response_var))) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(response_var)))
  cat("Rows remaining:", nrow(filtered_data), "\n")
  print(head(filtered_data))

  # Step 3: Handle haven_labelled
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(filtered_data[[response_var]], "haven_labelled")) {
      filtered_data <- filtered_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
      cat("\nStep 3 - After converting haven_labelled:\n")
      print(head(filtered_data))
    }
  }

  # Step 4: Check aggregated data
  cat("\nStep 4 - Aggregated data:\n")
  agg_data <- filtered_data %>%
    count(!!sym(time_var), !!sym(response_var), name = "count") %>%
    group_by(!!sym(time_var)) %>%
    mutate(percentage = round(count / sum(count) * 100, 1)) %>%
    ungroup()

  print(head(agg_data, n = 20))

  return(agg_data)
}

# Run the debug function
debug_data <- debug_timeline(gss_all, "year", "confinan")


create_timeline_fixed <- function(data, time_var, response_var, chart_type = "stacked_area", title = NULL, y_max = NULL) {

  # Basic data processing
  plot_data <- data %>%
    select(all_of(c(time_var, response_var))) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(response_var)))

  # Handle haven_labelled variables for BOTH time and response variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[time_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(time_var) := as.numeric(!!sym(time_var)))
    }
    if (inherits(plot_data[[response_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
    }
  }

  # Aggregate data
  agg_data <- plot_data %>%
    count(!!sym(time_var), !!sym(response_var), name = "count") %>%
    group_by(!!sym(time_var)) %>%
    mutate(percentage = round(count / sum(count) * 100, 1)) %>%
    ungroup()

  # Create chart manually by adding series one by one
  hc <- highchart() %>%
    hc_chart(type = "area") %>%
    hc_plotOptions(area = list(stacking = "normal")) %>%
    hc_title(text = title) %>%
    hc_yAxis(title = list(text = "Percentage"), max = y_max) %>%
    hc_xAxis(title = list(text = "Year"))

  # Add each response category as a separate series
  response_levels <- unique(agg_data[[response_var]])

  for(level in response_levels) {
    series_data <- agg_data %>%
      filter(!!sym(response_var) == level) %>%
      arrange(!!sym(time_var)) %>%
      select(x = !!sym(time_var), y = percentage)

    hc <- hc %>%
      hc_add_series(
        name = as.character(level),
        data = list_parse2(series_data),
        type = "area"
      )
  }

  return(hc)
}

# Test with y_max set to 100
plot1 <- create_timeline_fixed(
  data = gss_all,
  time_var = "year",
  response_var = "confinan",
  title = "Confidence in Financial Institutions Over Time",
  y_max = 100
)

plot1

# Test the fixed function
plot1 <- create_timeline_fixed(
  data = gss_all,
  time_var = "year",
  response_var = "confinan",
  title = "Confidence in Financial Institutions Over Time"
)

plot1

# Now let's try to add support for grouping variables, different chart types, and response level ordering

create_timeline_fixed <- function(data, time_var, response_var, group_var = NULL,
                                  chart_type = "stacked_area", title = NULL, y_max = NULL,
                                  response_levels = NULL) {

  # Basic data processing
  vars_to_select <- c(time_var, response_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)

  plot_data <- data %>%
    select(all_of(vars_to_select)) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(response_var)))

  if (!is.null(group_var)) {
    plot_data <- plot_data %>% filter(!is.na(!!sym(group_var)))
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[time_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(time_var) := as.numeric(!!sym(time_var)))
    }
    if (inherits(plot_data[[response_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
    }
    if (!is.null(group_var) && inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(group_var) := haven::as_factor(!!sym(group_var), levels = "labels"))
    }
  }

  # Apply response level ordering if specified
  if (!is.null(response_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var), levels = response_levels))
  }

  # Aggregate data
  if (is.null(group_var)) {
    agg_data <- plot_data %>%
      count(!!sym(time_var), !!sym(response_var), name = "count") %>%
      group_by(!!sym(time_var)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  } else {
    agg_data <- plot_data %>%
      count(!!sym(time_var), !!sym(response_var), !!sym(group_var), name = "count") %>%
      group_by(!!sym(time_var), !!sym(group_var)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  }

  # Create base chart
  hc <- highchart() %>%
    hc_title(text = title) %>%
    hc_yAxis(title = list(text = "Percentage"), max = y_max) %>%
    hc_xAxis(title = list(text = "Year"))

  # Create chart based on type
  if (chart_type == "stacked_area") {
    hc <- hc %>%
      hc_chart(type = "area") %>%
      hc_plotOptions(area = list(stacking = "normal"))

    if (is.null(group_var)) {
      # Simple stacked area
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var)) %>%
          select(x = !!sym(time_var), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "area"
          )
      }
    }

  } else if (chart_type == "line") {
    hc <- hc %>% hc_chart(type = "line")

    if (is.null(group_var)) {
      # Simple line chart by response
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var)) %>%
          select(x = !!sym(time_var), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "line"
          )
      }
    } else {
      # Line chart with grouping - create series for each response-group combination
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      group_levels <- unique(agg_data[[group_var]])

      for(resp_level in response_levels_to_use) {
        for(group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(response_var) == resp_level, !!sym(group_var) == group_level) %>%
            arrange(!!sym(time_var)) %>%
            select(x = !!sym(time_var), y = percentage)

          if(nrow(series_data) > 0) {
            hc <- hc %>%
              hc_add_series(
                name = paste(resp_level, "-", group_level),
                data = list_parse2(series_data),
                type = "line"
              )
          }
        }
      }
    }
  }

  return(hc)
}

# Test the line chart with grouping
plot2 <- create_timeline_fixed(
  data = gss_all,
  time_var = "year",
  response_var = "happy",
  group_var = "sex",
  chart_type = "line",
  title = "Happiness Trends by Gender",
  response_levels = c("very happy", "pretty happy", "not too happy")
)

plot2
# works

# now let's add support for a diverging bar chart
create_timeline_fixed <- function(data, time_var, response_var, group_var = NULL,
                                  chart_type = "stacked_area", title = NULL, y_max = NULL,
                                  response_levels = NULL, diverging_center = NULL,
                                  time_breaks = NULL, time_bin_labels = NULL) {

  # Basic data processing
  vars_to_select <- c(time_var, response_var)
  if (!is.null(group_var)) vars_to_select <- c(vars_to_select, group_var)

  plot_data <- data %>%
    select(all_of(vars_to_select)) %>%
    filter(!is.na(!!sym(time_var)), !is.na(!!sym(response_var)))

  if (!is.null(group_var)) {
    plot_data <- plot_data %>% filter(!is.na(!!sym(group_var)))
  }

  # Handle haven_labelled variables
  if (requireNamespace("haven", quietly = TRUE)) {
    if (inherits(plot_data[[time_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(time_var) := as.numeric(!!sym(time_var)))
    }
    if (inherits(plot_data[[response_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(response_var) := haven::as_factor(!!sym(response_var), levels = "labels"))
    }
    if (!is.null(group_var) && inherits(plot_data[[group_var]], "haven_labelled")) {
      plot_data <- plot_data %>%
        mutate(!!sym(group_var) := haven::as_factor(!!sym(group_var), levels = "labels"))
    }
  }

  # Handle time binning
  time_var_plot <- time_var
  if (!is.null(time_breaks)) {
    if (!is.numeric(plot_data[[time_var]])) {
      warning(paste0("'", time_var, "' is not numeric. Time binning ignored."), call. = FALSE)
    } else {
      plot_data <- plot_data %>%
        mutate(
          .time_binned = cut(!!sym(time_var),
                             breaks = time_breaks,
                             labels = time_bin_labels,
                             include.lowest = TRUE,
                             right = FALSE)
        )
      time_var_plot <- ".time_binned"
    }
  }

  # Apply response level ordering if specified
  if (!is.null(response_levels)) {
    plot_data <- plot_data %>%
      mutate(!!sym(response_var) := factor(!!sym(response_var), levels = response_levels))
  }

  # Aggregate data
  if (is.null(group_var)) {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), name = "count") %>%
      group_by(!!sym(time_var_plot)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  } else {
    agg_data <- plot_data %>%
      count(!!sym(time_var_plot), !!sym(response_var), !!sym(group_var), name = "count") %>%
      group_by(!!sym(time_var_plot), !!sym(group_var)) %>%
      mutate(percentage = round(count / sum(count) * 100, 1)) %>%
      ungroup()
  }

  # Create base chart
  hc <- highchart() %>%
    hc_title(text = title) %>%
    hc_yAxis(title = list(text = "Percentage"), max = y_max) %>%
    hc_xAxis(title = list(text = if(!is.null(time_breaks)) "Time Period" else "Year"))

  # Create chart based on type
  if (chart_type == "stacked_area") {
    hc <- hc %>%
      hc_chart(type = "area") %>%
      hc_plotOptions(area = list(stacking = "normal"))

    if (is.null(group_var)) {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var_plot)) %>%
          select(x = !!sym(time_var_plot), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "area"
          )
      }
    }

  } else if (chart_type == "line") {
    hc <- hc %>% hc_chart(type = "line")

    if (is.null(group_var)) {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      for(level in response_levels_to_use) {
        series_data <- agg_data %>%
          filter(!!sym(response_var) == level) %>%
          arrange(!!sym(time_var_plot)) %>%
          select(x = !!sym(time_var_plot), y = percentage)

        hc <- hc %>%
          hc_add_series(
            name = as.character(level),
            data = list_parse2(series_data),
            type = "line"
          )
      }
    } else {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      group_levels <- unique(agg_data[[group_var]])

      for(resp_level in response_levels_to_use) {
        for(group_level in group_levels) {
          series_data <- agg_data %>%
            filter(!!sym(response_var) == resp_level, !!sym(group_var) == group_level) %>%
            arrange(!!sym(time_var_plot)) %>%
            select(x = !!sym(time_var_plot), y = percentage)

          if(nrow(series_data) > 0) {
            hc <- hc %>%
              hc_add_series(
                name = paste(resp_level, "-", group_level),
                data = list_parse2(series_data),
                type = "line"
              )
          }
        }
      }
    }

  } else if (chart_type == "diverging_bar") {
    hc <- hc %>%
      hc_chart(type = "column") %>%
      hc_plotOptions(column = list(stacking = "normal"))

    # For diverging bars, we need to transform the data
    if (!is.null(diverging_center)) {
      response_levels_to_use <- if (!is.null(response_levels)) response_levels else unique(agg_data[[response_var]])
      center_index <- which(response_levels_to_use == diverging_center)

      if (length(center_index) > 0) {
        # Split into negative (left of center) and positive (right of center)
        negative_levels <- response_levels_to_use[1:(center_index-1)]
        positive_levels <- response_levels_to_use[(center_index+1):length(response_levels_to_use)]

        # Add negative values (make them negative for diverging effect)
        for(level in negative_levels) {
          series_data <- agg_data %>%
            filter(!!sym(response_var) == level) %>%
            arrange(!!sym(time_var_plot)) %>%
            mutate(y = -percentage) %>%  # Make negative
            select(x = !!sym(time_var_plot), y)

          hc <- hc %>%
            hc_add_series(
              name = as.character(level),
              data = list_parse2(series_data),
              type = "column"
            )
        }

        # Add positive values
        for(level in positive_levels) {
          series_data <- agg_data %>%
            filter(!!sym(response_var) == level) %>%
            arrange(!!sym(time_var_plot)) %>%
            select(x = !!sym(time_var_plot), y = percentage)

          hc <- hc %>%
            hc_add_series(
              name = as.character(level),
              data = list_parse2(series_data),
              type = "column"
            )
        }

        # Update y-axis for diverging chart
        hc <- hc %>%
          hc_yAxis(title = list(text = "Percentage"),
                   plotLines = list(list(value = 0, color = "black", width = 2)))
      }
    }
  }

  return(hc)
}

# Test the diverging bar chart
plot3 <- create_timeline_fixed(
  data = gss_all,
  time_var = "year",
  response_var = "polviews",
  chart_type = "diverging_bar",
  title = "Political Views Over Time",
  diverging_center = "moderate, middle of the road",
  time_breaks = c(1970, 1980, 1990, 2000, 2010, 2020),
  time_bin_labels = c("1970s", "1980s", "1990s", "2000s", "2010s")
)

plot3
# this doesn't really work, maybe try again later
