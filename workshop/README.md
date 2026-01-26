# dashboardr Comprehensive Workshop Materials

Welcome to the dashboardr workshop! This folder contains all materials for a **three-day** comprehensive hands-on workshop covering dashboardr and R package development.

## Workshop Structure

### Day 1: Foundations & Core Concepts

1. **Foundations**
   - What is dashboardr and why use it
   - The "Grammar of Dashboards" philosophy
   - Installation and setup
   - The three-step workflow: Build → Assemble → Generate

2. **Visualizations**
   - All 9 visualization types (histogram, bar, stackedbar, stackedbars, timeline, heatmap, treemap, scatter, **map**)
   - Smart defaults and overrides
   - Filters, weights, and binning
   - Custom bin breaks and labels
   - Vectorized creation with `add_vizzes()`

3. **Content System Basics**
   - Text, images, callouts, cards
   - Tabgroups (flat and nested hierarchies)
   - Combining collections with `+`

4. **Quick Start**
   - First dashboard creation
   - Themes preview
   - Q&A

### Day 2: Advanced Features & Publishing

1. **Advanced Visualizations**
   - Timeline with `y_filter`, `y_filter_combine`, `y_filter_label` (NEW!)
   - Response binning with `y_breaks`, `y_bin_labels`, `y_levels`
   - Time binning
   - Map visualization

2. **The Content System (Deep Dive)**
   - Value boxes and metrics
   - Accordions, dividers, spacers
   - Tables (gt, DT, reactable)
   - Mixing content types

3. **Interactive Inputs**
   - Select (single/multiple)
   - Checkbox and radio buttons
   - Switches for toggling series
   - Sliders with custom labels
   - Button groups

4. **Theming & Styling**
   - Bootswatch themes
   - Tabset themes
   - Built-in theme functions (modern, academic, clean, ascor)
   - Deep customization and overrides

5. **Dashboard Assembly**
   - Loading overlays
   - Lazy loading for performance
   - Multi-dataset pages
   - Pagination (page breaks)

6. **Publishing**
   - GitHub Pages deployment
   - One-time setup
   - Updating published dashboards

7. **Best Practices & Debugging**
   - Common mistakes and fixes
   - Pro tips
   - The power of `print()`

### Day 3: R Package Development

1. **Why Create Packages?**
   - Benefits of packaging code
   - When to create a package
   - Package vs. script mindset

2. **Package Structure**
   - Essential files and folders
   - DESCRIPTION & NAMESPACE
   - The R/ folder

3. **Creating Your Package**
   - `usethis` magic
   - Tidy package conventions
   - Git & GitHub integration

4. **Documentation with roxygen2**
   - Documentation tags (@param, @return, @export, etc.)
   - Writing good documentation
   - Examples that work
   - Using other packages (@importFrom)

5. **Testing with testthat**
   - Why test?
   - Writing effective tests
   - Test-driven development
   - Code coverage

6. **Sharing Your Package**
   - R CMD check
   - README and badges
   - pkgdown documentation sites
   - Continuous Integration (GitHub Actions)
   - CRAN considerations

7. **Best Practices**
   - Function naming conventions
   - Error messages that help
   - Internal vs. exported functions
   - Package development checklist

## Files in This Folder

| File | Description |
|------|-------------|
| `dashboardr_workshop.Rmd` | **Day 1** xaringan slides |
| `dashboardr_workshop_day2.Rmd` | **Day 2** xaringan slides |
| `dashboardr_workshop_day3.Rmd` | **Day 3** xaringan slides (Package Development) |
| `exercises.R` | 15 hands-on exercises with solutions |
| `cheatsheet.md` | Comprehensive quick reference |
| `custom.css` | Custom CSS styling for slides |
| `header.html` | Font Awesome icons support |
| `README.md` | This file |

## Before the Workshop

### Participants Should Have:

1. **R and RStudio** installed (recent versions)

2. **Quarto** installed: https://quarto.org/docs/get-started/

3. **dashboardr** installed:
```r
install.packages("pak")
pak::pak("favstats/dashboardr")
```

4. **Verify installation:**
```r
library(dashboardr)
library(dplyr)

# Quick test
viz <- create_viz(type = "histogram") %>%
  add_viz(x_var = "mpg", title = "Test")

dashboard <- create_dashboard(
  title = "Test",
  output_dir = "test_dashboard"
) %>%
  add_page("Test", data = mtcars, visualizations = viz)

generate_dashboard(dashboard, render = FALSE)
# Should see "Dashboard project initialized"
```

## Running the Slides

```r
# Install xaringan if needed
install.packages("xaringan")

# Day 1 - Live preview (recommended for presenting)
xaringan::inf_mr("dashboardr_workshop.Rmd")

# Day 2 - Live preview
xaringan::inf_mr("dashboardr_workshop_day2.Rmd")

# Day 3 - Live preview
xaringan::inf_mr("dashboardr_workshop_day3.Rmd")

# Or render to HTML
rmarkdown::render("dashboardr_workshop.Rmd")
rmarkdown::render("dashboardr_workshop_day2.Rmd")
rmarkdown::render("dashboardr_workshop_day3.Rmd")
```

## Workshop Learning Objectives

By the end of this workshop, participants will be able to:

### Days 1-2: dashboardr

1. ✅ Explain the "Grammar of Dashboards" concept
2. ✅ Create visualization collections with smart defaults and overrides
3. ✅ Use all **9** visualization types with appropriate parameters
4. ✅ Apply filters, weights, and custom binning
5. ✅ Use timeline filtering with `y_filter`, `y_filter_combine`, `y_filter_label`
6. ✅ Organize content with flat and nested tabgroups
7. ✅ Mix visualizations with text, callouts, and other content types
8. ✅ Add interactive inputs for user filtering
9. ✅ Apply and customize professional themes
10. ✅ Publish dashboards to GitHub Pages
11. ✅ Debug common issues

### Day 3: Package Development

12. ✅ Understand R package structure and conventions
13. ✅ Create a package using `usethis` and `devtools`
14. ✅ Write roxygen2 documentation
15. ✅ Create unit tests with `testthat`
16. ✅ Run R CMD check and fix issues
17. ✅ Set up GitHub Actions for CI
18. ✅ Create a pkgdown documentation site
19. ✅ Share packages via GitHub

## Key Analogies Used

| Concept | Analogy |
|---------|---------|
| dashboardr vs Shiny | Food truck (pre-made) vs Restaurant (made to order) |
| create_viz() + add_viz() | Document template: set once, reuse everywhere |
| Tabgroups | Folders organizing files |
| Nested tabgroups | File paths: folder/subfolder/item |
| The Grammar of Dashboards | LEGO bricks: snap together predictable components |
| + operator | Puzzle pieces: combine collections |

## Exercises Overview

| # | Topic | Key Skills |
|---|-------|------------|
| 1 | First Viz Collection | create_viz, add_viz, tabgroups |
| 2 | First Dashboard | create_dashboard, add_page, md_text |
| 3 | Multiple Viz Types | histogram, bar, stackedbar, + operator |
| 4 | Filters & title_tabset | filter syntax, comparing subsets |
| 5 | Nested Tabgroups | hierarchical organization |
| 6 | Custom Binning | bin_breaks, bin_labels |
| 7 | Multiple Stacked Bars | stackedbars for Likert questions |
| 8 | Themes & Icons | apply_theme, set_tabgroup_labels |
| 9 | Mixed Content | add_text, add_callout, add_accordion |
| 10 | Value Boxes | add_value_box_row, KPI display |
| 11 | Interactive Inputs | add_input, filtering |
| 12 | Vectorized Creation | add_vizzes efficiency |
| 13 | Weights | weight_var for survey data |
| 14 | Pagination | add_pagination, section breaks |
| 15 | Final Challenge | Complete publication-ready dashboard |

Plus 3 bonus exercises for advanced topics.

## Tips for Instructors

1. **Emphasize `print()`** - This is the debugging superpower! Always show students what the object looks like.

2. **Start simple** - Get the first dashboard working before adding complexity.

3. **Use `render = FALSE`** - Fast iteration during development, only render when needed.

4. **Have sample code ready** - For participants who get stuck.

5. **Encourage exploration** - Let participants modify examples.

6. **Use the analogies** - They help concepts stick:
   - Food truck vs restaurant
   - Template inheritance
   - File paths for tabgroups
   - LEGO bricks

7. **Demonstrate errors** - Show what happens with missing `~` in filters, wrong bin label counts, etc.

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Package not found" | `pak::pak("favstats/dashboardr")` |
| "Quarto not found" | Install from https://quarto.org |
| "Variable not found" | Check `names(data)` matches `x_var` |
| Filters not working | Use formula syntax: `filter = ~ col == "val"` |
| Wrong bin label count | `length(bin_labels) = length(bin_breaks) - 1` |
| Dashboard not rendering | Verify Quarto: `quarto --version` |

### Getting Help

```r
# Function documentation
?create_dashboard
?add_viz
?generate_dashboard

# All vignettes
vignette(package = "dashboardr")
```

## Resources

- **Package Documentation**: https://favstats.github.io/dashboardr/
- **GitHub Repository**: https://github.com/favstats/dashboardr
- **Icons (Iconify)**: https://icon-sets.iconify.design/
- **Themes (Bootswatch)**: https://bootswatch.com/
- **Color Palettes**: https://colorbrewer2.org/

### Live Demos

- Tutorial Dashboard: https://favstats.github.io/dashboardr/live-demos/tutorial/docs/
- Showcase Dashboard: https://favstats.github.io/dashboardr/live-demos/showcase/docs/

---

Happy teaching! 🎓

For questions or issues, open an issue on GitHub: https://github.com/favstats/dashboardr/issues
