# Create a new dashboard project

Initializes a dashboard project object that can be built up using the
piping workflow with add_landingpage() and add_page().

## Usage

``` r
create_dashboard(
  output_dir = "site",
  title = "Dashboard",
  logo = NULL,
  favicon = NULL,
  github = NULL,
  twitter = NULL,
  linkedin = NULL,
  email = NULL,
  website = NULL,
  search = TRUE,
  theme = NULL,
  custom_css = NULL,
  custom_scss = NULL,
  tabset_theme = "minimal",
  tabset_colors = NULL,
  author = NULL,
  description = NULL,
  page_footer = NULL,
  date = NULL,
  sidebar = FALSE,
  sidebar_style = "docked",
  sidebar_background = "light",
  sidebar_foreground = NULL,
  sidebar_border = TRUE,
  sidebar_alignment = "left",
  sidebar_collapse_level = 2,
  sidebar_pinned = FALSE,
  sidebar_tools = NULL,
  sidebar_contents = NULL,
  breadcrumbs = TRUE,
  page_navigation = FALSE,
  back_to_top = FALSE,
  reader_mode = FALSE,
  repo_url = NULL,
  repo_actions = NULL,
  navbar_style = NULL,
  navbar_bg_color = NULL,
  navbar_text_color = NULL,
  navbar_text_hover_color = NULL,
  navbar_brand = NULL,
  navbar_toggle = NULL,
  max_width = NULL,
  mainfont = "Fira Sans",
  fontsize = "16px",
  fontcolor = NULL,
  linkcolor = NULL,
  monofont = "Fira Code",
  monobackgroundcolor = NULL,
  linestretch = NULL,
  backgroundcolor = NULL,
  margin_left = NULL,
  margin_right = NULL,
  margin_top = NULL,
  margin_bottom = NULL,
  math = NULL,
  code_folding = NULL,
  code_tools = NULL,
  toc = NULL,
  toc_depth = 3,
  google_analytics = NULL,
  plausible = NULL,
  gtag = NULL,
  value_boxes = FALSE,
  metrics_style = NULL,
  page_layout = "full",
  mobile_toc = FALSE,
  viewport_width = NULL,
  viewport_scale = NULL,
  viewport_user_scalable = TRUE,
  self_contained = FALSE,
  code_overflow = NULL,
  html_math_method = NULL,
  shiny = FALSE,
  observable = FALSE,
  jupyter = FALSE,
  publish_dir = NULL,
  github_pages = NULL,
  netlify = NULL,
  allow_inside_pkg = FALSE,
  warn_before_overwrite = TRUE,
  sidebar_groups = NULL,
  navbar_sections = NULL,
  lazy_load_charts = FALSE,
  lazy_load_margin = "200px",
  lazy_load_tabs = NULL,
  lazy_debug = FALSE,
  pagination_separator = "of",
  pagination_position = "bottom",
  powered_by_dashboardr = TRUE,
  chart_export = FALSE,
  backend = "highcharter",
  contextual_viz_errors = FALSE
)
```

## Arguments

- output_dir:

  Directory for generated files

- title:

  Overall title for the dashboard site

- logo:

  Optional logo filename (will be copied to output directory)

- favicon:

  Optional favicon filename (will be copied to output directory)

- github:

  GitHub repository URL (optional)

- twitter:

  Twitter profile URL (optional)

- linkedin:

  LinkedIn profile URL (optional)

- email:

  Email address (optional)

- website:

  Website URL (optional)

- search:

  Enable search functionality (default: TRUE)

- theme:

  Bootstrap theme (cosmo, flatly, journal, etc.) (optional)

- custom_css:

  Path to custom CSS file (optional)

- custom_scss:

  Path to custom SCSS file (optional)

- tabset_theme:

  Tabset theme: "minimal" (default), "modern", "pills", "classic",
  "underline", "segmented", or "none"

- tabset_colors:

  Named list of tabset colors (e.g., list(active_bg = "#2563eb"))

- author:

  Author name for the site (optional)

- description:

  Site description for SEO (optional)

- page_footer:

  Custom footer text (optional)

- date:

  Site creation/update date (optional)

- sidebar:

  Enable/disable global sidebar (default: FALSE)

- sidebar_style:

  Sidebar style (floating, docked, etc.) (optional)

- sidebar_background:

  Sidebar background color (optional)

- sidebar_foreground:

  Sidebar foreground (text) color (optional)

- sidebar_border:

  Whether to show sidebar border (default TRUE)

- sidebar_alignment:

  Sidebar alignment: "left" (default) or "right"

- sidebar_collapse_level:

  Heading level at which sidebar items collapse (default 2)

- sidebar_pinned:

  Whether sidebar is pinned open (default FALSE)

- sidebar_tools:

  Sidebar tools configuration (optional)

- sidebar_contents:

  Sidebar contents configuration (optional)

- breadcrumbs:

  Whether to show breadcrumbs navigation (default TRUE)

- page_navigation:

  Whether to show prev/next page navigation (default FALSE)

- back_to_top:

  Whether to show a back-to-top button (default FALSE)

- reader_mode:

  Whether to enable reader mode (default FALSE)

- repo_url:

  Repository URL for source code link (optional)

- repo_actions:

  Repository actions configuration (optional)

- navbar_style:

  Navbar style (default, dark, light) (optional)

- navbar_bg_color:

  Navbar background color (CSS color value, e.g., "#2563eb", "rgb(37,
  99, 235)") (optional)

- navbar_text_color:

  Navbar text color (CSS color value, e.g., "#ffffff", "rgb(255, 255,
  255)") (optional)

- navbar_text_hover_color:

  Navbar text color on hover (CSS color value, e.g., "#f0f0f0")
  (optional)

- navbar_brand:

  Custom brand text (optional)

- navbar_toggle:

  Mobile menu toggle behavior (optional)

- max_width:

  Maximum width for page content (e.g., "1400px", "90%") (optional)

- mainfont:

  Font family for document text. Recommended: "Fira Sans" (smooth,
  modern), "Lato" (warm), "Source Sans Pro" (elegant), or "Roboto"
  (technical). Default is "Fira Sans" for a smooth, professional look.

- fontsize:

  Base font size for document (default: "16px" for optimal readability)

- fontcolor:

  Default text color (e.g., "#1f2937" for readable dark gray) (optional)

- linkcolor:

  Default hyperlink color (e.g., "#2563eb" for vibrant blue) (optional)

- monofont:

  Font family for code elements. Recommended: "Fira Code" (with
  ligatures), "JetBrains Mono", "Source Code Pro", or "IBM Plex Mono".
  Default: "Fira Code".

- monobackgroundcolor:

  Background color for code elements (e.g., "#f8fafc" for subtle gray)
  (optional)

- linestretch:

  Line height for text (default: 1.5) (optional)

- backgroundcolor:

  Background color for document (optional)

- margin_left:

  Left margin for document body (optional)

- margin_right:

  Right margin for document body (optional)

- margin_top:

  Top margin for document body (optional)

- margin_bottom:

  Bottom margin for document body (optional)

- math:

  Enable/disable math rendering (katex, mathjax) (optional)

- code_folding:

  Code folding behavior (none, show, hide) (optional)

- code_tools:

  Code tools (copy, download, etc.) (optional)

- toc:

  Table of contents (floating, left, right) (optional)

- toc_depth:

  TOC depth level (default: 3)

- google_analytics:

  Google Analytics ID (optional)

- plausible:

  Plausible analytics script hash (e.g., "pa-UnPiJwxFi8TS"). Find your
  script hash in Plausible Settings \> Tracking Code (Script
  Installation tab). This format includes ad-blocker bypass and doesn't
  require specifying your domain.

- gtag:

  Google Tag Manager ID (optional)

- value_boxes:

  Enable value box styling (default: FALSE)

- metrics_style:

  Metrics display style (optional)

- page_layout:

  Quarto page layout mode. Default is "full" for better mobile
  responsiveness. Other options: "article" (constrained width),
  "custom". See Quarto docs for details.

- mobile_toc:

  Logical. If TRUE, adds a collapsible mobile-friendly TOC button that
  appears in the top-right corner. Useful for mobile/tablet viewing.
  Default: FALSE.

- viewport_width:

  Numeric or character. Controls mobile viewport behavior. Default is
  NULL (standard responsive behavior). Set to a number (e.g., 1200) to
  force desktop rendering width on mobile devices. Useful if charts look
  squished on mobile. Can also be a full viewport string like
  "width=1400, minimum-scale=0.5" for advanced control.

- viewport_scale:

  Numeric. Initial zoom scale for mobile devices (e.g., 0.3 to zoom out,
  1.0 for no zoom). Only used if viewport_width is set. Default: NULL
  (no scale specified).

- viewport_user_scalable:

  Logical. Allow users to pinch-zoom on mobile? Default: TRUE. Only
  relevant if viewport_width is set.

- self_contained:

  Logical. If TRUE, produces a standalone HTML file with all
  dependencies embedded. Makes files larger but more portable and can
  improve mobile rendering consistency. Default: FALSE.

- code_overflow:

  Character. Controls code block overflow behavior. Options: "wrap"
  (wrap long lines), "scroll" (horizontal scrollbar). Default: NULL
  (Quarto default). Set to "wrap" to prevent horizontal scrolling issues
  on mobile.

- html_math_method:

  Character. Method for rendering math equations. Options: "mathjax",
  "katex", "webtex", "gladtex", "mathml". Default: NULL (Quarto
  default).

- shiny:

  Enable Shiny interactivity (default: FALSE)

- observable:

  Enable Observable JS (default: FALSE)

- jupyter:

  Enable Jupyter widgets (default: FALSE)

- publish_dir:

  Custom publish directory (optional)

- github_pages:

  GitHub Pages configuration (optional)

- netlify:

  Netlify deployment settings (optional)

- allow_inside_pkg:

  Allow output directory inside package (default FALSE)

- warn_before_overwrite:

  Warn before overwriting existing files (default TRUE)

- sidebar_groups:

  List of sidebar groups for hybrid navigation (optional)

- navbar_sections:

  List of navbar sections that link to sidebar groups (optional)

- lazy_load_charts:

  Enable lazy loading for charts (default: FALSE). When TRUE, charts
  only render when they scroll into view, dramatically improving initial
  page load time for pages with many visualizations.

- lazy_load_margin:

  Distance from viewport to start loading charts (default: "200px").
  Larger values mean charts start loading earlier.

- lazy_load_tabs:

  Only render charts in the active tab (default: TRUE when
  lazy_load_charts is TRUE). Charts in hidden tabs load when the tab is
  clicked.

- lazy_debug:

  Enable debug logging to browser console for lazy loading (default:
  FALSE). When TRUE, prints timing information for each chart load.

- pagination_separator:

  Text to show in pagination navigation (e.g., "of" -\> "1 of 3"),
  default: "of". Applies to all paginated pages unless overridden at
  page level.

- pagination_position:

  Default position for pagination controls: "bottom" (default, sticky at
  bottom), "top" (inline with page title), or "both" (top and bottom).
  This sets the default for all paginated pages. Individual pages can
  override this by passing position to add_pagination().

- powered_by_dashboardr:

  Whether to automatically add "Powered by dashboardr" branding
  (default: TRUE). When TRUE, adds a badge-style branding element. Can
  be overridden by explicitly calling add_powered_by_dashboardr() with
  custom options, or set to FALSE to disable entirely.

- chart_export:

  Whether to enable chart export functionality (default FALSE)

- backend:

  Rendering backend: "highcharter" (default), "plotly", "echarts4r", or
  "ggiraph".

- contextual_viz_errors:

  Logical. If TRUE, generated visualization chunks wrap viz calls in
  tryCatch and prepend contextual labels (title/type) to error messages.
  Default: FALSE.

## Value

A dashboard_project object

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic dashboard
dashboard <- create_dashboard("my_dashboard", "My Analysis Dashboard")

# Comprehensive dashboard with all features
dashboard <- create_dashboard(
  "my_dashboard",
  "My Analysis Dashboard",
  logo = "logo.png",
  github = "https://github.com/username/repo",
  twitter = "https://twitter.com/username",
  theme = "cosmo",
  author = "Dr. Jane Smith",
  description = "Comprehensive data analysis dashboard",
  page_footer = "(c) 2024 Company Name",
  sidebar = TRUE,
  toc = "floating",
  google_analytics = "GA-XXXXXXXXX",
  value_boxes = TRUE,
  shiny = TRUE
)

# Dashboard with lazy loading for better performance
dashboard <- create_dashboard(
  "fast_dashboard",
  "High Performance Dashboard",
  lazy_load_charts = TRUE,
  lazy_load_margin = "300px",
  lazy_load_tabs = TRUE
)

# Professional styling with modern fonts (Google Fonts work great!)
dashboard <- create_dashboard(
  "styled_dashboard",
  "Beautifully Styled Dashboard",
  navbar_bg_color = "#1e40af",     # Deep blue navbar
  mainfont = "Fira Sans",           # Smooth, modern (default choice)
  fontsize = "16px",
  fontcolor = "#1f2937",            # Dark gray for readability
  linkcolor = "#2563eb",            # Vibrant blue links
  monofont = "Fira Code",           # Code font with ligatures
  monobackgroundcolor = "#f8fafc",  # Light gray code background
  linestretch = 1.6,                # Comfortable line spacing
  backgroundcolor = "#ffffff"
)

# Alternative professional font combinations:
# Option 1: Warm & Friendly
dashboard <- create_dashboard(
  "friendly_dashboard",
  title = "Friendly Dashboard",
  mainfont = "Lato",                # Warm, approachable
  monofont = "JetBrains Mono"       # Excellent for code
)

# Option 2: Elegant & Refined
dashboard <- create_dashboard(
  "elegant_dashboard",
  title = "Elegant Dashboard",
  mainfont = "Source Sans Pro",     # Elegant, highly readable
  monofont = "Source Code Pro"      # Matching code font
)

# Option 3: Technical Feel
dashboard <- create_dashboard(
  "tech_dashboard",
  title = "Tech Dashboard",
  mainfont = "Roboto",              # Technical, clean
  monofont = "JetBrains Mono"       # Excellent for code
)
} # }
```
