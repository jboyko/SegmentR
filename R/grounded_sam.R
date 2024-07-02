#' Perform Grounded Segmentation
#'
#' @param image Path to image or URL
#' @param labels List of labels to detect
#' @param threshold Detection threshold
#' @param polygon_refinement Whether to refine polygons
#' @param detector_id ID of the detector model
#' @param segmenter_id ID of the segmenter model
#' @return List containing image array and detections
#' @export
grounded_segmentation_r <- function(image, labels, threshold = 0.3, polygon_refinement = FALSE,
                                    detector_id = NULL, segmenter_id = NULL) {
  message("Note: This may take a while to run in R... \nThis is because we are running Python through reticulate and R might not properly manage subprocesses needed for parallel execution (see vignette for details on how to run this in Python).")
  grounded_sam <- reticulate::import("main")
  result <- grounded_sam$grounded_segmentation(image, labels, threshold, polygon_refinement, detector_id, segmenter_id)
  # tmp <- grounded_sam$grounded_segmentation("../floral-vision/images/21838.jpg", "a flower. a bee.")
  list(image_array = result[[1]], detections = result[[2]])
}

#' Plot Detections
#'
#' @param image_array Image as a numpy array
#' @param detections List of detections
#' @param save_name Optional name to save the plot
#' @export
plot_detections_r <- function(image_array, detections, save_name = NULL) {
  plot_detections(image_array, detections, save_name)
}

#' Plot Detections using Plotly
#'
#' @param image_array Image as a numpy array
#' @param detections List of detections
#' @export
plot_detections_plotly_r <- function(image_array, detections) {
  plot_detections_plotly(image_array, detections)
}


library(jsonlite)

#' Run Grounded Segmentation using command-line interface
#'
#' @param image Path to image or URL
#' @param labels List of labels to detect
#' @param threshold Detection threshold
#' @param polygon_refinement Whether to refine polygons
#' @param detector_id ID of the detector model
#' @param segmenter_id ID of the segmenter model
#' @param save_plot Path to save the plotted results
#' @param save_json Path to save the detection results as JSON
#' @param script_path Path to the main.py script
#'
#' @return Invisible NULL (called for side effects)
#' @export
grounded_segmentation_cli <- function(image, labels, threshold = 0.3, polygon_refinement = FALSE,
                                      detector_id = NULL, segmenter_id = NULL,
                                      save_plot = NULL, save_json = NULL,
                                      script_path = system.file("python/main.py", package = "SegColR")) {

  tryCatch({
    # Ensure we're using the correct conda environment
    reticulate::use_condaenv("segcolr-env", required = TRUE)

    # Get the Python path from the conda environment
    python_path <- reticulate::conda_python("segcolr-env")

    # Prepare arguments
    args <- c(
      script_path,
      "--image", image,
      "--labels", jsonlite::toJSON(labels, auto_unbox = TRUE),
      "--threshold", as.character(threshold)
    )

    if (polygon_refinement) args <- c(args, "--polygon_refinement")
    if (!is.null(detector_id)) args <- c(args, "--detector_id", detector_id)
    if (!is.null(segmenter_id)) args <- c(args, "--segmenter_id", segmenter_id)
    if (!is.null(save_plot)) args <- c(args, "--save_plot", save_plot)
    if (!is.null(save_json)) args <- c(args, "--save_json", save_json)

    # Run the Python script
    result <- system2(python_path, args, stdout = TRUE, stderr = TRUE)

    # Check for errors
    if (attr(result, "status") != 0) {
      stop("Error running grounded segmentation: ", paste(result, collapse = "\n"))
    }

    # Print output
    cat(result, sep = "\n")

  }, error = function(e) {
    message("An error occurred: ", e$message)
    message("\nDetailed error information:")
    print(reticulate::py_last_error())
  })

  invisible(NULL)
}

# grounded_segmentation_cli(
#   image = "../floral-vision/images/21838.jpg",
#   labels = c("a flower.", "a bee."),
#   threshold = 0.3,
#   polygon_refinement = TRUE,
#   save_plot = "output.png",
#   save_json = "results.json"
# )


