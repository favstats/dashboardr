# Generate \_quarto.yml configuration file

Internal function that generates the complete Quarto website
configuration file based on the dashboard project settings. Handles all
Quarto website features including navigation, styling, analytics, and
deployment options.

## Usage

``` r
.generate_chunk_label(spec, spec_name = NULL)
```

## Arguments

- spec:

  Visualization specification object

- spec_name:

  Optional name for the specification

- proj:

  A dashboard_project object containing all configuration settings

## Value

Character vector of YAML lines for the \_quarto.yml file

Character string with sanitized chunk label

## Details

This function generates a comprehensive Quarto configuration including:

- Project type and output directory

- Website title, favicon, and branding

- Navbar with social media links and search

- Sidebar with auto-generated navigation

- Format settings (theme, CSS, math, code features)

- Analytics (Google Analytics, Plausible, GTag)

- Deployment settings (GitHub Pages, Netlify)

- Iconify filter for icon support Generate unique R chunk label for a
  visualization

Internal function that creates a unique, descriptive R chunk label based
on the visualization specification. Uses tabgroup, variable names,
title, or type to create meaningful labels.
