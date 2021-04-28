#!/bin/bash
# cron job for the webserver
set -ex
cd "$(dirname "$0")"
git fetch github
echo "latest commit $(git rev-parse github/master)"
wget -q http://uploadserver/website.ThomasV.asc -O website.ThomasV.asc
git rev-parse github/master | gpg --verify website.ThomasV.asc -
wget -q http://uploadserver/website.SomberNight.asc -O website.SomberNight.asc
git rev-parse github/master | gpg --verify website.SomberNight.asc -

echo "ok"
git pull github master
# todo: clear cloudflare cache
