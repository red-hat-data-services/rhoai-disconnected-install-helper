#!/bin/bash

source rhoai-z-dih.sh

function main(){
  rhods_version=""
  branch_main=""
  rhoai_version=""

  set_defaults

  # Support both: "-v rhoai-3.4.1" and "rhoai-3.4.1 channel" (positional args)
  if [[ "${1:-}" == "-v" || "${1:-}" == "--rhoai-version" ]]; then
    rhoai_version="${2:-}"
    shift 2 || true
    # Parse remaining flags
    parse_args "$@"
  elif [[ "${1:-}" =~ ^rhoai- ]]; then
    rhoai_version="$1"
    channel="${2:-fast}"
    shift 2 2>/dev/null || shift 1 2>/dev/null || true
    parse_args "$@"
  else
    parse_args "$@"
    rhoai_version="${rhods_version:-}"
  fi

  if [ -z "$rhoai_version" ]; then
    echo "No version provided"
    exit 1
  fi

  if [[ ! "$rhoai_version" =~ ^rhoai-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format. Expected format: rhoai-x.y.z (e.g., rhoai-3.4.1)"
    exit 1
  fi

  minmax_version=$(echo "$rhoai_version" | sed 's/rhoai-//')
  rhods_version=$(echo "$rhoai_version" | sed 's/rhoai-\([0-9]*\.[0-9]*\)\.[0-9]*/rhoai-\1/')
  file_name="$rhoai_version.md"

  echo "Use latest RHODS version $rhods_version"
  echo "File Name $file_name"

  if is_rhods_version_greater_or_equal_to rhods-2.25; then
    echo "Fetching additional images from rhoai-additional-images repo (branch: $rhods_version)"
    mkdir -p "$repository_folder"
    clone_repo "rhoai-additional-images" "$rhods_version"
  elif is_rhods_version_greater_or_equal_to rhods-2.4; then
    echo "Cloning repositories"
    clone_all_repos
  else
    fetch_repository
    pushd "$repository_folder" || echo "Error: Directory $repository_folder does not exist"
    change_rhods_version
    popd || exit 1
    fetch_notebooks_repository
  fi

  image_set_configuration
  cleanup
}
main "$@"
