library(haven) # required for loading .sav (SPSS) data
library(labelled)

# Example using the AlgoSoc data

# Step 1: Load the algosoc data (we're using wave 1)
algosoc <- read_sav("C:\\Users\\alexa\\Documents\\Old_Dashboardr_Backup\\old_Dashboardr\\data_files\\L_AlgoSoc_wave1_1.0p.sav")

# View the first few rows
head(algosoc)

# Get a summary of the data
summary(algosoc)

# Check the structure of the data
str(algosoc)

# View the data in RStudio's data viewer
View(algosoc)

# Let's use KAI5 again
algosoc$KAI5

algosoc <- algosoc %>%
  mutate(KAI5_clean = as.numeric(remove_labels(KAI5)))  # removes labels, keeps numeric value


# NOTE:
# This is not a true histogram.
# A histogram is used for continuous, numerical data with bin ranges.
# This is categorical data, and a bar chart is more appropriate


# Call the function
create_histogram(
  data           = algosoc,
  x_var          = "KAI5_clean",
  bin_breaks = c(0.5, 3.5, 4.5, 7.5),
  bin_labels  = c("Unfamiliar (1-3)", "Neutral (4)", "Familiar (5-7)"),
  title          = "Familiarity with chatbots",
  subtitle       = "On a Likert-type scale from 1 to 7",
  x_label        = "Familiarity",
  y_label        = "Frequency",
  histogram_type = "count",
  color          = "hotpink",
  tooltip_suffix   = " respondents"
)


