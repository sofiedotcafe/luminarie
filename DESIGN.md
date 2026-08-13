# RFC 001
A sovereign fleet infrastructure design document

## 1. Summary & Motivation

Traditional enterprise workstation and server management architectures rely on persistent inbound administrative listeners (such as SSH servers or centralized push orchestrators) and configuration data stored unencrypted in shared source repositories. These designs expose nodes to network interception, lateral movement, and compromise of the central orchestration plane.

This RFC specifies a decentralized, pull-based, hardware-authenticated infrastructure management framework. By combining OpenBao (Vault) for zero-trust secrets management, systemd-vaultd for in-memory credential injection, TPM2 PKI for hardware-rooted identity, and nix-fleet over Iroh P2P (QUIC) for state propagation, this architecture ensures that:

* Devices operate securely behind strict NAT or Carrier-Grade NAT (CGNAT) topologies without inbound listening ports.
* Secrets are never written to persistent disk storage or stored within Git repositories.
* Compromise of the control plane results in a scheduling outage rather than a credential data breach.

## 2. Protocol Graphs

### 2.1 Enrollment Phase

```mermaid
sequenceDiagram
    autonumber
    participant TPM as Hardware TPM2
    participant Agent as nix-fleet Agent
    participant Coord as Coordinator
    participant Vault as OpenBao

    TPM->>Agent: Generate EK/AK Keys & CSR
    Agent->>Coord: Handshake (NodeID + CSR)
    Coord->>Agent: Issue Signed Capability Token
    Agent->>Vault: Register TPM-bound Auth

```

### 2.2 Secrets Fetching Phase

```mermaid
sequenceDiagram
    autonumber
    participant App as Systemd Service
    participant VaultD as systemd-vaultd
    participant Vault as OpenBao

    App->>VaultD: Request Credential Socket
    VaultD->>Vault: mTLS Auth via TPM
    Vault-->>VaultD: Return Secret Payload
    VaultD->>App: Write to $CREDENTIALS_DIRECTORY

```

### 2.3 Update Loop Phase

```mermaid
sequenceDiagram
    autonumber
    participant Agent as nix-fleet Agent
    participant Coord as Coordinator
    participant Cache as Binary Cache

    Agent->>Coord: Poll Update Status
    Coord-->>Agent: Return Signed Closure Hash
    Agent->>Cache: Download & Verify Closure
    Agent->>Agent: nixos-rebuild switch

```

### 2.4 Wipe Phase

```mermaid
sequenceDiagram
    autonumber
    participant Admin as Admin
    participant Coord as Coordinator
    participant Agent as Agent
    participant TPM as TPM2

    Admin->>Coord: Trigger Crypto-Wipe
    Coord->>Agent: Broadcast Revocation
    Agent->>TPM: Flush Keys / Clear Keyring
    TPM-->>Agent: Keyring Invalidated

```

### 3. Technical Specifications

Identity & Enrollment

* Bootstrapping: Devices utilize a hardware-secured TPM2 Endorsement Key (EK) to sign an initial X.509 IDevID certificate during factory installation or provisioning stage.
* mTLS Auth: OpenBao’s cert auth engine validates device certificates against an internal fleet Certificate Authority to issue scoped, short-lived session tokens.
* Key Protection: Private keys remain permanently isolated inside TPM NVRAM, bound strictly to verified Platform Configuration Register (PCR) measurement states.

Update Pipeline (nix-fleet)

* Transport Layer: Asynchronous peer-to-peer communication using Iroh (QUIC combined with UDP holepunching) bypasses NAT and CGNAT barriers without exposing inbound listening ports on the node.
* Payload Integrity: The agent enforces strict cryptographic signature checks on pre-built Nix store closures retrieved from the binary cache prior to executing nixos-rebuild switch.

Secret Injection (systemd-vaultd)

* Socket Mechanism: systemd-vaultd exposes a local Unix domain socket mapped directly to systemd's native LoadCredential specification.
* Lifecycle & Memory Isolation: Target services block at startup until vault-agent resolves and writes the payload. Decrypted secrets exist exclusively in volatile memory ($CREDENTIALS_DIRECTORY mounted on tmpfs).