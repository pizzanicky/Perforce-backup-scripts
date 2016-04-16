#!/bin/bash
/usr/local/bin/p4d -r /usr/local/p4root -J /media/backup/journal -L /var/log/p4err -p tcp64:[::]:1666 &
