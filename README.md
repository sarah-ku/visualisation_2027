# Analyse og visualisering af biologiske datasæt – 2027

Course notes for the 2026/27 academic year, using the same R Bookdown / GitBook setup and custom stylesheet as the [2026 course](https://sarah-ku.github.io/visualisation_2026/).

Website: https://sarah-ku.github.io/visualisation_2027/

Published topics: **Lidt om kurset**, **Grundlæggende R**, **Grundlæggende statistik i base R**, **Introduktion til R Markdown**, **Visualisering - ggplot2 dag 1** (Kapitel 4), and **Visualisering - ggplot2 dag 2** (Kapitel 5).

## Edit and publish

1. Open `visualisation_2027.Rproj` in RStudio.
2. Edit `index.Rmd` (introduction), `00-baser.Rmd` (base R), `01-statistik.Rmd` (statistics), `01-rmark_v1.Rmd` (R Markdown), `uge47_ggplot2_dag1.Rmd` (ggplot2 day 1), or `uge47_ggplot2_dag2.Rmd` (ggplot2 day 2). Styling lives in `assets/style.css`.
3. Render the site from the R console:

   ```r
   source("render.R")
   ```

4. Preview `docs/index.html` and the PDF downloads, then commit and push the source changes **and all generated `docs/` files** to `main`.

GitHub Pages publishes `main` → `/docs`. It serves the rendered HTML; editing an `.Rmd` source alone does not rebuild the site.

If the required R packages are missing, install them once:

```r
install.packages(c("bookdown", "rmarkdown", "knitr", "png", "jpeg", "tidyverse", "RColorBrewer", "ggrepel", "palmerpenguins", "qpdf", "vembedr"))
```

RStudio includes Pandoc, which is also required for rendering. PDF generation also needs XeLaTeX. If you do not already have a LaTeX installation, install TinyTeX once and restart RStudio:

```r
tinytex::install_tinytex()
```

Install the small LaTeX packages used for wrapping long code lines:

```r
tinytex::tlmgr_install(c("fvextra", "upquote", "lineno"))
```

## PDF downloads

The download icon at the top of the website offers **Alle kursusnotater (PDF)** and **Dette emne (PDF)**. The complete PDF includes all currently published topics. Topic PDFs contain only the current topic, with the same chapter numbers and content as the complete PDF.

`source("render.R")` regenerates both the website and these downloads. It builds the complete PDF, extracts each topic at its chapter boundaries, and updates the download menu automatically. Adding a chapter to `_bookdown.yml` therefore adds it to the complete PDF and creates its individual PDF on the next rebuild. Commit the generated PDFs together with the HTML so the versions stay in sync.

## Add a chapter later

Add the chapter's `.Rmd` source and its images, then append its filename to `rmd_files` in `_bookdown.yml` in the desired order. Rebuild and push as above. Only the explicitly listed chapters are included in the site and search. The published course currently includes Kapitel 1–5 and the introduction; draft chapters 7 and 8 stay in the ignored local preview.

## One-time Pages setting

In the repository's **Settings → Pages**, choose **Deploy from a branch**, branch **main**, folder **/docs**, and save. These settings only need to be configured once. Keep `docs/.nojekyll` so GitHub serves Bookdown's generated assets directly.
