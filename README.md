# Rhods disconnected install helper

This repository contains the updated list of additional images needed to install RHODS in a disconnected environment using oc-mirror for the current releases supported by RHODS.

The list of images and versions are updated automatically by a GitHub action.

## How to use it

Copy the list from the file of the version you want to install and paste it in the aditionalImages section of the ImageSetConfiguration you are using to mirror the images. In the file there is also an example of ImageSetConfiguration.