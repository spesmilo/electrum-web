#!/bin/bash
# cron job for the webserver
set -ex

REPODIR="$(dirname "$(readlink -e "$0")")"

date -u

rm -rf /tmp/airlock
mkdir /tmp/airlock
cd /tmp/airlock

sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads-airlock
   -get trigger_website
   -rm trigger_website
   -get trigger_binaries
   -rm trigger_binaries
   bye
!

# Maybe update website.
# This could also update this script itself (but only for subsequent runs!)
if [ -f trigger_website ]; then
    echo "file trigger found: trigger_website."
    cd "$REPODIR"
    git fetch github
    LOCAL_COMMIT="$(git rev-parse master)"
    REMOTE_COMMIT="$(git rev-parse github/master)"

    if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
        echo "no changes for website."
    else
        echo "found some changes for website."

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
    fi
else
    echo "file trigger NOT found: trigger_website."
fi


# Maybe upload binaries.
cd /tmp/airlock
if [ ! -f trigger_binaries ] || [ ! -s trigger_binaries ]; then
    echo "file trigger NOT found or is empty: trigger_binaries."
else
    echo "file trigger found: trigger_binaries."
    TRIGGERVERSION="$(cat trigger_binaries)"
    echo "TRIGGERVERSION: $TRIGGERVERSION"

    # Read binaries/etc from the airlock directory, based on TRIGGERVERSION
    rm -rf /tmp/airlock
    mkdir /tmp/airlock
    cd /tmp/airlock

    sftp -oBatchMode=no -b - pubwww@uploadserver << !
        cd electrum-downloads-airlock
        cd "$TRIGGERVERSION"
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
        -mkdir "$TRIGGERVERSION"
        cd "$TRIGGERVERSION"
        -mput *
        bye
!

fi

# todo: clear cloudflare cache
