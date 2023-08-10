# Rhods disconnected install helper

This repository contains the updated list of additional images needed to install RHODS in a disconnected environment using oc-mirror for the current releases supported by RHODS.

The list of images and versions are updated automatically by a GitHub action.

## How to use it

You can copy the list directly from the repository or use the script to get the list of images for the version you want to install.

### 1. Copy the list of images from the repository:

Copy the list from the file of the version you want to install and paste it in the additionalImages section of the ImageSetConfiguration file you are using to mirror the images. In the file there is also an example of ImageSetConfiguration.

### 2. Run the script locally:
#### Requirements:
- bash 4.0 or higher
- jq
- oc
- yq
- skopeo

#### Usage:

Get last RHODS version:
```bash
./rhods-disconnected-helper.sh
```

Get a specific RHODS version:
```bash
./rhods-disconnected-helper.sh --rhods-version <version>
or
./rhods-disconnected-helper.sh -v <version>
```

Example:
```bash
./rhods-disconnected-helper.sh -v rhods-1.31
```

To get help about the script
```bash
./rhods-disconnected-helper.sh -h
```

After running the script, the list of images with an example will be saved in a file by default called rhods-< version >.md with version the version of RHODS you are using.