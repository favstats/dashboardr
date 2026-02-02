# Test tutorial_dashboard generation
devtools::load_all()

temp_dir <- tempfile("test_tutorial")
tryCatch({
  suppressMessages(tutorial_dashboard(directory = temp_dir, open = FALSE))
  cat("Generated files:\n")
  print(list.files(temp_dir, pattern = "\\.qmd$"))
  cat("\nSuccess!\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n")
})

unlink(temp_dir, recursive = TRUE)
