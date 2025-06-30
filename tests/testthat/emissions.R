
### FABIO: putting this here because there is no testing logic yet
### actually seems more like a dev script to me, would move?
donotrun <- F

if(donotrun){


  library(tidyverse)

  emissions <- read_csv("test_data/cumulative_co2_emissions_tonnes.csv")

  n <- 10
  emissions <- emissions %>% select(1,(ncol(emissions) - n + 1):ncol(emissions))

  emissions <- emissions %>%
    pivot_longer(
      cols = -1,
      names_to = "year",
      values_to = "value"
    )

  emissions <- emissions %>%
    mutate(value = case_when(
      str_detect(value, "B$") ~ as.numeric(str_replace(value, "B$", "")) * 1e9,
      str_detect(value, "M$") ~ as.numeric(str_replace(value, "M$", "")) * 1e6,
    ))

  emissions_plot <- create_stackedbar(
    data = emissions,
    x_var = "year",
    y_var = "value",
    stack_var = "country",
    x_label = "Year",
    y_label = "Emissions",
    stack_label = "Country",
    stacked_type = "normal",
    include_na = TRUE,
  )

  emissions_plot


}
