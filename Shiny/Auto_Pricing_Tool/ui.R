#Load libraries:
#Everything from shiny
library(shiny)
library(shinyWidgets)
library(shinydashboard)
library(shinyBS)
library(shinyjs)
library(shinycssloaders)
library(shinyalert)
library(htmltools)

library(plotly)
# library(shinyFiles)
#In order to read in the file in different versions:
# library(readr)
# library(readxl)
#In order to use Datatables:
library(DT)
library(dplyr)
# library(tidyr)



#ONLY IF I WANT TO RUN IT ON THE SERVER!!
# library(rsconnect)
# rsconnect::deployApp('C:/Users/skmu1/OneDrive - EY/Actuarial Tool/R-Shiny Projects/R_to_WinRes/')

##################################################################################
# HTML Styles:
##################################################################################
#Create the theme of the dashboard:
# Create the theme
# mytheme <- create_theme(
#   adminlte_color(
#     light_blue = "#434C5E"
#   ),
#   adminlte_sidebar(
#     width = "400px",
#     dark_bg = "#D8DEE9",
#     dark_hover_bg = "#81A1C1",
#     dark_submenu_hover_color = "#000000",
#     dark_submenu_color = "#000000",
#     # dark_submenu_hover_bg = "#3c8dbc",
#     dark_color = "#2E3440"
#   ),
#   adminlte_global(
#     content_bg = "#FFF",
#     box_bg = "#D8DEE9",
#     info_box_bg = "#D8DEE9"
#   )
# )

##################################################################################
# UI-Elements:
##################################################################################
shinyUI(
  dashboardPage(skin = "blue",
                dashboardHeader(title = "Pricing Tool"),
                dashboardSidebar(
                  sidebarMenu(id = 'sidebarmenu',
                              menuItem("Scrape Autoscout:", tabName = "Introduction", startExpanded = TRUE,
                                       menuSubItem("Scrape Data", tabName = "Scrape_data"),
                                       menuSubItem("Combine Data", tabName = "Combine_scrape_data")
                              ),
                              menuItem("Data Analytics", tabName = "Data_Analytics", startExpanded = FALSE,
                                       menuSubItem("Data Analysis", tabName = "Data_analysis"),
                                       menuSubItem("Attractive Items", tabName = "Attractive_items")
                              )

                  )
                ),
                dashboardBody(
                  shinyjs::useShinyjs(),
                  ################################################################################
                  ################## Define some general styling #################################
                  ################################################################################
                  tags$style(
                    HTML(' #sidebar {
                      background-color: #ffffff;
                      box-shadow: rgba(9, 30, 66, 0.25) 0px 4px 8px -2px, rgba(9, 30, 66, 0.08) 0px 0px 0px 1px;
                      border-radius: 10px;
                    }

                    #divboxes {
                          border: 0px solid gray;
                          border-radius: 1em;
                          padding: 5px;
                          box-shadow: rgba(60, 64, 67, 0.3) 0px 1px 2px 0px, rgba(60, 64, 67, 0.15) 0px 1px 3px 1px;
                          background-color: #FEFFFF;
                    }

                    #stepbystep-intro {
                      padding-left: 15px;
                      padding-right: 15px;
                    }

                    #centricbutton{
                      display:flex;
                      justify-content:center;
                    }

                    #rightbutton{
                      display:flex;
                      justify-content:right;
                    }


                    #firsttitlesidebar {
                      text-decoration: underline;
                      margin-top: 0px;
                    }


                    .skin-blue .main-header .navbar .logo {
                          background-color: #26619c  ;
                    }

                    .info-box-content {
                        padding-top: 0px; padding-bottom: 0px;
                    }

                    .navigate-info-box .info-box-icon {
                        float: right;
                    }

                   ')
                  ),

                  ################################################################################
                  #########                     Tab Elements                    ##################
                  ################################################################################
                  tabItems(
                    ############################################################################
                    #########                   Scrape Data                       ##############
                    ############################################################################
                    tabItem(tabName = "Scrape_data",
                            h1(paste0("Scrappe Autoscout24 from ", Sys.Date())),
                            helpText("At least once a day, we want to click on the
                                     'Scrappe Data'-button to get an update of the
                                     newest cars on autoscout24."),
                            fluidRow(
                              column(4,
                                     box(title = "Scrape Data:", width = "100%",
                                         solidHeader = TRUE, collapsible = TRUE,
                                         helpText("Please provide first additinal Information
                                                    about the type of scrapping you want to achieve:"),
                                         fluidRow(
                                           column(6,
                                                  numericInput("scrape_data_numberofpages_start",
                                                               label = "How many pages do you want to scrape?",
                                                               min = 1, max = 10000, value = 1),
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
                                     ),
                                     uiOutput("scrape_data_combine_dataframes"),
                                     uiOutput("scrape_data_final_message")

                              ),
                              column(8,
                                     box(title = "General Info",
                                         width = "100%",
                                         solidHeader = TRUE, collapsible = TRUE,
                                         helpText("Be aware of the following things:"),
                                         tags$ol(
                                           tags$li("Each page will take around a 1 second to load."),
                                           tags$li("You see the status of the process on the right button."),
                                           tags$li("After the process is finished, you will see the scraped table.
                                                    By clicking on the button 'Aggregate Data to DB', you will be able
                                                    to add this data to the DB.")
                                         )
                                     ),
                                     uiOutput("scrape_data_scrappeddata_table_ui")
                              )
                            ),

                    ),
                    ############################################################################
                    #######             Combine Data with Autoscout - DB          ##############
                    ############################################################################
                    # tabItem(tabName = "Combine_scrape_data",
                    #         h1(paste0("Combine Scraped Data from ", Sys.Date())),
                    #         helpText("Load Scrapped Data and aggregated DB and combine them."),
                    #         fluidRow(
                    #           column(4,
                    #                  box(title = "DataBase Information:",
                    #                      width = "100%", status = "primary",
                    #                      solidHeader = TRUE, collapsible = TRUE,
                    #                      fileInput(inputId = "scrape_data_fileinput",
                    #                                label = "Please provide the current database:",
                    #                                multiple = F),
                    #                      div(id = "centricbutton",
                    #                          actionButton("scrape_data_load_autoscout_db", "Load Autoscout DB",
                    #                                       style="color: #FFFFFF; background-color:  #24a0ed; border-color:  #24a0ed")
                    #                      )
                    #                  ),
                    #                  uiOutput("scrape_data_infos"),
                    #                  uiOutput("scrape_data_generateDB")
                    #               ),
                    #           column(8,
                    #                   uiOutput("scrape_data_autoscout_table_ui"),
                    #                   # uiOutput("scrape_data_scrappeddata_table_ui")
                    #                   # DT::dataTableOutput("scrape_data_autoscout_table"),
                    #                   # DT::dataTableOutput("scrape_data_scrappeddata_table")
                    #               )
                    #         )
                    #
                    # ),
                    ############################################################################
                    #########                   Analyse Data                      ##############
                    ############################################################################
                    tabItem(tabName = "Data_analysis",
                            h1("Car Pricing Tool:"),
                            helpText("Please filter for your car and determine the correct pricing
                                     for it."),
                            # Display some KPIs
                            fluidRow(
                              valueBoxOutput("data_analysis_totlanumberofrows"),
                              valueBoxOutput("data_analysis_scrapingdate"),
                              valueBoxOutput("data_analysis_uniquetypsofcar")
                            ),
                            uiOutput("data_analysis_overall_graphs_ui")


                    ),
                    ############################################################################
                    #########                 Attractive Items                    ##############
                    ############################################################################
                    tabItem(tabName = "Attractive_items",
                            h1("How it works"),
                            helpText("Need still to be done:")

                    )
                  )
    )
  )
)

