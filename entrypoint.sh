#!/bin/bash
set -e

# used for fatal error messaging
function fatal()
{
   echo "error: $1" >&2
   exit 1
}

# when DEBUG is not empty, echo command output
[ -z "${DEBUG}" ] || set -x
# when SUDO is empty, disable sudo access for runner
[ -z "${SUDO}" ] && rm -rf /etc/sudoers.d/runners
# when PERSISTENT is empty, set the ephemeral flag
[ -z "${PERSISTENT}" ] && EPHEMERAL_FLAG="--ephemeral"

# if RUNNER_CFG_PAT is empty, return error
[ -z "${RUNNER_CFG_PAT}" ] && fatal "environment variable RUNNER_CFG_PAT is required"
# if RUNNER_SCOPE is empty, return error
[ -z "${RUNNER_SCOPE}" ] && fatal "environment variable RUNNER_SCOPE is required"

# ensure labels include self-hosted
LBL_LIST=$(echo ${LABELS} | tr ',' ' ')
LABELS="self-hosted"
for lbl in ${LBL_LIST}; do
    [[ "${lbl}" != "self-hosted" ]] && LABELS="${LABELS},${lbl}"
done

# default runner name to hostname
[ -z "${RUNNER_NAME}" ] && RUNNER_NAME="${HOSTNAME}"
# fail if empty, this should not happen
[ -z "${RUNNER_NAME}" ] && fatal "failed to produce a runner name, this will happen when the environment lacks a HOSTNAME value"

#--------------------------------------
# Get a config token
#--------------------------------------
echo
echo "Generating a registration token..."

base_api_url="https://api.github.com"
if [ -n "${GH_HOSTNAME}" ]; then
    base_api_url="https://${GH_HOSTNAME}/api/v3"
fi

# if the scope has a slash, it's a repo runner
orgs_or_repos="orgs"
if [[ "$RUNNER_SCOPE" == *\/* ]]; then
    orgs_or_repos="repos"
fi

export RUNNER_TOKEN=$(curl -s -X POST ${base_api_url}/${orgs_or_repos}/${RUNNER_SCOPE}/actions/runners/registration-token -H "accept: application/vnd.github.everest-preview+json" -H "authorization: token ${RUNNER_CFG_PAT}" | jq -r '.token')

if [ "null" == "$RUNNER_TOKEN" -o -z "$RUNNER_TOKEN" ]; then
    fatal "Failed to get a token"
fi

#---------------------------------------
# Unattend config
#---------------------------------------
runner_url="https://github.com/${RUNNER_SCOPE}"
if [ -n "${ghe_hostname}" ]; then
    runner_url="https://${ghe_hostname}/${RUNNER_SCOPE}"
fi

echo
echo "Configuring ${runner_name} @ $runner_url"
echo "/runner/config.sh --unattended --url $runner_url --token *** --replace --name "${RUNNER_NAME}" --labels ${LABELS} ${runner_group:+--runnergroup "$runner_group"} --disableupdate ${EPHEMERAL_FLAG}"
/runner/config.sh --unattended --url $runner_url --token ${RUNNER_TOKEN} --replace --name "${RUNNER_NAME}" --labels ${LABELS} ${runner_group:+--runnergroup "$runner_group"} --disableupdate ${EPHEMERAL_FLAG}

# start runner
echo
/runner/run.sh
