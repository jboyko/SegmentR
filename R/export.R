#' Export Segmentation as Transparent PNG
#' @param input Either a seg_results list or image data (cimg object, array, or file path)
#' @param masks Optional list of masks or single mask array (if not provided in seg_results)
#' @param labels Optional vector of labels for each mask
#' @param scores Optional vector of confidence scores
#' @param output_path Character. Path where files should be saved.
#' @param score_threshold Numeric. Threshold for including results (0-1)
#' @param remove_overlap Boolean. Whether to remove any overlapping regions from masks with different labels.
#' @param return_binary Boolean. Whether only a binary mask should be returned.
#' @param crop Boolean. Whether to crop the image to the edges of the segment.
#' @param prefix Character. Prefix for output filenames (default: NULL uses "segment")
#' @param include_score Logical. Whether to include confidence score in filename (default: TRUE)
#' @param id_padding Integer. Number of digits to pad mask IDs with (default: 3)
#'
#' @return Invisibly returns vector of saved file paths.
export_transparent_png <- function(input,
  masks = NULL,
  labels = NULL,
  scores = NULL,
  output_path,
  score_threshold = 0,
  remove_overlap = TRUE,
  return_binary = FALSE,
  crop = FALSE,
  prefix = NULL,
  include_score = FALSE,
  id_padding = 3) {
  
  # Parse input type and extract components
  if (is.list(input) && all(c("image", "mask", "label", "score") %in% names(input))) {
    # Input is seg_results format
    image <- input$image
    masks <- input$mask
    labels <- input$label
    scores <- input$score
    if (is.null(prefix)) prefix <- sub("\\..*$", "",basename(input$paths$image))
  } else {
    # Input is direct image
    image <- input
    # Use provided masks, labels, scores or create defaults
    if (is.null(masks)) stop("Masks must be provided when input is not seg_results")
    if (!is.list(masks)) masks <- list(masks)
    if (is.null(labels)) labels <- seq_along(masks)
    if (is.null(scores)) scores <- rep(1, length(masks))
    if (is.null(prefix)) prefix <- "segment"
  }
  
  # Input validation and conversion for image
  if (is.character(image) && file.exists(image)) {
    image <- imager::load.image(image)
  } else if (!inherits(image, "cimg")) {
    image <- try(imager::as.cimg(image))
    if (inherits(image, "try-error")) {
      stop("Unable to convert input image to cimg format")
    }
  }
  
  # Create output directory if needed
  dir.create(output_path, showWarnings = FALSE, recursive = TRUE)
  labels <- as.factor(labels)
  # Ensure image has alpha channel
  if (dim(image)[4] == 3) {
    # Create alpha channel
    alpha_channel <- imager::imfill(dim = c(dim(image)[1:2], 1, 1), val = 1)
    image <- imager::imappend(imager::imlist(image, alpha_channel), "c")
  } else if (dim(image)[4] == 1) {
    # For grayscale, convert to RGB + alpha
    image_rgb <- imager::add.colour(image)  # Creates RGB
    alpha_channel <- imager::imfill(dim = c(dim(image)[1:2], 1, 1), val = 1)
    image <- imager::imappend(imager::imlist(image_rgb, alpha_channel), "c")
  }
  
  output_files <- character()
  if(remove_overlap){
    all_masks <- list()
    for(i in 1:length(levels(labels))){
      all_masks[[i]] <- imager::imfill(dim = c(dim(image)[1:2], 1, 1), val = 0)
    }
    for (i in seq_along(masks)) {
      if (scores[i] >= score_threshold) {
        # Standardize mask format
        mask <- try(imager::as.cimg(masks[[i]]))
        if (inherits(mask, "try-error")) {
          warning(sprintf("Skipping mask %d - invalid format", i))
          next
        }
        # Ensure mask dimensions match
        if (!all(dim(mask)[1:2] == dim(image)[1:2])) {
          warning(sprintf("Skipping mask %d - dimension mismatch", i))
          next
        }
        
        # Make binary
        mask <- (mask > 0)
        label_idx <- which(labels[i] == levels(labels))
        all_masks[[label_idx]] <- all_masks[[label_idx]] + mask
      }
    }
  }
  
  for (i in seq_along(masks)) {
    if (scores[i] >= score_threshold) {
      # Standardize mask format
      mask <- try(imager::as.cimg(masks[[i]]))
      if (inherits(mask, "try-error")) {
        warning(sprintf("Skipping mask %d - invalid format", i))
        next
      }
      
      # Ensure mask dimensions match
      if (!all(dim(mask)[1:2] == dim(image)[1:2])) {
        warning(sprintf("Skipping mask %d - dimension mismatch", i))
        next
      }
      
      # Make binary
      mask <- (mask > 0)
      if(remove_overlap){
        label_idx <- which(labels[i] == levels(labels))
        tmp_masks <- all_masks[-label_idx]
        if(length(tmp_masks) > 0){
          for(j in 1:length(tmp_masks)){
            mask <- mask > 0 & tmp_masks[[j]] == 0
          }
        }
      }
      
      # Convert to RGB
      mask_rgb <- imager::add.colour(mask)
      # Add alpha channel
      mask_rgba <- imager::imappend(imager::imlist(mask_rgb, mask), "c")
      
      # Copy image data for masked region
      result_img <- image * mask_rgba
      
      # Crop image
      if (crop) {
        # Create pixset from mask for bounding box calculation
        mask_pixset <- as.pixset(mask)
        
        # Crop the result image using imager's crop.bbox
        result_img <- imager::crop.bbox(result_img, mask_pixset)
        
        if (return_binary) {
          mask_rgba <- imager::crop.bbox(mask_rgba, mask_pixset)
        }
      }
      
      # Generate filename components
      mask_id <- sprintf(paste0("%0", id_padding, "d"), i)
      label_part <- ifelse(!is.null(labels), paste0("_", labels[i]), "")
      score_part <- ifelse(include_score, sprintf("_s%.2f", scores[i]), "")
      binary_part <- ifelse(return_binary, "_binary", "")
      
      # Construct full filename
      output_file <- file.path(
        output_path, 
        sprintf("%s_%s%s%s%s.png",
          prefix,
          mask_id,
          label_part,
          score_part,
          binary_part)
      )
      
      # Save the image
      if(!return_binary) {
        imager::save.image(result_img, output_file)
      } else {
        imager::save.image(as.cimg(mask_rgba), output_file)
      }
      
      output_files <- c(output_files, output_file)
    }
  }
  
  return(invisible(output_files))
}

#' Remove mask from segmentation results
#'
#' This function removes a specified mask from segmentation results by its index.
#'
#' @param results List. The segmentation results containing image, labels, scores, boxes, masks, and paths.
#' @param mask_index Integer. The index of the mask to remove.
#'
#' @return List with the same structure as the input, but with the specified mask removed.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- load_segmentation_results("path/to/image.jpg")
#' updated_results <- remove_mask(results, mask_index = 2)
#' }
remove_mask <- function(results, mask_index) {
  # Validate inputs
  if (!is.list(results) || length(results) != 6) {
    stop("Results must be a list with 6 elements (image, label, score, box, mask, paths)")
  }
  if (!is.numeric(mask_index) || mask_index < 1 || mask_index > length(results$mask)) {
    stop("Invalid mask_index. Must be between 1 and ", length(results$mask))
  }
  
  # Create new results list with mask removed
  new_results <- list(
    image = results$image,
    label = results$label[-mask_index],
    score = results$score[-mask_index],
    box = results$box[-mask_index, , drop = FALSE],
    mask = results$mask[-mask_index],
    paths = results$paths
  )
  
  return(new_results)
}