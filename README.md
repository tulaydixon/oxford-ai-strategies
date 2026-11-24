---

editor_options: 
  markdown: 
    wrap: 72
---

# Oxford Faculty's Strategies to Limit or Incorporate AI and How These Strategies Map onto Liberal Arts Learning Outcomes — Shiny App

A browsable directory of how faculty are limiting or incorporating AI use in their assignments, filterable by tag, professor, class, discipline, and learning outcome. Deployed as a static site via [shinylive](https://posit-dev.github.io/r-shinylive/), so it can be hosted for free on GitHub Pages with no server required.

## Project structure

```         
OxData.xlsx          Source spreadsheet you edit directly (one row per assignment)
pdfs/                 Master copy of handout PDFs, named <ID>.pdf to match the ID column
scripts/
  update_data.R       Regenerates app/data + public_pdfs from the two sources above
  export_site.R       Exports the app to docs/ and copies public_pdfs into docs/pdfs
public_pdfs/          Generated copy of only the PDFs with Handout == "Yes"
app/
  app.R               The Shiny app itself
  data/OxData.csv      Generated copy of the spreadsheet the app reads
docs/                  Generated shinylive export — this is what GitHub Pages serves
  pdfs/                Generated copy of public_pdfs, served as plain static files
```

## Data columns

| Column | Meaning |
|------------------------------------|------------------------------------|
| `ID` | Unique numeric ID; matches a PDF filename in `pdfs/` (e.g. `3.pdf`) |
| `Tag` | Course designation, e.g. `QR` (Quantitative Reasoning) |
| `Professor` / `Professor_show` | Professor's last name; shown only if `Professor_show == "Yes"` (otherwise displayed as "Anonymous") |
| `Class` / `Class_show` | Course code; shown only if `Class_show == "Yes"` (otherwise "Undisclosed") |
| `Discipline` | General discipline of the assignment |
| `Knowledge of Human Cultures and the Physical and Natural World` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Inquiry and Analysis` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Critical Thinking` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Creative Thinking` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Written Communication` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Oral Communication` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Reading` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Quantitative Literacy` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Information Literacy` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Teamwork` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Problem Solving` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Civic Engagement` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Intercultural Knowledge and Competence` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Ethical Reasoning` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Foundations and Skills for Lifelong Learning` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Global Learning` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Integrative Learning` | `Yes` if the strategy helps foster this specific learning outcome; `No` otherwise |
| `Ways of Incorporating AI` | Free text describing AI-incorporating strategy |
| `Ways of Limiting AI` | Free text describing AI-limiting strategy |
| `Handout` | `"Yes"` if the assignment handout PDF may be linked/previewed |

## Updating the data

1.  Edit `OxData.xlsx` (add a row, fill in the columns above) and/or drop a new `<ID>.pdf` into `pdfs/`.

2.  Run the sync script from the project root:

    ``` r
    source("scripts/update_data.R")
    ```

    This regenerates `app/data/OxData.csv` and copies PDFs with `Handout == "Yes"` into `public_pdfs/`.

3.  Preview locally: open `app/app.R` in RStudio and click **Run App**, or run `shiny::runApp("app")`.

4.  Re-export the static site for deployment:

    ``` r
    source("scripts/export_site.R")
    ```

    This runs `shinylive::export("app", "docs")` and copies the PDFs into `docs/pdfs/`. Preview the exported site with `httpuv::runStaticServer("docs")`.

    (Install once with `install.packages("shinylive")` if needed.)

5.  Commit and push. Everything under `docs/` is what GitHub Pages serves.

## Deploying to GitHub Pages

1.  Push this repository to GitHub.
2.  In the repo settings, go to **Pages** and set the source to the `docs/` folder on your main branch (Settings → Pages → Build and deployment → Deploy from a branch → `main` / `docs`).
3.  GitHub will publish the app at `https://<your-username>.github.io/<repo-name>/`.
4.  Any time you update data or the app code, repeat the export step above and push — GitHub Pages picks up the new `docs/` contents automatically.

## Notes on the shinylive approach

- The app runs entirely in the visitor's browser via WebAssembly (webR) — there's no server to maintain or pay for, but the first load is slower (\~a few seconds) while R and packages initialize.
- PDF handouts are deliberately kept out of `app/` so shinylive doesn't bundle them into `app.json` (which every visitor downloads up front). Instead they're served as ordinary files from `docs/pdfs/`. The shinylive app runs in an iframe at `<site>/app_xxx/`, so the app links to `../pdfs/<ID>.pdf` (opening in a new tab) to reach the site root. When run locally, `app.R` maps `/pdfs` to `../public_pdfs` with `addResourcePath()`.
- Because shinylive apps run client-side, avoid adding server-side secrets or packages unsupported in webR (see the `shinylive` R package docs for supported package list).
