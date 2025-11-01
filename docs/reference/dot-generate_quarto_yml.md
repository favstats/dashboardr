# Generate \_quarto.yml configuration file

Internal function that generates the complete Quarto website
configuration file based on the dashboard project settings. Handles all
Quarto website features including navigation, styling, analytics, and
deployment options.

## Usage

``` r
.generate_quarto_yml(proj)
```

## Arguments

- proj:

  A dashboard_project object containing all configuration settings

## Value

Character vector of YAML lines for the \_quarto.yml file

## Details

This function generates a comprehensive Quarto configuration including:

- Project type and output directory

- Website title, favicon, and branding

- Navbar with social media links and search

- Sidebar with auto-generated navigation

- Format settings (theme, CSS, math, code features)

- Analytics (Google Analytics, Plausible, GTag)

- Deployment settings (GitHub Pages, Netlify)

- Iconify filter for icon support
