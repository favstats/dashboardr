# Standalone Charts

# Standalone Charts

Code

This page demonstrates standalone charts (no tabsets) for key findings.

For example, you could use this layout to visualize the most important
trends or overarching themes of your data.

## This is a standalone chart.

This standalone chart shows the overall distribution of happiness across
education levels.

View R Code

``` r
add_viz(type = "stackedbar",
        x_var = "degree_1a",
        stack_var = "happy_1a",
        title = "This is a standalone chart.",
        subtitle = "Here youll notice that this is a standalone plot.",
        x_label = "Education Level",
        y_label = "Percentage of Respondents",
        stack_label = "Happiness Level",
        stacked_type = "percent",
        x_order = c("Lt High School", "High School", "Junior College", "Bachelor", "Graduate"),
        stack_order = c("Very Happy", "Pretty Happy", "Not Too Happy"),
        tooltip_suffix = "%",
        color_palette = c("#2E86AB", "#A23B72", "#F18F01"),
        text = "This standalone chart shows the overall distribution of happiness across education levels.",
        text_position = "above",
        icon = "ph:chart-bar",
        height = 600)
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#standalone-happiness-education)

## Here’s another summary chart

Subtitle for your standalone chart.

View R Code

``` r
add_viz(type = "heatmap",
        x_var = "partyid_1a",
        y_var = "polviews_1a",
        value_var = "trust_1a",
        title = "Heres another summary chart",
        subtitle = "This summary chart visualizes trust patterns across political groups",
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
        tooltip_labels_format = "{point.value:.2f}",
        text = "Subtitle for your standalone chart.",
        text_position = "below",
        icon = "ph:shield-check",
        height = 700)
```

[Full
documentation](https://favstats.github.io/dashboardr/live-demos/articles/tutorial_dashboard_code.html#standalone-trust-politics)

Back to top
