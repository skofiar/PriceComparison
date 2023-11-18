#' @title Adding Scrapped Data to Database
#'
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
adding_to_database <- function(scrapped_dataframe){
  library(dplyr)
  library(data.table)
  library(digest)

  # Create a copy of the scrapped data frame:
  new_df <- scrapped_dataframe

  # Check whether the data base file is already present in the Output folder:
  if (!any(grepl("Autoscout_Database",list.files("./Output/")))) {
      autoscout_data_base <- as.data.frame(prepare_scrapped_data(new_df))

      # Since the most actual data is uploaded to the database (and there was no data before)
      ## the "Status" is Active = T
      autoscout_data_base$Status = T
      # VerkauftIn is not going to be changed, as all of them is still online available

      # Save the data frames to Output:
      data.table::fwrite(autoscout_data_base,
                         paste0("./Output/", Sys.Date(), "_autoscout24_raw_data.csv"), row.names = T)
      data.table::fwrite(autoscout_data_base,
                         "./Output/Autoscout_Database.csv", row.names = T)
  }else{
    # Prepare the scrapped data:
    new_df_prepared <- as.data.table(prepare_scrapped_data(new_df))
    # Save the data frames to Output:
    data.table::fwrite(autoscout_data_base,
                       paste0("./Output/", Sys.Date(), "_autoscout24_raw_data.csv"), row.names = T)

    # Load the auto data base:
    autoscout_db <- data.table::fread(input = "./Output/Autoscout_Database.csv")

    # If the any element is "V1", we want to delete it, as it is an empty column
    if (colnames(autoscout_db)[1] == "V1") {
      set(autoscout_db, j = which(colnames(autoscout_db) == "V1"), value = NULL)
    }

    #### Check which elements were already yesterday online:
    # Create a hash for each row instead of pasting
    autoscout_db[, unique_id := paste(car_names, car_registered_date, car_km, car_PS, car_adresse, sep = "_")]
    new_df_prepared[, unique_id := paste(car_names, car_registered_date, car_km, car_PS, car_adresse, sep = "_")]

    # Then proceed with the binary search as before
    autoscout_db[, Status := unique_id %in% new_df_prepared$unique_id]

    ##### THE CLASSIFICATION IS NOT CORRECT IF A CAR IS SOLD OR NOT!!

    # If the Status is False (meaning the car was not online )
    autoscout_db[Status == F & VerkauftIn == F, VerkauftIn := T]

    ##### HERE NEEDS TO BE FURTHER CODE!!!

    # Export Result as new Autoscout DB:
    data.table::fwrite(autoscout_data_base,
                       "./Output/Autoscout_Database.csv", row.names = T)

  }
}
