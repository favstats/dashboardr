# Welcome to the Tutorial Dashboard!

# Welcome to the Tutorial Dashboard!

Code

Thank you for downloading and using Dashboardr. We hope that you’ll find
it helpful and fun to use.

## How to use this package

Here’s some information that you might find handy while you learn to use
the package. This is a tutorial dashboard, which means that these pages
were written by us, and are saved in the `dashboardr` R package.
However, when you decide to call `create_dashboard()` using your own or
sample data, an output directory will be generated.

## Locating your dashboard

Unless otherwise specified, your dashboard lives in the output
directory! For example:

C:/Users/user/test_dashboard

├── index.qmd

├── example_dashboard.qmd

├── standalone_charts.qmd

├── text_only_page.qmd

└── showcase_dashboard.qmd

## Editing your dashboard after rendering

You’ll also have the option to write a new GitHub repository.
`dashboardr` will tell you where it is saved upon rendering.

If you’d like to edit your pages further, you can do so by navigating to
the output directory and editing the .qmd files manually. If that
doesn’t suit you, then you can also create visualizations with
`create_viz() %>% add_viz()`, and build out the dashboard with
`add_page()`.

For an example of a dashboard that demonstrates the full breadth of this
package, click on the Showcase tab on the toolbar above. This tutorial
dashboard demonstrates the `dashboardr` package using real examples from
the vignettes.

## About this tutorial dashboard

This dashboard uses data from the **General Social Survey (GSS)** to
explore patterns in happiness, trust, and political attitudes.

Navigate through the pages above to explore the data and see the package
features in action.

Back to top
