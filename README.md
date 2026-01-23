# RHOAI disconnected install helper

This repository contains the updated list of additional images needed to install rhoai in a disconnected environment using oc-mirror for the current releases supported by rhoai.

The list of images and versions are updated automatically by a GitHub action.

## How to use it

**It is recommended to copy the list of additional images directly from the respective <rhoai-x.y>.md file. In case of any issues or conflicts, please contact the support team**. 

### Copy the list of images from the repository:

Copy the list from the file of the version you want to install and paste it in the additionalImages section of the ImageSetConfiguration file you are using to mirror the images. In the file there is also an example of ImageSetConfiguration.

### Run the script using GitHub Actions:

You can run the scripts directly from GitHub Actions without needing to set up the local environment. GitHub Actions workflows are available for both y-stream (regular releases) and z-stream (patch releases).

#### For Y-stream releases (e.g., rhoai-2.25):

1. Navigate to the [Y-stream GitHub Actions workflow](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/actions/workflows/rhods-disconnected-install-helper.yml)
2. Click on "Run workflow"
3. Fill in the optional inputs:
   - **branch_name**: Enter the y-stream version in the format `rhoai-x.y` (e.g., `rhoai-2.25`). Leave empty to process all versions from `releases.yaml`
   - **fbc_image**: Enter FBC details (optional)
4. Click "Run workflow" to start the execution

The workflow will:
- Run the script with your specified version (or all versions if not specified)
- Generate the corresponding markdown file(s) (e.g., `rhoai-2.25.md`)
- Automatically commit and push the generated file(s) to the repository

**Note**: Y-Stream also runs daily on scheduled basis and also on every nightly fbc published

#### For Z-stream releases (e.g., rhoai-2.25.2):

1. Navigate to the [Z-stream GitHub Actions workflow](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/actions/workflows/rhods-disconnected-install-helper-z-stream.yml)
2. Click on "Run workflow"
3. Fill in the required inputs:
   - **repositories**: Enter the z-stream version in the format `rhoai-x.y.z` (e.g., `rhoai-2.25.2`)
   - **channel_input**: Enter the channel name (e.g., `fast`, `stable`)
4. Click "Run workflow" to start the execution

The workflow will:
- Run the z-stream script with your specified version and channel
- Generate the corresponding markdown file (e.g., `rhoai-2.25.2.md`)
- Automatically commit and push the generated file to the repository

### Run the script locally (Only if you have insights into the tool-internals):
#### Requirements:
- bash 4.0 or higher
- jq latest
- oc latest
- yq latest
- skopeo latest

#### Usage:

Get last rhoai version:
```bash
./rhoai-disconnected-helper.sh
```

Get a specific rhoai version:
```bash
./rhoai-disconnected-helper.sh --rhoai-version <version>
or
./rhoai-disconnected-helper.sh -v <version>
```

Example:
```bash
./rhoai-disconnected-helper.sh -v rhoai-1.31
```

Get a z-stream rhoai version:
```bash
./rhoai-disconnected-helper-z-stream.sh <rhoai-x.y.z>
```

Example:
```bash
./rhoai-disconnected-helper-z-stream.sh rhoai-2.9.1
```

To get help about the script
```bash
./rhoai-disconnected-helper.sh -h
```

After running the script, the list of images with an example will be saved in a file by default called rhoai-< version >.md with version the version of rhoai you are using.
