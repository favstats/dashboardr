# Grammar of Dashboards - Conceptual Framework

## The Analogy: ggplot2’s Grammar of Graphics

Just as ggplot2 revolutionized data visualization by providing a
**grammar of graphics**, dashboardr aims to provide a **grammar of
dashboards**.

### ggplot2’s Core Components:

1.  **Data** - The dataset
2.  **Aesthetics** - Mappings from data to visual properties
3.  **Geometries** - Visual representations (points, lines, bars)
4.  **Scales** - Control how data maps to aesthetics
5.  **Facets** - Split plots into subplots
6.  **Coordinates** - The coordinate system
7.  **Themes** - Non-data visual elements

------------------------------------------------------------------------

## Grammar of Dashboards - Core Components

### 1. **Data Layer**

*The foundation - what you’re visualizing*

**dashboardr has:** - ✅ Multi-dataset support - ✅ Data deduplication
across pages - ✅ Automatic data path resolution - ✅ Filter-based data
subsets

**Could be enhanced:** - 🔄 Data transformations in-place - 🔄 Dynamic
data loading - 🔄 Data connections (databases, APIs)

------------------------------------------------------------------------

### 2. **Visualization Layer**

*The “geometries” of dashboards*

**dashboardr has:** - ✅ Multiple viz types (histogram, timeline,
stackedbar, heatmap, bar) - ✅ Composable visualizations
(`create_viz() %>% add_viz()`) - ✅ Type-specific parameters - ✅
Defaults + overrides pattern - ✅ Custom function-based visualizations

**This is strong!** The piping workflow is very grammar-like.

------------------------------------------------------------------------

### 3. **Hierarchy/Grouping Layer**

*The “facets” of dashboards - organizing related content*

**dashboardr has:** - ✅ Tabgroups with automatic nesting - ✅
Tree-based hierarchy (visible via
[`print()`](https://rdrr.io/r/base/print.html)) - ✅ Custom tab labels -
✅ Filter-based automatic grouping - ✅ Flexible nesting levels

**This is UNIQUE to dashboardr!** Most dashboard tools require manual
nesting.

------------------------------------------------------------------------

### 4. **Layout Layer**

*How things are arranged spatially*

**dashboardr has:** - ✅ Pages (top-level containers) - ✅ Cards
(content containers) - ✅ Card rows (horizontal arrangement) - ✅
Quarto’s column/row orientation

**Could be enhanced:** - 🔄 Responsive layouts (mobile/desktop) - 🔄
Grid systems - 🔄 Dynamic sizing based on content - 🔄 Drag-and-drop
arrangement

------------------------------------------------------------------------

### 5. **Navigation Layer**

*How users move through the dashboard*

**dashboardr has:** - ✅ Navbar (top navigation) - ✅ Sidebar (side
navigation) - ✅ Sidebar groups - ✅ Navbar menus (dropdowns) - ✅
Landing pages - ✅ Icon support

**This is comprehensive!**

------------------------------------------------------------------------

### 6. **Styling/Theming Layer**

*The “themes” of dashboards*

**dashboardr has:** - ✅ Tabset themes (pills, modern, classic, etc.) -
✅ Custom SCSS support - ✅ Color palettes - ✅ Custom tabset colors -
✅ Loading overlays

**Could be enhanced:** - 🔄 Global theme system (not just tabsets) - 🔄
Color scales - 🔄 Typography control - 🔄 Brand presets

------------------------------------------------------------------------

### 7. **Interactivity Layer**

*User-driven exploration*

**dashboardr has:** - ⚠️ Filters (limited - pre-defined at build time) -
✅ Tabs (user-driven navigation)

**Could be enhanced:** - 🔄 Dynamic filters (Shiny-like) - 🔄 Linked
selections - 🔄 Drill-downs - 🔄 Tooltips - 🔄 Crossfiltering

**Note:** dashboardr generates static Quarto dashboards, so true
interactivity requires JavaScript/Shiny.

------------------------------------------------------------------------

### 8. **Composition Layer**

*Combining elements*

**dashboardr has:** - ✅ `+` operator for viz collections - ✅
[`combine_viz()`](https://favstats.github.io/dashboardr/reference/combine_viz.md)
function - ✅ `%>%` piping throughout - ✅ Defaults inheritance - ✅
Automatic merging of labels

**This is excellent!** Very composable.

------------------------------------------------------------------------

### 9. **Generation/Rendering Layer**

*From specification to output*

**dashboardr has:** - ✅ Automatic QMD generation - ✅ Quarto YAML
configuration - ✅ Incremental builds - ✅ Preview mode - ✅ Progress
tracking - ✅ Error messages with suggestions

**Very polished!**

------------------------------------------------------------------------

## Summary: dashboardr’s Grammar

### Core Principles (Grammar-like)

1.  **Layering** - Build dashboards by adding layers

    ``` r
    dashboard <- create_dashboard() %>%
      add_page() %>%
      add_page()
    ```

2.  **Composition** - Combine visualizations naturally

    ``` r
    viz1 + viz2  # or combine_viz(viz1, viz2)
    ```

3.  **Defaults + Overrides** - Set once, override when needed

    ``` r
    create_viz(type = "histogram", color = "blue") %>%
      add_viz(x_var = "age") %>%              # uses blue
      add_viz(x_var = "income", color = "red") # overrides to red
    ```

4.  **Declarative** - Describe what you want, not how to build it

    ``` r
    add_viz(type = "histogram", x_var = "age", filter = ~ wave == 1)
    # dashboardr figures out the structure
    ```

5.  **Hierarchical** - Automatic organization based on tabgroups

    ``` r
    tabgroup = "demographics/age/item1"  # auto-nests
    ```

------------------------------------------------------------------------

## What Makes dashboardr Unique?

### 1. **Automatic Hierarchy Building**

Most dashboard tools require manual nesting. dashboardr infers structure
from `tabgroup` paths and `filter` parameters.

### 2. **Tree Visualization**

The [`print()`](https://rdrr.io/r/base/print.html) methods show the
actual structure being generated - pedagogical and debugging-friendly.

### 3. **Filter-Aware Grouping**

Automatically groups visualizations by their filter expressions.

### 4. **Piping-First Design**

Everything is pipeable, making complex dashboards readable.

### 5. **Static + Fast**

Generates static HTML (via Quarto), so it’s fast, hostable anywhere, and
doesn’t require a server.

------------------------------------------------------------------------

## Missing Pieces (Future Grammar Components?)

### 1. **Scales** (like ggplot2)

- Define color scales globally
- Coordinate scales across visualizations
- Custom scale transformations

### 2. **Annotations**

- Text overlays on visualizations
- Reference lines
- Highlights

### 3. **Computed Variables**

- Create variables on-the-fly
- Statistical transformations
- Aggregations at dashboard-level

### 4. **Responsive Design**

- Mobile layouts
- Conditional rendering based on screen size

### 5. **State Management**

- User preferences
- Saved filters
- Bookmarkable states

------------------------------------------------------------------------

## Pedagogical Framing

### For Vignettes:

**Introduction:** \> “Just as `ggplot2` provides a grammar of graphics
for creating visualizations, \> `dashboardr` provides a grammar of
dashboards for organizing and presenting them. \> \> This grammar
consists of: \> - **Data** - what you’re visualizing \> -
**Visualizations** - how you show it \> - **Hierarchy** - how you
organize it \> - **Layout** - how you arrange it \> - **Navigation** -
how users explore it \> - **Styling** - how it looks \> \> By combining
these elements through a fluent piping interface, you can build \>
complex dashboards that are both powerful and maintainable.”

**Key Message:** “Print your viz objects to see the tree structure! This
reveals how dashboardr interprets your specifications and builds the
hierarchy.”

------------------------------------------------------------------------

## Examples for Vignettes

### Show the Tree!

``` r
# Create a simple visualization collection
viz <- create_viz(type = "histogram") %>%
  add_viz(x_var = "age", tabgroup = "demographics", title = "Age") %>%
  add_viz(x_var = "income", tabgroup = "demographics", title = "Income") %>%
  add_viz(x_var = "score", tabgroup = "performance", title = "Score")

# Print it to see the structure!
print(viz)

# Output shows:
# ├─ demographics
# │  ├─ Age
# │  └─ Income
# └─ performance
#    └─ Score
```

This makes the hierarchy **visible and understandable**.

------------------------------------------------------------------------

## Conclusion

**dashboardr already embodies many principles of a “grammar of
dashboards”:**

✅ **Composable** - Build complex from simple  
✅ **Declarative** - Describe the what, not the how  
✅ **Layered** - Add components incrementally  
✅ **Hierarchical** - Automatic organization  
✅ **Pipeable** - Fluent, readable syntax  
✅ **Inspectable** - Print methods reveal structure

**What could enhance the grammar:** - Global scales/themes - More layout
control - Annotations - Computed variables - True interactivity (would
require Shiny backend)

The foundation is strong! The vignettes should emphasize this
grammatical approach.
