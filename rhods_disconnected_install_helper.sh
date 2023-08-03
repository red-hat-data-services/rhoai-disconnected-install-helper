#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

rhods_version=""
repository_folder=".odh-manifests"
file_name="$rhods_version.md"
skip_tls="false"
mirror_url="registry.example.com:5000/mirror/oc-mirror-metadata"
repository_url="https://github.com/red-hat-data-services/odh-manifests"
openshift_version="v4.12"
skip_image_verification="false"
channel="stable"

# Other additional images
must_gather_image="quay.io/modh/must-gather:stable"

help() {
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
}

get_latest_rhods_version() {
  local rhods_version
  rhods_version=$(git branch -a | grep remotes/origin/rhods | awk -F '/' '{print $NF}' | sort -V | tail -1)
  echo "$rhods_version"
}

get_supported_versions() {
  #!/bin/bash

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
  # cleanup
}

verify_image_exists() {
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

image_tag_to_digest() {
  local image=$1
  local image_name
  local image_digest
  image_name=$(echo "$image" | awk -F ':' '{print $1}')
  image_digest=$(skopeo inspect docker://"$image" | jq -r '.Digest')
  echo "$image_name@$image_digest"
}
image_search(){
  grep -hrEo 'quay\.io/[^/]+/[^@{},]+@sha256:[a-f0-9]+' "$repository_folder" | sort -u
  # search openvino image
  local image_name=$(yq -r .images[0].newName "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml)
  local image_tag=$(yq -r .images[0].digest "$repository_folder"/odh-dashboard/modelserving/kustomization.yaml)
  echo "$image_name@$image_tag"
}
image_set_configuration() {
  if [ "$skip_image_verification" == "false" ]; then
    echo "Verify images"
    while read -r image; do
      # verify that the image doesn't have } or { or , in the string
      if [[ $image =~ [{}]+ ]]; then
        continue
      fi
      verify_image_exists "$image"
    done < <(image_search)

    verify_image_exists "$(image_tag_to_digest $must_gather_image)"
  else
    echo "Skipping image verification"
  fi

cat <<EOF >"$file_name"
# Additional images:
$(image_search | sed 's/^/    - /')
$(image_tag_to_digest "$must_gather_image" | sed 's/^/    - /')

# ImageSetConfiguration example:
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
$(image_search | sed 's/^/    - name: /')
$(image_tag_to_digest "$must_gather_image" | sed 's/^/    - name: /')
\`\`\`
EOF
}

change_rhods_version() {
  echo "Change rhods version $rhods_version branch"

  if [[ ! $rhods_version =~ ^rhods-[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format $rhods_version. Valid format: rhods-X.Y"
    exit 1
  fi

  if ! git branch -a | grep -q "$rhods_version"; then
    echo "Error: Version $rhods_version does not exist"
    exit 1
  fi
  echo "Switching to $rhods_version"
  git switch "$rhods_version"
  return 0
}

fetch_repository() {
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

cleanup() {
  if [ -d "$repository_folder" ]; then
    echo "Remove $repository_folder"
    rm -rf "$repository_folder"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  -h | --help)
    help
    exit
    ;;
  --rhods-version | -v)
    rhods_version="$2"
    file_name="imageset-config-$rhods_version.md"
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
  --channel)
    channel="$2"
    shift
    shift
    ;;
  --openshift-version)
    openshift_version="$2"
    shift
    shift
    ;;
  --supported-versions)
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
image_set_configuration
cleanup
