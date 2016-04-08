#!/bin/bash

# Zentao daily backup script
BACKUP_DIR=/opt/zbox/app/zentao/tmp/backup
ZIP_NAME=`date "+%y%j.tar.gz"`
echo "Zipping $ZIP_NAME"
cd $BACKUP_DIR
tar czf $ZIP_NAME *
echo "Moving $ZIP_NAME to /media/zentaobak"
mv $ZIP_NAME /media/zentaobak
echo "Removing local backups"
rm ./*.php
echo "Removing old backups"
cd /media/zentaobak
DATE=`date "+%y%j"`
OUT_DATA=`expr $DATE - 7`
rm $OUT_DATA".tar.gz"
echo "Done."
