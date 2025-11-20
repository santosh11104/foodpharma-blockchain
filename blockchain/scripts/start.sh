#!/bin/bash

. utils.sh

infoln "Starting FoodPharma Blockchain Network"

# Start the network
infoln "Step 1: Starting network containers"
./network.sh up

sleep 5

# Create channel
infoln "Step 2: Creating channel"
./network.sh createChannel -c mychannel

sleep 3

# Deploy chaincode
infoln "Step 3: Deploying chaincode"
./network.sh deployCC -ccn foodpharma-cc

successln "FoodPharma blockchain network is ready!"
successln "Network endpoints:"
successln "- Orderer: localhost:7050"
successln "- FoodOrg Peer: localhost:7051"
successln "- PharmaOrg Peer: localhost:9051"