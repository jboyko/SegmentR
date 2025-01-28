#' Load an image file
#'
#' This function loads an image file and returns it as an array.
#'
#' @param image_path Character string. Path to the input image file.
#'
#' @return A 3D array representing the image (height x width x color channels).
#' @export
#'
#' @examples
#' \dontrun{
#' img <- load_image("path/to/image.jpg")
#' }
load_image <- function(image_path) {
  if (requireNamespace("imager", quietly = TRUE)) {
    img <- imager::load.image(image_path)
    return(as.array(img))
  } else {
    stop("imager package not available. Please install it or provide an alternative method.")
  }
}

#' Load segmentation results
#'
#' This function loads the original image, JSON results, and corresponding masks
#' from a previous segmentation operation.
#'
#' @param image_path Character string. Path to the original image file.
#' @param json_path Character string. Path to the JSON file containing segmentation results.
#'
#' @return A list containing the original image, segmentation results, and masks.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- load_segmentation_results(
#'   image_path = "path/to/image.jpg",
#'   json_path = "path/to/results.json",
#' )
#' }
load_segmentation_results <- function(image_path, json_path) {
  # Load image
  image <- load_image(image_path)

  # Load JSON results
  results <- jsonlite::fromJSON(json_path)

  # Return a list with all components
  list(
    image = image,
    label = results$label,
    score = results$score,
    box = results$box,
    mask = results$mask
  )
}


#' Load the SegmentR example dataset
#'
#' @return A list containing the example images, their file paths, and photographer credits.
#' @export
load_segmentr_example_data <- function() {
  image_paths <- list.files(
    system.file("extdata", "images", package = "SegmentR"),
    full.names = TRUE
  )
  image_list <- lapply(image_paths, imager::load.image)
  photographer_credits <- c(
    "Andaman Hind" = "Observation by fishhead (CC0) - https://www.inaturalist.org/observations/226199473",
    "American Bumble Bee" = "Observation by Mary Spolyar (CC BY-NC) - https://www.inaturalist.org/observations/100024260",
    "Horned Bream" = "Observation by Michael Bommerer (CC BY) - https://www.inaturalist.org/observations/227272077"
    # Add more credits here
  )
  return(list(
    images = image_list,
    image_paths = image_paths,
    photographer_credits = photographer_credits
  ))
}
