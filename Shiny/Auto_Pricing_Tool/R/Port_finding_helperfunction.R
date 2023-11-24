#' Add together two numbers
#'
#' @return First free port to use in order to initialize the Selenium Server.
#' @examples
#' find_free_port()
find_free_port <- function(start = 4567L, end = 5000L) {
  for (port in start:end) {
    if (!is_port_in_use(port)) {
      return(port)
    }
  }
  stop("No free ports found.")
}

#' Function to check if port is in use
#'
#' @param port An integer that denotes the port that one wants to use to initialize
#' the Selenium Server.
#' @return TRUE or FALSE, which denotes if the port is in use or not.
#' @examples
#' is_port_in_use(port = 4567L)
is_port_in_use <- function(port) {
  # Try to open a connection to the port
  con <- try(suppressWarnings(socketConnection("localhost", port = port, open = "r+")), silent = TRUE)
  if (inherits(con, "try-error")) {
    return(FALSE)
  }
  close(con)
  return(TRUE)
}



#------------------------------------------------------------------------------#
# Function to start RSelenium safely
#start_rs_driver <- function(port = 4567L) {
#  if (is_port_in_use(port)) {
#    warning(paste("Port", port, "is already in use. Trying to close existing server."))
#  }
#  print("I am here")
#  print(port)

#  driver <- rsDriver(port = port, browser = "firefox")
#  return(driver)
#}
