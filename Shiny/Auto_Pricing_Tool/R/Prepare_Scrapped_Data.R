#' @title Prepares Scrapped Data Frame
#'
#' This function prepares scrapped data frame to pricing tools standardized format,
#' whereby we add the following columns:
#'  - Datum           --> First time the car was online
#'  - Datum_end       --> First date where the car is not online anymore
#'  - Marke
#'  - Typ
#'  - Status          --> If the car is still online or not
#'  - VerkauftIn      --> Tells us how long the car was online (F if not selled,
#'                        number of days otherwise)
#'
#'  It is important to note here, that the data frame is only prepared here and
#'  not completely populized!
#'
#' @param df_to_prep Data frame that needs to be brought to the standardized format.
#' @return prepared_df, Data frame which is prepared to the desired form.
#' @import dplyr
#' @export
prepare_scrapped_data <- function(df_to_prep){
  # Extract the colnames
  colnames_df <- colnames(df_to_prep)

  # Prepare the df
  prepared_df <- df_to_prep %>%
    select(-element) %>%
    unique() %>%
    mutate(Datum = Sys.Date(),
           Registriertes_Jahr = case_when(
             car_registered_date == "Neues Fahrzeug" ~ as.numeric(substr(Sys.Date(),1,4)),
             car_registered_date == "Vorführmodell" ~ as.numeric(substr(Sys.Date(),1,4)),
             car_registered_date == "Tageszulassung" ~ as.numeric(substr(Sys.Date(),1,4)),
             TRUE ~ as.numeric(substr(car_registered_date, 4, 7))
           ),
           Marke = substr(car_names, 1, regexpr(" ", car_names)),
           Typ_1_details = substr(car_names, regexpr(" ", car_names) + 1, nchar(car_names)),
           Typ_2_details = substr(Typ_1_details, regexpr(" ", Typ_1_details) + 1, nchar(Typ_1_details)),
           Typ_grob = substr(Typ_1_details, 1, regexpr(" ", Typ_1_details)),
           Typ = paste0(substr(Typ_1_details, 1, regexpr(" ", Typ_1_details)), "",
                        substr(Typ_2_details, 1, regexpr(" ", Typ_2_details))),
           Status = NA,
           VerkauftIn = F,
           element = row_number()
    ) %>%
    select(-c(Typ_1_details, Typ_2_details)) %>%
    select("element", everything())

  return(prepared_df)
}
