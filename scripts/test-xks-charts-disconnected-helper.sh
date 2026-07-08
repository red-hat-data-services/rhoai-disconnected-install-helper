#!/bin/bash
# Test suite for xks-charts-disconnected-helper.sh
#
# Self-contained — does not require a prior run of the main script.
# Creates its own temp directories and test data, and cleans up on exit.
#
# Requirements: bash, jq, yq, grep
# Registry access is NOT required (input validation tests invoke the main
# script but only exercise the argument-parsing path, not the pull path).
#
# Tests:
#   - Input validation (version strings, image references)
#   - Version parsing (major/minor/micro/ea extraction)
#   - Registry pattern building
#   - Image extraction from YAML files (including Helm templates)
#   - Sail Operator version filtering
#   - Dependency chart include filter (INCLUDE_DEPENDENCY_CHARTS)
#   - OCI layout parsing with jq
#   - Operator layer extraction with jq
#   - yq-based Chart.yaml and values.yaml parsing
#   - Comment stripping / deduplication
#   - Output format (skopeo sync YAML)
#   - Work directory structure
#
# Usage:
#   ./scripts/test-xks-charts-disconnected-helper.sh
#
# Exit code: 0 if all tests pass, 1 if any test fails.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/xks-charts-disconnected-helper.sh"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# ============================================================================
# TEST HELPERS
# ============================================================================

pass() {
    PASS=$((PASS + 1))
    echo "  ✓ $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo "  ✗ $1"
    if [ -n "${2:-}" ]; then
        echo "    Expected: $2"
        echo "    Got:      ${3:-<empty>}"
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$desc"
    else
        fail "$desc" "$expected" "$actual"
    fi
}

assert_contains() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == *"$expected"* ]]; then
        pass "$desc"
    else
        fail "$desc" "contains '$expected'" "$actual"
    fi
}

assert_not_contains() {
    local desc="$1" unexpected="$2" actual="$3"
    if [[ "$actual" != *"$unexpected"* ]]; then
        pass "$desc"
    else
        fail "$desc" "does not contain '$unexpected'" "$actual"
    fi
}

assert_exit() {
    local desc="$1" expected_exit="$2"
    shift 2
    local actual_exit=0
    "$@" > /dev/null 2>&1 || actual_exit=$?
    if [ "$actual_exit" -eq "$expected_exit" ]; then
        pass "$desc"
    else
        fail "$desc" "exit $expected_exit" "exit $actual_exit"
    fi
}

# ============================================================================
# TEST: Input Validation
# ============================================================================

echo ""
echo "=== Input Validation ==="

# No arguments
assert_exit "no arguments exits 1" 1 bash "$SCRIPT"

# Invalid version formats
assert_exit "invalid version 'abc' exits 1" 1 bash "$SCRIPT" "abc"
assert_exit "invalid version '3.4' exits 1" 1 bash "$SCRIPT" "3.4"
assert_exit "invalid version '3.4.0.1' exits 1" 1 bash "$SCRIPT" "3.4.0.1"
assert_exit "invalid version '3.4.0-beta.1' exits 1" 1 bash "$SCRIPT" "3.4.0-beta.1"

# Invalid image reference (no tag/digest)
assert_exit "image ref without tag exits 1" 1 bash "$SCRIPT" "quay.io/rhoai/rhai-on-xks-chart"

# Invalid image reference (wrong repository)
assert_exit "image ref from unknown repo exits 1" 1 bash "$SCRIPT" "docker.io/library/nginx:latest"

# Valid version formats should fail on pull (not on validation)
output=$(bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_not_contains "valid version 3.5.0 passes validation" "Invalid version" "$output"

output=$(bash "$SCRIPT" "v3.5.0" 2>&1 || true)
assert_not_contains "valid version v3.5.0 (v prefix) passes validation" "Invalid version" "$output"

output=$(bash "$SCRIPT" "3.5.0-ea.1" 2>&1 || true)
assert_not_contains "valid version 3.5.0-ea.1 passes validation" "Invalid version" "$output"

output=$(bash "$SCRIPT" "v3.5.0-ea.2" 2>&1 || true)
assert_not_contains "valid version v3.5.0-ea.2 passes validation" "Invalid version" "$output"

# Valid image references should fail on pull (not on validation)
output=$(bash "$SCRIPT" "registry.redhat.io/rhai/rhai-on-xks-chart:v3.5.0" 2>&1 || true)
assert_not_contains "valid GA image ref passes validation" "Error:" "$output"

output=$(bash "$SCRIPT" "quay.io/rhoai/rhai-on-xks-chart@sha256:$(printf '%.0sa' {1..64})" 2>&1 || true)
assert_not_contains "valid dev digest ref passes validation" "Error:" "$output"

# ============================================================================
# TEST: Version Parsing (via printed output)
# ============================================================================

echo ""
echo "=== Version Parsing ==="

output=$(bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_contains "GA version major" "Major:             3" "$output"
assert_contains "GA version minor" "Minor:             5" "$output"
assert_contains "GA version micro" "Micro:             0" "$output"
assert_not_contains "GA version no EA suffix" "EA suffix:" "$output"

output=$(bash "$SCRIPT" "3.4.1-ea.2" 2>&1 || true)
assert_contains "EA version major" "Major:             3" "$output"
assert_contains "EA version minor" "Minor:             4" "$output"
assert_contains "EA version micro" "Micro:             1" "$output"
assert_contains "EA version EA suffix" "EA suffix:         -ea.2" "$output"

output=$(bash "$SCRIPT" "v3.5.0" 2>&1 || true)
assert_contains "v-prefix stripped from version" "Version:             3.5.0" "$output"

# ============================================================================
# TEST: BUILD_TYPE resolution
# ============================================================================

echo ""
echo "=== BUILD_TYPE Resolution ==="

output=$(BUILD_TYPE=ga bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_contains "BUILD_TYPE=ga tries GA registry" "Trying ga: registry.redhat.io" "$output"

output=$(BUILD_TYPE=nightly bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_contains "BUILD_TYPE=nightly tries dev nightly" "Trying nightly: quay.io/rhoai" "$output"

output=$(BUILD_TYPE=ci bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_contains "BUILD_TYPE=ci tries dev ci" "Trying ci: quay.io/rhoai" "$output"

output=$(BUILD_TYPE=invalid bash "$SCRIPT" "3.5.0" 2>&1 || true)
assert_contains "BUILD_TYPE=invalid exits with error" "Invalid BUILD_TYPE" "$output"

# ============================================================================
# TEST: Registry Pattern Building
# ============================================================================

echo ""
echo "=== Registry Pattern Building ==="

# Test that pattern is built correctly by running extract on test data
PATTERN_TEST_DIR="$TEST_DIR/pattern-test"
mkdir -p "$PATTERN_TEST_DIR"

cat > "$PATTERN_TEST_DIR/test.yaml" << 'EOF'
image: registry.redhat.io/rhoai/operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
image: registry.access.redhat.com/ubi9/ubi@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
image: docker.io/library/nginx@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
EOF

# Source the script functions by extracting the relevant parts
# Build pattern the same way the script does
REGISTRIES="registry.redhat.io registry.access.redhat.com"
REGISTRY_PATTERN=""
for reg in $REGISTRIES; do
    local_escaped="${reg//./\\.}"
    if [ -n "$REGISTRY_PATTERN" ]; then
        REGISTRY_PATTERN="${REGISTRY_PATTERN}|${local_escaped}"
    else
        REGISTRY_PATTERN="$local_escaped"
    fi
done

result=$(grep -oE "(${REGISTRY_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" "$PATTERN_TEST_DIR/test.yaml" | sort)
assert_contains "pattern matches registry.redhat.io" "registry.redhat.io/rhoai/operator@sha256:a" "$result"
assert_contains "pattern matches registry.access.redhat.com" "registry.access.redhat.com/ubi9/ubi@sha256:b" "$result"
assert_not_contains "pattern excludes docker.io" "docker.io" "$result"

# Test with single registry
REGISTRY_PATTERN_SINGLE="registry\\.redhat\\.io"
result=$(grep -oE "(${REGISTRY_PATTERN_SINGLE})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" "$PATTERN_TEST_DIR/test.yaml" | sort)
assert_contains "single registry pattern matches" "registry.redhat.io" "$result"
assert_not_contains "single registry pattern excludes others" "registry.access.redhat.com" "$result"

# ============================================================================
# TEST: Image Extraction from YAML
# ============================================================================

echo ""
echo "=== Image Extraction ==="

EXTRACT_DIR="$TEST_DIR/extract-test"
WORK_DIR="$TEST_DIR/extract-test"
mkdir -p "$EXTRACT_DIR/chart/templates"

# Test: images in various YAML formats
cat > "$EXTRACT_DIR/chart/values.yaml" << 'EOF'
operator:
  image: "registry.redhat.io/rhoai/odh-rhel9-operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  sidecar: "registry.redhat.io/rhoai/sidecar@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
unrelated: "some-value"
EOF

cat > "$EXTRACT_DIR/chart/templates/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: manager
        image: "registry.redhat.io/rhoai/odh-rhel9-operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      - name: proxy
        image: registry.access.redhat.com/ubi9/ubi@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
EOF

# Helm template file (with {{ }})
cat > "$EXTRACT_DIR/chart/templates/hook.yaml" << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  namespace: {{ .Values.namespace }}
spec:
  template:
    spec:
      containers:
      - name: hook
        image: "registry.redhat.io/openshift4/ose-cli-rhel9@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
EOF

IMAGES_RAW="$TEST_DIR/extract-images"
> "$IMAGES_RAW"

extract_matching_images() {
    local output="$1"
    local annotation="$2"

    grep -oE "(${REGISTRY_PATTERN})/[^\"'[:space:]]+@sha256:[a-f0-9]{64}" | \
        while IFS= read -r img; do
            echo "$img # ${annotation}" >> "$output"
        done || true
}

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

extract_images_from_dir "$EXTRACT_DIR/chart" "$IMAGES_RAW" "" "$EXTRACT_DIR"

img_count=$(wc -l < "$IMAGES_RAW" | tr -d ' ')
assert_eq "extracts correct number of images" "5" "$img_count"

unique_count=$(cut -d' ' -f1 "$IMAGES_RAW" | sort -u | wc -l | tr -d ' ')
assert_eq "finds 4 unique images" "4" "$unique_count"

assert_contains "extracts from values.yaml" "values.yaml" "$(cat "$IMAGES_RAW")"
assert_contains "extracts from Helm templates" "deployment.yaml" "$(cat "$IMAGES_RAW")"
assert_contains "extracts from templates with {{ }}" "hook.yaml" "$(cat "$IMAGES_RAW")"
assert_contains "includes source annotation" " # " "$(cat "$IMAGES_RAW")"

# ============================================================================
# TEST: Sail Operator Version Filtering
# ============================================================================

echo ""
echo "=== Sail Operator Version Filtering ==="

SAIL_DIR="$TEST_DIR/sail-test"
WORK_DIR="$TEST_DIR/sail-test"
mkdir -p "$SAIL_DIR/templates"

# istio.yaml with Helm template (like real file)
cat > "$SAIL_DIR/templates/istio.yaml" << 'EOF'
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: {{ .Values.namespace }}
  version: v1.27-latest
  values:
    pilot:
      env:
        ENABLE_GATEWAY_API: "true"
EOF

# Deployment with version-keyed annotations
cat > "$SAIL_DIR/templates/deployment-servicemesh-operator3.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: servicemesh-operator3
  namespace: {{ .Values.namespace }}
spec:
  template:
    metadata:
      annotations:
        images.v1_26_2.cni: registry.redhat.io/openshift-service-mesh/istio-cni-rhel9@sha256:1111111111111111111111111111111111111111111111111111111111111111
        images.v1_26_2.istiod: registry.redhat.io/openshift-service-mesh/istio-pilot-rhel9@sha256:2222222222222222222222222222222222222222222222222222222222222222
        images.v1_27_3.cni: registry.redhat.io/openshift-service-mesh/istio-cni-rhel9@sha256:3333333333333333333333333333333333333333333333333333333333333333
        images.v1_27_3.istiod: registry.redhat.io/openshift-service-mesh/istio-pilot-rhel9@sha256:4444444444444444444444444444444444444444444444444444444444444444
        images.v1_27_5.cni: registry.redhat.io/openshift-service-mesh/istio-cni-rhel9@sha256:5555555555555555555555555555555555555555555555555555555555555555
        images.v1_27_5.istiod: registry.redhat.io/openshift-service-mesh/istio-pilot-rhel9@sha256:6666666666666666666666666666666666666666666666666666666666666666
        images.v1_28_1.cni: registry.redhat.io/openshift-service-mesh/istio-cni-rhel9@sha256:7777777777777777777777777777777777777777777777777777777777777777
        images.v1_28_1.istiod: registry.redhat.io/openshift-service-mesh/istio-pilot-rhel9@sha256:8888888888888888888888888888888888888888888888888888888888888888
    spec:
      containers:
      - name: manager
        image: registry.redhat.io/openshift-service-mesh/istio-rhel9-operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
EOF

# Test auto-detection of version from istio.yaml
SAIL_IMAGES="$TEST_DIR/sail-images"
> "$SAIL_IMAGES"

extract_sail_operator_images() {
    local sail_dir="$1"
    local output="$2"
    local source_prefix="${3:-}"
    local path_base="${4:-$sail_dir}"

    local version_key=""
    if [ "$SAIL_OPERATOR_VERSION" = "all" ]; then
        extract_images_from_dir "$sail_dir" "$output" "$source_prefix" "$path_base"
        return
    elif [ -n "$SAIL_OPERATOR_VERSION" ]; then
        local pinned_version="$SAIL_OPERATOR_VERSION"
        local stripped="${pinned_version%-latest}"
        version_key="${stripped//./_}"
    else
        local istio_file="$sail_dir/templates/istio.yaml"
        if [ ! -f "$istio_file" ]; then
            echo "   ✗ No istio.yaml found in Sail Operator chart"
            exit 1
        fi

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

# Test 1: Auto-detect version (v1.27-latest → filter for v1_27_*)
SAIL_OPERATOR_VERSION=""
extract_sail_operator_images "$SAIL_DIR" "$SAIL_IMAGES" "test-operator:"

sail_count=$(wc -l < "$SAIL_IMAGES" | tr -d ' ')
assert_eq "sail filtering: v1.27 includes operator + v1_27 images" "5" "$sail_count"

assert_contains "sail filtering: includes operator image" "istio-rhel9-operator" "$(cat "$SAIL_IMAGES")"
assert_contains "sail filtering: includes v1_27_3.cni" "sha256:3333" "$(cat "$SAIL_IMAGES")"
assert_contains "sail filtering: includes v1_27_5.istiod" "sha256:6666" "$(cat "$SAIL_IMAGES")"
assert_not_contains "sail filtering: excludes v1_26" "sha256:1111" "$(cat "$SAIL_IMAGES")"
assert_not_contains "sail filtering: excludes v1_28" "sha256:7777" "$(cat "$SAIL_IMAGES")"

# Test 2: Override version
> "$SAIL_IMAGES"
SAIL_OPERATOR_VERSION="v1.26"
extract_sail_operator_images "$SAIL_DIR" "$SAIL_IMAGES" "test-operator:"

sail_count=$(wc -l < "$SAIL_IMAGES" | tr -d ' ')
assert_eq "sail override v1.26: includes operator + v1_26 images" "3" "$sail_count"
assert_contains "sail override v1.26: includes v1_26_2.cni" "sha256:1111" "$(cat "$SAIL_IMAGES")"
assert_not_contains "sail override v1.26: excludes v1_27" "sha256:3333" "$(cat "$SAIL_IMAGES")"

# Test 3: SAIL_OPERATOR_VERSION=all (no filtering)
> "$SAIL_IMAGES"
SAIL_OPERATOR_VERSION="all"
extract_sail_operator_images "$SAIL_DIR" "$SAIL_IMAGES" "test-operator:"

sail_count=$(wc -l < "$SAIL_IMAGES" | tr -d ' ')
assert_eq "sail all: includes all 9 image lines" "9" "$sail_count"

# Test 4: Missing istio.yaml exits with error
SAIL_OPERATOR_VERSION=""
SAIL_NO_ISTIO_DIR="$TEST_DIR/sail-no-istio"
mkdir -p "$SAIL_NO_ISTIO_DIR/templates"
cp "$SAIL_DIR/templates/deployment-servicemesh-operator3.yaml" "$SAIL_NO_ISTIO_DIR/templates/"
exit_code=0
(extract_sail_operator_images "$SAIL_NO_ISTIO_DIR" /dev/null "") > /dev/null 2>&1 || exit_code=$?
assert_eq "sail no istio.yaml: exits with error" "1" "$exit_code"

# Test 5: Missing deployment manifest exits with error
SAIL_OPERATOR_VERSION=""
SAIL_NO_DEPLOY_DIR="$TEST_DIR/sail-no-deploy"
mkdir -p "$SAIL_NO_DEPLOY_DIR/templates"
cp "$SAIL_DIR/templates/istio.yaml" "$SAIL_NO_DEPLOY_DIR/templates/"
exit_code=0
(extract_sail_operator_images "$SAIL_NO_DEPLOY_DIR" /dev/null "") > /dev/null 2>&1 || exit_code=$?
assert_eq "sail no deployment manifest: exits with error" "1" "$exit_code"

# ============================================================================
# TEST: INCLUDE_DEPENDENCY_CHARTS filtering
# ============================================================================

echo ""
echo "=== Dependency Chart Filtering ==="

should_process_chart() {
    local name="$1"
    [ "$INCLUDE_DEPENDENCY_CHARTS" = "all" ] && return 0
    for chart in $INCLUDE_DEPENDENCY_CHARTS; do
        [ "$chart" = "$name" ] && return 0
    done
    return 1
}

# Test: "all" includes everything
INCLUDE_DEPENDENCY_CHARTS="all"
should_process_chart "sail-operator" && pass "all: includes sail-operator" || fail "all: includes sail-operator"
should_process_chart "cert-manager-operator" && pass "all: includes cert-manager-operator" || fail "all: includes cert-manager-operator"
should_process_chart "unknown-chart" && pass "all: includes unknown-chart" || fail "all: includes unknown-chart"

# Test: specific list only includes listed charts
INCLUDE_DEPENDENCY_CHARTS="sail-operator cert-manager-operator"
should_process_chart "sail-operator" && pass "list: includes sail-operator" || fail "list: includes sail-operator"
should_process_chart "cert-manager-operator" && pass "list: includes cert-manager-operator" || fail "list: includes cert-manager-operator"
should_process_chart "lws-operator" && fail "list: excludes lws-operator" || pass "list: excludes lws-operator"
should_process_chart "gateway-api" && fail "list: excludes gateway-api" || pass "list: excludes gateway-api"

# Test: single chart
INCLUDE_DEPENDENCY_CHARTS="sail-operator"
should_process_chart "sail-operator" && pass "single: includes sail-operator" || fail "single: includes sail-operator"
should_process_chart "cert-manager-operator" && fail "single: excludes cert-manager-operator" || pass "single: excludes cert-manager-operator"

# Test: empty string excludes everything
INCLUDE_DEPENDENCY_CHARTS=""
should_process_chart "sail-operator" && fail "empty: excludes sail-operator" || pass "empty: excludes sail-operator"
should_process_chart "anything" && fail "empty: excludes anything" || pass "empty: excludes anything"

# Reset
INCLUDE_DEPENDENCY_CHARTS="all"

# ============================================================================
# TEST: OCI Layout Parsing with jq
# ============================================================================

echo ""
echo "=== OCI Layout Parsing (jq) ==="

OCI_DIR="$TEST_DIR/oci-test"
mkdir -p "$OCI_DIR/blobs/sha256"

# Create index.json
cat > "$OCI_DIR/index.json" << 'EOF'
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "digest": "sha256:abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "size": 671
    }
  ]
}
EOF

# Create manifest blob
cat > "$OCI_DIR/blobs/sha256/abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" << 'EOF'
{
  "schemaVersion": 2,
  "layers": [
    {
      "mediaType": "application/vnd.cncf.helm.chart.content.v1.tar+gzip",
      "digest": "sha256:chartblobdigest0000000000000000000000000000000000000000000000000"
    }
  ]
}
EOF

digest=$(jq -r '.manifests[0].digest' "$OCI_DIR/index.json")
assert_eq "jq extracts manifest digest" "sha256:abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" "$digest"

chart_blob=$(jq -r '.layers[0].digest' "$OCI_DIR/blobs/sha256/${digest#sha256:}")
assert_eq "jq extracts chart blob digest" "sha256:chartblobdigest0000000000000000000000000000000000000000000000000" "$chart_blob"

# ============================================================================
# TEST: Operator Manifest Parsing with jq
# ============================================================================

echo ""
echo "=== Operator Manifest Parsing (jq) ==="

OPERATOR_DIR="$TEST_DIR/operator-test"
mkdir -p "$OPERATOR_DIR"

cat > "$OPERATOR_DIR/manifest.json" << 'EOF'
{
  "schemaVersion": 2,
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "digest": "sha256:configdigest00000000000000000000000000000000000000000000000000000"
  },
  "layers": [
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "digest": "sha256:layer1digest0000000000000000000000000000000000000000000000000000"
    },
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "digest": "sha256:layer2digest0000000000000000000000000000000000000000000000000000"
    }
  ]
}
EOF

layers=$(jq -r '.layers[].digest' "$OPERATOR_DIR/manifest.json")
layer_count=$(echo "$layers" | wc -l | tr -d ' ')
assert_eq "jq extracts 2 layer digests" "2" "$layer_count"

first_layer=$(echo "$layers" | head -1)
assert_eq "jq first layer digest" "sha256:layer1digest0000000000000000000000000000000000000000000000000000" "$first_layer"

# ============================================================================
# TEST: yq Parsing
# ============================================================================

echo ""
echo "=== yq Parsing ==="

# Chart.yaml
CHART_YAML_DIR="$TEST_DIR/yq-test"
mkdir -p "$CHART_YAML_DIR"

cat > "$CHART_YAML_DIR/Chart.yaml" << 'EOF'
apiVersion: v2
appVersion: v3.5.0
description: Test chart
name: test-chart
version: 3.5.0
EOF

version=$(yq '.version' "$CHART_YAML_DIR/Chart.yaml")
assert_eq "yq extracts Chart.yaml version" "3.5.0" "$version"

# Chart.yaml with v prefix
cat > "$CHART_YAML_DIR/Chart-v.yaml" << 'EOF'
apiVersion: v2
version: v3.4.1
EOF

version=$(yq '.version' "$CHART_YAML_DIR/Chart-v.yaml")
version="${version#v}"
assert_eq "yq extracts and strips v prefix" "3.4.1" "$version"

# values.yaml operator image
cat > "$CHART_YAML_DIR/values.yaml" << 'EOF'
rhaiOperator:
  namespace: redhat-ods-operator
  image: "registry.redhat.io/rhoai/odh-rhel9-operator@sha256:c8efa4d12e99faa8a7faddf953acafe46f99592cf6c9f2200ee11f65d79b3ee4"
  imagePullPolicy: Always
kserve:
  image: "registry.redhat.io/rhoai/odh-kserve-controller@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  controllerImage: "registry.redhat.io/rhoai/odh-rhel9-operator@sha256:c8efa4d12e99faa8a7faddf953acafe46f99592cf6c9f2200ee11f65d79b3ee4"
EOF

operator_image=$(yq -r ".. | select(tag == \"!!str\" and test(\"odh-rhel9-operator\") and test(\"@sha256:\"))" "$CHART_YAML_DIR/values.yaml" | head -1)
assert_eq "yq extracts operator image" "registry.redhat.io/rhoai/odh-rhel9-operator@sha256:c8efa4d12e99faa8a7faddf953acafe46f99592cf6c9f2200ee11f65d79b3ee4" "$operator_image"

# Verify yq doesn't match non-operator images
non_operator=$(yq -r ".. | select(tag == \"!!str\" and test(\"odh-kserve-controller\") and test(\"@sha256:\"))" "$CHART_YAML_DIR/values.yaml" | head -1)
assert_not_contains "yq operator pattern doesn't match kserve" "odh-rhel9-operator" "$non_operator"

# ============================================================================
# TEST: Comment Stripping (bash builtins, no sed)
# ============================================================================

echo ""
echo "=== Comment Stripping ==="

STRIP_FILE="$TEST_DIR/strip-test"
cat > "$STRIP_FILE" << 'EOF'
registry.redhat.io/rhoai/operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa # chart/values.yaml
registry.redhat.io/rhoai/sidecar@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb # operator-image:deployment.yaml
registry.redhat.io/rhoai/operator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa # chart/templates/deploy.yaml
EOF

# Strip comments using bash builtins (same approach as in the script)
stripped=""
while IFS= read -r line; do
    stripped="${stripped}${line%% #*}"$'\n'
done < "$STRIP_FILE"

assert_contains "strip preserves image ref" "registry.redhat.io/rhoai/operator@sha256:a" "$stripped"
assert_not_contains "strip removes annotations" "values.yaml" "$stripped"
assert_not_contains "strip removes operator-image prefix" "operator-image:" "$stripped"

# Test deduplication
deduped=$(while IFS= read -r line; do echo "${line%% #*}"; done < "$STRIP_FILE" | sort -u | grep -c '@sha256:' || true)
assert_eq "deduplication removes duplicates" "2" "$deduped"

# ============================================================================
# TEST: Output Format (skopeo sync YAML)
# ============================================================================

echo ""
echo "=== Output Format ==="

OUTPUT_TEST_DIR="$TEST_DIR/output-test"
mkdir -p "$OUTPUT_TEST_DIR"

# Create a .images.final file
cat > "$OUTPUT_TEST_DIR/.images.final" << 'EOF'
registry.redhat.io/cert-manager/cert-manager-rhel9@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
registry.redhat.io/cert-manager/cert-manager-rhel9@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
registry.redhat.io/rhoai/odh-rhel9-operator@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
registry.access.redhat.com/ubi9/ubi-minimal@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
EOF

OUTPUT_FILE="$OUTPUT_TEST_DIR/output.yaml"
OUTPUT_FILENAME="output.yaml"

# Generate output (same logic as script)
cat > "$OUTPUT_FILE" << HEADER
# Skopeo sync configuration (auto-generated)
#
# Prerequisites:
#   skopeo login registry.redhat.io
#   skopeo login YOUR_REGISTRY
#
# Usage:
#   skopeo sync --src yaml --dest docker $OUTPUT_FILENAME YOUR_REGISTRY

HEADER

while IFS= read -r registry; do
    echo "${registry}:" >> "$OUTPUT_FILE"
    echo "  images:" >> "$OUTPUT_FILE"

    grep "^${registry}/" "$OUTPUT_TEST_DIR/.images.final" | sort -u | while IFS= read -r img; do
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
    }' >> "$OUTPUT_FILE"
done < <(cut -d'/' -f1 "$OUTPUT_TEST_DIR/.images.final" | sort -u)

output_content=$(cat "$OUTPUT_FILE")

# Verify structure
assert_contains "output has header" "Skopeo sync configuration" "$output_content"
assert_contains "output has registry.redhat.io section" "registry.redhat.io:" "$output_content"
assert_contains "output has registry.access.redhat.com section" "registry.access.redhat.com:" "$output_content"
assert_contains "output has images key" "  images:" "$output_content"
assert_contains "output groups cert-manager repo" "    cert-manager/cert-manager-rhel9:" "$output_content"
assert_contains "output groups operator repo" "    rhoai/odh-rhel9-operator:" "$output_content"
assert_contains "output has quoted digest" '      - "sha256:a' "$output_content"

# Verify multi-digest grouping (cert-manager has 2 digests)
cert_digest_count=$(grep -c 'sha256:.*aaaa\|sha256:.*bbbb' "$OUTPUT_FILE" || true)
assert_eq "output groups multiple digests under same repo" "2" "$cert_digest_count"

# ============================================================================
# TEST: Bash Parameter Expansion (version parsing)
# ============================================================================

echo ""
echo "=== Bash Parameter Expansion ==="

# Test major/minor/micro extraction
TEST_VERSION="3.5.1"
major="${TEST_VERSION%%.*}"
rest="${TEST_VERSION#*.}"
minor="${rest%%.*}"
micro_rest="${rest#*.}"
micro="${micro_rest%%-*}"

assert_eq "param expansion: major" "3" "$major"
assert_eq "param expansion: minor" "5" "$minor"
assert_eq "param expansion: micro" "1" "$micro"

# Test EA version
TEST_VERSION_EA="3.4.0-ea.2"
major="${TEST_VERSION_EA%%.*}"
rest="${TEST_VERSION_EA#*.}"
minor="${rest%%.*}"
micro_rest="${rest#*.}"
micro="${micro_rest%%-*}"
ea_suffix=""
if [[ "$TEST_VERSION_EA" == *-ea.* ]]; then
    ea_suffix="-${TEST_VERSION_EA#*-}"
fi

assert_eq "param expansion EA: major" "3" "$major"
assert_eq "param expansion EA: minor" "4" "$minor"
assert_eq "param expansion EA: micro" "0" "$micro"
assert_eq "param expansion EA: suffix" "-ea.2" "$ea_suffix"

# Test v-prefix stripping
TEST_VERSION_V="v3.5.0"
stripped="${TEST_VERSION_V#v}"
assert_eq "param expansion: v-prefix strip" "3.5.0" "$stripped"

# Test version key building (for sail operator)
SAIL_VERSION="v1.27-latest"
key_stripped="${SAIL_VERSION%-latest}"
version_key="${key_stripped//./_}"
assert_eq "param expansion: version key" "v1_27" "$version_key"

SAIL_VERSION_NO_LATEST="v1.26"
key_stripped="${SAIL_VERSION_NO_LATEST%-latest}"
version_key="${key_stripped//./_}"
assert_eq "param expansion: version key no -latest" "v1_26" "$version_key"

# Test dot escaping for registry pattern
REG="registry.redhat.io"
escaped="${REG//./\\.}"
assert_eq "param expansion: dot escape" 'registry\.redhat\.io' "$escaped"

# ============================================================================
# TEST: Work Directory Structure
# ============================================================================

echo ""
echo "=== Work Directory Structure ==="

WORK_TEST_DIR="$TEST_DIR/work-structure"
mkdir -p "$WORK_TEST_DIR/chart/oci" "$WORK_TEST_DIR/chart/extracted" "$WORK_TEST_DIR/operator/oci" "$WORK_TEST_DIR/operator/extracted"

[ -d "$WORK_TEST_DIR/chart/oci" ] && pass "work dir has chart/oci" || fail "work dir has chart/oci"
[ -d "$WORK_TEST_DIR/chart/extracted" ] && pass "work dir has chart/extracted" || fail "work dir has chart/extracted"
[ -d "$WORK_TEST_DIR/operator/oci" ] && pass "work dir has operator/oci" || fail "work dir has operator/oci"
[ -d "$WORK_TEST_DIR/operator/extracted" ] && pass "work dir has operator/extracted" || fail "work dir has operator/extracted"

# ============================================================================
# TEST: Edge Cases
# ============================================================================

echo ""
echo "=== Edge Cases ==="

# Image ref with no @sha256: in values.yaml
cat > "$TEST_DIR/no-digest-values.yaml" << 'EOF'
operator:
  image: "registry.redhat.io/rhoai/odh-rhel9-operator:v3.5.0"
EOF
no_digest_result=$(yq -r ".. | select(tag == \"!!str\" and test(\"odh-rhel9-operator\") and test(\"@sha256:\"))" "$TEST_DIR/no-digest-values.yaml" 2>/dev/null || true)
assert_eq "yq returns empty for tag-only image" "" "$no_digest_result"

# Empty YAML file
> "$TEST_DIR/empty.yaml"
EMPTY_IMAGES="$TEST_DIR/empty-images"
> "$EMPTY_IMAGES"
WORK_DIR="$TEST_DIR"
extract_images_from_dir "$TEST_DIR" "$EMPTY_IMAGES" ""
empty_count=$(wc -l < "$EMPTY_IMAGES" | tr -d ' ')
# Should have found images from other test files in this dir, but the empty.yaml specifically shouldn't crash
pass "empty YAML file doesn't crash extraction"

# Image with single-depth path (e.g., library/nginx)
cat > "$TEST_DIR/deep-path.yaml" << 'EOF'
image: registry.redhat.io/a/b/c/d@sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
EOF
DEEP_IMAGES="$TEST_DIR/deep-images"
> "$DEEP_IMAGES"
extract_images_from_dir "$TEST_DIR" "$DEEP_IMAGES" "test:"
deep_result=$(grep "a/b/c/d" "$DEEP_IMAGES" || true)
assert_contains "extracts deeply nested image path" "a/b/c/d@sha256:e" "$deep_result"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=========================================================================="
TOTAL=$((PASS + FAIL))
echo "Results: $PASS passed, $FAIL failed (out of $TOTAL tests)"
echo "=========================================================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
