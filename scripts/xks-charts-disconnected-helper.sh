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
#
# Examples with environment variables:
#   REGISTRIES="registry.redhat.io" ./xks-charts-disconnected-helper.sh 3.5.0
#   OUTPUT_FILENAME="images.yaml" ./xks-charts-disconnected-helper.sh 3.5.0
#   OPERATOR_IMAGE_PATTERN="my-operator" ./xks-charts-disconnected-helper.sh 3.5.0
#   SAIL_OPERATOR_VERSION="v1.26" ./xks-charts-disconnected-helper.sh 3.5.0
#   BUILD_TYPE="nightly" ./xks-charts-disconnected-helper.sh 3.5.0
#   BUILD_TYPE="ci" ./xks-charts-disconnected-helper.sh 3.5.0-ea.1

set -euo pipefail

# ============================================================================
# CONSTANTS
# ============================================================================

GA_CHART_REPOSITORY="${GA_CHART_REPOSITORY:-registry.redhat.io/rhai/rhai-on-xks-chart}"
DEV_CHART_REPOSITORY="${DEV_CHART_REPOSITORY:-quay.io/rhoai/rhai-on-xks-chart}"

# Derive chart name from GA repository (e.g. "rhai-on-xks-chart")
CHART_NAME="$(basename "$GA_CHART_REPOSITORY")"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Resolve repo root (for output directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Registries to extract (space-separated)
REGISTRIES="${REGISTRIES:-registry.redhat.io registry.access.redhat.com}"

# Output directory and file (default derived from version after parsing)
OUTPUT_DIR="${OUTPUT_DIR:-charts}"
OUTPUT_FILENAME="${OUTPUT_FILENAME:-}"

# Pattern to identify the operator image in values.yaml
OPERATOR_IMAGE_PATTERN="${OPERATOR_IMAGE_PATTERN:-odh-rhel9-operator}"

# Override Sail Operator Istio version filtering (auto-detected from chart if not set)
# Set to "all" to disable filtering and include all Istio versions
SAIL_OPERATOR_VERSION="${SAIL_OPERATOR_VERSION:-}"

# Build type: "ga" (default), "nightly", or "ci"
#   ga      - Try GA registry first, fall back to dev nightly
#   nightly - Use dev registry nightly build directly
#   ci      - Use dev registry CI build directly
BUILD_TYPE="${BUILD_TYPE:-ga}"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Build grep patterns from REGISTRIES into global variables:
#   GREP_PATTERN — BRE pattern for initial grep (uses \| alternation)
#   REGEX_PATTERN — ERE pattern for grep -oE extraction (uses | alternation, dots escaped)
build_registry_pattern() {
    GREP_PATTERN=""
    REGEX_PATTERN=""
    for reg in $REGISTRIES; do
        local escaped_reg=$(echo "$reg" | sed 's/\./\\./g')
        if [ -n "$GREP_PATTERN" ]; then
            GREP_PATTERN="${GREP_PATTERN}\|${reg}"
            REGEX_PATTERN="${REGEX_PATTERN}|${escaped_reg}"
        else
            GREP_PATTERN="$reg"
            REGEX_PATTERN="$escaped_reg"
        fi
    done
}

# Extract images from YAML files in a directory
# Recursively searches all .yaml files for image references matching configured
# registries with SHA256 digests, and appends them to the output file.
# Usage: extract_images_from_dir <directory> <output_file>
extract_images_from_dir() {
    local dir="$1"
    local output="$2"

    build_registry_pattern

    grep -rh "$GREP_PATTERN" "$dir" \
        --include="*.yaml" 2>/dev/null | \
        grep -oE "(${REGEX_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" \
        >> "$output" || true
}

# Extract version-filtered images from the Sail Operator chart.
# Parses the pinned Istio version from istio.yaml, then extracts only
# the operator image and matching version annotations from the deployment.
# Falls back to extract_images_from_dir if required files are missing.
# Usage: extract_sail_operator_images <sail_operator_chart_dir> <output_file>
extract_sail_operator_images() {
    local sail_dir="$1"
    local output="$2"

    build_registry_pattern

    # Determine the Istio version to filter for
    local version_key=""
    if [ "$SAIL_OPERATOR_VERSION" = "all" ]; then
        echo "   Sail Operator: filtering disabled (SAIL_OPERATOR_VERSION=all)"
        extract_images_from_dir "$sail_dir" "$output"
        return
    elif [ -n "$SAIL_OPERATOR_VERSION" ]; then
        local pinned_version="$SAIL_OPERATOR_VERSION"
        version_key=$(echo "$pinned_version" | sed 's/-latest$//' | sed 's/\./_/g')
        echo "   Sail Operator: using override version $pinned_version (${version_key}_*)"
    else
        # Auto-detect from istio.yaml
        local istio_file="$sail_dir/templates/istio.yaml"
        if [ ! -f "$istio_file" ]; then
            echo "   ⚠ No istio.yaml found in Sail Operator chart; extracting all images"
            extract_images_from_dir "$sail_dir" "$output"
            return
        fi

        local pinned_version
        pinned_version=$(grep -E '^\s+version:\s+' "$istio_file" | sed 's/.*version:[[:space:]]*//' | sed 's/[[:space:]]*$//' | head -1)
        if [ -z "$pinned_version" ]; then
            echo "   ⚠ Could not parse spec.version from istio.yaml; extracting all images"
            extract_images_from_dir "$sail_dir" "$output"
            return
        fi

        version_key=$(echo "$pinned_version" | sed 's/-latest$//' | sed 's/\./_/g')
        echo "   Sail Operator: pinned Istio version $pinned_version (filtering for ${version_key}_*)"
    fi

    # Find the deployment manifest
    local deployment_file
    deployment_file=$(find "$sail_dir/templates" -name "deployment-servicemesh-operator*.yaml" -type f 2>/dev/null | head -1)
    if [ -z "$deployment_file" ]; then
        echo "   ⚠ No deployment manifest found in Sail Operator chart; extracting all images"
        extract_images_from_dir "$sail_dir" "$output"
        return
    fi

    # Extract the operator image from spec.containers[].image
    grep -E '^\s+image:\s+' "$deployment_file" | \
        grep -oE "(${REGEX_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" \
        >> "$output" || true

    # Extract only annotation images matching the pinned version
    grep "images\.${version_key}_" "$deployment_file" | \
        grep -oE "(${REGEX_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" \
        >> "$output" || true
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# ============================================================================
# INPUT PARSING
# ============================================================================

INPUT="${1:-}"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <VERSION | IMAGE_REFERENCE>"
    echo ""
    echo "  VERSION:    X.Y.Z or X.Y.Z-ea.N (e.g., 3.4.0, 3.5.1, 3.4.0-ea.1)"
    echo "              An optional \"v\" prefix is stripped automatically."
    echo "  IMAGE_REF:  Full image reference with tag or digest"
    echo "              e.g., registry.redhat.io/rhai/rhai-on-xks-chart:v3.4.2"
    echo "              e.g., quay.io/rhoai/rhai-on-xks-chart@sha256:abc123..."
    exit 1
fi

# Detect input type: image reference (contains /) vs version string
DIRECT_REF=false
if [[ "$INPUT" == */* ]]; then
    DIRECT_REF=true
fi

if [ "$DIRECT_REF" = true ]; then
    CHART_REF_INPUT="$INPUT"
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
else
    VERSION="${INPUT#v}"

    RHOAI_GA_VERSION_REGEX="^[0-9]\.[0-9]{1,2}\.[0-9]{1,2}$"
    RHOAI_EA_VERSION_REGEX="^[0-9]\.[0-9]{1,2}\.[0-9]{1,2}-ea\.[0-9]+$"

    if [[ ! "$VERSION" =~ $RHOAI_GA_VERSION_REGEX ]] && [[ ! "$VERSION" =~ $RHOAI_EA_VERSION_REGEX ]]; then
        echo "Error: Invalid version format: $INPUT"
        echo "Version must be of the form X.Y.Z or X.Y.Z-ea.N (e.g., 3.4.0, 3.5.1, 3.4.0-ea.1)"
        exit 1
    fi

    MAJOR_VERSION=$(echo "$VERSION" | cut -d'.' -f1)
    MINOR_VERSION=$(echo "$VERSION" | cut -d'.' -f2)
    MICRO_VERSION=$(echo "$VERSION" | cut -d'.' -f3 | sed 's/-.*//')
    EA_SUFFIX=""
    if [[ "$VERSION" == *-ea.* ]]; then
        EA_SUFFIX=$(echo "$VERSION" | sed 's/^[0-9]*\.[0-9]*\.[0-9]*//')
    fi
fi

# parse_version_from_manifest: extract org.opencontainers.image.version from OCI manifest
# Sets VERSION (stripped of v prefix) from the manifest annotations
parse_version_from_manifest() {
    local oci_dir="$WORK_DIR/.chart-oci"
    local manifest_digest
    manifest_digest=$(grep -oE 'sha256:[a-f0-9]{64}' "$oci_dir/index.json" 2>/dev/null | head -1)
    if [ -n "$manifest_digest" ]; then
        local manifest_file="$oci_dir/blobs/sha256/${manifest_digest#sha256:}"
        local oci_version
        oci_version=$(grep -oE '"org\.opencontainers\.image\.version"\s*:\s*"[^"]*"' "$manifest_file" 2>/dev/null | sed 's/.*"org.opencontainers.image.version"\s*:\s*"//' | sed 's/"//')
        if [ -n "$oci_version" ]; then
            VERSION="${oci_version#v}"
        fi
    fi
}

echo "=========================================================================="
echo "Preparing disconnected install helper file for RHAI on XKS Helm Chart"
echo "=========================================================================="
echo ""
if [ "$DIRECT_REF" = true ]; then
    echo "Image reference:     $CHART_REF_INPUT"
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
echo ""

# ============================================================================
# CHART PULL
# ============================================================================

WORK_DIR="$(pwd)/.${CHART_NAME}-work"
# .images      — raw collected image references (appended to by each extraction step)
# .images.final — deduplicated and filtered (only @sha256: refs), used to generate output
IMAGES_RAW="${WORK_DIR}/.images"

if [ -d "$WORK_DIR" ]; then
    chmod -R +w "$WORK_DIR" 2>/dev/null
    rm -rf "$WORK_DIR"
fi
mkdir -p "$WORK_DIR"

# try_pull_chart: attempt to pull a chart by repo and tag/digest using skopeo, return 0 on success
# Downloads as OCI layout, extracts the chart .tgz from the blob layers
try_pull_chart() {
    local repo="$1"
    local tag="$2"
    local label="$3"

    # Use @ separator for digests, : for tags
    local separator=":"
    if [[ "$tag" == sha256:* ]]; then
        separator="@"
    fi

    echo "   Trying $label: ${repo}${separator}${tag}"

    local oci_dir="$WORK_DIR/.chart-oci"
    rm -rf "$oci_dir"
    mkdir -p "$oci_dir"

    if ! skopeo copy "docker://${repo}${separator}${tag}" "oci:${oci_dir}:${tag}" 2>/dev/null; then
        return 1
    fi

    CHART_REF="${repo}${separator}${tag}"
    CHART_REPO="$repo"

    # Extract digest and chart .tgz from OCI layout
    # index.json has the manifest digest; the manifest lists the chart blob
    local manifest_digest
    manifest_digest=$(grep -oE 'sha256:[a-f0-9]{64}' "$oci_dir/index.json" | head -1)
    CHART_DIGEST="$manifest_digest"
    if [ -n "$manifest_digest" ]; then
        local chart_blob
        chart_blob=$(grep -oE 'sha256:[a-f0-9]{64}' "$oci_dir/blobs/sha256/${manifest_digest#sha256:}" | tail -1)
        if [ -n "$chart_blob" ]; then
            cp "$oci_dir/blobs/sha256/${chart_blob#sha256:}" "$WORK_DIR/chart.tgz"
        fi
    fi

    echo "   ✓ Pulled: $CHART_REF"
    [ -n "$CHART_DIGEST" ] && echo "   Digest: $CHART_DIGEST"
    return 0
}

cd "$WORK_DIR"

if [ "$DIRECT_REF" = true ]; then
    echo "1. Pulling chart (direct reference)..."

    if [[ "$CHART_REF_INPUT" == *@sha256:* ]]; then
        CHART_REPOSITORY="${CHART_REF_INPUT%%@*}"
        CHART_TAG="${CHART_REF_INPUT#*@}"
    else
        CHART_REPOSITORY="${CHART_REF_INPUT%:*}"
        CHART_TAG="${CHART_REF_INPUT##*:}"
    fi

    try_pull_chart "$CHART_REPOSITORY" "$CHART_TAG" "direct" || {
        echo "   ✗ Chart not found: $CHART_REF_INPUT"
        exit 1
    }

    # Extract version from OCI manifest annotation
    parse_version_from_manifest
    if [ -z "${VERSION:-}" ]; then
        echo "   ✗ Could not determine version from chart manifest"
        exit 1
    fi
    echo "   Version from manifest: $VERSION"

else
    case "$BUILD_TYPE" in
        ga)      CHART_REPOSITORY="$GA_CHART_REPOSITORY";  CHART_TAG="v${VERSION}" ;;
        ci)      CHART_REPOSITORY="$DEV_CHART_REPOSITORY"; CHART_TAG="rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}" ;;
        nightly) CHART_REPOSITORY="$DEV_CHART_REPOSITORY"; CHART_TAG="rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}-nightly" ;;
        *)
            echo "Error: Invalid BUILD_TYPE '$BUILD_TYPE' (must be ga, nightly, or ci)"
            exit 1
            ;;
    esac

    echo "1. Pulling chart (build_type=$BUILD_TYPE)..."

    if [ "$BUILD_TYPE" = "ga" ]; then
        try_pull_chart "$CHART_REPOSITORY" "$CHART_TAG" "GA registry" || {
            FALLBACK_TAG="rhoai-${MAJOR_VERSION}.${MINOR_VERSION}${EA_SUFFIX}-nightly"
            try_pull_chart "$DEV_CHART_REPOSITORY" "$FALLBACK_TAG" "dev nightly" || {
                echo "   ✗ Chart not found"
                echo "   Tried: ${GA_CHART_REPOSITORY}:${CHART_TAG}"
                echo "          ${DEV_CHART_REPOSITORY}:${FALLBACK_TAG}"
                exit 1
            }
        }
    else
        try_pull_chart "$CHART_REPOSITORY" "$CHART_TAG" "dev $BUILD_TYPE" || {
            echo "   ✗ Chart not found: ${CHART_REPOSITORY}:${CHART_TAG}"
            exit 1
        }
    fi
fi

# Set output filename and path now that VERSION is known
if [ -z "$OUTPUT_FILENAME" ]; then
    OUTPUT_FILENAME="${CHART_NAME}-${VERSION}.yaml"
fi
OUTPUT_PATH="${REPO_ROOT}/${OUTPUT_DIR}/${OUTPUT_FILENAME}"
mkdir -p "$(dirname "$OUTPUT_PATH")"
echo "   Output: $OUTPUT_PATH"
echo ""

# --------------------------------------------------------------------------
# Step 2: Add the helm chart OCI image reference to the list
# --------------------------------------------------------------------------
echo "2. Adding chart image reference to list..."
if [ -n "$CHART_DIGEST" ]; then
    echo "   ${GA_CHART_REPOSITORY}@${CHART_DIGEST}"
    echo "${GA_CHART_REPOSITORY}@${CHART_DIGEST}" >> "$IMAGES_RAW"
else
    echo "   ✗ Could not resolve chart digest from OCI layout"
    exit 1
fi
echo ""

# --------------------------------------------------------------------------
# Step 3: Extract the chart locally
# --------------------------------------------------------------------------
echo "3. Extracting chart locally..."

CHART_FILE=$(ls "$WORK_DIR"/*.tgz 2>/dev/null | head -1)
if [ -z "$CHART_FILE" ]; then
    echo "   ✗ No .tgz file found after chart pull"
    exit 1
fi
tar -xzf "$CHART_FILE" -C "$WORK_DIR"
CHART_DIR=$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | head -1)
if [ -z "$CHART_DIR" ]; then
    echo "   ✗ No chart directory found after extraction"
    exit 1
fi
echo "   ✓ Chart extracted: $(basename "$CHART_DIR")"
echo ""

# --------------------------------------------------------------------------
# Step 4: Extract images from chart YAML files
# --------------------------------------------------------------------------
echo "4. Extracting images from chart YAML files..."
extract_images_from_dir "$CHART_DIR" "$IMAGES_RAW"
MAIN_COUNT=$(sort -u "$IMAGES_RAW" | grep -c '@sha256:' || true)
echo "   ✓ Found $MAIN_COUNT images with SHA256 digests"
echo ""

# --------------------------------------------------------------------------
# Step 5: Identify the operator image
# --------------------------------------------------------------------------
echo "5. Identifying operator image (pattern: $OPERATOR_IMAGE_PATTERN)..."
OPERATOR_IMAGE=$(grep '  image:' "$CHART_DIR/values.yaml" | grep "$OPERATOR_IMAGE_PATTERN" | sed 's/.*image: "//' | sed 's/".*//' | head -1)
if [ -z "$OPERATOR_IMAGE" ]; then
    echo "   ✗ Could not find operator image matching '$OPERATOR_IMAGE_PATTERN' in $CHART_DIR/values.yaml"
    exit 1
else
    echo "   ✓ Found: $OPERATOR_IMAGE"
    echo ""

    # --------------------------------------------------------------------------
    # Step 6: Pull operator image and extract dependency charts
    # --------------------------------------------------------------------------
    echo "6. Pulling operator image (this requires authentication)..."
    echo ""

    OPERATOR_DIR="$WORK_DIR/operator-image"
    mkdir -p "$OPERATOR_DIR"

    # Check if the release has been published to the GA registry
    IS_GA=true
    [[ "$CHART_REPO" != "$GA_CHART_REPOSITORY" ]] && IS_GA=false

    OPERATOR_PULLED=false
    if skopeo copy --override-os linux --override-arch amd64 "docker://$OPERATOR_IMAGE" "dir:$OPERATOR_DIR" 2>"$WORK_DIR/.skopeo-err"; then
        OPERATOR_PULLED=true
        echo "   ✓ Operator image downloaded: $OPERATOR_IMAGE"
    elif [ "$IS_GA" = false ]; then
        # For non-GA builds, fall back to dev registry
        DEV_OPERATOR_IMAGE="${OPERATOR_IMAGE/registry.redhat.io/quay.io}"
        echo "   ⚠ Not found in GA registry, trying dev registry..."
        echo "   Trying: $DEV_OPERATOR_IMAGE"
        rm -rf "$OPERATOR_DIR"
        mkdir -p "$OPERATOR_DIR"
        if skopeo copy --override-os linux --override-arch amd64 "docker://$DEV_OPERATOR_IMAGE" "dir:$OPERATOR_DIR" 2>"$WORK_DIR/.skopeo-err"; then
            OPERATOR_PULLED=true
            echo "   ✓ Operator image downloaded: $DEV_OPERATOR_IMAGE"
        fi
    fi

    if [ "$OPERATOR_PULLED" = false ]; then
        echo "   ✗ Failed to pull operator image: $OPERATOR_IMAGE"
        if grep -q "unauthorized\|authentication required\|denied\|401" "$WORK_DIR/.skopeo-err" 2>/dev/null; then
            echo "   ℹ You need to authenticate: skopeo login registry.redhat.io"
        elif grep -q "manifest unknown\|not found\|404" "$WORK_DIR/.skopeo-err" 2>/dev/null; then
            echo "   ℹ Image digest not found in registry. The image may not have been published yet."
        else
            echo "   ℹ $(cat "$WORK_DIR/.skopeo-err")"
        fi
        exit 1
    else
        echo "   ✓ Operator image downloaded"

        echo "   Extracting dependency charts from /opt/charts/..."
        for layer_file in "$OPERATOR_DIR"/*; do
            if [ -f "$layer_file" ] && [ "$(basename "$layer_file")" != "manifest.json" ] && [ "$(basename "$layer_file")" != "version" ]; then
                if file "$layer_file" | grep -q "gzip"; then
                    tar -xzf "$layer_file" -C "$WORK_DIR" 2>/dev/null || true
                fi
            fi
        done

        if [ -d "$WORK_DIR/opt/charts" ]; then
            echo "   ✓ Found dependency charts:"
            ls "$WORK_DIR/opt/charts/" | sed 's/^/      - /'
            echo ""

            # ------------------------------------------------------------------
            # Step 7: Extract images from dependency chart YAML files
            # ------------------------------------------------------------------
            echo "7. Extracting images from dependency chart YAML files..."
            BEFORE_COUNT=$(sort -u "$IMAGES_RAW" | grep -c '@sha256:' || true)

            # 7a: Sail Operator — version-aware filtering
            SAIL_OPERATOR_DIR="$WORK_DIR/opt/charts/sail-operator"
            if [ -d "$SAIL_OPERATOR_DIR" ]; then
                extract_sail_operator_images "$SAIL_OPERATOR_DIR" "$IMAGES_RAW"
            fi

            # 7b: All other dependency charts — standard extraction
            for chart_dir in "$WORK_DIR/opt/charts"/*/; do
                if [ "$(basename "$chart_dir")" = "sail-operator" ]; then
                    continue
                fi
                extract_images_from_dir "$chart_dir" "$IMAGES_RAW"
            done

            AFTER_COUNT=$(sort -u "$IMAGES_RAW" | grep -c '@sha256:' || true)
            DEP_COUNT=$((AFTER_COUNT - BEFORE_COUNT))
            echo "   ✓ Found $DEP_COUNT dependency images"
        else
            echo "   ⚠ No /opt/charts/ found in operator image"
            echo "7. Skipped - no dependency charts found"
        fi
    fi
fi

# Deduplicate and count
echo ""
echo "Processing and deduplicating..."
sort -u "$IMAGES_RAW" | grep -E '@sha256:' > "${WORK_DIR}/.images.final"
TOTAL=$(wc -l < "${WORK_DIR}/.images.final" | tr -d ' ')

echo ""
echo "=========================================================================="
echo "Extraction Complete - Found $TOTAL unique images"
echo "=========================================================================="
echo ""

# Create output file in charts directory
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

# Process each registry and group by image name
for registry in $(cut -d'/' -f1 "${WORK_DIR}/.images.final" | sort -u); do
    echo "${registry}:" >> "$OUTPUT_PATH"
    echo "  images:" >> "$OUTPUT_PATH"

    grep "^${registry}/" "${WORK_DIR}/.images.final" | sort -u | while IFS= read -r img; do
        if [[ $img =~ ^([^/]+)/(.+)@(sha256:[a-f0-9]{64})$ ]]; then
            repo="${BASH_REMATCH[2]}"
            digest="${BASH_REMATCH[3]}"
            echo "${repo}|${digest}"
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
done

# Count images by category
MAIN_CHART=$(grep -cE "registry.redhat.io/(rhoai|rhaii|openshift4)" "${WORK_DIR}/.images.final" || true)
CERT_MGR=$(grep -c "cert-manager" "${WORK_DIR}/.images.final" || true)
LWS=$(grep -c "leader-worker-set" "${WORK_DIR}/.images.final" || true)
ISTIO=$(grep -c "openshift-service-mesh" "${WORK_DIR}/.images.final" || true)

echo "Image Breakdown:"
echo "  • Main Chart (RHAI):      $MAIN_CHART images"
[ "$CERT_MGR" -gt 0 ] && echo "  • cert-manager:           $CERT_MGR images"
[ "$LWS" -gt 0 ] && echo "  • LeaderWorkerSet (LWS):  $LWS images"
[ "$ISTIO" -gt 0 ] && echo "  • Istio/Service Mesh:     $ISTIO images"
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
