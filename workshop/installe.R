# installe.R - Install all dependencies for dashboardr
# Run this script to set up your environment

# Install dashboardr itself (if not already installed)
pak::pak("favstats/dashboardr")

# Install gssr from r-universe (for tutorial/example data)
install.packages("gssr", repos = "https://kjhealy.r-universe.dev")



# Verify Quarto is installed (required for rendering)
if (!quarto::quarto_available()) {
  message("\n⚠️  Quarto CLI not found!")
  message("   Download from: https://quarto.org/docs/download/")
  message("   dashboardr requires Quarto >= 1.4\n")
}

cat("\n✅ All packages installed!\n")
