#!/bin/bash


#  list-current-files [--time <time>] <url>
#              Lists the files contained in the most current backup or backup at time.  The
#              information will be extracted from the signature files, not the archive data
#              itself. Thus the whole archive does not have to be downloaded, but on the other
#              hand if the archive has been deleted or corrupted, this command will not detect it. 


source auth.sh
source cfg.sh

CONSIGNE="Entrer :\n- Une date specifique\n- Vide ou 0 pour le backup le plus récent\n- 1 pour afficher les details des backup\n   ->: "

TIME_FORMAT='\n[TIME FORMAT] :\nThe acceptible time strings are intervals (like "3D64s") \nw3-datetime strings, like "2002-04-26T04:22:01-07:00" (strings like "2002-04-26T04:22:01" are also acceptable - duplicity will use the current time zone)\nor ordinary dates like 2/4/1997 or 2001-04-23 (various combinations are acceptable, but the month always precedes the day)\n\n'



echo -e $TIME_FORMAT

echo -ne "$CONSIGNE"

read TIME

while [ "$TIME"  == "1" ]
do
	bash $BACKUP_PATH/script/collection-status.sh
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
