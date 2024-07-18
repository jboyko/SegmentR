#' Combine masks based on a score threshold
#'
#' This function combines all masks that meet or exceed a specified score threshold.
#'
#' @param masks List of logical matrices representing individual masks.
#' @param scores Numeric vector of scores corresponding to each mask.
#' @param threshold Numeric. The score threshold for including a mask (default: 0.5).
#'
#' @return A logical matrix representing the combined mask.
#' @export
#'
#' @examples
#' \dontrun{
#' combined_mask <- combine_masks(results$masks, results$results$scores, threshold = 0.6)
#' }
combine_masks <- function(masks, scores, threshold = 0.5) {
  selected_masks <- masks[scores >= threshold]
  if (length(selected_masks) == 0) {
    stop("No masks meet the score threshold")
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
#' specified by a mask. It can either use k-means clustering to find dominant
#' colors or cluster based on user-specified colors.
#'
#' @param image Array. The original image (height x width x channels).
#' @param mask Logical matrix. The mask specifying which pixels to consider.
#' @param n_colors Integer. Number of dominant colors to extract when using k-means clustering (default: 5).
#' @param custom_colors Character vector. Optional. Hex codes of colors to use for clustering instead of k-means.
#'
#' @return A list containing color information including dominant colors and color statistics.
#' @export
#'
#' @examples
#' \dontrun{
#' # Using k-means clustering
#' color_info <- extract_colors(results$image, final_mask, n_colors = 3)
#'
#' # Using custom colors
#' custom_colors <- c("#FF0000", "#00FF00", "#0000FF")
#' color_info <- extract_colors(results$image, final_mask, custom_colors = custom_colors)
#' }
extract_colors <- function(image, mask, n_colors = 5, custom_colors = NULL) {
  image <- imager::as.cimg(image)
  mask <- imager::as.cimg(mask) > 0
  masked_pixels <- matrix(image[mask], ncol = 3)

  # Convert RGB values to Lab color space
  lab_colors <- convertColor(masked_pixels, from = "sRGB", to = "Lab")

  if (is.null(custom_colors)) {
    # Perform k-means clustering
    km_result <- kmeans(lab_colors, centers = n_colors)
    custom_colors_lab <- km_result$centers
    cluster_sizes <- km_result$size
  } else {
    # Convert custom colors to Lab color space
    custom_colors_rgb <- t(col2rgb(custom_colors)) / 255
    custom_colors_lab <- convertColor(custom_colors_rgb, from = "sRGB", to = "Lab")
    n_colors <- length(custom_colors)
  }
  custom_colors_lab_t <- t(custom_colors_lab)
  # Assign each pixel to the nearest custom color
  cluster_assignments <- apply(lab_colors, 1, function(x)
    which.min(sqrt(colSums((custom_colors_lab_t - x)^2))))
  # Calculate cluster centers and sizes
  dominant_colors_lab <- custom_colors_lab
  cluster_sizes <- tabulate(cluster_assignments, nbins = n_colors)

  # Create a km_result-like object for consistency
  km_result <- list(
    cluster = cluster_assignments,
    centers = dominant_colors_lab,
    size = cluster_sizes
  )

  # Convert Lab centroids to RGB and then to hex codes
  dominant_colors_rgb <- apply(dominant_colors_lab, 1, function(x) {
    rgb_values <- convertColor(matrix(x, nrow = 1, ncol = 3), from = "Lab", to = "sRGB")
    rgb(rgb_values[1], rgb_values[2], rgb_values[3])
  })

  # Summarize the dominant colors
  dominant_color_info <- data.frame(
    lab_l = dominant_colors_lab[, 1],
    lab_a = dominant_colors_lab[, 2],
    lab_b = dominant_colors_lab[, 3],
    hex_color = dominant_colors_rgb,
    cluster_size = cluster_sizes
  )

  # Calculate color statistics
  mean_color <- colMeans(masked_pixels)
  median_color <- apply(masked_pixels, 2, median)

  # Return results
  list(
    masked_pixels = masked_pixels,
    hex_colors = rgb(masked_pixels[, 1] / 255, masked_pixels[, 2] / 255, masked_pixels[, 3] / 255),
    dominant_color_info = dominant_color_info,
    mean_color = rgb(mean_color[1], mean_color[2], mean_color[3]),
    median_color = rgb(median_color[1], median_color[2], median_color[3]),
    km_result = km_result
  )
}

#' Process image masks and extract color information
#'
#' This function combines masks, excludes specified masks, and extracts color information
#' from the resulting masked area of an image.
#'
#' @param image Array. The original image (height x width x channels x 1).
#' @param masks List of logical matrices representing individual masks.
#' @param scores Numeric vector of scores corresponding to each mask.
#' @param labels Character vector of labels corresponding to each mask.
#' @param include_labels Character vector of labels to include.
#' @param exclude_labels Character vector of labels to exclude.
#' @param exclude_boxes Numeric. Specifies which bounding boxes should be removed manually rather than by score threshold.
#' @param score_threshold Numeric. The score threshold for including a mask (default: 0.5).
#' @param n_colors Integer. Number of dominant colors to extract (default: 5).
#' @param custom_colors Character vector. Optional. Hex codes of colors to use for clustering instead of k-means.
#' @return A list containing the final mask and extracted color information.
#' @export
#'
#' @examples
#' \dontrun{
#' results <- process_masks_and_extract_colors(
#'   image = seg_results$image,
#'   masks = seg_results$masks,
#'   scores = seg_results$results$scores,
#'   labels = seg_results$results$labels,
#'   include_labels = c("flower"),
#'   exclude_labels = c("bee"),
#'   score_threshold = 0.6,
#'   n_colors = 3
#' )
#' }
process_masks_and_extract_colors <- function(image, masks, scores, labels,
  include_labels, exclude_labels = NULL, exclude_boxes = NULL,
  score_threshold = 0.5, n_colors = 5, custom_colors = NULL) {

  # Exclude any masks specified numerically
  if(!is.null(exclude_boxes)){
    masks <- masks[-exclude_boxes]
    scores <- scores[-exclude_boxes]
    labels <- labels[-exclude_boxes]
  }

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
  include_probs <- scores[include_indices]

  # Combine masks
  combined_mask <- combine_masks(include_masks, include_probs, threshold = score_threshold)

  # Exclude masks if specified
  if (!is.null(exclude_labels)) {
    exclude_indices <- which(labels %in% exclude_labels)
    exclude_masks <- adjusted_masks[exclude_indices]
    final_mask <- exclude_masks(combined_mask, exclude_masks)
  } else {
    final_mask <- combined_mask
  }

  # Extract colors
  color_info <- extract_colors(image, final_mask,
    n_colors = n_colors,
    custom_colors = custom_colors)

  # Return results
  list(
    final_mask = final_mask,
    image = image,
    color_info = color_info
  )
}

# remove_shadows <- function(image){
#   # Ensure image is in the correct format
#   if (is.cimg(image)) {
#     image <- as.array(image)
#   }
#
#   # Reshape the image for color conversion
#   dims <- dim(image)
#   reshaped_image <- matrix(image, ncol = 3)
#
#   # Convert RGB to LAB
#   lab_image <- convertColor(reshaped_image, from = "sRGB", to = "Lab")
#
#   # Reshape back to original dimensions
#   lab_image <- array(lab_image, dim = dims)
#
#   # Separate L, A, and B channels
#   L <- lab_image[,,,1]
#   A <- lab_image[,,,2]
#   B <- lab_image[,,,3]
#
#   # Compute mean values for L, A, and B
#   mean_L <- mean(L)
#   mean_A <- mean(A)
#   mean_B <- mean(B)
#
#   # Shadow detection
#   if (mean_A + mean_B <= 256) {
#     # Compute standard deviation of L
#     sd_L <- sd(as.vector(L))
#     # Classify shadow pixels
#     shadow_mask <- L <= (mean_L - sd_L/3)
#   } else {
#     # Classify pixels with lower values in both L and B as shadow
#     shadow_mask <- (L < mean_L) & (B < mean_B)
#   }
#
#   # Shadow removal
#   # Function to compute ratio for a channel
#   compute_ratio <- function(channel, mask) {
#     non_shadow_avg <- mean(channel[!mask])
#     shadow_avg <- mean(channel[mask])
#     return(non_shadow_avg / shadow_avg)
#   }
#
#   # Compute ratios for R, G, B channels
#   r_ratio <- compute_ratio(image[,,,1], shadow_mask)
#   g_ratio <- compute_ratio(image[,,,2], shadow_mask)
#   b_ratio <- compute_ratio(image[,,,3], shadow_mask)
#
#   # Apply correction
#   corrected_image <- image
#   corrected_image[,,,1][shadow_mask] <- corrected_image[,,,1][shadow_mask] * r_ratio
#   corrected_image[,,,2][shadow_mask] <- corrected_image[,,,2][shadow_mask] * g_ratio
#   corrected_image[,,,3][shadow_mask] <- corrected_image[,,,3][shadow_mask] * b_ratio
#
#   # Clip values to valid range [0, 1]
#   corrected_image <- pmin(pmax(corrected_image, 0), 1)
#
#   return(corrected_image)
# }

