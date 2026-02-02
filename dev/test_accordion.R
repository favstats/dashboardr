# Test that tutorial_dashboard has the code accordion
devtools::load_all()

temp_dir <- tempfile("test_tutorial")
suppressMessages(tutorial_dashboard(directory = temp_dir))

cat("Generated files:\n")
print(list.files(temp_dir, pattern = "\\.qmd$"))

# Check if index has the accordion
index_content <- readLines(file.path(temp_dir, "index.qmd"))
accordion_found <- any(grepl("View Full Dashboard Code", index_content))
cat("Accordion found in tutorial index:", accordion_found, "\n")

unlink(temp_dir, recursive = TRUE)

# Test showcase too
temp_dir2 <- tempfile("test_showcase")
suppressMessages(showcase_dashboard(directory = temp_dir2))

index_content2 <- readLines(file.path(temp_dir2, "index.qmd"))
accordion_found2 <- any(grepl("View Full Dashboard Code", index_content2))
cat("Accordion found in showcase index:", accordion_found2, "\n")

unlink(temp_dir2, recursive = TRUE)
