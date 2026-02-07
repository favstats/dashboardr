# Tests for dashboard_creation.R — lightweight, covr-safe
# Targets: create_dashboard, add_dashboard_page, add_page (alias),
#          .specs_contain_show_when, validation branches
library(testthat)

# Use tempdir to avoid warnings about existing directories
test_dir <- file.path(tempdir(), paste0("test_dash_", Sys.getpid()))

# --- create_dashboard ---

test_that("create_dashboard returns dashboard_project", {
  d <- create_dashboard(output_dir = test_dir, title = "Test Dashboard")
  expect_s3_class(d, "dashboard_project")
  expect_equal(d$title, "Test Dashboard")
})

test_that("create_dashboard default values", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_defaults"))
  expect_equal(d$title, "Dashboard")
  expect_true(d$search)
  expect_false(d$sidebar)
  expect_false(d$shiny)
  expect_equal(d$mainfont, "Fira Sans")
  expect_equal(d$fontsize, "16px")
  expect_equal(d$page_layout, "full")
  expect_false(d$mobile_toc)
  expect_false(d$self_contained)
  expect_equal(d$pagination_separator, "of")
  expect_equal(d$pagination_position, "bottom")
  expect_true(d$powered_by_dashboardr)
})

test_that("create_dashboard with social links", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_social"),
    title = "Social",
    github = "https://github.com/test/repo",
    twitter = "https://twitter.com/test",
    linkedin = "https://linkedin.com/in/test",
    email = "test@example.com",
    website = "https://example.com"
  )
  expect_equal(d$github, "https://github.com/test/repo")
  expect_equal(d$twitter, "https://twitter.com/test")
  expect_equal(d$email, "test@example.com")
})

test_that("create_dashboard with styling options", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_style"),
    title = "Styled",
    theme = "cosmo",
    navbar_bg_color = "#1e40af",
    navbar_text_color = "#ffffff",
    navbar_text_hover_color = "#f0f0f0",
    mainfont = "Lato",
    fontsize = "18px",
    fontcolor = "#1f2937",
    linkcolor = "#2563eb",
    monofont = "JetBrains Mono",
    monobackgroundcolor = "#f8fafc",
    linestretch = 1.6,
    backgroundcolor = "#ffffff",
    max_width = "1400px"
  )
  expect_equal(d$theme, "cosmo")
  expect_equal(d$navbar_bg_color, "#1e40af")
  expect_equal(d$mainfont, "Lato")
  expect_equal(d$max_width, "1400px")
})

test_that("create_dashboard with sidebar options", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_side"),
    sidebar = TRUE,
    sidebar_style = "floating",
    sidebar_background = "dark",
    sidebar_foreground = "#ffffff",
    sidebar_border = FALSE,
    sidebar_alignment = "right",
    sidebar_collapse_level = 3,
    sidebar_pinned = TRUE
  )
  expect_true(d$sidebar)
  expect_equal(d$sidebar_style, "floating")
  expect_equal(d$sidebar_alignment, "right")
  expect_true(d$sidebar_pinned)
})

test_that("create_dashboard with navigation options", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_nav"),
    breadcrumbs = FALSE,
    page_navigation = TRUE,
    back_to_top = TRUE,
    reader_mode = TRUE
  )
  expect_false(d$breadcrumbs)
  expect_true(d$page_navigation)
  expect_true(d$back_to_top)
  expect_true(d$reader_mode)
})

test_that("create_dashboard with lazy loading", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_lazy"),
    lazy_load_charts = TRUE,
    lazy_load_margin = "300px",
    lazy_load_tabs = TRUE,
    lazy_debug = TRUE
  )
  expect_true(d$lazy_load_charts)
  expect_equal(d$lazy_load_margin, "300px")
  expect_true(d$lazy_load_tabs)
  expect_true(d$lazy_debug)
})

test_that("create_dashboard lazy_load_tabs defaults to lazy_load_charts", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_lazy2"),
                        lazy_load_charts = TRUE)
  expect_true(d$lazy_load_tabs)

  d2 <- create_dashboard(output_dir = file.path(tempdir(), "dash_lazy3"),
                         lazy_load_charts = FALSE)
  expect_false(d2$lazy_load_tabs)
})

test_that("create_dashboard with analytics", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_analytics"),
    google_analytics = "GA-12345",
    plausible = "pa-Test123",
    gtag = "GTM-XXXXX"
  )
  expect_equal(d$google_analytics, "GA-12345")
  expect_equal(d$plausible, "pa-Test123")
})

test_that("create_dashboard with tabset_theme", {
  for (theme in c("modern", "minimal", "pills", "classic", "underline", "segmented", "none")) {
    d <- create_dashboard(output_dir = file.path(tempdir(), paste0("dash_tab_", theme)),
                          tabset_theme = theme)
    expect_equal(d$tabset_theme, theme)
  }
})

test_that("create_dashboard with invalid tabset_theme errors", {
  expect_error(
    create_dashboard(output_dir = file.path(tempdir(), "dash_badtab"),
                     tabset_theme = "invalid_theme"),
    "tabset_theme"
  )
})

test_that("create_dashboard with tabset_colors", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_tabcol"),
    tabset_colors = list(active_bg = "#2563eb", active_text = "#fff")
  )
  expect_equal(d$tabset_colors$active_bg, "#2563eb")
})

test_that("create_dashboard with invalid tabset_colors warns", {
  expect_warning(
    create_dashboard(output_dir = file.path(tempdir(), "dash_badtabcol"),
                     tabset_colors = list(bad_key = "red")),
    "Unknown tabset_colors"
  )
})

test_that("create_dashboard with pagination_position", {
  for (pos in c("bottom", "top", "both")) {
    d <- create_dashboard(output_dir = file.path(tempdir(), paste0("dash_page_", pos)),
                          pagination_position = pos)
    expect_equal(d$pagination_position, pos)
  }
})

test_that("create_dashboard invalid pagination_position errors", {
  expect_error(
    create_dashboard(output_dir = file.path(tempdir(), "dash_badpage"),
                     pagination_position = "invalid"),
    "pagination_position"
  )
})

test_that("create_dashboard with viewport options", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_vp"),
    viewport_width = 1200,
    viewport_scale = 0.5,
    viewport_user_scalable = FALSE
  )
  expect_equal(d$viewport_width, 1200)
  expect_equal(d$viewport_scale, 0.5)
  expect_false(d$viewport_user_scalable)
})

test_that("create_dashboard with misc options", {
  d <- create_dashboard(
    output_dir = file.path(tempdir(), "dash_misc"),
    author = "Dr. Test",
    description = "A test dashboard",
    page_footer = "(c) 2024",
    date = "2024-01-01",
    logo = "logo.png",
    favicon = "fav.ico",
    code_folding = "hide",
    code_tools = TRUE,
    toc = "floating",
    toc_depth = 4,
    value_boxes = TRUE,
    shiny = TRUE,
    observable = TRUE,
    chart_export = TRUE,
    self_contained = TRUE,
    code_overflow = "wrap"
  )
  expect_equal(d$author, "Dr. Test")
  expect_equal(d$page_footer, "(c) 2024")
  expect_true(d$value_boxes)
  expect_true(d$shiny)
  expect_true(d$chart_export)
})

test_that("create_dashboard starts with empty pages", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_empty"))
  expect_equal(length(d$pages), 0)
})

# --- add_dashboard_page / add_page ---

test_that("add_dashboard_page adds text-only page", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p1")) |>
    add_dashboard_page("About", text = "# About\n\nThis is info.")
  expect_equal(length(d$pages), 1)
  expect_equal(d$pages[[1]]$name, "About")
  expect_true(grepl("About", d$pages[[1]]$text))
})

test_that("add_dashboard_page adds landing page", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p2")) |>
    add_dashboard_page("Home", text = "Welcome!", is_landing_page = TRUE)
  expect_true(d$pages[[1]]$is_landing_page)
})

test_that("add_dashboard_page adds page with data", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p3")) |>
    add_dashboard_page("Analysis", data = mtcars, text = "# Analysis")
  expect_true(!is.null(d$pages[[1]]$data) || !is.null(d$pages[[1]]$data_path))
})

test_that("add_dashboard_page adds page with icon", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p4")) |>
    add_dashboard_page("Users", text = "Users page", icon = "ph:users-three")
  expect_equal(d$pages[[1]]$icon, "ph:users-three")
})

test_that("add_dashboard_page with overlay", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p5")) |>
    add_dashboard_page("Heavy Page", text = "Loading...",
                       overlay = TRUE, overlay_theme = "dark",
                       overlay_text = "Please wait", overlay_duration = 5000)
  expect_true(d$pages[[1]]$overlay)
  expect_equal(d$pages[[1]]$overlay_theme, "dark")
})

test_that("add_dashboard_page with navbar_align right", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p6")) |>
    add_dashboard_page("Settings", text = "Config", navbar_align = "right")
  expect_equal(d$pages[[1]]$navbar_align, "right")
})

test_that("add_dashboard_page with content collection", {
  vc <- create_viz(data = mtcars) |>
    add_viz(type = "bar", x_var = "cyl")
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p7")) |>
    add_dashboard_page("Charts", data = mtcars, visualizations = vc)
  expect_equal(length(d$pages), 1)
})

test_that("add_dashboard_page with mixed content and viz", {
  cc <- create_content(data = mtcars) |>
    add_text("# Analysis") |>
    add_viz(type = "bar", x_var = "cyl") |>
    add_text("## Conclusion")
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p8")) |>
    add_dashboard_page("Mixed", data = mtcars, content = cc)
  expect_equal(length(d$pages), 1)
})

test_that("add_dashboard_page multiple pages", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p9")) |>
    add_dashboard_page("Page 1", text = "First") |>
    add_dashboard_page("Page 2", text = "Second") |>
    add_dashboard_page("Page 3", text = "Third")
  expect_equal(length(d$pages), 3)
})

test_that("add_dashboard_page error: not a dashboard_project", {
  expect_error(add_dashboard_page("not_a_dashboard", "Page"), "dashboard_project")
})

test_that("add_dashboard_page with content block (single)", {
  block <- add_text(text = "Hello world")
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p10")) |>
    add_dashboard_page("Block", content = block)
  expect_equal(length(d$pages), 1)
})

test_that("add_dashboard_page with tabset_theme override", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p11"),
                        tabset_theme = "minimal") |>
    add_dashboard_page("Custom Tabs", text = "Tabs", tabset_theme = "pills")
  expect_equal(d$pages[[1]]$tabset_theme, "pills")
})

test_that("add_dashboard_page with lazy_load overrides", {
  d <- create_dashboard(output_dir = file.path(tempdir(), "dash_p12"),
                        lazy_load_charts = FALSE) |>
    add_dashboard_page("Lazy Page", text = "Charts",
                       lazy_load_charts = TRUE, lazy_load_margin = "500px")
  expect_true(d$pages[[1]]$lazy_load_charts)
  expect_equal(d$pages[[1]]$lazy_load_margin, "500px")
})

# --- .specs_contain_show_when ---

test_that(".specs_contain_show_when finds show_when", {
  specs <- list(
    list(type = "viz", show_when = ~country == "US"),
    list(type = "viz")
  )
  expect_true(dashboardr:::.specs_contain_show_when(specs))
})

test_that(".specs_contain_show_when handles empty/NULL", {
  expect_false(dashboardr:::.specs_contain_show_when(NULL))
  expect_false(dashboardr:::.specs_contain_show_when(list()))
})

test_that(".specs_contain_show_when searches nested children", {
  specs <- list(
    list(type = "viz", nested_children = list(
      list(type = "viz", show_when = ~x > 1)
    ))
  )
  expect_true(dashboardr:::.specs_contain_show_when(specs))
})

test_that(".specs_contain_show_when returns FALSE when no show_when", {
  specs <- list(
    list(type = "viz", x_var = "cyl"),
    list(type = "viz", x_var = "gear")
  )
  expect_false(dashboardr:::.specs_contain_show_when(specs))
})
