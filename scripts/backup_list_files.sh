#!/bin/bash


#  list-current-files [--time <time>] <url>
#              Lists the files contained in the most current backup or backup at time.  The
#              information will be extracted from the signature files, not the archive data
#              itself. Thus the whole archive does not have to be downloaded, but on the other
#              hand if the archive has been deleted or corrupted, this command will not detect it. 


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

CONSIGNE="Entrer :\n- Une date specifique\n- Vide ou 0 pour le backup le plus récent\n- 1 pour afficher les details des backup\n   ->: "

TIME_FORMAT='\n[TIME FORMAT] :\nThe acceptible time strings are intervals (like "3D64s") \nw3-datetime strings, like "2002-04-26T04:22:01-07:00" (strings like "2002-04-26T04:22:01" are also acceptable - duplicity will use the current time zone)\nor ordinary dates like 2/4/1997 or 2001-04-23 (various combinations are acceptable, but the month always precedes the day)\n\n'



echo -e $TIME_FORMAT

echo -ne "$CONSIGNE"

read TIME

while [ "$TIME"  == "1" ]
do
	bash backup_list_bucket.sh
	echo -ne "\n\n$CONSIGNE"
	read TIME
done

if [ -z $TIME ]
then
	TIME=0
fi



duplicity \
	list-current-files -t $TIME \
	--encrypt-key $ENC_KEY \
	--sign-key $SIG_KEY \
	$SCW_BUCKET


exit $?
