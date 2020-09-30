#!/bin/bash

ARGS=0
E_ERREUROPTION=65
E_ERREURFILE=64
E_ERREURENV=63

DATE=`date +%Y-%m`
DAY=`date +%d`
HOUR=`date +%H:%M:%S`

TIME_FORMAT='\n[TIME FORMAT] :\nThe acceptible time strings are intervals (like "3D64s") \nw3-datetime strings, like "2002-04-26T04:22:01-07:00" (strings like "2002-04-26T04:22:01" are also acceptable - duplicity will use the current time zone)\nor ordinary dates like 2/4/1997 or 2001-04-23 (various combinations are acceptable, but the month always precedes the day)\n\n' #mettre en fr


if [ $# -eq 0 ]  # Script appelé sans argument?
then
  echo "Usage: `basename $0` ....."
  exit $E_ERREUROPTION        # Sort et explique l'usage, si aucun argument(s)
                              # n'est donné.
fi


backup(){


## Active le mode maintenance de nextcloud
sudo nextcloud.occ maintenance:mode --on

if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]   L'activation du monde maintenance a échouée"
	exit 1
fi

echo -e "\t\t[BACKUP]\t$DATE-$DAY\t$HOUR\n" >>$LOG_PATH/backup_$DATE.log
echo -e "\t--- Removing old backups\n" >>$LOG_PATH/backup_$DATE.log


## Suppression des plus vieux backup

sudo duplicity \
	remove-older-than "$REMOVE_BACKUP_TIME" \
	--verbosity 8 \
	--sign-key "$SIG_KEY" \
	--num-retries 3 \
	"$SCW_BUCKET" \
	>>"$LOG_PATH"/backup_$DATE.log \
	2>&1

if [ $? -ne 0 ]; then
	>&2 echo "[BACKUP ERROR]  La suppression des anciens backup a échouée."
fi


echo -e "\t--- Creating and uploading backup\n" >>$LOG_PATH/backup_$DATE.log


## Sauvegarde

sudo duplicity \
	--full-if-older-than "$FULL_BACKUP_TIME" \
	--copy-links \
	--verbosity 8 \
	--encrypt-key "$ENC_KEY" \
	--sign-key "$SIG_KEY" \
	--num-retries 3 \
	--asynchronous-upload \
	"$SRC_PATH" "$SCW_BUCKET" \
	>>"$LOG_PATH"/backup_$DATE.log \
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
}


list_bucket(){
sudo duplicity \
	collection-status \
	--encrypt-key "$ENC_KEY" \
	--sign-key "$SIG_KEY" \
	"$SCW_BUCKET"
}


list_files(){
CONSIGNE1="Entrer :\n- Une date specifique\n- Vide ou 0 pour le backup le plus récent\n- 1 pour afficher les details des backup\n   ->: "


echo -e $TIME_FORMAT

echo -ne "$CONSIGNE1"

read TIME

while [ "$TIME"  == "1" ]
do
	list_bucket
	echo -ne "\n\n$CONSIGNE1"
	read TIME
done

if [ -z $TIME ]
then
	TIME=0
fi

sudo duplicity \
	list-current-files -t $TIME \
	--encrypt-key "$ENC_KEY" \
	--sign-key "$SIG_KEY" \
	"$SCW_BUCKET"
}



list(){
	echo -ne "Afficher le détail du bucket (1) \nAfficher le detail d'un backup (2)\n(1/2) : "
	read CHOICE
	if [ "$CHOICE" = "1" ]; then
		list_bucket
	elif [ "$CHOICE" = "2" ]; then
		list_file
	else
		exit 1
	fi
}







gleaning(){
	echo -n "Indiquer la date du backup ou vide pour le plus recent : "
	read TIME
	if [ -z "$TIME" ]
	then
		TIME=0
	fi
	echo -n "Indiquer le chemin où stocker le backup (path/<NAME BACKUP>) : "
	read DST
	if [ "$OPT" -eq 4 ]
	then
		echo -n "indiquer le nom du ficher ou répertoire à récupérer : "
		read FILE
	fi
}


recover(){

CONSIGNE2="
Afficher les détails des backup (1)
Afficher les details d un backup (2)
Restorer un backup entier (3)
Restorer un fichier precis (4)"


echo -en  "$CONSIGNE2\n(1-4): "
read OPT

while [ "$OPT" -le 2 ]
do
	if [ "$OPT" -eq 1 ]
	then
		list_bucket
	elif [ "$OPT" -eq 2 ]
	then
		list_files
	fi
	echo -en "$CONSIGNE2\n(1-4): "
	read OPT
done

echo -e $TIME_FORMAT

if [ "$OPT" = "3" ]; then
	gleaning
	sudo duplicity \
		-t "$TIME" \
		--encrypt-key "$ENC_KEY" \
		--sign-key "$SIG_KEY" \
		"$SCW_BUCKET" "$DST"

elif [ "$OPT" = "4" ]; then
	gleaning
	sudo duplicity \
		-t $TIME \
		--file-to-restore "$FILE" \
		--encrypt-key "$ENC_KEY" \
		--sign-key "$SIG_KEY" \
		"$SCW_BUCKET" "$DST"
fi
}


sourcefile(){
	if [ -r "$OPTARG" ]; then
		source "$OPTARG"
	else
		>&2 echo "Mauvais fichier: "$OPTARG": Fichier inexistant ou permissions insuffisantes"
		exit $E_ERREURFILE
	fi
}


while getopts ":blrs:" Option
do
	case $Option in
	b ) ARGS="BACKUP";;
	l ) ARGS="LIST";;
	r ) ARGS="RECOVER";;
	s ) sourcefile;;
	esac
done




# Initialise ces variables si elles n'existent pas

SRC_PATH=${SRC_PATH:-~/backup}
LOG_PATH=${LOG_PATH:-/var/log}
REMOVE_BACKUP_TIME=${REMOVE_BACKUP_TIME:-6M}
FULL_BACKUP_TIME=${FULL_BACKUP_TIME:-1M}


# Vérifie l'existence de ces variables

if [ -z "$ENC_KEY" ] || [ -z "$SIG_KEY" ] \
	|| [ -z "$PASSPHRASE" ] || [ -z "$SIGN_PASSPHRASE" ] \
	|| [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] \
	|| [ -z "$SCW_BUCKET" ]
then
	>&2 echo "Une ou des variables n'ont pas été initialisées. Voir README.ME"
	exit $E_ERREURENV
fi

if [ $ARGS = "BACKUP" ]; then
	backup
elif [ $ARGS = "LIST" ]; then
	list
elif [ $ARGS = "RECOVER" ]; then
	recover
fi


exit 0
