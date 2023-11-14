library(RSelenium)
library(tidyverse)
library(roxygen2)
library(openxlsx)
library(jsonlite)
library(future)
library(furrr)
library(promises)
library(parallel)

source("R/Port_finding_helperfunction.R")
source("R/Page_Information.R")
source("R/Extract_Data.R")


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

# List to store future objects
page_futures <- list()

# Loop to initiate scraping in parallel
total_pages <- 150 # Replace with actual total page count
# print(total_pages)
for (page_number in 1:total_pages) {
  page_futures[[page_number]] <- future({
    process_page(page_number)
  })
}

# Initiate scraping in parallel and collect the results
results <- future_map(1:total_pages, process_page)

# Combine all the dataframes into one
final_result <- do.call(rbind, results)

# Print the final combined dataframe
print("All pages have been processed.")
print(final_result)

# Export data to Excel
export_scrapped_data(data_to_export = final_result)

# Prepare the data:
# 1. Need to add the current date:
# 2. Extract Automarke und Auto Modell --> Finde guten weg hierfür!
# 3. Add the link to the element
# 4. Karte erstellen mit den Postleitzahlen
# 5. Automarke erstellen indem weitere Spalten hinzugefügt werden und dann immer weiter für das nächste Element gefiltert wird
# 6. Zeit messen wie lange das es braucht um die Daten zu generieren

# Make a save copy:
crnt_data_set <- as.data.frame(final_result)
# Prepare the data:
crnt_data_set <- crnt_data_set %>%
  mutate(Datum = Sys.Date(),
         Marke = substr(car_names, 1, regexpr(" ", car_names)))
