#!/bin/bash

FABRIC_VERSION="2.5.4"
FABRIC_CA_VERSION="1.5.7"

echo "Downloading Fabric binaries only..."

# Download and extract binaries
curl -sSL https://github.com/hyperledger/fabric/releases/download/v${FABRIC_VERSION}/hyperledger-fabric-linux-amd64-${FABRIC_VERSION}.tar.gz | tar xz -C ../bin/

# Download CA binaries
curl -sSL https://github.com/hyperledger/fabric-ca/releases/download/v${FABRIC_CA_VERSION}/hyperledger-fabric-ca-linux-amd64-${FABRIC_CA_VERSION}.tar.gz | tar xz -C ../bin/

echo "Fabric binaries installed to ../bin/"