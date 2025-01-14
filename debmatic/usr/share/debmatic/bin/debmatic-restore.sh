#!/bin/bash

set -e

if [ $EUID != 0 ]; then
  echo "Please run as root"
  exit
fi

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "debmatic-restore <backupfile>"
  exit 1
fi

CONFIGDIR="/etc/config"
BACKUPFILE=`realpath $1`

if [ `systemctl is-active debmatic-rega.service` == "active" ]; then
  echo "load tclrega.so; rega system.Save()" | /bin/tclsh
fi

TMPDIR=`mktemp -d`

systemctl stop debmatic.service

# now remove the whole /etc/config
find $CONFIGDIR -mindepth 1 -maxdepth 1 -exec rm -rf {} \;

if [ ! "$(ls -A /etc/config)" ]; then
  tar --warning=no-timestamp --no-same-owner -xf $BACKUPFILE -C $TMPDIR/

  # extract usr_local.tar.gz but make sure NOT to unarchive anything outside
  tar -xf $TMPDIR/usr_local.tar.gz --warning=no-timestamp --no-same-owner --strip-components=2 -C /

  # fix $CONFIGDIR/localtime
  rm $CONFIGDIR/localtime
  ln -s /usr/share/zoneinfo/Europe/Berlin $CONFIGDIR/localtime

#  cd $CURDIR
  rm -rf $TMPDIR

  sync
else
  echo "DebMatic data-directory not empty, please check ${CONFIGDIR}"
fi

systemctl start debmatic.service

echo "Backup from $BACKUPFILE restored"

