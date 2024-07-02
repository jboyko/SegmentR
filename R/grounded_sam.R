#' @import reticulate

# Use conda_install to ensure the correct environment is used
reticulate::conda_install("segcolr-env", packages = c("numpy", "opencv", "pillow", "matplotlib", "plotly", "requests", "torch", "torchvision", "transformers"))

# Use conda_python to specify the Python interpreter
reticulate::use_condaenv("segcolr-env", required = TRUE)

# Import the Python modules
py_main <- reticulate::import_from_path("main", path = system.file("python", package = "SegColR"))

#' Run Grounded Segmentation
#'
#' @param image_path Path to the image file
#' @param labels Vector of labels to detect
#' @param threshold Detection threshold
#' @param polygon_refinement Whether to refine polygons
#' @param detector_id ID of the detector model
#' @param segmenter_id ID of the segmenter model
#' @export
grounded_segmentation_r <- function(image_path, labels, threshold = 0.3, polygon_refinement = FALSE,
                                    detector_id = "IDEA-Research/grounding-dino-tiny",
                                    segmenter_id = "Zigeng/SlimSAM-uniform-77") {
  # Convert R vector to Python list
  py_labels <- reticulate::r_to_py(labels)

  # Call the Python function
  result <- py_main$grounded_segmentation(image_path, py_labels, threshold, polygon_refinement, detector_id, segmenter_id)

  # Convert the result back to R objects if necessary
  # This depends on what grounded_segmentation returns and how you want to use it in R

  return(result)
}

#' Run Grounded Segmentation via Command Line
#'
#' This function runs the grounded segmentation algorithm by calling the Python script via command line,
#' activating the required conda environment before execution.
#'
#' @param image_path Character string. Path to the input image.
#' @param labels Character vector. Labels to detect in the image.
#' @param threshold Numeric. Detection threshold (default: 0.3).
#' @param polygon_refinement Logical. Whether to refine polygons (default: FALSE).
#' @param detector_id Character string. ID of the detector model (default: "IDEA-Research/grounding-dino-tiny").
#' @param segmenter_id Character string. ID of the segmenter model (default: "Zigeng/SlimSAM-uniform-77").
#' @param conda_env Character string. Name of the conda environment (default: "segcolr-env").
#' @param conda_path Character string. Path to the conda executable (default: "conda").
#' @param script_path Character string. Path to the Python script (default: system.file("python/main.py", package = "SegColR")).
#' @param output_plot Character string. Path to save the output plot (optional).
#' @param output_json Character string. Path to save the output JSON (optional).
#'
#' @return A list containing the command output and the paths to any saved outputs.
#' @export
grounded_segmentation_cli <- function(image_path,
                                      labels,
                                      threshold = 0.3,
                                      polygon_refinement = FALSE,
                                      detector_id = "IDEA-Research/grounding-dino-tiny",
                                      segmenter_id = "Zigeng/SlimSAM-uniform-77",
                                      conda_env = "segcolr-env",
                                      conda_path = "conda",
                                      script_path = system.file("python/main.py", package = "SegColR"),
                                      output_plot = NULL,
                                      output_json = NULL) {

  # Function to escape paths
  escape_path <- function(path) {
    if (grepl(" ", path) || grepl("&", path)) {
      return(paste0("\"", path, "\""))
    }
    return(path)
  }

  # Escape paths
  image_path <- escape_path(image_path)
  script_path <- escape_path(script_path)
  if (!is.null(output_plot)) output_plot <- escape_path(output_plot)
  if (!is.null(output_json)) output_json <- escape_path(output_json)

  # Construct the base command to activate conda environment and run the script
  if (.Platform$OS.type == "windows") {
    activate_cmd <- sprintf("call %s activate %s &&", conda_path, conda_env)
  } else {
    activate_cmd <- sprintf("source %s activate %s &&", conda_path, conda_env)
  }

  cmd <- sprintf("%s python %s --image %s --labels '%s' --threshold %f",
                 activate_cmd, script_path, image_path, jsonlite::toJSON(labels), threshold)

  # Add optional arguments
  if (polygon_refinement) cmd <- paste(cmd, "--polygon_refinement")
  if (!is.null(detector_id)) cmd <- paste(cmd, sprintf("--detector_id '%s'", detector_id))
  if (!is.null(segmenter_id)) cmd <- paste(cmd, sprintf("--segmenter_id '%s'", segmenter_id))
  if (!is.null(output_plot)) cmd <- paste(cmd, sprintf("--save_plot %s", output_plot))
  if (!is.null(output_json)) cmd <- paste(cmd, sprintf("--save_json %s", output_json))

  # Run the command
  if (.Platform$OS.type == "windows") {
    output <- system(sprintf("cmd /c %s", cmd), intern = TRUE)
  } else {
    output <- system(cmd, intern = TRUE)
  }

  # Return the results
  list(
    command_output = output,
    plot_path = output_plot,
    json_path = output_json
  )
}
