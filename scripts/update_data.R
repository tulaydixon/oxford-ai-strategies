# Regenerates app/data/OxData.csv and public_pdfs/ from OxData.xlsx and pdfs/.
# Run from the project root: source("scripts/update_data.R")

local({
  dat <- readxl::read_excel("OxData.xlsx")
  names(dat) <- trimws(names(dat))

  required <- c("ID", "Tag", "Professor", "Professor_show", "Class",
                "Class_show", "Discipline", "Ways of Incorporating AI",
                "Ways of Limiting AI", "Handout")
  missing <- setdiff(required, names(dat))
  if (length(missing)) {
    stop("OxData.xlsx is missing column(s): ", paste(missing, collapse = ", "))
  }

  dup <- unique(dat$ID[duplicated(dat$ID)])
  if (length(dup)) {
    warning("Duplicate ID(s) in OxData.xlsx: ", paste(dup, collapse = ", "),
            ". Each row should have a unique ID matching its PDF.")
  }

  # The CSV ships to every visitor inside docs/app.json, so redact hidden
  # values here rather than only hiding them in the UI.
  is_yes <- function(x) !is.na(x) & toupper(trimws(x)) == "YES"
  dat$Professor[!is_yes(dat$Professor_show)] <- "Anonymous"
  dat$Class[!is_yes(dat$Class_show)] <- "Undisclosed"

  dir.create("app/data", recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, "app/data/OxData.csv", row.names = FALSE, na = "")

  # Shareable PDFs live outside app/ so shinylive doesn't bundle them into
  # app.json; scripts/export_site.R copies them to docs/pdfs/ as plain files.
  dir.create("public_pdfs", showWarnings = FALSE)
  unlink(list.files("public_pdfs", full.names = TRUE))
  shown <- dat$ID[toupper(trimws(dat$Handout)) %in% "YES"]
  pdfs <- file.path("pdfs", paste0(unique(shown), ".pdf"))
  absent <- pdfs[!file.exists(pdfs)]
  if (length(absent)) {
    warning("Handout is 'Yes' but PDF not found: ",
            paste(absent, collapse = ", "))
  }
  file.copy(pdfs[file.exists(pdfs)], "public_pdfs", overwrite = TRUE)

  message("Wrote ", nrow(dat), " rows to app/data/OxData.csv and copied ",
          sum(file.exists(pdfs)), " PDF(s) to public_pdfs/")
})
