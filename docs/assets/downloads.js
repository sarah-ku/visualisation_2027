(function () {
  "use strict";

  // Resolve assets from this script so GitHub Pages project paths keep working.
  var script = document.currentScript;
  var bookRoot = new URL("../", script ? script.src : window.location.href);
  var manifest = null;
  var installed = false;

  function currentPage() {
    var path = window.location.pathname;
    if (path.indexOf(bookRoot.pathname) !== 0) return null;
    path = path.slice(bookRoot.pathname.length);
    if (!path || /\/$/.test(path)) path += "index.html";
    try {
      return decodeURIComponent(path);
    } catch (error) {
      return path;
    }
  }

  function pdfUrl(entry) {
    if (!entry || typeof entry.path !== "string") return null;
    var pdf;
    try {
      pdf = new URL(entry.path, bookRoot);
    } catch (error) {
      return null;
    }
    if (pdf.origin !== bookRoot.origin || pdf.pathname.indexOf(bookRoot.pathname) !== 0 || !/\.pdf$/i.test(pdf.pathname)) return null;
    return pdf;
  }

  function setDownloadLink(link, pdf, title) {
    // This origin-relative link retains /visualisation_2027/ on GitHub Pages.
    link.href = pdf.pathname + pdf.search;
    link.setAttribute("download", pdf.pathname.split("/").pop());
    link.title = title;
  }

  function downloadMenu() {
    var icon = document.querySelector(".book-header .fa-download");
    var toggle = icon && icon.closest(".btn");
    var dropdown = toggle && toggle.closest(".dropdown");

    // Bookdown renders one PDF as a direct button. Replace it with a menu
    // containing direct download links instead of its window.open callback.
    if (!dropdown) {
      icon = document.querySelector(".book-header > .btn .fa-file-pdf-o");
      var fullBookButton = icon && icon.closest(".btn");
      var fullBookEntry = manifest.__book;
      var fullBookPdf = pdfUrl(fullBookEntry);
      if (!fullBookButton || !fullBookPdf) return null;

      dropdown = document.createElement("div");
      dropdown.className = "dropdown pull-left js-toolbar-action";
      fullBookButton.parentNode.insertBefore(dropdown, fullBookButton);

      toggle = document.createElement("a");
      toggle.className = "btn toggle-dropdown";
      toggle.href = "#";
      toggle.setAttribute("aria-label", "Download PDF");
      toggle.setAttribute("aria-haspopup", "true");
      toggle.title = "Download PDF";
      toggle.innerHTML = '<i class="fa fa-download" aria-hidden="true"></i>';
      dropdown.appendChild(toggle);

      var menu = document.createElement("div");
      menu.className = "dropdown-menu dropdown-right";
      menu.innerHTML = '<div class="dropdown-caret"><span class="caret-outer"></span><span class="caret-inner"></span></div>';
      dropdown.appendChild(menu);

      var fullBookRow = document.createElement("div");
      fullBookRow.className = "buttons course-book-pdf-row";
      var fullBookLink = document.createElement("a");
      fullBookLink.className = "button size-1";
      fullBookLink.textContent = fullBookEntry.title || "Alle kursusnotater (PDF)";
      setDownloadLink(fullBookLink, fullBookPdf, fullBookLink.textContent);
      fullBookRow.appendChild(fullBookLink);
      menu.appendChild(fullBookRow);
      fullBookButton.remove();
    }

    dropdown.classList.add("course-pdf-downloads");
    return dropdown.querySelector(".dropdown-menu");
  }

  function updateDownload() {
    if (!manifest) return;
    var page = currentPage();
    var entry = page && Object.prototype.hasOwnProperty.call(manifest, page) ? manifest[page] : null;
    var existing = document.querySelector(".course-topic-pdf-row");
    var pdf = pdfUrl(entry);

    // Only use local PDFs inside this book, and leave native downloads alone
    // on pages without a corresponding topic PDF (for example, the 404 page).
    if (!pdf) {
      if (existing) existing.remove();
      return;
    }

    var menu = downloadMenu();
    if (!menu) return;
    var row = menu.querySelector(".course-topic-pdf-row");
    if (!row) {
      row = document.createElement("div");
      row.className = "buttons course-topic-pdf-row";
      var link = document.createElement("a");
      link.className = "button size-1";
      link.textContent = "Dette emne (PDF)";
      row.appendChild(link);
      menu.appendChild(row);
    }

    var topicLink = row.querySelector("a");
    setDownloadLink(topicLink, pdf, entry.title ? entry.title + " (PDF)" : "Dette emne (PDF)");
  }

  function install() {
    if (installed || !window.gitbook || !window.gitbook.events) return;
    installed = true;
    window.gitbook.events.bind("page.change", updateDownload);
    window.fetch(new URL("assets/pdf-downloads.json", bookRoot), { cache: "no-cache" })
      .then(function (response) {
        if (!response.ok) throw new Error("PDF manifest unavailable");
        return response.json();
      })
      .then(function (data) {
        if (!data || typeof data !== "object" || Array.isArray(data)) return;
        manifest = data;
        updateDownload();
      })
      .catch(function () {
        // A missing manifest must not affect reading or the full-course PDF.
      });
  }

  install();
  document.addEventListener("DOMContentLoaded", install);
  window.addEventListener("load", install);
})();
