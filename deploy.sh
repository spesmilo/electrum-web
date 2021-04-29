#!/bin/bash
# cron job for the webserver
set -ex
cd "$(dirname "$0")"

# fixme: we should not poll github
git fetch github

echo "latest commit $(git rev-parse github/master)"
LOCAL_VERSION=$(git show master:version|jq '.version'|tr -d '"')
VERSION=$(git show github/master:version|jq '.version'|tr -d '"')

echo "local version: $LOCAL_VERSION "
echo "github version: $VERSION "

sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads-airlock
   get website.ThomasV.asc
   get website.SomberNight.asc
   bye
!

git rev-parse github/master | gpg --verify website.ThomasV.asc -
git rev-parse github/master | gpg --verify website.SomberNight.asc -

echo "website signature verified"

if [ $LOCAL_VERSION = $VERSION ];
then
    echo "updating website and exiting"
    git pull github master
    exit 0
fi

# 1. read from the airlock directory
rm -rf airlock
mkdir airlock
cd airlock

sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads-airlock
   cd $VERSION
   mget *
   bye
!

# verify signatures
tgz=Electrum-$VERSION.tar.gz
appimage=electrum-$VERSION-x86_64.AppImage
zip=Electrum-$VERSION.zip
dmg=electrum-$VERSION.dmg
win=electrum-$VERSION.exe
win_setup=electrum-$VERSION-setup.exe
win_portable=electrum-$VERSION-portable.exe

for item in $tgz $appimage $zip $win $win_setup $win_portable
do
    gpg --verify $item $item.ThomasV.asc
    gpg --verify $item $item.SomberNight.asc
done

# dmg
gpg --verify $dmg $dmg.ThomasV.asc

echo "verification passed"

# publish files
sftp -oBatchMode=no -b - pubwww@uploadserver << !
   cd electrum-downloads
   mkdir $VERSION
   cd $VERSION
   mput *
   bye
!

# update website
git pull github master

# todo: clear cloudflare cache
