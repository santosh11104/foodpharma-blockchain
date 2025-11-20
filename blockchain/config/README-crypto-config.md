# crypto-config.yaml — documentation

This file documents the structure and purpose of `crypto-config.yaml` used by the `cryptogen` tool
to generate cryptographic material for a Hyperledger Fabric network. The example fragment this document
describes is the one at `blockchain/config/crypto-config.yaml`.

Purpose
- `cryptogen` consumes `crypto-config.yaml` to create keys, certificates, and MSP directories for
  orderers and peers. This is intended for development and test networks. For production networks,
  consider a CA-based approach (Fabric CA or an external CA).

Top-level structure
- `OrdererOrgs`: list of orderer organization entries.
- `PeerOrgs`: list of peer organization entries.

Fields explained (common fields used in the example)
- `Name`: Logical name of the organization (e.g., `OrdererOrg`, `FoodOrg`).
- `Domain`: DNS-style domain for the org (e.g., `example.com`, `foodorg.example.com`).
- `Specs`: Used by orderer orgs to define orderer hostnames. Each spec typically contains a `Hostname`.
- `Template` (under a peer org): `Count` indicates how many peer identities (peer0..peerN) to generate.
- `Users`: `Count` indicates how many user certificates to generate (commonly used to create an `Admin` user).

The provided snippet (lines 1–21)
```yaml
OrdererOrgs:
  - Name: OrdererOrg
    Domain: example.com
    Specs:
      - Hostname: orderer

PeerOrgs:
  - Name: FoodOrg
    Domain: foodorg.example.com
    Template:
      Count: 2
    Users:
      Count: 1

  - Name: PharmaOrg
    Domain: pharmaorg.example.com
    Template:
      Count: 2
    Users:
      Count: 1
```

What this produces
- One orderer under the domain `example.com` with the hostname `orderer` (orderer.example.com).
- Two peer identities for `FoodOrg` (peer0.foodorg.example.com, peer1.foodorg.example.com) and
  one user cert (useful to create admin/user MSPs).
- Two peer identities for `PharmaOrg` (peer0.pharmaorg.example.com, peer1.pharmaorg.example.com) and
  one user cert.

How to change the config
- Increase `Template.Count` to generate more peers for an organization.
- Increase `Users.Count` to create more user identities (admins, application users).
- Add more entries under `OrdererOrgs` or `PeerOrgs` to include additional organizations.
- For multiple orderer nodes, add more `Specs` entries, e.g.:
```yaml
Specs:
  - Hostname: orderer0
  - Hostname: orderer1
```

Quick `cryptogen` usage
- From the directory containing `crypto-config.yaml` run:
```bash
cryptogen generate --config=crypto-config.yaml --output=../crypto-config
```
- Adjust the `--output` path as needed. Ensure the `cryptogen` binary is on your `PATH` or use the
  full path to the binary located in your Fabric binaries (e.g., `bin/cryptogen`).

Notes & common pitfalls
- `cryptogen` is intended for development/test only — it does not provide production-level key management.
- Ensure org `Domain` names are unique and correctly formed.
- Hostnames created by `Template.Count` and `Specs` follow Fabric naming conventions (peer0, peer1,
  orderer0, etc.). If you rely on container hostnames, make sure Docker Compose / Kubernetes manifests
  use the same names.
- If you need TLS certificates, `cryptogen` can generate them as part of the same output; make sure
  your Fabric configs (orderer/peer YAMLs) point to the generated TLS directories.

Further reading
- Fabric docs — cryptogen and identity management: https://hyperledger-fabric.readthedocs.io/

If you want, I can:
- Validate this `crypto-config.yaml` and run `cryptogen generate` in the workspace (if you want me to),
- Or convert this doc into a short `blockchain/config/crypto-config-example.md` with multiple examples.
