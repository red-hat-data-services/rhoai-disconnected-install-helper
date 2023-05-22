#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

rhods_version=""
outputfile_name=""
repository_folder=".odh-manifests"
mirror_url="registry.example.com:5000/mirror/oc-mirror-metadata"
repository_url="https://github.com/red-hat-data-services/odh-manifests"
openshift_version="v4.12"
skip_tls=false
skip_image_verification=false
update_all_support_version=false
channel="stable"

# Other additional images
openvino_image="quay.io/modh/openvino-model-server:2022.3-release"
must_gather_image="quay.io/modh/must-gather:stable"

help() {
  echo "Usage: rhods_disconnected_install_helper.sh"
  echo "  -h, --help                Display this help message"
  echo "  -v, --rhods-version       Only update one specified RHODS version. Valid format: rhods-X.Y"
  echo "  -a, --all-supported-versions  Update for all 4 supported RHODS versions at once"
  echo "  --skip-image-verification Skip image verification, default to not skip"
  echo "  --skip-tls                Skip TLS verification, default to not skip"
  echo "  --set-repository-source   Use a different repository as source"
  echo "  --set-file-name           Set output file name, not compatiable with --all-supported-versions"
  echo "  --set-repository-folder   Use a different local folder to clone from source repository"
  echo "  --set-registry            Set a different mirror registry url in output example"
  echo "  --set-ocp-version         Use a different OpenShift version in output example than 4.12"
  echo "  --set-channel             Use a different channel in output example than stable"
}

get_latest_rhods_version() {
  # Get latest version from Git branch name
  pushd "$repository_folder" > /dev/null || echo "Error: Cannot change current dir to $repository_folder"
  local latest_rhods_version=$(git branch -a | grep remotes/origin/rhods | awk -F '/' '{print $NF}' | sort -V | tail -1)
  popd > /dev/null
  echo "$latest_rhods_version"
}

update_outputfile(){
  # By default only update version set in variable rhods_version
  local count="1"
  local major_version=$(echo $rhods_version | cut -d'-' -f2 | cut -d'.' -f1)
  local minor_version=$(echo $rhods_version | cut -d'-' -f2 | cut -d'.' -f2)
  pwd
  if [ "$update_all_support_version" == true ]; then
    count="1 2 3 4"
  fi

  for i in $count; do
    if [ $i == 1 ]; then
      minor_version=$((minor_version))
    else
      minor_version=$((minor_version - 1))
    fi
    if [ $minor_version -lt 0 ]; then
      major_version=$((major_version - 1))
      minor_version=99
    fi

    rhods_version="rhods-$major_version.$minor_version"
    if [ -z "$outputfile_name" ]; then
      outputfile_name="$rhods_version.md"
    fi
    pushd "$repository_folder" > /dev/null || echo "Error: Cannot change current dir to $repository_folder"
    change_rhods_version
    popd > /dev/null || exit 1
    write_imagesetconfiguration
  done
}

verify_image_exists() {
  local image=$1
  local image_name=$(echo "$image" | awk -F '@' '{print $1}')
  local image_digest=$(echo "$image" | awk -F '@' '{print $2}')
  local image_sha256=$(skopeo inspect docker://"$image" | jq -r '.Digest')

  echo "Verifying image $image_name"
  if [ "$image_digest" != "$image_sha256" ]; then
    echo "Error: Image $image_name SHA256 does not match digest from skopeo"
    exit 1
  fi
  echo "Image $image_name exists with digest $image_sha256"
}

convert_image_to_digest() {
  local image=$1
  local image_name=$(echo "$image" | awk -F ':' '{print $1}')
  local image_digest=$(skopeo inspect docker://"$image" | jq -r '.Digest')
  echo "$image_name@$image_digest"
}

write_imagesetconfiguration() {
  local openvino_digest=$(convert_image_to_digest $openvino_image)
  local must_gather_digest=$(convert_image_to_digest $must_gather_image)

  if [ "$skip_image_verification" == false ]; then
    echo "Verify images"
    for image in $(grep -rE 'quay\.io/modh/.+@sha256:[a-f0-9]+' $repository_folder | awk -F ' ' '{print $3}'); do
      verify_image_exists "$image"
    done

    verify_image_exists $openvino_digest
    verify_image_exists $must_gather_digest
  else
    echo "Skipping image verification"
  fi

cat <<EOF >"$outputfile_name"
# Additional images
$(grep -rE 'quay\.io/modh/.+@sha256:[a-f0-9]+' "$repository_folder" | awk -F ' ' '{print $3}' | sed 's/^/    - /')
$(echo $openvino_digest | sed 's/^/    - /')
$(echo $must_gather_digest | sed 's/^/    - /')

# ImageSetConfiguration example
\`\`\`yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry: $skip_tls
    imageURL: $mirror_url
    skipTLS:                         
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:$openshift_version
    packages:
    - name: rhods-operator
      channels:
      - name: $channel
  additionalImages:   
$(grep -rE 'quay\.io/modh/.+@sha256:[a-f0-9]+' "$repository_folder" | awk -F ' ' '{print $3}' | sed 's/^/    - name: /')
$(echo $openvino_digest | sed 's/^/    - name: /')
$(echo $must_gather_digest | sed 's/^/    - name: /')
\`\`\`
EOF
}

change_rhods_version() {
  if [[ ! $rhods_version =~ ^rhods-[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format $rhods_version. Valid format: rhods-X.Y"
    exit 1
  fi

  echo "Switching to branch: $rhods_version"
  git switch $rhods_version || exit 1
  return 0
}

fetch_source_repo() {
  if [ -d "$repository_folder" ]; then
    echo "Update $repository_folder"
    pushd "$repository_folder" > /dev/null || echo "Error: Cannot change current dir to $repository_folder"
    git pull
    popd > /dev/null || echo "Error: Cannot move back to $repository_folder"
  else
    echo "Clone $repository_url into $repository_folder"
    git clone "$repository_url" "$repository_folder"
  fi
}

cleanup() {
  if [ -d "$repository_folder" ]; then
    echo "Remove $repository_folder"
    rm -rf "$repository_folder"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --help | -h)
    help
    exit
    ;;
  --rhods-version | -v)
    rhods_version="$2"
    shift 2
    ;;
  --all-supported-versions | -a)
    update_all_support_version=true
    shift
    ;;
  --skip-image-verification)
    skip_image_verification=true
    shift
    ;;
  --skip-tls)
    skip_tls=true
    shift
    ;;
  --set-file-name)
    outputfile_name="$2"
    shift 2
    ;;
  --set-registry)
    mirror_url="$2"
    shift 2
    ;;
  --set-repository-source)
    repository_url="$2"
    shift 2
    ;;
  --set-repository-folder)
    repository_folder="$2"
    shift 2
    ;;
  --set-channel)
    channel="$2"
    shift 2
    ;;
  --set-ocp-version)
    openshift_version="$2"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Invalid option: $1" >&2
    exit 1
    ;;
  esac
done

# Prepare
fetch_source_repo

# Main logic
if [ -n "$rhods_version" ]; then
  echo "Update with specified RHODS version $rhods_version"
else
  rhods_version=$(get_latest_rhods_version)
  echo "Update with latest RHODS version $rhods_version"
  if [ "$update_all_support_version" == true ]; then
    echo "and backwards 3 supported versions"
  fi
fi
update_outputfile

# Post
cleanup
