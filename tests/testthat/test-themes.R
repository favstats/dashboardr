# =================================================================
# Tests for themes.R
# =================================================================

# --- theme_ascor() ---
test_that("theme_ascor returns a list with correct UvA branding", {
  theme <- theme_ascor()
  
  expect_type(theme, "list")
  
  # Check UvA red color
  expect_equal(theme$navbar_bg_color, "#CB0D0D")
  expect_equal(theme$navbar_text_color, "#ffffff")
  expect_equal(theme$linkcolor, "#CB0D0D")
  
  # Check typography
  expect_equal(theme$mainfont, "Fira Sans")
  expect_equal(theme$fontsize, "16px")
  expect_equal(theme$monofont, "Fira Code")
  
  # Check layout
  expect_equal(theme$max_width, "1200px")
  expect_equal(theme$linestretch, 1.6)
})

test_that("theme_ascor accepts navbar_style parameter", {
  theme_dark <- theme_ascor(navbar_style = "dark")
  theme_light <- theme_ascor(navbar_style = "light")
  
  expect_equal(theme_dark$navbar_style, "dark")
  expect_equal(theme_light$navbar_style, "light")
})

test_that("theme_ascor allows custom overrides via ...", {
  theme <- theme_ascor(
    fontsize = "18px",
    max_width = "1400px",
    mainfont = "Inter"
  )
  
  expect_equal(theme$fontsize, "18px")
  expect_equal(theme$max_width, "1400px")
  expect_equal(theme$mainfont, "Inter")
  
  # Original values should remain
  expect_equal(theme$navbar_bg_color, "#CB0D0D")
})

# --- theme_uva() ---
test_that("theme_uva is an alias for theme_ascor", {
  uva <- theme_uva()
  ascor <- theme_ascor()
  
  expect_equal(uva, ascor)
})

test_that("theme_uva passes navbar_style correctly", {
  theme <- theme_uva(navbar_style = "light")
  expect_equal(theme$navbar_style, "light")
})

# --- theme_academic() ---
test_that("theme_academic returns correct structure", {
  theme <- theme_academic()
  
  expect_type(theme, "list")
  
  # Check default accent color is applied
  expect_equal(theme$navbar_bg_color, "#2563eb")
  expect_equal(theme$linkcolor, "#2563eb")
  
  # Check typography
  expect_equal(theme$mainfont, "Fira Sans")
  expect_equal(theme$monofont, "Source Code Pro")
  
  # Check layout
  expect_equal(theme$max_width, "1200px")
})

test_that("theme_academic accepts custom accent color", {
  theme <- theme_academic(accent_color = "#8B0000")
  
  expect_equal(theme$navbar_bg_color, "#8B0000")
  expect_equal(theme$linkcolor, "#8B0000")
})

test_that("theme_academic allows overrides", {
  theme <- theme_academic(
    accent_color = "#ff0000",
    fontsize = "17px",
    mainfont = "Roboto"
  )
  
  expect_equal(theme$navbar_bg_color, "#ff0000")
  expect_equal(theme$fontsize, "17px")
  expect_equal(theme$mainfont, "Roboto")
})

# --- theme_modern() ---
test_that("theme_modern returns correct default (blue) style", {
  theme <- theme_modern()
  
  expect_type(theme, "list")
  expect_equal(theme$navbar_bg_color, "#1e40af")  # Blue navbar
  expect_equal(theme$linkcolor, "#2563eb")
  expect_equal(theme$navbar_style, "dark")
  
  # Tech fonts
  expect_equal(theme$mainfont, "Roboto")
  expect_equal(theme$monofont, "JetBrains Mono")
  
  # Wider layout for data dashboards
  expect_equal(theme$max_width, "1400px")
})

test_that("theme_modern supports different style variants", {
  # Purple
  purple <- theme_modern(style = "purple")
  expect_equal(purple$navbar_bg_color, "#7c3aed")
  expect_equal(purple$linkcolor, "#8b5cf6")
  
  # Green
  green <- theme_modern(style = "green")
  expect_equal(green$navbar_bg_color, "#059669")
  expect_equal(green$linkcolor, "#10b981")
  
  # Orange
  orange <- theme_modern(style = "orange")
  expect_equal(orange$navbar_bg_color, "#ea580c")
  expect_equal(orange$linkcolor, "#f97316")
  
  # White (light navbar)
  white <- theme_modern(style = "white")
  expect_equal(white$navbar_bg_color, "#ffffff")
  expect_equal(white$navbar_style, "light")
  expect_equal(white$navbar_text_color, "#1f2937")
})

test_that("theme_modern allows overrides", {
  theme <- theme_modern(style = "purple", fontsize = "18px", mainfont = "Inter")
  
  expect_equal(theme$navbar_bg_color, "#7c3aed")  # Purple retained
  expect_equal(theme$fontsize, "18px")
  expect_equal(theme$mainfont, "Inter")
})

# --- theme_clean() ---
test_that("theme_clean returns minimal theme settings", {
  theme <- theme_clean()
  
  expect_type(theme, "list")
  
  # Light navbar (white background)
  expect_equal(theme$navbar_bg_color, "#ffffff")
  expect_equal(theme$navbar_style, "light")
  expect_equal(theme$navbar_text_color, "#1f2937")
  
  # Clean typography
  expect_equal(theme$mainfont, "Source Sans Pro")
  expect_equal(theme$monofont, "IBM Plex Mono")
  expect_equal(theme$fontsize, "17px")
  
  # Narrower for readability
  expect_equal(theme$max_width, "900px")
  
  # More comfortable spacing
  expect_equal(theme$linestretch, 1.7)
})

test_that("theme_clean allows overrides", {
  theme <- theme_clean(mainfont = "Inter", max_width = "1200px")
  
  expect_equal(theme$mainfont, "Inter")
  expect_equal(theme$max_width, "1200px")
  
  # Other values stay
  expect_equal(theme$navbar_bg_color, "#ffffff")
})

# --- apply_theme() ---
test_that("apply_theme returns theme when proj is NULL", {
  result <- apply_theme(theme = theme_ascor())
  
  expect_type(result, "list")
  expect_equal(result$navbar_bg_color, "#CB0D0D")
})

test_that("apply_theme applies overrides when proj is NULL", {
  result <- apply_theme(
    theme = theme_ascor(),
    fontsize = "20px",
    linkcolor = "#000000"
  )
  
  expect_equal(result$fontsize, "20px")
  expect_equal(result$linkcolor, "#000000")
  # Original value retained
  expect_equal(result$navbar_bg_color, "#CB0D0D")
})

test_that("apply_theme errors on non-dashboard_project object", {
  expect_error(
    apply_theme(proj = list(name = "test"), theme = theme_ascor()),
    "dashboard_project"
  )
})

test_that("apply_theme applies theme to dashboard_project", {
  # Create a minimal dashboard project
  proj <- create_dashboard("test_dash", "Test Dashboard")
  
  result <- apply_theme(proj, theme = theme_ascor())
  
  # Check class is preserved
  expect_s3_class(result, "dashboard_project")
  
  # Check theme parameters were applied
  expect_equal(result$navbar_bg_color, "#CB0D0D")
  expect_equal(result$mainfont, "Fira Sans")
  expect_equal(result$max_width, "1200px")
})

test_that("apply_theme with overrides modifies theme before applying", {
  proj <- create_dashboard("test_dash", "Test Dashboard")
  
  result <- apply_theme(
    proj = proj, 
    theme = theme_modern(),
    fontsize = "18px",
    max_width = "1600px"
  )
  
  expect_equal(result$fontsize, "18px")
  expect_equal(result$max_width, "1600px")
})

test_that("apply_theme works in pipe chains", {
  result <- create_dashboard("test", "Test") %>%
    apply_theme(theme_clean())
  
  expect_s3_class(result, "dashboard_project")
  expect_equal(result$navbar_bg_color, "#ffffff")
})


# ===================================================================
# Theme Validation Tests
# ===================================================================

test_that("apply_theme validates color parameters", {
  # Invalid type (numeric instead of character)
  expect_error(
    apply_theme(theme = list(navbar_bg_color = 123)),
    "must be a single character string"
  )
  
  # Invalid hex color
  expect_error(
    apply_theme(theme = list(linkcolor = "#GGG")),
    "invalid color value"
  )
  
  # Valid colors should work
  expect_no_error(apply_theme(theme = list(navbar_bg_color = "#CB0D0D")))
  expect_no_error(apply_theme(theme = list(linkcolor = "red")))
  expect_no_error(apply_theme(theme = list(fontcolor = "rgb(255, 0, 0)")))
})

test_that("apply_theme validates size parameters", {
  # Missing units
  expect_error(
    apply_theme(theme = list(fontsize = "16")),
    "must include units"
  )
  
  # Numeric instead of character
  expect_error(
    apply_theme(theme = list(fontsize = 16)),
    "must be a character string with units"
  )
  
  # Valid sizes should work
  expect_no_error(apply_theme(theme = list(fontsize = "16px")))
  expect_no_error(apply_theme(theme = list(max_width = "1200px")))
  expect_no_error(apply_theme(theme = list(margin_left = "2rem")))
  expect_no_error(apply_theme(theme = list(margin_top = "5%")))
})

test_that("apply_theme validates linestretch as numeric", {
  # String instead of numeric
  expect_error(
    apply_theme(theme = list(linestretch = "1.5")),
    "must be a single number"
  )
  
  # Valid numeric should work
  expect_no_error(apply_theme(theme = list(linestretch = 1.6)))
})

test_that("apply_theme validates font parameters", {
  # Non-character type
  expect_error(
    apply_theme(theme = list(mainfont = 123)),
    "must be a character string"
  )
  
  # Invalid characters that would break SCSS
  expect_error(
    apply_theme(theme = list(mainfont = "Font{bad}")),
    "invalid characters"
  )
  
  # Valid fonts should work
  expect_no_error(apply_theme(theme = list(mainfont = "Fira Sans")))
  expect_no_error(apply_theme(theme = list(monofont = "JetBrains Mono")))
})

test_that("built-in themes pass validation", {
  # All built-in themes should pass validation and return lists
  expect_type(apply_theme(theme = theme_ascor()), "list")
  expect_type(apply_theme(theme = theme_uva()), "list")
  expect_type(apply_theme(theme = theme_academic()), "list")
  expect_type(apply_theme(theme = theme_modern()), "list")
  expect_type(apply_theme(theme = theme_modern("purple")), "list")
  expect_type(apply_theme(theme = theme_modern("green")), "list")
  expect_type(apply_theme(theme = theme_modern("orange")), "list")
  expect_type(apply_theme(theme = theme_modern("white")), "list")
  expect_type(apply_theme(theme = theme_clean()), "list")
})
