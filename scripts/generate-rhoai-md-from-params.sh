#!/usr/bin/env bash
# Ad-hoc generator: restructure rhoai-*.md using notebooks params.env suffixes.
# Intended for review with maintainers before integrating into rhoai-dih.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-rhoai-3.5}"
OUTPUT="${2:-$REPO_ROOT/${VERSION}.md}"

NOTEBOOKS_BRANCH="$VERSION"
PARAMS_ENV_URL="https://raw.githubusercontent.com/red-hat-data-services/notebooks/${NOTEBOOKS_BRANCH}/manifests/rhoai/base/params.env"
ADDITIONAL_IMAGES_URL="https://raw.githubusercontent.com/red-hat-data-services/rhoai-additional-images/${NOTEBOOKS_BRANCH}/rhoai-disconnected-images.yaml"
PARAMS_ENV_SOURCE="https://github.com/red-hat-data-services/notebooks/blob/${NOTEBOOKS_BRANCH}/manifests/rhoai/base/params.env"

MIRROR_URL="${MIRROR_URL:-registry.example.com:5000/mirror/oc-mirror-metadata}"
SKIP_TLS="${SKIP_TLS:-false}"
OPENSHIFT_VERSION="${OPENSHIFT_VERSION:-v4.20}"
CHANNEL="${CHANNEL:-fast}"

semver="${VERSION#rhoai-}"
operator_min_version="${semver}.0"
operator_max_version="${operator_min_version}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

params_env="$tmpdir/params.env"
additional_yaml="$tmpdir/rhoai-disconnected-images.yaml"

curl -fsSL "$PARAMS_ENV_URL" -o "$params_env"
curl -fsSL "$ADDITIONAL_IMAGES_URL" -o "$additional_yaml"

previous_ga_images="$tmpdir/previous-ga.txt"
pypi_2025_2_images="$tmpdir/pypi-2025-2.txt"
pypi_2025_1_images="$tmpdir/pypi-2025-1.txt"
all_params_images="$tmpdir/all-params.txt"

: >"$previous_ga_images"
: >"$pypi_2025_2_images"
: >"$pypi_2025_1_images"
: >"$all_params_images"

previous_ga_label=""

while IFS='=' read -r key value; do
  [[ -z "${key:-}" || -z "${value:-}" ]] && continue
  [[ "$key" =~ ^# ]] && continue

  printf '%s\n' "$value" >>"$all_params_images"

  if [[ "$key" == *-3-4 ]]; then
    printf '%s\n' "$value" >>"$previous_ga_images"
    if [[ -z "$previous_ga_label" && "$key" =~ -([0-9]+)-([0-9]+)$ ]]; then
      previous_ga_label="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
  elif [[ "$key" == *-2025-2 ]]; then
    printf '%s\n' "$value" >>"$pypi_2025_2_images"
  elif [[ "$key" == *-2025-1 ]]; then
    printf '%s\n' "$value" >>"$pypi_2025_1_images"
  fi
done <"$params_env"

additional_images="$tmpdir/additional.txt"
: >"$additional_images"

while IFS= read -r image; do
  [[ -z "$image" ]] && continue
  if grep -qxF "$image" "$all_params_images"; then
    continue
  fi
  printf '%s\n' "$image" >>"$additional_images"
done < <(yq e '.additional-images[]' "$additional_yaml")

format_image_list() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    return
  fi
  sed 's/^/    - /' "$file"
  printf '\n'
}

format_yaml_image_list() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    return
  fi
  sed 's/^/    - name: /' "$file"
  printf '\n'
}

{
  printf '# Additional images:\n'
  format_image_list "$additional_images"

  cat <<EOF

# Unsupported Images:
Optional workbench and pipeline runtime images not included in the operator CSV.
Mirror a subsection below only if users will select those images in the dashboard.
Current-release workbench and pipeline runtime images are mirrored automatically with
the RHOAI operator.

## Previous GA release (${previous_ga_label}) workbench images
Mirror only if users need workbench images from the immediately preceding GA release
(for example, existing notebooks or imported resources created on ${previous_ga_label}).

<!-- Source: ${PARAMS_ENV_SOURCE} keys *-3-4 -->
EOF
  format_image_list "$previous_ga_images"

  cat <<EOF
## PyPI-enabled (2025.2 version) workbench and pipeline runtime images
Mirror only if users need PyPI-enabled (2025.2) workbench or pipeline runtime images
that remain selectable in RHOAI ${semver}. See the
[Red Hat AI Python Index](https://access.redhat.com/articles/7137881) article
for background on the move away from PyPI-enabled images.

<!-- Source: ${PARAMS_ENV_SOURCE} keys *-2025-2 -->
EOF
  format_image_list "$pypi_2025_2_images"

  cat <<'EOF'
## PyPI-enabled (2025.1 version) workbench images
Mirror only if users need PyPI-enabled (2025.1) workbench images.

EOF
  printf '<!-- Source: %s keys *-2025-1 -->\n' "$PARAMS_ENV_SOURCE"
  format_image_list "$pypi_2025_1_images"

  cat <<EOF
# ImageSetConfiguration example:
\`\`\`yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry:
    imageURL: ${MIRROR_URL}
    skipTLS: ${SKIP_TLS}
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:${OPENSHIFT_VERSION}
    packages:
    - name: rhods-operator
      channels:
      - name: ${CHANNEL}
        minVersion: ${operator_min_version}
        maxVersion: ${operator_max_version}
  additionalImages:
EOF
  format_yaml_image_list "$additional_images"
  printf '```\n'
} >"$OUTPUT"

echo "Wrote $OUTPUT"
