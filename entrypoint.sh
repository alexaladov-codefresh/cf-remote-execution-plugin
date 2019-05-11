#!/bin/bash

set -e

for reqV in HOST_ADDRESS SSH_PRV_KEY SSH_PUB_KEY SSH_USERNAME SSH_PORT GIT_CONTEXT ; do
    if [ -z ${!reqV} ]; then echo "The variable $reqV is not set, stopping..."; exit 1; fi
done

ssh-keyscan "${HOST_ADDRESS}" > /root/.ssh/known_hosts
echo "${SSH_PRV_KEY}" | base64 -d > /root/.ssh/id_rsa
echo "${SSH_PUB_KEY}" | base64 -d > /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa.pub

echo "Preparing env variables..."
export GIT_ACCESS_TOKEN=$(curl -s -H "Authorization: $CF_API_KEY" https://g.codefresh.io/api/contexts/$GIT_CONTEXT?decrypt=true | jq .spec.data.auth.password --raw-output)
export REPOSITORY_LINK=${CF_COMMIT_URL%%//*}//$GIT_ACCESS_TOKEN@$(echo $CF_COMMIT_URL | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")/$CF_REPO_OWNER/$CF_REPO_NAME.git
set | sed '/HOSTNAME=\|HOME=\|BASH=\|BASH_VERSINFO=\|BASHOPTS=\|BASH_ALIASES=\|BASH_ARGC=\|BASH_ARGV=\|EUID=\|PPID=\|SHELLOPTS=\|UID=\|TERM=\|PATH=\|PWD=/d'  | awk '$0="export "$0' > /cf-ssh-vars

echo "Copying context..."
rsync  -zae "ssh -p${SSH_PORT} -o LogLevel=ERROR" /cf-ssh-vars ${SSH_USERNAME}@${HOST_ADDRESS}:~/volume/

echo "Starting Git Clone..."
ssh ${SSH_USERNAME}@${HOST_ADDRESS} -p ${SSH_PORT} "bash -s" < /cf-git-clone.sh

echo "Starting remote session..."
ssh ${SSH_USERNAME}@${HOST_ADDRESS} -p ${SSH_PORT} "source volume/cf-ssh-vars && rm -f volume/cf-git-clone.sh && rm -f volume/cf-ssh-vars && cd volume/$CF_REPO_NAME ; $@"

