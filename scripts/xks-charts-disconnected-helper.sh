#!/bin/bash
# Disconnected install helper generation script for RHAI on XKS Helm charts
#
# Usage:
#   ./xks-charts-disconnected-helper.sh <VERSION | IMAGE_REFERENCE>
#
# Version format:
#   X.Y.Z        GA release   (e.g., 3.4.0, 3.5.1)
#   X.Y.Z-ea.N   Early access (e.g., 3.4.0-ea.1, 3.5.0-ea.2)
#   An optional "v" prefix is stripped automatically.
#
# Image reference format:
#   Full image reference with tag or digest (must contain /)
#   e.g., registry.redhat.io/rhai/rhai-on-xks-chart:v3.4.2
#   e.g., quay.io/rhoai/rhai-on-xks-chart@sha256:abc123...
#
# Examples:
#   ./xks-charts-disconnected-helper.sh 3.5.0
#   ./xks-charts-disconnected-helper.sh v3.4.0-ea.1
#   ./xks-charts-disconnected-helper.sh registry.redhat.io/rhai/rhai-on-xks-chart:v3.4.2
#   ./xks-charts-disconnected-helper.sh quay.io/rhoai/rhai-on-xks-chart:rhoai-3.5-ea.2-nightly
#
# Output:
#   charts/<CHART_NAME>-<VERSION>.yaml  Generated in the charts/ directory (relative to repo root)
#   .<CHART_NAME>-work/                 Working directory (cleaned up before each run)
#
# Chart resolution (controlled by BUILD_TYPE):
#   ga (default) - try GA registry first, fall back to dev nightly:
#     1. registry.redhat.io/rhai/rhai-on-xks-chart:v<VERSION>
#     2. quay.io/rhoai/rhai-on-xks-chart:rhoai-<MAJOR>.<MINOR><EA_SUFFIX>-nightly
#   nightly - use dev registry directly:
#     quay.io/rhoai/rhai-on-xks-chart:rhoai-<MAJOR>.<MINOR><EA_SUFFIX>-nightly
#   ci - use dev registry directly:
#     quay.io/rhoai/rhai-on-xks-chart:rhoai-<MAJOR>.<MINOR><EA_SUFFIX>
#
# Operator image resolution:
#   The operator image reference is read from values.yaml (GA registry path).
#   If the chart was pulled from the dev registry (i.e., the release has not
#   been published to the GA registry yet), and the operator image is not found
#   in registry.redhat.io, the script falls back to quay.io with the same
#   image path and digest.
#
# Environment Variables:
#   REGISTRIES              - Space-separated list of registries to extract
#                             Default: "registry.redhat.io registry.access.redhat.com"
#   OUTPUT_DIR              - Output directory (relative to repo root)
#                             Default: "charts"
#   OUTPUT_FILENAME         - Output file name
#                             Default: "<CHART_NAME>-<VERSION>.yaml" (derived from GA_CHART_REPOSITORY)
#   OPERATOR_IMAGE_PATTERN  - Pattern to identify the operator image in values.yaml
#                             Default: "odh-rhel9-operator"
#   SAIL_OPERATOR_VERSION   - Override Istio version filtering for Sail Operator
#                             Default: "" (auto-detect from chart's istio.yaml)
#                             Set to "all" to disable filtering
#   BUILD_TYPE              - Build type for chart resolution
#                             Default: "ga" (try GA registry, fall back to nightly builds from dev registry)
#                             "nightly" - use dev registry nightly build directly
#                             "ci"      - use dev registry CI build directly
#   INCLUDE_DEPENDENCY_CHARTS - Dependency charts to include from the operator image
#                             Default: "all" (include every chart under /opt/charts/)
#                             Space-separated list to include specific charts
#                             Empty string to skip dependency chart extraction entirely
#
# Examples with environment variables:
#   REGISTRIES="registry.redhat.io" ./xks-charts-disconnected-helper.sh 3.5.0
#   OUTPUT_FILENAME="images.yaml" ./xks-charts-disconnected-helper.sh 3.5.0
#   OPERATOR_IMAGE_PATTERN="my-operator" ./xks-charts-disconnected-helper.sh 3.5.0
#   SAIL_OPERATOR_VERSION="v1.26" ./xks-charts-disconnected-helper.sh 3.5.0
#   BUILD_TYPE="nightly" ./xks-charts-disconnected-helper.sh 3.5.0
#   BUILD_TYPE="ci" ./xks-charts-disconnected-helper.sh 3.5.0-ea.1
#   INCLUDE_DEPENDENCY_CHARTS="sail-operator cert-manager-operator" ./xks-charts-disconnected-helper.sh 3.5.0
#   INCLUDE_DEPENDENCY_CHARTS="" ./xks-charts-disconnected-helper.sh 3.5.0

set -euo pipefail

# ============================================================================
# CONSTANTS
# ============================================================================

GA_CHART_REPOSITORY="${GA_CHART_REPOSITORY:-registry.redhat.io/rhai/rhai-on-xks-chart}"
DEV_CHART_REPOSITORY="${DEV_CHART_REPOSITORY:-quay.io/rhoai/rhai-on-xks-chart}"

CHART_NAME="$(basename "$GA_CHART_REPOSITORY")"

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REGISTRIES="${REGISTRIES:-registry.redhat.io registry.access.redhat.com}"
OUTPUT_DIR="${OUTPUT_DIR:-charts}"
OUTPUT_FILENAME="${OUTPUT_FILENAME:-}"
OPERATOR_IMAGE_PATTERN="${OPERATOR_IMAGE_PATTERN:-odh-rhel9-operator}"
SAIL_OPERATOR_VERSION="${SAIL_OPERATOR_VERSION:-}"
BUILD_TYPE="${BUILD_TYPE:-ga}"
INCLUDE_DEPENDENCY_CHARTS="${INCLUDE_DEPENDENCY_CHARTS:-all}"

# ============================================================================
# BUILD REGISTRY PATTERN (computed once)
# ============================================================================

REGISTRY_PATTERN=""
for reg in $REGISTRIES; do
    local_escaped="${reg//./\\.}"
    if [ -n "$REGISTRY_PATTERN" ]; then
        REGISTRY_PATTERN="${REGISTRY_PATTERN}|${local_escaped}"
    else
        REGISTRY_PATTERN="$local_escaped"
    fi
done

# ============================================================================
# FUNCTIONS
# ============================================================================

# Check if a dependency chart should be processed based on INCLUDE_DEPENDENCY_CHARTS
should_process_chart() {
    local name="$1"
    [ "$INCLUDE_DEPENDENCY_CHARTS" = "all" ] && return 0
    for chart in $INCLUDE_DEPENDENCY_CHARTS; do
        [ "$chart" = "$name" ] && return 0
    done
    return 1
}

# Diagnose a skopeo pull failure from captured stderr
# Usage: diagnose_pull_failure <error_file> <image_ref>
diagnose_pull_failure() {
    local err_file="$1"
    local image_ref="$2"
    local registry="${image_ref%%/*}"

    if grep -q "unauthorized\|authentication required\|denied\|401" "$err_file" 2>/dev/null; then
        echo "   ℹ You may need to authenticate: skopeo login $registry"
    elif grep -q "manifest unknown\|not found\|404" "$err_file" 2>/dev/null; then
        echo "   ℹ Image not found in registry. It may not have been published yet."
    elif [ -s "$err_file" ]; then
        echo "   ℹ $(cat "$err_file")"
    fi
}

# Extract image references matching REGISTRY_PATTERN from lines piped to stdin,
# and append them with a source annotation to the output file.
# Usage: grep ... | extract_matching_images <output_file> <annotation>
extract_matching_images() {
    local output="$1"
    local annotation="$2"

    grep -oE "(${REGISTRY_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" | \
        while IFS= read -r img; do
            echo "$img # ${annotation}" >> "$output"
        done || true
}

# Extract images from YAML files in a directory
# Recursively searches all .yaml files for image references matching configured
# registries with SHA256 digests, and appends them to the output file.
# Each line is annotated with the source file path as a comment.
# Usage: extract_images_from_dir <directory> <output_file> [<source_prefix>] [<path_base>]
extract_images_from_dir() {
    local dir="$1"
    local output="$2"
    local source_prefix="${3:-}"
    local path_base="${4:-$dir}"

    find "$dir" -name "*.yaml" -type f 2>/dev/null | while IFS= read -r file; do
        local rel_path="${file#$path_base/}"
        grep -E "(${REGISTRY_PATTERN})/" "$file" 2>/dev/null | \
            extract_matching_images "$output" "${source_prefix}${rel_path}"
    done || true
}

# Extract version-filtered images from the Sail Operator chart.
# Parses the pinned Istio version from istio.yaml, then extracts only
# the operator image and matching version annotations from the deployment.
# Exits with an error if required files are missing (unless SAIL_OPERATOR_VERSION=all).
# Each line is annotated with the source file path as a comment.
# Usage: extract_sail_operator_images <sail_operator_chart_dir> <output_file> [<source_prefix>] [<path_base>]
extract_sail_operator_images() {
    local sail_dir="$1"
    local output="$2"
    local source_prefix="${3:-}"
    local path_base="${4:-$sail_dir}"

    local version_key=""
    if [ "$SAIL_OPERATOR_VERSION" = "all" ]; then
        echo "   Sail Operator: filtering disabled (SAIL_OPERATOR_VERSION=all)"
        extract_images_from_dir "$sail_dir" "$output" "$source_prefix" "$path_base"
        return
    elif [ -n "$SAIL_OPERATOR_VERSION" ]; then
        local pinned_version="$SAIL_OPERATOR_VERSION"
        local stripped="${pinned_version%-latest}"
        version_key="${stripped//./_}"
        echo "   Sail Operator: using override version $pinned_version (${version_key}_*)"
    else
        local istio_file="$sail_dir/templates/istio.yaml"
        if [ ! -f "$istio_file" ]; then
            echo "   ✗ No istio.yaml found in Sail Operator chart"
            exit 1
        fi

        # istio.yaml is a Helm template — parse the version field from non-templated lines
        local pinned_version=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]+version:[[:space:]]+(.*) ]]; then
                pinned_version="${BASH_REMATCH[1]}"
                pinned_version="${pinned_version%"${pinned_version##*[![:space:]]}"}"
                break
            fi
        done < "$istio_file"

        if [ -z "$pinned_version" ]; then
            echo "   ✗ Could not parse spec.version from istio.yaml"
            exit 1
        fi

        local stripped="${pinned_version%-latest}"
        version_key="${stripped//./_}"
        echo "   Sail Operator: pinned Istio version $pinned_version (filtering for ${version_key}_*)"
    fi

    local deployment_file
    deployment_file=$(find "$sail_dir/templates" -name "deployment-servicemesh-operator*.yaml" -type f 2>/dev/null | head -1)
    if [ -z "$deployment_file" ]; then
        echo "   ✗ No deployment manifest found in Sail Operator chart"
        exit 1
    fi

    local rel_path="${deployment_file#$path_base/}"
    local annotation="${source_prefix}${rel_path}"

    grep -E '^\s+image:\s+' "$deployment_file" | \
        extract_matching_images "$output" "$annotation"

    grep "images\.${version_key}_" "$deployment_file" | \
        extract_matching_images "$output" "$annotation"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# ============================================================================
# INPUT PARSING — resolve to (CHART_REPOSITORY, CHART_TAG) pair
# ============================================================================

INPUT="${1:-}"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <VERSION | IMAGE_REFERENCE>"
    echo ""
    echo "  VERSION:    X.Y.Z or X.Y.Z-ea.N (e.g., 3.4.0, 3.5.1, 3.4.0-ea.1)"
    echo "              An optional \"v\" prefix is stripped automatically."
    echo "  IMAGE_REF:  Full image reference with tag or digest"
    echo "              e.g., registry.redhat.io/rhai/rhai-on-xks-chart:v3.5.0"
    echo "              e.g., quay.io/rhoai/rhai-on-xks-chart@sha256:abc123..."
    exit 1
fi

# Detect input type: image reference (contains /) vs version string
DIRECT_REF=false
FALLBACK_REFS=()

if [[ "$INPUT" == */* ]]; then
    # Image reference input
    DIRECT_REF=true

    if [[ "$INPUT" != *:* ]] && [[ "$INPUT" != *@sha256:* ]]; then
        echo "Error: Image reference must include a tag (:tag) or digest (@sha256:...)"
        exit 1
    fi
    if [[ "$INPUT" != ${GA_CHART_REPOSITORY}* ]] && [[ "$INPUT" != ${DEV_CHART_REPOSITORY}* ]]; then
        echo "Error: Image reference must be from a known chart repository:"
        echo "  - $GA_CHART_REPOSITORY"
        echo "  - $DEV_CHART_REPOSITORY"
        exit 1
    fi

    if [[ "$INPUT" == *@sha256:* ]]; then
        CHART_REPOSITORY="${INPUT%%@*}"
        CHART_TAG="${INPUT#*@}"
    else
        CHART_REPOSITORY="${INPUT%:*}"
        CHART_TAG="${INPUT##*:}"
    fi
else
    # Version string input
    VERSION="${INPUT#v}"

    RHOAI_GA_VERSION_REGEX="^[0-9]\.[0-9]{1,2}\.[0-9]{1,2}$"
    RHOAI_EA_VERSION_REGEX="^[0-9]\.[0-9]{1,2}\.[0-9]{1,2}-ea\.[0-9]+$"

    if [[ ! "$VERSION" =~ $RHOAI_GA_VERSION_REGEX ]] && [[ ! "$VERSION" =~ $RHOAI_EA_VERSION_REGEX ]]; then
        echo "Error: Invalid version format: $INPUT"
        echo "Version must be of the form X.Y.Z or X.Y.Z-ea.N (e.g., 3.4.0, 3.5.1, 3.4.0-ea.1)"
        exit 1
    fi

    MAJOR_VERSION="${VERSION%%.*}"
    local_rest="${VERSION#*.}"
    MINOR_VERSION="${local_rest%%.*}"
    local_micro_rest="${local_rest#*.}"
    MICRO_VERSION="${local_micro_rest%%-*}"
    EA_SUFFIX=""
    if [[ "$VERSION" == *-ea.* ]]; then
        EA_SUFFIX="-${VERSION#*-}"
    fi

    case "$BUILD_TYPE" in
        ga)
            CHART_REPOSITORY="$GA_CHART_REPOSITORY"
            CHART_TAG="v${VERSION}"
            FALLBACK_REFS=("${DEV_CHART_REPOSITORY}:rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}-nightly")
            ;;
        ci)
            CHART_REPOSITORY="$DEV_CHART_REPOSITORY"
            CHART_TAG="rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}"
            ;;
        nightly)
            CHART_REPOSITORY="$DEV_CHART_REPOSITORY"
            CHART_TAG="rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}-nightly"
            ;;
        *)
            echo "Error: Invalid BUILD_TYPE '$BUILD_TYPE' (must be ga, nightly, or ci)"
            exit 1
            ;;
    esac
fi

echo "=========================================================================="
echo "Preparing disconnected install helper file for RHAI on XKS Helm Chart"
echo "=========================================================================="
echo ""
if [ "$DIRECT_REF" = true ]; then
    echo "Image reference:     $INPUT"
else
    echo "Version:             $VERSION"
    echo "  Major:             $MAJOR_VERSION"
    echo "  Minor:             $MINOR_VERSION"
    echo "  Micro:             $MICRO_VERSION"
    [ -n "$EA_SUFFIX" ] && echo "  EA suffix:         $EA_SUFFIX"
fi
echo ""
echo "Configuration:"
echo "  Registries:        $REGISTRIES"
echo "  Operator pattern:  $OPERATOR_IMAGE_PATTERN"
[ -n "$SAIL_OPERATOR_VERSION" ] && echo "  Sail version:      $SAIL_OPERATOR_VERSION (override)"
echo "  Dep charts:        $INCLUDE_DEPENDENCY_CHARTS"
echo ""

# ============================================================================
# WORK DIRECTORY SETUP
# ============================================================================

WORK_DIR="$(pwd)/.${CHART_NAME}-work"
IMAGES_RAW="${WORK_DIR}/.images"

if [ -d "$WORK_DIR" ]; then
    chmod -R +w "$WORK_DIR" 2>/dev/null
    rm -rf "$WORK_DIR"
fi
mkdir -p "$WORK_DIR/chart/oci" "$WORK_DIR/chart/extracted" "$WORK_DIR/operator/oci" "$WORK_DIR/operator/extracted"

# ============================================================================
# CHART PULL
# ============================================================================

# Pull a chart OCI artifact by repo and tag/digest, extract digest and chart .tgz.
# Usage: try_pull_chart <repo> <tag> <label>
try_pull_chart() {
    local repo="$1"
    local tag="$2"
    local label="$3"

    local separator=":"
    if [[ "$tag" == sha256:* ]]; then
        separator="@"
    fi

    local ref="${repo}${separator}${tag}"
    local oci_dir="$WORK_DIR/chart/oci"
    rm -rf "$oci_dir"
    mkdir -p "$oci_dir"

    echo "   Trying $label: $ref"

    if ! skopeo copy --quiet "docker://${ref}" "oci:${oci_dir}:${tag}" 2>"$WORK_DIR/.skopeo-err"; then
        return 1
    fi

    CHART_REPO="$repo"
    CHART_DIGEST=$(jq -r '.manifests[0].digest' "$oci_dir/index.json")

    if [ -n "$CHART_DIGEST" ] && [ "$CHART_DIGEST" != "null" ]; then
        local manifest_file="$oci_dir/blobs/sha256/${CHART_DIGEST#sha256:}"
        local chart_blob
        chart_blob=$(jq -r '.layers[0].digest' "$manifest_file")
        if [ -n "$chart_blob" ] && [ "$chart_blob" != "null" ]; then
            cp "$oci_dir/blobs/sha256/${chart_blob#sha256:}" "$WORK_DIR/chart/chart.tgz"
        fi
    fi

    echo "   ✓ Pulled: $ref"
    [ -n "$CHART_DIGEST" ] && [ "$CHART_DIGEST" != "null" ] && echo "   Digest: $CHART_DIGEST"
    return 0
}

cd "$WORK_DIR"

echo "1. Pulling chart..."

CHART_DIGEST=""
CHART_REPO=""

if [ "$DIRECT_REF" = true ]; then
    PULL_LABEL="direct"
else
    PULL_LABEL="$BUILD_TYPE"
fi

if ! try_pull_chart "$CHART_REPOSITORY" "$CHART_TAG" "$PULL_LABEL"; then
    echo "   ⚠ Not found"
    PULLED=false
    for fallback in "${FALLBACK_REFS[@]}"; do
        fallback_repo="${fallback%:*}"
        fallback_tag="${fallback##*:}"
        if try_pull_chart "$fallback_repo" "$fallback_tag" "fallback"; then
            PULLED=true
            break
        fi
    done
    if [ "$PULLED" = false ]; then
        echo "   ✗ Chart not found"
        if [ "$DIRECT_REF" = true ]; then
            echo "   Tried: $INPUT"
        else
            echo "   Tried: ${CHART_REPOSITORY}:${CHART_TAG}"
            for fallback in "${FALLBACK_REFS[@]}"; do
                echo "          $fallback"
            done
        fi
        diagnose_pull_failure "$WORK_DIR/.skopeo-err" "$CHART_REPOSITORY"
        exit 1
    fi
fi
echo ""

# --------------------------------------------------------------------------
# Step 2: Add the helm chart OCI image reference to the list
# --------------------------------------------------------------------------
echo "2. Adding chart image reference to list..."
if [ -n "$CHART_DIGEST" ] && [ "$CHART_DIGEST" != "null" ]; then
    echo "   ${GA_CHART_REPOSITORY}@${CHART_DIGEST}"
    echo "${GA_CHART_REPOSITORY}@${CHART_DIGEST} # chart-oci" >> "$IMAGES_RAW"
else
    echo "   ✗ Could not resolve chart digest from OCI layout"
    exit 1
fi
echo ""

# --------------------------------------------------------------------------
# Step 3: Extract the chart locally
# --------------------------------------------------------------------------
echo "3. Extracting chart locally..."

CHART_FILE="$WORK_DIR/chart/chart.tgz"
if [ ! -f "$CHART_FILE" ]; then
    echo "   ✗ No .tgz file found after chart pull"
    exit 1
fi
tar -xzf "$CHART_FILE" -C "$WORK_DIR/chart/extracted"
CHART_DIR=$(find "$WORK_DIR/chart/extracted" -mindepth 1 -maxdepth 1 -type d | head -1)
if [ -z "$CHART_DIR" ]; then
    echo "   ✗ No chart directory found after extraction"
    exit 1
fi
echo "   ✓ Chart extracted: $(basename "$CHART_DIR")"

# For direct image reference input, extract version from Chart.yaml
if [ "$DIRECT_REF" = true ]; then
    VERSION=$(yq '.version' "$CHART_DIR/Chart.yaml")
    VERSION="${VERSION#v}"
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
        echo "   ✗ Could not determine version from Chart.yaml"
        exit 1
    fi
    echo "   Version from Chart.yaml: $VERSION"
fi

if [ -z "$OUTPUT_FILENAME" ]; then
    OUTPUT_FILENAME="${CHART_NAME}-${VERSION}.yaml"
fi
OUTPUT_PATH="${REPO_ROOT}/${OUTPUT_DIR}/${OUTPUT_FILENAME}"
mkdir -p "$(dirname "$OUTPUT_PATH")"
echo "   Output: $OUTPUT_PATH"
echo ""

# --------------------------------------------------------------------------
# Step 4: Extract images from chart YAML files
# --------------------------------------------------------------------------
echo "4. Extracting images from chart YAML files..."
BEFORE_CHART=$(wc -l < "$IMAGES_RAW")
extract_images_from_dir "$CHART_DIR" "$IMAGES_RAW" "" "$WORK_DIR/chart/extracted"
AFTER_CHART=$(wc -l < "$IMAGES_RAW")
MAIN_CHART_COUNT=$((AFTER_CHART - BEFORE_CHART))
echo "   ✓ Found $MAIN_CHART_COUNT images"
echo ""

# --------------------------------------------------------------------------
# Step 5: Identify the operator image
# --------------------------------------------------------------------------
echo "5. Identifying operator image (pattern: $OPERATOR_IMAGE_PATTERN)..."
OPERATOR_IMAGE=$(yq -r ".. | select(tag == \"!!str\" and test(\"${OPERATOR_IMAGE_PATTERN}\") and test(\"@sha256:\"))" "$CHART_DIR/values.yaml" | head -1)
if [ -z "$OPERATOR_IMAGE" ] || [ "$OPERATOR_IMAGE" = "null" ]; then
    echo "   ✗ Could not find operator image matching '$OPERATOR_IMAGE_PATTERN' in $CHART_DIR/values.yaml"
    exit 1
fi
echo "   ✓ Found: $OPERATOR_IMAGE"
echo ""

# --------------------------------------------------------------------------
# Step 6: Pull operator image and extract dependency charts
# --------------------------------------------------------------------------
echo "6. Pulling operator image..."

OPERATOR_DIR="$WORK_DIR/operator/oci"
OPERATOR_EXTRACTED="$WORK_DIR/operator/extracted"

IS_GA=true
[[ "$CHART_REPO" != "$GA_CHART_REPOSITORY" ]] && IS_GA=false

OPERATOR_PULLED=false
echo "   Trying ga: $OPERATOR_IMAGE"
if skopeo copy --quiet --override-os linux --override-arch amd64 "docker://$OPERATOR_IMAGE" "dir:$OPERATOR_DIR" 2>"$WORK_DIR/.skopeo-err"; then
    OPERATOR_PULLED=true
    echo "   ✓ Pulled: $OPERATOR_IMAGE"
else
    echo "   ⚠ Not found"
fi

if [ "$OPERATOR_PULLED" = false ] && [ "$IS_GA" = false ]; then
    DEV_OPERATOR_IMAGE="${OPERATOR_IMAGE/registry.redhat.io/quay.io}"
    echo "   Trying fallback: $DEV_OPERATOR_IMAGE"
    rm -rf "$OPERATOR_DIR"
    mkdir -p "$OPERATOR_DIR"
    if skopeo copy --quiet --override-os linux --override-arch amd64 "docker://$DEV_OPERATOR_IMAGE" "dir:$OPERATOR_DIR" 2>"$WORK_DIR/.skopeo-err"; then
        OPERATOR_PULLED=true
        echo "   ✓ Pulled: $DEV_OPERATOR_IMAGE"
    fi
fi

if [ "$OPERATOR_PULLED" = false ]; then
    echo "   ✗ Failed to pull operator image"
    diagnose_pull_failure "$WORK_DIR/.skopeo-err" "$OPERATOR_IMAGE"
    exit 1
fi

OPERATOR_NAME="${OPERATOR_IMAGE##*/}"
OPERATOR_NAME="${OPERATOR_NAME%%@*}"

if [ -z "$INCLUDE_DEPENDENCY_CHARTS" ]; then
    echo "   Skipping dependency chart extraction (INCLUDE_DEPENDENCY_CHARTS is empty)"
    echo ""
    echo "7. Skipped - dependency chart extraction disabled"
    DEP_COUNT=0
else
    echo "   Extracting dependency charts from /opt/charts/..."

    jq -r '.layers[].digest' "$OPERATOR_DIR/manifest.json" | while IFS= read -r layer_digest; do
        local_blob="$OPERATOR_DIR/${layer_digest#sha256:}"
        if [ -f "$local_blob" ]; then
            tar -xzf "$local_blob" -C "$OPERATOR_EXTRACTED" --include='opt/charts/*' 2>/dev/null || true
        fi
    done

    if [ -d "$OPERATOR_EXTRACTED/opt/charts" ]; then
        echo "   ✓ Found dependency charts:"
        for chart_dir in "$OPERATOR_EXTRACTED/opt/charts"/*/; do
            chart_name="$(basename "$chart_dir")"
            if should_process_chart "$chart_name"; then
                echo "      - $chart_name"
            else
                echo "      - $chart_name (skipped)"
            fi
        done
        echo ""

        # ------------------------------------------------------------------
        # Step 7: Extract images from dependency chart YAML files
        # ------------------------------------------------------------------
        echo "7. Extracting images from dependency chart YAML files..."
        BEFORE_DEP=$(wc -l < "$IMAGES_RAW" | tr -d ' ')

        for chart_dir in "$OPERATOR_EXTRACTED/opt/charts"/*/; do
            chart_name="$(basename "$chart_dir")"
            if ! should_process_chart "$chart_name"; then
                echo "   Skipping $chart_name (not in INCLUDE_DEPENDENCY_CHARTS)"
                continue
            fi
            BEFORE_CHART_DEP=$(wc -l < "$IMAGES_RAW" | tr -d ' ')
            if [ "$chart_name" = "sail-operator" ]; then
                echo "   Processing $chart_name (version-filtered)..."
                extract_sail_operator_images "$chart_dir" "$IMAGES_RAW" "${OPERATOR_NAME}:" "$OPERATOR_EXTRACTED"
            else
                echo "   Processing $chart_name..."
                extract_images_from_dir "$chart_dir" "$IMAGES_RAW" "${OPERATOR_NAME}:" "$OPERATOR_EXTRACTED"
            fi
            AFTER_CHART_DEP=$(wc -l < "$IMAGES_RAW" | tr -d ' ')
            CHART_DEP_COUNT=$((AFTER_CHART_DEP - BEFORE_CHART_DEP))
            echo "   ✓ $chart_name: $CHART_DEP_COUNT images"
        done

        AFTER_DEP=$(wc -l < "$IMAGES_RAW" | tr -d ' ')
        DEP_COUNT=$((AFTER_DEP - BEFORE_DEP))
        echo "   Total: $DEP_COUNT dependency images"
    else
        echo "   ⚠ No /opt/charts/ found in operator image"
        echo "7. Skipped - no dependency charts found"
        DEP_COUNT=0
    fi
fi

# ============================================================================
# DEDUPLICATION AND OUTPUT
# ============================================================================

echo ""
echo "Processing and deduplicating..."

# Strip annotations and deduplicate
while IFS= read -r line; do
    echo "${line%% #*}"
done < "$IMAGES_RAW" | sort -u | grep -E '@sha256:' > "${WORK_DIR}/.images.final"

TOTAL=$(wc -l < "${WORK_DIR}/.images.final" | tr -d ' ')

echo ""
echo "=========================================================================="
echo "Extraction Complete - Found $TOTAL unique images"
echo "=========================================================================="
echo ""

# Create output file
cat > "$OUTPUT_PATH" << HEADER
# Skopeo sync configuration (auto-generated)
#
# Prerequisites:
#   skopeo login registry.redhat.io
#   skopeo login YOUR_REGISTRY
#
# Usage:
#   skopeo sync --src yaml --dest docker $OUTPUT_FILENAME YOUR_REGISTRY

HEADER

# Group images by registry and repository
while IFS= read -r registry; do
    echo "${registry}:" >> "$OUTPUT_PATH"
    echo "  images:" >> "$OUTPUT_PATH"

    grep "^${registry}/" "${WORK_DIR}/.images.final" | sort -u | while IFS= read -r img; do
        if [[ $img =~ ^([^/]+)/(.+)@(sha256:[a-f0-9]{64})$ ]]; then
            echo "${BASH_REMATCH[2]}|${BASH_REMATCH[3]}"
        fi
    done | sort | \
    awk -F'|' '
    {
        repo = $1
        digest = $2
        if (repo != prev_repo) {
            if (prev_repo != "") {
                for (i = 1; i <= digest_count; i++) {
                    print "      - \"" digests[i] "\""
                }
            }
            print "    " repo ":"
            prev_repo = repo
            digest_count = 0
        }
        digest_count++
        digests[digest_count] = digest
    }
    END {
        if (prev_repo != "") {
            for (i = 1; i <= digest_count; i++) {
                print "      - \"" digests[i] "\""
            }
        }
    }' >> "$OUTPUT_PATH"
done < <(cut -d'/' -f1 "${WORK_DIR}/.images.final" | sort -u)

echo "Image Breakdown:"
printf "  • %-28s %d image\n" "Helm chart (OCI artifact):" 1
printf "  • %-28s %d images\n" "$(basename "$CHART_DIR"):" "$MAIN_CHART_COUNT"
if [ -n "$INCLUDE_DEPENDENCY_CHARTS" ] && [ -d "$OPERATOR_EXTRACTED/opt/charts" ]; then
    for chart_dir in "$OPERATOR_EXTRACTED/opt/charts"/*/; do
        chart_name="$(basename "$chart_dir")"
        should_process_chart "$chart_name" || continue
        count=$(grep -c "# ${OPERATOR_NAME}:opt/charts/${chart_name}/" "$IMAGES_RAW" || true)
        [ "$count" -gt 0 ] && printf "  • %-28s %d images\n" "${chart_name}:" "$count"
    done
fi
echo ""
echo "Generated: $OUTPUT_PATH"
echo ""
echo "=========================================================================="
echo "Next Steps"
echo "=========================================================================="
echo ""
echo "Mirror all images to your private registry:"
echo ""
echo "  skopeo login registry.redhat.io"
echo "  skopeo login YOUR_REGISTRY"
echo "  skopeo sync --src yaml --dest docker $OUTPUT_FILENAME YOUR_REGISTRY"
echo ""
echo "=========================================================================="

# Write version to a file for CI consumption
echo "$VERSION" > "${WORK_DIR}/.version"
