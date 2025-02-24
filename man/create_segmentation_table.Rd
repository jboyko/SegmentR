% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/image_loading.R
\name{create_segmentation_table}
\alias{create_segmentation_table}
\title{Create summary table of segmentation results}
\usage{
create_segmentation_table(results, include_paths = TRUE)
}
\arguments{
\item{results}{List. Output from load_segmentation_results function.}

\item{include_paths}{Logical. Whether to include full file paths in the table (default: TRUE).}
}
\value{
A data.frame containing the summary information.
}
\description{
This function takes loaded segmentation results and creates a summary table
showing key information about the masks, scores, and file locations.
}
\examples{
\dontrun{
results <- load_segmentation_results("path/to/image.jpg")
summary_table <- create_segmentation_table(results)
}
}
