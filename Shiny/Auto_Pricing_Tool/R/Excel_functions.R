#################################################################################
# Functions - Fileinp/ Read-in Funciton:
#################################################################################
#' Function that loads all the information coming from the Shiny-widget
#' fileInput() into a list and prepares/processes all the respective elements.
#' Using this function, one could also upload multiple files using the named widget
#' and gets a nested list of all the information.
#'
#' @param fileinp Uploaded file information using fileinput() like name, temp. path etc.
#' @param shtnms Excel-Sheet names of the uploaded file/-s
#' @param range.selection Range which should be extracted from Excel. Default is selected NULL, i.e. no selection.
#' @param mltple Are multiple Files uploaded? If yes, TRUE is selected
#'
#' @return List with the following information:
#' - df              = Uploaded data frame
#' - extension       = Ending of the data file (e.g. .xlsx)
#' - filepath        = Temporary file path
#' - fliename        = Complete file name
#'
#' @importFrom tools file_ext
#' @importFrom readr read_csv
#' @importFrom readxl excel_sheets read_xls read_xlsx read_excel
#' @importFrom data.table fread, set
#' @export
fileinp.filereadin <- function(fileinp, shtnms, range.selection, mltple){
  # library(tools)
  # library(readr)
  # library(readxl)
  # library(data.table)

  if (is.null(fileinp)) { return(NULL) }

  if (mltple == F) {
    #Read out the extension of the Paid triangle, in order to read in correctly:
    extension <- tools::file_ext(fileinp$name)
    print(extension)
    #Tells me the path where the file is currently saved on:
    filepath <- fileinp$datapath
    #Tells me the name of the fileinput
    filenm <- fileinp$name

    #Checks how (which function) we want to upload the data
    # We deactivate colnames here, as they are going to be selected by the user later on!
    if (is.null(shtnms)) {
      df <- switch(extension,
                   # csv = readr::read_csv(filepath, col_names = F),
                   csv = data.table::fread(filepath),
                   xls = readxl::read_xls(filepath, col_names = F),
                   xlsx = readxl::read_xlsx(filepath, col_names = F),
                   xlsm = readxl::read_excel(path = filepath, col_names = F))
    }else{
      df <- switch(extension,
                   # csv = readr::read_csv(filepath, col_names = F),
                   csv = data.table::fread(filepath),
                   xls = readxl::read_xls(filepath, sheet = shtnms , range = range.selection, col_names = F),
                   xlsx = readxl::read_xlsx(filepath, sheet = shtnms, range = range.selection, col_names = F),
                   xlsm = readxl::read_excel(path = filepath, sheet = shtnms, range = range.selection, col_names = F))
    }

    # In case csv was selected, we need to check for "V1" columns:
    if ("V1" %in% colnames(df)) {
      data.table::set(df, j = which(colnames(df) == "V1"), value = NULL)
    }

    # Convert datatable to dataframe:
    df <- as.data.frame(df)

    if (extension != "csv") {
      #Naming the columns correctly:
      colnames(df) <- c(paste(1:(dim(df)[2])))

      #Extract sheet names from an excel
      sheet.names <- readxl::excel_sheets(paste(filepath))
    }else{
      sheet.names <- NULL
    }

    return(list(df, extension, filepath, filenm, sheet.names))
  }else{
    #List for the output of multiple Rows:
    outputlist <- list()
    #For each row of fileinp (which represent a file)
    for (i in 1:nrow(fileinp)) {
      #Select the corresponding row:
      fileinp.row <- fileinp[i,]
      #Read out the extension of the Paid triangle, in order to read in correctly:
      extension <- tools::file_ext(fileinp.row$name)
      #Tells me the path where the file is currently saved on:
      filepath <- fileinp.row$datapath
      #Tells me the name of the fileinput
      filenm <- fileinp.row$name

      #Checks how (which function) we want to upload the data
      # We deactivate colnames here, as they are going to be selected by the user later on!
      if (is.null(shtnms)) {
        df <- switch(extension,
                     # csv = readr::read_csv(filepath, col_names = F),
                     csv = data.table::fread(filepath),
                     xls = readxl::read_xls(filepath, col_names = F),
                     xlsx = readxl::read_xlsx(filepath, col_names = F),
                     xlsm = readxl::read_excel(path = filepath, col_names = F))
      }else{
        df <- switch(extension,
                     # csv = readr::read_csv(filepath, col_names = F),
                     csv = data.table::fread(filepath),
                     xls = readxl::read_xls(filepath, sheet = shtnms , range = range.selection, col_names = F),
                     xlsx = readxl::read_xlsx(filepath, sheet = shtnms, range = range.selection, col_names = F),
                     xlsm = readxl::read_excel(path = filepath, sheet = shtnms, range = range.selection, col_names = F))
      }

      # In case csv was selected, we need to check for "V1" columns:
      if ("V1" %in% colnames(df)) {
        data.table::set(df, j = which(colnames(df) == "V1"), value = NULL)
      }

      if (extension != "csv") {
        #Naming the columns correctly:
        colnames(df) <- c(paste(1:(dim(df)[2])))

        #Extract sheet names from an excel
        sheet.names <- readxl::excel_sheets(paste(filepath))
      }else{
        sheet.names <- NULL
      }

      #Append the row as an listelement in form of a list:
      outputlist[[i]] <- list(df, extension, filepath, filenm, sheet.names)
    }

    return(outputlist)
  }

}
