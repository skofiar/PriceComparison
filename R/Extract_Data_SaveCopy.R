# Extract the script information of each page:
extract_script_frompage <- function(remote_driver, page_nmbr){
  # Loop through all found script elements and extract the JSON content
  script_elements <- remote_driver$findElements(using = 'xpath', value = "//script[@type='application/ld+json']")
  extracted_data <- vector("list", length = length(script_elements))  # Create a list to hold extracted data

  # Loop through all found script elements and extract the JSON content
  for (i in seq_along(script_elements)) {
    script_element <- script_elements[[i]]
    json_text <- script_element$getElementAttribute("textContent")[[1]]

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
      #return(car_temp_df)
      extracted_data[[i]] <- car_temp_df
    }
  }

  if (length(extracted_data) == 0) {
    return(NULL)  # In case no matching script element was found
  } else {
    do.call(rbind, extracted_data)  # Combine all data frames into one
  }
}


# Function to extract data from a page
extract_data_from_page <- function(page_number) {
  remote_driver$navigate(paste0('https://www.autoscout24.ch/de/autos/alle-marken?vehtyp=10&page=', page_number))
  Sys.sleep(1)  # Wait for the page to load
  extract_script_frompage(remote_driver, page_number)
}

# Function to process a single page
process_page <- function(page_number) {
  tryCatch({
    extract_data_from_page(page_number)
  }, error = function(e) {
    message("Error in process_page with page number ", page_number, ": ", e$message)
    return(NULL)  # Return NULL if there was an error
  })
}
