.onLoad <- function(libname, pkgname) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    warning("reticulate package is required for some functionality. Please install it.")
    return(invisible(NULL))
  }
  # if (!requireNamespace("imager", quietly = TRUE)) {
  #   warning("Package 'imager' is required but not installed.")
  # }
  # if (!requireNamespace("jsonlite", quietly = TRUE)) {
  #   warning("Package 'jsonlite' is required but not installed.")
  # }
  invisible(NULL)
}
