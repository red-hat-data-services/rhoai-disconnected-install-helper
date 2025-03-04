#!/bin/bash

source rhoai-dih.sh

function validate_rhoai_branch() {
  local branch="$1"
  if [[ ! "$branch" =~ ^rhoai-[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid rhoai branch format '$branch'. Expected format: rhoai-X.Y (e.g., rhoai-2.18)."
    exit 1
  fi
}

function main() {
  set_defaults
  parse_args "$@"
  rhods_version="${2:-}"

  if [[ -n "$rhods_version" ]]; then
    validate_rhoai_branch "$rhods_version"  # Validate user input
    releases=("$rhods_version")  # Store input argument as an array
  else
    mapfile -t releases < <(yq e '.releases[]' releases.yaml)
  fi

  echo "Releases: ${releases[@]+"${releases[@]}"}"  # Prevents empty array issues

  for release in "${releases[@]}"; do
      branch_main=""
     
      if [ -z "$rhods_version" ]; then
        rhods_version="$release"
        file_name="$rhods_version.md"
      fi
      echo "Use latest RHODS version $rhods_version"  
      update_must_gather
      echo "$must_gather_image"

      if is_rhods_version_greater_or_equal_to rhods-2.4; then
        echo "Cloning repositories"
        clone_all_repos
      else
        fetch_repository
        pushd "$repository_folder" || { echo "Error: Directory $repository_folder does not exist"; exit 1; }
        change_rhods_version
        popd || exit 1
        fetch_notebooks_repository
      fi
      
      image_set_configuration
      cleanup
      rhods_version=""
done
}

main "$@"
