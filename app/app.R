library(shiny)
library(bslib)

# Data ------------------------------------------------------------------------

dat <- read.csv("data/OxData.csv", check.names = FALSE,
                stringsAsFactors = FALSE, na.strings = "")

is_yes <- function(x) !is.na(x) & toupper(trimws(x)) == "YES"

outcomes <- c(
  "Knowledge of Human Cultures and the Physical and Natural World",
  "Inquiry and Analysis", "Critical Thinking", "Creative Thinking",
  "Written Communication", "Oral Communication", "Reading",
  "Quantitative Literacy", "Information Literacy", "Teamwork",
  "Problem Solving", "Civic Engagement",
  "Intercultural Knowledge and Competence", "Ethical Reasoning",
  "Foundations and Skills for Lifelong Learning", "Global Learning",
  "Integrative Learning"
)
outcomes <- intersect(outcomes, names(dat))

dat$prof_display  <- ifelse(is_yes(dat$Professor_show), dat$Professor, "Anonymous")
dat$class_display <- ifelse(is_yes(dat$Class_show), dat$Class, "Undisclosed")
dat$has_incorp <- !is.na(dat$`Ways of Incorporating AI`) &
  nzchar(trimws(dat$`Ways of Incorporating AI`))
dat$has_limit <- !is.na(dat$`Ways of Limiting AI`) &
  nzchar(trimws(dat$`Ways of Limiting AI`))

choices_for <- function(x) sort(unique(x[!is.na(x)]))

# Local runs serve handouts from ../public_pdfs; the shinylive site serves them
# as static files from docs/pdfs/. Links use "../pdfs/" because the shinylive
# app runs in an iframe at <site>/app_xxx/, so "../" reaches the site root
# (and locally "../" from "/" resolves to "/").
if (dir.exists("../public_pdfs")) {
  addResourcePath("pdfs", normalizePath("../public_pdfs"))
}

# UI --------------------------------------------------------------------------

ui <- page_sidebar(
  title = "Oxford Faculty's Strategies to Limit or Incorporate AI and How These Strategies Map onto Liberal Arts Learning Outcomes",
  theme = bs_theme(version = 5, preset = "shiny"),
  sidebar = sidebar(
    width = 320,
    textInput("search", "Search text", placeholder = "e.g. reflection, oral exam"),
    radioButtons(
      "approach", "Approach to AI",
      choices = c("Any" = "any", "Incorporating AI" = "incorp",
                  "Limiting AI" = "limit")
    ),
    accordion(
      open = FALSE,
      accordion_panel(
        "Course",
        selectizeInput("tag", "Tag", choices_for(dat$Tag), multiple = TRUE),
        selectizeInput("discipline", "Discipline", choices_for(dat$Discipline),
                       multiple = TRUE),
        selectizeInput("prof", "Professor", choices_for(dat$prof_display),
                       multiple = TRUE),
        selectizeInput("class", "Class", choices_for(dat$class_display),
                       multiple = TRUE)
      ),
      accordion_panel(
        "Learning outcomes",
        checkboxGroupInput("outcomes", NULL, choices = outcomes),
        helpText("Shows assignments that foster all selected outcomes.")
      )
    ),
    actionButton("reset", "Reset filters", class = "btn-outline-secondary btn-sm")
  ),
  uiOutput("count"),
  uiOutput("cards")
)

# Server ----------------------------------------------------------------------

server <- function(input, output, session) {

  observeEvent(input$reset, {
    updateTextInput(session, "search", value = "")
    updateRadioButtons(session, "approach", selected = "any")
    for (id in c("tag", "discipline", "prof", "class")) {
      updateSelectizeInput(session, id, selected = character(0))
    }
    updateCheckboxGroupInput(session, "outcomes", selected = character(0))
  })

  filtered <- reactive({
    d <- dat
    if (length(input$tag))        d <- d[d$Tag %in% input$tag, ]
    if (length(input$discipline)) d <- d[d$Discipline %in% input$discipline, ]
    if (length(input$prof))       d <- d[d$prof_display %in% input$prof, ]
    if (length(input$class))      d <- d[d$class_display %in% input$class, ]
    if (input$approach == "incorp") d <- d[d$has_incorp, ]
    if (input$approach == "limit")  d <- d[d$has_limit, ]
    for (o in input$outcomes) d <- d[is_yes(d[[o]]), ]

    q <- trimws(input$search)
    if (nzchar(q) && nrow(d)) {
      hay <- paste(d$Tag, d$Discipline, d$prof_display, d$class_display,
                   d$`Ways of Incorporating AI`, d$`Ways of Limiting AI`)
      d <- d[grepl(q, hay, ignore.case = TRUE, fixed = FALSE), ]
    }
    d
  })

  output$count <- renderUI({
    p(class = "text-muted mb-0",
      sprintf("Showing %d of %d assignments", nrow(filtered()), nrow(dat)))
  })

  output$cards <- renderUI({
    d <- filtered()
    if (!nrow(d)) {
      return(p("No assignments match the current filters."))
    }
    layout_column_wrap(
      width = "420px",
      fill = FALSE,
      !!!lapply(seq_len(nrow(d)), \(i) assignment_card(d[i, ]))
    )
  })
}

assignment_card <- function(r) {
  fostered <- outcomes[vapply(outcomes, \(o) is_yes(r[[o]]), logical(1))]

  strategy <- function(label, text) {
    if (is.na(text) || !nzchar(trimws(text))) return(NULL)
    # Blank lines start a new paragraph; single line breaks become <br>
    text <- gsub("\r\n?", "\n", trimws(text))
    paras <- strsplit(text, "\n[[:space:]]*\n")[[1]]
    tagList(
      h6(label, class = "mt-2"),
      lapply(paras, \(para) {
        lines <- strsplit(trimws(para), "\n", fixed = TRUE)[[1]]
        content <- list(lines[1])
        for (line in lines[-1]) content <- c(content, list(tags$br(), line))
        p(content)
      })
    )
  }

  handout <- if (is_yes(r$Handout)) {
    card_footer(
      tags$a(href = sprintf("../pdfs/%s.pdf", r$ID), target = "_blank",
             class = "btn btn-sm btn-primary", "View handout (PDF)")
    )
  }

  card(
    card_header(
      div(
        strong(r$class_display), " ",
        span(class = "badge text-bg-secondary", r$Tag)
      ),
      div(class = "small text-muted", r$Discipline, " | Prof. ", r$prof_display)
    ),
    card_body(
      strategy("Ways of incorporating AI", r$`Ways of Incorporating AI`),
      strategy("Ways of limiting AI", r$`Ways of Limiting AI`),
      if (length(fostered)) {
        tags$details(
          tags$summary(sprintf("Learning outcomes fostered (%d)", length(fostered))),
          div(class = "mt-2",
              lapply(fostered, \(o) span(class = "badge text-bg-light border me-1 mb-1", o)))
        )
      }
    ),
    handout
  )
}

shinyApp(ui, server)
