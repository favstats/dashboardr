library(gssr)
library(tidyverse)
library(dashboardr)
library(forcats)
data("gss_panel20")
# Filter to valid years and simplify for examples
gss_data <- gss_panel20 |>
  select(sex_1a, grass_1a, polviews_1a, educ_1a, happy_1a, goodlife_1a, finrela_1a) %>%
  drop_na()


## Example Graph with Opinion on Political Views

# 1. Manually map the 7-point political view scale from the codebook
polviews_map <- list(
  "1" = "Extremely Liberal",
  "2" = "Liberal",
  "3" = "Slightly Liberal",
  "4" = "Moderate",
  "5" = "Slightly Conservative",
  "6" = "Conservative",
  "7" = "Extremely Conservative"
)
# Define the logical order for the x-axis
polviews_order <- c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                    "Slightly Conservative", "Conservative", "Extremely Conservative")

# 2. Manually map the 'grass_1a' variable
grass_map <- list(
  "1" = "Should be Legal",
  "2" = "Should Not be Legal"
)
# Define the display order and colors for the stacks
grass_order <- c("Should be Legal", "Should Not be Legal")
grass_colors <- c("#1a9641", "#d7191c") # Green for Legal, Red for Not Legal


## By ideology
create_stackedbar(
  data = gss_data,
  x_var = "polviews_1a",
  stack_var = "grass_1a",
  title = "Opinion on Marijuana Legalization by Political View",
  stacked_type = "percent",
  tooltip_suffix = "%",

  # Arguments for the X-axis ('polviews_1a')
  x_map_values = polviews_map,
  x_order = polviews_order,
  x_label = "Political View",

  # Arguments for the Stack variable ('grass_1a')
  stack_map_values = grass_map,
  stack_order = grass_order,
  color_palette = grass_colors,
  stack_label = "Opinion"
)





## Example Graph with Relative Economic Situation and Economic Optimism

# 1.Compared with American families in general, would you say your family income is far below average, below average, average, above average, or far above average? (finrela)
finrela_map <- list(
  "1" = "Far Below Average",
  "2" = "Below Average",
  "3" = "Average",
  "4" = "Above Average",
  "5" = "Far Above Average"
)

finrela_order <- c("Far Below Average", "Below Average", "Average", "Above Average", "Far Above Average")

#  2. The way things are in America, people like me and my family have a good chance of improving our standard of living. Do you agree or disagree? (goodlife)
optimism_order <- c("Agree", "Neutral", "Disagree")
optimism_colors <- c("#1a9641", "#ffffbf", "#d7191c") # Green-Yellow-Red


processed_gss_data <- gss_data %>%
  mutate(
    optimism_level = case_when(
      goodlife_1a %in% c(1, 2) ~ "Agree",        # Combine "Strongly Agree" and "Agree"
      goodlife_1a == 3        ~ "Neutral",      # "Neither Agree nor Disagree"
      goodlife_1a %in% c(4, 5) ~ "Disagree",     # Combine "Disagree" and "Strongly Disagree"
      TRUE                    ~ NA_character_   # Handle any other cases (like NAs)
    )
  )

# --- Create the Chart ---

create_stackedbar(
  data = processed_gss_data,
  x_var = "finrela_1a",
  stack_var = "optimism_level", # Use our newly created variable for the stacks
  title = "Optimism About Improving Standard of Living",
  subtitle = "By Perceived Relative Family Income",
  stacked_type = "percent",
  tooltip_suffix = "%",

  # Arguments for the X-axis
  x_map_values = finrela_map,
  x_order = finrela_order,
  x_label = "Relative Family Income",

  # Arguments for our new aggregated Stack variable
  stack_order = optimism_order,
  color_palette = optimism_colors,
  stack_label = "Chance of Improving Standard of Living"
)
