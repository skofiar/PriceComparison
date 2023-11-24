# Function to wait for the scripts to be present on the page
# wait_for_scripts_to_load <- function(remote_driver, timeout = 10) {
#   # Wait up to `timeout` seconds for at least one script element to be present
#   for (i in 1:timeout) {
#     script_elements <- remote_driver$findElements(using = 'xpath', value = "//script[@type='application/ld+json']")
#     if (length(script_elements) > 0) return(TRUE)
#     Sys.sleep(1) # Wait for 1 second before trying again
#   }
#   FALSE # Return FALSE if the script elements never appeared
# }
wait_for_element <- function(remote_driver, xpath, timeout = 10) {
  for (i in 1:timeout) {
    elements <- tryCatch({
      remote_driver$findElements(using = 'xpath', value = xpath)
    }, error = function(e) {
      return(NULL)
    })
    if (length(elements) > 0) {
      # Check if the element has a 'style' attribute that implies it's not displayed
      style_attr <- elements[[1]]$getElementAttribute("style")[[1]]
      if (!grepl("display: none", style_attr, fixed = TRUE)) {
        return(TRUE)
      }
    }
    Sys.sleep(2)
  }
  return(FALSE)
}


# Extract the script information of each page:
extract_script_frompage <- function(remote_driver, page_nmbr){

  # Wait for the script elements to load
  # if (!wait_for_scripts_to_load(remote_driver)) {
  #   message(paste("Scripts did not load after waiting on page", page_nmbr))
  #   return(NULL)
  # }

  if (!wait_for_element(remote_driver, xpath = "//script[@type='application/ld+json']")) {
    message(paste("Scripts did not load after waiting on page", page_nmbr))
    return(NULL)
  }

  # Loop through all found script elements and extract the JSON content
  script_elements <- remote_driver$findElements(using = 'xpath', value = "//script[@type='application/ld+json']")
  extracted_data <- vector("list", length = length(script_elements))  # Create a list to hold extracted data
  print(page_number)

  # Loop through all found script elements and extract the JSON content
  for (i in seq_along(script_elements)) {
    script_element <- script_elements[[i]]
    json_text <- script_element$getElementAttribute("textContent")[[1]]


    if (grepl('"@type": "ItemList"', json_text)) {
      json_ld <- jsonlite::fromJSON(json_text)

      # Extract the car-information:
      element <-(as.numeric(page_nmbr) - 1 )*20 + as.numeric(json_ld$itemListElement$position)
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
  # Sys.sleep(1)  # Wait for the page to load
  extract_script_frompage(remote_driver, page_number)
}

# Function to process a single page
process_page <- function(page_number) {
  tryCatch({
    return(extract_data_from_page(page_number))
  }, error = function(e) {
    message("Error in process_page with page number ", page_number, ": ", e$message)
    return(NULL)  # Return NULL if there was an error
  })
}
