## Setting up the Python Environment

This package requires a specific Python environment. Follow these steps to set it up:

1. Install Anaconda or Miniconda if you haven't already.

2. Open a terminal or command prompt.

3. Navigate to the directory containing this package.

4. Run the following command to create the required environment:

   ```
   conda env create -f inst/environment.yml
   ```

5. Activate the environment:

   ```
   conda activate segcolr-env
   ```

The R package will automatically use this environment when loaded.

Install transformers Directly:
Sometimes, specifying transformers in environment.yml might not install it correctly. Try installing it directly into your Conda environment:

reticulate::conda_install(envname = "segcolr-env", packages = "transformers")
reticulate::conda_install(envname = "segcolr-env", packages = "git+https://github.com/huggingface/transformers")
reticulate::py_install(packages = "git+https://github.com/huggingface/transformers.git", envname = "segcolr-env")

reticulate::use_condaenv("segcolr-env", required = TRUE)
reticulate::py_run_string("import subprocess; subprocess.run(['pip', 'install', 'git+https://github.com/huggingface/transformers.git'])")
