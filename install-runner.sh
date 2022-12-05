#!/bin/bash
set -xe

cd "$(dirname "$0")"

arch="${1:-arm64}"

# translate poor naming schema for the runner downloads
runner_arch="${arch}"
[ "${runner_arch}" == "amd64" ] && runner_arch="x64"

runner_plat="linux"

apt update && apt install -y sudo curl jq
rm -rf /var/lib/apt/lists/*
useradd -d /runner -s /bin/bash runner
echo '%runner ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/runner
chmod u=r,g=r,o= /etc/sudoers.d/runner

#---------------------------------------
# Download latest released and extract
#---------------------------------------
echo
echo "Downloading latest runner ..."

# For the GHES Alpha, download the runner from github.com
latest_version_label=$(curl -s -X GET 'https://api.github.com/repos/actions/runner/releases/latest' | jq -r '.tag_name')
latest_version=$(echo ${latest_version_label:1})
runner_file="actions-runner-${runner_plat}-${runner_arch}-${latest_version}.tar.gz"

if [ -f "${runner_file}" ]; then
    echo "${runner_file} exists. skipping download."
else
    runner_url="https://github.com/actions/runner/releases/download/${latest_version_label}/${runner_file}"

    echo "Downloading ${latest_version_label} for ${runner_plat} ..."
    echo $runner_url

    curl -O -L ${runner_url}
fi

ls -la *.tar.gz

#---------------------------------------------------
# extract to runner directory in this directory
#---------------------------------------------------
echo
mkdir /runner
echo "Extracting ${runner_file} to /runner"
tar xzf "./${runner_file}" -C /runner
sudo chown -R runner:runner /runner

rm -rf "./${runner_file}"

# install deps
/runner/bin/installdependencies.sh
