# RHOAI disconnected install helper

This repository contains the updated list of additional images needed to install rhoai in a disconnected environment using oc-mirror for the current releases supported by rhoai.

The list of images and versions are updated automatically by a GitHub action.

## How to use it

**It is recommended to copy the list of additional images directly from the respective <rhoai-x.y>.md file. In case of any issues or conflicts, please contact the support team**. 

### Copy the list of images from the repository:

Copy the list from the file of the version you want to install and paste it in the additionalImages section of the ImageSetConfiguration file you are using to mirror the images. In the file there is also an example of ImageSetConfiguration.


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
