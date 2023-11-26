#' @title Adding Scrapped Data to Database
#'
#' @description
#' This function will take as an input the newly scrapped data frame and append
#' the new cars rows to the DB.
#' Further, it should classify which cars are still online and which one are
#' already sold
#'
#' @param scrapped_dataframe Today's scrapped data frame.
#' @return autoscout_data_base, data frame including the past information.
#' @import dplyr
#' @import data.table
#' @import digest
#' @export
adding_to_database <- function(scrapped_dataframe, autoscout_db){
  library(dplyr)
  library(data.table)
  library(digest)

  # If the data in autoscout_db is given as data.table, then we convert it:
  if (is.data.table(autoscout_db) == F) {
    autoscout_db <- as.data.table(autoscout_db)
  }

  print(is.data.table(autoscout_db))

  # Prepare the scrapped data:
  new_df_prepared <- as.data.table(prepare_scrapped_data(scrapped_dataframe))
  print(is.data.table(new_df_prepared))
  # If the any element is "V1", we want to delete it, as it is an empty column
  if ("V1" %in% colnames(autoscout_db)) {
    set(autoscout_db, j = which(colnames(autoscout_db) == "V1"), value = NULL)
  }
  if ("V1" %in% colnames(new_df_prepared)) {
    set(new_df_prepared, j = which(colnames(new_df_prepared) == "V1"), value = NULL)
  }

  #### Check which elements were already yesterday online:
  # Create a hash for each row instead of pasting
  autoscout_db[, unique_id := paste(car_names, car_registered_date, car_km, car_PS, car_adresse, sep = "_")]
  new_df_prepared[, unique_id := paste(car_names, car_registered_date, car_km, car_PS, car_adresse, sep = "_")]

  # Then proceed with the binary search as before
  autoscout_db[, Status := unique_id %in% new_df_prepared$unique_id]
  # All of the cars in these rows are online now (as it is taken from the actual day)
  new_df_prepared$Status <- T

  ##### THE CLASSIFICATION IS NOT CORRECT IF A CAR IS SOLD OR NOT!!

  # If the Status is False (meaning the car was not online )
  autoscout_db[Status == F & VerkauftIn == F, VerkauftIn := T]

  ##### HERE NEEDS TO BE FURTHER CODE!!!

  # Find data rows, that are not represented in the DB:
  unique_new_data <- new_df_prepared[!autoscout_db, on = .(unique_id)]

  # Fixing wrong data types:
  unique_new_data$Datum <- as.Date(unique_new_data$Datum)
  autoscout_db$Datum <- as.Date(autoscout_db$Datum)

  # Append the new data to the autoscout_db:
  autoscout_db <- rbind(unique_new_data, autoscout_db)
  # Renumerate element column:
  autoscout_db$element <- 1:(dim(autoscout_db)[1])

  # Export Result as new Autoscout DB:
  data.table::fwrite(autoscout_db,
                     "./Output/Autoscout_Database.csv", row.names = T)
  return(autoscout_db)
}

