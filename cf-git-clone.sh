#!/bin/bash
source volume/cf-ssh-vars

git_retry () {
# Retry git on exit code 128
(
   set +e
   RETRY_ON_SIGNAL=128
   COMMAND=$@
   local TRY_NUM=1 MAX_TRIES=4 RETRY_WAIT=5
   until [[ "$TRY_NUM" -ge "$MAX_TRIES" ]]; do
      $COMMAND
      EXIT_CODE=$?
      if [[ $EXIT_CODE == 0 ]]; then
        break
      elif [[ $EXIT_CODE == "$RETRY_ON_SIGNAL" ]]; then
        echo "Failed with Exit Code $EXIT_CODE - try $TRY_NUM "
        TRY_NUM=$(( ${TRY_NUM} + 1 ))
        sleep $RETRY_WAIT
      else
        break
      fi
   done
   return $EXIT_CODE
   )
}

set -e
mkdir -p volume
cd volume
git config --global advice.detachedhead false

# Check if the cloned dir already exists from previous builds
if [ -d "$CF_REPO_NAME" ]; then
  # Cloned dir already exists from previous builds so just fetch all the changes
  echo "Preparing to update $REPO"
  cd $CF_REPO_NAME
  # Make sure the CLONE_DIR folder is a git folder
  if git status &> /dev/null ; then
      # Reset the remote URL because the embedded user token may have changed
      git remote set-url origin $REPOSITORY_LINK

      echo "Cleaning up the working directory"
      git reset -q --hard
      git clean -df
      #git gc --force
      git_retry git remote prune origin $REPOSITORY_LINK
      git_retry git fetch origin --tags --prune "+refs/tags/*:refs/tags/*"

      echo "Fetching the updates from origin"
      git_retry git fetch
      git_retry git fetch --tags

      if [ -n "$CF_REVISION" ]; then

          echo "Updating $REPO to revision $CF_REVISION"
          git checkout  $CF_REVISION

          CURRENT_BRANCH="`git branch 2>/dev/null | grep '^*' | cut -d' ' -f2-`"

          # If the revision is identical to the current branch we can rebase it with the latest changes. This isn't needed when running detached
          if [ "$CF_REVISION" == "$CURRENT_BRANCH" ]; then
             echo 'Rebasing current branch $CF_REVISION to latest changes...'
             git rebase
          fi
      fi
  else
      # The folder already exists but it is not a git repository
      # Clean folder and clone a fresh copy on current directory
      cd ..
      rm -rf $CF_REPO_NAME
      echo "cloning $CF_REPO_NAME"
      git_retry git clone $REPOSITORY_LINK $CF_REPO_NAME
      cd $CF_REPO_NAME

      if [ -n "$CF_REVISION" ]; then
        git checkout   $CF_REVISION
      fi
  fi
else

  # Clone a fresh copy
  echo "cloning "
  git_retry git clone $REPOSITORY_LINK $CF_REPO_NAME
  cd $CF_REPO_NAME

  if [ -n "$CF_REVISION" ]; then
    git checkout $CF_REVISION
  fi
fi
