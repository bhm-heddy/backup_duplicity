#!/bin/bash


for av in $@; do
	if [ -r $av ]; then
		source $av
	else
		>&2 echo "Bad file: $av"
		exit 1
	fi
done

if [ -z $ENC_KEY ] || [ -z $SIG_KEY ] \
	|| [ -z $PASSPHRASE ] || [ -z $SIGN_PASSPHRASE ] \
	|| [ -z $AWS_ACCESS_KEY_ID ] || [ -z $AWS_SECRET_ACCESS_KEY ] \
	|| [ -z $SCW_BUCKET ]
then
	>&2 echo "message d erreur + info"
	exit 1
fi


duplicity \
	collection-status \
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
