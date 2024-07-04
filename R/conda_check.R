#' Set up Conda Environment for SegColR
#'
#' This function creates a conda environment for SegColR based on the specified YAML file.
#'
#' @param env_type Character string specifying which environment file to use.
#'   Options are "general" (default) or "specific".
#' @param conda_path Character string specifying the path to the conda executable.
#'   If NULL (default), the function will attempt to find conda automatically.
#' @param force Logical indicating whether to force recreation of the environment
#'   if it already exists. Default is FALSE.
#'
#' @return Invisible NULL. The function is called for its side effects.
#'
#' @export
setup_conda_environment <- function(env_type = "general", conda_path = NULL, force = FALSE) {
  # Validate env_type
  if (!env_type %in% c("general", "specific")) {
    stop("env_type must be either 'general' or 'specific'")
  }

  # Determine the environment file to use
  env_file <- if (env_type == "general") {
    system.file("environment_general.yml", package = "SegColR")
  } else {
    system.file("environment.yml", package = "SegColR")
  }

  if (!file.exists(env_file)) {
    stop("Environment file not found: ", env_file)
  }

  # Find conda
  if (is.null(conda_path)) {
    conda_path <- reticulate::conda_binary()
    if (conda_path == "") {
      stop("conda not found in system PATH. Please provide the path to conda executable.")
    }
  }

  # Check if the environment already exists
  env_name <- "segcolr-env"
  if (reticulate::condaenv_exists(env_name) && !force) {
    message("Conda environment 'segcolr-env' already exists. Use force = TRUE to recreate.")
    return(invisible(NULL))
  }

  # Create or recreate the environment
  message("Creating conda environment. This may take a while...")
  if (force && reticulate::condaenv_exists(env_name)) {
    reticulate::conda_remove(env_name)
  }
  reticulate::conda_create(env_name, environment = env_file, conda = conda_path)

  message("Conda environment 'segcolr-env' has been created successfully.")
  invisible(NULL)
}

