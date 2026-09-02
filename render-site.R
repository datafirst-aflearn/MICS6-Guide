# Build the full site: book chapters + navigation landing page.
# Use this instead of bookdown::render_book() alone.

if (!file.exists("_bookdown.yml")) {
  stop("Run this script from the MICS6-Guide project root.")
}

# Remove stale knitr/bookdown cache
for (d in c("mics6-guide_cache", "_bookdown_files")) {
  if (dir.exists(d)) unlink(d, recursive = TRUE)
}

bookdown::render_book("index.Rmd")
source("R/publish-nav.R", local = TRUE)

message("Done. Open docs/index.html to view the navigation home page.")
