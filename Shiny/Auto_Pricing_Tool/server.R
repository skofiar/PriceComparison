library(shiny)

## Input Variables:
# Make the input-size bigger:
options(shiny.maxRequestSize = 1000*1024^2)
# Extract working directory:
workingdir <- getwd()

## Source R - Function files:
source(paste0(getwd(),"/Shiny/Auto_Pricing_Tool/R/Excel_functions.R"))

# Define server logic required to draw a histogram
function(input, output, session) {
  # Generate the reactive Values list, where we save all the information in:
  autoscout_db <- reactiveValues()

  observeEvent(input$scrape_data_startscraping, {
    ### Load the data input:
    Fileinp <- input$scrape_data_fileinput
    autoscout_db$raw_data_info <- fileinp.filereadin(fileinp = Fileinp, shtnms = NULL,
                                                     range.selection = NULL, mltple = F)
    autoscout_db$data.table <- autoscout_db$raw_data_info[[1]]
    print(autoscout_db$data.table)

    ### Load the second input box, which allows to give more detailed information
    ####  about the scrape process:
    output$scrape_data_infos <- renderUI({
      outputlist <- list()
      outputlist[[1]] <-
        box(title = "Scrpae the Data",
            width = "100%", status = "primary",
            solidHeader = TRUE, collapsible = TRUE,
            helpText("Please provide first additinal Information
                     about the type of scrapping you want to achieve:"),
        fluidRow(
          column(6,
                 numericInput("scrape_data_numberofpages_start",
                              label = "How many pages do you want to scrape?",
                              min = 1, max = 10000, value = 750),
                 shinyBS::bsTooltip(id = "scrape_data_numberofpages_end",
                                    title = "For each page selected 20 car information are extracted.",
                                    placement = "right", trigger = "hover",
                                    options = list(container = "body")),
          ),
          column(6,
                 numericInput("scrape_data_numberofpages_end",
                              label = "How many pages do you want to scrape?",
                              min = 1, max = 10000, value = 750),
                 shinyBS::bsTooltip(id = "scrape_data_numberofpages_end",
                                    title = "For each page selected 20 car information are extracted.",
                                    placement = "right", trigger = "hover",
                                    options = list(container = "body")),
          )
        ),

            hr(),
            helpText("By pressing the button 'Scrape Data', you will
                     start the scraping of the autoscout24 data.",
                     strong("This takes time!")),
            div(id = "centricbutton",
                actionButton("scrape_data_startscraping", "Scrape Data",
                             style="color: #FFFFFF; background-color:  #24a0ed; border-color:  #24a0ed")
             )
        )
      return(outputlist)
    })
  })

  # As soon as the "Scrape Data" button is clicked, we start with the scraping of the data:


}
