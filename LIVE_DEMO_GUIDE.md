# 🐧 Palmer Penguins Dashboard - Live Coding Demo

## Pre-Demo Setup (1 minute before)

```r
# Install required package
install.packages("palmerpenguins")

# Load libraries
library(dashboardr)
library(palmerpenguins)
data("penguins")
```

---

## Demo Flow (3-5 minutes)

### ⏱️ **STEP 1: Simplest Dashboard** (30 seconds)
**What to say:** "Let's create a dashboard in 5 lines of code"

```r
create_dashboard("Penguins") %>%
  add_page("Overview", data = penguins,
           content = create_viz() %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g")) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

**Show:** Browser opens with interactive scatter plot

---

### ⏱️ **STEP 2: Add More Charts** (45 seconds)
**What to say:** "Adding more visualizations is just... more pipes!"

```r
create_dashboard("Penguins") %>%
  add_page("Overview", data = penguins,
           content = create_viz() %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g", 
                     color_var = "species") %>%
             add_viz(type = "histogram", x_var = "body_mass_g") %>%
             add_viz(type = "stackedbar", x_var = "species", fill_var = "sex")) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

**Show:** Three charts on one page

---

### ⏱️ **STEP 3: Add Tabs & Content** (1 minute)
**What to say:** "Let's organize with tabs and add some context"

```r
create_dashboard("Penguins", theme = "cosmo") %>%
  add_page("Analysis", data = penguins,
           content = create_viz() %>%
             add_callout("Palmer Penguins", "3 species across Antarctic islands 🐧", 
                         type = "note") %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
                     tabgroup = "Size") %>%
             add_viz(type = "histogram", x_var = "body_mass_g", tabgroup = "Distribution") %>%
             add_viz(type = "stackedbar", x_var = "island", fill_var = "species",
                     tabgroup = "Location")) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

**Show:** Tabs + callout box

---

### ⏱️ **STEP 4: The Full Experience** (2 minutes)
**What to say:** "Now let's go all-in: multiple pages, nested tabs, value boxes!"

```r
create_dashboard("Penguin Dashboard", theme = "flatly") %>%
  
  # Page 1: By Species
  add_page("By Species", data = penguins,
           content = create_viz() %>%
             add_text("🐧 **Three penguin species** in Palmer Archipelago") %>%
             
             # Adelie with nested tab
             add_viz(type = "histogram", x_var = "body_mass_g",
                     tabgroup = "Adelie", filter = species == "Adelie") %>%
             add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
                     tabgroup = "Adelie/Bills", filter = species == "Adelie") %>%
             
             # Gentoo with nested tab
             add_viz(type = "histogram", x_var = "body_mass_g",
                     tabgroup = "Gentoo", filter = species == "Gentoo") %>%
             add_viz(type = "scatter", x_var = "bill_length_mm", y_var = "bill_depth_mm",
                     tabgroup = "Gentoo/Bills", filter = species == "Gentoo")) %>%
  
  # Page 2: Summary
  add_page("Summary", data = penguins,
           content = create_viz() %>%
             add_value_box(value = 3, title = "Species", icon = "bi-egg") %>%
             add_value_box(value = 344, title = "Penguins", icon = "bi-graph-up") %>%
             add_divider() %>%
             add_viz(type = "scatter", x_var = "flipper_length_mm", y_var = "body_mass_g",
                     color_var = "species")) %>%
  
  generate_dashboard(render = TRUE, open = "browser")
```

**Show:** 
- Multiple pages in navbar
- Nested tabs (Adelie → Bills)
- Value boxes
- Filtered data per tab

---

## 🎯 Key Points to Emphasize

1. **Piping:** Everything flows naturally with `%>%`
2. **Simplicity:** From 5 lines to full dashboard
3. **Flexibility:** Mix content (text, callouts, value boxes) with visualizations
4. **Organization:** Tabs and nested tabs (`"Parent/Child"`)
5. **Filtering:** `filter = species == "Adelie"` for subset views
6. **Themes:** 25+ Bootswatch themes available
7. **Publishing:** One command to deploy (if time permits)

---

## 💡 Pro Tips for Live Coding

- **Type slowly** - let people follow along
- **Show the browser** after each step
- **Point out** the `tabgroup =` and `filter =` parameters
- **If typo occurs:** Just fix it and regenerate - that's the beauty!
- **Backup plan:** Use `demo_penguins_live.R` if typing fails

---

## 📊 Features Showcased

✅ Multiple visualization types (scatter, histogram, stacked bar)  
✅ Tabbed organization  
✅ Nested tabs  
✅ Content blocks (text, callouts, value boxes, dividers)  
✅ Multiple pages  
✅ Data filtering  
✅ Color mapping  
✅ Theming  
✅ Piping workflow  

**Total:** 9+ features in ~50 lines of code!

---

## 🚀 Closing Line

> "And that's how you go from zero to a full interactive dashboard in under 5 minutes. Questions?"

---

## Emergency Backup (if palmerpenguins fails)

```r
# Use built-in mtcars instead
create_dashboard("Cars") %>%
  add_page("Overview", data = mtcars,
           content = create_viz() %>%
             add_viz(type = "scatter", x_var = "wt", y_var = "mpg", color_var = "cyl")) %>%
  generate_dashboard(render = TRUE, open = "browser")
```

