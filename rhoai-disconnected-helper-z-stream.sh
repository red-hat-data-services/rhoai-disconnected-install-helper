#!/bin/bash

source rhoai-dih.sh

function main(){
  echo "Enter branch name (rhoai-x.y):"
  read branch_name

  echo "Enter z-stream version (rhoai-x.y.z):"
  read rhoai_version
  #branch_name=$1
  #rhoai_version=$2

   branch_main=""

  set_defaults
  if [ -z "$rhods_version" ]; then
    rhods_version="$branch_name"
    file_name="$rhoai_version.md"
    echo "Use latest RHODS version $rhods_version"  
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