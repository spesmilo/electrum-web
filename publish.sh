# sign website commit and publish it
# uploadserver needs to be defined in /etc/hosts

user=$1
if [ -z $user ]; then
    echo "usage: publish.sh gpg_username"
    exit 1
fi
set -ex
cd "$(dirname "$0")"
echo $(git rev-parse master)

PUBKEY=""
if [ $user == "ThomasV" ]; then
    PUBKEY="--local-user 6694D8DE7BE8EE5631BED9502BD5824B7F9470E6"
elif [ $user == "sombernight_releasekey" ]; then
    PUBKEY="--local-user 0EEDCFD5CAFB459067349B23CA9EEEC43DF911DC"
fi
git rev-parse master | gpg --sign --armor --detach $PUBKEY > website.$user.asc

sftp -oBatchMode=no -b - ${user,,}@uploadserver << !
   cd electrum-downloads-airlock
   mput website.$user.asc
   bye
!
