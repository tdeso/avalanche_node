# Introduction

Repo contenant deux scripts permettant l'installation d'un noeud Avalanche et sa mise à jour.

# Prérequis

Avoir suivi le tutoriel à cette adresse:
https://nicolas-avalabs.gitbook.io/avalanche-tutoriels/tutoriels/securisation-dun-serveur-vps

## Installation

  1. Se connecter au VPS
  2. lancer la commande suivante:
```shell
curl -s https://raw.githubusercontent.com/tdeso/avalanche_node/master/install.sh | bash
```
  3. Vérifier que le noeud tourne avec la commande suivante:
```shell
sudo systemctl status avaxnode
```
  4. Lancer la commande curl suivante pour récupérer le NodeID:
```shell
curl -X POST --data '{
  "jsonrpc":"2.0",
  "id"     :1,
  "method" :"info.getNodeID"
}' -H 'content-type:application/json;' 127.0.0.1:9650/ext/info
```
  5. Suivre les instructions pour devenir validateur: https://docs.avax.network/v1.0/en/tutorials/adding-validators/
  
  6. Faire une sauvegarde du dossier staking avec la commande suivante:
```shell
scp -r -P XXXX user@XX.XX.XX.XX:/home/avalanche-user/go/src/github.com/ava-labs/.avalanchego/staking/ $HOME/avalanche
```
  
  7. Faire une sauvegarde de l'utilisateur en lançant la commande curl suivante:
```shell
curl --location --request POST 'http://localhost:9650/ext/keystore' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "keystore.exportUser",
    "params": {
        "username": "[ENTER YOUR USERNAME HERE]",
        "password": "[ENTER YOUR PASSWORD HERE]"
    }
}'
```

## Post-installation

  1. Pour consulter les logs, lancer la commande suivante:
```shell
journalctl -u avaxnode.service
```

  2. Pour mettre à jour le noeud, lancer la commande suivante:
```shell
cd $HOME/bin && ./update.sh
```
  3. Pour modifier les arguments de lancement de avalanchego, éditer le fichier `/etc/.avavalanche.conf`

## Licence
[MIT](https://choosealicense.com/licenses/mit/)
