library(RSelenium)
library(tidyverse)
library(roxygen2)
library(openxlsx)

source("Port_finding_helperfunction.R")

# Extract the script information of each page:
extract_script_frompage <- function(remote_driver, page_nmbr){
  # Loop through all found script elements and extract the JSON content
  for (script_element in remote_driver) {
    json_text <- script_element$getElementAttribute("textContent")[[1]]

    # Since we are looking for a specific script, we can check if the text includes a unique part of the JSON structure
    if (grepl('"@type": "ItemList"', json_text)) {
      json_ld <- jsonlite::fromJSON(json_text)

      # Extract the car-information:
      element <- paste0(page_nmbr, ".", json_ld$itemListElement$position)  # --> Eventuell muss das noch geändert werden!
      car_names <- json_ld$itemListElement$item$name
      car_prices <- as.numeric(json_ld$itemListElement$item$offers$price)
      car_registered_date <- json_ld$itemListElement$item$dateVehicleFirstRegistered
      car_km <- json_ld$itemListElement$item$mileageFromOdometer$value
      car_PS <- json_ld$itemListElement$item$vehicleEngine$enginePower$value
      car_configuration <- json_ld$itemListElement$item$vehicleTransmission
      car_fuelType <- json_ld$itemListElement$item$fuelType
      car_adresse <- json_ld$itemListElement$item$offers$seller$address

      car_temp_df <- as.data.frame(cbind(element, car_names, car_prices, car_registered_date,
                                         car_km, car_PS, car_configuration,
                                         car_fuelType, car_adresse))
      print(car_temp_df)
      return(car_temp_df)
    }
  }
  # In case no remote_driver element had a Itemlist --> We return NULL
  return(NULL)
}

# Function to extract the total number of pages
get_total_pages <- function(driver) {
  # Find all the page number buttons
  page_buttons <- driver$findElements(using = "css selector", "ul.pagination li.page-item button.page-link")
  # Extract the numbers from the buttons
  page_numbers <- sapply(page_buttons, function(x) x$getElementText())
  # The last button before "..." or the last button if "..." is not present
  last_button_text <- tail(page_numbers[page_numbers != "..."], 1)
  return(as.numeric(last_button_text))
}

# Use try-catch to ensure server is closed even if error occurs
tryCatch({
  #driver <- start_rs_driver()
  # Determine the right Server-Port:
  port <- find_free_port()
  print(paste0("I am using Port: ", port))

  # Create the Selenium Server and navigate to the desired place:
  driver <- rsDriver(port = port, browser = "firefox")
  remote_driver <- driver[["client"]]

  # Navigate to the website
  remote_driver$navigate('https://www.autoscout24.ch/de/autos/alle-marken?vehtyp=10')


  # From here on --> Create a new function:

  script_elements <- remote_driver$findElements(using = 'xpath', "//script[@type='application/ld+json']")

  # Start with the first page:
  current_page <- 1
  total_pages <- get_total_pages(driver = remote_driver)

  # Create a dummy DF to save the data into it:
  res_df <- as.data.frame(matrix(rep(NA, 9), ncol = 9))
  colnames(res_df) <- c("element", "car_names", "car_prices", "car_registered_date",
                        "car_km", "car_PS", "car_configuration", "car_fuelType",
                        "car_adresse")

  # As long as we are not on the last page we do the following
  while(current_page <= total_pages){
    page_data <- extract_script_frompage(script_elements, current_page)
    res_df <- rbind(res_df, page_data)

    #Move to the next page:
    current_page <- current_page + 1
    if (current_page > total_pages) {
      break
    }

    # Find the button for the next page and click it
    next_page_button <- remote_driver$findElement(using = "xpath",
      paste0("//button[@type='button' and contains(@class,'page-link') and text()='", current_page, "']"))
    next_page_button$clickElement()


    # Wait for the next page to load
    Sys.sleep(10) # Adjust sleep time as necessary
    print(paste0("I did extract page number ", current_page-1))
  }



  # # Loop through all found script elements and extract the JSON content
  # for (script_element in script_elements) {
  #   json_text <- script_element$getElementAttribute("textContent")[[1]]
  #
  #   # Since we are looking for a specific script, we can check if the text includes a unique part of the JSON structure
  #   if (grepl('"@type": "ItemList"', json_text)) {
  #     json_ld <- jsonlite::fromJSON(json_text)
  #
  #     # Extract the car-information:
  #     element <- json_ld$itemListElement$position  # --> Eventuell muss das noch geändert werden!
  #     car_names <- json_ld$itemListElement$item$name
  #     car_prices <- as.numeric(json_ld$itemListElement$item$offers$price)
  #     car_registered_date <- json_ld$itemListElement$item$dateVehicleFirstRegistered
  #     car_km <- json_ld$itemListElement$item$mileageFromOdometer$value
  #     car_PS <- json_ld$itemListElement$item$vehicleEngine$enginePower$value
  #     car_configuration <- json_ld$itemListElement$item$vehicleTransmission
  #     car_fuelType <- json_ld$itemListElement$item$fuelType
  #     car_adresse <- json_ld$itemListElement$item$offers$seller$address
  #
  #     car_temp_df <- as.data.frame(cbind(element, car_names, car_prices, car_registered_date,
  #                                        car_km, car_PS, car_configuration,
  #                                        car_fuelType, car_adresse))
  #
  #
  #
  #     # Do something with the json_ld object, like extracting car names
  #     # car_names <- sapply(json_ld$itemListElement, function(x) x$item$name)
  #     # Print car names
  #     print(car_names)
  #     break # Exit the loop if we've found the right script element
  #   }
  # }

  # Parse the JSON content
  json_ld <- jsonlite::fromJSON(json_ld_text)

  # Now you can access the data like a regular list in R
  # For example, to get all the car names
  car_names <- sapply(json_ld$itemListElement, function(x) x$item$name)

  # ----------------------------------------------------------------------------#

  # # Find car items by class name or other identifier
  # car_elements <- remote_driver$findElements(using = 'css selector', value = '.vehicle-card .vehicle-info')
  # # Initialize a data frame to store the scraped data
  # car_data <- tibble(name = character(), price = numeric())
  #
  # for(car_element in car_elements){
  #   # Extract car name and price, or other details as needed
  #   name <- car_element$findElement(using = 'css selector', value = '.mr-auto, .mx-auto')$getElementText()[[1]]
  #   #name <- car_element$findElement(using = 'css selector', value = 'div.d-flex.mr-auto.font-weight-bold.text')$getElementText()[[1]]
  #   description <- car_element$findElement(using = "css selector", value = "article.vehicle-card:nth-child(1) > div:nth-child(3) > div:nth-child(2) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1)")$getElementText()[[1]]
  #   # PROBLEM: --> I GET ONLY THE WHOLE NAME, NOT THE ELEMENT ITSELF AS IT IS IN A REPEATING ELEMENT....
  #   tech_spec <- car_element$findElement(using = "css selector", value = "span.vehicle-tech-spec")$getElementText()[[1]]
  #   price <- car_element$findElement(using = 'css selector', value = '.class-for-car-price')$getElementText()[[1]]
  #
  #
  #   # This will print the HTML of the car_element, which can help you debug your selectors.
  #   html <- car_element$getElementAttribute("outerHTML")[[1]]
  #   print(html)
  #
  #
  #   # Add the data to the data frame
  #   car_data <- bind_rows(car_data, tibble(name = name, price = price))
  # }


  # At the very end, we stop the server, so that it is not blocking the port:
  remote_driver$close()
  driver$server$stop()
}, error = function(e) {
  # This block handles the error
  cat("An error has occurred:\n", e$message, "\n")
}, finally = {
  # This block runs regardless of whether an error occurred
  if (exists("driver")) {
    driver$server$stop()
  }
})


# Save the result:
wb <- createWorkbook()
addWorksheet(wb, "data")
writeData(wb, "data", final_result)
saveWorkbook(wb, "09-13-2023_autoscout24", overwrite = T)

#------------------------------------------------------------------------------#

# Starting the Selenium server and browser
## by deleting the "port = XXXX" piece you'll open directly a port
driver <- rsDriver(browser = "firefox")
remote_driver <- driver[["client"]]

# Navigate to the website
remote_driver$navigate('https://www.autoscout24.ch/de/autos/alle-marken?vehtyp=10')






# Free up the port, so that if you rerun it you will be able to use the same Port again!
remote_driver$close()
rm(driver)
gc(driver)


