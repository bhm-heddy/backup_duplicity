#!/bin/bash


for av in $@; do
	if [ -r $av ]; then
		source $av
	else
		>&2 echo "Bad file: $av"
		exit 1
	fi
done



export SRC_PATH=${SRC_PATH:-/var/lib/backup}
export LOG_PATH=${LOG_PATH:-/var/log}
export REMOVE_BACKUP_TIME=${REMOVE_BACKUP_TIME:-6M}
export FULL_BACKUP_TIME=${FULL_BACKUP_TIME:-1M}



if [ -z $ENC_KEY ] || [ -z $SIG_KEY ] \
	|| [ -z $PASSPHRASE ] || [ -z $SIGN_PASSPHRASE ] \
	|| [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] \
	|| [ -z $SCW_BUCKET ]
then
	>&2 echo "message d erreur + info"
	exit 1
fi


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




unset enc_key
unset sig_key
unset passphrase
unset sign_passphrase
unset aws_access_key_id
unset aws_secret_access_key
unset scw_bucket
unset repo_path
unset src_path
unset log_path
unset remove_backup_time
unset full_backup_time
