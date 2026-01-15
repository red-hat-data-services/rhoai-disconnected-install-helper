set -o nounset
set -o pipefail

set_defaults() {
  org_url_base="https://api.github.com/orgs/red-hat-data-services/repos?per_page=100&page="
  excluded_repos=("rhods-disconnected-install-helper" "odh-manifests" "openshift-ai-handbook")
  # Repositories to exclude from rhoai-2.24 onwards
  excluded_repos_from_rhoai_2_24=("notebooks" "must-gather" "kserve" "trustyai-service-operator" "lm-evaluation-harness" "fms-guardrails-orchestrator" "guardrails-regex-detector" "vllm-orchestrator-gateway" "guardrails-detectors")
  rhods_version="${rhods_version:-}"
  repository_folder="${repository_folder:-.odh-manifests}"
  notebooks_folder="${notebooks_folder:-.odh-notebooks}"
  notebooks_branch="${rhods_version:-main}"
  file_name="${file_name:-$rhods_version.md}"
  skip_tls="${skip_tls:-false}"
  mirror_url="${mirror_url:-registry.example.com:5000/mirror/oc-mirror-metadata}"
  repository_url="${repository_url:-https://github.com/red-hat-data-services/odh-manifests}"
  notebooks_url="${notebooks_url:-https://github.com/red-hat-data-services/notebooks}"
  openshift_version="${openshift_version:-v4.20}"
  skip_image_verification="${skip_image_verification:-false}"
  channel="${channel:-fast}"
}
# Other additional images
# must_gather_image=""

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
}

function get_latest_rhods_version() {
  local rhods_version
  rhods_version=$(git ls-remote --heads https://github.com/red-hat-data-services/rhods-operator | grep 'rhoai' | awk -F'/' '{print $NF}' | sort -V | tail -1)
  echo "$rhods_version"
}

is_rhods_version_greater_or_equal_to() {
  local version=$1
  major_version=$(echo "$version" | cut -d'-' -f2 | cut -d'.' -f1)
  minor_version=$(echo "$version" | cut -d'-' -f2 | cut -d'.' -f2)
  actual_major_version=$(echo "$rhods_version" | cut -d'-' -f2 | cut -d'.' -f1)
  actual_minor_version=$(echo "$rhods_version" | cut -d'-' -f2 | cut -d'.' -f2)
  if [ "$actual_major_version" -gt "$major_version" ] || ([ "$actual_major_version" -eq "$major_version" ] && [ "$actual_minor_version" -ge "$minor_version" ]); then
    return 0
  else
    return 1
  fi
}

function get_supported_versions() {
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
  echo "docker image: $image"
  image_sha256=$(skopeo inspect docker://"$image" | jq -r '.Digest')

  echo "Verifying image $image_name"
  echo "Image variable: $image"

  if [ "$image_digest" != "$image_sha256" ]; then
    echo "Error: Image $image_name does not exist"
    #exit 1
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

if is_rhods_version_greater_or_equal_to rhods-2.25; then
  # Only read from rhoai-disconnected-images.yaml
  IMAGES_FILE="$repository_folder/rhoai-additional-images/rhoai-disconnected-images.yaml"
  if [ -f "$IMAGES_FILE" ]; then
    ADDITIONAL_IMAGES=$(yq e '.additional-images[]' "$IMAGES_FILE")
    echo "$ADDITIONAL_IMAGES"
  fi
else
  if is_rhods_version_greater_or_equal_to rhods-2.4; then
    if is_rhods_version_greater_or_equal_to rhods-2.14; then

      # if is_rhods_version_greater_or_equal_to rhods-2.22; then
      #   # find ".odh-manifests" -type f -path "*/notebooks/manifests*"   -exec grep -hEv 'n-[2-9]' {} +   | grep -Eo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+"   | grep -v 'quay\.io/opendatahub'   | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter'   | sort -u
      #   # find ".odh-manifests" \( -path "*/notebooks/*" -o -path "*/notebooks" \) -prune -o -type f \( -path "*/manifests/*" -o -path "*/config/*" -o -path "*/jupyter/*" \) ! -name "params-vllm-cpu.env" -exec grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" {} + | grep -v 'quay\.io/opendatahub' | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' | sort -u
      #   (
      #     find "$repository_folder" \( -path "*/notebooks/*" -o -path "*/notebooks" \) -prune -o -type f \( -path "*/manifests/*" -o -path "*/config/*" -o -path "*/jupyter/*" \) ! -name "params-vllm-cpu.env" -exec grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" {} + ;
      #     find "$repository_folder" -type f -path "*/notebooks/manifests*" -exec grep -hEv 'n-(2|[3-9]|[1-9][0-9]+)' {} + | grep -Eo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+"
      #   ) | grep -v 'quay\.io/opendatahub' \
      #     | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' \
      #     | sort -u
      # else
       find "$repository_folder" -type f \( -path "*/manifests/*" -o -path "*/config/*" -o -path "*/jupyter/*" \) ! -name "params-vllm-cpu.env" -exec grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" {} + | grep -v 'quay\.io/opendatahub' | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' | sort -u
      # fi
     #find "$repository_folder" -maxdepth 2 -type d \( -name "manifests" -o -name "config" -o -name "jupyter" \) -exec bash -c 'grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" "$0"' {} \; | grep -v 'quay\.io/opendatahub' | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' | sort -u
     # find "$repository_folder" -type f \( -path "*/manifests/*" -o -path "*/config/*" -o -path "*/jupyter/*" \) ! -name "params-vllm-cpu.env" -exec grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" {} + | grep -v 'quay\.io/opendatahub' | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' | sort -u
    else  
     find "$repository_folder" -maxdepth 2 -type d \( -name "manifests" -o -name "config" -o -name "jupyter" \) -exec bash -c 'grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" "$0"' {} \; | grep -v 'quay\.io/opendatahub' | sort -u
    fi
  else
    grep -hrEo 'quay\.io/[^/]+/[^@{},]+@sha256:[a-f0-9]+' "$repository_folder" | sort -u
  fi

  if is_rhods_version_greater_or_equal_to rhods-2.10; then

    # local openvino_path="$repository_folder/odh-model-controller/config/base/params.env"
    
    # while IFS= read -r line || [[ -n "$line" ]]; do
    #   imagename_tag="${line#*=}"
    #   if [[ "$imagename_tag" == quay.io/modh/* ]]; then
    #    echo "$imagename_tag"
    #   fi
    # done < "$openvino_path"

    #additional images changes
    
    # Path to the YAML file 
    IMAGES_FILE="$repository_folder/rhoai-additional-images/rhoai-disconnected-images.yaml"

    if [ -f "$IMAGES_FILE" ]; then
      # Read the YAML file and parse it using yq
      ADDITIONAL_IMAGES=$(yq e '.additional-images[]' "$IMAGES_FILE")

      # Display the images
      echo "$ADDITIONAL_IMAGES"
    fi 


  else
  # search openvino image
    local manifests_folder=$( is_rhods_version_greater_or_equal_to rhods-2.4 && echo "/manifests" || echo "" )
    local openvino_path="$repository_folder/odh-dashboard$manifests_folder/overlays/modelserving/kustomization.yaml"

    if [ -f "$openvino_path" ]; then
      #local image_name=$(yq -r .images[0].newName "$openvino_path")
      local image_name_tag=$(yq eval '.images[] | .newName + "@" + .digest' "$openvino_path")
      echo "$image_name_tag"
    elif [ ! -f "$openvino_path" ]; then
      openvino=$(grep -hrEo 'quay\.io/[^/]+/[^@{},]+:[^@{},]+' "$repository_folder" | sort -u | sed -n '/openvino/p')
      if [ -z "$openvino" ]; then
        echo "Error: openvino image not found"
        exit 1
      fi
      image_tag_to_digest $(echo "$openvino")
    fi

    if is_rhods_version_greater_or_equal_to rhods-2.22; then
      echo "Error: rhods-2.22 detected"
      exit
    fi
  fi

fi
}

function find_notebooks_images() {
  grep -hrEo 'quay\.io/[^/]+/[^@{},]+@sha256:[a-f0-9]+' "$notebooks_folder" | sort -u
}
function unsupported_images() {
  if is_rhods_version_greater_or_equal_to rhods-2.22; then
    find "$repository_folder" -type f -path "*/notebooks/manifests*" \
      -exec grep -hE 'n-(2|[3-9]|[1-9][0-9]+)' {} + \
      | grep -Eo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" \
      | grep -v 'quay\.io/opendatahub' \
      | grep -v 'quay\.io/integreatly/prometheus-blackbox-exporter' \
      | sort -u
  fi
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
    if ! is_rhods_version_greater_or_equal_to rhods-2.4; then
      while read -r image; do
        if [[ $image =~ [{}]+ ]]; then
          continue
        fi
        verify_image_exists "$image"
      done < <(find_notebooks_images)
    fi
    # verify_image_exists "$(image_tag_to_digest $must_gather_image)"
  else
    echo "Skipping image verification"
  fi
  min_max_version=""
  if [ -z "$branch_main" ]; then
    rhods_semver="${rhods_version/rhoai-/}.0"
    min_max_version="minVersion: $rhods_semver
        maxVersion: $rhods_semver"
  fi
  if [ -n "${minmax_version:-}" ]; then
    min_max_version="minVersion: $minmax_version
        maxVersion: $minmax_version"
  fi

# Prepare unsupported section only if condition is met
if is_rhods_version_greater_or_equal_to rhods-2.22; then
  unsupported_images_section=$(
    cat <<EOF
# Unsupported Images:
These images are no longer officially supported but are still provided for convenience.
(They may be useful for users who wish to import older resources or maintain compatibility with previous setups.)

$(unsupported_images | sed 's/^/    - /')
EOF
  )
else
  unsupported_images_section=""
fi
# $(image_tag_to_digest "$must_gather_image" | sed 's/^/    - /')
cat <<EOF >"$file_name"
# Additional images:
$(find_images | sed 's/^/    - /')

$(if [ -n "$branch_main" ]; then echo "    - quay.io/modh/kserve-agent:nightly"
    echo "    - quay.io/modh/kserve-controller:nightly"
    echo "    - quay.io/modh/kserve-router:nightly"
    echo "    - quay.io/modh/kserve-storage-initializer:nightly"
fi)
$(if ! is_rhods_version_greater_or_equal_to rhods-2.4; then
find_notebooks_images | sed 's/^/    - name: /' 
fi)
$unsupported_images_section

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
        $min_max_version
  additionalImages:   
$(find_images | sed 's/^/    - name: /')

$(if [ -n "$branch_main" ]; then echo "    - name: quay.io/modh/kserve-agent:nightly"
    echo "    - name: quay.io/modh/kserve-controller:nightly"
    echo "    - name: quay.io/modh/kserve-router:nightly"
    echo "    - name: quay.io/modh/kserve-storage-initializer:nightly"
fi)
$(if ! is_rhods_version_greater_or_equal_to rhods-2.4; then
find_notebooks_images | sed 's/^/    - name: /' 
fi)

\`\`\`
EOF
}
#$(image_tag_to_digest "$must_gather_image" | sed 's/^/    - name: /')
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
  echo "Switching to $rhods_version"
  git switch "$rhods_version"
  return 0
}

function fetch_repository() {
  if is_rhods_version_greater_or_equal_to rhods-2.4; then
    echo "Cloning repositories"
    clone_all_repos
  else
    if [ -d "$repository_folder" ]; then
      echo "Update $repository_folder"
      pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
      git pull
      popd || echo "Error: Directory $repository_folder does not exist"
    else
      echo "Clone $repository_folder"
      git clone "$repository_url" "$repository_folder"
    fi
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
    git checkout "$notebooks_branch"
    popd || echo "Error: Directory $notebooks_folder does not exist"
  fi
}

# Check github rate limit
check_github_rate_limit() {
    response=$(curl -s https://api.github.com/rate_limit)
    limit=$(echo "$response" | jq -r '.resources.core.limit')
    remaining=$(echo "$response" | jq -r '.resources.core.remaining')
    reset=$(echo "$response" | jq -r '.resources.core.reset')
    reset_date=$(date -d @$reset)

    if [ "$remaining" -eq 0 ]; then
      echo "GitHub rate limit has been reached. Wait until $reset_date to continue."
      echo "Rate limit: $limit"
      echo "Remaining requests: $remaining"
      echo "Reset time: $reset_date"
      exit 1
    fi
}

function get_next_page_url() {
  local org_url=$1
  curl -sI "$org_url" | awk '/Link:/ {match($0,/\<(https[^;]*)\>; rel="next"/,a); print a[1]}'
}

function branch_exists() {
  local repo=$1
  local version=$2
  git ls-remote --heads "https://github.com/red-hat-data-services/$repo.git" "$version" | grep -q "$version"
}

function clone_repo() {
  local repo=$1
  local version=$2
  echo "cloning $repo with version $version"
  git clone --depth 1 -b "$version" "https://github.com/red-hat-data-services/$repo.git" "$repository_folder/$repo" 
  if [ $? -ne 0 ]; then
    echo "Error: Failed to access $repo"
    return 1
  fi
}

function clone_default_repo() {
  local repo=$1
  echo "cloning $repo repo"
  git clone "https://github.com/red-hat-data-services/$repo.git" "$repository_folder/$repo" 
  if [ $? -ne 0 ]; then
    echo "Error: Failed to access $repo"
    return 1
  fi
}


function is_repo_excluded() {
  local repo=$1
  
  # Check general excluded repos
  for excluded_repo in "${excluded_repos[@]}"; do
    if [[ "$repo" == "$excluded_repo" ]]; then
      return 0
    fi
  done
  
  # Check version-specific excluded repos (rhoai-2.24 and later)
  if is_rhods_version_greater_or_equal_to rhoai-2.24; then
    for excluded_repo in "${excluded_repos_from_rhoai_2_24[@]}"; do
      if [[ "$repo" == "$excluded_repo" ]]; then
        return 0
      fi
    done
  fi
  
  return 1
}

function clone_all_repos() {
  local org_url="${org_url_base}"
  check_github_rate_limit
  while :; do
    local repos
    repos=$(curl -s "$org_url" | jq -r '.[] | .name')
    if [ -z "$repos" ]; then
      break
    fi
    org_url=$(get_next_page_url "$org_url")
    for repo in $repos; do
      if ! is_repo_excluded "$repo"; then
        if branch_exists "$repo" "$rhods_version"; then
          if [ -z "$branch_main" ]; then
            clone_repo "$repo" "$rhods_version"
          else
            clone_default_repo "$repo"   
          fi  
        fi
      fi
    done
  done
}

function find_quay_images() {
  local repository_folder=$repository_folder
  find "$repository_folder" -maxdepth 2 -type d \( -name "manifests" -o -name "config" -o -name "jupyter" \) -exec bash -c 'grep -hrEo "quay\.io/[^/]+/[^@\{\},]+@sha256:[a-f0-9]+" "$0"' {} \; | grep -v 'quay\.io/opendatahub' | sort -u
}

function count_number_images() {
  find_quay_images | wc -l
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

function test_current_branch_name() {
  branchName=$1

  repo_folder="$repository_folder/kubeflow"
  # Check if the repository folder exists
  if [ -d "$repo_folder" ]; then
      # Navigate to the repository folder
      cd "$repo_folder" || exit

      # Check the git branch
      branch=$(git rev-parse --abbrev-ref HEAD)
      echo "Current branch for $branchName: $branch"
  else
      echo "Repository folder not found"
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
    -h | --help)
      help
      exit
      ;;
    --rhoai-version | -v)
      rhods_version="$2"
      file_name="$rhods_version.md"
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
# function update_must_gather() {
#   if is_rhods_version_greater_or_equal_to rhods-2.10; then
#     must_gather_image="quay.io/modh/must-gather:$rhods_version"
#   else
#     must_gather_image="quay.io/modh/must-gather:stable"
#   fi
  
# }
