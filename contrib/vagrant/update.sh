#!/bin/sh

BOX=$1
if [ -z "${BOX}" ]; then
  echo "$(basename $0) <box-name>" >&2
  exit 1
fi
BOX_DIR=$(echo "${BOX}" | sed -e 's/\//-VAGRANTSLASH-/g')

pushd `dirname $0` > /dev/null
HERE=`pwd`
popd > /dev/null

echo "Updating the box to make sure you have the latest one."
vagrant box update --box "${BOX}" --provider virtualbox

if [ ! -d ~/.vagrant.d/boxes/${BOX_DIR} ]; then
  exit 1
fi
cd ~/.vagrant.d/boxes/${BOX_DIR}

VERSION=$(ls -1 | sort -t . -k 1,1n -k 2,2n -k 3,3n | grep -v metadata_url | tail -n 1)
echo "The latest version you have is ${VERSION}."

cd "${HERE}"

jq -f sort.jq ~/.vagrant.d/data/machine-index/index > index.old

jq -f update.jq --arg box "${BOX}" --arg version "${VERSION}" ~/.vagrant.d/data/machine-index/index > index.new

echo "diff index.old index.new"
if ! diff index.old index.new; then
  read -p "Are you sure to update the Vagrant index file (y/n)? " -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp ~/.vagrant.d/data/machine-index/index index.org
    jq -c -f update.jq --arg box "${BOX}" --arg version "${VERSION}" ~/.vagrant.d/data/machine-index/index > index
    cp index ~/.vagrant.d/data/machine-index/index
    echo "The index file has been updated!"
    echo "The original index file has been saved as ${HERE}/index.org."
  else
    echo "Aborted!"
  fi
else
  echo "No need to update."
fi
