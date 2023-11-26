library(RSelenium)
library(tidyverse)
library(roxygen2)
library(openxlsx)
library(jsonlite)
library(future)
library(furrr)
library(promises)
library(parallel)
library(readxl)

source("R/Port_finding_helperfunction.R")
source("R/Page_Information.R")
source("R/Extract_Data.R")
source("R/Adding_to_Database.R")
source("R/Prepare_Scrapped_Data.R")

# Measure the starting time:
start_time <- Sys.time()

# Determine the right Server-Port:
port <- find_free_port()
print(paste0("I am using Port: ", port))

# Create the Selenium Server and navigate to the desired place:
driver <- rsDriver(port = port, browser = "firefox")
remote_driver <- driver[["client"]]

# Precompile the regex pattern
item_list_pattern <- '"@type": "ItemList"'

numCores <- detectCores()
plan(multisession, workers = max(numCores-2,1))  # Adjust the number of workers based on your machine
# Loop to initiate scraping in parallel
# total_pages <- get_total_pages(driver = remote_driver)
total_pages <- 1500

# # Initialize a result data frame:
# final_result <- as.data.frame(matrix(rep(NA, 9), ncol = 9))
# colnames(final_result) <- c("element", "car_names", "car_prices", "car_registered_date",
#                             "car_km", "car_PS", "car_configuration", "car_fuelType", "car_adresse" )

results <- list()
# Scrape the data:
for (i in 1:total_pages) {
  results[[i]] <- process_page(page_number = i)
}

# # Initiate scraping in parallel and collect the results
# results <- future_map(1:total_pages, process_page)
#
# Combine all the dataframes into one
final_result <- do.call(rbind, results)

# Stopping the end time and calculting the duration of the tool up until here:
end_time <- Sys.time()
duration <- end_time - start_time
print(paste0("The tool took ", duration, "hours/minuts/seconds for the whole scraping!"))

# Print the final combined dataframe
print("All pages have been processed.")
View(final_result)

# Prepare the final_result:
autoscout_db <- adding_to_database(scrapped_dataframe = final_result)

# Free up the port, so that if you rerun it you will be able to use the same Port again!
remote_driver$close()
# rm(driver)
# gc(driver)


# Prepare the data:
# XXX 1. Need to add the current date:
# XXX 2. Extract Automarke und Auto Modell --> Finde guten weg hierfür!
# 3. Add the link to the element
# 4. Karte erstellen mit den Postleitzahlen
# XXX 5. Automarke erstellen indem weitere Spalten hinzugefügt werden und dann immer weiter für das nächste Element gefiltert wird
# XXX 6. Zeit messen wie lange das es braucht um die Daten zu generieren

# # Make a save copy:
# crnt_data_set <- as.data.frame(final_result)
# # Prepare the data:
# crnt_data_set <- crnt_data_set %>%
#   mutate(Datum = Sys.Date(),
#          Marke = substr(car_names, 1, regexpr(" ", car_names)),
#          Typ_1_details = substr(car_names, regexpr(" ", car_names) + 1, nchar(car_names)),
#          Typ_2_details = substr(Typ_1_details, regexpr(" ", Typ_1_details) + 1, nchar(Typ_1_details)),
#          Typ = paste0(substr(Typ_1_details, 1, regexpr(" ", Typ_1_details)), "",
#                       substr(Typ_2_details, 1, regexpr(" ", Typ_2_details)))
#          ) %>%
#   select(-c(Typ_1_details, Typ_2_details))

# readxl::read_xlsx(path = paste0(getwd(),"/Output/2023-11-13_autoscout24_raw_data.xlsx"))
# # library(openxlsx)
# # wb <- loadWorkbook("../Output/2023-11-13_autoscout24_raw_data.xlsx")
# final_result <- as.data.frame(read_excel(paste0(getwd(), "/Output/2023-11-13_autoscout24_raw_data")))
# final_result <- read_excel(path = "./Output/2023-11-13_autoscout24_raw_data.xlsx")
#
# sapply(final_result$car_names, function(x){
#   return(c(strsplit(x," ")[[1]][1:2]))
# })
