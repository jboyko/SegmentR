## Installing the package

Install the R-package using `devtools::install_github("jboyko/SegColR")`

## Setting up the Python Environment Within R

This package requires a specific Python environment. Follow these steps to set it up:

1. Install Anaconda or Miniconda if you haven't already.

2. Install the SegColR R-package.

3. run `setup_conda_environment()` 


## Setting up the Python Environment Outside of R

This package requires a specific Python environment. Follow these steps to set it up:

1. Install Anaconda or Miniconda if you haven't already.

2. Open a terminal or command prompt.

3. Navigate to the directory containing this package.

4. Run the following command to create the required environment:

   ```
   conda env create -f inst/environment.yml
   ```

5. (Optional) Activate the environment:

   ```
   conda activate segcolr-env
   ```