library(haven) # since we're using SPSS data we need this
library(tidyr)
library(dplyr)
# library(dashboardr)


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

# Step 2: Convert SPSS labelled Likert vars into R factors
# Let's use a few from the ADSV battery
algosoc_factored <- algosoc %>%
  mutate(
    ADSV1 = as_factor(ADSV1),
    ADSV2 = as_factor(ADSV2),
    ADSV3 = as_factor(ADSV3),
    ADSV4 = as_factor(ADSV4)
  )
print(algosoc_factored)


# Step 3: Call the function
hc <- viz_stackedbars(
  data            = algosoc_factored,
  questions       = c("ADSV1", "ADSV2", "ADSV3", "ADSV4"),
  title       = "In welke mate zijn de volgende waarden van belang voor u bij het ontwikkelen en gebruiken van automatische besluitvormingssystemen?",
  subtitle = "Likert-type scale from 1 to 7",
  x_var_labels = c(" Respect voor privacy van gebruikers", "Gebruiksvriendelijkheid", "Politiek neutraal", "Vrijheid om te kiezen welke informatie je krijgt"),
  stacked_type= "percent"

)


# 4. Print the plot
hc

