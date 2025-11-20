#!/bin/bash

. docker-fabric.sh
export FABRIC_CFG_PATH=${PWD}/../config

. utils.sh

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}

CHANNEL_NAME="mychannel"
CC_NAME="foodpharma-cc"
CC_VERSION="1.0"
CC_SEQUENCE=1
MAX_RETRY=5
CLI_DELAY=3
VERBOSE=false

function clearContainers() {
  infoln "Removing remaining containers"
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
}

function removeUnwantedImages() {
  infoln "Removing generated chaincode docker images"
  ${CONTAINER_CLI} image rm -f $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
  ${CONTAINER_CLI} volume prune -f
}

function networkUp() {
  infoln "Starting FoodPharma blockchain network"
  ${CONTAINER_CLI_COMPOSE} -f ../config/docker-compose.yaml up -d 2>&1
  
  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

function createChannel() {
  infoln "Creating channel ${CHANNEL_NAME}"
  
  # Generate channel genesis block
  docker run --rm -v ${PWD}/../config:/etc/hyperledger/fabric -v ${PWD}/../crypto-config:/etc/hyperledger/crypto-config -v ${PWD}/../channel-artifacts:/channel-artifacts -w /channel-artifacts hyperledger/fabric-tools:latest configtxgen -profile FoodPharmaChannel -outputCreateChannelTx ${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
  
  # Create channel
  ${CONTAINER_CLI} exec cli peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  
  # Join peers to channel
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=FoodOrgMSP -e CORE_PEER_ADDRESS=peer0.foodorg.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/users/Admin@foodorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
  
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=PharmaOrgMSP -e CORE_PEER_ADDRESS=peer0.pharmaorg.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/users/Admin@pharmaorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/peers/peer0.pharmaorg.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block
  
  successln "Channel '${CHANNEL_NAME}' created and peers joined"
}

function deployCC() {
  infoln "Deploying chaincode ${CC_NAME}"
  
  # Package chaincode
  ${CONTAINER_CLI} exec cli peer lifecycle chaincode package ${CC_NAME}.tar.gz --path /opt/gopath/src/github.com/chaincode/ --lang golang --label ${CC_NAME}_${CC_VERSION}
  
  # Install on FoodOrg peer
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=FoodOrgMSP -e CORE_PEER_ADDRESS=peer0.foodorg.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/users/Admin@foodorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
  
  # Install on PharmaOrg peer
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=PharmaOrgMSP -e CORE_PEER_ADDRESS=peer0.pharmaorg.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/users/Admin@pharmaorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/peers/peer0.pharmaorg.example.com/tls/ca.crt cli peer lifecycle chaincode install ${CC_NAME}.tar.gz
  
  # Get package ID
  PACKAGE_ID=$(${CONTAINER_CLI} exec cli peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
  
  # Approve for FoodOrg
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=FoodOrgMSP -e CORE_PEER_ADDRESS=peer0.foodorg.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/users/Admin@foodorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  
  # Approve for PharmaOrg
  ${CONTAINER_CLI} exec -e CORE_PEER_LOCALMSPID=PharmaOrgMSP -e CORE_PEER_ADDRESS=peer0.pharmaorg.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/users/Admin@pharmaorg.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/peers/peer0.pharmaorg.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  
  # Commit chaincode definition
  ${CONTAINER_CLI} exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.foodorg.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt --peerAddresses peer0.pharmaorg.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/pharmaorg.example.com/peers/peer0.pharmaorg.example.com/tls/ca.crt
  
  successln "Chaincode ${CC_NAME} deployed successfully"
}

function networkDown() {
  infoln "Stopping network"
  ${CONTAINER_CLI_COMPOSE} -f ../config/docker-compose.yaml down --volumes --remove-orphans
  clearContainers
  removeUnwantedImages
  
  # Clean up artifacts
  rm -rf ../channel-artifacts/*.block ../channel-artifacts/*.tx
  rm -rf *.tar.gz
}

# Parse command line arguments
if [[ $# -lt 1 ]] ; then
  echo "Usage: $0 {up|down|createChannel|deployCC}"
  exit 0
else
  MODE=$1
  shift
fi

# Parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  * )
    echo "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done

# Execute based on mode
if [ "$MODE" == "up" ]; then
  infoln "Starting FoodPharma network"
  networkUp
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'"
  createChannel
elif [ "$MODE" == "deployCC" ]; then
  infoln "Deploying chaincode on channel '${CHANNEL_NAME}'"
  deployCC
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
  networkDown
else
  echo "Usage: $0 {up|down|createChannel|deployCC}"
  exit 1
fi
