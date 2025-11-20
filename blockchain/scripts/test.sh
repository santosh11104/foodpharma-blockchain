#!/bin/bash

. utils.sh

infoln "Testing FoodPharma Blockchain Network"

# Test 1: Initialize ledger
infoln "Test 1: Initializing ledger"
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n foodpharma-cc --peerAddresses peer0.foodorg.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt -c '{"Args":["InitLedger"]}'

sleep 3

# Test 2: Query all products
infoln "Test 2: Querying all products"
docker exec cli peer chaincode query -C mychannel -n foodpharma-cc -c '{"Args":["GetAllProducts"]}'

# Test 3: Create new product
infoln "Test 3: Creating new product"
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n foodpharma-cc --peerAddresses peer0.foodorg.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt -c '{"Args":["CreateProduct","TEST001","Test Product","food","Test Farm","TestCorp","T001","2024-12-31","fresh","FoodOrg","2024-01-01"]}'

sleep 3

# Test 4: Read specific product
infoln "Test 4: Reading specific product"
docker exec cli peer chaincode query -C mychannel -n foodpharma-cc -c '{"Args":["ReadProduct","TEST001"]}'

# Test 5: Transfer product
infoln "Test 5: Transferring product ownership"
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n foodpharma-cc --peerAddresses peer0.foodorg.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/foodorg.example.com/peers/peer0.foodorg.example.com/tls/ca.crt -c '{"Args":["TransferProduct","TEST001","PharmaOrg","2024-01-15"]}'

sleep 3

# Test 6: Verify transfer
infoln "Test 6: Verifying product transfer"
docker exec cli peer chaincode query -C mychannel -n foodpharma-cc -c '{"Args":["ReadProduct","TEST001"]}'

successln "All tests completed!"