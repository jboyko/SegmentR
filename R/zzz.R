.onLoad <- function(libname, pkgname) {
  tryCatch({
    message("Attempting to set up Python environment...")

    # Check if the conda environment exists
    conda_envs <- reticulate::conda_list()
    env_exists <- any(conda_envs$name == "segcolr-env")

    if (!env_exists) {
      message("Creating conda environment 'segcolr-env'...")
      reticulate::conda_create(envname = "segcolr-env", environment = system.file("environment.yml", package = pkgname))
    } else {
      message("Conda environment 'segcolr-env' already exists.")
    }

    # Use the conda environment
    reticulate::use_condaenv("segcolr-env", required = TRUE)

    message("Python environment setup successful.")
  }, error = function(e) {
    warning("Error setting up Python environment: ", e$message)
  })
}

