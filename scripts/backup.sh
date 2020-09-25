#!/bin/bash

# Source si des fichiers de configuration sont passés en argument

for av in $@; do
	if [ -r $av ]; then
		source $av
	else
		>&2 echo "Fichier inexistant ou de permissions: $av"
		exit 1
	fi
done



# Initialise ces variables si elles n'existent pas

SRC_PATH=${SRC_PATH:-/var/lib/backup}
LOG_PATH=${LOG_PATH:-/var/log}
REMOVE_BACKUP_TIME=${REMOVE_BACKUP_TIME:-6M}
FULL_BACKUP_TIME=${FULL_BACKUP_TIME:-1M}



# Vérifie l'existence de ces variables

if [ -z $ENC_KEY ] || [ -z $SIG_KEY ] \
	|| [ -z $PASSPHRASE ] || [ -z $SIGN_PASSPHRASE ] \
	|| [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] \
	|| [ -z $SCW_BUCKET ]
then
	>&2 echo "Une ou des variables n'ont pas été initialisées. Voir README.ME"
	exit 1
fi



DATE=`date +%Y-%m`
DAY=`date +%d`
HOUR=`date +%H:%M:%S`



## Active le mode maintenance de nextcloud

sudo nextcloud.occ maintenance:mode --on


if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]   L'activation du monde maintenance a échouée"
	exit 1
fi


echo -e "\t\t[BACKUP]\t$DATE-$DAY\t$HOUR\n" >>$LOG_PATH/backup_$DATE.log
echo -e "\t--- Removing old backups\n" >>$LOG_PATH/backup_$DATE.log


## Suppression des plus vieux backup

duplicity \
	remove-older-than $REMOVE_BACKUP_TIME \
	--verbosity 8 \
	--sign-key $SIG_KEY \
	--num-retries 3 \
	$SCW_BUCKET \
	>>$LOG_PATH/backup_$DATE.log \
	2>&1

if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]  La suppression des anciens backup a échouée."
fi


echo -e "\t--- Creating and uploading backup\n" >>$LOG_PATH/backup_$DATE.log


## Sauvegarde

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

if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]  La sauvegarde a échouée."
fi


## Desactive le mode maintenance

sudo nextcloud.occ maintenance:mode --off

if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]   La désactivation du monde maintenance a échouée"
	exit 1
fi

exit 0
