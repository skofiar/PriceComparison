library(shiny)
library(roxygen2)
library(openxlsx)

## Input Variables:
# Make the input-size bigger:
options(shiny.maxRequestSize = 1000*1024^2)

##################################################################################
# Working directories:
##################################################################################
# Extract working directory:
workingdir <- getwd()

##################################################################################
# Load Source-Files:
##################################################################################
## Source R - Function files:
source("./R/Excel_functions.R")

# Autoscout Source files
source("./R/Port_finding_helperfunction.R")
source("./R/Page_Information.R")
source("./R/Extract_Data.R")
source("./R/Adding_to_Database.R")
source("./R/Prepare_Scrapped_Data.R")


##################################################################################
# Excel Output Style:
##################################################################################
grybckgrndclr <- createStyle(fgFill = "gray93")
bckgrndclr <- createStyle(fgFill = "white")
insideBorders <- createStyle( border = c("top", "bottom"), borderStyle = "thin", fgFill = "white")
header_st <- createStyle(textDecoration = "Bold", fgFill = "yellow", border = c("top", "left", "bottom", "right"))
pth_stl <- createStyle(textDecoration = "Bold", fontSize = 13)

##################################################################################
# Initialiazing Variables:
##################################################################################
#Defining the options for the dataTableOutput:
DToptions <- list(autoWidth = FALSE, scrollX = TRUE,
                  columnDefs = list(list(width = "125px", targets = "_all")),dom = 'tpB',
                  lengthMenu = list(c(5, 10,-1), c('5', '10', 'All')), pageLength = 7)

##################################################################################
# Server Functions:
##################################################################################
function(input, output, session) {
  # Generate the reactive Values list, where we save all the information in:
  autoscout_db <- reactiveValues()

  observeEvent(input$scrape_data_startscraping, {
    ### Load the data input:
    Fileinp <- input$scrape_data_fileinput
    autoscout_db$raw_data_info <- fileinp.filereadin(fileinp = Fileinp, shtnms = NULL,
                                                     range.selection = NULL, mltple = F)
    autoscout_db$data.table <- autoscout_db$raw_data_info[[1]]
    # print(autoscout_db$data.table)

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
                              min = 1, max = 10000, value = 1),
                 shinyBS::bsTooltip(id = "scrape_data_numberofpages_start",
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
    # Create the UI for the Autoscout DB table
    output$scrape_data_autoscout_table_ui <- renderUI({
      outputlist <- list()
      outputlist[[1]] <- box(title = "Autoscout DataBase:",
                           width = "100%", status = "primary",
                           solidHeader = TRUE, collapsible = TRUE,
                           DT::dataTableOutput("scrape_data_autoscout_table")
      )

      return(outputlist)
    })


  })

  # Show the first couple of rows of the Autoscout data table:
  output$scrape_data_autoscout_table <- DT::renderDataTable({
    if (is.null(autoscout_db$data.table )) {return()}
    #Output the data table
    return(datatable(autoscout_db$data.table , options = DToptions,
                     class = 'cell-border stripe', editable = T, rownames = F,
                     filter = "none"))
  })

  # As soon as the "Scrape Data" button is clicked, we start with the scraping of the data:


}
