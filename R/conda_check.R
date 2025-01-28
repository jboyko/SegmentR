#' Set up Conda Environment for SegmentR
#'
#' This function creates a Conda environment for SegmentR based on the specified YAML file.
#'
#' @param conda_path Character string specifying the path to the conda executable.
#'   If NULL (default), the function will attempt to find conda automatically.
#' @param force Logical indicating whether to force recreation of the environment
#'   if it already exists. Default is FALSE.
#'
#' @return Invisible NULL. The function is called for its side effects.
#'
#' @export
setup_conda_environment <- function(conda_path = NULL, force = FALSE) {
  # Validate env_type

  # Determine the environment file to use
  env_file <- system.file("environment.yml", package = "SegmentR")

  if (!file.exists(env_file)) {
    stop("Environment file not found: ", env_file)
  }

  # Find conda
  if (is.null(conda_path)) {
    conda_path <- Sys.which("conda")
    if (conda_path == "") {
      conda_path <- search_conda_locations()
      if (is.null(conda_path)) {
        stop("Conda not found. Please install Conda or provide the path manually. Use 'which conda' in terminal to find the path.")
      }
    }
  }

  # Check if the environment already exists
  env_name <- "segmentr-env"
  cmd_check_env <- sprintf('%s env list | grep -q "%s"', conda_path, env_name)
  env_exists <- system(cmd_check_env, ignore.stderr = TRUE)

  if (env_exists == 0 && !force) {
    message("Conda environment 'segmentr-env' already exists. Use force = TRUE to recreate.")
    return(invisible(NULL))
  }

  # Remove the existing environment if force is TRUE
  if (force && env_exists == 0) {
    message("Removing existing conda environment 'segmentr-env'...")
    cmd_remove_env <- sprintf('%s env remove -n %s', conda_path, env_name)
    system(cmd_remove_env, intern = TRUE, ignore.stderr = TRUE)
  }

  # Create the environment
  message("Creating conda environment. This may take a while...")
  cmd_create_env <- sprintf('%s env create -n %s -f %s', conda_path, env_name, env_file)
  result <- system(cmd_create_env, intern = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    warning("Conda environment creation may have encountered issues. Testing installation...")
  }
  # system(cmd_create_env, intern = TRUE, ignore.stderr = TRUE)
  
  # Check again that environment was created
  cmd_check_env <- sprintf('%s env list | grep -q "%s"', conda_path, env_name)
  env_exists <- system(cmd_check_env, ignore.stderr = TRUE)
  if(env_exists == 0){
    message("Conda environment 'segmentr-env' has been created successfully.")
  }
  invisible(NULL)
}

#' Search for Conda Executable in Common Locations
#'
#' This function searches for the Conda executable in common installation directories.
#' It looks in the user's home directory, as well as standard system-wide directories.
#'
#' @return A character string representing the path to the Conda executable if found,
#'   or NULL if Conda is not found in the specified locations.
#'
search_conda_locations <- function() {
  if (Sys.info()["sysname"] == "Windows") {
    # Common paths for Windows
    locations <- c(
      Sys.getenv("USERPROFILE"),  # User's home directory on Windows
      "C:/ProgramData/Anaconda3", # Common system-wide installation
      "C:/Users/Public/Anaconda3", # Another common system-wide directory
      "C:/ProgramData/Miniconda3", # Miniconda
      "C:/Users/Public/Miniconda3" # Another Miniconda directory
    )
  } else {
    # Common paths for Unix-like systems
    locations <- c(
      Sys.getenv("HOME"),                # User's home directory
      "/usr/local",                      # Common system-wide installation
      "/opt"                             # Another common system-wide directory
    )
  }

  for (loc in locations) {
    conda_path <- file.path(loc, "miniconda3/bin/conda")
    if (file.exists(conda_path)) {
      return(conda_path)
    }
    conda_path <- file.path(loc, "anaconda3/bin/conda")
    if (file.exists(conda_path)) {
      return(conda_path)
    }
    # Windows paths
    conda_path <- file.path(loc, "Miniconda3/Scripts/conda.exe")
    if (file.exists(conda_path)) {
      return(conda_path)
    }
    conda_path <- file.path(loc, "Anaconda3/Scripts/conda.exe")
    if (file.exists(conda_path)) {
      return(conda_path)
    }
  }

  return(NULL)
}
