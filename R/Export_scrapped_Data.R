# Creating workingbook and export the data:
export_scrapped_data <- function(data_to_export){
  # Change working dir to the output dir:
  crnt_workingdir <- getwd()
  setwd(paste0(crnt_workingdir, "/Output/"))

  # Create a working book and export the data:
  wb <- createWorkbook()
  addWorksheet(wb, "data")
  writeData(wb, "data", data_to_export)
  saveWorkbook(wb, paste0(Sys.Date(),"_autoscout24_raw_data"), overwrite = T)

  # Change the data back to the original workingdir:
  setwd(crnt_workingdir)
}
