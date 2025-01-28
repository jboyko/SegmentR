#' Perform Grounded Segmentation via Command Line Interface
#'
#' This function performs grounded segmentation on an image using a Python backend.
#'
#' @param image_path Character string. Path to the input image.
#' @param labels Character vector. Labels to detect in the image.
#' @param threshold Numeric. Detection threshold (default: 0.3).
#' @param detector_id Character string. ID of the detector model.
#' @param segmenter_id Character string. ID of the segmenter model.
#' @param output_plot Character string. Path or directory to save the output plot.
#' @param output_json Character string. Path or directory to save the output JSON.
#' @param show_plot Boolean. Whether a plot should automatically be shown after a segmentation.
#' @param create_dir Boolean. If the output directory doesn't exist, one will be created. 
#' @param conda_env Character string. Name of the conda environment to use.
#'
#' @return A list containing the command output and paths to saved outputs.
#' @export
grounded_segmentation_cli <- function(image_path,
  labels,
  threshold = 0.3,
  detector_id = "IDEA-Research/grounding-dino-tiny",
  segmenter_id = "Zigeng/SlimSAM-uniform-77",
  output_plot = NULL,
  output_json = NULL,
  show_plot = FALSE,
  create_dir = TRUE,
  conda_env = "segmentr-env") {
  
  # normalize to absolute paths
  image_path <- normalizePath(image_path)
  polygon_refinement = FALSE
  script_path = system.file("python/main.py", package = "SegmentR")
  
  # Ensure the script path is correct
  if (!file.exists(script_path)) {
    stop("Python script not found at: ", script_path)
  }
  
  # Generate default output paths if not provided
  file_name <- basename(image_path)
  file_name <- sub("\\.[^.]*$", "", file_name)
  directory <- dirname(image_path)
  
  # Set up plot directory and path
  if (is.null(output_plot)) {
    plot_dir <- file.path(directory, "plots")
    if (create_dir && !dir.exists(plot_dir)) {
      dir.create(plot_dir, recursive = TRUE)
    }
    output_plot <- file.path(plot_dir, paste0("segmentr_plot_", file_name, ".png"))
  } else {
    if (create_dir && !dir.exists(output_plot)) {
      dir.create(output_plot, recursive = TRUE)
    }
    output_plot <- file.path(output_plot, paste0("segmentr_plot_", file_name, ".png"))
  }
  
  # Set up json directory and path
  if (is.null(output_json)) {
    json_dir <- file.path(directory, "json")
    if (create_dir && !dir.exists(json_dir)) {
      dir.create(json_dir, recursive = TRUE)
    }
    output_json <- file.path(json_dir, paste0("segmentr_output_", file_name, ".json"))
  } else {
    if (create_dir && !dir.exists(output_json)) {
      dir.create(output_json, recursive = TRUE)
    }
    output_json <- file.path(output_json, paste0("segmentr_output_", file_name, ".json"))
  }
  
  # Ensure paths exist for directory creation
  if (!dir.exists(dirname(output_plot)) && !create_dir) {
    stop("Plot output directory does not exist: ", dirname(output_plot))
  }
  if (!dir.exists(dirname(output_json)) && !create_dir) {
    stop("JSON output directory does not exist: ", dirname(output_json))
  }
  
  # Normalize paths after directory creation
  output_plot <- normalizePath(output_plot, mustWork = FALSE)
  output_json <- normalizePath(output_json, mustWork = FALSE)
  
  # Find conda path
  conda_path <- search_conda_locations()
  if (is.null(conda_path)) {
    stop("Conda executable not found. Please install Conda or provide the path manually.")
  }
  
  # Check if the Conda environment exists
  cmd_check_env <- sprintf('%s env list | grep -q "%s"', conda_path, conda_env)
  env_exists <- system(cmd_check_env, ignore.stderr = TRUE)
  if (env_exists != 0) {
    stop("Specified conda environment '", conda_env, "' does not exist. ",
      "Please create it using setup_conda_environment() function.")
  }
  
  # Construct the command to run the script in the Conda environment
  cmd <- sprintf("%s run -n %s python %s --image %s --labels '%s' --threshold %f --save_plot %s --save_json %s",
    conda_path,
    conda_env,
    shQuote(script_path),
    shQuote(image_path),
    jsonlite::toJSON(labels),
    threshold,
    shQuote(output_plot),
    shQuote(output_json))
  
  # Add optional arguments
  if (polygon_refinement) cmd <- paste(cmd, "--polygon_refinement")
  if (!is.null(detector_id)) cmd <- paste(cmd, sprintf("--detector_id %s", shQuote(detector_id)))
  if (!is.null(segmenter_id)) cmd <- paste(cmd, sprintf("--segmenter_id %s", shQuote(segmenter_id)))
  if (show_plot) cmd <- paste(cmd, "--show_plot")
  
  # Print the command (for debugging)
  cat("Executing command:", cmd, "\n")
  
  # Run the command
  tryCatch({
    output <- system(cmd, intern = TRUE)
  }, error = function(e) {
    stop("Error executing command: ", e$message,
      "\nCommand was: ", cmd)
  })
  
  # Return the results
  list(
    activate_cmd = cmd,
    command_output = output,
    image_path = image_path,
    plot_path = output_plot,
    json_path = output_json
  )
}
#' Perform Custom Bounded Box Segmentation
#'
#' This function performs segmentation on an image using a custom bounding box.
#'
#' @param image_path Character string. Path to the input image.
#' @param bbox Numeric vector. Custom bounding box coordinates = xmin, ymin, xmax, ymax.
#' @param polygon_refinement Logical. Whether to refine polygons (default: FALSE).
#' @param segmenter_id Character string. ID of the segmenter model.
#' @param script_path Character string. Path to the Python script.
#' @param output_plot Character string or NULL. Path to save the output plot. If NULL, saves to current working directory.
#' @param output_json Character string or NULL. Path to save the output JSON. If NULL, saves to current working directory.
#' @param conda_env Character string. Name of the conda environment to use.
#'
#' @return A list containing the segmentation results.
#' @export
custom_bbox_segmentation_cli <- function(image_path,
                                         bbox,
                                         polygon_refinement = FALSE,
                                         segmenter_id = "Zigeng/SlimSAM-uniform-77",
                                         script_path = system.file("python/main.py", package = "SegmentR"),
                                         output_plot = NULL,
                                         output_json = NULL,
                                         conda_env = "segmentr-env") {

  # Ensure the script path is correct
  if (!file.exists(script_path)) {
    stop("Python script not found at: ", script_path)
  }

  # Generate default output paths if not provided
  if (is.null(output_plot)) {
    output_plot <- file.path(getwd(), paste0("segmentation_plot_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".png"))
  }
  if (is.null(output_json)) {
    output_json <- file.path(getwd(), paste0("segmentation_output_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json"))
  }

  # Construct the command to activate conda and run the script
  activate_cmd <- sprintf("source /home/jboyko/anaconda3/etc/profile.d/conda.sh && conda activate %s && ", conda_env)
  cmd <- sprintf("%s python %s --image %s --labels '[]' --custom_bbox '%s' --segmenter_id %s --save_plot %s --save_json %s",
                 activate_cmd,
                 shQuote(script_path),
                 shQuote(image_path),
                 jsonlite::toJSON(bbox),
                 shQuote(segmenter_id),
                 shQuote(output_plot),
                 shQuote(output_json))

  if (polygon_refinement) {
    cmd <- paste(cmd, "--polygon_refinement")
  }

  # Print the command (for debugging)
  cat("Executing command:", cmd, "\n")

  # Run the command using bash
  output <- system(paste("bash -c", shQuote(cmd)), intern = TRUE)

  # Check if the JSON file was created
  if (!file.exists(output_json)) {
    stop("Failed to create output JSON file. Python script execution may have failed.")
  }

  # Read and parse the JSON output
  segmentation_results <- jsonlite::fromJSON(output_json)

  # Return the results
  list(
    command_output = output,
    segmentation_results = segmentation_results,
    plot_path = output_plot,
    json_path = output_json
  )
}
