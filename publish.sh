#!/bin/bash
# sign website commit and publish it
# uploadserver needs to be defined in /etc/hosts

GPGUSER=$1
if [ -z $GPGUSER ]; then
    echo "usage: $0 gpg_username"
    exit 1
fi
set -ex
cd "$(dirname "$0")"
echo $(git rev-parse master)

export SSHUSER="$GPGUSER"
PUBKEY=""
if [ $GPGUSER == "ThomasV" ]; then
    PUBKEY="--local-user 6694D8DE7BE8EE5631BED9502BD5824B7F9470E6"
    export SSHUSER=thomasv
elif [ $GPGUSER == "sombernight_releasekey" ]; then
    PUBKEY="--local-user 0EEDCFD5CAFB459067349B23CA9EEEC43DF911DC"
    export SSHUSER=sombernight
else
    echo "ERROR! unexpected GPGUSER=$GPGUSER"
    exit 1
fi
git rev-parse master | gpg --sign --armor --detach $PUBKEY > website.$GPGUSER.asc

touch trigger_website
sftp -oBatchMode=no -b - ${SSHUSER}@uploadserver << !
    cd electrum-downloads-airlock
    mput website.$GPGUSER.asc
    -mput trigger_website
    bye
!
