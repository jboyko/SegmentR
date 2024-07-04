#' @importFrom imager load.image
#' @importFrom jsonlite fromJSON
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
#' @param mask_format Character string. Format of the mask files. Either "image" or "binary".
#'
#' @return A list containing the original image, segmentation results, and masks.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- load_segmentation_results(
#'   image_path = "path/to/image.jpg",
#'   json_path = "path/to/results.json",
#'   mask_format = "image"
#' )
#' }
load_segmentation_results <- function(image_path, json_path, mask_format = "image") {
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
