# backup_duplicity

# INSTALLATION

#### Installer duplicity
ubutun 16.04 LTS
	sudo snap install duplicity --classic
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

#### Faire un backup des clés.




