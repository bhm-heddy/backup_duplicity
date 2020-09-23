#!/bin/bash

source auth.sh

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
