#' Export segmentation masks as transparent PNGs
#'
#' @param segmentation Result from load_segmentation_results
#' @param output_dir Directory to save the exported images
#' @param background_transparency Numeric between 0-1 for background transparency
#' @param separate_masks Logical, whether to export each segment as separate file
#' @param format Output format ("png" or "tiff")
#' @return Invisibly returns paths to saved files
#' @export
export_transparent_masks <- function(segmentation, 
  output_dir, 
  background_transparency = 0,
  separate_masks = TRUE,
  format = "png") {
  # Validate inputs
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  # Get base filename
  base_name <- tools::file_path_sans_ext(basename(segmentation$paths$image))
  
  # Convert image to RGBA
  img_array <- as.array(segmentation$image)
  rgba_img <- array(1, dim = c(dim(img_array)[1:2], 4))
  
  if (separate_masks) {
    paths <- character()
    # Export each mask separately
    for (i in seq_along(segmentation$label)) {
      mask <- segmentation$mask[[i]]
      
      # Create RGBA image with transparency
      rgba_img[,,4] <- ifelse(mask == 1, 1, background_transparency)
      rgba_img[,,1:3] <- img_array * mask
      
      # Create output path
      out_path <- file.path(output_dir, 
        sprintf("%s_%s.%s", base_name, segmentation$label[i], format))
      
      # Save image
      png::writePNG(rgba_img, out_path)
      paths <- c(paths, out_path)
    }
  } else {
    # Combine all masks
    combined_mask <- Reduce(`|`, segmentation$mask)
    rgba_img[,,4] <- ifelse(combined_mask == 1, 1, background_transparency)
    rgba_img[,,1:3] <- img_array
    
    out_path <- file.path(output_dir, sprintf("%s_masked.%s", base_name, format))
    png::writePNG(rgba_img, out_path)
    paths <- out_path
  }
  
  invisible(paths)
}

#' Export segmentation as binary masks
#'
#' @param segmentation Result from load_segmentation_results
#' @param output_dir Directory to save the masks
#' @param format Output format ("png" or "tiff")
#' @return Invisibly returns paths to saved files
#' @export
export_binary_masks <- function(segmentation, output_dir, format = "png") {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  base_name <- tools::file_path_sans_ext(basename(segmentation$paths$image))
  paths <- character()
  
  # Export each mask
  for (i in seq_along(segmentation$label)) {
    mask <- segmentation$mask[[i]]
    out_path <- file.path(output_dir, 
      sprintf("%s_%s_mask.%s", base_name, segmentation$label[i], format))
    
    # Save binary mask
    png::writePNG(mask, out_path)
    paths <- c(paths, out_path)
  }
  
  invisible(paths)
}

#' Export segmentation as ImageJ ROIs
#'
#' @param segmentation Result from load_segmentation_results
#' @param output_dir Directory to save the ROIs
#' @return Invisibly returns paths to saved files
#' @export
export_imagej_roi <- function(segmentation, output_dir) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  base_name <- tools::file_path_sans_ext(basename(segmentation$paths$image))
  paths <- character()
  
  # For each mask, extract coordinates and save as ROI
  for (i in seq_along(segmentation$label)) {
    mask <- segmentation$mask[[i]]
    
    # Get coordinates of mask boundary
    contour <- get_mask_contour(mask)
    
    # Save as ROI file
    out_path <- file.path(output_dir, 
      sprintf("%s_%s.roi", base_name, segmentation$label[i]))
    write_imagej_roi(contour, out_path)
    paths <- c(paths, out_path)
  }
  
  invisible(paths)
}

#' Export segmentation in COCO JSON format
#'
#' @param segmentation Result from load_segmentation_results
#' @param output_path Path to save the JSON file
#' @return Invisibly returns path to saved file
#' @export
export_coco_json <- function(segmentation, output_path) {
  # Create COCO format annotations
  annotations <- list()
  for (i in seq_along(segmentation$label)) {
    mask <- segmentation$mask[[i]]
    box <- segmentation$box[[i]]
    
    # Get polygon coordinates
    contour <- get_mask_contour(mask)
    
    annotations[[i]] <- list(
      id = i,
      image_id = 1,  # Assuming single image
      category_id = i,
      segmentation = list(as.numeric(contour)),
      area = sum(mask),
      bbox = c(box$xmin, box$ymin, box$xmax - box$xmin, box$ymax - box$ymin),
      iscrowd = 0
    )
  }
  
  # Create COCO format JSON
  coco_json <- list(
    images = list(
      list(
        id = 1,
        file_name = basename(segmentation$paths$image),
        width = dim(segmentation$image)[2],
        height = dim(segmentation$image)[1]
      )
    ),
    annotations = annotations,
    categories = lapply(seq_along(segmentation$label), function(i) {
      list(
        id = i,
        name = segmentation$label[i],
        supercategory = "object"
      )
    })
  )
  
  # Save JSON
  jsonlite::write_json(coco_json, output_path, auto_unbox = TRUE, pretty = TRUE)
  invisible(output_path)
}

# Helper function to get mask contour coordinates
get_mask_contour <- function(mask) {
  # Implementation needed - could use contour finding algorithm
  # or boundary tracing to get coordinates
}

# Helper function to write ImageJ ROI format
write_imagej_roi <- function(contour, path) {
  # Implementation needed - write coordinates in ImageJ ROI format
}
