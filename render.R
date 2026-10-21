# Rebuild the published GitBook and copy its static image assets.
bookdown::render_book("index.Rmd", output_format = "bookdown::gitbook")
dir.create("docs/plots", recursive = TRUE, showWarnings = FALSE)
file.copy(list.files("plots", full.names = TRUE), "docs/plots", overwrite = TRUE)
file.create("docs/.nojekyll")
