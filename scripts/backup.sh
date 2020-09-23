#!/bin/bash




source auth.sh
source cfg.sh


DATE=`date +%Y-%m`
DAY=`date +%d`
HOUR=`date +%H:%M:%S`


## Maintence mode. Locks the sessions of logged-in users and prevents new logins in order to prevent inconsistencies of your data

sudo nextcloud.occ maintenance:mode --on



## First call duplicity, delete all backup sets older than the REMOVE_BACK_TIME

echo -e "\t\t[BACKUP]\t$DATE-$DAY\t$HOUR\n" >>$LOG_PATH/backup_$DATE.log
echo -e "\t--- Removing old backups\n" >>$LOG_PATH/backup_$DATE.log

duplicity \
	remove-older-than $REMOVE_BACKUP_TIME \
	--verbosity 8 \
	--sign-key $SIG_KEY \
	--num-retries 3 \
	$SCW_BUCKET \
	>>$LOG_PATH/backup_$DATE.log \
	2>&1



## Second call, encrypt incremental backup

echo -e "\t--- Creating and uploading backup\n" >>$LOG_PATH/backup_$DATE.log

duplicity \
	--full-if-older-than $FULL_BACKUP_TIME \
	--copy-links \
	--verbosity 8 \
	--encrypt-key $ENC_KEY \
	--sign-key $SIG_KEY \
	--num-retries 3 \
	--asynchronous-upload \
	$SRC_PATH $SCW_BUCKET \
	>>$LOG_PATH/backup_$DATE.log \
	2>&1



## Disable maintenance mode

sudo nextcloud.occ maintenance:mode --off




unset ENC_KEY
unset SIG_KEY
unset PASSPHRASE
unset SIGN_PASSPHRASE
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset SCW_BUCKET
unset REPO_PATH
unset SRC_PATH
unset LOG_PATH
unset REMOVE_BACKUP_TIME
unset FULL_BACKUP_TIME
