# FoodPharma Blockchain Network

A Hyperledger Fabric blockchain network for food and pharmaceutical supply chain tracking.

## Network Architecture

- **Organizations**: FoodOrg, PharmaOrg, OrdererOrg
- **Peers**: peer0.foodorg.example.com:7051, peer0.pharmaorg.example.com:9051
- **Orderer**: orderer.example.com:7050 (Raft consensus)
- **Channel**: mychannel
- **Chaincode**: foodpharma-cc (Go) - Located in `/chaincode`

## Quick Start

```bash
cd blockchain/scripts

# Start the network
./start.sh

# Stop the network
./stop.sh
```

## Manual Operations

```bash
cd blockchain/scripts

# Start network containers
./network.sh up

# Create channel
./network.sh createChannel -c mychannel

# Deploy chaincode
./network.sh deployCC -ccn foodpharma-cc

# Stop network
./network.sh down
```

## Testing

```bash
cd blockchain/scripts

# Run comprehensive tests
./test.sh

# Manual testing via CLI
docker exec -it cli bash
peer chaincode query -C mychannel -n foodpharma-cc -c '{"Args":["GetAllProducts"]}'
```

## Chaincode Functions

- `InitLedger()` - Initialize with sample data
- `CreateProduct(id, name, type, origin, manufacturer, batchNumber, expiryDate, status, owner, timestamp)`
- `ReadProduct(id)` - Get product details
- `TransferProduct(id, newOwner, timestamp)` - Transfer ownership
- `GetAllProducts()` - List all products
- `ProductExists(id)` - Check if product exists

## Network Endpoints

- Orderer: localhost:7050
- FoodOrg Peer: localhost:7051
- PharmaOrg Peer: localhost:9051
- CLI Container: Access via `docker exec -it cli bash`

## Prerequisites

- Docker and Docker Compose
- Go 1.19+ (for chaincode development)

## Security Notes

- All cryptographic materials are auto-generated
- TLS enabled for all network communication
- Private keys and certificates are gitignored
- No hardcoded credentials in source code

## Project Structure

```
foodpharma/
├── blockchain/          # Blockchain network configuration
│   ├── config/         # Network configuration files
│   ├── scripts/        # Network management scripts
│   └── crypto-config/  # Cryptographic materials (gitignored)
└── chaincode/          # Smart contract code
    ├── foodpharma.go   # Main chaincode
    └── go.mod          # Go dependencies
```

## Development Setup

1. Clone repository
2. Generate crypto materials: `cd blockchain/scripts && ./bootstrap.sh`
3. Start network: `./start.sh`
4. Run tests: `./test.sh`

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request