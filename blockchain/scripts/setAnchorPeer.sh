#!/bin/bash

. envVar.sh
. utils.sh

ORG=$1
CHANNEL_NAME=$2
: ${CHANNEL_NAME:="mychannel"}

setGlobalsCLI $ORG

infoln "Fetching channel config for channel $CHANNEL_NAME"
set -x
peer channel fetch config config_block.pb -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME --tls --cafile "$ORDERER_CA"
{ set +x; } 2>/dev/null

infoln "Decoding config block to JSON and isolating config to ${CORE_PEER_LOCALMSPID}config.json"
set -x
configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq .data.data[0].payload.data.config config_block.json > config.json
{ set +x; } 2>/dev/null

HOST="peer0.foodorg.example.com"
PORT=7051

if [ $ORG -eq 2 ]; then
  HOST="peer0.pharmaorg.example.com"
  PORT=9051
fi

infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

set -x
jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' config.json > modified_config.json
{ set +x; } 2>/dev/null

set -x
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output config_update.pb
{ set +x; } 2>/dev/null

set -x
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb
{ set +x; } 2>/dev/null

infoln "Submitting transaction to update anchor peer for Org${ORG} on channel $CHANNEL_NAME"
set -x
peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f config_update_in_envelope.pb --tls --cafile "$ORDERER_CA"
{ set +x; } 2>/dev/null

successln "Anchor peer set for Org ${ORG} on channel '$CHANNEL_NAME'"