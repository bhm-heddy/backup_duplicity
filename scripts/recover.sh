#!/bin/bash


source auth.sh
source cfg.sh

CONSIGNE="
Afficher les détails des backup (1)
Afficher les details d un backup (2)
Restorer un backup entier (3)
Restorer un fichier precis (4)"


TIME_FORMAT='\n[TIME FORMAT] :\nThe acceptible time strings are intervals (like "3D64s") \nw3-datetime strings, like "2002-04-26T04:22:01-07:00" (strings like "2002-04-26T04:22:01" are also acceptable - duplicity will use the current time zone)\nor ordinary dates like 2/4/1997 or 2001-04-23 (various combinations are acceptable, but the month always precedes the day)\n\n'


gleaning()
{
	echo -n "Indiquer la date du backup ou vide pour le plus recent : "
	read TIME
	if [ -z $TIME ]
	then
		TIME=0
	fi
	echo -n "Indiquer le path absolu où stocker le backup : "
	read DST
	if [ $OPT -eq 4 ]
	then
		echo -n "indiquer le nom du ficher ou répertoire à récupérer : "
		read FILE
	fi
}





echo -en  "$CONSIGNE\n(1-4): "
read OPT

while [ $OPT -le 2 ]
do
	if [ $OPT -eq 1 ]
	then
		bash $BACKUP_PATH/scripts/collection_status.sh
	elif [ $OPT -eq 2 ]
	then
		bash $BACKUP_PATH/scripts/list_files.sh
	fi
	echo -en "$CONSIGNE\n(1-4): "
	read OPT
done

echo -e $TIME_FORMAT

if [ $OPT -eq 3 ]
then
	gleaning
	duplicity \
		-t $TIME \
		--encrypt-key $ENC_KEY \
		--sign-key $SIG_KEY \
		$SCW_BUCKET $DST

elif [ $OPT -eq 4 ]
then
	gleaning
	duplicity \
		-t $TIME \
		--file-to-restore $FILE \
		--encrypt-key $ENC_KEY \
		--sign-key $SIG_KEY \
		$SCW_BUCKET $DST
fi


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

exit

