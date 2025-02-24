% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/grounded_sam.R
\name{get_segmentation_paths}
\alias{get_segmentation_paths}
\title{Get expected output paths for grounded segmentation}
\usage{
get_segmentation_paths(
  path,
  output_plot = NULL,
  output_json = NULL,
  pattern = "\\\\.(jpg|jpeg|png)$",
  recursive = FALSE
)
}
\arguments{
\item{path}{Character string. Path to an input image or directory containing images.}

\item{output_plot}{Character string. Path or directory for output plots (default: NULL creates "plots" subdirectory).}

\item{output_json}{Character string. Path or directory for output JSONs (default: NULL creates "json" subdirectory).}

\item{pattern}{Character string. File pattern to match when path is a directory (default: "\\.(jpg|jpeg|png)$").}

\item{recursive}{Boolean. Whether to search for images recursively in subdirectories (default: FALSE).}
}
\value{
A list containing expected file paths for each image
}
\description{
Get expected output paths for grounded segmentation
}
