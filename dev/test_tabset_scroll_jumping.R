# Test script for tabset scroll jumping issue
# This creates a dashboard with nested tabs to reproduce the scroll jumping bug
# Run this to test if the bombproof scroll fix is working

# devtools::install_github("favstats/dashboardr")
devtools::load_all(".")

library(tidyverse)

# ============================================
# Generate mock data similar to the survey
# ============================================
set.seed(42)

n_per_country <- 250
countries <- c("DE", "NL", "ES", "PL")

# German states
de_states <- c("Baden-Württemberg", "Bayern", "Berlin", "Brandenburg", "Bremen", 
               "Hamburg", "Hessen", "Mecklenburg-Vorpommern", "Niedersachsen", 
               "Nordrhein-Westfalen", "Rheinland-Pfalz", "Saarland", "Sachsen", 
               "Sachsen-Anhalt", "Schleswig-Holstein", "Thüringen")

# Dutch provinces
nl_states <- c("Groningen", "Friesland", "Drenthe", "Overijssel", "Gelderland",
               "Flevoland", "Utrecht", "Noord-Holland", "Zuid-Holland", "Zeeland",
               "Noord-Brabant", "Limburg")

# Spanish regions
es_states <- c("Andalucía", "Aragón", "Cantabria", "Castilla y León", 
               "Castilla-La Mancha", "Cataluña", "Comunidad Valenciana", 
               "Comunidad de Madrid", "Extremadura", "Galicia", 
               "Islas Baleares", "Islas Canarias", "País Vasco")

# Polish voivodeships
pl_states <- c("Dolnośląskie", "Kujawsko-Pomorskie", "Lubelskie", "Lubuskie",
               "Łódzkie", "Małopolskie", "Mazowieckie", "Opolskie", "Podkarpackie",
               "Podlaskie", "Pomorskie", "Śląskie", "Świętokrzyskie", 
               "Warmińsko-Mazurskie", "Wielkopolskie", "Zachodniopomorskie")

# Generate data for each country
generate_country_data <- function(country_code, states, n) {
  tibble(
    country = country_code,
    q001 = factor(sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.48, 0.52))),
    q002 = factor(sample(c("18-24 years", "25-34 years", "35-44 years", 
                           "45-54 years", "55-64 years", "65+"), 
                         n, replace = TRUE, 
                         prob = c(0.12, 0.18, 0.18, 0.18, 0.17, 0.17)),
                  levels = c("18-24 years", "25-34 years", "35-44 years", 
                             "45-54 years", "55-64 years", "65+")),
    q003 = sample(states, n, replace = TRUE),
    q004_recoded = factor(sample(c("Low", "Middle", "High"), n, replace = TRUE, 
                                  prob = c(0.3, 0.45, 0.25)),
                          levels = c("Low", "Middle", "High")),
    ad03 = factor(sample(c("Not at all useful", "Slightly useful", "Moderately useful",
                           "Very useful", "Extremely useful"), n, replace = TRUE,
                         prob = c(0.15, 0.20, 0.30, 0.25, 0.10)),
                  levels = c("Not at all useful", "Slightly useful", "Moderately useful",
                             "Very useful", "Extremely useful")),
    g112_01 = sample(1:10, n, replace = TRUE)  # Left-right scale
  )
}

# Combine all countries
dat <- bind_rows(
  generate_country_data("DE", de_states, n_per_country),
  generate_country_data("NL", nl_states, n_per_country),
  generate_country_data("ES", es_states, n_per_country),
  generate_country_data("PL", pl_states, n_per_country)
)

cat("Generated", nrow(dat), "rows of mock survey data\n")
cat("Countries:", paste(unique(dat$country), collapse = ", "), "\n\n")

# ============================================
# Create dashboard with nested tabs
# This is the structure that causes scroll jumping
# ============================================

# ============================================
# EXACT REPLICA of user's 3-level nested structure:
# Level 1: "Demographics" (top tabgroup from "Demographics/Gender")
# Level 2: Gender, Age, State, Education
# Level 3: Germany, Netherlands, Spain, Poland (via title)
# ============================================

demographics <- create_content(data = dat, type = "bar") %>%
  add_text("This is a very preliminary visualization of our data yippie.") %>%
  # Gender - 3 levels: Demographics > Gender > [Country tabs via title]
  add_viz(x_var = "q001", title = "Germany", tabgroup = "Demographics/Gender", 
          filter = ~ country == "DE", x_label = "Gender") %>%
  add_viz(x_var = "q001", title = "Netherlands", tabgroup = "Demographics/Gender", 
          filter = ~ country == "NL", x_label = "Gender") %>%
  add_viz(x_var = "q001", title = "Spain", tabgroup = "Demographics/Gender", 
          filter = ~ country == "ES", x_label = "Gender") %>%
  add_viz(x_var = "q001", title = "Poland", tabgroup = "Demographics/Gender", 
          filter = ~ country == "PL", x_label = "Gender") %>%
  # Age - 3 levels: Demographics > Age > [Country tabs via title]
  add_viz(x_var = "q002", title = "Germany", tabgroup = "Demographics/Age", 
          filter = ~ country == "DE", x_label = "Age") %>%
  add_viz(x_var = "q002", title = "Netherlands", tabgroup = "Demographics/Age", 
          filter = ~ country == "NL", x_label = "Age") %>%
  add_viz(x_var = "q002", title = "Spain", tabgroup = "Demographics/Age", 
          filter = ~ country == "ES", x_label = "Age") %>%
  add_viz(x_var = "q002", title = "Poland", tabgroup = "Demographics/Age", 
          filter = ~ country == "PL", x_label = "Age") %>%
  # State - 3 levels: Demographics > State > [Country tabs via title]
  add_viz(x_var = "q003", title = "Germany", tabgroup = "Demographics/State", 
          filter = ~ country == "DE", x_label = "State") %>%
  add_viz(x_var = "q003", title = "Netherlands", tabgroup = "Demographics/State", 
          filter = ~ country == "NL", x_label = "State") %>%
  add_viz(x_var = "q003", title = "Spain", tabgroup = "Demographics/State", 
          filter = ~ country == "ES", x_label = "State") %>%
  add_viz(x_var = "q003", title = "Poland", tabgroup = "Demographics/State", 
          filter = ~ country == "PL", x_label = "State") %>%
  # Education - 3 levels: Demographics > Education > [Country tabs via title]
  add_viz(x_var = "q004_recoded", title = "Germany", tabgroup = "Demographics/Education", 
          filter = ~ country == "DE", x_label = "Education") %>%
  add_viz(x_var = "q004_recoded", title = "Netherlands", tabgroup = "Demographics/Education", 
          filter = ~ country == "NL", x_label = "Education") %>%
  add_viz(x_var = "q004_recoded", title = "Spain", tabgroup = "Demographics/Education", 
          filter = ~ country == "ES", x_label = "Education") %>%
  add_viz(x_var = "q004_recoded", title = "Poland", tabgroup = "Demographics/Education", 
          filter = ~ country == "PL", x_label = "Education")

# Attitudes - also nested: Attitudes > [subtabs]
attitudes <- create_content(data = dat, type = "stackedbar") %>%
  add_viz(x_var = "ad03", stack_var = "country", title = "Gen-AI Use", 
          tabgroup = "Attitudes") %>%
  add_viz(x_var = "g112_01", stack_var = "country", title = "Left-Right Attitude", 
          tabgroup = "Attitudes")

# Create pages - EXACT structure from user's code
analysis <- create_page("Analysis", data = dat, icon = "ph:chart-bar", is_landing_page = TRUE) %>%
  add_content(demographics) %>%
  add_content(attitudes)

about <- create_page("About", navbar_align = "right", icon = "ph:info") %>%
  add_text("## About", "", 
           "This is a test dashboard for the tabset scroll jumping fix.", "",
           "Built with [dashboardr](https://github.com/favstats/dashboardr)")

# ============================================
# Generate dashboard
# ============================================

# Clean up old output
output_dir <- "test_scroll_jumping"
if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE)
}

my_dashboard <- create_dashboard(
  title = "Scroll Jump Test", 
  output_dir = output_dir,
  theme = "flatly",
  tabset_theme = "segmented"  # Test with segmented theme
) %>%
  add_pages(analysis, about)

# Generate and open
cat("\n=== Generating dashboard ===\n")
my_dashboard %>% generate_dashboard(render = TRUE, open = "browser")

cat("\n")
cat("========================================\n")
cat("SCROLL JUMPING TEST - 3 LEVEL NESTED TABS\n")
cat("========================================\n")
cat("Structure:\n")
cat("  Level 1: Demographics (top tabgroup)\n")
cat("  Level 2: Gender / Age / State / Education\n")
cat("  Level 3: Germany / Netherlands / Spain / Poland\n")
cat("\n")
cat("TEST STEPS:\n")
cat("1. Scroll down so tabs are in MIDDLE of screen\n")
cat("2. Click between Level 2 tabs (Gender -> Age -> State)\n")
cat("3. Click between Level 3 tabs (Germany -> Netherlands)\n")
cat("4. Page should NOT jump when clicking ANY tab\n")
cat("========================================\n")
cat("\n")
cat("DEBUG (open DevTools F12, Console tab):\n")
cat("- Look for '[dashboardr] Tab click intercepted' messages\n")
cat("- Look for '[dashboardr] Restoring scroll to' messages\n")
cat("- If NO messages: script not running (check for JS errors)\n")
cat("- If messages appear but still jumping: timing issue\n")
cat("========================================\n")
