# Unofficial bash strict mode.
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e
set -o pipefail

# Enabled debug flag for bash shell
set -x

CMD="docker-compose"
if ! command -v docker-compose &> /dev/null
then
    echo "docker-compose not found, let's try 'docker compose'"
    CMD="docker compose"
fi


dockerId=$(docker ps | grep yaci-cli:0.0.20-beta1 | awk '{print $1}')

# Remove old genesis hashes
sed -i '/ByronGenesisHash/d' ./config/yaci-node-configuration.yaml
sed -i '/ShelleyGenesisHash/d' ./config/yaci-node-configuration.yaml
sed -i '/AlonzoGenesisHash/d' ./config/yaci-node-configuration.yaml
sed -i '/ConwayGenesisHash/d' ./config/yaci-node-configuration.yaml

byronGenesisHash=$(docker exec $dockerId cardano-cli byron genesis print-genesis-hash --genesis-json /clusters/default/genesis/byron/genesis.json)
echo "ByronGenesisHash: $byronGenesisHash" >> ./config/yaci-node-configuration.yaml

shelleyGenesisHash=$(docker exec $dockerId  cardano-cli genesis hash --genesis /clusters/default/genesis/shelley/genesis.json)
echo "ShelleyGenesisHash: $shelleyGenesisHash" >> ./config/yaci-node-configuration.yaml

alonzoGenesisHash=$(docker exec $dockerId  cardano-cli genesis hash --genesis /clusters/default/genesis/shelley/genesis.alonzo.json)
echo "AlonzoGenesisHash: $alonzoGenesisHash" >> ./config/yaci-node-configuration.yaml

alonzoGenesisHash=$(docker exec $dockerId  cardano-cli genesis hash --genesis /clusters/default/genesis/shelley/genesis.conway.json)
echo "ConwayGenesisHash: $alonzoGenesisHash" >> ./config/yaci-node-configuration.yaml

# fix timestamp in alonzo genesis file 
sudo sed -i 's/\("systemStart" : "[^"]*\)\.[0-9]*Z"/\1Z"/' ./cluster-data/default/genesis/shelley/genesis.json

# launch db sync docker image
$CMD -p db-sync -f ./docker-compose-db-sync.yml --env-file env up
