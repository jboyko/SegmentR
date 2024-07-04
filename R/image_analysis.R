#' @importFrom jsonlite fromJSON
#' Combine masks based on a probability threshold
#'
#' This function combines all masks that meet or exceed a specified probability threshold.
#'
#' @param masks List of logical matrices representing individual masks.
#' @param probabilities Numeric vector of probabilities corresponding to each mask.
#' @param threshold Numeric. The probability threshold for including a mask (default: 0.5).
#'
#' @return A logical matrix representing the combined mask.
#' @export
#'
#' @examples
#' \dontrun{
#' combined_mask <- combine_masks(results$masks, results$results$scores, threshold = 0.6)
#' }
combine_masks <- function(masks, probabilities, threshold = 0.5) {
  selected_masks <- masks[probabilities >= threshold]
  if (length(selected_masks) == 0) {
    stop("No masks meet the probability threshold")
  }
  combined <- Reduce(`|`, lapply(selected_masks, function(m) m > 0))
  return(combined)
}

#' Exclude masks from a combined mask
#'
#' This function excludes specified masks from a combined mask.
#'
#' @param combined_mask Logical matrix. The combined mask to exclude from.
#' @param exclude_masks List of logical matrices representing masks to exclude.
#'
#' @return A logical matrix representing the resulting mask after exclusions.
#' @export
#'
#' @examples
#' \dontrun{
#' final_mask <- exclude_masks(combined_mask, bee_masks)
#' }
exclude_masks <- function(combined_mask, exclude_masks) {
  for (mask in exclude_masks) {
    combined_mask[mask > 0] <- FALSE
  }
  return(combined_mask)
}

#' Extract color information from an image using a mask
#'
#' This function extracts color information from the parts of an image
#' specified by a mask.
#'
#' @param image Array. The original image (height x width x channels).
#' @param mask Logical matrix. The mask specifying which pixels to consider.
#' @param n_colors Integer. Number of dominant colors to extract (default: 5).
#'
#' @return A list containing color information including dominant colors and color statistics.
#' @export
#'
#' @examples
#' \dontrun{
#' color_info <- extract_colors(results$image, final_mask, n_colors = 3)
#' }
extract_colors <- function(image, mask, n_colors = 5) {
  # Ensure image is 3D (height x width x channels)
  if (length(dim(image)) == 4) {
    image <- array(image, dim = c(dim(image)[c(1,2,4)]))
  }

  # Ensure mask is 2D
  if (length(dim(mask)) > 2) {
    mask <- mask[,,1]
  }

  # Check dimensions
  if (!all(dim(image)[1:2] == dim(mask))) {
    stop("Image and mask dimensions do not match.")
  }

  # Extract RGB values for masked pixels
  masked_pixels <- image[rep(mask, dim(image)[3])]
  masked_pixels <- matrix(masked_pixels, ncol = dim(image)[3], byrow = TRUE)

  # Convert to hex colors
  hex_colors <- rgb(masked_pixels[,1], masked_pixels[,2], masked_pixels[,3])

  # Find dominant colors
  color_table <- table(hex_colors)
  dominant_colors <- names(sort(color_table, decreasing = TRUE)[1:min(n_colors, length(color_table))])

  # Calculate color statistics
  mean_color <- colMeans(masked_pixels)
  median_color <- apply(masked_pixels, 2, median)

  # Return results
  list(
    masked_pixels = masked_pixels,
    hex_colors = hex_colors,
    dominant_colors = dominant_colors,
    mean_color = rgb(mean_color[1], mean_color[2], mean_color[3]),
    median_color = rgb(median_color[1], median_color[2], median_color[3])
  )
}

#' Process image masks and extract color information
#'
#' This function combines masks, excludes specified masks, and extracts color information
#' from the resulting masked area of an image.
#'
#' @param image Array. The original image (height x width x channels x 1).
#' @param masks List of logical matrices representing individual masks.
#' @param probabilities Numeric vector of probabilities corresponding to each mask.
#' @param labels Character vector of labels corresponding to each mask.
#' @param include_labels Character vector of labels to include.
#' @param exclude_labels Character vector of labels to exclude.
#' @param probability_threshold Numeric. The probability threshold for including a mask (default: 0.5).
#' @param n_colors Integer. Number of dominant colors to extract (default: 5).
#'
#' @return A list containing the final mask and extracted color information.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- process_masks_and_extract_colors(
#'   image = seg_results$image,
#'   masks = seg_results$masks,
#'   probabilities = seg_results$results$scores,
#'   labels = seg_results$results$labels,
#'   include_labels = c("flower"),
#'   exclude_labels = c("bee"),
#'   probability_threshold = 0.6,
#'   n_colors = 3
#' )
#' }
process_masks_and_extract_colors <- function(image, masks, probabilities, labels,
  include_labels, exclude_labels = NULL,
  probability_threshold = 0.5, n_colors = 5) {
  # Ensure image is in 0-1 range
  if (max(image, na.rm = TRUE) > 1) {
    image <- image / 255
  }

  # Transpose and adjust masks to match image dimensions
  adjusted_masks <- lapply(masks, function(mask) {
    t(matrix(unlist(mask), nrow = ncol(image), ncol = nrow(image)))
  })

  # Filter masks based on labels to include
  include_indices <- which(labels %in% include_labels)
  include_masks <- adjusted_masks[include_indices]
  include_probs <- probabilities[include_indices]

  # Combine masks
  combined_mask <- combine_masks(include_masks, include_probs, threshold = probability_threshold)

  # Exclude masks if specified
  if (!is.null(exclude_labels)) {
    exclude_indices <- which(labels %in% exclude_labels)
    exclude_masks <- adjusted_masks[exclude_indices]
    final_mask <- exclude_masks(combined_mask, exclude_masks)
  } else {
    final_mask <- combined_mask
  }

  # Extract colors
  color_info <- extract_colors(image, final_mask, n_colors = n_colors)

  # Return results
  list(
    final_mask = final_mask,
    color_info = color_info
  )
}

