library(shiny)
library(roxygen2)
library(openxlsx)
library(RSelenium)

# For data.table manipulations:
library(data.table)

# Also used direct calling of these two:
library(parallel)
library(future)

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
  scrape_data_frame <- reactiveValues()
  DB_data <- reactiveVal()
  filtering_data_base <- reactiveValues()
  # scrape_data_log_vales <- reactiveValues()

  #----------------------------------------------------------------------------#
  #                       Scrape Data
  #----------------------------------------------------------------------------#
  # As soon as the Scrape button is clicked, we do the following:
  observeEvent(input$scrape_data_startscraping, {
    # Measure the starting time:
    start_time <- Sys.time()

    # Determine the right Server-Port:
    port <- find_free_port()
    print(paste0("I am using Port: ", port))

    # Create the Selenium Server and navigate to the desired place:
    driver <- rsDriver(port = port, browser = "firefox")
    remote_driver <<- driver[["client"]]

    # Precompile the regex pattern
    item_list_pattern <- '"@type": "ItemList"'

    # Define the number of cores that you want to let run:
    numCores <- parallel::detectCores()
    # Adjust the number of workers based on your machine
    future::plan(future::multisession, workers = max(numCores-2,1))

    # Create a Progress object
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    progress$set(message = "Scraping Data", value = 0)

    # Initializing an result vector:
    results <- list()
    for (i in input$scrape_data_numberofpages_start:input$scrape_data_numberofpages_end) {
    # for (i in 1:10) {

      # Increment the progress bar, and update the detail text.
      progress$inc(1/input$scrape_data_numberofpages_end,
                   detail = paste("- Doing page", i))

      ### SCRAPE the data:
      results[[i]] <- process_page(page_number = i)
    }

    # # Free up the port, so that if you rerun it you will be able to use the same Port again!
    # remote_driver$close()

    # Combine all the dataframes into one
    final_result <<- do.call(rbind, results)
    # Save the raw scrapped data to the reactiveValues
    scrape_data_frame$raw_scrapped_data <- final_result

    # Stopping the end time and calculating the duration of the tool up until here:
    end_time <- Sys.time()
    duration <- end_time - start_time
    print(paste0("The tool took ", duration, "hours/minuts/seconds for the whole scraping!"))

    # Print the final combined dataframe
    print("All pages have been processed.")
    View(final_result)

    # Creating the output table for the extracted data
    output$scrape_data_scrappeddata_table_ui <- renderUI({
      outputlist <- list()
      outputlist[[1]] <-
        box(title = "Extracted Data:", width = "100%",
            solidHeader = TRUE, collapsible = TRUE,
            DT::dataTableOutput("scrape_data_scrappeddata_table_output")
        )
    })

    # Create the box to redirect to the aggregation part:
    output$scrape_data_combine_dataframes <- renderUI({
      outputlist <- list()
      outputlist[[1]] <- box(title = "Append to Database:", width = "100%",
                             solidHeader = TRUE, collapsible = TRUE,
                             helpText("Please upload the Autoscout Database:"),
                             fileInput(inputId = "scrape_data_fileinput",
                                       label = "Please provide the current database:",
                                       multiple = F),
                             helpText("Please click on the following button,
                                      to check whether the scraped cars are already in the database.
                                      If the cars or not yet in the database, they will be added."),
                             div(id = "centricbutton",
                                  actionButton("scrape_data_load_autoscout_db", "Load Autoscout DB",
                                               style="color: #FFFFFF; background-color:  #24a0ed; border-color:  #24a0ed")
                              )
      )
      return(outputlist)
    })

  })

  # Place for the data table output:
  # Show the first couple of rows of the Autoscout data table:
  output$scrape_data_scrappeddata_table_output <- DT::renderDataTable({
    if (is.null(scrape_data_frame$raw_scrapped_data)) {return()}
    #Output the data table
    return(datatable(scrape_data_frame$raw_scrapped_data , options = DToptions,
                     class = 'cell-border stripe', editable = T, rownames = F,
                     filter = "none"))
  })

  # As soon as the Combine Data Button is clicked, we combine the scrapped data
  ## with the corresponding database
  observeEvent(input$scrape_data_load_autoscout_db, {
    ### Load the data input:
    Fileinp <- input$scrape_data_fileinput
    autoscout_db$raw_data_info <- fileinp.filereadin(fileinp = Fileinp, shtnms = NULL,
                                                     range.selection = NULL, mltple = F)
    autoscout_db$data.table <- autoscout_db$raw_data_info[[1]]

    # Combine data from the scrapped data to the DB:
    autoscout_db$final.data.table <- adding_to_database(scrapped_dataframe = scrape_data_frame$raw_scrapped_data,
                                                        autoscout_db = autoscout_db$data.table)

    # Create the UI for the Autoscout DB table
    output$scrape_data_final_message <- renderUI({
      outputlist <- list()
      outputlist[[1]] <- box(title = "Status Message:",  status = "primary",
                             width = "100%", solidHeader = TRUE, collapsible = TRUE,
                             div(id = "centricbutton",
                                 helpText("The data was appended! Thanks for the scraping!")
                              )
      )

      return(outputlist)
    })


  })

  #----------------------------------------------------------------------------#
  #                       Combine Data
  #----------------------------------------------------------------------------#
  # observeEvent(input$scrape_data_load_autoscout_db, {
  #   ### Load the data input:
  #   Fileinp <- input$scrape_data_fileinput
  #   autoscout_db$raw_data_info <- fileinp.filereadin(fileinp = Fileinp, shtnms = NULL,
  #                                                    range.selection = NULL, mltple = F)
  #   autoscout_db$data.table <- autoscout_db$raw_data_info[[1]]
  #   # print(autoscout_db$data.table)
  #
  #   ### Load the second input box, which allows to give more detailed information
  #   ####  about the scrape process:
  #   # output$scrape_data_infos <- renderUI({
  #   #   outputlist <- list()
  #   #   outputlist[[1]] <-
  #   #     # box(title = "Scrpae the Data",
  #   #     #     width = "100%", status = "primary",
  #   #     #     solidHeader = TRUE, collapsible = TRUE,
  #   #     #     helpText("Please provide first additinal Information
  #   #     #              about the type of scrapping you want to achieve:"),
  #   #     # fluidRow(
  #   #     #   column(6,
  #   #     #          numericInput("scrape_data_numberofpages_start",
  #   #     #                       label = "How many pages do you want to scrape?",
  #   #     #                       min = 1, max = 10000, value = 1),
  #   #     #          shinyBS::bsTooltip(id = "scrape_data_numberofpages_start",
  #   #     #                             title = "For each page selected 20 car information are extracted.",
  #   #     #                             placement = "right", trigger = "hover",
  #   #     #                             options = list(container = "body")),
  #   #     #   ),
  #   #     #   column(6,
  #   #     #          numericInput("scrape_data_numberofpages_end",
  #   #     #                       label = "How many pages do you want to scrape?",
  #   #     #                       min = 1, max = 10000, value = 750),
  #   #     #          shinyBS::bsTooltip(id = "scrape_data_numberofpages_end",
  #   #     #                             title = "For each page selected 20 car information are extracted.",
  #   #     #                             placement = "right", trigger = "hover",
  #   #     #                             options = list(container = "body")),
  #   #     #   )
  #   #     # ),
  #   #     #
  #   #     #     hr(),
  #   #     #     helpText("By pressing the button 'Scrape Data', you will
  #   #     #              start the scraping of the autoscout24 data.",
  #   #     #              strong("This takes time!")),
  #   #     #     div(id = "centricbutton",
  #   #     #         actionButton("scrape_data_startscraping", "Scrape Data",
  #   #     #                      style="color: #FFFFFF; background-color:  #24a0ed; border-color:  #24a0ed")
  #   #     #      )
  #   #     # )
  #   #   return(outputlist)
  #   # })
  #   # Create the UI for the Autoscout DB table
  #   output$scrape_data_autoscout_table_ui <- renderUI({
  #     outputlist <- list()
  #     outputlist[[1]] <- box(title = "Autoscout DataBase:",
  #                          width = "100%", status = "primary",
  #                          solidHeader = TRUE, collapsible = TRUE,
  #                          DT::dataTableOutput("scrape_data_autoscout_table")
  #     )
  #
  #     return(outputlist)
  #   })
  #
  #
  # })
  #
  # # Show the first couple of rows of the Autoscout data table:
  # output$scrape_data_autoscout_table <- DT::renderDataTable({
  #   if (is.null(autoscout_db$data.table )) {return()}
  #   #Output the data table
  #   return(datatable(autoscout_db$data.table , options = DToptions,
  #                    class = 'cell-border stripe', editable = T, rownames = F,
  #                    filter = "none"))
  # })

  # As soon as the "Scrape Data" button is clicked, we start with the scraping of the data:

  #----------------------------------------------------------------------------#
  #                       Data Analysis
  #----------------------------------------------------------------------------#
  # As soon as the Data Analysis Tab is clicked, I will open it:
  observeEvent(input$sidebarmenu, {
    if (input$sidebarmenu == "Data_analysis") {
      # Save the autoscout data base into the reactive value:
      auto_DB <- fread(input = "./Output/Autoscout_Database.csv")
      # If the any element is "V1", we want to delete it, as it is an empty column
      if ("V1" %in% colnames(auto_DB)) {
        set(auto_DB, j = which(colnames(auto_DB) == "V1"), value = NULL)
      }
      DB_data(auto_DB)
    }

    # Fill the ValueBoxes with values:
    output$data_analysis_totlanumberofrows <- renderValueBox({
      valueBox(
        value = nrow(DB_data()), subtitle = "Number of datapoints:",
        icon = icon("list"), color = "aqua"
      )
    })
    output$data_analysis_scrapingdate <- renderValueBox({
      valueBox(
        value = max(DB_data()[["Datum"]]), subtitle = "Latest Scrapping Date:",
        icon = icon("list"), color = "aqua"
      )
    })
    output$data_analysis_uniquetypsofcar <- renderValueBox({
      valueBox(
        value = length(unique(DB_data()[["Marke"]])), subtitle = "Number of Car Types",
        icon = icon("list"), color = "aqua"
      )
    })

    # Create the sceleton for the filtering and the graphs display:
    output$data_analysis_overall_graphs_ui <- renderUI({
      datbas <- DB_data()
      outputlist <- list()
      outputlist[[1]] <-
        fluidRow(
          # This will be the filtering part
          column(4,
              box(title = "Filter for car:",
                  width = "100%", solidHeader = TRUE,
                  selectInput(inputId = "data_analysis_filter_carbrand",
                              label = "Select car brand:",
                              choices = unique(datbas[["Marke"]])),
                  selectInput(inputId = "data_analysis_filter_carmodel",
                              label = "Select car model:",
                              choices = NULL),
                  selectInput(inputId = "data_analysis_filter_carfueltype",
                              label = "Select car fuel type:",
                              choices = NULL),
                  selectInput(inputId = "data_analysis_filter_carconfiguration",
                              label = "Select car configuration:",
                              choices = NULL),
                  sliderInput("data_analysis_filter_registeredyear",
                              label = "Select car registration year:",
                              min = min(datbas[["Registriertes_Jahr"]]),
                              max = max(datbas[["Registriertes_Jahr"]]),
                              value = c(min(datbas[["Registriertes_Jahr"]]), max(datbas[["Registriertes_Jahr"]])),
                              step = 1,
                              sep = ""),
                  uiOutput("data_analysis_filter_for_car")
              )
          ),
          # This will be the graphs
          column(8,
              uiOutput("data_analysis_filtered_plot")
          )
        )
      return(outputlist)
    })
  })

  # Some update elements that influence the filtering options:
  observeEvent(input$data_analysis_filter_carbrand, {
    filtered_dt2 <- DB_data()[Marke == input$data_analysis_filter_carbrand, ]
    filtering_data_base$filter2 <- filtered_dt2
    updateSelectInput(session, "data_analysis_filter_carmodel", choices = c("All" , unique(filtered_dt2$Typ_grob)))
  })

  # Reactive for select3 based on select2 and select1
  observeEvent(input$data_analysis_filter_carmodel, {
    if (is.null(input$data_analysis_filter_carmodel)) return()

    if (input$data_analysis_filter_carmodel == "All") {
      filtered_dt3 <- DB_data()[Marke == input$data_analysis_filter_carbrand, ]
    }else{
      filtered_dt3 <- DB_data()[Marke == input$data_analysis_filter_carbrand & Typ_grob == input$data_analysis_filter_carmodel, ]
    }

    # Filter base 3
    filtering_data_base$filter3 <- filtered_dt3

    updateSelectInput(session, "data_analysis_filter_carfueltype", choices = c("All", unique(filtered_dt3$car_fuelType)))
  }, ignoreNULL = FALSE)

  # Reactive for select4 based on select3, select2 and select1
  observeEvent(input$data_analysis_filter_carfueltype, {
    if (is.null(input$data_analysis_filter_carfueltype)) return()

    # Filter if there is something to filter at
    if (input$data_analysis_filter_carfueltype != "All") {
      filtered_dt4 <- filtering_data_base$filter3[car_fuelType == input$data_analysis_filter_carbrand, ]
    }
    filtered_dt4 <- filtering_data_base$filter3
    filtering_data_base$filter4 <- filtered_dt4

    updateSelectInput(session, "data_analysis_filter_carconfiguration", choices = c("All", unique(filtered_dt4$car_configuration)))
  }, ignoreNULL = FALSE)


  observeEvent(input$data_analysis_filter_carconfiguration, {
    # Create a list of all possible data tables:
    db_data_tables_list <- list(filtering_data_base$filter4,
                                filtering_data_base$filter3,
                                filtering_data_base$filter2)
    # Initialize a variable to store the index of the first non-empty data table:
    first_non_empty_index <- NULL
    # Loop through the list and check for the first non-empty data.table
    for (i in seq_along(db_data_tables_list)) {
      if (nrow(db_data_tables_list[[i]]) > 0) {
        first_non_empty_index <- i
        print(i)
        break
      }
    }
    # Extract the data from the list:
    ## At least the complete data table for a car model is given in here, therefore
    ## there will always be one data table which is not empty!
    data_for_range <- db_data_tables_list[[first_non_empty_index]]

    print(min(as.numeric(data_for_range[["Registriertes_Jahr"]])))
    print(max(as.numeric(data_for_range[["Registriertes_Jahr"]])))
    print("----")
    updateSliderInput(session, "data_analysis_filter_registeredyear",
                      min = min(as.numeric(data_for_range[["Registriertes_Jahr"]])),
                      max = max(as.numeric(data_for_range[["Registriertes_Jahr"]])),
                      value = c(min(as.numeric(data_for_range[["Registriertes_Jahr"]])),
                                max(as.numeric(data_for_range[["Registriertes_Jahr"]]))))

    print("Bin hier durch")
  })

}
