#!/bin/bash
FABRIC_REPO_TAG="2.2.11"
FABRIC_CA_TAG="1.4.9"

echo "Downloading Fabric binaries and Docker images..."
curl -sSL https://bit.ly/2ysbOFE | bash -s -- $FABRIC_REPO_TAG $FABRIC_CA_TAG

mkdir -p ../bin
mv bin/* ../bin/

echo "Fabric binaries moved to ../bin"