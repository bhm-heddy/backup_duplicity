#!/bin/bash


# Source si des fichiers de configuration sont passés en argument

for av in $@; do
	if [ -r $av ]; then
		source $av
	else
		>&2 echo "Fichier inexistant ou permissions insuffisantes: $av"
		exit 1
	fi
done

# Vérifie l'existence de ces variables

if [ -z $ENC_KEY ] || [ -z $SIG_KEY ] \
	|| [ -z $PASSPHRASE ] || [ -z $SIGN_PASSPHRASE ] \
	|| [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] \
	|| [ -z $SCW_BUCKET ]
then
	>&2 echo "message d erreur + info"
	exit 1
fi

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
	echo -n "Indiquer le chmin où stocker le backup (path/<NAME BACKUP>) : "
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
		bash backup_list_bucket.sh
	elif [ $OPT -eq 2 ]
	then
		bash backup_list_files.sh
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



exit $?

