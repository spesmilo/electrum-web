# sign website commit and publish it
# uploadserver neess to be defined in /etc/hosts

user=$1
if [ -z $user ]; then
    echo "usage: publish.sh gpg_username"
    exit 1
fi
set -ex
cd "$(dirname "$0")"
echo $(git rev-parse master)
git rev-parse master | gpg --armor --detach > website.$user.asc
sftp -oBatchMode=no -b - ${user,,}@uploadserver << !
   cd electrum-downloads-airlock
   mput website.$user.asc
   bye
!
