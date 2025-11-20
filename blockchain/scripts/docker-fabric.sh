#!/bin/bash

# Run Fabric commands using Docker containers instead of local binaries

configtxgen() {
    docker run --rm -v ${PWD}/../config:/etc/hyperledger/fabric -v ${PWD}/../channel-artifacts:/channel-artifacts hyperledger/fabric-tools:latest configtxgen "$@"
}

peer() {
    docker exec cli peer "$@"
}

export -f configtxgen
export -f peer