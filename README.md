# backup_duplicity


**backup.sh** : Effectue la sauvegarde.

**backup_list_bucket.sh** : Liste l'ensemble des sauvegardes sur le bucket.

**backup_list_files.sh** : Liste les fichiers et répertoires dans une sauvegarde.

**backup_recover.sh**: Récupère une sauvegarde complète ou un fichier ou répertoire précis.


# INSTALLATION

#### Installer duplicity
ubutun 16.04 LTS
`sudo snap install duplicity --classic`
	
Ubuntu 20.04.1 LTS
`sudo apt-get update && sudo apt-get install duplicity -y`

#### Installer les dépendances necessaire pour le protocol s3

ubutun 16.04 LTS
`sudo apt-get install -y python-boto`

Ubuntu 20.04.1 LTS
`sudo apt-get install -y python3-boto`

#### Créer la clé de chiffrement
  `sudo gpg --full-generate-key`

#### Créer la clé de signature
  `sudo gpg --full-generate-key`

#### Faire un sauvegarde des clés.



# UTILISATION

## Fonctionnement

Les scipts *scripts/backup.sh*, *scipts/backup_list_bucket.sh*, *scripts/backup_list_files.sh*, *scripts/backup_recover.sh* ont besoin que des *variables d'environnements* et des *variables locales* soient initialisées.

Varaibles d'envirronnement pour le chiffrement gpg

* ENC_KEY : Le fingerprint de la clé de chiffrement
* SIG_KEY : Le fingerprint de la clé de signature
* PASSPHRASE : Le mot de passe de la clé de chiffrement
* SIGN_PASSPHRASE : Le mot de passe de la cle de signature

Variables d'environnement pour le bucket S3
* AWS_ACCESS_KEY_ID : L'ID du bucket cloud storage
* AWS_SECRET_ACCESS_KEY : Le mot de passe du bucket
* SCW_BUCKET : Le nom du bucket

Variables locales de configuration de la sauvegarde.
Si ces variables n'existe pas, elles prennent une valeur défaut
* FULL_BACKUP_TIME : Effectue un sauvegarde complet tous les X temps. (défaut: *1M*)
* REMOVE_BACK_TIME : Efface les sauvegardes les plus anciens après X temps. (défaut: *6M*)
* SRC_PATH : Chemin du répertoir à sauvegarder. (defaut: *A COMPLETER*)
* LOG_PATH : Chemin oú écrire les log (défaut: */var/log*)







## Conseil de mise en place et d'utilisation

Créer un répertoire pour stocker les fichiers à backup
`mkdir ~/backup`
Pour ne pas à avoir à copier des fichiers et répertoires volumineux, l'utilisation de liens symboliques est supporté
`ln -s /rèpertoire_à_sauvegardè ~/backup/ŕepertoire`

Rendre les scripts exècutables 

`chmod +x scripts/*.sh `

Déplacer les scripts dans */usr/sbin*

`mv scripts/*.sh /usr/sbin`

Renseigner les variables des fichiers de configuration et les déplacer dans */etc*

`mv backup_auth.conf backup_cfg.conf /etc`

#### Utilisation
`backup /etc/backup_auth_conf /etc/backup_cfg.conf`

`bacup_list_bucket /etc/backup_auth.conf`

`backup_recover /etc/backup_auth.conf`

#### Crontab
Mise en place d'une tâche crontab effectuant une sauvegarde tous les jours à 03h00.

`crontab -e`

`00 03 * * *		backup /etc/back_auth.conf /etc/backup_cfg.con`



