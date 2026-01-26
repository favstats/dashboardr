# Make sure the wd is correct
setwd("C:\\Users\\alexa\\Documents\\Dashboardr")
getwd()


# Load necessary libraries (good practice, even for simple data generation)
library(dplyr) # For data manipulation (e.g., mutate, tibble)
library(stringr) # For string manipulation if needed (not strictly used here, but good general utility)

# Set a seed for reproducibility
set.seed(123)

# Define number of observations
n_obs <- 500

# 1. Experimental Variable: "treatment"
# Categorical, e.g., "Control", "Treatment A", "Treatment B"
treatment <- sample(
  c("Control", "Treatment A", "Treatment B"),
  size = n_obs,
  replace = TRUE,
  prob = c(0.3, 0.35, 0.35) # Slightly uneven distribution for realism
)

# 2. Control Variable: "age"
# Numeric, simulating age in years, skewed towards younger adults
age <- round(rnorm(n_obs, mean = 35, sd = 10))
age[age < 18] <- 18 # Minimum age
age[age > 75] <- 75 # Maximum age, cap for realism

# Convert age to categories (often more useful in survey context)
age_group <- cut(
  age,
  breaks = c(17, 25, 35, 45, 55, 65, Inf),
  labels = c("18-25", "26-35", "36-45", "46-55", "56-65", "65+"),
  right = TRUE,
  include.lowest = TRUE # Include 18 in 18-25
)

# 3. Control Variable: "socioeconomic_status" (SES)
# Ordinal categorical, e.g., "Low", "Medium", "High"
socioeconomic_status <- sample(
  c("Low", "Medium", "High"),
  size = n_obs,
  replace = TRUE,
  prob = c(0.25, 0.50, 0.25) # Realistic distribution
)

# Convert to factor with ordered levels for proper analysis later
socioeconomic_status <- factor(
  socioeconomic_status,
  levels = c("Low", "Medium", "High"),
  ordered = TRUE
)


# 4. Outcome Variable: "satisfaction" (Likert scale 1:7)
# Let's simulate some effects for realism:
# - Treatment A might slightly increase satisfaction
# - Treatment B might increase it more
# - Higher age might slightly decrease satisfaction
# - Higher SES might slightly increase satisfaction

# Base satisfaction score (e.g., from a normal distribution)
base_satisfaction <- round(rnorm(n_obs, mean = 4, sd = 1.5))

# Add effects
# Treatment effects
treatment_effect <- case_when(
  treatment == "Control" ~ 0,
  treatment == "Treatment A" ~ 0.5, # Small positive effect
  treatment == "Treatment B" ~ 1.0  # Larger positive effect
)

# Age effect (older -> slightly lower satisfaction)
age_effect <- case_when(
  age_group == "18-25" ~ 0.5,
  age_group == "26-35" ~ 0.2,
  age_group == "36-45" ~ 0,
  age_group == "46-55" ~ -0.2,
  age_group == "56-65" ~ -0.5,
  age_group == "65+" ~ -0.8
)

# SES effect (higher -> slightly higher satisfaction)
ses_effect <- case_when(
  socioeconomic_status == "Low" ~ -0.5,
  socioeconomic_status == "Medium" ~ 0,
  socioeconomic_status == "High" ~ 0.5
)

# Combine effects and round to nearest integer for Likert scale
satisfaction_raw <- base_satisfaction + treatment_effect + age_effect + ses_effect
satisfaction <- round(satisfaction_raw)

# Ensure satisfaction is within 1 to 7 bounds
satisfaction[satisfaction < 1] <- 1
satisfaction[satisfaction > 7] <- 7

# Convert to factor with ordered levels (optional, but good for Likert)
satisfaction_labels <- c(
  "1-Strongly Disagree", "2-Disagree", "3-Slightly Disagree",
  "4-Neutral", "5-Slightly Agree", "6-Agree", "7-Strongly Agree"
)
satisfaction_likert <- factor(satisfaction, levels = 1:7, labels = satisfaction_labels, ordered = TRUE)


# Combine into a tibble (modern data frame)
survey_data <- tibble(
  treatment = factor(treatment, levels = c("Control", "Treatment A", "Treatment B")), # Ensure order
  age_numeric = age, # Keep numeric age for flexibility
  age_group = age_group,
  socioeconomic_status = socioeconomic_status,
  satisfaction_numeric = satisfaction, # Keep numeric satisfaction for flexibility
  satisfaction_likert = satisfaction_likert
)

# Display the structure and first few rows
print(str(survey_data))
print(head(survey_data))
print(summary(survey_data))

# Check some distributions
library(ggplot2)
ggplot(survey_data, aes(x = satisfaction_likert, fill = treatment)) +
  geom_bar(position = "fill") +
  labs(title = "Satisfaction by Treatment Group (100% Stacked Bar)")

ggplot(survey_data, aes(x = age_group, fill = socioeconomic_status)) +
  geom_bar() +
  labs(title = "Socioeconomic Status by Age Group")



# Try the function
dummy1 <- viz_stackedbar(
  data = survey_data,
  x_var = "satisfaction_likert",
  stack_var = "socioeconomic_status",
  title = "Satisfaction by socioeconomic status",
  subtitle = "",
  x_label = "Satisfaction with treatment",
  y_label = "Total responses",
  stack_label = "SE status",
  stacked_type = "percent",
  include_na = TRUE
)

# dummy1 %>%
#   hc_

dummy1 %>%
  hc_chart(inverted=T)

