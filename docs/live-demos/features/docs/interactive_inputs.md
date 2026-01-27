# Interactive Inputs

# Interactive Inputs

``` r
create_page("Inputs Demo", data = gss, type = "bar") %>%
  add_input_row() %>%
    add_input(
      input_id = "edu", label = "Education",
      type = "select_multiple", filter_var = "degree"
    ) %>%
    add_input(
      input_id = "race", label = "Race", 
      type = "checkbox", filter_var = "race", inline = TRUE
    ) %>%
  end_input_row() %>%
  add_input_row() %>%
    add_input(
      input_id = "age", label = "Age Range",
      type = "slider", filter_var = "age", min = 18, max = 89
    ) %>%
    add_input(
      input_id = "sex", label = "Gender",
      type = "radio", filter_var = "sex", inline = TRUE
    ) %>%
  end_input_row() %>%
  add_viz(x_var = "happy", title = "Happiness")
```

Education Level associate/junior college bachelor's graduate high school
less than high school

Race

black

other

white

Age Range 25 65

18 89

Gender

female male

## Happiness by Gender

## Political Views Distribution
