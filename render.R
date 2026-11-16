# Give each published revision of a course chapter its own browser cache entry.
version_chapter_links <- function(html_dir, html_files) {
  chapters <- intersect(c("index", "baser", "statistik", "rmarkdown"),
                        tools::file_path_sans_ext(basename(html_files)))
  if (!length(chapters)) return(invisible(NULL))

  revisions <- substr(tools::md5sum(file.path(html_dir, paste0(chapters, ".html"))), 1L, 12L)
  patterns <- paste0('href="', chapters, '\\.html(?=[#"])')
  # The .html suffix keeps GitBook's keyboard search navigation working.
  targets <- paste0('href="', chapters, '.html?v=', revisions, '.html')

  # GitBook uses href to highlight and toggle the current chapter in the
  # sidebar. Read the link with its version from the entry for this data-path.
  script <- list.files(file.path(html_dir, "libs"), "^plugin-bookdown\\.js$",
                       recursive = TRUE, full.names = TRUE)
  stopifnot(length(script) == 1L)
  lines <- readLines(script, warn = FALSE)
  marker <- "    if (href === '') href = 'index.html';"
  stopifnot(sum(lines == marker) == 1L)
  lines <- append(lines, c(
    "    var chapter = $('ul.summary li.chapter[data-path=\"' + href + '\"] > a').first();",
    "    href = chapter.attr('href') || href;"
  ), after = match(marker, lines))
  writeLines(lines, script, useBytes = TRUE)

  script_revision <- substr(tools::md5sum(script), 1L, 12L)
  style_revision <- substr(tools::md5sum(file.path(html_dir, "assets", "style.css")), 1L, 12L)
  for (file in html_files) {
    html <- readLines(file, warn = FALSE, encoding = "UTF-8")
    if ("index" %in% chapters) {
      html <- gsub('href="./"', paste0('href="./?v=', revisions[match("index", chapters)], '.html"'),
                   html, fixed = TRUE)
    }
    for (i in seq_along(chapters)) {
      html <- gsub(patterns[i], targets[i], html, perl = TRUE)
    }
    html <- sub('plugin-bookdown.js"', paste0('plugin-bookdown.js?v=', script_revision, '"'),
                html, fixed = TRUE)
    html <- sub('href="assets/style.css"',
                paste0('href="assets/style.css?v=', style_revision, '"'), html, fixed = TRUE)
    writeLines(html, file, useBytes = TRUE)
  }
}

# Rebuild the website, the complete PDF, and one PDF per published topic.
render_course <- function() {
  packages <- c("bookdown", "qpdf", "jsonlite", "xml2", "vembedr")
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Install the required R packages first: install.packages(c(",
         paste(sprintf('"%s"', missing), collapse = ", "), "))", call. = FALSE)
  }
  if (!nzchar(Sys.which("xelatex"))) {
    stop("PDF downloads need XeLaTeX. Install TinyTeX with tinytex::install_tinytex(), then restart RStudio.",
         call. = FALSE)
  }

  config <- yaml::read_yaml("_bookdown.yml")
  book_name <- config$book_filename
  output_dir <- config$output_dir
  stage <- tempfile("course-pdf-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  html_dir <- file.path(stage, "html")
  chapter_file <- paste0(book_name, ".chapter-pages")
  if (file.exists(chapter_file)) unlink(chapter_file)

  # Shared setup applies to all topics; it resets format-specific options and
  # the random seed so computed examples agree across the two formats.
  pdf <- bookdown::render_book("index.Rmd", output_format = "bookdown::pdf_book",
                               output_dir = stage, new_session = FALSE)
  if (!file.exists(chapter_file)) {
    stop("The PDF did not record its chapter pages; no downloads were published.", call. = FALSE)
  }
  starts <- read.delim(chapter_file, sep = "|", header = FALSE,
                       col.names = c("id", "page"), stringsAsFactors = FALSE)
  if (!nrow(starts) || anyDuplicated(starts$id) || any(diff(starts$page) <= 0)) {
    stop("PDF chapters need unique heading IDs and must start on separate pages.", call. = FALSE)
  }

  bookdown::render_book("index.Rmd", output_format = "bookdown::gitbook",
                        output_dir = html_dir, new_session = FALSE)
  html_files <- list.files(html_dir, pattern = "\\.html$", full.names = TRUE)
  chapters <- list()
  for (html_file in html_files) {
    document <- xml2::read_html(html_file)
    headings <- xml2::xml_find_all(document,
      "//div[contains(concat(' ', normalize-space(@class), ' '), ' level1 ')]/h1")
    for (heading in headings) {
      id <- xml2::xml_attr(xml2::xml_parent(heading), "id")
      key <- gsub("[^A-Za-z0-9_-]", "", id)
      if (!key %in% starts$id) next
      title <- trimws(xml2::xml_text(heading))
      chapters[[key]] <- list(html = basename(html_file), title = title,
                              path = paste0("pdf/", key, ".pdf"))
    }
  }
  if (!all(starts$id %in% names(chapters))) {
    stop("Some PDF chapters have no matching website page; check their heading IDs.", call. = FALSE)
  }

  page_count <- qpdf::pdf_length(pdf)
  ends <- c(starts$page[-1L] - 1L, page_count)
  dir.create(file.path(html_dir, "pdf"), recursive = TRUE, showWarnings = FALSE)
  manifest <- list(`__book` = list(path = paste0(book_name, ".pdf"),
                                  title = "Alle kursusnotater (PDF)"))
  for (i in seq_len(nrow(starts))) {
    chapter <- chapters[[starts$id[i]]]
    qpdf::pdf_subset(pdf, pages = seq.int(starts$page[i], ends[i]),
                     output = file.path(html_dir, chapter$path))
    manifest[[chapter$html]] <- list(path = chapter$path, title = chapter$title)
  }
  file.copy(pdf, file.path(html_dir, paste0(book_name, ".pdf")), overwrite = TRUE)
  dir.create(file.path(html_dir, "plots"), recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files("plots", full.names = TRUE), file.path(html_dir, "plots"), overwrite = TRUE)
  file.copy(c("assets/downloads.js", "assets/downloads.css"), file.path(html_dir, "assets"), overwrite = TRUE)
  jsonlite::write_json(manifest, file.path(html_dir, "assets/pdf-downloads.json"),
                       auto_unbox = TRUE, pretty = TRUE)
  version_chapter_links(html_dir, html_files)
  # Publish generated files only after every PDF and link has been built.
  # Merge into docs/ so uploaded materials such as PDFs and datasets survive.
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(list.files(html_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE),
                       output_dir, recursive = TRUE, overwrite = TRUE)
  if (!all(copied)) stop("Some generated website files could not be copied to ", output_dir,
                         call. = FALSE)
  file.create(file.path(output_dir, ".nojekyll"))
  message("Website and PDF downloads are ready in ", output_dir, "/.")
  invisible(manifest)
}

render_course()
