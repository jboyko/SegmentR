#' #' Export Segmentation as Transparent PNG/TIFF
#' #' 
#' #' Exports segmentation results as an image file with specified regions made transparent
#' #' @param seg_results A list containing segmentation results (image, label, score, box, mask)
#' #' @param file_path Character. Path where the image should be saved
#' #' @param format Character. Output format ("png" or "tiff")
#' #' @param labels_to_keep Character vector. Labels of regions to keep (others made transparent)
#' #' @param separate Logical. Whether to export each region as a separate file
#' #' 
#' #' @return Invisibly returns NULL
#' #' @importFrom imager save.image as.cimg add.alpha
#' #' @export
#' export_transparent_image <- function(seg_results, 
#'   file_path,
#'   format = "png",
#'   labels_to_keep = NULL,
#'   separate = FALSE) {
#'   # Validate format
#'   format <- match.arg(format, c("png", "tiff"))
#'   
#'   # Convert original image to cimg
#'   orig_img <- imager::as.cimg(seg_results$image)
#'   
#'   # If no labels specified, keep all
#'   if (is.null(labels_to_keep)) {
#'     labels_to_keep <- unique(seg_results$label)
#'   }
#'   
#'   if (separate) {
#'     # Export each region separately
#'     for (label in labels_to_keep) {
#'       # Find masks for this label
#'       label_indices <- which(seg_results$label == label)
#'       
#'       # Combine all masks for this label using imager
#'       combined_mask <- imager::as.cimg(array(0, dim = dim(t(seg_results$mask[[1]]))))
#'       for (i in label_indices) {
#'         combined_mask <- combined_mask | imager::as.cimg(t(seg_results$mask[[i]]))
#'       }
#'       
#'       # Create masked image
#'       masked_img <- orig_img * combined_mask
#'       
#'       # Add alpha channel
#'       result_img <- imager::add.alpha(masked_img, alpha = combined_mask)
#'       
#'       # Generate output filename
#'       out_path <- paste0(tools::file_path_sans_ext(file_path), 
#'         "_", 
#'         make.names(label), 
#'         ".", 
#'         format)
#'       
#'       # Save using imager
#'       imager::save.image(result_img, out_path)
#'     }
#'   } else {
#'     # Combine all specified labels into one mask
#'     combined_mask <- imager::as.cimg(array(0, dim = dim(t(seg_results$mask[[1]]))))
#'     for (label in labels_to_keep) {
#'       label_indices <- which(seg_results$label == label)
#'       for (i in label_indices) {
#'         combined_mask <- combined_mask | imager::as.cimg(t(seg_results$mask[[i]]))
#'       }
#'     }
#'     
#'     # Create masked image
#'     masked_img <- orig_img * combined_mask
#'     
#'     # Add alpha channel
#'     result_img <- imager::add.alpha(masked_img, alpha = combined_mask)
#'     
#'     # Save using imager
#'     imager::save.image(result_img, file_path)
#'   }
#'   
#'   invisible(NULL)
#' }
#' 
#' #' Export Binary Mask
#' #' 
#' #' Exports segmentation masks as binary images
#' #' @param seg_results A list containing segmentation results
#' #' @param file_path Character. Path where to save the mask
#' #' @param labels_to_keep Character vector. Labels to include in mask
#' #' @param separate Logical. Whether to export each label as separate mask
#' #' 
#' #' @return Invisibly returns NULL
#' #' @importFrom imager save.image as.cimg
#' #' @export
#' export_binary_mask <- function(seg_results,
#'   file_path,
#'   labels_to_keep = NULL,
#'   separate = FALSE) {
#'   
#'   # If no labels specified, keep all
#'   if (is.null(labels_to_keep)) {
#'     labels_to_keep <- unique(seg_results$label)
#'   }
#'   
#'   if (separate) {
#'     # Export each label as separate mask
#'     for (label in labels_to_keep) {
#'       # Find masks for this label
#'       label_indices <- which(seg_results$label == label)
#'       
#'       # Combine all masks for this label using imager
#'       combined_mask <- imager::as.cimg(array(0, dim = dim(t(seg_results$mask[[1]]))))
#'       for (i in label_indices) {
#'         combined_mask <- combined_mask | imager::as.cimg(t(seg_results$mask[[i]]))
#'       }
#'       
#'       # Generate output filename
#'       out_path <- paste0(tools::file_path_sans_ext(file_path),
#'         "_",
#'         make.names(label),
#'         ".png")
#'       
#'       # Save using imager
#'       imager::save.image(combined_mask, out_path)
#'     }
#'   } else {
#'     # Combine all specified labels into one mask using imager
#'     combined_mask <- imager::as.cimg(array(0, dim = dim(t(seg_results$mask[[1]]))))
#'     for (label in labels_to_keep) {
#'       label_indices <- which(seg_results$label == label)
#'       for (i in label_indices) {
#'         combined_mask <- combined_mask | imager::as.cimg(t(seg_results$mask[[i]]))
#'       }
#'     }
#'     
#'     # Save using imager
#'     imager::save.image(combined_mask, file_path)
#'   }
#'   
#'   invisible(NULL)
#' }
#' 
#' #' Export ImageJ ROI Coordinates
#' #' 
#' #' Exports segmentation masks as ImageJ ROI coordinates
#' #' @param seg_results A list containing segmentation results
#' #' @param file_path Character. Path where to save the coordinates
#' #' @param labels_to_keep Character vector. Labels to include
#' #' @param format Character. Output format ("txt" or "zip")
#' #' 
#' #' @return Invisibly returns NULL
#' #' @importFrom imager as.cimg boundary
#' #' @importFrom utils write.table
#' #' @export
#' export_roi_coordinates <- function(seg_results,
#'   file_path,
#'   labels_to_keep = NULL,
#'   format = "txt") {
#'   
#'   # Validate format
#'   format <- match.arg(format, c("txt", "zip"))
#'   
#'   if (is.null(labels_to_keep)) {
#'     labels_to_keep <- unique(seg_results$label)
#'   }
#'   
#'   # Process each label
#'   for (label in labels_to_keep) {
#'     label_indices <- which(seg_results$label == label)
#'     
#'     # Process each instance of the label
#'     for (i in label_indices) {
#'       # Convert mask to cimg and get boundary
#'       mask_img <- imager::as.cimg(t(seg_results$mask[[i]]))
#'       boundary_pts <- imager::boundary(mask_img)
#'       
#'       # Extract x,y coordinates
#'       coords <- cbind(boundary_pts$x, boundary_pts$y)
#'       
#'       if (format == "txt") {
#'         # Save as text file with x,y coordinates
#'         out_path <- paste0(tools::file_path_sans_ext(file_path),
#'           "_",
#'           make.names(label),
#'           "_",
#'           i,
#'           ".txt")
#'         
#'         write.table(coords, 
#'           out_path,
#'           row.names = FALSE,
#'           col.names = c("X", "Y"),
#'           sep = "\t")
#'       } else {
#'         # Save as ImageJ ROI ZIP file
#'         # Note: This requires the ijroi package or similar
#'         # Implementation depends on specific requirements
#'         warning("ZIP format not yet implemented")
#'       }
#'     }
#'   }
#'   
#'   invisible(NULL)
#' }
#' 
#' #' Export COCO JSON Format
#' #' 
#' #' Exports segmentation results in COCO JSON format
#' #' @param seg_results A list containing segmentation results
#' #' @param file_path Character. Path where to save the JSON file
#' #' @param image_id Character/Numeric. ID for the image in COCO format
#' #' @param category_ids Named numeric vector. Mapping of labels to category IDs
#' #' 
#' #' @return Invisibly returns NULL
#' #' @importFrom jsonlite write_json
#' #' @importFrom imager as.cimg boundary
#' #' @export
#' export_coco_json <- function(seg_results,
#'   file_path,
#'   image_id = 1,
#'   category_ids = NULL) {
#'   
#'   # Create default category IDs if not provided
#'   if (is.null(category_ids)) {
#'     unique_labels <- unique(seg_results$label)
#'     category_ids <- setNames(seq_along(unique_labels), unique_labels)
#'   }
#'   
#'   # Initialize COCO format
#'   coco_data <- list(
#'     images = list(
#'       list(
#'         id = image_id,
#'         width = dim(seg_results$image)[2],
#'         height = dim(seg_results$image)[1]
#'       )
#'     ),
#'     annotations = list(),
#'     categories = lapply(seq_along(category_ids), function(i) {
#'       list(
#'         id = category_ids[i],
#'         name = names(category_ids)[i]
#'       )
#'     })
#'   )
#'   
#'   # Process each segmentation
#'   for (i in seq_along(seg_results$label)) {
#'     # Convert mask to cimg and get boundary
#'     mask_img <- imager::as.cimg(t(seg_results$mask[[i]]))
#'     boundary_pts <- imager::boundary(mask_img)
#'     
#'     # Format coordinates for COCO (flatten x,y coordinates)
#'     segmentation <- as.numeric(rbind(boundary_pts$x, boundary_pts$y))
#'     
#'     # Create annotation entry
#'     annotation <- list(
#'       id = i,
#'       image_id = image_id,
#'       category_id = category_ids[seg_results$label[i]],
#'       segmentation = list(segmentation),
#'       area = sum(t(seg_results$mask[[i]])),
#'       bbox = as.numeric(c(
#'         seg_results$box$xmin[i],
#'         seg_results$box$ymin[i],
#'         seg_results$box$xmax[i] - seg_results$box$xmin[i],
#'         seg_results$box$ymax[i] - seg_results$box$ymin[i]
#'       )),
#'       iscrowd = 0
#'     )
#'     
#'     coco_data$annotations[[i]] <- annotation
#'   }
#'   
#'   # Write to JSON file
#'   jsonlite::write_json(coco_data, 
#'     file_path, 
#'     auto_unbox = TRUE, 
#'     pretty = TRUE)
#'   
#'   invisible(NULL)
#' }
