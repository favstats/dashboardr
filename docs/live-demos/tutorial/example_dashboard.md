# Example Dashboard

# Example Dashboard

Code

Here, you can see how to add text within a dashboard.

## Add a new heading like this

A line break is displayed when you add a new section.

## Example 1: Stacked Bars

- Change the title here…

If you want to add text within the tab, you can do so here.

View R Code

``` r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "Change the title here...",
        subtitle = "You can add a subtitle using the subtitle argument",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "If you want to add text within the tab, you can do so here.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 500,
        tabgroup = "demographics")
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#stacked-bar-happiness-education)

## Example 1: Stacked Bars

- Tabset \#2

Change the position of the text using the `text_position` argument.

View R Code

``` r
add_viz(type = "stackedbar",
        x_var = "sex_1a",
        stack_var = "happy_1a",
        title = "Tabset #2",
        subtitle = "Another example subtitle here!",
        x_label = "Gender",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "Change the position of the text using the `text_position` argument.",
        text_position = "below",
        icon = "ph:gender-intersex",
        height = 450,
        tabgroup = "demographics")
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#stacked-bar-happiness-gender)

## Example 2: Heatmap

- Trust by Education and Age

Here’s another example of the kind of plots you can generate in your
dashboard.

View R Code

``` r
add_viz(type = "heatmap",
        x_var = "degree_1a",
        y_var = "age_1a",
        value_var = "trust_1a",
        title = "Trust by Education and Age",
        subtitle = "Average trust levels across education and age groups",
        x_label = "Example x axis",
        y_label = "Customizable y label",
        value_label = "You can change the label here too...",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Heres another example of the kind of plots you can generate in your dashboard.",
        text_position = "above",
        icon = "ph:heatmap",
        height = 600,
        tabgroup = "social")
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#heatmap-trust-education-age)

## Example 2: Heatmap

- Trust by Region and Education

Educational and regional patterns in trust distribution.

View R Code

``` r
add_viz(type = "heatmap",
        x_var = "region_1a",
        y_var = "degree_1a",
        value_var = "trust_1a",
        title = "Trust by Region and Education",
        subtitle = "Educational and regional patterns in trust levels",
        x_label = "Region",
        y_label = "Education Level",
        value_label = "Trust Level",
        y_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        color_palette = c("#d7191c", "#fdae61", "#ffffbf", "#abdda4", "#2b83ba"),
        tooltip_prefix = "Trust: ",
        tooltip_suffix = "/3",
        tooltip_labels_format = "{point.value:.2f}",
        text = "Educational and regional patterns in trust distribution.",
        text_position = "above",
        icon = "ph:chart-pie",
        height = 550,
        tabgroup = "social")
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#heatmap-trust-region-education)

Back to top
