#!/bin/bash

. utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_FOODORG_CA=${PWD}/../crypto-config/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt
export PEER0_PHARMAORG_CA=${PWD}/../crypto-config/peerOrganizations/pharmaorg.example.com/peers/peer0.pharmaorg.example.com/tls/ca.crt

setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  infoln "Using organization ${USING_ORG}"
  
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="FoodOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_FOODORG_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../crypto-config/peerOrganizations/foodorg.example.com/users/Admin@foodorg.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="PharmaOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_PHARMAORG_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../crypto-config/peerOrganizations/pharmaorg.example.com/users/Admin@pharmaorg.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=peer0.foodorg.example.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=peer0.pharmaorg.example.com:9051
  else
    errorln "ORG Unknown"
  fi
}

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    if [ $1 -eq 1 ]; then
      PEER="peer0.foodorg"
    elif [ $1 -eq 2 ]; then
      PEER="peer0.pharmaorg"
    fi
    
    if [ -z "$PEERS" ]; then
      PEERS="$PEER"
    else
      PEERS="$PEERS $PEER"
    fi
    
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    
    if [ $1 -eq 1 ]; then
      TLSINFO=(--tlsRootCertFiles "${PEER0_FOODORG_CA}")
    elif [ $1 -eq 2 ]; then
      TLSINFO=(--tlsRootCertFiles "${PEER0_PHARMAORG_CA}")
    fi
    
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}