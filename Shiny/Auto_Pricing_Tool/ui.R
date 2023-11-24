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
                dashboardHeader(title = "Car_Pricing"),
                dashboardSidebar(
                  sidebarMenu(id = 'sidebarmenu',
                              menuItem("Scrape Autoscout:", tabName = "Introduction", startExpanded = TRUE,
                                       menuSubItem("Scrape Data", tabName = "Scrape_data")
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
                    #########             Scrape Data from Autoscout24            ##############
                    ############################################################################
                    tabItem(tabName = "Scrape_data",
                            h1(paste0("Scrappe Autoscout24 from ", Sys.Date())),
                            helpText("At least once a day, we want to click on the
                                     'Scrappe Data'-button to get an update of the
                                     newest cars on autoscout24."),
                            fluidRow(
                              column(4,
                                     box(title = "DataBase Information:",
                                         width = "100%", status = "primary",
                                         solidHeader = TRUE, collapsible = TRUE,
                                         fileInput(inputId = "scrape_data_fileinput",
                                                   label = "Please provide the current database:",
                                                   multiple = F),
                                         div(id = "centricbutton",
                                             actionButton("scrape_data_startscraping", "Load Autoscout DB",
                                                          style="color: #FFFFFF; background-color:  #24a0ed; border-color:  #24a0ed")
                                         )
                                     ),
                                     uiOutput("scrape_data_infos"),
                                     uiOutput("scrape_data_generateDB")
                                  ),
                              column(8,
                                      # h2("Output table of the Scrapped Datatable:"),
                                      DT::dataTableOutput("scrape_data_scrappeddata_table")
                                  )
                            )

                    ),
                    ############################################################################
                    #########                   Analyse Data                      ##############
                    ############################################################################
                    tabItem(tabName = "Data_analysis",
                            h1("How it works"),
                            helpText("Need still to be done:")

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

