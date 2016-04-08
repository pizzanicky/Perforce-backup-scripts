#!/bin/bash

BACKUP_DIR=/media/backup
DEPOT_DIR=/usr/local/p4root
P4=/usr/local/bin/p4
USER=xxxxx
PASSWORD=xxxx
DATE=`date "+%y%j"`
OUT_DATA=`expr $DATE - 7`

# Verify the depot
echo "=========Verify depot=========="
$P4 -u $USER -P $PASSWORD verify //...

# Create checkpoint and journal
echo "Generating checkpoint and journal..."
$P4 -u $USER -P $PASSWORD admin checkpoint

# Create backup sub dir
echo "Create today's dir"
mkdir $BACKUP_DIR/$DATE

# Move checkpoint and journal to backup dir
echo "Copy checkpoint and journal to backup dir"
cp $DEPOT_DIR/checkpoint.* $BACKUP_DIR/$DATE
cp $DEPOT_DIR/journal.* $BACKUP_DIR/$DATE
echo "Copy depot to backup dir..."
cp -r $DEPOT_DIR/depot $BACKUP_DIR/$DATE
echo "=========Daily backup complete========="

# Remove outdated data
echo "Removing outdated dir:$BACKUP_DIR/$OUT_DATA"
rm -rf $BACKUP_DIR/$OUT_DATA
echo "Done."
