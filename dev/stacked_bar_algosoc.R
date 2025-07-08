# Install the package for loading a .sav SPSS file
if(!("pak" %in% as.data.frame(installed.packages())$Package)){
  install.packages("pak")
}

pak::pak("haven")
library(dashboardr)


# Load the algosoc data (we're using wave 1)
# algosoc <- read_sav("C:\\Users\\alexa\\Documents\\Dashboardr\\data_files\\L_AlgoSoc_wave1_1.0p.sav")

algosoc <- haven::read_sav("~/Downloads/L_AlgoSoc_wave1_1.0p.sav")

# View the first few rows
head(algosoc)

# Get a summary of the data
summary(algosoc)

# Check the structure of the data
str(algosoc)

# View the data in RStudio's data viewer
View(algosoc)


# Example using the AlgoSoc data

# Step 1: Define your mapping lists for the variables
# User notes
# You can rename it to any variable you want, e.g., `age_mapping`
# Depends on what variable you're looking at
# Just remember to make sure you call the same variable later
gender_mapping <- list(
  "1" = "Man",
  "2" = "Vrouw",
  "3" = "Anders"
)
# Make sure the order matches
gender_display_order <- c("Man", "Vrouw", "Anders")

# Step 2: Make sure your response variable is also mapped / recoded
# This might not be necessary if you just want them as strings,
# But the order is important
pu1_days_mapping <- list(
  "0" = "0 dagen",
  "1" = "1 dag",
  "2" = "2 dagen",
  "3" = "3 dagen",
  "4" = "4 dagen",
  "5" = "5 dagen",
  "6" = "6 dagen",
  "7" = "7 dagen"
)
pu1_days_order <- c("0 dagen", "1 dag", "2 dagen", "3 dagen", "4 dagen", "5 dagen", "6 dagen", "7 dagen")


# Step 3: Call the general create_stackedbar function
algosoc_plot1 <- create_stackedbar(
  data = algosoc,
  x_var = "PU1",           # X-axis will be 'days per week'
  stack_var = "geslacht", # Stacks/legend will be 'gender'
  title = "Hoeveel dagen in een gemiddelde week bezoekt u YouTube?",
  subtitle = "Verdeling per geslacht", # Distribution per gender
  x_label = "Aantal dagen per week", # Number of days per week
  y_label = "Aantal respondenten",   # Number of respondents
  stack_label = "Geslacht",        # Gender
  stacked_type = "normal",
  x_tooltip_suffix = " dagen",
  include_na = TRUE, # Always good for survey data if you want to see missingness
  # Apply mapping to the X-axis variable if needed
  x_map_values = pu1_days_mapping,
  # Ensure X-axis order uses the new, mapped labels (or original if no map)
  x_order = pu1_days_order,
  # Apply mapping to the stacked variable
  stack_map_values = gender_mapping,
  # Ensure stack order uses the new, mapped labels
  stack_order = gender_display_order
)

# Step 4: Display the plot
algosoc_plot1


# Let's try a harder example, with binning
# Example: KAI5
# We will stack the bars by age

# Define mappings and orders for examples
# For familiarity (as x_var in this example, KAI5)
familiarity_mapping <- list(
  "1" = "Not at all familiar with", "2" = "unfamiliar", "3" = "Slightly unfamiliar",
  "4" = "Neutral", "5" = "Slightly familiar", "6" = "Familiar", "7" = "Very familiar with"
)
familiarity_order <- c(
  "Not at all familiar with", "unfamiliar", "Slightly unfamiliar",
  "Neutral", "Slightly familiar", "Familiar", "Very familiar with"
)

# Define breaks, bin labels, and order for the stack_var
age_numeric_breaks <- c(-Inf, 25, 35, 45, 55, 65, Inf) # Define your income ranges
age_bins <- c("Under 25", "25 to 34", "35 to 44", "45 to 54", "55 to 64", "65+") # Custom labels for these ranges
age_order <- age_bins # Order should follow the labels


# Call the function
algosoc_kai5 <- create_stackedbar(
  data = algosoc,
  x_var = "KAI5", # X-axis will be familiarity with chatbots
  stack_var = "leeftijd",   # Age to be stacked and binned
  title = "Familiarity with chatbots",
  subtitle = "Age is binned into categories and stacked",
  x_label = "Familiarity",
  y_label = "Number of Respondents",
  stack_label = "Age",
  stacked_type = "normal",
  # Arguments for the X-axis (familiarity with chatbots)
  x_map_values = familiarity_mapping,
  x_order = familiarity_order,
  # Arguments for the stacked variable (age)
  stack_breaks = age_numeric_breaks,         # Provide the numeric cut points for stack_var
  stack_bin_labels = age_bins, # Provide custom labels for the stack_var bins
  stack_order = age_order           # Order the stacks by these custom labels
)

# Display the plot
algosoc_kai5

