#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

set_defaults() {
  rhods_version="${rhods_version:-}"
  repository_folder="${repository_folder:-.odh-manifests}"
  notebooks_folder="${notebooks_folder:-.odh-notebooks}"
  notebooks_branch="${notebooks_branch:-}"
  file_name="${file_name:-$rhods_version.md}"
  skip_tls="${skip_tls:-false}"
  mirror_url="${mirror_url:-registry.example.com:5000/mirror/oc-mirror-metadata}"
  repository_url="${repository_url:-https://github.com/red-hat-data-services/odh-manifests}"
  notebooks_url="${notebooks_url:-https://github.com/red-hat-data-services/notebooks}"
  openshift_version="${openshift_version:-v4.13}"
  skip_image_verification="${skip_image_verification:-false}"
  channel="${channel:-stable}"
}
# Other additional images
must_gather_image="quay.io/modh/must-gather:stable"

function help() {
  echo "Usage: script.sh [-h] [-v] [--skip-image-verification] [--skip-tls]"
  echo "  -h, --help  Display this help message"
  echo "  -v, --rhods-version  RHODS version. Valid format: rhods-X.Y"
  echo "  --skip-image-verification  Skip image verification"
  echo "  --skip-tls  Skip TLS verification"
  echo "  --set-repository-source  Set the repository source"
  echo "  --set-file-name  Set the file name"
  echo "  --set-registry  Set the registry"
  echo "  --set-openshift-version  Set the OpenShift version"
  echo "  --set-channel  Set the channel"
  echo "  --notebooks-branch  Set the notebooks branch"
}

function get_latest_rhods_version() {
  local rhods_version
  rhods_version=$(git branch -a | grep remotes/origin/rhods | awk -F '/' '{print $NF}' | sort -V | tail -1)
  echo "$rhods_version"
}

function get_supported_versions() {
  # Get the latest version
  pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
  latest_rhods_version=$(get_latest_rhods_version)
  popd || exit 1
  
  major_version=$(echo $latest_rhods_version | cut -d'-' -f2 | cut -d'.' -f1)
  minor_version=$(echo $latest_rhods_version | cut -d'-' -f2 | cut -d'.' -f2)


  for i in {1..4}; do
    pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
    if [ $i == 1 ]; then
      minor_version=$((minor_version))
    else
      minor_version=$((minor_version - 1))
    fi
    if [ $minor_version -lt 0 ]; then
      major_version=$((major_version - 1))
      minor_version=99
    fi

    version="rhods-$major_version.$minor_version"

    rhods_version=$version
    file_name="$rhods_version.md"
    change_rhods_version
    popd || exit 1
    image_set_configuration
  done
}

function verify_image_exists() {
  local image=$1
  local image_name
  local image_digest
  local image_sha256
  image_name=$(echo "$image" | awk -F '@' '{print $1}')
  image_digest=$(echo "$image" | awk -F '@' '{print $2}')
  image_sha256=$(skopeo inspect docker://"$image" | jq -r '.Digest')

  echo "Verifying image $image_name"
  echo "Image variable: $image"

  if [ "$image_digest" != "$image_sha256" ]; then
    echo "Error: Image $image_name does not exist"
    exit 1
  fi
  echo "Image $image_name exists with digest $image_sha256"
}

function image_tag_to_digest() {
  local image=$1
  local image_name
  local image_digest
  image_name=$(echo "$image" | awk -F ':' '{print $1}')
  image_digest=$(skopeo inspect docker://"$image" | jq -r '.Digest')
  echo "$image_name@$image_digest"
}

function find_images(){
  local openvino=""
  grep -hrEo 'quay\.io/[^/]+/[^@{},]+@sha256:[a-f0-9]+' "$repository_folder" | sort -u

  # search openvino image
  if [ -f "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml ]; then
    local image_name=$(yq -r .images[0].newName "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml)
    local image_tag=$(yq -r .images[0].digest "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml)
    echo "$image_name@$image_tag"
  elif [ ! -f "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml ]; then
    openvino=$(grep -hrEo 'quay\.io/[^/]+/[^@{},]+:[^@{},]+' "$repository_folder" | sort -u | sed -n '/openvino/p')
    if [ -z "$openvino" ]; then
      echo "Error: openvino image not found"
      exit 1
    fi
    image_tag_to_digest $(echo "$openvino")
  fi
}

function find_notebooks_images() {
  grep -hrEo 'quay\.io/[^/]+/[^@{},]+@sha256:[a-f0-9]+' "$notebooks_folder" | sort -u
}

function image_set_configuration() {
  if [ "$skip_image_verification" == "false" ]; then
    echo "Verify images"
    while read -r image; do
      if [[ $image =~ [{}]+ ]]; then
        continue
      fi
      verify_image_exists "$image"
    done < <(find_images)
    while read -r image; do
      if [[ $image =~ [{}]+ ]]; then
        continue
      fi
      verify_image_exists "$image"
    done < <(find_notebooks_images)

    verify_image_exists "$(image_tag_to_digest $must_gather_image)"
  else
    echo "Skipping image verification"
  fi

cat <<EOF >"$file_name"
# Additional images:
$(find_images | sed 's/^/    - /')
$(image_tag_to_digest "$must_gather_image" | sed 's/^/    - /')
$(find_notebooks_images | sed 's/^/    - /')

# ImageSetConfiguration example:
\`\`\`yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  registry: 
    imageURL: $mirror_url
    skipTLS: $skip_tls                       
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:$openshift_version
    packages:
    - name: rhods-operator
      channels:
      - name: $channel
  additionalImages:   
$(find_images | sed 's/^/    - name: /')
$(find_notebooks_images | sed 's/^/    - name: /')
$(image_tag_to_digest "$must_gather_image" | sed 's/^/    - name: /')
\`\`\`
EOF
}

function change_rhods_version() {
  echo "Change rhods version $rhods_version branch"

  if [[ ! $rhods_version =~ ^rhods-[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format $rhods_version. Valid format: rhods-X.Y"
    exit 1
  fi

  if ! git branch -a | grep -q "$rhods_version"; then
    echo "Error: Version $rhods_version does not exist"
    exit 1
  fi

  # Set the same version for notebooks if not set otherwise via
  #   --notebooks-branch <notebooks_branch>
  if [ -z "${notebooks_branch}" ]; then
    notebooks_branch="${rhods_version}"
  fi

  echo "Switching to $rhods_version"
  git switch "$rhods_version"
  return 0
}

function fetch_repository() {
  if [ -d "$repository_folder" ]; then
    echo "Update $repository_folder"
    pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
    git pull
    popd || echo "Error: Directory $repository_folder does not exist"
  else
    echo "Clone $repository_folder"
    git clone "$repository_url" "$repository_folder"
  fi
}

function fetch_notebooks_repository() {
  if [ -d "$notebooks_folder" ]; then
    echo "Update $notebooks_folder"
    pushd "$notebooks_folder" || echo "Error: Directory $notebooks_folder does not exist"
    git checkout $notebooks_branch
    git pull origin $notebooks_branch

    popd || echo "Error: Directory $notebooks_folder does not exist"
  else
    echo "Clone $notebooks_folder"
    git clone "$notebooks_url" "$notebooks_folder"
    pushd "$notebooks_folder" || echo "Error: Directory $notebooks_folder does not exist"
    git checkout $notebooks_branch
    popd || echo "Error: Directory $notebooks_folder does not exist"
  fi
}

function cleanup() {
  if [ -d "$repository_folder" ]; then
    echo "Remove $repository_folder"
    rm -rf "$repository_folder"
  fi
  if [ -d "$notebooks_folder" ]; then
    echo "Remove $notebooks_folder"
    rm -rf "$notebooks_folder"
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
    -h | --help)
      help
      exit
      ;;
    --rhods-version | -v)
      rhods_version="$2"
      file_name="$rhods_version.md"
      shift
      shift
      ;;
    --notebooks-branch)
      notebooks_branch="$2"
      shift
      shift
      ;;
    --skip-image-verification)
      skip_image_verification=true
      shift
      ;;
    --skip-tls)
      skip_tls="true"
      shift
      ;;
    --set-file-name)
      file_name="$2"
      shift
      shift
      ;;
    --set-registry)
      mirror_url="$2"
      shift
      shift
      ;;
    --set-repository-folder)
      repository_folder="$2"
      shift
      shift
      ;;
    --set-channel)
      channel="$2"
      shift
      shift
      ;;
    --set-openshift-version)
      openshift_version="$2"
      shift
      shift
      ;;
    --supported-versions)
      fetch_notebooks_repository
      fetch_repository
      get_supported_versions
      exit
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
}

function main(){
  set_defaults
  parse_args "$@"
  fetch_repository
  pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
  if [ -z "$rhods_version" ]; then
    rhods_version=$(get_latest_rhods_version)
    file_name="$rhods_version.md"
    echo "Use latest RHODS version $rhods_version"
    change_rhods_version
  else
    change_rhods_version
  fi
  popd || exit 1
  fetch_notebooks_repository
  image_set_configuration
  cleanup
}

main "$@"