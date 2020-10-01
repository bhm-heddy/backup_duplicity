#!/bin/bash

E_ERREUROPTION=65
E_ERREURFILE=64
E_ERREURENV=63
E_ERREURNC=62

#date pour les logs
DATE=`date +%Y-%m`
DAY=`date +%d`
HOUR=`date +%H:%M:%S`


ARGS=0

#Path nextcloud, defaut nextcloud installé par snap
NEXTCLOUD_OCC=${NEXTCLOUD_OCC:-/snap/bin/nextcloud.occ}
NEXTCLOUD_SQLDUMP=${NEXTCLOUD_SQLDUMP:-/snap/bin/nextcloud.mysqldump}
NEXTCLOUD_EXPORT=${NEXTCLOUD_EXPORT:-/snap/bin/nextcloud.export}





TIME_FORMAT='\n[TIME FORMAT]\nPlusieurs formats sont acceptés :\n- Un interval : s, m, h, D, W, M, or Y (indique secondes, minutes, heures, jours, semaine, mois, or années respectivement). Exemple "1h78m" correspond à une heure et 78 minutes. Un mois est toujours égal a 35jours et une année à 365 jours.\n- Une date précise  "2002-04-26T04:22:01" ou "2/4/1997" ou "2001-04-23"\nDe nombreuses combinaisons sont acceptables. Man duplicity, section "Time format" pour plus d information.\n\n'


# Quitte si aucun argument
#if [ $# -eq 0 ]
#then
#  echo "Erreur: au moins un argument attendu"
#  ft_usage
#fi


#################################################################
#######		         FONCTIONS			#########
#################################################################

ft_usage(){
	echo "Usage: `basename $0` [-b backup] [ [-s <source file>]]"
  	exit $E_ERREUROPTION
}


ft_backup(){



## Active le mode maintenance de nextcloud
#sudo $NEXTCLOUD_OCC maintenance:mode --on
#if [ $? -ne 0 ]; then
#	>&2 echo "[BACKUP ERROR]   L activation du monde maintenance a échouée"
#	exit $E_ERREURNC
#fi

## Active le mode maintenance de nextcloud
## Copie intégrale du nextcloud
## Path de la copie socker dans nextcloud_backup

NEXTCLOUD_BACKUP=`sudo nextcloud.export | grep Successfully | cut -d " " -f3`

if [ -z "$NEXTCLOUD_BACKUP" ]; then
	>&2 echo "[BACKUP ERROR] nextcloud.export a échouée"
	exit 62
fi

## Creation du lien symbolique
ln -s $NEXTCLOUD_BACKUP "$SRC_PATH"


echo -e "\t\t[BACKUP]\t$DATE-$DAY\t$HOUR\n" >>$LOG_PATH/backup_$DATE.log
echo -e "\t--- Removing old backups\n" >>$LOG_PATH/backup_$DATE.log


## Suppression des plus vieux backup
duplicity \
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
duplicity \
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


#Suppression du lien symbolique et de la copie de nextcloud
rm -rf "$SRC_PATH/`basename $NEXTCLOUD_BACKUP`"
rm -rf $NEXTCLOUD_BACKUP


exit 0
}


ft_list_bucket(){
duplicity \
	collection-status \
	--encrypt-key "$ENC_KEY" \
	--sign-key "$SIG_KEY" \
	"$SCW_BUCKET"
}


ft_list_files(){
CONSIGNE1="Entrer :\n- Une date specifique\n- Vide ou 0 pour le backup le plus récent\n- 1 pour afficher les details des backup\n   ->: "


echo -e $TIME_FORMAT

echo -ne "$CONSIGNE1"

read TIME

while [ "$TIME"  == "1" ]
do
	ft_list_bucket
	echo -ne "\n\n$CONSIGNE1"
	read TIME
done

if [ -z $TIME ]
then
	TIME=0
fi

duplicity \
	list-current-files -t $TIME \
	--encrypt-key "$ENC_KEY" \
	--sign-key "$SIG_KEY" \
	"$SCW_BUCKET"
}



ft_list(){
	echo -ne "Afficher le détail du bucket (1) \nAfficher le detail d'un backup (2)\n(1/2) : "
	read CHOICE
	if [ "$CHOICE" = "1" ]; then
		ft_list_bucket
	elif [ "$CHOICE" = "2" ]; then
		ft_list_files
	else
		ft_list
	fi
}

ft_gleaning(){
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


ft_recover(){

CONSIGNE2="
Afficher les détails du bucket (1)
Afficher les details d'un backup (2)
Restorer un backup entier (3)
Restorer un fichier precis (4)
Quitter (5)"


echo -en  "$CONSIGNE2\n(1-5): "
read OPT

while [ "$OPT" -le 2 ]
do
	if [ "$OPT" -eq 1 ]; then
		ft_list_bucket
	elif [ "$OPT" -eq 2 ]; then
		ft_list_files
	fi
	echo -en "$CONSIGNE2\n(1-5): "
	read OPT
done

if [ "$OPT" -eq 5 ] ; then
		exit 0
fi

echo -e $TIME_FORMAT

if [ "$OPT" = "3" ]; then
	ft_gleaning
	duplicity \
		-t "$TIME" \
		--encrypt-key "$ENC_KEY" \
		--sign-key "$SIG_KEY" \
		"$SCW_BUCKET" "$DST"

elif [ "$OPT" = "4" ]; then
	ft_gleaning
	duplicity \
		-t $TIME \
		--file-to-restore "$FILE" \
		--encrypt-key "$ENC_KEY" \
		--sign-key "$SIG_KEY" \
		"$SCW_BUCKET" "$DST"
fi
}


ft_sourcefile(){
	if [ -r "$OPTARG" ]; then
		source "$OPTARG"
	else
		>&2 echo "Mauvais fichier: "$OPTARG": Fichier inexistant ou permissions insuffisantes"
		exit $E_ERREURFILE
	fi
}






#################################################################
#######		         MAIN								#########
#################################################################


# Parcourt les arguments
while getopts ":bs:" Option
do
	case $Option in
	b ) ARGS="BACKUP";;
	s ) ft_sourcefile;;
	* ) ft_usage
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


#Lance le mode en fonction de l'argument passé
if [ $ARGS = "BACKUP" ]; then
	ft_backup
else
	ft_recover
fi


exit 0
