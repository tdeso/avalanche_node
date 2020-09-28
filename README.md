# Introduction

Ce script automatise les étapes du guide suivant https://github.com/ava-labs/avalanchego

# PREREQUIS

## Utilisation

  1. Se connecter au VPS
  2. lancer la commande
```shell
curl -s https://raw.githubusercontent.com/tdeso/avalanche_node/master/install.sh | bash
```
  3. Vérifier que le noeud tourne
```shell
sudo systemctl status avaxnode
```
  4. Lancer la commande curl pour récupérer le NodeID
```shell
curl -X POST --data '{
  "jsonrpc":"2.0",
  "id"     :1,
  "method" :"info.getNodeID"
}' -H 'content-type:application/json;' 127.0.0.1:9650/ext/info
```
  5. Faire une sauvegarde du dossier staking 
```shell
scp -r -P XXXX user@XX.XX.XX.XX:/home/avalanche-user/go/src/github.com/ava-labs/.avalanchego/staking/ Users/localMachine/Desktop
```
  6. Suivre les instructions pour devenir validateur: https://docs.avax.network/v1.0/en/tutorials/adding-validators/

## Licence
[MIT](https://choosealicense.com/licenses/mit/)
