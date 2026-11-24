# Exports the app to docs/ with shinylive and adds the handout PDFs as plain
# static files in docs/pdfs/. Run from the project root after update_data.R:
# source("scripts/export_site.R")

local({
  shinylive::export("app", "docs")

  # shinylive's index.html uses a generic "Shiny App" browser-tab title
  index <- readLines("docs/index.html")
  index <- sub("<title>Shiny App</title>",
               "<title>Oxford Faculty Strategies on AI</title>", index, fixed = TRUE)
  writeLines(index, "docs/index.html")

  # Tell GitHub Pages to serve files as-is rather than processing with Jekyll
  file.create("docs/.nojekyll")

  dir.create("docs/pdfs", showWarnings = FALSE)
  unlink(list.files("docs/pdfs", full.names = TRUE))
  pdfs <- list.files("public_pdfs", pattern = "\\.pdf$", full.names = TRUE)
  file.copy(pdfs, "docs/pdfs", overwrite = TRUE)

  message("Copied ", length(pdfs), " PDF(s) to docs/pdfs/")
})
