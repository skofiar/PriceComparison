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
