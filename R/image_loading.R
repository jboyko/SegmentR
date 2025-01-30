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
        mask = lapply(results$mask, t),
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

#' Create summary table of segmentation results
#'
#' This function takes loaded segmentation results and creates a summary table
#' showing key information about the masks, scores, and file locations.
#'
#' @param results List. Output from load_segmentation_results function.
#' @param include_paths Logical. Whether to include full file paths in the table (default: TRUE).
#'
#' @return A data.frame containing the summary information.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- load_segmentation_results("path/to/image.jpg")
#' summary_table <- create_segmentation_table(results)
#' }
create_segmentation_table <- function(results, include_paths = TRUE) {
  # Handle single result case
  if (!is.null(results$paths)) {
    results <- list(single_result = results)
  }
  
  # Remove summary element if present
  results <- results[names(results) != "summary"]
  
  # Initialize lists to store data
  image_names <- character()
  mask_ids <- integer()
  labels <- character()
  scores <- numeric()
  box_coords <- character()
  mask_dims <- character()
  image_paths <- character()
  json_paths <- character()
  
  # Process each result
  for (img_name in names(results)) {
    result <- results[[img_name]]
    if (!is.null(result)) {
      # Get number of masks for this image
      n_masks <- length(result$mask)
      
      # Add data for each mask
      for (i in seq_len(n_masks)) {
        image_names <- c(image_names, img_name)
        mask_ids <- c(mask_ids, i)
        labels <- c(labels, result$label[i])
        scores <- c(scores, result$score[i])
        
        # Format box coordinates
        box <- unlist(result$box[i,])
        box_coords <- c(box_coords, 
          sprintf("xmin=%d, ymin=%d, xmax=%d, ymax=%d", 
            box[1], box[2], box[3], box[4]))
        
        # Get mask dimensions
        mask_dim <- dim(result$mask[[i]])
        mask_dims <- c(mask_dims,
          sprintf("%d x %d", mask_dim[1], mask_dim[2]))
        
        # Add file paths
        image_paths <- c(image_paths, result$paths$image)
        json_paths <- c(json_paths, result$paths$json)
      }
    }
  }
  
  # Create data frame
  df <- data.frame(
    image_name = image_names,
    mask_id = mask_ids,
    label = labels,
    score = round(scores, 3),
    box_coordinates = box_coords,
    mask_dimensions = mask_dims,
    stringsAsFactors = FALSE
  )
  
  # Add paths if requested
  if (include_paths) {
    df$image_path <- image_paths
    df$json_path <- json_paths
  }
  
  return(df)
}

#' Load the SegmentR example dataset
#'
#' @return A list containing the example images, their file paths, and photographer credits.
#' @export
load_segmentr_example_data <- function() {
  
  image_paths_1 <- list.files(
    system.file("extdata", "images", "other_images", package = "SegmentR"),
    full.names = TRUE
  )
  image_paths_1 <- image_paths_1[grep("Bream", image_paths_1)]
  
  image_paths_2 <- list.files(
    system.file("extdata", package = "SegmentR"),
    full.names = TRUE
  )
  image_paths_2 <- image_paths_2[grep("images", image_paths_2)]
  
  photographer_credits <- c(
    "Horned Bream" = "https://www.inaturalist.org/observations/227272077",
    "Lesser Fringed Gentian" = "https://www.inaturalist.org/observations/249435672",
    "Flat-topped Goldenrod" = "https://www.inaturalist.org/observations/243695619",
    "Calico Aster" = "https://www.inaturalist.org/observations/242477360",
    "Black-eyed Susan" = "https://www.inaturalist.org/observations/243146103"
    # Add more credits here
  )
  return(list(
    image_paths_1 = image_paths_1,
    image_paths_2 = image_paths_2,
    photographer_credits = photographer_credits
  ))
}
