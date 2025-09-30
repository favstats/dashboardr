# Test the fixed dashboard system
devtools::load_all()

# Load GSS Panel 2020 data
data(gss_panel20, package = "gssr")

# Create a working dataset with key _1a variables from 2016 wave
gss_clean <- gss_panel20 %>%
  select(
    # Demographics
    age_1a, sex_1a, degree_1a, income_1a, region_1a,
    # Attitudes and behaviors
    happy_1a, trust_1a, fair_1a, helpful_1a,
    polviews_1a, partyid_1a, attend_1a,
    # Economic
    class_1a
  ) %>%
  # Remove completely empty rows
  filter(if_any(everything(), ~ !is.na(.)))

# Use this as our sample data
sample_data <- gss_clean

tabgroup1 <- "Attitudes"
tabgroup2 <- "Non-Attitudes"


# Method 1: Using create_viz() and add_viz() piping
page1_vizzes <- create_viz() %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness Distribution Across Education Levels",
          subtitle = "Percentage breakdown within each education category",
          x_label = "Education Level",
          y_label = "Percentage of Respondents",
          stack_label = "Happiness Level",
          stacked_type = "percent",
          x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          tooltip_suffix = "%",
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          tabgroup = tabgroup1) %>%
  add_viz(type = "heatmap",
          x_var = "partyid_1a",
          y_var = "polviews_1a",
          value_var = "trust_1a",
          title = "Trust in People by Party and Ideology",
          subtitle = "Average trust levels across political groups",
          x_label = "Party Identification",
          y_label = "Political Views",
          value_label = "Trust Level",
          x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                      "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
          y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                      "Slightly Conservative", "Conservative", "Extremely Conservative"),
          color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
          tooltip_prefix = "Trust: ",
          tooltip_suffix = "/3",
          data_labels_format = "{point.value:.2f}",
          tabgroup = tabgroup1) %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness Distribution Across Education Levels",
          subtitle = "Percentage breakdown within each education category",
          x_label = "Education Level",
          y_label = "Percentage of Respondents",
          stack_label = "Happiness Level",
          stacked_type = "percent",
          x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          tooltip_suffix = "%",
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          tabgroup = tabgroup1) %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness Distribution Across Education Levels",
          subtitle = "Percentage breakdown within each education category",
          x_label = "Education Level",
          y_label = "Percentage of Respondents",
          stack_label = "Happiness Level",
          stacked_type = "percent",
          x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          tooltip_suffix = "%",
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          tabgroup = tabgroup2) %>%
  add_viz(type = "stackedbar",
          x_var = "degree_1a",
          stack_var = "happy_1a",
          title = "Happiness Distribution Across Education Levels",
          subtitle = "Percentage breakdown within each education category",
          x_label = "Education Level",
          y_label = "Percentage of Respondents",
          stack_label = "Happiness Level",
          stacked_type = "percent",
          x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
          stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
          tooltip_suffix = "%",
          color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
          tabgroup = tabgroup2)

# Method 2: Using spec_viz() and combining
viz1 <- spec_viz(type = "heatmap",
                 x_var = "partyid_1a",
                 y_var = "polviews_1a",
                 value_var = "trust_1a",
                 title = "Trust in People by Party and Ideology",
                 subtitle = "Average trust levels across political groups",
                 x_label = "Party Identification",
                 y_label = "Political Views",
                 value_label = "Trust Level",
                 x_order = c("Strong Democrat", "Not Very Strong Democrat", "Independent, Close to Democrat",
                             "Independent", "Independent, Close to Republican", "Not Very Strong Republican", "Strong Republican"),
                 y_order = c("Extremely Liberal", "Liberal", "Slightly Liberal", "Moderate",
                             "Slightly Conservative", "Conservative", "Extremely Conservative"),
                 color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
                 tooltip_prefix = "Trust: ",
                 tooltip_suffix = "/3",
                 data_labels_format = "{point.value:.2f}",
                 tabgroup = tabgroup1)

viz2 <- spec_viz(type = "heatmap",
                 x_var = "degree_1a",
                 y_var = "class_1a",
                 value_var = "fair_1a",
                 title = "Fairness by Education and Social Class",
                 subtitle = "Perceived fairness across education and class groups",
                 x_label = "Education Level",
                 y_label = "Social Class",
                 value_label = "Fairness Rating",
                 x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
                 y_order = c("Lower Class", "Working Class", "Middle Class", "Upper Class"),
                 color_palette = c("#ca0020", "#f4a582", "#ffffff", "#92c5de", "#0571b0"),
                 tooltip_prefix = "Fairness: ",
                 tooltip_suffix = "/3",
                 data_labels_format = "{point.value:.2f}",
                 tabgroup = tabgroup1)

viz3 <- spec_viz(type = "stackedbar",
                 x_var = "region_1a",
                 stack_var = "trust_1a",
                 title = "Trust Levels by US Region",
                 subtitle = "Regional variation in interpersonal trust",
                 x_label = "US Region",
                 y_label = "Percentage of Respondents",
                 stack_label = "Trust Level",
                 stacked_type = "percent",
                 stack_order = c("Can Trust", "Can't Be Too Careful", "Depends"),
                 tooltip_suffix = "%",
                 color_palette = c("#2E8B57", "#DAA520", "#CD5C5C"),
                 tabgroup = tabgroup1)

page2_vizzes <- list(viz1, viz2, viz3)

# Create dashboard with piping
dashboard <- create_dashboard(
  output_dir = "test_dashboard",
  title = "Test Dashboard with Piping",
  allow_inside_pkg = TRUE
) %>%
  add_landingpage(
    title = "Welcome to the Test Dashboard",
    md = "This dashboard demonstrates the new piping workflow for creating visualizations."
  ) %>%
  add_page(
    name = "Survey Demographics",
    data = sample_data,
    visualizations = page1_vizzes
  ) %>%
  add_page(
    name = "Political Attitudes",
    data = sample_data,
    visualizations = page2_vizzes
  )

# Print the dashboard structure
cat("\n=== DASHBOARD PROJECT ===\n")
print.dashboard_project(dashboard)

# Print the visualization collections
cat("\n=== VISUALIZATION COLLECTION 1 ===\n")
print.viz_collection(page1_vizzes)

cat("\n=== VISUALIZATION COLLECTION 2 ===\n")
print.viz_collection(page2_vizzes)


# Generate the dashboard
generate_dashboard(dashboard, render = TRUE, open = "browser")
