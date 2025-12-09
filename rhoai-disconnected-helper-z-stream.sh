#!/bin/bash

source rhoai-z-dih.sh

function main(){
  rhoai_version=$1
  channel=$2
  rhods_version=""
  branch_main=""

  set_defaults

  if [ -z "$rhoai_version" ]; then
    echo "No version provided"
    exit 1
  fi
    # Validate the version string against the pattern x.y.z
  if [[ ! "$rhoai_version" =~ ^rhoai-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format. Expected format: rhoai-x.y.z"
    exit 1
  fi
  minmax_version=$(echo $rhoai_version | sed 's/rhoai-//')
  if [ -z "$rhods_version" ]; then
    rhods_version=$(echo "$rhoai_version" | sed 's/rhoai-\([0-9]*\.[0-9]*\)\.[0-9]*/rhoai-\1/')
    
    file_name="$rhoai_version.md"
    echo "Use latest RHODS version $rhods_version"  
    echo "File Name $file_name"
    # update_must_gather
    # echo $must_gather_image
  fi
  if is_rhods_version_greater_or_equal_to rhods-2.4; then
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
  #test_current_branch_name "$rhods_version"
  cleanup
  
}
main "$@"
