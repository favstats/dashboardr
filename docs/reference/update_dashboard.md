# Update dashboard on GitHub

Convenience function to add, commit, and push changes to GitHub. Works
from the current working directory.

## Usage

``` r
update_dashboard(files = ".", message = "Update dashboard", ask = TRUE)
```

## Arguments

- files:

  Files to add. Can be:

  - `"."` to add all changes (default)

  - A character vector of specific file paths

  - A glob pattern (e.g., "*.R", "docs/*")

- message:

  Commit message (default: "Update dashboard")

- ask:

  Whether to ask for confirmation before pushing (default: TRUE)

## Value

Invisibly returns TRUE

## Examples

``` r
if (FALSE) { # \dontrun{
# Update all changes (will ask for confirmation)
update_dashboard()

# Update with custom message
update_dashboard(message = "Fix navbar styling")

# Update specific files
update_dashboard(files = c("docs/index.html", "docs/styles.css"))

# Skip confirmation prompt
update_dashboard(ask = FALSE)
} # }
```
