library(testthat)
library(dashboardr)

test_that("add_vizzes creates multiple visualizations from vector input", {
  # Create a viz collection with 3 timeline viz
  viz <- create_viz(
    type = "timeline",
    time_var = "wave",
    chart_type = "line"
  ) |>
    add_vizzes(
      y_var = c("var1", "var2", "var3"),
      .tabgroup_template = "test/item{i}"
    )
  
  # Should have 3 visualizations
  expect_equal(length(viz$items), 3)
  
  # Check each has correct y_var
  expect_equal(viz$items[[1]]$y_var, "var1")
  expect_equal(viz$items[[2]]$y_var, "var2")
  expect_equal(viz$items[[3]]$y_var, "var3")
  
  # Check tabgroups were templated correctly (parsed into vectors)
  expect_equal(viz$items[[1]]$tabgroup, c("test", "item1"))
  expect_equal(viz$items[[2]]$tabgroup, c("test", "item2"))
  expect_equal(viz$items[[3]]$tabgroup, c("test", "item3"))
})

test_that("add_vizzes shares common parameters across all viz", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2"),
      group_var = "AgeGroup",  # Should be same for both
      time_var = "wave",       # Should be same for both
      .tabgroup_template = "test/item{i}"
    )
  
  expect_equal(length(viz$items), 2)
  
  # Both should have same group_var and time_var
  expect_equal(viz$items[[1]]$group_var, "AgeGroup")
  expect_equal(viz$items[[2]]$group_var, "AgeGroup")
  expect_equal(viz$items[[1]]$time_var, "wave")
  expect_equal(viz$items[[2]]$time_var, "wave")
})

test_that("add_vizzes works with parallel expansion of multiple params", {
  viz <- create_viz(type = "stackedbar") |>
    add_vizzes(
      x_var = c("Age", "Gender", "Education"),
      title = c("By Age", "By Gender", "By Education"),
      .tabgroup_template = "demo/item{i}"
    )
  
  expect_equal(length(viz$items), 3)
  
  # Check parallel expansion
  expect_equal(viz$items[[1]]$x_var, "Age")
  expect_equal(viz$items[[1]]$title, "By Age")
  
  expect_equal(viz$items[[2]]$x_var, "Gender")
  expect_equal(viz$items[[2]]$title, "By Gender")
  
  expect_equal(viz$items[[3]]$x_var, "Education")
  expect_equal(viz$items[[3]]$title, "By Education")
})

test_that("add_vizzes uses tabgroup vector if no template provided", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2"),
      tabgroup = c("test/a", "test/b")  # Explicit tabgroups
    )
  
  expect_equal(length(viz$items), 2)
  # Tabgroups are parsed into vectors by add_viz
  expect_equal(viz$items[[1]]$tabgroup, c("test", "a"))
  expect_equal(viz$items[[2]]$tabgroup, c("test", "b"))
})

test_that("add_vizzes template can use variable values", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("SInfo1", "SInfo2", "SInfo3"),
      .tabgroup_template = "skills/{y_var}"  # Use actual var name
    )
  
  expect_equal(length(viz$items), 3)
  expect_equal(viz$items[[1]]$tabgroup, c("skills", "SInfo1"))
  expect_equal(viz$items[[2]]$tabgroup, c("skills", "SInfo2"))
  expect_equal(viz$items[[3]]$tabgroup, c("skills", "SInfo3"))
})

test_that("add_vizzes works with title_template", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2"),
      .tabgroup_template = "test/item{i}",
      .title_template = "Question {i}"
    )
  
  expect_equal(length(viz$items), 2)
  expect_equal(viz$items[[1]]$title, "Question 1")
  expect_equal(viz$items[[2]]$title, "Question 2")
})

test_that("add_vizzes inherits defaults from create_viz", {
  viz <- create_viz(
    type = "timeline",
    time_var = "wave",
    chart_type = "line",
    color_palette = c("#red", "#blue")
  ) |>
    add_vizzes(
      y_var = c("var1", "var2"),
      .tabgroup_template = "test/item{i}"
    )
  
  # Check defaults were inherited
  expect_equal(viz$items[[1]]$time_var, "wave")
  expect_equal(viz$items[[1]]$chart_type, "line")
  expect_equal(viz$items[[1]]$color_palette, c("#red", "#blue"))
  
  expect_equal(viz$items[[2]]$time_var, "wave")
  expect_equal(viz$items[[2]]$chart_type, "line")
})

test_that("add_vizzes errors if no expandable params with length > 1", {
  expect_error(
    create_viz(type = "timeline") |>
      add_vizzes(
        y_var = "var1",  # Single value, not a vector
        .tabgroup_template = "test/item{i}"
      ),
    "No expandable parameters found with length > 1"
  )
})

test_that("add_vizzes errors if vector params have different lengths", {
  expect_error(
    create_viz(type = "timeline") |>
      add_vizzes(
        y_var = c("var1", "var2", "var3"),  # Length 3
        x_var = c("a", "b")  # Length 2 - mismatch!
      ),
    "All expandable vector parameters must have the same length"
  )
})

test_that("add_vizzes can be chained with add_viz", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2"),
      .tabgroup_template = "test/auto{i}"
    ) |>
    add_viz(
      y_var = "var3",
      tabgroup = "test/manual"
    )
  
  expect_equal(length(viz$items), 3)
  expect_equal(viz$items[[1]]$tabgroup, c("test", "auto1"))
  expect_equal(viz$items[[2]]$tabgroup, c("test", "auto2"))
  expect_equal(viz$items[[3]]$tabgroup, c("test", "manual"))
})

test_that("add_vizzes works with filters", {
  viz <- create_viz(type = "stackedbar") |>
    add_vizzes(
      x_var = c("Age", "Gender"),
      filter = ~ wave == 1,  # Same filter for all
      .tabgroup_template = "test/wave1/{i}"
    )
  
  expect_equal(length(viz$items), 2)
  
  # Both should have the same filter
  expect_equal(deparse(viz$items[[1]]$filter[[2]]), "wave == 1")
  expect_equal(deparse(viz$items[[2]]$filter[[2]]), "wave == 1")
})

test_that("add_vizzes preserves insertion order", {
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2", "var3"),
      .tabgroup_template = "test/item{i}"
    )
  
  # Check insertion indices are sequential
  expect_equal(viz$items[[1]]$.insertion_index, 1)
  expect_equal(viz$items[[2]]$.insertion_index, 2)
  expect_equal(viz$items[[3]]$.insertion_index, 3)
})

test_that("add_vizzes works with complex tabgroup template using glue", {
  tbgrp <- "skills"
  wave <- "wave1"
  demographic <- "age"
  
  viz <- create_viz(type = "timeline") |>
    add_vizzes(
      y_var = c("var1", "var2"),
      .tabgroup_template = glue::glue("{tbgrp}/{wave}/{demographic}/item{{i}}")
    )
  
  expect_equal(viz$items[[1]]$tabgroup, c("skills", "wave1", "age", "item1"))
  expect_equal(viz$items[[2]]$tabgroup, c("skills", "wave1", "age", "item2"))
})

test_that("add_vizzes works for user's helper function pattern", {
  # Simulate the user's use case
  add_all_viz_timeline <- function(viz, vars, group_var, tbgrp, demographic, wave_label) {
    wave_path <- tolower(gsub(" ", "", wave_label))
    
    viz |> add_vizzes(
      y_var = vars,
      group_var = group_var,
      .tabgroup_template = glue::glue("{tbgrp}/{wave_path}/{demographic}/item{{i}}")
    )
  }
  
  viz <- create_viz(type = "timeline", time_var = "wave", chart_type = "line") |>
    add_all_viz_timeline(
      vars = c("SInfo1", "SInfo2", "SInfo3"),
      group_var = "AgeGroup",
      tbgrp = "skills",
      demographic = "age",
      wave_label = "Over Time"
    )
  
  expect_equal(length(viz$items), 3)
  expect_equal(viz$items[[1]]$tabgroup, c("skills", "overtime", "age", "item1"))
  expect_equal(viz$items[[1]]$y_var, "SInfo1")
  expect_equal(viz$items[[1]]$group_var, "AgeGroup")
  
  expect_equal(viz$items[[3]]$tabgroup, c("skills", "overtime", "age", "item3"))
  expect_equal(viz$items[[3]]$y_var, "SInfo3")
})

