#!/bin/bash
# cron job for the webserver
set -ex

REPODIR="$(dirname "$(readlink -e "$0")")"
cd "$REPODIR"

date -u

# fixme: we should not poll github
git fetch github
LOCAL_COMMIT="$(git rev-parse master)"
REMOTE_COMMIT="$(git rev-parse github/master)"

if [ $LOCAL_COMMIT = $REMOTE_COMMIT ];
then
    echo "no changes, exiting"
    exit 0
fi

LOCAL_VERSION=$(cat version|jq '.version'|tr -d '"')
VERSION=$(git show github/master:version|jq '.version'|tr -d '"')

echo "local version: $LOCAL_VERSION "
echo "github version: $VERSION "

sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads-airlock
   get website.ThomasV.asc
   get website.sombernight_releasekey.asc
   bye
!

git rev-parse github/master | gpg --no-default-keyring --keyring "$REPODIR/gpg/thomasv.gpg" --verify website.ThomasV.asc -
git rev-parse github/master | gpg --no-default-keyring --keyring "$REPODIR/gpg/sombernight_releasekey.gpg" --verify website.sombernight_releasekey.asc -

echo "website signature verified"
# Update website immediately (in case the rest of the script crashes)
git merge --ff-only FETCH_HEAD


# Read from the airlock directory
rm -rf /tmp/airlock
mkdir /tmp/airlock
pushd /tmp/airlock

sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads-airlock
   cd $VERSION
   mget *
   bye
!

# verify signatures of binaries
for item in ./*
do
    if [[ "$item" == *".asc" ]]; then
        :  # skip verifying signature-files
    else
        # All other files should be reproducible binaries; verify two sigs.
        # In case we upload any other file for whatever reason, both sigs are needed too.
        gpg --no-default-keyring --keyring "$REPODIR/gpg/thomasv.gpg" --verify "$item.ThomasV.asc" "$item"
        gpg --no-default-keyring --keyring "$REPODIR/gpg/sombernight_releasekey.gpg" --verify "$item.sombernight_releasekey.asc" "$item"
        # create aggregated signature file
        cat $item.*.asc > "$item.asc"
    fi
done

echo "verification passed"

# publish files
sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads
   -mkdir $VERSION
   cd $VERSION
   mput *
   bye
!

popd

# todo: clear cloudflare cache
