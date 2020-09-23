# backup_duplicity

# INSTALLATION

#### Installer duplicity
sudo apt-get update && sudo apt-get install duplicity -y

#### Installer les dépendances necessaire pour le protocol s3
sudo apt-get install -y python3-boto

#### Créer la clé de chiffrement
gpg --full-generate-key

#### Créer la clé de signature
gpg --full-generate-key

#### Faire un backup des clés.


# CONFIGURATION

## CFG.SH

Vérifier que la valeur de "BACKUP_PATH" conresponde bien à l'emplacement du répertoir contenant les répertoir "backup", "log", "script" et à l'utilisateur initiant les scripts.


La variable "FULL_BACKUP_TIME" indique à duplicity d'effectuer un backup complet tous les X temps.

La variable "REMOVE_BACK_TIME" indique à duplicity d'effacer les backup après X temps. 

Par defaut, ces variables sont configurées pour effectuer un backup complet tous les mois et effacer les backup après 6 mois. 

*****
s, m, h, D, W, M, or Y (indique secondes, minutes, heures, jours, semaine, mois, or années respectivement).
Exemple "1h78m" correspond à  une heure et 78 minutes.
Un mois est toujours égal a 35jours et une année à 365 jours.
*****


## AUTH.SH

Renseigner les variables présentes dans le script avec :
- Le fingerprint de la clé de chiffrement
- Le fingerprint de la clé de signature
- Le mot de passe de la clé de chiffrement
- Le mot de passe de la cle de signature
- L'ID du bucket cloud storage
- Le mot de passe du bucket
- Le nom du bucket




# MISE EN PLACE

Mettre les répertoires et fichier à backup dans le répertoire "backup". 
Pour éviter de devoir copier des répertoires entiers des liens symboliques peuvent mis en place :

exemple : ln -s /var/snap/nextcloud/common/nextcloud/data ~/duplicity/backup/nextcloud_data





## PARTIE SCRIPT


##### Renseigner les champs du script auth.sh && cfg.sh
