# RHOAI DIH (Disconnected Install Helper)

This repository generates and maintains the complete list of container images needed to install RHOAI in disconnected (air-gapped) environments. Image lists are updated automatically via GitHub Actions.

Two flavors are supported:

- **RHOAI (OpenShift)** -- generates `rhoai-<version>.md` files for use with `oc-mirror`
- **XKS Charts (vanilla Kubernetes)** -- generates `charts/rhai-on-xks-chart-<version>.yaml` files for use with `skopeo sync`

## Table of Contents

- [RHOAI DIH (Disconnected Install Helper)](#rhoai-dih-disconnected-install-helper)
  - [Table of Contents](#table-of-contents)
  - [Generate using GitHub Actions](#generate-using-github-actions)
    - [RHOAI (OpenShift)](#rhoai-openshift)
    - [XKS Charts (vanilla Kubernetes)](#xks-charts-vanilla-kubernetes)
  - [Run Locally](#run-locally)
    - [RHOAI (OpenShift)](#rhoai-openshift-1)
    - [XKS Charts (vanilla Kubernetes)](#xks-charts-vanilla-kubernetes-1)
      - [Configuration](#configuration)
  - [How XKS Charts DIH Files Are Generated](#how-xks-charts-dih-files-are-generated)
    - [Extraction Process](#extraction-process)
    - [Sail Operator Image Filtering](#sail-operator-image-filtering)

## Generate using GitHub Actions

### RHOAI (OpenShift)

Workflows are available for both y-stream (regular releases) and z-stream (patch releases).

**Y-stream releases (e.g., rhoai-2.25):**

1. Navigate to the [Y-stream workflow](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/actions/workflows/rhods-disconnected-install-helper.yml)
2. Click "Run workflow"
3. Fill in the optional inputs:
   - **branch_name**: Version in the format `rhoai-x.y` (e.g., `rhoai-2.25`). Leave empty to process all versions from `releases.yaml`
   - **fbc_image**: FBC details (optional)
4. Click "Run workflow"

The workflow generates `rhoai-<version>.md` and commits it to the repository.

Y-stream also runs daily on a scheduled basis and on every nightly FBC publish.

**Z-stream releases (e.g., rhoai-2.25.2):**

1. Navigate to the [Z-stream workflow](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/actions/workflows/rhods-disconnected-install-helper-z-stream.yml)
2. Click "Run workflow"
3. Fill in the required inputs:
   - **repositories**: Version in the format `rhoai-x.y.z` (e.g., `rhoai-2.25.2`)
   - **channel_input**: Channel name (e.g., `fast`, `stable`)
4. Click "Run workflow"

The workflow generates `rhoai-<version>.md` and commits it to the repository.

### XKS Charts (vanilla Kubernetes)

1. Navigate to the [XKS Charts workflow](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/actions/workflows/xks-charts-disconnected-helper.yml)
2. Click "Run workflow"
3. Enter the full image reference (e.g., `quay.io/rhoai/rhai-on-xks-chart@sha256:...`, or `registry.redhat.io/rhoai/rhai-on-xks-chart@sha256:...`)
4. Click "Run workflow"

The workflow generates `charts/rhai-on-xks-chart-<version>.yaml` and commits it to the repository.

**Note:** The GitHub Actions workflow intentionally only accepts full image URIs with SHA digests to ensure right image is used for the DIH file generation.

## Run Locally

### RHOAI (OpenShift)

**Requirements:** bash 4.0+, jq, oc, yq, skopeo

```bash
# All versions from releases.yaml
./rhoai-disconnected-helper.sh

# Specific y-stream version
./rhoai-disconnected-helper.sh -v rhoai-2.25

# Z-stream version
./rhoai-disconnected-helper-z-stream.sh rhoai-2.25.2

# Help
./rhoai-disconnected-helper.sh -h
```

Output is saved as `rhoai-<version>.md`. Copy the image list into the `additionalImages` section of your `ImageSetConfiguration`.

**It is recommended to copy the list directly from the respective `rhoai-<version>.md` file in the repository. In case of any issues or conflicts, please contact the devops team.**

### XKS Charts (vanilla Kubernetes)

**Requirements:** bash, skopeo

```bash
# Login to registries
skopeo login registry.redhat.io
skopeo login quay.io
```

**Usage:**

```bash
# By version (GA release)
scripts/xks-charts-disconnected-helper.sh 3.5.0

# By version (early access)
scripts/xks-charts-disconnected-helper.sh 3.5.0-ea.1

# By full image reference with tag
scripts/xks-charts-disconnected-helper.sh registry.redhat.io/rhai/rhai-on-xks-chart:v3.5.0

# By full image reference with digest
scripts/xks-charts-disconnected-helper.sh quay.io/rhoai/rhai-on-xks-chart@sha256:abc123...

# Use dev nightly build directly (skip GA registry check)
BUILD_TYPE=nightly scripts/xks-charts-disconnected-helper.sh 3.5.0

# Use dev CI build directly
BUILD_TYPE=ci scripts/xks-charts-disconnected-helper.sh 3.5.0-ea.1

# Only extract images from registry.redhat.io (exclude registry.access.redhat.com)
REGISTRIES="registry.redhat.io" scripts/xks-charts-disconnected-helper.sh 3.5.0

# Custom output filename
OUTPUT_FILENAME="my-images.yaml" scripts/xks-charts-disconnected-helper.sh 3.5.0

# Filter for a specific Istio version
SAIL_OPERATOR_VERSION=v1.26 scripts/xks-charts-disconnected-helper.sh 3.5.0

# Include all Istio versions (disable filtering)
SAIL_OPERATOR_VERSION=all scripts/xks-charts-disconnected-helper.sh 3.5.0
```

Output is saved as `charts/rhai-on-xks-chart-<version>.yaml` in skopeo sync format.

See [`charts/README.md`](charts/README.md) for details on how to use the generated files.

**Note on version input and registry fallback:** When a version string is provided, the script uses `BUILD_TYPE` to determine which registry to try. With the default `BUILD_TYPE=ga`, it first attempts the GA registry (`registry.redhat.io`). If the chart is not found there -- which is expected for in-progress releases that haven't been published to the GA registry yet -- it automatically falls back to the dev nightly registry (`quay.io/rhoai`). Set `BUILD_TYPE=nightly` or `BUILD_TYPE=ci` to skip the GA check and go directly to the dev registry.

#### Configuration

| Variable                 | Default                                          | Purpose                                                |
| ------------------------ | ------------------------------------------------ | ------------------------------------------------------ |
| `GA_CHART_REPOSITORY`    | `registry.redhat.io/rhai/rhai-on-xks-chart`      | GA chart repository; also derives output filenames     |
| `DEV_CHART_REPOSITORY`   | `quay.io/rhoai/rhai-on-xks-chart`                | Dev chart repository for nightly and CI builds         |
| `REGISTRIES`             | `registry.redhat.io registry.access.redhat.com`  | Space-separated registries to search for in YAML files |
| `OUTPUT_DIR`             | `charts`                                         | Output directory (relative to repo root)               |
| `OUTPUT_FILENAME`        | `rhai-on-xks-chart-<VERSION>.yaml`               | Output file name (derived from `GA_CHART_REPOSITORY`)  |
| `OPERATOR_IMAGE_PATTERN` | `odh-rhel9-operator`                             | Pattern to find operator image in `values.yaml`        |
| `SAIL_OPERATOR_VERSION`  | *(auto-detect)*                                  | Override Istio version filtering; `all` to disable     |
| `BUILD_TYPE`             | `ga`                                             | `ga`, `nightly`, or `ci` (version input only)          |

## How XKS Charts DIH Files Are Generated

### Extraction Process

The XKS charts script discovers all container images by following these steps:

1. **Pull the Helm chart and add its image reference to the list** -- downloads the chart OCI artifact using `skopeo copy`, resolves its digest, and adds the chart image reference to the image list.
2. **Extract the chart locally** -- extracts the downloaded `.tgz` to access the chart's YAML files.
3. **Search chart YAML files** -- recursively searches all `.yaml` files in the chart for Red Hat image references (`registry.redhat.io`, `registry.access.redhat.com`) with SHA256 digests and adds them to the list.
4. **Identify and pull the operator image** -- locates the operator image reference (matching `odh-rhel9-operator` by default) in `values.yaml` and pulls it. If the chart was pulled from the dev registry (i.e., the release has not been published to the GA registry yet) and the operator image is not found in `registry.redhat.io`, it falls back to the dev registry (`quay.io`) with the same image path and digest.
5. **Extract dependency charts from operator image** -- extracts the operator container image's filesystem layers to access `/opt/charts/`, where dependency charts are packaged.
6. **Search dependency chart YAML files** -- recursively searches all `.yaml` files in the dependency charts for Red Hat image references with SHA256 digests and adds them to the list. Sail Operator images are [version-filtered](#sail-operator-image-filtering).
7. **Deduplicate and generate output** -- all discovered images are deduplicated and written to a skopeo sync YAML file, grouped by registry and repository.

### Sail Operator Image Filtering

The Sail Operator chart bundles image references for **all** supported Istio versions (e.g. v1.24, v1.25, v1.26, v1.27) as annotations on the operator deployment manifest. However, only one Istio version is actually pinned for deployment. Including all versions would add dozens of unnecessary images to the mirror list.

The script filters these automatically:

1. Reads `spec.version` from `sail-operator/templates/istio.yaml` (e.g. `v1.27-latest`)
2. Strips the `-latest` suffix and converts dots to underscores to build an annotation key prefix (e.g. `v1_27`)
3. From the deployment manifest (`deployment-servicemesh-operator3.yaml`):
   - **Always includes** the operator container image itself (`spec.containers[].image`)
   - **Includes** annotation values where the key matches `images.v1_27_*` (e.g. `images.v1_27_pilot`, `images.v1_27_proxyv2`)
   - **Excludes** annotations for all other versions (e.g. `images.v1_24_*`, `images.v1_25_*`)

This reduces the Sail Operator image count from ~56 (all versions) to ~12 (single pinned version).

**Override behavior:**

- `SAIL_OPERATOR_VERSION=v1.26` -- filter for a specific version instead of auto-detecting
- `SAIL_OPERATOR_VERSION=all` -- disable filtering entirely, include all Istio versions
- If `istio.yaml` or the deployment manifest cannot be found or parsed, the script falls back to including all images with a warning
