------------------------------------------------------------------------

# SegmentR: A Package for Image Segmentation

The **SegmentR** package is a tool for image segmentation and color extraction. SegmentR is built on two pretrained models: [GroundingDINO](https://github.com/IDEA-Research/GroundingDINO) and [Segment Anything Model (SAM)](https://github.com/facebookresearch/segment-anything). Specifically, we use a lighter version of SAM called [SlimSAM](https://github.com/czg1225/SlimSAM), which uses fewer parameters but achieves similar results.

More details on SegmentR can be found here: https://www.biorxiv.org/content/10.1101/2024.07.28.605475v1

## Installing the Package

To install the SegmentR package from GitHub, use the following command in R:

``` r
devtools::install_github("jboyko/SegmentR")
```

## Setting up the Python Environment Within R

SegmentR requires a specific Python environment.
To set it up from within R, follow these steps:

1.  **Install Anaconda or Miniconda**: If you don't have Anaconda or Miniconda installed, download and install it from their [official website](https://docs.conda.io/en/latest/miniconda.html).

2.  **Install the SegmentR R Package**: Install the package using the command provided above.

3.  **Setup the Conda Environment**: Run the following R function to set up the required Python environment:

    ``` r
    setup_conda_environment()
    ```

    This function will create and configure the Conda environment as specified in the `inst/environment.yml` file.

## Setting up the Python Environment Outside of R

If you prefer to set up the Python environment outside of R, follow these steps:

1.  **Install Anaconda or Miniconda**: If not already installed, download and install Anaconda or Miniconda from their [official website](https://docs.conda.io/en/latest/miniconda.html).

2.  **Open a Terminal or Command Prompt**: Access your command-line interface.

3.  **Navigate to the Package Directory**: Go to the directory containing the SegmentR package.

4.  **Create the Conda Environment**: Execute the following command to create the required environment:

    ``` bash
    conda env create -f inst/environment.yml
    ```

5.  **(Optional) Activate the Environment**: To activate the environment, use:

    ``` bash
    conda activate segmentr-env
    ```

## Usage

```
library(SegmentR)
library(imager)
library(RColorBrewer)

example_data <- load_segmentr_example_data()
```

## Guided Segmentation and Color Analysis

We'll use the batch example to demonstrate the segmentation. A single image example can be found in the vignette.

```
img_folder <- load_segmentr_example_data()[[2]]
image_paths <- dir(img_folder, full.names = TRUE)[grep("jpeg", dir(img_folder))]

```
![Flower images](https://i.imgur.com/SQTJkjL.png)

To segment the image and analyze colors, use the `run_grounded_segmentation` function:

```
run_grounded_segmentation(img_folder, labels = c("an individual flower"))
```

It will output plots and jsons. It will also print out to console the command it's running in python. 

```
Processing image 1 of 4: 242477360.jpeg
Executing command: /opt/miniconda3/bin/conda run -n segmentr-env python '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/python/main.py' --image '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/242477360.jpeg' --labels '["an individual flower"]' --threshold 0.300000 --save_plot '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/plots/segmentr_plot_242477360.png' --save_json '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/json/segmentr_output_242477360.json' --detector_id 'IDEA-Research/grounding-dino-tiny' --segmenter_id 'Zigeng/SlimSAM-uniform-77' 

Processing image 2 of 4: 243146103.jpeg
Executing command: /opt/miniconda3/bin/conda run -n segmentr-env python '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/python/main.py' --image '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/243146103.jpeg' --labels '["an individual flower"]' --threshold 0.300000 --save_plot '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/plots/segmentr_plot_243146103.png' --save_json '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/json/segmentr_output_243146103.json' --detector_id 'IDEA-Research/grounding-dino-tiny' --segmenter_id 'Zigeng/SlimSAM-uniform-77' 

Processing image 3 of 4: 243695619.jpeg
Executing command: /opt/miniconda3/bin/conda run -n segmentr-env python '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/python/main.py' --image '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/243695619.jpeg' --labels '["an individual flower"]' --threshold 0.300000 --save_plot '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/plots/segmentr_plot_243695619.png' --save_json '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/json/segmentr_output_243695619.json' --detector_id 'IDEA-Research/grounding-dino-tiny' --segmenter_id 'Zigeng/SlimSAM-uniform-77' 

Processing image 4 of 4: 249435672.jpeg
Executing command: /opt/miniconda3/bin/conda run -n segmentr-env python '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/python/main.py' --image '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/249435672.jpeg' --labels '["an individual flower"]' --threshold 0.300000 --save_plot '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/plots/segmentr_plot_249435672.png' --save_json '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/SegmentR/extdata/images/json/segmentr_output_249435672.json' --detector_id 'IDEA-Research/grounding-dino-tiny' --segmenter_id 'Zigeng/SlimSAM-uniform-77' 
```


All of the necessary paths are saved as part of the results, but they can also be recreated (without doing the segmentaiton again) using `get_segmentation_paths`. Load the segmentation results:

```
results <- get_segmentation_paths(img_folder)
seg_res <- load_segmentation_results(results$summary$source_directory)
```

Visualize the results with (annoyingly these results were even better than the ones I shared in the manuscript):

```
layout(matrix(1:4, nrow = 2))
par(mar = c(1, 0, 1, 0))
for(i in 4:1){
  plot_seg_results(seg_res[[i]])
}
```

![Segmentaiton results produced in R.](https://i.imgur.com/VcowwaZ.png)

Finally, we can export the masks.

```
for(i in 1:(length(seg_res)-1)){
  focal <- seg_res[[i]]
  export_transparent_png(input = focal, 
    output_path = "~/exported_segments/", remove_overlap = TRUE, crop = TRUE)
}
```
---
