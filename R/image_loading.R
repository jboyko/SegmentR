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
    stop("imager package not available. Please install it.")
  }
}

#' Load segmentation results
#'
#' This function loads the original image(s), JSON results, and corresponding masks
#' from previous segmentation operations. It can handle both single files and directories.
#'
#' @param path Character string. Path to original image file or directory containing images.
#' @param json_path Character string. Optional path to JSON file or directory. If NULL,
#'   will look in "json" subdirectory of image path.
#' @param pattern Character string. File pattern to match when path is a directory (default: "\\.(jpg|jpeg|png)$").
#' @param recursive Boolean. Whether to search for images recursively in subdirectories (default: FALSE).
#'
#' @return For single files: A list containing the original image, segmentation results, and masks.
#'         For directories: A list of results for each image plus summary information.
#' @export
#'
#' @examples
#' \dontrun{
#' # Load single image results
#' results <- load_segmentation_results(
#'   path = "path/to/image.jpg",
#'   json_path = "path/to/results.json"
#' )
#'
#' # Load all results from a directory
#' results <- load_segmentation_results(
#'   path = "path/to/image/directory",
#'   recursive = TRUE
#' )
#' }
load_segmentation_results <- function(path,
  json_path = NULL,
  pattern = "\\.(jpg|jpeg|png)$",
  recursive = FALSE) {
  
  # Get expected paths
  paths <- get_segmentation_paths(
    path = path,
    output_json = json_path,
    pattern = pattern,
    recursive = recursive
  )
  
  # Helper function to load a single result
  load_single_result <- function(image_path, json_path) {
    # Check if files exist
    if (!file.exists(image_path)) {
      warning("Image file not found: ", image_path)
      return(NULL)
    }
    if (!file.exists(json_path)) {
      warning("JSON file not found: ", json_path)
      return(NULL)
    }
    
    tryCatch({
      # Load image
      image <- load_image(image_path)
      # Load JSON results
      results <- jsonlite::fromJSON(json_path)
      # Return combined results
      list(
        image = image,
        label = results$label,
        score = results$score,
        box = results$box,
        mask = results$mask,
        paths = list(
          image = image_path,
          json = json_path
        )
      )
    }, error = function(e) {
      warning("Error loading results for ", image_path, ": ", e$message)
      NULL
    })
  }
  
  # Handle directory case
  if (is.list(paths) && !is.null(paths$summary)) {
    # Initialize results list
    results <- list()
    
    # Process each image
    for (img_name in names(paths)) {
      if (img_name != "summary") {
        results[[img_name]] <- load_single_result(
          paths[[img_name]]$image_path,
          paths[[img_name]]$json_path
        )
      }
    }
    
    # Add summary information
    results$summary <- list(
      total_images = paths$summary$total_images,
      loaded_images = sum(!sapply(results[names(results) != "summary"], is.null)),
      source_directory = paths$summary$source_directory,
      failed_loads = names(which(sapply(results[names(results) != "summary"], is.null)))
    )
    
    return(results)
    
  } else {
    # Handle single image case
    return(load_single_result(paths$image_path, paths$json_path))
  }
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
