#!/bin/bash

# Be sure to execute this script after your checkpoint and journal files
# are properly backuped!
DEPOT_DIR=/usr/local/p4root
rm -rf $DEPOT_DIR/checkpoint.*
rm -rf $DEPOT_DIR/journal.*

