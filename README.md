# Analyse og visualisering af biologiske datasæt – 2027

Course notes for the 2026/27 academic year, using the same R Bookdown / GitBook setup and custom stylesheet as the [2026 course](https://sarah-ku.github.io/visualisation_2026/).

Website: https://sarah-ku.github.io/visualisation_2027/

Initially published: the introduction and **Grundlæggende R**. The chapter content is carried over from 2026.

## Edit and publish

1. Open `visualisation_2027.Rproj` in RStudio.
2. Edit `index.Rmd` (introduction) or `00-basics_v1.Rmd` (first chapter). Styling lives in `assets/style.css`.
3. Render the site from the R console:

   ```r
   source("render.R")
   ```

4. Preview `docs/index.html`, then commit and push the source changes **and the generated `docs/` files** to `main`.

GitHub Pages publishes `main` → `/docs`. It serves the rendered HTML; editing an `.Rmd` source alone does not rebuild the site.

If the required R packages are missing, install them once:

```r
install.packages(c("bookdown", "rmarkdown", "knitr", "png", "tidyverse"))
```

RStudio includes Pandoc, which is also required for rendering.

## Add a chapter later

Add the chapter's `.Rmd` source and its images, then append its filename to `rmd_files` in `_bookdown.yml` in the desired order. Rebuild and push as above. Only the explicitly listed chapters are included in the site and search.

## One-time Pages setting

In the repository's **Settings → Pages**, choose **Deploy from a branch**, branch **main**, folder **/docs**, and save. These settings only need to be configured once. Keep `docs/.nojekyll` so GitHub serves Bookdown's generated assets directly.
