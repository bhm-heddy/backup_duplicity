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
	>&2 echo "Une ou des variables n'ont pas été initialisées. Voir README.ME"
	exit 1
fi


duplicity \
	collection-status \
	--encrypt-key $ENC_KEY \
	--sign-key $SIG_KEY \
	$SCW_BUCKET
	
exit $?
