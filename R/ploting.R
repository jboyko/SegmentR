#' Plot Segmentation Results
#' This function creates a plot of segmentation results with various customization options using base R graphics.
#' @param seg_results A list containing segmentation results (image, label, score, box, mask).
#' @param mask_colors A named vector of colors for each label, or a color palette name from RColorBrewer.
#' @param background One of "original", "grayscale", "transparent", or a specific color.
#' @param show_label Logical. Whether to display labels.
#' @param show_score Logical. Whether to display scores
#' @param show_bbox Logical. Whether to display bounding boxes.
#' @param score_threshold Numeric. Threshold for displaying results (0-1).
#' @param exclude_boxes Numeric. Specifies which object detections should not be plotted.
#' @param label_size Numeric. Size of label text.
#' @param bbox_thickness Numeric. Thickness of bounding box lines.
#' @param mask_alpha Numeric. Transparency of mask overlays (0-1).
#'
#' @return Invisibly returns NULL, called for side effect of plotting.
#' @export
plot_seg_results <- function(seg_results,
  mask_colors = "Set1",
  background = "original",
  show_label = TRUE,
  show_score = TRUE,
  show_bbox = TRUE,
  score_threshold = 0,
  exclude_boxes = NULL,
  label_size = 1,
  bbox_thickness = 2,
  mask_alpha = 0.3) {

  default_par <- par(no.readonly = TRUE)

  # Prepare background
  original = imager::as.cimg(seg_results$image)
  original = imager::flatten.alpha(original)
  bg <- switch(background,
    "original" = original,
    "grayscale" = imager::grayscale(original),
    "transparent" = imager::imfill(dim = dim(original), val = 0),
    imager::imfill(dim = dim(original), val = col2rgb(background) / 255))

  # Prepare color palette
  if (length(mask_colors) == 1 && mask_colors %in% rownames(RColorBrewer::brewer.pal.info)) {
    n_colors <- length(unique(seg_results$label))
    mask_colors <- RColorBrewer::brewer.pal(n_colors, mask_colors)
    names(mask_colors) <- unique(seg_results$label)
  }

  # Plot the background
  # plot(bg, axes = FALSE)

  # Add the segmentation masks
  for (i in seq_along(seg_results$label)) {
    if (seg_results$score[i] >= score_threshold) {
      mask <- imager::as.cimg(t(seg_results$mask[[i]])) > 0
      col <- mask_colors[seg_results$label[i]]
      bg <- imager::colorise(bg, mask, col, alpha = mask_alpha)
    }
  }

  par(mar=c(.1,.1,.1,.1))
  plot(bg, axes=FALSE)

  for (i in seq_along(seg_results$label)) {
    if(!(i %in% exclude_boxes)){
      if (seg_results$score[i] >= score_threshold) {
        # Add bounding box if requested
        if (show_bbox) {
          box <- seg_results$box[i, ]
          rect(box$xmin, box$ymin, box$xmax, box$ymax,
            border = mask_colors[seg_results$label[i]],
            lwd = bbox_thickness)
        }

        # Add label and score if requested
        if (show_score) {
          label_text <- sprintf("%s: %.2f", seg_results$label[i], seg_results$score[i])
        } else {
          label_text <- seg_results$label[i]
        }

        # add labels if requested
        if (show_label){
          text(seg_results$box$xmin[i], seg_results$box$ymin[i], label_text,
            col = mask_colors[seg_results$label[i]],
            adj = c(0, 1), cex = label_size)
        }
      }
    }
  }

  # Display message if no detections above threshold
  if (all(seg_results$score < score_threshold)) {
    text(mean(dim(bg)[1]), mean(dim(bg)[2]),
      "No detections above threshold",
      col = "red", cex = label_size)
  }

  par(default_par)
  invisible(NULL)
}

#' Plot Color Information
#'
#' This function plots the dominant colors, color histogram, and other color statistics
#' based on the output of the `extract_colors` function.
#'
#' @param color_results List. Output of the `process_masks_and_extract_colors` function.
#' @param repainted Logical. Whether the mask should be repainted by dominant colors.
#' @param horiz Logical. Whether the mask and original image should be arranged horizontally or vertically.
#'
#' @return Invisibly returns NULL, called for side effect of plotting.
#' @export
plot_color_info <- function(color_results, horiz=TRUE, repainted=TRUE) {
  default_par <- par(no.readonly = TRUE)
  # Extract relevant information from the color_info list
  masked_pixels_matrix <- color_results$color_info$masked_pixels
  dominant_color_info <- color_results$color_info$dominant_color_info
  mean_color <- color_results$color_info$mean_color
  median_color <- color_results$color_info$median_color
  image <- color_results$image
  final_mask <- 1 - color_results$final_mask

  # Set up the grid layout
  if(horiz){
    layout(matrix(c(
      1,1,2,
      3,4,5,
      3,4,6,
      3,4,7),
      nrow=4, byrow = TRUE))
  }else{
    layout(matrix(c(
      1,1,2,
      3,3,5,
      4,4,6,
      4,4,7),
      nrow=4, byrow = TRUE))
  }

  # Plot the dominant colors
  par(mar=c(.5,.5,3,.5))
  plot(0, 0, type = "n", xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "", main = "Dominant Colors", axes=FALSE)
  for (i in 1:nrow(dominant_color_info)) {
    rect(
      (i - 1) / nrow(dominant_color_info), 0,
      i / nrow(dominant_color_info), 1,
      col = dominant_color_info$hex_color[i],
      border = NA
    )
    text(
      (i - 0.5) / nrow(dominant_color_info), 0.5,
      sprintf("%.2f%%", dominant_color_info$cluster_size[i] / sum(dominant_color_info$cluster_size) * 100),
      col = "white", cex = 0.8
    )
  }

  # Plot the mean and median colors
  par(mar=c(.5,.5,2,.5))
  plot(0, 0, type = "n", xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "", main = "Mean and Median Colors", axes=FALSE)
  rect(0, 0, 0.5, 1, col = mean_color, border = NA)
  rect(0.5, 0, 1, 1, col = median_color, border = NA)
  text(0.25, 0.5, "Mean", col = "white", cex = 0.8)
  text(0.75, 0.5, "Median", col = "white", cex = 0.8)

  # Plot the original image and the final mask
  par(mar = c(0.1, 2, 0.1, 0.1))
  plot(as.cimg(image), axes = FALSE)
  par(mar = c(0.1, 0.1, 0.1, 2))
  if(repainted){
    plot_repainted_mask(
      image = color_results$image,
      final_mask = color_results$final_mask,
      color_info = color_results$color_info)
  }else{
    plot(as.cimg(final_mask), axes = FALSE)
  }
  # plot the colored mask
  # Plot the color histograms
  par(mar = c(3, 1, 2, 1))
  # Red channel histogram
  hist(masked_pixels_matrix[, 1], col = "red", main = "Red Channel Histogram", breaks = 30, border = "white", xlab = "Pixel Value", ylab = "", axes=FALSE)
  box(col = "white")
  axis(1, at = seq(0, 1, .1), labels = seq(0, 1, .1))

  # Green channel histogram
  hist(masked_pixels_matrix[, 2], col = "green", main = "Green Channel Histogram", breaks = 30, border = "white", xlab = "Pixel Value", ylab = "", axes=FALSE)
  box(col = "white")
  axis(1, at = seq(0, 1, .1), labels = seq(0, 1, .1))

  # Blue channel histogram
  hist(masked_pixels_matrix[, 3], col = "blue", main = "Blue Channel Histogram", breaks = 30, border = "white", xlab = "Pixel Value", ylab = "", axes=FALSE)
  box(col = "white")
  axis(1, at = seq(0, 1, .1), labels = seq(0, 1, .1))

  par(default_par)
  invisible(NULL)
}


#' Repaint Masked Image with Dominant Colors
#'
#' This function takes an image, a final mask, and the dominant color information
#' and generates a new "repainted" image where the masked regions are colored
#' according to the dominant colors.
#'
#' @param image Array. The original image (height x width x channels).
#' @param final_mask Logical matrix. The final mask specifying which pixels to consider.
#' @param color_info List. The dominant color information, including kmeans result.
#'
#' @return Array. The repainted image (height x width x channels).
#' @export
plot_repainted_mask <- function(image, final_mask, color_info, verbose=FALSE) {
  # Create a new image the same size as the original
  repainted_image <- as.cimg(array(1, dim = c(nrow(image), ncol(image), 1, 3)))
  ind_mat <- final_mask
  ind_mat[final_mask == 1] <- 1:sum(final_mask)
  col_mat <- t(col2rgb(color_info$dominant_color_info$hex_color[color_info$km_result$cluster]))/255
  for(i in 1:nrow(final_mask)){
    if(verbose){
      cat("\rProcessing:", round(i/nrow(final_mask) * 100), "%...")
    }
    repainted_image[i, which(final_mask[i,]), 1, ] <- col_mat[ind_mat[i,which(final_mask[i,])],]
  }
  # if(crop){
  #   rows_to_keep <- range(which(abs(rowSums(final_mask))>0))
  #   cols_to_keep <- range(which(abs(colSums(final_mask))>0))
  #   cropped_image <- as.cimg(repainted_image[rows_to_keep[1]:rows_to_keep[2],
  #     cols_to_keep[1]:cols_to_keep[2], , ])
  #   plot(cropped_image, axes = FALSE)
  # }else{
  plot(repainted_image, axes = FALSE)
  # }
}


