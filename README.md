------------------------------------------------------------------------

# SegColR: A Package for Image Segmentation

The **SegColR** package is a tool for image segmentation and color extraction. SegColR is built on two pretrained models: [GroundingDINO](https://github.com/IDEA-Research/GroundingDINO) and [Segment Anything Model (SAM)](https://github.com/facebookresearch/segment-anything). Specifically, we use a lighter version of SAM called [SlimSAM](https://github.com/czg1225/SlimSAM), which uses fewer parameters but achieves similar results.

More details on SegColR can be found here: https://www.biorxiv.org/content/10.1101/2024.07.28.605475v1

## Installing the Package

To install the SegColR package from GitHub, use the following command in R:

``` r
devtools::install_github("jboyko/SegColR")
```

## Setting up the Python Environment Within R

SegColR requires a specific Python environment.
To set it up from within R, follow these steps:

1.  **Install Anaconda or Miniconda**: If you don't have Anaconda or Miniconda installed, download and install it from their [official website](https://docs.conda.io/en/latest/miniconda.html).

2.  **Install the SegColR R Package**: Install the package using the command provided above.

3.  **Setup the Conda Environment**: Run the following R function to set up the required Python environment:

    ``` r
    setup_conda_environment()
    ```

    This function will create and configure the Conda environment as specified in the `inst/environment.yml` file.

## Setting up the Python Environment Outside of R

If you prefer to set up the Python environment outside of R, follow these steps:

1.  **Install Anaconda or Miniconda**: If not already installed, download and install Anaconda or Miniconda from their [official website](https://docs.conda.io/en/latest/miniconda.html).

2.  **Open a Terminal or Command Prompt**: Access your command-line interface.

3.  **Navigate to the Package Directory**: Go to the directory containing the SegColR package.

4.  **Create the Conda Environment**: Execute the following command to create the required environment:

    ``` bash
    conda env create -f inst/environment.yml
    ```

5.  **(Optional) Activate the Environment**: To activate the environment, use:

    ``` bash
    conda activate segcolr-env
    ```

## Usage

```
library(SegColR)
library(imager)
library(RColorBrewer)

example_data <- load_segcolr_example_data()
```

## Guided Segmentation and Color Analysis

We'll use the second image from the example data to demonstrate the segmentation and color analysis.

```
img <- example_data$images[[2]]
plot(img, axes = FALSE, main = "Andaman Hind")
```
![Andaman Hind](https://i.imgur.com/MzAmPR2.jpeg)

To segment the image and analyze colors, use the `grounded_segmentation_cli()` function:

```
ground_results <- grounded_segmentation_cli(
  image_path = example_data$image_paths[2],
  labels = "a fish.",
  output_json = "/home/jboyko/SegColR/extdata/json/",
  output_plot = "/home/jboyko/SegColR/extdata/plot/")
```
![As part of the output an image is generated from Python and saved in the output_plot directory.](https://i.imgur.com/G1S5Vqz.png)


All of the necessary paths are saved as part of the ground_results. Load the segmentation results:

```
seg_results <- load_segmentation_results(
  image_path = ground_results$image_path,
  json_path = ground_results$json_path
)
```

Visualize the results with:

```
plot_seg_results(
  seg_results = seg_results,
  mask_colors = "Set1",
  background = "grayscale",
  show_label = TRUE,
  show_score = TRUE,
  show_bbox = TRUE,
  score_threshold = 0.5,
  label_size = 1.2,
  bbox_thickness = 2,
  mask_alpha = 0.3)
```
![Segmentaiton results produced in R.](https://i.imgur.com/8e2BWbg.png)

Analyze colors in the segmented regions:

```
color_results <- process_masks_and_extract_colors(
  image = seg_results$image,
  masks = seg_results$mask,
  scores = seg_results$score,
  labels = seg_results$label,
  include_labels = labels,
  exclude_labels = NULL,
  score_threshold = 0.5,
  n_colors = 5)
```

Finally, visualize the extracted colors:

```
plot_color_info(color_results)
```

![This plot displays the colors in the segmented regions, showing their proportions and RGB values.](https://i.imgur.com/mxe4DNO.png)

This is only a very basic color analysis and other R packages such as `recolorize` may be better suited for downstream analyses. 

---
